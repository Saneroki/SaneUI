# Sane UI: quick context for a new chat

Reviewed 2026-10-14 against source at `be710d5`. This is repository memory, not hidden chat memory.
Use current source and the user's instructions when they differ from a note.

## Read as little as needed

1. Read this page (and root `AGENTS.md` where there is one); check `git status --short` and `git log -5 --oneline`.
2. Read the relevant note below and the matching development guide.
3. Read the current implementation and nearby tests for the requested behaviour.
4. Look up only the needed Blizzard APIs/templates locally. Avoid generated copies in `BUILD/`.

| Task | Next reading |
| --- | --- |
| Lifecycle, events, errors, saved variables, options, shared windows | [core.md](core.md) |
| Future spells, reservations, action layouts, spellbook/Home UI | [abilities.md](abilities.md) |
| Tooltip content, layout, live unit data, quests, prices | [tooltips.md](tooltips.md) |
| Messages, bubbles, native chat, input, filtering/fading | [social.md](social.md) |
| Unit frames, party, raid, buffs, nameplates, pets (not built yet) | `src/Combat/README.md`, `Doc/ideas/Combat.md` |
| NPC talks, books and letters as a scene, part of Social (not built yet) | `Doc/ideas/Dialogue.md` |
| Lore: AI voice overs, a library of the world's lore, tidbits in tooltips (an idea, not built) | `Doc/ideas/Lore.md` |
| Game settings kept per account/character/profile, chat windows, own channels | [sync.md](sync.md) |
| Core's data framework: the master (`assets/data/`), packs, `Data.Set`, the scheduler, the characters (built: 1a, 1b, 1c.4 in part; Tooltips reads Quests, Drops, Characters) | [Doc/guides/data.md](../guides/data.md), then `Doc/ideas/Data-build.md` |
| Build, tests, generators, reference paths, documentation caveats | [development.md](development.md) |
| Locate a declaration or find changed files | `rg -n 'symbol' src dev`; `dev/tools/project-index --check` |

## What exists

Sane UI replaces or extends parts of WoW: Forever's UI. Version `0.3.0`, interface `16001` in all
five TOCs. Modules are independent addons under category/group Sane UI; only Core is required.
Core holds the options (`src/Core/Settings/`, `Core.Config`: pages put up at login, filled when first
opened) and Sync (`src/Core/Sync/`, `Core.Sync`); neither is a module. Abilities extends the game's book with future spells and
reserves action slots. Tooltips draws panels over native tooltips. Social supplies a messenger-style
window and temporarily seats Blizzard's own chat edit boxes in it, and joins or leaves the game's chat
channels as chosen on its page. Combat (2026-10-16) is set up for unit frames, party, raid, buffs,
nameplates and pets; nothing built yet (`src/Combat/README.md`, plan `Doc/ideas/Combat.md`). Sync keeps the game's per-character
settings (CVars, chat windows/channels, Edit Mode layout, action bars) with Sane UI's settings; its switches
are in the tab Accountwide of the options page Profiles, next to the CVar list.

All addon source is Lua and TOCs, plus XML templates (`Core/Settings/Banner.xml`, `Core/Settings/CVars.xml`: settings-list rows);
no package manager or compiled application. Original art ships in `<Module>/Art/`: banners as BLP, Tooltips' masks and shapes as TGA (`dev/tools/tooltip-art`).
Development scripts use Bash, Python 3 and Lua 5.1. Shared global `SaneUI`; account saved variable
`SaneUIDB` and per-character `SaneUICharDB`, declared only by Core. The game's `Settings` global is distinct from `Core.Config` (Sane UI's options).

`/sane` (`/saneui`) lists enabled modules and commands; Core owns `errors`, `options`
(`config`, `settings`), `window`; Abilities owns `spellbook` (`sb`); Social owns `social` (`chat`).
Tooltips has settings but no dedicated slash subcommand.

## Validation and scope of this review

`dev/tests/run` passed on 2026-10-14: lint (5 addons, 61 TOC files) and **1,117 checks**:
Core/Settings 80; Abilities 274 + 270 without Settings; Tooltips 252; Social 185; Windows 56.
These numbers are a dated baseline; run the suite to obtain current results.

Review covered addon implementation, TOCs, module documentation, guides, development tools,
test harness/coverage and recent architectural history. Data tables were inspected by schema,
registration and provenance, rather than reproducing every numeric record in these notes.
The index fingerprints every project file in its scope, including complete data-file contents.
Generated build copies, personal saved settings, IDE metadata and the roughly 16 GB local external
reference library were not exhaustively read. There is no need for future chats to do that either.

The current module changes have substantial pending in-game QA. Earlier tooltip panels were tried;
that does not validate today's layouts. See module READMEs for detailed human QA lists.

## Keeping the memory useful

These notes contain stable architecture and traps, not a duplicate manual or task diary. Update the
affected note when a contract, file responsibility or workflow changes. Keep user-facing behaviour
in module READMEs and record actual changes in `Doc/Changed.md`.

`files.json` is a generated navigation index with SHA-256 hashes, sizes, source declaration line
numbers, Markdown headings and TOC load order. Do not read it whole. Use `--check` to identify stale
files, or query a selected entry with Python. After rereading changed source and updating prose,
run `dev/tools/project-index`; refreshing hashes alone does not refresh the notes.
