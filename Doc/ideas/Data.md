# Data

Planning notes for **Core's data framework** (`Core.Data`): how Sane UI gathers, keeps, ships and reads its
own databases. Everything here is a proposal for Saneroki to discuss (2026-10-16); nothing is built yet.
Today's data files are not the model: they move into this framework, and their old ways go (*What moves
over*).

## What it is for

Sane UI knows more and more that the game does not tell an addon: which NPC gives which quest, what a
class trainer teaches at which level, where a rare can spawn, what an item fetches at the auction house.
That data comes from several places (the game's own files and API, our own scans and crawls in the game,
what players share with each other, and what we write by hand), and it changes when Blizzard changes the
game.

**Core and its data are the backend; the modules are logic and views on top** (Saneroki, 2026-10-16). The
framework gives that data one home in Core, so that:

- **every module asks one place,** by name, and gets an answer fast, without knowing where the data came
  from or how it is stored;
- **nothing is ever lost:** when the game changes an entry, the entry gets a new version linked to the old
  one; the old one stays and can be compared with the new (*Versions*);
- **data loads only when it is needed,** and costs nothing while nobody asks for it;
- **a failure stays small:** a missing or broken database leaves its modules on their fallback (the
  Blizzard default), never the game broken;
- **updating is routine:** a tool takes in new staging, shows what changed, and the build ships it;
- **players share:** guild members who use Sane UI pass fresh auction prices and whatever their game
  discovers to each other in the game, unless they switch it off (*Sharing in the game*);
- **modules only read:** checks, writes, sharing and chat messages about changes are the database's job;
  a module asks for an entry, its history or its last versions (*Discoveries and notices*).

## Words

| Word | Meaning |
| --- | --- |
| **Set** | One kind of thing, keyed by one ID: *Items* by item ID, *Quests* by quest ID, *NPCs* by creature ID. What a module asks for. |
| **Entry** | One thing in a set: the item 16801. |
| **Version** | An entry's facts from one game build on. An entry has one or more; the newest one the running client has reached is the *current* one. |
| **Build** | The game's build number (`GetBuildInfo`): the clock versions are measured by. A small table names each build's patch (*1.60.2*) and date. |
| **Game version** | One game as one kind of client plays it, in its own folder (Sane Sync's word): Forever live (`forever`), its PTR (`forever-ptr`), its beta (`forever-beta`), later retail's. Not to be mixed up with an entry's *Version*. Their data never meet (*Game versions kept apart*). |
| **Source** | Where a fact came from: the game, a hand fix, or a numbered batch of staging from one of our tools. |
| **Master** | The sets as kept in the repository: plain text, every version, every source. The truth. |
| **Pack** | What the game loads: one or more sets compiled from the master into a small load-on-demand addon. |
| **Release** | One compile of the packs. Each set in it is named by the hash of its master and the newest build it knows; there is no date in it, so the same master always gives the same bytes (*Building*). |
| **Learned** | What the game showed in play that the packs do not know yet, kept in saved variables until the next release takes it in. |
| **Series** | Measurements over time instead of facts: auction prices per day. Kept and shipped like sets, but appended to, not versioned. |
| **Character data** | What the player's own characters have and did: bags, bank, auctions, gold, talents, legacy points. Kept per character, never shipped, never shared. |
| **Crawl** | Asking the game, on request and slowly, for everything of one kind (every item, every player spell), to keep its facts and their history. |
| **Discovery** | An accepted change to the player's data: a new entry, a change, an entry gone, a drop chance that moved. Told in chat if switched on, shared with the guild. |
| **Area** | A part of a map, as the cells it covers (a map is 100 × 100 cells): a quest's area, where a creature can spawn, where an herb grows (*Quest areas*, *Places on the map*). |

## The picture

```
 where it comes from          the repository                                   the game
 ───────────────────          ──────────────                                   ────────
 the game's files ─┐
 hand fixes ───────┴─► staging ─► import ─► MASTER ─► check ─► compile ─► PACKS ─► Core.Data ─► modules
                       (lines)    (report)  (text, every                 (load on   (Set, Get,
                                             version)                     demand)    History)
        ▲                                                                                 │
        └─ harvest ◄── saved variables (learned, series) ◄── watchers, scans, sharing ◄───┘
```

1. **Gather:** a tool reads a source and writes a *staging* file in one neutral format.
2. **Import:** `dev/tools/data import` compares it with the master and reports new entries, changed
   entries and conflicts; applied, it adds entries and versions. It never deletes.
3. **Check:** `dev/tests/run` checks every set against its schema.
4. **Compile:** `dev/build` turns the master into packs in `BUILD/`.
5. **Use:** modules read through `Core.Data`.
6. **Learn:** what the game shows in play that differs from the packs (a nerfed item, a vendor's new
   goods) and the auction scans go into saved variables.
7. **Harvest:** `dev/tools/data harvest` reads those saved files back into staging, and the circle closes.

## Sets by concern

A pack is cut by **who needs it and when**: what is needed together at the same moment goes into one pack;
what is big and needed rarely (spawn places, long price history) gets its own, so it does not load with
the rest.

| Pack (addon) | Sets | Asked for by | Loads |
| --- | --- | --- | --- |
| `SaneUI_Data_Items` | Items (with the game's stats and effects), ItemSets | Tooltips, Economy, later the character sheet | first item looked at |
| `SaneUI_Data_Quests` | Quests (name, levels, requirements, giver and taker, objectives and stages, chain, breadcrumbs, rewards; givers, takers, drops, starters and chains as indexes; *Quests*) | Tooltips, Navigation | soon after login |
| `SaneUI_Data_World` | NPCs (stats, abilities, buffs, services: *Creatures*), CreatureSpells, Objects, Zones, Travel, Places, Drops (counts: *Drop rates and gathering*) | Tooltips, Navigation | soon after login |
| `SaneUI_Data_Spawns` | Spawns (what a map shows: NPCs with a service, quest givers and objectives, rares, treasures, objects, herbs and ore), QuestAreas (*Quest areas*), PatrolPaths (the NPCs' paths, Saneroki 2026-10-16) | Navigation | first map opened; with Navigation on, soon after login (the minimap shows from login), so it stays lean |
| `SaneUI_Data_CreatureSpawns` | CreatureSpawns (every other creature's spawn points and areas; Saneroki, decision 18) | Navigation, a creature's tooltip | first asked for: a creature's spawns, its area on the map |
| `SaneUI_Data_Routes` | Walking (the walking data for Navigation's routes, made by our tool, its size measured once made; Saneroki 2026-10-16: route data is on demand and Core's) | Navigation | first route asked for |
| `SaneUI_Data_Guides` | Guides (the leveling guides, Saneroki 2026-10-16: per guide its side, levels and the guide after it; per step its places, quests, NPCs, creatures, items, checks and for whom; `Doc/ideas/Navigation.md`, *Leveling guide*) | Navigation | first guide shown |
| `SaneUI_Data_Spells` | Spells (the players' spells and abilities, every rank), Auras (buffs that are no player spell: *Creatures*), Trainers, QuestSpells, WeaponSkills, SkillLines, Professions | Abilities, Tooltips, Economy's trainer window | Abilities' login |
| `SaneUI_Data_Talents` | Talents (the class trees), Legacy (the three Legacy trees, their challenges and reward track) | Tooltips, later a talent window | first talent looked at |
| `SaneUI_Data_Market` | Vendors; Prices (a series) | Economy, Tooltips | auction house, vendor, first price shown |
| `SaneUI_Data_Game` | CVarLabels, Currencies, other tables from the game's own code | Settings | options first opened |
| `SaneUI_Data_Characters` | No shipped data: the characters' own data (*Characters*) | Tooltips (counts on alts), Economy, later bags and a character sheet | soon after every login |

- A set's name is unique across packs: a module asks for `"Items"`, never for a pack.
- Every set here has its schema since step 1a.7 (`assets/data/<Set>/schema.toml`; the guide lists them with
  their keys, *The sets*). Spawns and Drops, whose things have IDs that overlap, are keyed by text
  (`npc:<ID>`, `object:<ID>`). Still open for prompt 2: a mailbox is a kind of both *Objects* and *Places*
  (one of them is to give it up), and Navigation's *Tiles* has no pack here yet.
- Packs are Core's own addons, not modules: no settings page, only their data and the code that reads it
  (Saneroki, decision 24: `Quests.lua` comes with the Quests pack, `Scan.lua` with Market, ...), `## Dependencies:
  SaneUI`, `## Group: SaneUI`, `## LoadOnDemand: 1`. In the addon list they stand under Sane UI, titled
  *Data: Items*, *Data: Quests*, ... so they sort together.
- A module never depends on a pack. A module that is switched off loads no data; a pack that is switched
  off leaves its sets missing, and the modules that ask for them fall back.

## Versions

### How an entry keeps its history

An entry's versions are lines in the master, in build order. The first holds every fact; each later one
holds only the fields that changed, each in full. `since` is the build from which the version holds.

Saneroki's example: Blizzard nerfs a pair of gloves in patch 1.60.2 (the ID, builds and stats here are
examples).

```json
{"key":16801,"since":0,"src":[3],"name":"Arcanist Gloves","slot":"hands","armor":40,"stats":{"int":10,"spi":5}}
{"key":16801,"since":65100,"src":["game"],"armor":36,"stats":{"int":8,"spi":5}}
```

In the game, with a client at build 65100 or later:

```lua
Items:Get(16801).armor     --> 36
Items:At(16801, 64000)     --> the gloves as they were: armor 40, int 10
Items:Changes(16801)       --> { {since = 65100, patch = "1.60.2", field = "armor", from = 40, to = 36},
                           --    {since = 65100, patch = "1.60.2", field = "stats", from = {...}, to = {...}} }
```

A tooltip could then say *Changed in 1.60.2: armour 40 → 36*.

### The rules

- **Versions are only added.** A change in the game is a new version; the old one is never edited or
  removed.
- **A correction is not a change in the game.** If our data was wrong (a typo, a bad import), the wrong
  version is corrected in place, and git keeps what it said before. So the versions tell what Blizzard
  changed, and the git history tells what we corrected: two clocks, and neither needs extra machinery.
- **Gone:** an entry the game removed gets a last version `{"since":65100,"gone":true}`. `Get` gives nil
  from that build on; `History` and `At` still show it.
- **Replaced by another entry:** when the game swaps a thing for a new one with another ID (Forever replaced
  some quests), the new entry says `"replaces":<old key>`; the compiler adds `replacedBy` to the old one, so
  both ways can be followed. Only one side is written, so they cannot disagree.
- **The clock is the build and the day** (Saneroki, decision 21): Blizzard also changes data by hotfix,
  without a new build. A version carries both (`"since":65100,"day":"2026-11-03"`), and the game's word at
  the same build on a later day is a new version, not a conflict.
- **`since = 0`** means "as far as we know, from the start": what an import gives without knowing its build.
- **Builds:** `builds.toml` names each build's patch and date; `History` and `Changes` show patches, not
  numbers.
- **A newer pack on an older client:** a pack made for a patch the client has not reached yet answers with
  the version that client has. It costs nothing in the usual case.

### Keys

- **Blizzard's ID** wherever one exists: item, quest, creature, object, spell, map.
- **Otherwise our own number** (a mailbox, a spawn place, a pier), given once by the import and never used
  again. The schema says how a staged thing is matched to an entry already there (for a mailbox: the same
  map, within half a percent of it). That is where one thing known several ways (shipped, learned in play,
  shared) becomes **one entry**, the rule Navigation needs (*One pin per thing* in `Navigation.md`).

## Game versions kept apart

Saneroki (2026-10-17): Sane UI can be in several game versions at once: Forever live, its PTR and its beta,
later retail's (Sane Sync, *Finding the game*). Their data never mix. Forever live uses only what Forever
live showed, never a discovery of the PTR or the beta.

**Why the clock needs it:** builds are the clock, and the game versions' builds run side by side. On
Saneroki's computer (2026-10-17) Forever live is at build 70245 and its beta at 70450. A beta fact would
look newer than anything live knows, so it would become a live version. And a live client, older than such
a pack, would skip its patch check for good (*The patch check*).

- **Every fact belongs to one game version,** named short: `forever`, `forever-ptr`, `forever-beta` (later
  `retail`, `retail-ptr`, ...). Which game it is shows in the version number; whether it is live, PTR or
  beta shows in the product (Sane Sync, *What a World of Warcraft folder holds*).
- **The game already keeps most of it apart:** each game version has its own folder, addons and saved
  files, and its own realms, so guild members of two game versions never meet. What could join them is
  ours: the harvest (several folders into one master), a pack installed into the wrong folder, a `WTF` copied
  from one folder to another (a PTR is often started with live's), a backup restored, and later Sane Sync's
  data beyond the guild. Each of these is closed:

| Where | How it is kept apart |
| --- | --- |
| The master | Forever live's versions are in the set's own files (`Items.jsonl`). The PTR's and the beta's are in files of their own beside them (`Items.forever-ptr.jsonl`, `Items.forever-beta.jsonl`), holding only what that game version showed otherwise. The check refuses a line in the wrong file. |
| Builds | `builds.toml` names each build's game version. Versions are put in order within one game version only. |
| Staging and import | Every staging line names its game version (`"game":"forever-beta"`); a line without one is refused. It is compared with that game version's own view, and a change becomes a version in that game version's file. |
| The packs | Compiled per game version. Forever live's come from the live files only. The PTR's and the beta's come from the live files with their own on top: they are live's next patch, so where they showed nothing else, live's facts hold. The TOC says which (`## X-SaneUI-Game: forever-beta`), and so does `Data.Add`. |
| Installing | `dev/build` and Sane Sync read the folder's product (`.flavor.info`) and install that game version's packs. The code is the same for every game version; only the packs differ. |
| In the game | Core tells its game version from the client (`WOW_PROJECT_ID`, `IsBetaBuild`, `IsTestBuild`; which answers what is to be checked on the beta). It refuses a pack of another game version; that is said once, and the modules fall back. A client it cannot tell refuses every pack: no data rather than the wrong data. |
| Saved data | Each pack's saved variable, and Core's `SaneUIDB.data`, are keyed by game version first (`SaneUIData_Items["forever-beta"]`). Core uses only its own key. The others in a copied `WTF` stay untouched and unused. Settings are no data and may be copied freely. |
| Harvest | Per folder: it takes only the part keyed by that folder's own game version, and its staging says so. |
| Sharing | Every message names its game version; one of another is ignored, with no strike. Sane Sync's data beyond the guild later does the same. |
| Backups | Sane Sync restores a backup only into the game version it came from. |

- **Nothing flows from one game version into another,** also not when a patch moves from the PTR to live:
  live learns the patch again with its own patch check, crawl and play. The only ground they share is the
  live files under the PTR's and the beta's packs.
- **The beta's data stays the beta's:** its learned facts, crawls, counts, discoveries and prices (*The
  beta's auction data*).
- **Staging batches:** each batch's number says in `sources.toml` which game version it describes
  (decision 27).

## Realms and regions

Saneroki (2026-10-17): realms differ in kind (normal, PvP, roleplay, hardcore) and in region (US, EU, ...).
The game is the same on all of them; the market is not. So the game's facts are kept once for every realm,
and what players make is kept per auction house.

- **One copy for every realm:** whatever the client and the game decide. That covers items and their stats,
  quests, NPCs, spells, talents and places; vendors and their fixed prices; drop chances and counts (the
  game decides the loot, not the players). Sets, versions and packs are per game version only (*Game
  versions kept apart*), never per realm or region.
- **Per auction house:** what players make. That covers the scans, the price series, what sold between
  scans and the sales per day. A price of one auction house is never used, shown or mixed into another's:
  no average over realms, and no other realm's price in its place. A house with no scan yet shows no
  price.
- **An auction house is named by** its game version, region, realm and side, as
  `forever/eu/1234/horde`:
  - **Region** (`GetCurrentRegion`): a US realm and an EU realm can have the same name.
  - **Realm:** its number (`GetRealmID`); the name is only for showing. Where connected realms share one
    auction house (`GetAutoCompleteRealms`), the group counts as one realm, named by its lowest number.
  - **Side:** the house of the player's faction, or a neutral one (the house in a goblin town).
  - *To check in the game:* whether Forever's houses are split by faction, how to tell a neutral one at
    `AUCTION_HOUSE_SHOW` (by the NPC that opened it), and whether Forever has connected realms.
- **The realm's kind needs nothing of its own:** each realm has its own auction house anyway, a hardcore
  realm (`C_GameRules.IsHardcoreActive`) as much as a roleplay one. A self-found character
  (`C_PlayerInfo.IsSelfFoundActive`) uses no auction house, so it scans nothing.
- **How each part keeps it:**
  - **Saved data:** the Market pack keeps its series per house, under the game version
    (`SaneUIData_Market["forever"].houses["eu/1234/horde"]`).
  - **Characters:** a character's own auctions and auction log stay with the character, whose realm and region
    are known.
  - **The master:** the series in a file per house (`Prices/forever/eu-1234-horde.jsonl`). The harvest
    names each scan's house.
  - **Packs:** the shipped archive is one function per house, and Core runs only those of the player's
    realm; the others are never built. Once the master holds many houses (Sane Sync, *Beyond the guild*),
    a player gets only the houses of the realms they play, which Sane Sync sees in
    `WTF/Account/<account>/<realm>/`.
  - **Sharing:** a scan names its house, and a receiver takes only its own house's. A guild member on a
    connected realm shares the house; one at a neutral house brings that house's prices.
  - **Chat messages and `/sane data`** name the house.
- **Characters across realms:** character data is per character anyway, and each character knows its realm
  and region. Counts across characters (`Data.Count`) carry the realm, so a view can tell *on this realm*
  from *on all characters*.

## The master

### Files

The master is in `assets/data/` (Saneroki, decision 3): originals that a tool turns into the game's files,
as `assets/` holds the art. The engine that reads the packs stays in `src/Core/Data/`.

```
assets/data/
  builds.toml          the game's builds: game version, patch and date
  sources.toml         the sources: number, kind, the game version it describes, a description
  Items/
    schema.toml        the set's key and its type, fields, indexes, pack
    Items.jsonl        Forever live: one line per version, sorted by key and build; written by the tools
    Items.forever-beta.jsonl   the beta's: only what it showed otherwise (one file per other game version)
    fixes.jsonl        hand fixes, applied last; written by people, never by an import
  Quests/  NPCs/  ...
```

- **Plain text, one line per version:** git shows exactly which entries an import changed, two sessions can
  work on different sets without conflicts, and Python reads it without any package. A big set is split by
  key range (`Items.0.jsonl`, `Items.20000.jsonl`) to keep files and diffs readable.
- **No database file in git** (SQLite, ...): it cannot be read in a diff and two sessions would overwrite
  each other. If a question needs one, the tool can build a throwaway one from the text.
- **Tools write the master, people write the fixes.** An import compares against the master without the
  fixes, so taking in a source again never fights a hand fix. The check warns when the game has a newer
  version than a fix (the game may have fixed it itself). A set that no tool feeds (a short hand-made list)
  is written by hand directly, with source `hand`.
- The folder is not built into the game: it lies outside `src/`, so no addon folder takes it in.

### Schema

One file per set, read by the tools; the runtime needs none of it but the field order, which the compiler
writes into the pack.

```toml
set = "Items"
key = "int"              # the item ID, Blizzard's ("text" for a set keyed by a name, such as CVarLabels)
pack = "Items"
learn = true             # the game may teach it in play (Learned)

[fields]
name    = { type = "text" }
quality = { type = "int", min = 0, max = 8 }
slot    = { type = "enum", of = ["head", "neck", "shoulder", "back", "chest", "wrist", "hands", "waist", "legs", "feet"] }
armor   = { type = "int", min = 0 }
stats   = { type = "map", of = "int" }       # stat = amount
sell    = { type = "money" }                 # copper
from    = { type = "list", of = "ref NPCs" } # creatures that drop it

[index]
bySlot = "slot"
```

Types: `int`, `number`, `text`, `bool`, `enum`, `flags` (a bit mask), `money` (copper), `point` (map, x,
y), `ref <Set>` (a key of another set, checked), `list of ...`, `map of ...`. A new field is a line in the
schema; old versions simply lack it. No set has a licence line: the project's one licence covers all data
(CLAUDE.md, *One licence*).

### Sources

`sources.toml` lists every source by number, its kind, and a description:

| Kind | What | Its facts |
| --- | --- | --- |
| `game` | The game's own files in `references/`, its API, our scans and learned data | Win over imports: the game is the ground truth |
| `hand` | Hand-made sets and `fixes.jsonl` | Applied last |
| a number | A batch of staging files from one of our tools | Fill in what the game does not tell an addon |

## Gathering

### Extractors

- **What they read:** Blizzard's own: the game's code and tables in `references/` (the CVar labels today),
  and the game in play (learned data, scans; later a slow crawl on request, such as asking the client for
  every item's stats, throttled as the server needs).
- **What they write:** staging files only; they never touch the master.

### Staging

The one format every extractor writes, one JSON object per line:

```json
{"set":"Items","key":16801,"game":"forever","build":65100,"day":"2026-11-03","src":"game","fields":{"armor":36}}
{"set":"Items","key":19999,"game":"forever","build":65100,"day":"2026-11-03","src":"game","gone":true}
```

`game` is the game version the fact was seen in (*Game versions kept apart*); a line without it is refused.

### Import

`dev/tools/data import <file>` first prints a report, and changes the master only with `--apply`. Every
rule below holds within one game version: a staged fact is compared with its own game version's view, and
written only into its own game version's files (*Game versions kept apart*).

- **Unknown key:** a new entry, first version `since` = the staged build (or 0).
- **Known key, all staged fields agree** with the version current at that build: nothing changes; the
  source is added to that version's sources.
- **A field differs, and the source is the game at a newer build, or at the same build on a later day** (a
  hotfix): a new version with the changed fields.
- **A field differs otherwise** (an import against the game's facts, or two values for the same build): a
  **conflict**, listed and not applied. `--take` applies it as a correction, in place.
- **Fields a source does not have** are left alone: sources are partial.
- **Older than anything we have:** a staged fact of an older build than an entry's first version becomes
  an earlier version in front of it, if it differs (the game's files of an earlier client read by our
  tool, for example). So the history can reach back before our first crawl.
- **Missing from a source** is no proof of removal: an entry is *gone* only on the game's word or by hand.

### Harvest

`dev/tools/data harvest` reads the packs' saved files from the game's `WTF`, loading them as data only
(no functions run), and writes learned entries and series as staging for the import. It also reads the client's `.bak` copies when a saved file is missing.

## Building

- **Check** (`dev/tools/data check`, run by `dev/tests/run`): every line parses and fits its schema; keys
  are unique per build; versions in build order; every `ref` and every fix points at an entry that exists;
  no field outside the schema; every source known.
- **Compile** (`dev/build`): the master into `BUILD/SaneUI_Data_*/` (TOC, Lua, licence). The same master
  always gives the same bytes. The packs land in `BUILD/` like every addon folder and, like it, are not
  committed (Saneroki, decision 4): `dev/build` makes them anew from the master at every build. Changes are
  made only in the master, never in a pack.
- **Budgets** the check holds: each pack's size; every row decodes; a sample decodes in time.
- **Lua's constant limit is per function, not per file:** Lua 5.1 stops at 262,143 constants in one
  function, and a file whose main function is over it does not load at all. The compiler therefore puts
  at most 50,000 rows into one function and calls the functions one after the other, so no pack can meet
  the limit. Measured with Lua 5.1: 300,000 rows in one function do not load (*constant table overflow*);
  cut into six functions, the same 7.6 MB load in 131 ms.
- **The same master gives the same bytes:** compiling is a pure function of the master: no date, no clock,
  entries sorted by key, one row per line. An unchanged set gives an unchanged pack, so a hash says exactly
  when a set changed, and Sane Sync downloads only the packs that did (`Doc/ideas/SaneSync.md`).
- **Hashes, not dates:** every set carries the hash of its master (the first 8 hex digits of its SHA-256)
  and the newest build it knows. A module that keeps something worked out from a set (Tooltips' list of
  what an NPC wants) knows by the hash when it is stale.

## In the game

### What a module reads

```lua
local Data = SaneUI.Core.Data

local Items = Data.Set("Items")          -- a handle: cheap, loads nothing, never nil
Data.Prepare("Items")                     -- load soon: after the loading screen, out of combat

Items:Ready()                             -- loaded, or can be loaded now
Items:Get(16801)                          -- the current version, or nil
Items:Get(16801, "armor")                 -- one field
Items:History(16801)                      -- every version, oldest first, each with since and patch
Items:At(16801, 64000)                    -- the version at that build
Items:Changes(16801)                      -- what changed: since, patch, field, from, to
Items:Keys("bySlot", "hands")             -- keys by an index of the schema
Items:Each(fn)                            -- every entry: heavy, out of combat only
Items:Versions(16801, 3)                  -- the last three versions
Items:Stamp()                             -- grows with every accepted change: redraw if it moved
Items.hash, Items.build                   -- where the data came from: its master's hash, the newest build it knows

local Prices = Data.Series("Prices")      -- the prices of this character's auction house (Realms and regions)
Prices:Last(item)
Prices:Range(item, fromDay, toDay)        -- the shipped archive and the saved days together
```

- **Records are shared and read-only.** A module never writes into one; the tests hand out frozen records
  to catch it.
- **A set may be missing.** `Get` then gives nil and the module falls back. The handle of a set nobody
  ships works the same, so a module needs no guard of its own.
- **The game first:** where the client tells (an item's name, a quest's title), the module asks the
  client; our data fills in what the client does not say (Blizzard fidelity).

### Loading

- At login Core finds the packs and their sets from their TOC lines (`## X-SaneUI-Sets: Items, ItemSets`,
  `## X-SaneUI-Format: 1`), read with `C_AddOns.GetAddOnMetadata` without loading them. Core needs no
  generated list of its own.
- `Prepare` loads after the loading screen, one pack per frame, out of combat (`C_AddOns.LoadAddOn`).
- **`Get` never loads a pack** (Saneroki, decision 20): on a set not loaded yet it answers nil and asks for
  `Prepare`; the set's `Stamp` moves when it is there, so the view redraws. A read is always cheap and
  changes nothing; loading is a short hitch, never in a tooltip and never in a fight.
- A module that draws often (Tooltips) calls `Prepare` in its `OnLogin`, so its packs are there before the
  first tooltip and a tooltip never waits for a pack to load (*Speed*).
- A pack switched off in the addon list, missing, or of a format this Core does not read: its sets are not
  ready, Core says so once in the error log, the modules fall back. Core never switches a pack on by
  itself: the player's choice stands.

### How a pack is stored

- **One string per version,** its build and day first, then the fields in schema order. Thousands of small
  tables cost far more memory and load time than strings. (The Tooltips quest database works this way
  today, by hand.)
- **Cut by characters game text never holds:** a tab between fields; inside a field, character 30 between
  the items of a list or map, character 31 between an item's parts (a map's key and value, a point's map,
  x and y, an objective's kind, what, count and text). Those are ASCII's own separators, and no game text
  holds them or a tab: the check refuses text that does, so nothing is ever escaped and a row is taken
  apart with plain finds. (A comma or `=` would break on the first quest text that holds one.) An empty
  part is no value.
- **A table is made only for an entry somebody asks for,** and kept while anybody holds it (a cache with weak
  values): a walk over every entry (`Each`) cannot fill the memory with 25,000 tables, and taking a row
  apart again costs 2.5 µs (*Speed*).
- **The current version by default, history on demand (Saneroki):** `Get` gives the current version, and that
  is what tooltips and the rest ask for. Older versions are taken apart only when `History`, `At` or
  `Changes` asks for them. They ride in the pack as strings, only for entries that changed, so they are
  small; if they ever grow big, the compiler moves them into a pack of their own, loaded on the first
  `History`, with the same API.
- **Every version whole in the pack:** the master keeps only what changed; the compiler works each version
  out in full. So the game never adds up changes, `At` is one lookup, `Changes` compares two neighbours,
  and a field a patch removed (`null` in the master) is simply empty.
- **Indexes** the schema names are made by the compiler (a list of keys per value), not by the game at login.
- Plain readable text. The client can compress (`C_EncodingUtil.CompressString`); that is kept for a cold,
  very large part, if measuring ever asks for it.

### Who can read it

Plain text, on purpose: the packs are readable Lua strings, the saved files readable Lua, the master readable
lines. Nothing is encrypted, and nothing could usefully be:

- **Addons cannot be kept out.** All addons run in one Lua state with the same rights. Modules reach the data
  through the global `SaneUI`, so any other addon can reach it the same way; saved variables are globals
  too; any addon can register the prefix `SaneUI` and hear the guild's messages.
- **Encryption would not hold:** the key would have to ship in our code, which every addon and player can
  read; and Blizzard's policy forbids hiding or obfuscating an addon's code.
- **What can be protected is:** data from other players is checked before it is kept, and nothing we
  receive is ever run. Inside the game nothing can be shielded from another addon (it could change our
  tables as it could change Blizzard's).
- Shared messages are packed (to fit the budget, with a checksum), which makes them unreadable to the eye,
  not to an addon.

### Speed (measured)

Measured 2026-10-16 with Lua 5.1, the game's Lua, on Saneroki's computer (Ryzen 9 7950X): the real quest
database (`Tooltips/Data/Quests.lua`) and a made-up pack of 25,000 items written as the compiler would
write it. A slower computer takes perhaps two to three times as long.

| Step | Time | How often |
| --- | --- | --- |
| Load a pack (read and run the file) | about 8 ms for Quests (686 KB), 11 ms for 25,000 items (2 MB) | once a session, after the loading screen |
| First lookup of an entry (its string taken apart) | about 2.5 µs | once per entry a session |
| Every later lookup of it (kept) | 0.02 to 0.05 µs | every time |
| An entry's history taken apart | about 1.2 µs | when asked |
| Memory | 2.3 MB for Quests, about 3 MB for the 25,000 items | while loaded |

- A frame at 60 frames a second has 16,700 µs. A tooltip that asks for ten entries never asked before
  spends about 25 µs on data (0.15 % of a frame), and nothing measurable the next time. **Fetching data will
  not be felt in drawing a tooltip;** what is slow there is the drawing, not the data.
- The one cost that could be felt is loading a pack: 8 to 11 ms here, perhaps 30 ms on a slow computer,
  about two frames. So never in a tooltip and never in combat: packs load after the loading screen
  (`Prepare`), one a frame.
- A lookup of a kept entry makes no table and no garbage: the record is made once and kept, and so is a
  history once asked for.

## The game's own data

Saneroki (2026-10-16): the client's own data (items, skills, abilities, spells, talents, legacy points) goes
into our database too, so that its history can be kept and compared like the rest.

### Why, when the game already says it

- **History:** the client only knows today. Only our copy can say *armour 40 → 36 in 1.60.2*, or show a
  talent as it was before a patch.
- **Patch notes for free:** after a patch, a crawl and an import list every item, spell and talent Blizzard
  changed (`dev/tools/data diff --patch 1.60.2`), including what the patch notes leave out.
- **No waiting:** the client knows an item only once the server has sent it (`GetItemInfo` gives nothing for
  an item not seen yet). Our copy answers at once, so a window or tooltip never waits.
- **Search:** *every hands item with intellect*, *every rank of Frostbolt*, without asking the server.
- **Alts:** an alt's talents and legacy trees shown with names and ranks while playing another character.

**The game stays the ground truth (Blizzard fidelity):** where the running client answers, its answer is
what is shown, and our copy fills in the history, what the client has not loaded yet, and search. When the
two differ, the difference is learned for the next release.

### What is kept

| Set | What | From the game (to check each in the game) |
| --- | --- | --- |
| Items | Name, quality, kind, slot, levels, stats, armour, weapon damage and speed, sell price, effects, set | `C_Item` (`GetItemInfo`, `GetItemStats`), `C_TooltipInfo.GetItemByID` for effects |
| Spells | The players' spells and abilities, every rank: name, rank, description, cost, cast time, cooldown, range | `C_Spell` (`GetSpellInfo`, `GetSpellDescription`), `C_TooltipInfo.GetSpellByID` |
| Talents | Each class's tree: nodes, positions, links, ranks, the spell of each rank | `C_Traits` (`GetTreeNodes`, `GetNodeInfo`, `GetEntryInfo`, `GetDefinitionInfo`) |
| Legacy | Forever's three Legacy trees (professions 1187, adventure 1188, progression 1189, paid in legacy points, currency 4225), the challenges and the reward track | `C_Traits`; `C_MajorFactions` for the reward track; `LegacyConstantsDocumentation.lua` |
| Professions, SkillLines | Skills and their recipes (reagents, levels) | the profession window's API, while it is open |
| Currencies | Name, icon, cap | `C_CurrencyInfo` |
| CreatureSpells, Auras | Creatures' spells, and buffs from food, potions, items and the world: name, description, school, cast time, kind, duration (*Creatures*) | `C_Spell`, `C_TooltipInfo.GetSpellByID`, by the spell's ID |
| NPCs | A creature's level, rank, type, family, reaction, health, auras, casts: what the game shows out of combat (*Creatures*) | the unit API, `C_UnitAuras`, `UNIT_SPELLCAST_START` |

- **Only what players can have or meet:** creatures' spells and buffs too (*Creatures*), but no test items and
  no spell nobody meets. That keeps Items at about 25,000 entries (about 3 MB in the game, *Speed*) and the
  spells at some thousands.
- **Names and descriptions in English only** (Saneroki, decisions 7 and 22); numbers, IDs and structure are
  the same in every language. On a client in another language (`GetLocale()` not `enUS` or `enGB`) the
  watchers, the crawl and the patch check compare and learn numbers and IDs only, never text; a shared message
  carries the sender's language, and text from another language is dropped.

### How it is gathered

- **Learned on sight:** whatever the client shows in play (the item in a tooltip, the talent tree when it
  opens) is compared with the pack and noted if it differs (*Learned*).
- **The crawl,** on request: `/sane data crawl items` (spells, talents, legacy, currencies) asks the client
  for every entry of one kind, out of combat, within the frame budget (*Cost in the game*). What the client
  has in memory (spells, talents) goes fast; what it must ask the server for (items it has not seen) goes at
  a slow, fixed pace (*proposal* 10 a second: 25,000 items in about 45 minutes). It writes what it finds,
  with the build, into the pack's saved file; the harvest and the import do the rest, and a change since the
  last crawl becomes a new version by itself.
- **After every patch** one crawl of each kind is enough to keep the history complete.
- **Before our first crawl:** staged facts of older builds can fill in earlier versions (*Import*).

### The patch check: a new build at login

Saneroki (2026-10-16): when Sane UI loads, it compares the client's build with the last one it saw; on a newer
build it looks for what changed, during the loading.

- **The game cannot rewrite an addon's files;** an addon writes only its saved variables. So what the check
  finds goes into the learned data (*Learned*), tagged with the new build, and is **used at once**: `Get`
  gives the new value, `Changes` already lists it, a tooltip can say *Changed in 1.60.2*. The harvest and
  the next build make it lasting versions in the packs; for a player without our tools the learned data
  simply stays.
- **When:** `GetBuildInfo()` gives the build's number and version (*1.60.2*). Core keeps in `SaneUIDB` the
  last build each set was checked for (a few numbers). A set is checked when the client's build is newer
  than both its last check and the build its pack was made for: a pack made after the patch knows it
  already. Once per build and account, not per character. Both numbers are the client's own game
  version's (*Game versions kept apart*): a beta build never counts as a check for live.
- **During the loading, if switched on** (*Load client data on load*, on by default; *The switches*): at
  `PLAYER_LOGIN` the loading screen is still up, and nobody sees the frame rate. The check does one step
  there of at most 250 ms (*proposal*): the first login after a patch is that much longer, every other
  login is not. What does not fit goes on after the loading screen (`LOADING_SCREEN_DISABLED`) within the
  frame budget, out of combat. To see in the game: whether frames run while the loading screen shows; if
  they do, the check can use the whole loading screen with a bigger budget per frame.
- **Switched off:** nothing during the loading; the whole check runs after the loading screen, in the
  background within the frame budget.
- **In the order of what the client holds itself:**
  1. **Talents and legacy trees:** every node of every tree, read from the client (`C_Traits`). Complete:
     new and removed nodes are found too. Fast.
  2. **Spells:** every spell of the pack, the spellbook's and the trees': name, rank, description, cost,
     cast time, cooldown. Those the client still has to load (`C_Spell.IsSpellDataCached`) are asked for
     and compared when they arrive (`SPELL_DATA_LOAD_RESULT`).
  3. **Currencies** and the legacy reward track.
  4. **Items,** last and slowly, after the loading screen: those the client holds already
     (`C_Item.IsItemDataCachedByID`) at once, the rest at the crawl's pace, the player's own items and the
     alts' first. Spread over sessions if need be (the place reached is kept). New item IDs above the
     highest we know are probed (`C_Item.DoesItemExistByID`).
- **Estimated:** a few thousand spells and the trees are some 100 to 200 ms (to measure in the game), so
  they mostly fit into the loading step; items take their 45 minutes in the background.
- **Gone:** an entry the client no longer knows is noted as missing in that build, and called *gone* only
  after a second check agrees (data not loaded yet is no proof).
- **An empty answer is no fact:** nil, an empty text or a 0 from data the client has not loaded yet means
  *not known*, never a change and never *gone*. Each kind is read only once the client has it: the spells
  after the first `SPELLS_CHANGED`, the trees after `TRAIT_CONFIG_LIST_UPDATED`, a spell or item once it is
  cached (to check in the game which events come before the loading screen ends). This rule holds for
  every watcher and the crawl too.
- **The build itself is noted:** its version, number and first day go into the learned data and, with the
  harvest, into `builds.toml`. The game fills in the table of builds by itself.
- **What the player sees:** a chat message if switched on (*Chat messages*), and `/sane data`: *Patch
  1.60.2 found: 214 spells and 12 talents changed; items 34 % checked*.
- **A client older than the packs** (packs made for a later patch): no check; the packs answer with the
  versions that client has (*Versions*).
- **Shared:** what the check finds is offered to the guild once per set and patch (*Bundles*), so a guild
  checks each patch about once. What the game can check is checked by each receiver anyway (*Poisoning*).

## Live data

### Saved variables

- **Each pack declares its own saved variable** (`SaneUIData_Market`, `SaneUIData_Items`): the client loads
  it only with its pack, so months of auction history never slow a login that does not need them. Settings
  stay in `SaneUIDB`. Today only Core declares saved variables; the packs are Core's own, so this keeps the
  spirit, but it needs Saneroki's yes.
- Checked on load like settings: a format number with upgrade steps; a part of the wrong shape is set aside
  under `broken` (kept for the harvest to look at), never wiped.
- Packed in strings, not tables of tables: the client writes and reads it faster, and a big saved file
  cannot hit Lua's constant limit (which would lose the whole file).
- **A lost file:** Core notes in `SaneUIDB` how much each pack had saved. If a pack's data was there last
  session and is gone now (the file failed to load), Core warns at once, before the next logout writes over
  the client's `.bak` copy of it.

### Learned

- The database keeps only what differs from the pack, with the build and the day (`Learn`, inside Core).
  `Get` reads learned facts over the pack's.
- **While a pack is not loaded** (Saneroki, decision 19) its saved variable does not exist yet, and whatever
  Core put into that global would be overwritten when the pack loads. So what is learned for a set not
  loaded waits in a small, bounded inbox in `SaneUIDB` (the key and the changed fields), and moves into the
  pack's saved file when the pack loads. The same holds for discoveries and the patch check's findings.
  A watcher compares only against packs already loaded, and otherwise only notes the key: a watcher never
  loads a pack.
- When a release has taken it in (the pack now says the same), the learned entry is dropped at load: the
  learned part empties itself with every release.
- **Learned wins only while it is newer:** a learned entry is also dropped at load when the pack has a
  version of that entry at its build and day or later, whether the pack agrees or not: the release has
  seen that build and decided. So a wrong learned fact (a watcher's bug) cannot stand above the packs for
  ever.
- **A learned entry is a whole row** in the pack's format: the pack's row with what the game showed put in.
  `Get` then takes the learned row instead of the pack's, with no merging of fields.
- **Who learns: Core's watchers** (`Watch.lua`), small listeners for the moments the game shows something
  our data may lack or have otherwise (*When sharing makes sense*): a quest taken, a vendor, a trainer, a
  recipe, loot, a rare on the map. Each only compares and marks; the reading follows in steps within the
  frame budget. So discovery works whichever modules are switched on. An item or spell in any tooltip is
  compared too (`TooltipDataProcessor.AddTooltipPostCall`, once per entry a session): that is how the
  nerfed gloves are found by themselves. The tooltip is only the sign: what is compared is the plain item
  asked for by its ID (`GetItemInfo`, `GetItemStats`), never one link's own suffix, enchant or scaling
  (Saneroki, decision 23).
- **Modules do not learn** (Saneroki): they only read. Core also gathers through the crawl, the patch check
  (*The game's own data*), the characters' data (*Characters*) and **the full auction scan**: when the
  auction house opens, the database scans it (Economy's *How it runs*), whether Economy is switched on or
  not; Economy shows what it found. This moves the scan and its history from Economy's file list
  (`Doc/ideas/Economy.md`, *Files*: `Scan.lua`, `History.lua`) into Core's data framework.
- Only sets whose schema says `learn = true`.

### Series

- Per auction house (*Realms and regions*: region, realm, side): **today's points in a small table per
  item**, updated by every scan (own or shared); **at logout** today's point is added to
  the item's string for its month (one packed string per item and month). Measured: adding a point to one
  long string per item at every scan copies the whole history each time and grows slower by the month;
  this way a scan only touches today's tables, and logout touches strings of a month at most (about 17 ms
  for 6,000 items, during logout).
- **The server's day:** a day is the server's (`GetServerTime()`, days since 1970 in UTC), never the
  computer's clock (`time()`), so every character and every guild member counts the same day. The same
  holds for every time that is shared or kept across characters.
- **A saved file has Lua's constant limit too:** the client reads it as one function, so a file of more
  than 262,143 different strings and numbers loads as nothing and is written back empty. Every saved
  variable therefore keeps a budget (*proposal* 100,000 values), counted before logout; over it, the oldest
  detail is rolled up further (days into weeks, weeks into months). The packed strings keep it far below.
- **History is never lost.** The Market pack carries the last day its archive holds (`archivedTo`). Saved
  days older than the full-detail window (*proposal* 60 days) are dropped only once the archive has them.
  A player without our tools (no harvest) gets old days rolled into weeks in the game instead: less detail,
  never a gap.
- The harvest moves the scans into the master, so the repository is the archive and the saved file is the
  inbox.

### The beta's auction data: pruned once, by hand

Saneroki (2026-10-16): what the auction house gave during the beta is no market of the released game. On
1 November 2026 the auction history from before that day is pruned once, as a development step done with a
prompt: in the repository's master and in Sane UI's own saved files in the game's `WTF` folder. It is no
function of the addon, so nothing in the game or the tools checks the date.

## Characters

Saneroki (2026-10-16): Sane UI keeps what each of the player's characters has: bank and bags, and what they
posted at the auction house and when, so that every character can see its alts' things.

### What is kept, per character

Grouped by the moment the game lets Core read it:

| Moment | Read then | From the game |
| --- | --- | --- |
| **Login** (and again when it changes) | who the character is: name (`Core.FullName`), realm, class, race, level, faction, guild (`PLAYER_LEVEL_UP`, `PLAYER_GUILD_UPDATE`); quests done, for what a character still lacks (*Quests*) and *done on an alt* (`QUEST_TURNED_IN` adds one) | the unit API, `C_QuestLog.GetAllCompletedQuestIDs` |
| **While playing,** on the game's own event | gold, also as a series per day (`PLAYER_MONEY`); bags with counts (`BAG_UPDATE` marks a bag, `BAG_UPDATE_DELAYED` reads the marked); what is worn (`PLAYER_EQUIPMENT_CHANGED`); currencies with legacy points, reputations and renown (`CURRENCY_DISPLAY_UPDATE`, `UPDATE_FACTION`); the ranks of the talent and legacy trees (`TRAIT_CONFIG_UPDATED`); professions and skill levels (`SKILL_LINES_CHANGED`) | `GetMoney`, `C_Container`, the inventory API, `C_CurrencyInfo`, `C_Reputation`, `C_MajorFactions`, `C_Traits`, the profession API |
| **Only while a window is open** | the bank (`BANKFRAME_OPENED`, `PLAYERBANKSLOTS_CHANGED`); own auctions with count, price, when posted and time left (`OWNED_AUCTIONS_UPDATED`, `AUCTION_HOUSE_AUCTION_CREATED`); known recipes (the profession window) | `C_Container`, `C_Bank`, `C_AuctionHouse.QueryOwnedAuctions`, `GetOwnedAuctions`, the profession API |
| **As it happens** | the auction log: each auction posted, sold, expired, cancelled or bought, with its day and price (sold and expired seen as auctions leave the list; later also from the mailbox) | as above |
| *Later* | mailbox, lockouts, profession cooldowns | |

- **Account bank** once per account, not per character.
- **What things are** (an item's name, a talent's spell) is not kept here: only IDs and counts. The names
  come from the sets (*The game's own data*), so a character's data stays small.
- **Current, with a few records over time:** each list is the character's as last seen (with the time it
  was seen; a bank not opened for a week says so). History only where it tells something: gold per day,
  the auction log, legacy points per day. The log and the series are rolled up like the price history.

### Where and how

- **Its own saved variable,** `SaneUIData_Characters`, declared by the pack `SaneUI_Data_Characters`, which
  has no shipped data and is loaded soon after every login. Keyed by Core's character key (`Core.charKey`,
  the GUID: Forever names can collide).
- **Core reads it, not a module:** many modules show it (Tooltips' *20 on your alts*, Economy's bank and
  auction windows, later bags and a character sheet) and none owns it, so the reading lives with the
  framework (`Characters.lua`). It costs nothing a player would notice:
  - **mark, then read:** an event only marks what changed (a bag, the bank, the gold); the reading follows
    once, on the next frame or a moment later (`Core.Later`), a bag at a time, within the frame budget
    (*Performance*);
  - **nothing in combat:** marks wait for the fight to end;
  - **at logout** only what is still marked is read.
- **Packed like the rest:** a container is one string of `item:count` (and the item's string only where it
  is not the plain item: suffix, enchant).
- **Counts across characters** are worked out once when first asked and kept up to date as lists change, so
  an item's tooltip asks one table.

```lua
Data.Characters()             -- every character of the account: key, name, realm, class, level, seen
Data.Character(key)           -- one character: gold, bags, bank, auctions, professions, ... (read-only)
Data.Count(item)              -- { [key] = { bags = 12, bank = 8, auctions = 20 }, total = 40 }
Data.AuctionLog(key, fromDay) -- the character's auction log
```

### Private

- **Never shared:** sharing sends prices only (*Sharing in the game*); character data never leaves the
  computer.
- Only the characters of this WoW account: the game keeps saved files per account, so characters on another
  WoW account of the same Battle.net login are not seen.
- **A character deleted** in the page *Profiles* (its list of characters) loses its data too; one not seen
  for a long time is shown as such, never removed by itself.

## Discoveries and notices

Saneroki (2026-10-16): the database, not the modules, tells about changes. Modules only read: an entry, its
full history or its last few versions. Checks, writes, sharing and chat messages are the database's job.

### Discoveries

- A **discovery** is every accepted change to the player's data: a new entry, a changed field, an entry
  gone, a drop chance that changed with a build, new auction house prices. Each notes the set, key, build,
  day, what changed (from, to) and how it came: the patch check, the crawl, a watcher, a scan, or shared and
  accepted (*Poisoning*).
- Kept in a short list (`Found.lua`) in the saved file of the set's pack, bounded (*proposal* the last 90
  days; the versions keep the rest for ever).

### Chat messages

- **Only when switched on** (*The switches*: *Chat message for new data changes*, *Chat message for new
  auction house data*, both off by default), and **only when data was accepted and changed something**.
- Made by the database for every module's data; no module prints anything about data.
- **One line, summed up:** *Sane UI data: 3 new quests, 12 changed items (1.60.2), drop chances of 40
  creatures updated. [Details]*. The first change is told at once; after that at most one line every 15
  minutes per kind, with everything accepted since. Never in combat (held until after).
- *[Details]* prints what `/sane data` shows (an addon link, `|Haddon:SaneUI:data|h`, which the client hands
  to `EventRegistry`'s `SetItemRef`; local only).
- **Nothing about guild members:** a shared quest is the quest (title, objectives, rewards, giver, where),
  not who found it or what anybody did. The senders' names stay inside the checks against poisoning and are
  never shown.

### What modules read

```lua
Items:Get(16801)              -- the current version
Items:History(16801)          -- every version
Items:Versions(16801, 3)      -- the last three versions
Items:Changes(16801)          -- what changed, when
Items:Stamp()                 -- a number that grows with every accepted change: redraw if it moved
Data.Found(fromDay)           -- the discoveries (for a view of them, such as a Library module)
```

A module with a view of discoveries and history (a *Library*) only reads these.

## Drop rates and gathering

Saneroki (2026-10-16): the database learns how likely an item drops from which creature, at which level, and
what gathering herbs and ore gives: a growing accumulation of every sharing player's loot. If 200 guild
members loot 2,000 wolves and 1,000 of them had meat, the chance is 50 %.

### What is counted

- **Loot of a creature** (`LOOT_OPENED`; the corpse's GUID names the creature): one *loot* for the creature,
  one *drop* for each item in it, with its count. Each corpse counts once (its GUID is remembered a while).
  The creature's level as seen (target, mouseover, nameplate): the lowest and highest.
- **Gathering:** herbs, ore, skinning: one *gather* for the node (or creature), and what it gave; fishing
  per zone.
- **Items a quest objective asks for** count only while the looting player has the quest (they do not
  drop otherwise), so their chance is the chance for those on the quest.
- **Items that start a quest** count always, whether the player has the quest or not (Saneroki): the item
  itself is what starts the quest, so its chance is everybody's.
- **Chance = drops ÷ loots,** per corpse looted, not per kill: kills cannot be counted (the combat log is
  closed to addons), and a corpse with nothing on it is never opened. Kills that were not looted say
  nothing and are not counted. A view says *per corpse looted*.
- *To check first in the game:* `GetLootSourceInfo` (the corpse's GUID for each loot slot) is in neither the
  client's code nor its API documentation in `references/`. Without it the corpse is not known for sure,
  and nothing is counted: the creature is never guessed from the target.
- **Where, and for which quest:** each loot also notes its place and the creature's quests (*What every kill
  teaches*).

### Build periods

- Counts are kept **per build period** (from one build to the next).
- **Shown from the whole history by default** (Saneroki): all periods together, the most data and the
  steadiest number. One period alone on request.
- **Shared per build period:** members share their counts of the current period (*Bundles*).
- **On a new build** the patch check compares the last period with the one before. A chance that changed
  considerably (enough loots on both sides, *proposal* 100 each, and a clear difference: a two-proportion
  test with |z| above 3 and at least a fifth up or down) is a discovery: *Wolf Meat from Prowlers: 50 % →
  30 % in 1.60.2*.
- **After such a change the whole history starts at that build** (Saneroki, decision 13): for that creature
  and item, *the whole history* means the periods from the build of the change on, so the chance shown is
  the new one at once and not a blend with the old. The older periods stay kept and can be shown alone.
- **Merged to stay small:** the last three periods stay apart for comparing; older ones are merged into one
  *earlier* count per creature and item. An item seen very rarely (*proposal* under 3 drops in all) is kept
  but given no chance until there is more.
- Estimated size: a few thousand creatures, about ten items each: under 1 MB in the World pack's saved
  file. To measure.

```lua
local Drops = Data.Drops()
Drops:Chance(creature, item)              -- the whole history: chance, drops, loots
Drops:Chance(creature, item, "period")    -- this build period only
Drops:From(item)                          -- who drops it (creatures, nodes), best chance first
Drops:Of(creature)                        -- what it drops, with chances, and its levels
```

### What every kill teaches

Saneroki (2026-10-16): the loot that is counted for the drop chances also tells where the creature was and
which quests it belongs to, so the map grows more detailed with every kill and the database learns the game
over time.

- **Where:** each loot notes the place, the player's at `LOOT_OPENED` (within looting range of the corpse),
  as a cell (*Area*): per creature and map, a count per cell, with the creature's level there. Many kills
  make a map of where the creature is found and fought, and its area grows from it (*Places on the map*,
  from play). A corpse lies where the fight ended, near its spawn point rather than on it, so kills fill
  areas; points come only from what is seen within a few yards (gathering, talking).
- **For which quest:**
  - **The game says it** out of combat: a creature under the mouse or on a nameplate that belongs to a quest
    in the log has the quest's title and its objective in its tooltip (`C_TooltipInfo.GetUnit`, lines of
    the kinds `QuestTitle` and `QuestObjective`; `C_QuestLog.UnitIsRelatedToActiveQuest(unit)`). *To try:*
    whether the line carries the quest's ID, or its title must name it.
  - **The count goes up:** a kill objective's count rises (`QUEST_WATCH_UPDATE`; in a fight only noted, one
    table write) and the creature looted next is the one, if the objective's text names it.
  - **Loot for a quest:** an item an objective asks for, dropped by it (*What is counted*).
  - Each link is a quest relation: the creature in the quest's objective (*Quests*), and the quests of a
    creature as an index (`Quests:For(creature)`). A new or different one is a discovery.
- **Counted like drops:** per character and build period, shared in the bundle (*Bundles*): cells and counts,
  no time, never anybody's route.
- **Bounded:** per creature and map at most a few hundred cells (*proposal*); a cell looted once is kept, but
  takes part in the area only after a second loot there (a long chase is no spawn place).

## Quests

Saneroki (2026-10-16): a quest's entry holds what is needed to find it, take it and finish it: its name, its
objectives, its stages, its place in a chain and the breadcrumbs that lead to it, who gives it, what a
character needs before it is offered, where each step is done, and the areas on the map where its
objectives are found.

### What a quest holds

| Field | What | In today's `Quests.lua` |
| --- | --- | --- |
| `name` | The title | yes |
| `level`, `minLevel`, `maxLevel` | The quest's level; the levels it is offered from and up to | yes |
| `side`, `races`, `classes` | Who it is offered to | yes |
| `requires` | Quests done before (all of them, or one of them), quests that lock it out, a reputation and its standing, a profession and its skill, an item to carry | quests only |
| `start` | Who offers it: an NPC, an object, or an item that starts it | in the NPC records (`g`, `s`) and item records (`b`) |
| `finish` | Who takes it back: an NPC or an object | in the NPC records (`t`) |
| `objectives` | In order, each: its kind (kill, loot, use an object, explore, talk, an event), what (a creature, item or object), how many, the game's text, its stage | loot ones only, in the NPC (`d`) and item (`n`) records |
| `next`, `breadcrumbTo` | The next quest of its chain; the quest a breadcrumb leads to | only as closing it (the rule's `!`) |
| `line` | The game's quest line, where it has one: its number and name | no |
| `rewards` | Money, experience, items (all, or one to choose), reputation, spells | no |
| `kind` | Elite, group (with its size), dungeon, raid, class quest, daily, repeatable; still offered or not any more | no |

- **Places are not copied into the quest.** Givers and takers are references to NPCs and Objects, and where
  they stand is theirs (World, Spawns); an item that starts a quest is found where it drops (*Drop rates and
  gathering*). A giver that moved is changed once, and every quest of it follows.
- **Only one side of a link is written,** as with `replaces`: `next`, `breadcrumbTo` and `requires`. The compiler
  adds the other side as indexes: the quest before, the breadcrumbs that lead to a quest, the quests a
  quest opens.
- Every field has versions like any other (*Versions*): a quest whose requirements, rewards or area changed in
  a patch keeps both.

### Chains, stages and breadcrumbs

- **A chain** is what the links make: the compiler follows `next` and `requires`, gives every chain a number
  and puts its quests in order (an index). Where the game names a quest line (`C_QuestLine`), its name and
  order win.
- **Stages** are the steps inside one quest: objectives that show one after the other, the next when the one
  before is done. Each objective carries its stage; a quest of one step has all its objectives at stage 1.
- **A breadcrumb** sends the player to another quest's giver, and is usually closed once that quest is
  taken; `breadcrumbTo` says which quest.

```lua
local Quests = Data.Set("Quests")
Quests:Get(quest)              -- name, levels, who, requires, start, finish, objectives, rewards, kind
Quests:Chain(quest)            -- the chain in order, its name, and this quest's place in it (part 3 of 5)
Quests:Before(quest)           -- every quest that must be done first, as a tree
Quests:Breadcrumbs(quest)      -- the quests that lead to it
Quests:From(npc|object|item)   -- the quests it starts, and those it takes back
Quests:For(creature|item|object) -- the quests whose objectives ask for it
Quests:Missing(quest, key)     -- what a character still lacks (level, quests, reputation, skill); nil: none
```

`Missing` reads the character's data (*Characters*), which keeps the completed quests for that
(`C_QuestLog.GetAllCompletedQuestIDs`). It is a reading, so every module that asks *can this character take
it?* gets the same answer.

### Requirements: shipped, checked by the game

- The game tells an addon nothing about what a quest requires before it is offered, so the requirements
  ship with our quest data (prompt 2).
- **The game proves a requirement wrong when it offers the quest anyway:** the quest offered
  (`QUEST_DETAIL`), or in an NPC's list (`C_GossipInfo.GetAvailableQuests` at `GOSSIP_SHOW`,
  `QUEST_GREETING`) or in `C_QuestLine.GetAvailableQuestLines`, at level 8 when our data says from 10, to a
  race or class our data leaves out, or without a quest our data says must be done first. Each is a
  discovery: the level is narrowed to 8, the wrong prerequisite removed.
- **Not offered when our data says it should be** proves less: a requirement our data lacks, or a quest the
  NPC stopped giving. It is noted as a doubt, and becomes a discovery (*a requirement is missing*, *not
  offered any more*) only when several characters (*proposal* 3) saw the same.
- The check uses only the observing character's own state. What is shared is the conclusion (*quest 123 is
  offered from level 8*), never which quests anybody did.

### Where the steps are

Each objective's places are known three ways, the game's first:

1. **The game,** for the quests in the player's log: `C_QuestLog.GetQuestsOnMap(map)` gives where the game's
   map pin of a quest stands (its next step, or its taker once it is done), `C_QuestLog.GetNextWaypoint` the
   way to another map. Noted per objective and stage as they come.
2. **The data:** the spawns of an objective's creatures and objects (Spawns), the creatures that drop its
   items (Drops), an *explore* objective's point (map, x, y and radius).
3. **Play:** where an objective's count went up (`QUEST_WATCH_UPDATE`), the player's place on the map at
   that moment, rounded to a cell (*Quest areas*).

### Quest areas

What the game draws on its map as a quest's area, the shaded patch that says *the creatures this quest needs
are somewhere in here*. Our data keeps them for every quest, not only those in the player's log.

- **One area per objective, stage and map, as cells:** a map is cut into 100 × 100 cells, and an area is the
  cells it covers, stored as runs per row (row, first cell, last cell). An area a tenth of the map wide is
  about ten runs. Areas known several ways merge by adding their cells, a point is tested with one look,
  and a view draws the runs or a soft glow at the area's middle (Navigation's plan); the middle and size are
  stored beside the runs for that.
- **Made by the compiler** from the objective's places in the data: each spawn point marks the cells around
  it (*proposal* within 3 % of the map), and marked cells that touch form one area, so a camp and a far
  cave of the same creature stay two areas without any distance chosen by hand.
- **The game's own area, where it can be read.** The client draws the area of a quest in the log itself
  (`QuestBlobPinTemplate`, a `QuestPOIFrame` with `SetMapID` and `DrawBlob(questID, true)`) and gives an
  addon no outline. But it answers whether a point is inside: `UpdateMouseOverTooltip(x, y)` gives the quest
  under a point of the map. A hidden frame of our own can ask that for every cell (10,000 questions for a
  map, in steps within the frame budget, out of combat, once per quest, stage and map), and so reads the
  game's own area exactly. *To try in the game:* whether a hidden frame of our own answers. If it does, the
  game's area replaces the computed one.
- **Learned in play:** a cell where an objective's count went up is added when it lies outside the area.
- **A set of its own, `QuestAreas`, in the pack Spawns:** only the map needs it, and it is the biggest part of
  the quest data, so it loads with the first map opened, not with the tooltips. Estimated well under 1 MB for
  4,800 quests (to measure).

```lua
local Areas = Data.Areas()
Areas:Of(quest)                -- per objective and stage: map, runs, middle, size, and from where (game, data, play)
Areas:Here(map, x, y)          -- the quests and objectives whose area holds this point
```

### What the game tells, and when

All through Core's watchers (*Learned*); a quest that differs from the data is a discovery and goes into the
bundle when sharing is on (*Bundles*).

| Moment | Event and API | What it adds |
| --- | --- | --- |
| An NPC's list of quests | `GOSSIP_SHOW` (`C_GossipInfo.GetAvailableQuests`, `GetActiveQuests`), `QUEST_GREETING` | Who gives and takes which quest; offered to this character (*Requirements*) |
| A quest offered | `QUEST_DETAIL` (`GetQuestID`, `GetTitleText`, `GetObjectiveText`, the rewards), the NPC or object (`UnitGUID("npc")`) or the item used | Name, giver or starting item, rewards |
| Taken | `QUEST_ACCEPTED`: `C_QuestLog.GetQuestObjectives`, `GetInfo`, `GetQuestTagInfo`, `GetSuggestedGroupSize` | Objectives (text, kind, how many), level, kind |
| A count goes up, a new objective shows | `QUEST_WATCH_UPDATE`, `QUEST_LOG_UPDATE`; `C_Map.GetBestMapForUnit`, `C_Map.GetPlayerMapPosition` | Places, stages, areas |
| On the map | `C_QuestLog.GetQuestsOnMap`, `GetNextWaypoint`; the area test | The game's places and areas |
| Handed in | `QUEST_COMPLETE`, `QUEST_TURNED_IN` (quest, experience, money), the NPC | Taker, the rewards given |
| The next one offered | `QUEST_DETAIL` from the same NPC right after a hand-in | `next` |
| Quest lines | `C_QuestLine.GetAvailableQuestLines(map)`, `GetQuestLineInfo`, `GetQuestLineQuests` | A chain's name and order, where it starts. *To try:* whether Forever's zones have quest lines at all |
| Any time | `C_QuestLog.RequestLoadQuestByID`, `GetTitleForQuestID` | That a quest exists, its title |

- **Shared as general knowledge:** the quest's facts, an area's cells, a narrowed requirement; never who, when
  or in which order (*What is shared*).
- **Checked like everything shared** (*Poisoning*): that it exists and its title by the game; its objectives
  and the game's own area by the game when the receiver has the quest in its log; giver, rewards, places,
  requirements and chain by three senders.

## Creatures

Saneroki (2026-10-16): the database keeps what is known about every creature: where it stands and can spawn,
what it drops and how likely, what it casts, its stats, its buffs.

### What a creature holds

Set *NPCs*, keyed by creature ID, pack World:

| Field | What |
| --- | --- |
| `name`, `title` | Its name, and the line under it (*Repair Merchant*, *Innkeeper*) |
| `level` | The lowest and highest level seen; a boss (`??`) |
| `rank` | Normal, elite, rare, rare elite, boss (`UnitClassification`) |
| `type`, `family` | Beast, humanoid, undead, ...; wolf, cat, ... (what can be skinned follows from it) |
| `reaction` | Friendly, neutral or hostile, per side (`UnitReaction`), and its faction |
| `stats` | Health and mana per level seen (`UnitHealthMax`, `UnitPowerMax`); armour, resistances, damage and attack speed where our data has them (the game gives an addon those for the player and pets, *to try* for others) |
| `abilities` | The spells it casts (references to *CreatureSpells*) |
| `auras` | The buffs it carries at rest (references to *CreatureSpells* or *Auras*) |
| `services` | Vendor, repair, innkeeper, class or profession trainer, flight master, banker, auction house, stable master, battlemaster, spirit healer, ... |
| `respawn` | How long it takes to come back, where known (rares) |

Kept elsewhere and joined by the creature's ID: what it drops, is skinned for and pickpocketed for (*Drop
rates and gathering*), where it spawns and walks (*Places on the map*), the quests it gives and takes back
(*Quests*).

### Its spells and the buffs

- **The game knows every spell by its ID,** not only the players': `C_Spell` and `C_TooltipInfo.GetSpellByID`
  give a creature's spell or a buff's name and description out of combat (after `C_Spell.RequestLoadSpellData`).
  So these are the game's own data like the players' spells: checked, crawled, and kept with their history
  (*The game's own data*).
- Two sets beside the players' *Spells*:
  - *CreatureSpells* (pack World): what creatures cast and the auras they carry or put on others: name,
    description, school, cast time, range, and for an aura its kind (magic, poison, curse, disease) and
    duration.
  - *Auras* (pack Spells): buffs and debuffs that are no player spell and no creature's: food, potions,
    elixirs, item effects, world buffs.
- `Data.Spell(id)` asks *Spells*, *Auras* and *CreatureSpells* in turn, so a tooltip need not know whose
  spell it is.

### What the game shows, and what it hides

- **Out of combat** the game answers about a creature in the target, under the mouse or on a nameplate: its
  name, level, rank, type, family, reaction, health, its auras (`C_UnitAuras.GetAuraDataByIndex`), and a
  cast it starts (`UNIT_SPELLCAST_START`, `UnitCastingInfo`). A creature fighting someone else while the
  player is not in combat shows its casts too.
- **In combat it hides most of it:** this client gives addons casts, auras, health and stats as secret values
  while a restriction is active (`C_RestrictedActions.IsAddOnRestrictionActive`: combat, an encounter, a
  rated match; `ADDON_RESTRICTION_STATE_CHANGED`), and the combat log is not for addons
  (`COMBAT_LOG_EVENT_UNFILTERED` is restricted; Blizzard reads it through its own `C_CombatLogSecure`). That
  fits *nothing in combat* anyway.
- So the watchers look at creatures only while no restriction is active, every value goes through
  `Core.Plain`, and a secret one is skipped, never stored or compared.
- **Cheap:** a nameplate or a mouseover costs one table look (the creature's ID, seen this session or not);
  each creature is read once a session, in steps within the frame budget.
- **Abilities come mostly from the shipped data** (prompt 2), and the game checks each spell's facts by its ID.
  Play adds what it sees out of combat: a cast, an aura, the health at a level.
- **A module cannot look a cast up in a fight** either: the spell's ID is a secret then. Creature data is for
  before and after a fight: the tooltip of a creature under the mouse, the map, a view of creatures.
- *To try in the game:* what Forever's open world hides (it may hide less than the newest dungeons), and
  whether a creature's health is plain out of combat.

```lua
local NPCs = Data.Set("NPCs")
NPCs:Get(creature)          -- name, title, levels, rank, type, reaction, stats, abilities, auras, services
Data.Spell(spell)           -- a spell of anybody: the players', an aura, a creature's
Data.Drops():Of(creature)   -- what it drops, with chances (*Drop rates and gathering*)
Data.Map():Spawns(creature) -- where it spawns (*Places on the map*)
```

## Places on the map

Saneroki (2026-10-16): the database keeps the map's things: where creatures spawn, and the places of chests,
rares, herbs and ore, quests, trainers, repair, inns and every other NPC with a service.

### What is kept

| Set | Keyed by | Holds | Pack |
| --- | --- | --- | --- |
| *Spawns* | creature or object ID | Its spawn points per map (map, x, y) and its spawn area (an *Area*) | Spawns |
| *PatrolPaths* | creature | The path it walks | Spawns |
| *Objects* | object ID | Name, kind (chest, herb, ore, mailbox, quest object, book), the skill it needs (herbalism 150); what it gives is in *Drops* | World |
| *Places* | our own number | What is no creature or object: zone crossings, cave entrances, piers, dungeon entrances | World |
| *NPCs* | creature ID | `services`: which NPCs are trainers, repair, inns, ...; where they stand is their *Spawns* | World |

- **One shape for every area:** quest areas, spawn areas and herb or ore areas all use the same cells
  (*Quest areas*), the same merging and the same point test (`Areas.lua`).
- **One list per map:** the compiler also writes, per map, every thing on it (kind, key, point), so a map view
  gets all pins of a map with one look, not by walking every creature.

### How each kind is known

| Thing | Shipped (our data) | From the game, in play |
| --- | --- | --- |
| NPCs with a service (trainer, repair, inn, vendor, banker, flight master, stable master, auction house, battlemaster) | spawn points, service flags | Talking to them (`GOSSIP_SHOW`, `MERCHANT_SHOW` with `CanMerchantRepair`, `TRAINER_SHOW`, `TAXIMAP_OPENED`, `BANKFRAME_OPENED`, ...): the service, and the place: the player's, a few yards off |
| Flight points | | `C_TaxiMap.GetTaxiNodesForMap(map)`: every flight point of a map with its exact place, known or not, at any time |
| Rares and treasures | spawn points, respawn | `VIGNETTES_UPDATED`: `C_VignetteInfo.GetVignetteInfo` (the rare or chest, by its GUID) and `GetVignettePosition`: its exact place, while it is near |
| Herbs and ore | spawn points | Gathered (`LOOT_OPENED`; the node by the loot's source): the player's place, a few yards off |
| Chests | spawn points | Opened (loot from an object), and their vignettes |
| Creatures | spawn points | Where looted (the corpse lies near where it stood) or talked to. A creature only targeted is too far away to place: the game gives a unit's position only for group members. |
| Quest givers, objectives, quest areas | *Quests* | *Quests* |
| The game's own points | | `C_AreaPoiInfo.GetAreaPOIForMap`, `C_Map.GetMapLinksForMap`; dungeon entrances (*to try* in Forever) |
| Mailboxes, meeting stones, spirit healers, zone crossings | *Places* | *Later* (Navigation's routes) |

- **Precision:** a place seen from a few yards (talking, looting, gathering) is rounded to a tenth of a cell;
  within a cell of a known spawn point it is that point (*Keys*), farther away it is a new one: a discovery.
- **Spawn areas** are made like quest areas: the points grouped, the cells around them. A rare's area is
  where it can spawn (Navigation draws it on a click).
- **Shared and checked** (*Poisoning*): flight points by the receiver's own game (`C_TaxiMap`); every other
  place by three senders, or by the receiver's own sighting. A place is shared as the thing's, rounded, with
  no time: never where a member was.

```lua
local Map = Data.Map()
Map:Spawns(creature|object)    -- points and areas per map
Map:On(map, kinds)             -- everything of these kinds on a map: the pins
Map:Services(map, "repair")    -- every NPC with that service on a map, with its places
Map:Near(map, x, y, kinds)     -- what is near a point, nearest first
```

## Sharing in the game

Saneroki (2026-10-16): players who use Sane UI share general game knowledge, so that everybody's database
stays up to date: auction prices, discoveries (a new quest with its objectives, rewards, giver and place; a
changed item) and drop and gathering counts. A switch lets anybody opt out.

**With the guild, the party and the raid** (Saneroki, decision 9). The pages below speak of *the guild*
where the design was first written for it; each such rule holds for the party and the raid the same way,
each a channel of its own. Still to work out when sharing is built (step 1f): a member in both the guild and
a group hears a transfer once; a scan goes once per auction house and 15 minutes over all channels together;
a group of strangers (a group found by the game's finder) weighs less than the guild (*Poisoning*).

### What the game offers

- `C_ChatInfo.SendAddonMessage(prefix, text, chatType, target)` sends hidden messages to the addons of other
  players that registered the same prefix (`C_ChatInfo.RegisterAddonMessagePrefix`); they arrive as
  `CHAT_MSG_ADDON` (prefix, text, channel, sender). Channels: guild, party, raid, whisper, a custom channel.
  Nothing shows in chat.
- **Limits:** a message holds at most 255 bytes (to check in the game), text without a zero byte (a C
  string: packed data is made text first, `C_EncodingUtil.EncodeBase64`, a third bigger). Each prefix has
  a budget the server keeps and does not publish: Blizzard's own queue for its commentator messages
  (`Blizzard_CooldownBroadcaster/MessageQueue.lua`) plans with 10 messages at once, then one a second, a
  safe start. Every send answers whether it was too much (`AddonMessageThrottle`, `ChannelThrottle`), and
  the queue slows down when it does.
- **Lockdown:** `C_ChatInfo.InChatMessagingLockdown()` says when the game's restrictions on chat messages
  apply (a send then answers `AddOnMessageLockdown`); meanwhile a received text may be a secret value.
- The client packs with a checksum (`C_EncodingUtil.CompressString`, method *Zlib*): a damaged or incomplete
  transfer fails to unpack instead of giving wrong prices.

### What is shared

| Kind | What | How often |
| --- | --- | --- |
| Auction prices | Per item of a full scan: lowest price, market price, units, auctions; the scan's time and auction house | One scan per auction house in 15 minutes, for the whole guild (*Scans*) |
| Discoveries | General game knowledge our data lacked or had otherwise (table below) | In each member's bundle, at most one in 15 minutes (*Bundles*) |
| Counts | Loots and drops per creature, gathers and yields per node, where (cells) and for which quest (*What every kill teaches*), of the current build period | In the same bundle |
| Patch findings | What a patch check found | One bundle per set and patch for the whole guild |

What the game shows while playing, and Core's watchers notice (*Learned*):

| Situation (watcher) | General knowledge it may add |
| --- | --- |
| A quest offered, taken, handed in (`QUEST_DETAIL`, `QUEST_TURNED_IN`) | The quest: title, level, objectives and stages, rewards, giver and taker (name, place) or the item that starts it, its chain, a requirement the offer proved wrong, its areas (*Quests*) |
| Talking to an NPC (`GOSSIP_SHOW`) | Where it stands, its services |
| A vendor (`MERCHANT_SHOW`) | Its goods, prices, stock, costs in other currencies |
| A trainer (`TRAINER_SHOW`) | Its services, costs, levels and skills needed |
| A flight master (`TAXIMAP_OPENED`) | Flight points and costs |
| Crafting (`TRADE_SKILL_SHOW`) | Recipes, reagents, skill ranges, tools, cooldowns |
| Loot, gathering (`LOOT_OPENED`) | Counts (*Drop rates and gathering*); a new drop; herb and ore places |
| Rares and treasures on the map (`VIGNETTES_UPDATED`, `C_VignetteInfo`) | Their spawn places |
| A creature in the target, under the mouse or on a nameplate, out of combat (*Creatures*) | Its level, rank, type, reaction, health, buffs, the casts it starts |
| A map's flight points (`C_TaxiMap.GetTaxiNodesForMap`) | Their places (*Places on the map*) |
| An item or spell in any tooltip (`TooltipDataProcessor.AddTooltipPostCall`) | An item or spell that differs from ours |
| The patch check, the crawl | Whatever changed in a new build |
| A full auction scan | Prices |
| *Later:* mailboxes, spirit healers, meeting stones, zone crossings | Places (Navigation's routes) |

**Never shared:** anything of the player's own (characters, bags, bank, gold, own auctions, where the player
is, chat), and nothing of what a member did (whom it talked to, which quests it did): a discovery is the
game's fact, not the player's story.

### Scans

One prefix, `SaneUI`, for everything Sane UI sends. Every message starts with its kind and the protocol
number; a kind or number we do not know is ignored.

1. **Have:** a player finishes a scan and tells the guild in one message: *I have the prices of this auction
   house from this time* (with the size), unless the guild had a transfer of that auction house in the last
   15 minutes.
2. **Want:** a member who may take one now answers *want*, in the guild, after a random wait of up to three
   seconds, so that not everybody answers in the same moment. One *want* is enough: the others who want it
   hear it during their wait and stay quiet. A member took one in the last 15 minutes, or scanned itself:
   it does not want.
3. **Data:** if anybody wants it within a few seconds, the scan is sent once to the whole guild in **blocks of
   250 items**, each block packed by itself and cut into numbered parts, at the pace the budget allows.
   Whoever wanted it takes each block in as soon as its parts are there; the rest ignore the parts.
4. **At login** a member first listens for a minute (a transfer may be running: it rides along). If none
   came, it asks the guild once *who has prices newer than mine?* The holders wait a random second or two;
   the newest answers with a *have*, the others hear it and stay quiet. Then as above.

- With 200 members scanning, the guild still sees at most one transfer per auction house in 15 minutes; a
  member who scans within 15 minutes of the last transfer keeps its scan for itself.
- Two members who scanned at the same time: the newer scan goes on, the older one stops when it hears of it.
- **Best effort:** a lost part costs only its block; a transfer with no new part for two minutes is ended.
- Nothing is sent in combat or during a lockdown: the transfer waits and goes on after.

### Bundles

- **Gathered for 15 minutes, then shared** (Saneroki): each member collects its discoveries and counts for 15
  minutes and then sends them as one bundle (once in 15 minutes is plenty for most limits): a small one in
  a message or two, a big one in blocks like a scan.
- **Scans once per guild, counts per character** (Saneroki): an auction scan goes out once per auction house
  and 15 minutes for the whole guild, but drop and gathering counts come from every character, each in its
  own bundle: every character's loot adds to the chances.
- Before sending it strikes what it already heard from others (the same fact is the same text), and it
  listens before talking (*Limits*).
- Counts are the sending character's totals of the build period: a newer total replaces the older one of
  the same character, so nothing is counted twice. The player's own characters' counts are kept per
  character the same way and summed with the rest.
- A patch check's findings go once per guild, set and patch, with *have* and *want* like a scan.

### Limits

Saneroki: sending to 200 guild members or hearing from 200 of them in a short time must not be felt. One guild
message reaches every member, so sending costs the same for 2 or 200; what is held back is the number of
messages, so the guild's traffic does not grow with the guild.

| Limit | *Proposal* |
| --- | --- |
| The database's work in a frame, all of it together, by the clock (*Performance*) | at most 5 ms and a quarter of a frame, out of combat; none in combat |
| Scans, for the whole guild | one per auction house in 15 minutes |
| A member's own bundle | one in 15 minutes |
| Bundles taken from one sender | one in 15 minutes; more is a strike |
| Messages taken from one sender | 90 a minute (an honest sender sends 10 at once, then one a second: about 70 in its first minute); more and it is ignored for 10 minutes |
| Shared counts kept per sender (*Poisoning*, 6) | the current build period only, *proposal* 5,000 cells a sender and 100,000 in all; at a new build they are checked, summed into one count and the senders' parts dropped |
| The guild busy (Sane UI messages heard in the last 10 seconds) | above 4 a second, a member holds its own bundle |
| Transfers at a time in the guild | one |
| The inbox | 1,000 messages; more is dropped (what matters comes again) |
| Facts waiting for a check (*Poisoning*) | 2,000; per sender 200 |
| Facts already heard, remembered | some days |

- **In the event, only the least:** the prefix checked (another addon's message ends there), the text put
  into the inbox. Measured with Lua 5.1 on Saneroki's computer: 0.08 µs a message; a storm of 200 members each
  sending its burst of 10 in the same frame (2,000 messages) costs our code 0.16 ms in that frame.
- **Taken in later, in steps** within the frame budget, out of combat (in combat the inbox only holds).
  Measured: the 1,000 messages of that storm took 0.83 ms in all.
- **Known facts cost one table look:** the fact's text is its own key.
- With bundles once in 15 minutes, even 200 members send under one bundle every 4 seconds on average.
- What the client itself spends handing each message to the addons cannot be changed by us; few messages
  keep that cost small too.

### Poisoning

Saneroki: someone could write an addon or a script that speaks like ours, to poison or break everybody's
database. The answer: trust no message, and let the game decide wherever it can.

**What cannot work:** a secret key or a signature. Our code is readable by everybody (and must be, by
Blizzard's policy), so a key in it is no secret, and a copy of our addon can send whatever ours sends. Every
message is treated as possibly hostile, whichever addon it seems to come from.

**What works, in layers:**

1. **Only the guild, the party and the raid** (decision 9). Shared data is taken only from those channels.
   The server puts the sender's name on every message and the sender cannot change it: an attacker has to
   be a member of the guild or the group, and is then one known name. A party or raid can hold strangers, so
   for the rules of several senders (5) a sender known only from a group counts less than a guild member (how
   much: decided in step 1f, tuned in the game).
2. **Strict shape.** Strict reading; sizes capped before and after unpacking (the client's unpacking has no
   limit of its own, so the packed block is capped first, *proposal* 4 KB, and zlib cannot make more than a
   few MB of that); every fact checked against its set's schema (kinds, ranges, references). Anything off
   is dropped, with a strike for the sender. A fact of a build newer than the receiver's client waits until
   the client has that build (layer 4), and is dropped after 14 days.
3. **Quarantine.** Shared data never goes into the player's data directly. It waits apart, kept per sender,
   and `Get` does not give it until it is accepted. Everything one sender ever sent can be removed at once.
4. **The game decides where it can.** Most facts the receiver's own game can check:

   | Fact | Checked with |
   | --- | --- |
   | An item's stats, sell price, levels, effects | `C_Item` (`GetItemInfo`, `GetItemStats`), `C_TooltipInfo.GetItemByID`, after `RequestLoadItemDataByID` |
   | A spell's name, rank, description; a creature's spell or a buff the same way | `C_Spell` (`DoesSpellExist`, `GetSpellDescription`) |
   | A flight point's place | `C_TaxiMap.GetTaxiNodesForMap` |
   | A talent or legacy node | `C_Traits` |
   | That a quest exists, and its title | `C_QuestLog.RequestLoadQuestByID`, `GetTitleForQuestID` |
   | A quest's objectives and the game's own area, when the receiver has the quest in its log | `C_QuestLog.GetQuestObjectives`; the area test (*Quest areas*) |

   The receiver asks its own game, in steps and at the crawl's pace; **accepted only if the game agrees**,
   and then it counts as the player's own observation. If the game disagrees: rejected, a strike for the
   sender. A fact for a build the receiver's client has not reached waits until it has.
   Saneroki's example: a member sends *these gloves have new stats*. The receiver's game is asked for the
   gloves. The same stats: accepted. Other stats: rejected, the sender gets a strike, nothing changes.
5. **What the game cannot check needs several senders.** Where an NPC stands, a vendor's goods and prices, a
   quest's giver and rewards, herb places: accepted only when **3 different members** (*proposal*) sent the
   same, and nothing the player saw says otherwise. One sender alone never changes anything. The player's
   own observation always wins.
6. **Counts are summed robustly.** Each sender's counts are kept apart per build period. They must be
   possible (loots per hour within what one player can do; never more drops than loots allow). A sender
   whose chance is far from everybody else's, with enough loots to be sure (a clear statistical outlier), is
   left out; no sender may make up more than a quarter of a creature's loots (*proposal*). The player's own
   counts always count.
7. **Prices: own first, then the middle.** A shared scan fills in only where the player's own is older. Per
   item the median of the senders' prices; a price more than five times off the item's own history
   (*proposal*) needs a second sender.
8. **Strikes.** Three strikes (*proposal*) and a sender is ignored for a week and its waiting data dropped;
   kept by name, on this computer only.
9. **Never into the master unchecked.** The harvest takes accepted data only, with how it was accepted (by
   the game, or by how many senders); waiting data never.
10. **Undo.** A button *Forget shared data* (*The switches*) removes everything accepted from others and all
    that waits, and leaves the player's own data and the packs as they were.

**What remains:** one person with three characters in the guild could agree with itself about something the
game cannot check (where an NPC stands). It cannot touch what the game checks; it is removed with one
button; the player's own observation overrides it; it never reaches the master unchecked; and the guild can
remove such a member.

### The switches

On Core's page *General*, under a heading *Data* (Saneroki, 2026-10-16). Account-wide; they hold for every
module's data, so no module has switches of its own for this.

| Switch | Default | Does |
| --- | --- | --- |
| **Share data with my guild** | on | Sending and taking shared data. Off: the prefix is not even registered, so the game does not hand the messages to us at all; it costs nothing. |
| **Load client data on load** | on | The patch check reads the game's data during the loading screen. Off: the check runs after the loading screen, in the background, within the frame budget (*The patch check*). |
| **Chat message for new data changes** | off | One line when accepted data changed the database (*Chat messages*). |
| **Chat message for new auction house data** | off | One line when an accepted scan, own or shared, changed prices. |

- Tooltip of the first: *Sane UI players in your guild swap general game knowledge (auction prices, new
  quests, changes after a patch, drop chances), so everybody's is up to date. Nothing about you or your
  characters is sent, and it does not slow the game.*
- Below them the button **Forget shared data** (*Poisoning*).
- They come with what they switch (*Three prompts*), not before: a switch with nothing behind it would be
  dead code.

### Cost in the game (measured)

Saneroki: the scanner asks who wants the newest auction house data and sends only what that scan fetched (the
summary of the newest scan, never the history). Since nothing runs in combat, up to 5 ms a frame out of
combat is within the performance specs: not to be noticed there.

Measured 2026-10-16 with Lua 5.1 on Saneroki's computer, for a scan of 6,000 items; packing with zlib in C, as
the client's `C_EncodingUtil` does:

| Who | Step | Time |
| --- | --- | --- |
| Sender | 250 items into text | 0.09 ms |
| Sender | a block packed (the client's code, one call) | 0.03 ms |
| Sender | a block cut into its parts (about 9) | under 0.02 ms |
| Sender | each message, one a second | a few µs |
| Receiver | each message arriving | 0.08 to 0.2 µs of our code, plus the event's own few µs |
| Receiver | a block's parts together and unpacked | about 0.03 ms |
| Receiver | 250 items read, checked and kept as today's price | 0.29 ms |

Packed in blocks, a scan is as small as packed in one piece: about 53 KB for 6,000 items (made-up prices),
24 blocks; made text (`EncodeBase64`) about 71 KB, about 290 messages, about five minutes at one a second.

- **Frame rate:** every step above is a fraction of a millisecond; the 5 ms are a ceiling for when much is
  queued at once, not the usual. Even a frame at the full 5 ms happens only out of combat (Saneroki: not to be
  noticed there), and in combat the database does nothing.
- While nothing runs: nothing (no timer, no polling). A message not for us: one cheap check.
- Members who switched sharing off pay nothing.
- The heavy part at the auction house is the scan itself (reading every auction), the database's (*Learned*),
  in steps within the same budget.
- **Smaller later, if measuring asks:** prices rounded to three significant figures pack much tighter; or
  only items whose price moved since the last shared scan.

## When something fails

| Fails | What happens |
| --- | --- |
| A pack is missing, switched off, or of an unknown format | Its sets are not ready; said once; modules fall back |
| A row cannot be read | That entry is nil; said once per set. The build decodes every row, so it should not happen |
| A pack's saved data has a wrong shape | That part is set aside under `broken`; the rest works |
| A pack's saved file failed to load | Warned at once, before the `.bak` is lost |
| A module writes into a record | Caught by the tests (frozen records) |
| The master breaks a rule | The build stops: a broken pack is never made |
| The game changed and our data is old | The client's own answer wins where it gives one; learned data notes the difference for the next release |
| A part of a shared transfer is lost or damaged | Only its block (250 items) is dropped; the other blocks are taken in. Own data is never touched |
| A shared block or fact has a wrong shape or values | Dropped, a strike for the sender |
| Sending is refused (budget, lockdown) | The transfer waits and goes on later |
| A guild member sends something false | The game rejects what it can check; the rest needs three senders; the player's own observation wins; a button forgets all shared data (*Poisoning*) |

## Performance

- **One budget for all the database's work: at most 5 ms a frame, and only out of combat** (Saneroki: with
  nothing in combat, 5 ms a frame cannot be noticed), measured by the client's precise clock
  (`debugprofilestop`). One scheduler (`Steps.lua`) runs every job in steps (the scan's reading, shared data
  taken in, checks, the characters, the crawl) and stops each frame when the 5 ms are spent; the rest goes
  on in the next, and never takes more than a quarter of a frame at the current frame rate
  (`GetFramerate`; at 144 frames a second 1.7 ms; Saneroki, decision 25). A slower computer takes more frames,
  no frame more time. The scheduler also stops while a restriction is active
  (`ADDON_RESTRICTION_STATE_CHANGED`). Only the client's own packing and unpacking cannot be cut; the block
  size keeps them far below. A step that cannot be cut (loading a pack) runs alone in its frame.
- **A job is a coroutine** that yields when the frame's time is spent, so a long loop (a scan's rows, a
  crawl) reads as one plain loop. Each job is guarded by itself: `coroutine.resume` catches its error, the
  job is dropped and logged (`Core.Report`), and the others go on. (`module.Guarded` would not fit: it stands
  a whole module down, and Core has none of its own.) **A job never yields inside `Core.Safe` or `pcall`:**
  Lua 5.1 cannot yield there, and measured, the yield fails into the `pcall`'s error and the job runs on
  past its budget without a word.
- **Reads always work, also in combat:** `Get`, `History` and the rest on a loaded set are a table index and
  at most one row taken apart. Only loading packs and the scheduler's jobs wait for the fight to end.
- **Nothing in combat** but what must be: a message put into the inbox (0.08 µs). The scheduler stops at
  `PLAYER_REGEN_DISABLED` and goes on at `PLAYER_REGEN_ENABLED`.
- Nothing loads at login that nobody asked for; what is asked loads after the loading screen, a pack a frame.
- A lookup is one table index and, the first time, one row taken apart. No table per row until asked.
- No `OnUpdate` of our own beyond the scheduler's frame, which runs only while there is work. The events:
  the watchers' (a quest, a vendor, loot: moments, not a stream; each only compares and marks), the
  characters' (marks only), and with sharing on `CHAT_MSG_ADDON`.
- **Bounded and merged:** saved data grows in bounds: prices rolled up by day, week and month, drop counts
  merged into one *earlier* count after three build periods, discoveries 90 days, waiting shared data and
  facts heard capped, duplicates struck by their text.
- Measured numbers: *Speed*, *Limits*, *Cost in the game*.
- The packs are addons of their own, so the client's addon profiler shows each one's memory and time.

## Tools

| Command | Does |
| --- | --- |
| `dev/tools/data check` | Checks the master (run by `dev/tests/run`) |
| `dev/tools/data import <file> [--apply] [--take]` | Staging into the master, with the report first |
| `dev/tools/data harvest` | Saved files into staging (accepted data only) |
| `dev/tools/data show <set> <key>` | An entry with every version and source |
| `dev/tools/data diff <set> [--patch 1.60.2]` | What a patch (or a release) changed |
| `dev/tools/data stats` | Counts, sizes, budgets per set and pack |
| `dev/tools/data compile <dir>` | The packs (run by `dev/build`) |

In the game, `/sane data`: the packs, loaded or not, their release, what was accepted since (own, shared),
the patch check's progress, the days not yet archived, shared data waiting, senders ignored.
`/sane data crawl <kind>` starts a crawl; `/sane data forget` does what the button *Forget shared data* does.

## Tests

- **Tools** (Python, run by `dev/tests/run`): the check catches every broken rule; the import's report and
  its result on small sample masters (new, changed, conflict, gone, replaced, merged keys); compiling twice
  gives the same bytes; the harvest takes accepted data only.
- **Game versions apart:** a live pack holds no line of the PTR's or the beta's files; a beta pack is the live
  files with the beta's on top; a staging line without its game version is refused, and one in the wrong
  file fails the check; a beta build never makes a live version; the harvest of two folders writes two game
  versions. In the game: a pack of another game version is refused; saved data under another game
  version's key is neither used nor changed; a message of another game version is ignored.
- **Realms apart:** a scan, a shared scan and a harvested day go only to their own auction house; a
  character on another realm, region or side sees none of those prices (not even as a fallback); one item
  has two different prices on two houses; the game's facts (an item, a quest) are the same on every realm.
- **Runtime** (`dev/tests/data.lua`, Lua 5.1 with `wowstub.lua`): handles, loading and refusing packs
  (missing, switched off, wrong format, in combat), `Get`, `At`, `History`, `Versions`, `Changes`,
  `Stamp`, indexes, learned over shipped, series with the archive handshake, saved data of a wrong shape,
  frozen records.
- **Scheduler:** no frame over 5 ms whatever is queued; nothing in combat; jobs go on after.
- **Characters:** marks and reading in steps, nothing in combat, the bank only while open, counts across
  characters kept up to date, the auction log from auctions leaving the list, a deleted character.
- **Crawl and patch check:** the pace; a newer build starts the check, the same or an older one does not, a
  pack made after the patch skips its sets; with *Load client data on load* a step during the loading,
  without it none; it resumes after a logout; *gone* only after a second miss; the build noted.
- **Watchers, discoveries, chat messages:** each watcher with a known, a new and a changed thing;
  discoveries kept and bounded; a chat message only when switched on and only for accepted changes, summed
  up, at most one in 15 minutes per kind, none in combat.
- **Drop rates:** loots and drops counted once per corpse; objective items only on the quest, items that
  start a quest always; counts per character; build periods; the whole history by default; a change
  between periods found only with enough loots and a clear difference; older periods merged; a loot's
  place counted per cell, a cell looted once kept out of the area; a creature linked to a quest by its
  tooltip, by a rising count and by quest loot.
- **Quests:** chains in order from `next` and `requires`, breadcrumbs both ways, `Missing` for a character
  (level, quests all of and one of, a quest that locks it out, reputation, skill); a quest offered against
  our requirements narrows them, one not offered needs three characters; areas as runs of cells (merging,
  the point test, the compiler's groups); the area test in steps within the budget, nothing in combat.
- **Creatures and the map:** a creature noted only while no restriction is active, a secret value skipped
  and never stored; `Data.Spell` finds a spell in any of the three sets; places rounded, a nearby one
  merged into its spawn point, a far one a discovery; the list per map; `Near` nearest first; flight
  points checked by `C_TaxiMap`.
- **Sharing,** with a stub guild of several players: scans (have, want, data; one answer; the 15 minutes);
  bundles (once in 15 minutes per member and per sender; facts already heard struck); counts per sender never
  added twice; the busy guild; a storm of 2,000 messages in one frame within its cost; the inbox's bound;
  the budget's refusals and the lockdown; the switch off (no prefix registered).
- **Poisoning,** each layer with a hostile stub member: only the guild; a wrong shape; quarantine (`Get`
  gives nothing until accepted); a fact the game disagrees with rejected, one it agrees with accepted; a
  fact of a newer build waiting; one sender alone never enough for what the game cannot check, three are;
  counts that cannot be and an outlier left out, one sender capped at a quarter; prices by the median and
  the five-times rule; three strikes; *Forget shared data* leaving own data untouched.
- Module tests run against small packs compiled from sample masters, not against the real data.
- **The codec both ways:** the sample masters are compiled by the Python compiler and every row is read
  back by the Lua codec and compared with the master. It is the one test that keeps the two languages in
  step.
- **Nothing hostile raises an error:** random, cut and oversized texts into the inbox, and broken saved
  files, are dropped or set aside, never an error.

## Files (proposal)

```
src/Core/Data/            the framework, in SaneUI.toc (decision 24: in the end only the engine stays here)
  Data.lua                sets and handles, finding and loading packs, Get, At, History, Versions, Changes, Keys
  Codec.lua               a row's string into its fields, by the field order the pack carries
  Steps.lua               the scheduler: every job in steps, 5 ms a frame for all of them, nothing in combat
  Live.lua                saved variables: learned, series, upgrade, roll-up, the archive handshake
  Characters.lua          the characters' data: marks, reading in steps, counts, the auction log
  Crawl.lua               /sane data crawl, and the patch check at login: the game asked, paced
  Watch.lua               the watchers: quests, NPCs, creatures out of combat, vendors, trainers, crafting, loot, rares, flight points, tooltips
  Scan.lua                the full auction scan when the auction house opens
  Drops.lua               drop and gathering counts, build periods, chances, changes between periods
  Quests.lua              chains, breadcrumbs, what a character still lacks, quest areas and the area test
  Areas.lua               the cells of an area: quests, spawns, herbs; merging, the point test
  Map.lua                 places on the map: spawns, services, the list per map, Near; Data.Map
  Found.lua               the discoveries, and the chat messages the switches ask for
  Share.lua               sharing with the guild, party and raid: scans, bundles, the inbox and the queue, the limits
  Trust.lua               against poisoning: shape, quarantine, the game's check, several senders, strikes
  Packs/<Pack>/           a pack's own code (decision 24), copied into its pack by the compiler, not in SaneUI.toc
  README.md
assets/data/              the master (*The master*, decision 3): builds.toml, sources.toml, packs.toml, <Set>/
dev/tools/data            the command
dev/data/                 its Python: schema, check, import, compile, harvest
dev/tests/data.lua        runtime tests;  dev/tests/data/  sample masters and the tools' tests
BUILD/SaneUI_Data_<Pack>/ the packs, made by dev/build (TOC, Lua, licence), not committed (decision 4)
```

Where the code loads (Saneroki, decision 24): Core holds the engine (`Data`, `Codec`, `Steps`, `Live`,
`Found`, `Characters`, the watchers' marks). The domain code ships with its pack: `Quests.lua` with
Quests, `Areas.lua` and `Map.lua` with Spawns, `Drops.lua` with World, `Scan.lua` with Market. Sharing
(`Share.lua`, `Trust.lua`) is a load-on-demand part of its own, loaded only while *Share data with my
guild* is on. The sources stay together in `src/Core/Data/`: a pack's own code in `Packs/<Pack>/`, which
the compiler copies into its pack after the set files, and which the lint knows is no file of Core's TOC.
The API stays the same (`Data.Set`, `Data.Map`, ...).

## What moves over

| Today | Becomes |
| --- | --- |
| `Core/Settings/Data/CVarLabels.lua` (25 KB, made by `dev/tools/cvar-labels`) | Set *CVarLabels*, pack Game; the tool writes staging |
| `Abilities/Data/` (trainer per class, quest spells, weapon skills, skill lines) | Pack Spells; the faction and race filters of `Data/Trainer.lua` stay in Abilities, as code over the sets |
| `Tooltips/Data/Quests.lua` (546 KB: `ns.QuestFacts`, records per quest, NPC and item) | Pack Quests: a quest's levels, races and classes become fields of *Quests*, its rule (`+`, `/`, `!`) becomes `requires`; the NPC and item records become indexes, made by the compiler |
| Tooltips' `prices` and `seen` in `SaneUIDB` and their gathering (`Tooltips/Auction.lua`) | Series *Prices*, pack Market, gathered by the database; Tooltips only reads |
| Economy's scan and price history (planned in `Doc/ideas/Economy.md`) | The database's (`Scan.lua`, series *Prices*); Economy only shows |
| Navigation's data (planned) | Sets World, Spawns from the start |

Each set moves first as one version per entry with `since = 0` and a source *old* (today's files). The
module then reads through `Core.Data`, and its old file is deleted in the same commit.

## Contracts

The exact shapes a building session keeps to are in the guide [Doc/guides/data.md](../guides/data.md),
since step 1a.1: a line of the master, the schema, staging and the import's cases, the check, a pack's TOC
and Lua file, a row, the answers in the game, the scheduler's jobs, the saved variables, the messages and the
clocks. The guide is the reference; where this page and the guide differ, the guide wins. Why they are so is
in this page's own sections:

- one string per version, cut by characters no game text holds (*How a pack is stored*);
- every version whole in the pack, history on demand (*How a pack is stored*);
- the same master, the same bytes; hashes, not dates; at most 50,000 rows a function (*Building*);
- nil means not known, and `Get` never loads a pack (*Loading*, decision 20);
- everything keyed by game version first (*Game versions kept apart*);
- packed strings and a budget of values in saved files (*Saved variables*, *Series*);
- jobs as coroutines that never yield inside `pcall` (*Performance*);
- the server's day for everything kept or shared (*Series*).

## Three prompts (Saneroki)

Saneroki has the work done in three prompts. Each reads this page first; what follows is what each one does
and when it is done.

### 1. Build the system

- **In six steps** (Saneroki, decision 26), each ending with green tests and a commit, one prompt each if
  need be:
  - **1a** the contracts first, in `Doc/guides/data.md` (*Review*: a pack's Lua file, each saved
    variable, a message, the return shapes); then the frame (master format, schemas, check, compile,
    loading packs, `Get`, the scheduler) with *CVarLabels* as the first set the whole way; versions in full
    (`History`, `At`, `Versions`, `Changes`, builds, the import with its report);
  - **1b** the Tooltips quests moved over (prompt 3 for one set), so a real reader proves the frame before
    more is built on it;
  - **1c** live data (learned with its inbox, series, the archive handshake, harvest), the characters,
    the crawl and the patch check;
  - **1d** the watchers, discoveries, drop counts, chat messages, quests and the map;
  - **1e** the auction scan;
  - **1f** sharing (scans, then bundles) with the defences against poisoning, last: the riskiest part.
- Each step lists the session's checks (tests, build) apart from Saneroki's checks in the game.
- `dev/build` and `dev/tests/run` call the tool; the lint knows the packs (`LoadOnDemand`, the
  `X-SaneUI-*` lines, their saved variables).
- Every set's schema from *Sets by concern* and *The game's own data*, `builds.toml`, `sources.toml`, small
  sample masters for the tests. Real data comes with prompts 2 and 3.
- The four switches and the button *Forget shared data* on the page *General* (*The switches*); `/sane
  data`.
- Documents: a guide `Doc/guides/data.md` (read before adding data), Core's README, an agent note
  `Doc/agent/data.md`, `Doc/Changed.md`.
- **Done when** the tests are green and `dev/build` makes the packs (the session's part), and in the game
  (Saneroki's part, each check with its step) the packs load, `/sane
  data` lists them, a crawl of spells runs, an older last build put in the saved file starts the patch
  check, the characters' data fills, a vendor or quest missing from the data becomes a discovery, loot is
  counted, a quest taken gets its objectives, places and area, the auction house is scanned, and two accounts in one guild share a scan and a bundle (and a
  false fact sent by one is rejected by the other). Apart from the Tooltips quests (1b), no module uses it
  yet, and today's other data ways are untouched.
- **The steps are cut into commits** in [Data-build.md](Data-build.md), with how a session goes on where the
  last one stopped. A session of prompt 1 reads it first and ticks off each commit there.

### 2. Import the data

- Our tools' staging files are taken into the sets: quests, NPCs (with stats, abilities, buffs and
  services), creatures' spells, objects, spawns, items, vendors, trainers, rares, treasures, herbs and ore,
  travel, zones, drop chances, prices.
- Taken in with the report first; conflicts looked at, not forced; one thing seen several ways kept as one
  entry (*Keys*).
- Then a crawl in the game of items, spells, talents and legacy, so the game's own facts stand beside the
  staged ones, and above them.
- **Done when** the masters hold the data, the check is green, the packs are built, and the import's report
  says per set how many entries each batch brought and what was refused.

### 3. Move the modules over

- Each module reads through `Core.Data`, and only reads; its old data, data code and any gathering of its
  own are deleted in the same commit (*What moves over*). Saved parts that move (Tooltips' prices) are
  dropped from `SaneUIDB`; nobody else has old copies, so no upgrade step is needed.
- Module tests run on small sample packs; every module still falls back when its pack is missing.
- **Done when** no module holds or gathers data of its own, no old data file is left, all tests are green,
  and each module's in-game checks are listed in its README.

### Later: a view of discoveries and history

A module that shows the discoveries and every entry's history (a *Library*) is work of its own, with its own
idea page first. It only reads (`Data.Found`, `History`, `Versions`, `Changes`); the chat messages are the
database's, not its.

## Review (2026-10-16)

A full pass over this page before prompt 1, by a Claude session, its claims checked against the Blizzard
code in `references/` and against Core.

### What holds

- **The shape is the proven one:**
  - data apart from the views;
  - a plain-text master, with tools that check it and compile it;
  - packs as load-on-demand addons;
  - one string per row, taken apart on first ask and kept (as the Tooltips quest database already does,
    measured);
  - indexes made by the build;
  - one scheduler with a time budget, and nothing in combat;
  - the game as ground truth;
  - every shared message treated as hostile.
- **The APIs it names exist in this client:**
  - `C_AddOns.GetAddOnMetadata`, `LoadAddOn`;
  - `C_EncodingUtil.CompressString`, `EncodeBase64`;
  - `C_ChatInfo.SendAddonMessage` with its result, `InChatMessagingLockdown`;
  - `C_RestrictedActions.IsAddOnRestrictionActive`;
  - `TooltipDataProcessor.AddTooltipPostCall`;
  - `C_Item.DoesItemExistByID`, `IsItemDataCachedByID`, `RequestLoadItemDataByID`;
  - the quest map pin's `UpdateMouseOverTooltip`.
- **Core already has what the plan leans on:** `Core.Plain`, `Core.Ask`, `Core.Later`, `Core.FullName`,
  and `Core.charKey` (the GUID).
- **The versioning is simple and sound:** versions are only added, corrections are made in place with git
  as the second clock, and an entry is *gone* only on the game's word.

### Corrected in this page

- **Sending:** a message is a C string, so packed data is made text first (`EncodeBase64`). That makes it
  a third bigger, and *Cost in the game* is updated.
- **The send budget:** 10 messages, then one a second, is what Blizzard's own queue for commentator
  messages plans with. It is not a published limit of the server; only each send's answer tells the real
  one.

### Smaller points, for the build

- **Guarded steps:** each job is guarded by itself (`coroutine.resume` catches its error; there is no
  `Core.Guarded`, and a module's `Guarded` stands the whole module down). A job that errors is dropped and
  logged, and the others go on (*Resilience*, *Performance*).
- **Restrictions:** the scheduler stops while a restriction is active (`ADDON_RESTRICTION_STATE_CHANGED`),
  not only in combat.
- **Own messages:** a guild message also comes back to its sender. Sharing drops the player's own
  messages by the sender's name, with the realm (`Ambiguate`).
- **Data twice in git:** the master and the packs are both committed (decision 4), and the walking data
  alone may be several megabytes (to measure once our tool has made it). The repository is 34 MB today, so
  weigh decision 4 with that. *Settled* (Saneroki, 2026-10-17): `BUILD/` is not committed (`.gitignore`), so
  neither are the packs; only the master is.

### Second pass (2026-10-16)

A second session went over the page again for what the first pass left: the formats, the limits of Lua
and the client, and the rules that keep wrong data from staying. Measured with Lua 5.1 where it says so;
the client's API checked in `references/`.

- **Checked in the client as well:**
  - `C_EncodingUtil` also has `SerializeCBOR` and `SerializeJSON`; not needed, the one codec serves packs,
    saved strings and messages alike;
  - `CompressString` packs as *Deflate* (no checksum) unless *Zlib* is named, so every call names it;
  - `CHAT_MSG_ADDON` gives the sender's name, never a GUID;
  - an addon link (`|Haddon:...|h`) reaches `EventRegistry`'s `SetItemRef`;
  - the tooltip line kinds `QuestTitle` and `QuestObjective`; `C_AuctionHouse.ReplicateItems`;
    `GetServerTime`.
- **Not found:** `GetLootSourceInfo`, which the drop counts lean on, is in neither the client's code nor its
  API documentation. To check first in the game; without it nothing is counted (*What is counted*).
- **Corrected in this page:**
  - **Separators** (*How a pack is stored*): a comma or `=` inside a field breaks on the first quest text
    that holds one. Rows are now cut by characters no game text holds (tab, ASCII 30 and 31), and the check
    refuses text that holds them.
  - **The same master, the same bytes** (*Building*): a release named by its date made every compile
    differ, so every commit would have rewritten every pack. Packs now carry the master's hash and the
    newest build, sorted, one row per line.
  - **Lua's constant limit** is per function (*Building*): the compiler cuts rows into functions, so no
    pack meets it (measured). Saved files meet it too: each saved variable keeps a budget (*Series*).
  - **Every version whole in the pack** (*How a pack is stored*): the compiler works versions out, so the
    game never adds up changes, and a field a patch removed is simply empty.
  - **Records kept weakly** (*How a pack is stored*): a walk over every entry cannot fill the memory.
  - **Learned wins only while it is newer** (*Learned*), and is a whole row: a wrong learned fact cannot
    stand above the packs for ever.
  - **An empty answer is no fact** (*The patch check*): data the client has not loaded is never a change.
  - **The server's day** (*Series*): every day and time that is shared or kept across characters comes
    from `GetServerTime`.
  - **Per corpse looted** (*What is counted*): kills cannot be counted, so a chance is per corpse looted.
  - **Sharing:** one sender may send 90 messages a minute, not 60 (an honest one sends about 70 in its
    first minute); *want* waits a random moment; the packed block is capped before unpacking; a fact of a
    newer build waits instead of the unclear *newest known plus one*; shared counts per sender are bounded
    and summed at each new build (*Scans*, *Limits*, *Poisoning*).
  - **Jobs as coroutines** (*Performance*): a yield inside `pcall` fails without a word in Lua 5.1
    (measured), so no job yields inside `Core.Safe`; reads work in combat, only loading and jobs wait.
  - **No licence line in a schema** (*Schema*): the one licence covers all data.
- **The contracts** the first pass asked for are written down in *Contracts*, for step 1a to carry into
  the guide.
- **The build in steps** (decision 26) is cut into commits, each with its own checks, in
  [Data-build.md](Data-build.md): a session that stops loses at most one commit's work.

### Is it a good brief for a building session?

It is good for the why and the what: goals, examples, measurements, failures and tests are all there. It
lacks the exact contracts a build needs, the places where two sessions would each invent their own. Write
them down first, in the guide `Doc/guides/data.md`, as step 1a's first work:

- **A pack's Lua file:** how it hands its sets to Core in one call, with the field order, the row strings,
  the history strings and the indexes.
- **Each saved variable:** its layout and its format number.
- **A message:** kind, protocol, part numbers, and the block's checksum.
- **The return shapes:** what `History`, `Versions`, `Changes` and `Keys` give back, and that the tables
  they give are shared and read-only.

The gaps were decisions 19 to 26 below, all answered as proposed (Saneroki), and written into the page.

## Decide before prompt 1

What is not answered by then is built as proposed. Every decision below is answered now (Saneroki, the
open ones on 2026-10-17).

1. Answered (Saneroki, 2026-10-17): as proposed, packs. **Packs as load-on-demand addons** in the addon list
   (under Sane UI, *Data: Items*), or all data inside Core? Inside Core is simpler, but all of it is always
   in memory and every login slower as it grows. *Proposal:* packs.
2. Answered (Saneroki, 2026-10-17): as proposed, yes. **Saved variables declared by the packs** for live data
   and characters, beside `SaneUIDB`? *Proposal:* yes.
3. Answered (Saneroki, 2026-10-17): **`assets/data/`**, not as proposed. **The master in `src/Core/Data/`**
   (part of Core, as Saneroki said), or in `assets/data/` (originals that tools turn into game files, like the
   art)? *Proposal:* `src/Core/Data/`. The engine that reads the packs stays in `src/Core/Data/`.
4. Answered (Saneroki, 2026-10-17): **the packs are not committed.** The question's ground had moved:
   `BUILD/` is not committed any more (`.gitignore`), so the packs are made by `dev/build` at every build,
   as every addon folder is. **Packs in git:** `BUILD/` is committed today, so each commit would hold the
   master and the packs made from it (the data twice). *Proposal:* commit them like the rest of `BUILD/`, so
   a checkout plays without Python.
5. ~~History in the game~~ Answered (Saneroki): the current version by default, history on demand.
6. Answered (Saneroki, 2026-10-17): as proposed, yes. **The auction history archived in the repository for
   ever** and shipped back in the Market pack? It is Saneroki's own scans, for own use; several megabytes a
   year, to measure. *Proposal:* yes.
7. ~~Names in English only~~ Answered (Saneroki): English only (decision 22).
8. ~~Who learns~~ Answered (Saneroki): the database; modules only read.
9. Answered (Saneroki, 2026-10-17): **the guild, the party and the raid**, not as proposed; no whispers.
   *Sharing in the game* says what follows from it. **Sharing beyond the guild:** also with the party or
   raid, or with friends by whisper? *Proposal:* the guild first; a guild is a group of people who know each
   other, so trust is simplest there.
10. ~~Facts from the guild used at once~~ Answered by *Poisoning*: only once accepted (checked by the game,
    or sent by three members).
11. ~~Chat messages~~ Answered (Saneroki): the database's, behind two switches, off by default.
12. Answered (Saneroki, 2026-10-17): as proposed, start values, each a named constant, tuned in the game
    (with the party and the raid too) before they are final. **The numbers of the limits and the defences**
    (*Limits*, *Poisoning*, *Drop rates and gathering*): 15 minutes; the guild busy above 4 messages a
    second; three senders; three strikes; a quarter per sender; five times off; 100 loots and |z| above 3
    for a changed drop chance. To measure in the game with a real guild before they are final.
13. Answered (Saneroki, 2026-10-17): as proposed. **After a drop chance changed with a build:** the whole
    history by default (Saneroki) mixes the old chance into the new one for a long time. *Proposal:* where a
    change was found, the whole history starts at that build.
14. ~~Load client data on load~~ Answered (Saneroki): on by default; switched off, the check runs after the
    loading screen in the background. The frame budget: 5 ms out of combat, nothing in combat (Saneroki).
15. Answered (Saneroki, 2026-10-17): as proposed, 10 a second and 250 ms, both start values to measure in
    the game. **The crawl's pace** for what the server must send (items): 10 a second (*proposal*), or
    slower? And the patch check's step during the loading screen: at most 250 ms (*proposal*)?
16. ~~If Sane UI is ever handed out~~ Answered (CLAUDE.md, *Licensing*): not a question for this plan.
17. Answered (Saneroki, 2026-10-17): as proposed, cells and 3 %. **Quest areas as cells** of 1 % of the map
    (*proposal*), or as outlines (smoother to draw, but hard to merge and to test a point against)? And the
    margin around spawn points: 3 % (*proposal*)?
18. Answered (Saneroki, 2026-10-17): **every creature, in a pack of its own** (Navigation's proposal, its
    open question 11): *Spawns* holds what a map shows and stays lean, as it loads soon after every login
    with Navigation on; every other creature's spawn points are the set *CreatureSpawns* in the pack
    `SaneUI_Data_CreatureSpawns`, loaded when asked for, split by continent if measuring says so. **Spawn
    points of every creature** our data has, or only of those a map shows (rares, NPCs with a service, quest
    objectives, herbs, ore, chests)? Every creature can be several megabytes. *Proposal:* every creature, in
    the pack Spawns (it loads with the first map), measured in prompt 2 and split by continent if it is too
    big.
19. Answered (Saneroki, 2026-10-16): as proposed. **Where learned data waits while its pack is not loaded** (*Review*). A pack's saved variable exists
    only once the pack is loaded, and whatever Core puts into that global before is overwritten when it
    loads. Yet the watchers fire at any time (a vendor, a tooltip), and the patch check and the discoveries
    write into the packs' saved files too. *Proposal:*
    - Core keeps a small, bounded inbox in `SaneUIDB`: the key and the changed fields.
    - The inbox moves into the pack's saved file when the pack loads.
    - A watcher compares only against packs already loaded; otherwise it only notes the key, so a watcher
      never loads a pack.
20. Answered (Saneroki, 2026-10-16): as proposed. **`Get` never loads a pack.** As planned, `Get` on a set not loaded yet loads its pack at once. That
    is a read with an 8 to 30 ms hitch wherever the call happens to be, a tooltip among them. *Proposal:*
    - `Get` on a set not loaded gives nil and asks for `Prepare`.
    - `Stamp` moves when the set is there, so the view redraws.
    - Reads are then always cheap and change nothing.
21. Answered (Saneroki, 2026-10-16): as proposed. **Changes without a new build.** Blizzard changes data by hotfix without a new build number. The
    plan's clock is the build, so a change the game shows at the same build would be a *conflict*.
    *Proposal:* a version's clock is the build and the day (`"since":65100,"day":"2026-11-03"`). The
    game's word at the same build, on a later day, is a new version.
22. Answered (Saneroki, 2026-10-16): as proposed. English only. **Other languages.** Names and texts are kept in English only (decision 7), so a player with a German
    client would *learn* every name as a change, and share it. *Proposal:*
    - Watchers, the crawl and the patch check compare text fields only on an English client
      (`GetLocale()`: `enUS`, `enGB`). Numbers and IDs count from every client.
    - A shared message carries the sender's language, and text fields from another language are dropped.
23. Answered (Saneroki, 2026-10-16): as proposed. **What an item in a tooltip says.** A tooltip shows an item as that player has it: a suffix, an
    enchant, the player's own level or class in some lines. *Proposal:* the watcher only takes the
    tooltip as a sign, and compares the plain item asked for by its ID (`GetItemInfo`, `GetItemStats`),
    never what one link shows.
24. Answered (Saneroki, 2026-10-16): as proposed. **Code in Core that only some need.** Every file under *Files* is in `SaneUI.toc`, so all of them load
    at every login, even where nobody asks for their part: quest chains, the map, drops, the auction scan,
    sharing and its defences. *Proposal:*
    - **Core holds the engine:** `Data`, `Codec`, `Steps`, `Live`, `Found`, `Characters`, and the
      watchers' marks.
    - **The domain code comes with its pack:**
      - `Quests.lua` with the Quests pack;
      - `Areas.lua` and `Map.lua` with the Spawns pack;
      - `Drops.lua` with the World pack;
      - `Scan.lua` with the Market pack.
    - **Sharing** (`Share.lua`, `Trust.lua`) is a load-on-demand part, loaded only while *Share data with
      my guild* is on.
    - A pack then holds its data and its readers, and the API stays `Data.Set`, `Data.Map`, ...
25. Answered (Saneroki, 2026-10-16): as proposed. **The frame budget on fast screens.** 5 ms is a third of a frame at 60 frames a second, but three
    quarters of one at 144 (6.9 ms). *Proposal:* at most 5 ms, and never more than a quarter of a frame at
    the current frame rate (`GetFramerate`).
26. Answered (Saneroki, 2026-10-16): as proposed. **Prompt 1 is too big for one go, and its *done when* cannot be checked by a session.**
    - It builds all fifteen files, sharing and its defences among them, before any module reads a line.
    - Half of its checks need the game, and some need two accounts.

    *Proposal:* split it into steps that each end green and committed:
    - **1a** the frame with *CVarLabels*, versions and the tools, starting with the contracts (*Review*);
    - **1b** the Tooltips quests moved over (prompt 3 for one set), so that a real reader proves the frame
      before more is built on it;
    - **1c** live data, learned data, the characters, the crawl and the patch check;
    - **1d** the watchers, discoveries, drop counts, quests and the map;
    - **1e** the auction scan;
    - **1f** sharing and its defences, last: it is the riskiest part and needs the most testing in the
      game.

    Each step lists the session's checks (tests, build) apart from Saneroki's checks in the game.

27. Answered (Saneroki, 2026-10-17): as proposed, the beta's batches are Forever live's base (`since` 0),
    the rest of the beta's own data stays the beta's.
    **Which game version the data gathered so far counts for** (*Game versions kept apart*). Each staging
    batch says in `sources.toml` which game version it describes. What our tools have gathered so far was
    seen on Forever's beta. Taken strictly, it is the beta's, and Forever live would start with no quests,
    NPCs or places. *Proposal:*
    - A batch seen on the beta counts as Forever live's base: `since` 0, the weakest version. Live's own
      patch check, crawl and play replace it wherever live shows otherwise. The same holds for the Tooltips
      quests moved over in 1b (source *old*).
    - Everything of our own from the beta stays the beta's: learned facts, crawls, counts, discoveries and
      prices.
    - Stricter, if Saneroki wants it: a batch counts only for the game version it was seen in, and live
      starts empty.
