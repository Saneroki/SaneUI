# Abilities

## Data and reservation flow

`Abilities.lua` registers module/options/commands, bars and saved state. Login fills class-specific
trainer data and hooks events; the first `PLAYER_ENTERING_WORLD` waits 2 s before setting `ready`.
`QueueUpdate(scan, delay)` coalesces events (normally 0.2 s) → `Sources.ScanBook` outside combat →
learn form-page names → `Engine.Reconcile` → module `REFRESH`.

| File | Job |
| --- | --- |
| `Sources.lua` | Known castable rank by name; lazy future-spell list; trainer visits, talent discovery, tab assignment |
| `Data/Trainer.lua` | Class registration; reads families + conditions into `D.spells` (faction/race filtered); next-rank links for `D.Learned`; spell texts |
| `Data/Classes/*.lua` | Hand-edited. Families: one string per spell, ranks in order as `spell:level:copper` (bare `spell` = rank not sold, e.g. start/quest). Conditions by spell ID: `talent`, `after`, `alone` (no rank-before requirement), `side`, `raceIDs`; each holds for its rank and later ranks until overridden |
| `Data/QuestSpells.lua`, `WeaponSkills.lua`, `SkillLines.lua` | Race-specific rewards; weapon skills; English tab fallback and talent-tree lines |
| `Engine.lua` | Reserve/clear/reconcile slots; defer real actions for combat or busy cursor |
| `Presets.lua` | Class-shared saved bar layouts and save/load dialogs |
| `Ghosts.lua` | Noninteractive grey overlays on real empty action buttons |

Entry shape: `{kind = "spell"|"item"|"macro", id, name, icon}`. Future spells add `sub/rank/level/cost`,
`prior` (rank before), `talentFirst`, `after`, quest, tab, source and state. States, checked in the game
spellbook's order (level first): `level`, `talentfirst`, `spellfirst` (+`missing`), `quest`, `trainable`;
`talent` (tree) and `other` (manual). `D.Learned(id)`: that rank or any later rank of its family is known. Spells match by name across ranks, items by ID, macros
by name. **The player's latest placement wins:** real action and reservation never coexist by
intent. Secret `HasAction` returns the sentinel `"unknown"`; reconciliation must not act on it.
Empty slots can be reserved during combat, but real action mutations require no combat and empty
cursor. Engine has 1 s grace after own changes, and tracks automatic pushes for 60 s using the
exact `SPELL_PUSHED_TO_ACTIONBAR` slot; never remove the player's other copy of that spell.

Eight managed bar offsets: `0,60,48,24,36,144,156,168`; 12 buttons each. Bar 1 form rows add
`72,84,96,108`; read current button `.action` for paging. Other bars' buttons are found by the slot
they carry (`ns.ActionOf`).

Saved under `modules.Abilities`: `options`, `chars[GUID].reserved[slot]`, `presets[class][name]`
(`slots/by`), `extras[class]`, `trainer[class]` (`tabs/spells/told`), `pageNames[class]`, `diag`,
`window` (`large/small` sizes, `left/top`). Preset loading leaves `kind="other"` actions alone.

Future list is built only on `Sources.All()` when stale. Sources: own trainer data, weapon skills,
stored trainer observations, client traits, manual extras. Missing spell texts are requested once;
load events invalidate. Tab priority: known rank → trainer category → game skill-line probe → English
static mapping → talent tree. Unknown active spells go to first class tab; passives/skills to General.
Class data is registered as closures; only the player's class builds its table at login.
A book rank named with a numeral (*Instant Poison II* + *Rank 2*) is the trainer's *Instant Poison*
(`D.FamilyName`): `ScanBook` keys `known/has/knownTab` by both names, `Collect` groups by the base name,
`UndoPushes` matches a reservation by either.

## Abilities UI: preserve secure execution

The module must leave learned-spell creation and clicks with Blizzard. Writing native page numbers,
providers or frame fields can taint casting and action bars. The workaround is deliberate:

- `Book/Book.lua` raises native first column to **60000**, letting Blizzard create the whole tab.
  It collects native frames read-only, then places/scales them alongside our grey entries.
  Other pages and folded ranks park at `-8000`; our pager replaces the offscreen native pager.
- `Book/Layout.lua` has pure pagination/merge/sort. Compact scale is 0.75; dimensions follow window
  size; coordinates account for scaled anchors. Rank families fold unless expanded by our buttons.
- `Book/Item.lua` makes independent grey entries, tooltips, links, reservation/quest marks and menus.
  `Book/Drag.lua` carries an addon icon because the native cursor refuses unknown spells.
- `Book/Home.lua` adds a **separate button**, not a native tab. It shifts native tab row by 46,
  parks underlying entries with `SetHome`, covers selected native tab visually. Trainer-now total
  and quest rewards use shared row/layout helpers; overflow is counted, not paged here.
- `Book/Window.lua` uses Core mover/sizer for `PlayerSpellsFrame`; reapplies saved dimensions only
  while our book is armed and the spellbook is shown, outside combat. Talents keep native sizing.
  `Book/Menu.lua` appends via `Menu.ModifyMenu("MENU_SPELL_BOOK_SETTINGS", ...)`.

`Book.StandDown` restores column/pager, scales and placement as far as possible; Home/window hear
`BOOK_PAGES`. Protected frames wait until `PLAYER_REGEN_ENABLED`. Controller mode, failed setup or
repeated conflicting placement cause fallback. After fallback, changing tabs lets Blizzard redraw.
Watcher runs 10 frames after layout, then every 0.2 s only while visible.

Options: `showHidden/home/compact/window/ghosts/announce/book`, initially true. `book` takes effect
after reload. Commands: `list/clear/debug/add/item/save/load/delete/layouts/pages/window reset`.
Tests: `dev/tests/abilities.lua`; made-up families stand in for class tables, real class files are format-checked.
Pending QA: learned-spell casting/taint, combat/flyouts, skins, Home tabs/search, resize/minimise,
weapon-skill recognition and compact readability. See module README for exact checks.
