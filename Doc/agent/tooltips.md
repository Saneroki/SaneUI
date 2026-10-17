# Tooltips

## Pipeline and files

`Tooltips.lua`: post-call/Show hooks → `Filled` queues once → end-of-frame driver `Settle` → `Draw`
→ `ns.Read` → `Model.Commit` → `Panel.Draw` only when changed/invalidated → `Host.Seat`.
Wait until end of frame because Blizzard and other addons append comparison lines after callbacks.
Read primary tooltip data rather than interpreting appended data as a new tooltip.

| File | Responsibility |
| --- | --- |
| `Texts.lua` | Own words, localized-global patterns (`Pattern`); a spell's facts by the game's sentences (`ns.FACTS`: `MANA_COST`, `SPELL_RANGE`, `SPELL_CAST_TIME_*`, the cooldown sentences, ...); English school/heal/control words |
| `Model.lua` | Reused `shown/fill` buffers, row/head field lists (a strip's cells in its array part, compared too); the palette `ns.COLOR`: the game's font colours (`GameColor`, with fallbacks) moved toward each other (`Mix`/`Tone`); `Hex`, `Like` (a line's colour near one of the game's, ±0.12) |
| `Read.lua` | Actual native lines/colours, align data by index/text, readers' helpers, Alt details |
| `Kinds/Item.lua` | Binding/appearance, kind/slot, requirements, stats, recipes, durability; sections Quest (`Quests.Item`) and Professions (*Used in*, by trade-goods subclass); a comparison gets only added lines and its vendor price |
| `Kinds/Inventory.lua` | Inventory section: `Data.Count(item)` per character (you first, the others by name from `Data.Characters()`, the account's bank last), whole names in class colours, *Bags/Bank/Worn* counts, Total with two or more; five without Alt |
| `Kinds/Gold.lua` | Gold section, always per one: *Vendor* (`GetItemInfo`), *AH profit* (`Gold.Sale`: own lowest price less 5% cut; not when bound); one advice line (AH needs 5% over vendor; *Buy if under* on AH listings, by getter name); Alt: lowest, cut, deposit (60% of vendor) |
| `Kinds/Spell.lua` | School (combat-log colours, `STRING_SCHOOL_*` names)/category; a facts strip in the game's order cost, range, cast, cooldown with cells only for stated facts; a numbers strip (per second, amount, per power or swing speed, crit; cells only for known numbers) |
| `Kinds/Unit.lua` | Unit header, portrait/rank, inspection, target/bars, quest section |
| `Kinds/Aura.lua`, `Quest.lua` | Aura found by its getter (`GETTERS`: exact getter name → by instance or list filter); colour of what removes it (`AuraUtil`, `None` for a debuff), none for a plain buff; timer/caster. Quest state/objectives |
| `Numbers.lua` | Description cut at its numbers into amounts/times; per second when cast again and again; swing stats, mana share, XP from one table |
| `Quests.lua` | Quest lists over Core's sets `Quests` and `Drops` (`Keys` by `byStartNPC`, `byFinishNPC`, `byStartItem`, `byObjective`; `Get("npc:<id>")` of Drops): creature and item lists, quest standing; `Start(redraw)` prepares both sets at login and redraws on their stamps |
| `Live.lua` | The parts of a panel that change while it is shown: a unit's health/power, target, auras, a buff's running time; run from the panel's OnUpdate every 0.1 s (auras 0.5 s), in its own `xpcall` |
| `Inspect.lua` | Paced item level and talent inspection/cache |
| `Auction.lua` | Passive browse-price observations and expiry |
| `Pools.lua` | Pools `panel.texts/lines/icons/bars` = `Core.Pool` (`taken`, `:Take()`); `Reset` hides only the last draw's parts, then `:Begin()`; a text redressed only when its kind or the fonts change (`Restyle` stamp); `Width` = whole unit past the end; separate live widgets |
| `Panel.lua` | `Measure` → `Fit` (224..432 in steps of 8; wrapping rows ≤ 22 ems) → `Picture` (icon/plaque) → `Lay` (rows; right side gives way, keeps 4 ems; captions left with a rule; strip cells sized by their words) → `Finish` (ground `TOOLTIP_DEFAULT_BACKGROUND_COLOR` tinted 28% top / darkened + 6% bottom, dragon, levels); hairline = `PixelUtil.GetNearestPixelSize(1, scale, 1)`; one lazy panel per native tooltip; the 3D model in the picture's place (`Figure`, option `models`: `panel.figure` `PlayerModel` for a unit (`SetUnit`, ready at once) or a display (`SetDisplayInfo`), `panel.dresser` `DressUpModel` for gear (`SetUnit("player")` once, then `Dress` + `TryOn(link)`); given only when `head.model`/GUID changes, forgotten on hide; the picture until `OnModelLoaded`/`GetModelFileID`, kept when the load fails; `panel.figured` is the active one, its alpha by `Panel.Strength` and readiness; dragon/plaque/level on `panel.front` over it) |
| `Figures.lua` | `Figures.Item(head, id, tooltip)` / `Figures.Spell(head, id)` set `head.model`, `modelKind` (`display`/`dress`), `modelZoom`, `modelTurn`: a mount (`C_MountJournal.GetMountFromItem`/`FromSpell` → `GetMountInfoExtraByID` or first of `GetMountAllCreatureDisplayInfoByID`), a pet (`C_PetJournal.GetPetInfoByItemID` 12th answer), dressable gear (`C_Item.IsDressableItemByID`, else by equip location; zoom/turn by equip location; the link from `tooltip:GetItem()`); cached per id (nil = ask again) |
| `Host.lua` | `Dim`/`Blank`/`Keep` alphas, `Free` restores; `Seat` = blank + place + mouse reach; `Hold` on refresh; places panels by corner, `Beside` (one point on the other panel by the game's side), comparisons at own absolute slots (`Compare`/`Lay`/`Track`, gap = 2 × soft edge) |

`ns.KINDS[dataType]` maps to a reader; unknown type uses Generic. Context contains native lines,
fill/head, model and options. Readers mark consumed lines; `Read.Rest` shows the remaining game lines
only, each in the section `ctx.name(line, index, fresh)` names (default `Read.Named`: Description or
Details; Item: Stats/Effects/Set/Description by line type, `ITEM_SET_NAME` or colour family; Quest: always
Description; nested recipe product stays in `Creates`); a new name opens `Read.Section(name)` (caption, or the
same section: the game's blank → `ctx.gap` → row `space`). `Read.Generic` sets `ctx.flat` (no sections, blank
→ gap). No row has a divider of its own: captions are the only rules (`ROW` has `space`, no `rule`). Kinds
open their own sections with `Read.Section`/`Read.Caption` (`ctx.section` = current name). Other addons'
lines (`Read.Added`: not in the data; with `lineIndex` (`ctx.placed`) anywhere after the first data line,
`ctx.firstOwn`, else after the last, `ctx.lastOwn`) never reach a reader's rows: `ns.Read` appends them after
the kind's rows and Alt's `Details` (caption `TEXT.IDS`), in one section `Others` (caption `TEXT.ADDONS` =
"Addons", small, ASIDE colour, blank → gap). PTR feedback and redundant ID lines are omitted (an ID line is read plain by `C_StringUtil.StripHyperlinks`,
else `Core.Fuzzy.Plain`, which keeps square brackets). Model rows:
`text/strip/bar/caption/auras`. Adding a model field requires including it in
`HEAD` or `ROW` reset/comparison lists, or stale fields/undetected changes can result.

## Fallback and secrets

Reader failure disables that **reader function** for the session (shared types may share it), leaving
its tooltips native. Other guarded failures stand down the module and release all native tooltips.
Cursor-anchor hook is `Safe`, so it remains useful independently of panels.
Forbidden/embedded/invisible/unplaced scanner tooltips are excluded. Unreadable secret text, extra
embedded frames/bars/unsupported money, or secret measurement means native fallback for that draw.

Do not resize or reposition native tooltips: Blizzard comparison placement depends on their size.
Panels anchor by corresponding corner or beside another panel, with cyclic-anchor fallback.
`Host.Free` restores native alpha first, then pieces independently; clear panel anchors on release.
A fill of a tooltip that is not on screen only dims it (`Host.Dim`: its own alpha); `Host.Blank` (also
each piece, which stays at 0 while the game fades it) is for one on screen and at every draw (`Seat`).
`panel.linesRead` is the line count at the last read; a different count in `Watch` means a redraw.
`Read` marks a line by the first data line naming its index (a data line without text gets the last line's).

Live health/power can pass secret values directly to permitted widgets/formatters. **Never measure
or reuse those widgets for plain text.** Pools keeps live texts/bars separate. Panel clears anchors
before measuring; `Pools.Spoilt()` rejects secret sizes. Aura queries require no combat and open
`C_Secrets`; updates are 0.1 s for numbers, 0.5 s for auras, maximum 16 aura icons. GUID mismatch
freezes the fading unit panel rather than reading a new `mouseover` unit. `Live.Start`/`Update` run in their
own `xpcall`: a failure is reported once and switches live values off, not the module.

## Data and limits

- Inspect: one request at a time, at least 2 s after anybody's NotifyInspect; same GUID retry 15 s,
  timeout 5 s, cached result 300 s. No combat, open native inspection, or out-of-range requests.
  Own talents refresh after 5 s. Specs **are implemented** using trait groups/points.
- Auction: no server requests; note minimum browse buyout. Saved `prices[item]` copper and
  `seen[item]` epoch day; expire over 30 days on startup. The only price source of `Kinds/Gold.lua`.
- Quest data is Core's (`Doc/guides/data.md`; master `assets/data/Quests`, `assets/data/Drops`, source
  `old` = the former module file, taken in once). Quests: `level`, `minLevel`, `maxLevel`, `side`
  (`alliance`/`horde`), `races`, `classes`, `requires` {kind done/one/closed, quest (plain ID), side},
  `startNPCs`/`finishNPCs` {npc, side}, `startItems`, `objectives` {index (the game's number), kind loot,
  what item}. Drops `npc:<id>` → items {item, chance (whole %, 0 = <1)}; the quests wanting an item come
  from `byObjective` (check `kind == "loot"`, IDs overlap). Records are shared/read-only: derive, never
  write. Lists cached per NPC/item until a quest-log, level or stamp change; nil sets → empty lists.
  List kinds: drop, opener, due, give, wants; item states: log, open, soon, done.
- Characters (Core `Data/Characters.lua`, pack `SaneUI_Data_Characters`, saved only): `Data.Count(item)` →
  `{ total, [guid] = { bags, bank, worn }, account = { bank } }`, nil until counted. Names shown are the
  stored whole names (never a first name alone).
- A spell's facts strip works in every language (the game's sentences); its school and derived amounts
  need enUS/enGB descriptions: elsewhere no school colour and no numbers strip.
  Estimates are presentation, not combat decisions; client-hidden inputs give no calculated answer.
- Six own TGA assets come from `dev/tools/tooltip-art` (including plaque); other art uses client paths.

Saved `modules.Tooltips`: `options`, `version` migration (currently 3: 2 opacity 90→97, 3 `cursor` a choice and
`show` added), `prices`, `seen`.
Options: `show="always"` (or while a key is held), `cursor="default"` (where the game puts them | while a key is
held | always), `classColors/icons/models=true` (`models`: "3D model in tooltips"; a model needs a picture,
so `icons` too), `textSize=14 (10..20)`, `opacity=97 (30..100)`.
`ns.options` = `Core.Settings(ns.name)`; `ns.store` = `Core.Store` (prices). Changes invalidate `panel.drawn`;
redraw on subsequent tooltip work. Kept, not Core's kit (2026-10-17): Host's alpha ledger
(`Core.Lend` would hold a protected tooltip's alpha back in a fight and costs three tables per piece) and
the `FONTS`/`Sizes` dressing (follows the game's font objects live; `Core.Font` copies one into a named font).
Tests: `dev/tests/tooltips.lua` (412 checks; it loads Core's `Core`, `Kit`, `Motion`, `Saved`, `Profiles`, `Fuzzy` and `Data/`;
`shape(panel)` lists rows with captions by name; sample packs from `dev/tests/data/tooltips/` via `dev/tests/data/packs.py`,
the stub's default Characters pack, `Steps()` pumps the scheduler and the next frame).
In-game QA still needed for current layouts, comparison stability, secret values, inspection/specs,
quest offers, dragon/plaque alignment and coexistence; for the palette from the game's colours, the facts
strip by the game's sentences (each client's wording), width steps, captions with a rule, hairlines at 4K.

The redesign (AI art, layered looks): `Doc/ideas/Tooltips/Types.md` is the catalogue of every type and
look, `Doc/ideas/Tooltips/Build.md` how it is built (facts → `Look.lua` → `Looks.lua` → layers) and in
which steps. Read both before working on it.
