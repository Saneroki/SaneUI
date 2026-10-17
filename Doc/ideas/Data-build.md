# Data: the build, commit by commit

Prompt 1 of [Data.md](Data.md) (*Three prompts*, decision 26), cut into commits. Each commit leaves the
tests green and `dev/build` working, so a session that stops in the middle (a token limit, a crash) loses
at most the commit it was on, and the next session goes on from there.

## How a session goes on

1. Read this page. Then read the *Contracts* (in Data.md; once 1a.1 is done, in the guide
   `Doc/guides/data.md`), the sections of Data.md the next commit names, and
   [addon standards](../guides/addon-standards.md).
2. Look at `git status` and `git log --oneline -15`. The first box below that is not ticked is next.
   - Files of that commit that are there but not committed come from a session that stopped: they are
     this plan's, so take them up, after reading them, because they may be half done.
   - Changes to other files belong to other sessions: leave them alone (CLAUDE.md, *Parallel sessions*).
3. Build the commit. Write its tests first where that is possible.
4. Run `dev/build`. Then commit by path, with a short message. Tick the box in the same commit; `git log`
   has the hash. Add a line to `Doc/Changed.md` under the heading *Core's data framework*. On Saneroki's
   computer a commit is never pushed (CLAUDE.md); a cloud session, whose container is thrown away, pushes
   each commit to `main` (Saneroki, 2026-10-17) and runs `dev/build --no-install` (there is no game there).
5. A commit's *in the game* checks are Saneroki's. The session lists them in its answer; it cannot do them.

**Every commit keeps to these rules:**
- The *Contracts* and the addon standards.
- No module reads the data, except where a step says so.
- A switch comes with what it switches, never before (*The switches*).
- Every fact belongs to its game version, and nothing crosses from one game version to another (*Game
  versions kept apart*). Each commit below that touches facts tests it.

## 1a The frame, with CVarLabels the whole way

- [x] **1a.1 The guide.** `Doc/guides/data.md` holds the contracts (Data.md, *Contracts*) and how to add a
  set. `AGENTS.md` and `CLAUDE.md` name it where they list the guides (both are local files, in
  `.gitignore`, edited, never committed; a cloud session hands Saneroki edited copies).
- [x] **1a.2 The master and its check.**
  - Files: `assets/data/builds.toml`, `sources.toml` and `CVarLabels/schema.toml` (decision 3); `dev/data/`
    (Python: schema, check) and `dev/tools/data check`.
  - *CVarLabels* is the first master. `dev/tools/cvar-labels` gains a mode that writes staging; its Lua
    file stays as it is. That staging is taken in as new entries, the import's simplest case.
  - Game versions from the start: every staging line names its own; `builds.toml` and `sources.toml` name it
    too; the check knows the other game versions' files (`<Set>.forever-beta.jsonl`) and refuses a line in
    the wrong file.
  - `dev/tests/run` runs the check and the tools' tests (`dev/tests/data/`): each broken rule is caught.
  - The master lies outside `src/` (decision 3), so no addon folder takes it in.
- [x] **1a.3 Compile, and packs in BUILD.**
  - `dev/data/compile.py` and `dev/tools/data compile <dir>`. It writes rows, history and indexes, at most
    50,000 rows per function, and nothing that changes from one run to the next.
  - Compiled per game version (`--game forever-beta`): live's from the live files only, another's from
    the live files with its own on top; the TOC's `X-SaneUI-Game` and `Data.Add` say which.
  - `dev/build` makes `BUILD/SaneUI_Data_Game` (Forever live's; like all of `BUILD/` not committed,
    decision 4) and installs. It reads the game folder's product (`.flavor.info`): into the beta's folder
    (`_classic_beta_` today) it installs the beta's packs, compiled into a scratch folder. The stale clean-up keeps
    the `SaneUI_Data_*` folders. A pack is made only when one of its sets has entries.
  - The lint knows a pack's TOC: `LoadOnDemand`, the `X-SaneUI-*` lines, its saved variable, and Core's
    `Interface` and `Version`.
  - Tests: the same master compiled twice gives the same bytes; a live pack holds no line of another game
    version; a beta pack is the live files with the beta's on top; sample masters.
  - *In the game:* the addon list shows *Data: Game* under Sane UI, not loaded.
- [x] **1a.4 The scheduler.**
  - `src/Core/Data/Steps.lua`, in `SaneUI.toc`.
  - `wowstub.lua` gains `debugprofilestop`, `GetFramerate`, `C_RestrictedActions` and its event.
  - Tests:
    - no frame over the budget, whatever is queued;
    - nothing in combat or during a restriction, and the jobs go on after;
    - a job that errors is dropped and the others go on;
    - a job of the same name is not started twice;
    - the frame is hidden when there is no work.
- [ ] **1a.5 Packs in the game.**
  - `Codec.lua`, and `Data.lua`:
    - packs found by their TOC lines;
    - `Data.Add`, handles and `Get`;
    - `Prepare`: after the loading screen, one pack a frame, out of combat;
    - `Stamp`, records kept weakly, and failures said once;
    - the client's game version (`WOW_PROJECT_ID`, `IsBetaBuild`, `IsTestBuild`); a pack of another game
      version is refused, and a client that cannot be told refuses every pack.
  - The first lines of `/sane data`: the game version, the packs, loaded or not, and their hash.
  - `wowstub.lua` gains metadata per addon, the addon list, `LoadAddOn` of a compiled pack, and the client's
    game version.
  - Tests:
    - the codec both ways: the Python compiler's samples are read back by Lua;
    - a pack missing, switched off, of a wrong format, of another game version, or asked for in combat;
    - `Get` never loads a pack;
    - frozen records.
  - *In the game:* `/sane data` names the game version (`forever-beta` on the beta; this is also the check
    of what `IsBetaBuild` and `IsTestBuild` answer there) and lists *Game*; after `Prepare`, a CVar's label is
    read.
- [ ] **1a.6 Versions in full.**
  - In the game: `History`, `At`, `Versions`, `Changes`, `Keys`, and patch names from `builds.toml`.
  - The import with its report (`import`, `--apply`, `--take`). Its cases:
    - new;
    - agreeing;
    - a newer build, or the same build on a later day;
    - a conflict;
    - older, put in front;
    - gone;
    - replaces.
  - The commands `show`, `diff` and `stats`.
  - Tests: each import case on sample masters, each within its own game version (a beta build never makes a
    live version); Lua's answers on a sample with history, including a pack newer than the client.
- [ ] **1a.7 Every set's schema.** The sets of *Sets by concern* and *The game's own data*, each checked,
  with empty masters. Real data comes with prompts 2 and 3.

## 1b The Tooltips quests, a real reader

- [ ] **1b.1 The Quests master.**
  - Today's `Tooltips/Data/Quests.lua` is turned into staging once, with a script in the scratchpad, not
    kept (a one-time step). It is imported with source *old*.
  - The Quests pack carries its indexes (givers, drops, starters, items).
  - Tests: every quest of the old file gives the same answers from the pack.
- [ ] **1b.2 Tooltips reads it.**
  - Tooltips calls `Prepare("Quests")` in its `OnLogin`, reads `Data.Set("Quests")`, and redraws when
    `Stamp` moves.
  - Its old file and data code are deleted, and its tests run on a sample pack.
  - First look at `git status` for Tooltips: another session may be working on it.
  - *In the game:* the quest lines in tooltips are as before. With *Data: Quests* off, tooltips show
    nothing of it and raise no error.

## 1c Live data

- [ ] **1c.1 Saved data and learned.** `Live.lua`:
  - Core's inbox in `SaneUIDB.data`;
  - the packs' saved variables: format, checks, `broken`, a lost file warned of, the budget of values;
  - all saved data keyed by game version first;
  - learned rows over the pack's, dropped once the pack is as new;
  - `Stamp` moves.
  - Tests, among them: saved data under another game version's key (a copied `WTF`) is neither used nor
    changed.
- [ ] **1c.2 Series.**
  - The series *Prices*: today's points, the months at logout, the archive handshake (`archivedTo`), and
    the roll-up.
  - Kept per auction house (*Realms and regions*): the house named by region, realm (or connected group)
    and side; a series file per house in the master; the shipped archive run only for the player's houses.
  - `Data.Series`.
  - Tests, among them: one item with two prices on two houses, and none of another house's prices shown.
- [ ] **1c.3 Harvest.**
  - `dev/data/harvest.py` reads saved files as data: a small reader of their Lua, never run. It writes
    staging of accepted data only, and reads the `.bak` file when a saved file is missing.
  - Per game folder: it takes only the part keyed by that folder's own game version (its product in
    `.flavor.info`), and its staging names that game version.
  - Tests with sample saved files, among them two folders whose data go to two game versions.
- [ ] **1c.4 Characters.**
  - `Characters.lua`, and the pack Characters: no shipped data, only its saved variable.
  - Changes are marked, then read in steps; the bank only while it is open; counts across characters; the
    auction log; a character deleted in *Profiles*.
  - Tests.
  - *In the game:* after two characters logged in, `Data.Count` of an item names both.
- [ ] **1c.5 The crawl and the patch check.**
  - `Crawl.lua` and `/sane data crawl <kind>`.
  - The patch check at login: readiness, empty answers, the loading step, *gone* only after two misses,
    and the build noted.
  - The switch *Load client data on load*.
  - Tests.
  - *In the game:* `/sane data crawl spells` runs. An older build put into the saved file starts the
    check.

## 1d Watchers and what they find

- [ ] **1d.1 Watchers, discoveries, chat messages.**
  - `Watch.lua` (marks only) and `Found.lua`.
  - The watchers for vendors, trainers, flight masters and services.
  - The switch *Chat message for new data changes*.
  - Tests.
- [ ] **1d.2 Tooltips and creatures.**
  - Items and spells seen in tooltips (decision 23).
  - Creatures, only out of combat and with no restriction active (`Core.Plain`).
  - `Data.Spell`.
  - Tests.
- [ ] **1d.3 Drops,** with the World pack (decision 24).
  - Loot counted, but only if `GetLootSourceInfo` is there.
  - Build periods, chances, the test for a changed chance, cells.
  - Tests.
- [ ] **1d.4 Quests,** with the Quests pack.
  - The quest watchers.
  - Chains, breadcrumbs and `Missing`.
  - Requirements narrowed by what the game offers.
  - Tests.
- [ ] **1d.5 Areas and the map,** with the Spawns pack.
  - Cells and runs, merging, and the point test.
  - The list per map and `Near`.
  - The area test, behind its check in the game.
  - Tests.

## 1e The auction scan

- [ ] **1e.1 `Scan.lua`,** with the Market pack.
  - `ReplicateItems` when the auction house opens, at most once in 15 minutes.
  - The house told at `AUCTION_HOUSE_SHOW` (region, realm, side); a self-found character scans nothing.
  - The rows read in steps, into today's points of that house.
  - The switch *Chat message for new auction house data*.
  - Tests.

## 1f Sharing, last

- [ ] **1f.1 Its part and the transport.**
  - Sharing's own load-on-demand part (decision 24), with its own saved variable.
  - The switch *Share data with my guild*.
  - The prefix, the inbox and the send queue.
  - Blocks and parts (*Zlib*, Base64) and the limits.
  - The player's own messages are dropped, and so are messages of another game version.
  - Tests with a stub guild.
- [ ] **1f.2 Scans:** have, want, data, and the question at login, each naming its auction house; a
  receiver takes only its own house's. Tests.
- [ ] **1f.3 Bundles.** Tests.
- [ ] **1f.4 Trust.**
  - Shape, quarantine and the game's check.
  - Three senders, counts and prices.
  - Strikes.
  - *Forget shared data*: the button and `/sane data forget`.
  - Tests with hostile members.
  - *In the game:* two accounts in one guild share a scan and a bundle, and a false fact one sends is
    rejected by the other.

## Last

- [ ] **Documents.**
  - The guide, complete; Core's README.
  - `Doc/agent/data.md` and `Doc/agent/core.md`, then `dev/tools/project-index`.
  - `Doc/changelog.txt` for the switches players see.
