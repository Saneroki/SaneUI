# Sane UI: Combat

**Status:** its window and full screen built: docked at the bottom middle, the bottom edge's middle half (or your spellbook or talents key) fills the screen with our own spellbook and talents (built), as the game's, on Core's board; quest marks beside nameplates · **Since:** 2026-10-16 · **Addon:** `SaneUI_Combat` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for everything about the fight: your own frame, your target's (and its target's), your
focus and your pet, the party and the raid, your buffs and debuffs, and what goes with them (cast bars,
totems, bosses). Each part, once built, gives the game's own frame back when it fails. The plan is in
`Doc/ideas/Combat.md`; the nameplates are a module of their own (`src/Nameplates/`).

Built so far: its window, docked in the screen's bottom middle. Push the mouse against the middle half of
the bottom edge, or press your spellbook or talents key, and it fills the screen with our own spellbook and
talents windows, which look and work as the game's, on Core's board that you arrange; push there again, press
the key again, or Esc, and it goes back. A talent planner Sane UI knows is a window of its own there.

## How to use
- **Switch it on or off:** tick or untick *Combat* under *Sane UI* in the game's addon list.
- **The full screen:** push the mouse against the bottom edge of the screen anywhere in its middle half
  (a quarter of the screen's width either side of the middle). Push there again, or press Esc, to go back.
  Not in Edit Mode, and not with *Can expand to fullscreen* off (*Sane UI > Combat > Expand window*).
- **Your keys:** the keys you gave the game's spellbook (P), pet spellbook and talents (N) open the full
  screen with that window on it (the pet's: the spellbook at the pet's tab), and close it again, as they do
  the game's windows. Your key bindings stay as they are; *Your spellbook and talents keys open ours* off,
  they open the game's own windows again. In the game's key bindings, under *Sane UI*, Combat's own keys for
  the same, to put on other keys.
- **The spellbook:** the game's book, at its size and in its art, scaled to fit its window: both pages where
  the window is wide enough, one page where not (the game's book minimized).
  - A tab per skill line at the top left (the class's, General, professions) and the pet's while your pet has
    spells; each tab's spells under its heading, laid out on the pages as the game's book lays them out; the
    page controls at the bottom right, or the mouse wheel.
  - Each spell as in the game's book: its icon in the game's frame (round for a passive), name and rank, a
    spell still to learn greyed with the level it comes at or *Trainable*, the cooldown, the glow of a spell on
    none of your action bars, a pet ability's autocast, the tooltip.
  - **Click** to cast it, **right click** on a pet ability to switch its autocast, **drag** it onto an action
    bar, **Shift-click** to link it in chat (or to pick it up, as your game's modified clicks say).
  - **In a fight** the book shows, pages and drags as always, but a click does not cast (it says so): cast from
    your action bars then. After the fight, a click casts again.
  - At the top right the game's own settings for its book: *Hide passives*, and *Show all ranks* (not for
    rogues and warriors); they change the game's book too. The full screen's search box finds spells of every
    tab. Flyouts are shown as their spells, one by one (as the game's book with *Use flyouts* off).
- **The talents:** your three talent trees as the game's window shows them in this client, at its size and in
  its art, scaled to fit. Each tree's head shows the points spent in it, the box at the top right your unspent
  points. **Click** a talent to learn a rank, **right click** to take one back (**Shift**: with the talents that
  need it); a choice opens its options. Changes wait: **Apply Changes** applies them (a short cast, shown over
  the trees), the round button beside it undoes them, and with nothing waiting it is **Reset** (class,
  specialization or all). The tabs *Primary* and *Secondary* show either specialization; the inactive one is
  only to look at, with **Activate** to switch. Not in a fight. The full screen's search box marks the talents
  it finds. Before your first talent point it says from which level.
- **The talent planner:** with a talent planner Sane UI knows installed, the dropdown *Windows* has it: ticked,
  it gets a window of its own on the board, opens with it and closes when it goes. Opened any way of its own
  while its window is on the layout, it brings the full screen.
- **Arranging them:** as on every board of Sane UI's. Drag a window's head onto another to swap them or put it
  above, below or beside it; drag the gap between them to share the room anew; the X takes a window off, the
  dropdown *Windows* puts it back. Layouts are tabs after the title: *+* makes one, a right click renames it,
  resets the first or deletes another.
- **The game's own windows:** the full screen's dropdown *Classic windows* has *Spellbook* and *Talents*: the
  full screen goes back and what opens the game's is said: its key, or, while your keys open ours, its button
  in the micro menu (our code does not open the game's spellbook). The game's spellbook has the button *Sane UI*
  left of its sizing button: the game's closes and this full screen comes, with our spellbook or talents.
- **Quest marks beside nameplates:** a creature that belongs to a quest in your log shows a small mark left of
  its nameplate while an objective of it is still to do: a sword to kill it, a sack to loot it, with the count
  still open ("3/8"). It goes once the objective is done. As the game says it in the creature's tooltip; a
  creature the game says nothing about has none. *Quest marks on nameplates* switches it off.
- **Settings:** *Sane UI > Combat*: *Your spellbook and talents keys open ours*, *Quest marks on nameplates*,
  the section *Expand window* (whether it fills the screen, its kind of motion, the background's opacity and
  texture) and *Window corners*.

## Technical details
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked at `BOTTOM` at first,
  `Window.WIDTH` x `Window.HEIGHT`, not sizable, see-through and empty while small (no mouse); in Edit Mode
  its box, to be docked elsewhere. Core's option `strip = Window.STRIP` (0.5): the strip that fills the
  screen is half the screen's side, in its middle, whatever the window's width (Core's `Edge.lua`; its
  length follows `DISPLAY_SIZE_CHANGED` and `UI_SCALE_CHANGED`). `docked`, once it stands full, lays the
  board out (`Board.Show`); `filled` on its way back, and `docked` at rest, take it away (`Board.Hide`).
  `Window.Open(key, tab)` fills the screen with that window on the layout (`Board.Add`, once it stands: Core's
  board adds one only then) and the book at that tab; `Window.Toggle` is that, or back to its size where that
  window is shown already (the keys). Its option `classic` lists the game's spellbook and talents for Core's
  *Classic windows* (`Core.Classic`): `show` says what opens the game's (`Classic.Press`, the binding's name, or
  none while `Keys.Taken()`), `ours` is `Window.Open` of ours.
- **The board** (`Board.lua`): Core's (`Core.Board.New`, kept in `store.board`: layouts behind tabs, a panel
  per window with its head, X and body, the dropdown *Windows*), a registry of parts in files of their own
  (`Board.Part(key, title, least, part, wants)`; a part has `Build(panel)`, `Show(on)`, `Size(w, h)`,
  `Search(text)`, `Present()`, `Leave()`, as Inventory's). `Board.ORDER`: `talents`, `spellbook`, `planner`; the
  dropdown lists those `Present` now (`Board.Present`). The first layout: `Board.FIRST` side by side, the shares
  the game's sizes of their windows (`wants`: the talents' 1218 x 708, the book's 1612 x 702).
- **The spellbook** (`Book/`): our own frames, in the game's art and words, after Camelot's
  `Blizzard_PlayerSpells` (`SpellBook/` and `Camelot/SpellBook/`); the game's own `PlayerSpellsFrame` and its
  templates are not used (the game's entry casts from its own click, `C_SpellBook.CastSpellBookItem`, protected).
  - `Book.lua`, the part: a holder of the game's size (`Book.WIDE` 1612 or `Book.NARROW` 806 x `Book.HIGH` 702),
    scaled to fit its body (`min(1, ...)`), centred; both pages while they can be `Book.TWO` of one page's
    scale (`spellbook-Page-Left-C60`, `-Right-C60`; one page: the right page's art whole). Square icon tabs at
    `Book.TABS` (`spellbook-Tab-Frame-C60`, `-Glow-C60`, `-glow-gradient-C60`, the icon masked by `SquareMask`,
    44 x 32, the game's sound `IG_SPELLBOOK_OPEN`), the views at the game's places (`Book.VIEW_*`), the game's
    `PagingControlsHorizontalTemplate` at `Book.PAGER` (made in our code, it asks its frame's `OnPageChanged`),
    the mouse wheel, and the game's `UIPanelArrowDropdownButtonTemplate` at `Book.SETTINGS` with the CVars
    `spellBookHidePassives` and `ShowAllSpellRanks` (no menu tag: other code's lines for the game's book menu
    stay out). Events only while shown (`Core.On`/`Off`), each burst once a frame (`Core.Later`): the tabs and
    pages anew on `SPELLS_CHANGED`, `LEARNED_SPELL_IN_SKILL_LINE`, `PLAYER_SPECIALIZATION_CHANGED`, `UNIT_PET`; the
    page's entries on `SPELL_UPDATE_COOLDOWN`, `ACTIONBAR_SLOT_CHANGED`, `CURSOR_CHANGED`,
    `UPDATE_SHAPESHIFT_FORM`, `PET_BAR_UPDATE`; the secure buttons with `PLAYER_REGEN_DISABLED`/`_ENABLED`.
  - `Data.lua`: the tabs as the game's Camelot book makes them (`C_SpellBook.GetNumSpellBookSkillLines`,
    `GetSpellBookSkillLineInfo`, not `shouldHide`; General with `GetClassSkillLineInfo`'s icon; the pet's while
    `HasPetSpells` and `PetHasSpellbook`, `GetPetIcon`), each one group under its name; the game's filter
    (`SpellBookFrameMixin:ShouldDisplaySpellBookItem`) with flyouts loose; `Data.Search` over name and rank in
    every tab.
  - `Layout.lua`: the game's paging rules (`PagedContentFrameBaseMixin:ProcessElement`, the condensed vertical
    grid), with Camelot's numbers: views 680 x 590, three columns 15 apart, rows 10 apart, headings and entries
    60 high, groups 20 apart, column by column in `ceil(n / 3)` rows, never a heading alone at a view's foot.
  - `Item.lua`: an entry as `SpellBookItemTemplate` draws it (220 x 60, the button 40, the icon 36; the art sets
    `Item.ART`, Square and Circle, with the game's border anchors; `SPELLBOOK_FONT_COLOR`,
    `SPELLBOOK_UNLEARNED_TINT_COLOR`, `SPELLBOOK_AVAILABLE_AT`, `SPELLBOOK_TRAINABLE`, `SPELL_PASSIVE`), the rank
    from `Spell:ContinueWithCancelOnSpellLoad` where the game has none; the cooldown by
    `GetSpellBookItemCooldownDuration` into `SetCooldownFromDurationObject` (a secret value in a fight is taken
    as it is); the glow by `ActionButtonUtil.GetActionBarStatusForSpell`/`ForPetAction`
    (`MissingFromAllBars`, not auto attacks), its tooltip line `TALENT_BUTTON_TOOLTIP_NOT_ON_ACTION_BAR`;
    autocast by `GetSpellBookItemAutoCast`; `C_LevelLink.IsSpellLocked`; tooltip `SetSpellBookItem`; drag and
    `PICKUPACTION` by `PickupSpellBookItem`, `CHATLINK` by the item's (trade skill) link. Nothing of the game's
    action bars is written (no highlight marks).
  - `Casts.lua`: the cast. `SecureActionButtonTemplate` buttons on UIParent, each over the icon of a castable
    entry (`Item.Castable`: a learned spell, a pet ability), in UIParent's units, `Book.LEVEL` above the panel's
    body: `type` `spell` and `spell` the spell's ID (the rank it is); a pet ability `macro`, `/cast` its name, the
    right click `/petautocasttoggle` where it may autocast; `checkselfcast`, `useOnKeyDown = false`, no cast on
    Shift (`shift-type*` empty: `PostClick` links or picks it up). Made, set, placed, shown and hidden out of a
    fight only; all hidden at `PLAYER_REGEN_DISABLED` (the game locks them after it), set again after
    `PLAYER_REGEN_ENABLED`. Not in our window, so the full screen never becomes protected.
- **The talents** (`Talents/`): the game's shared talent frame (`TalentFrameBaseTemplate`,
  `Blizzard_SharedTalentUI`, loaded with `C_AddOns.LoadAddOn` in a `pcall` where it is not yet) inherited, as the
  game's class frame inherits it; the class layer the game's window adds lives in `Blizzard_PlayerSpells`, which
  is never loaded, so it is ported: the frame's keys, layers, gates, events and the game's talent search
  (`ClassTalentSearchMixin`, `Tree.lua`), the nodes' templates and the class glow, tooltip and sounds
  (`Nodes.lua`), the class's background, clouds, lights, frame and dividers (`Art.lua`), the trees' heads
  (x = 140 + 400 (i - 1), y = -100; `C_Traits.GetGroupCurrencyInfo`) and the unspent points (`Headers.lua`), the
  dual-spec tabs (the game's `TabSystemTemplate`, `GetCombatConfigIDForSpecGroup`, `SetActiveSpecGroup`;
  `Specs.lua`), Apply, Undo and Reset (`Foot.lua`; `C_ClassTalents.CommitConfig`, `C_Traits.RollbackConfig`,
  `ResetTreeByCurrency`, `PurchaseRank`, `RefundRank`, `SetSelection`; `Changes.lua`), the commit's cast on a cast
  bar of ours from the game's `CastingBarFrameTemplate` (`ApplyingTalents`, run with your casts only while a
  commit or switch is under way; the game's spinner after half a second without one; `Commit.lua`). The art
  (1212 x 701) scaled to fit the panel's body, centred (`Talents.lua`). Every method of ours on the frame and
  every script the game's templates gave our frames is behind the module's guard (`Talents.Wrap`); nothing of
  the game's window, casting bars or tables is written. Changes only on the active specialization and out of a
  fight; Apply as `C_ClassTalents.CanChangeTalents` says. Zoom and pan off; events only while shown. Left out
  as the Camelot window has them not: loadouts, starter builds, hero talents, inspecting; also the node sheen,
  the purchase effects and the action bars' marks (they write the game's bars).
- **The keys** (`Keys.lua`, `Bindings.xml`): Combat's keys `SANEUI_COMBAT_SPELLBOOK`, `_PETBOOK`, `_TALENTS`
  (Sane UI's section in the game's key bindings) run `Keys.Press` (`Window.Toggle`). `SetOverrideBinding` on a
  frame of ours puts them on the keys of `TOGGLESPELLBOOK`, `TOGGLEPETBOOK`, `TOGGLETALENTS`
  (`GetBindingKey`): at the login, on `UPDATE_BINDINGS` when those actions' keys changed, cleared
  (`ClearOverrideBindings`) with the switch `keys` off and at standing down; out of a fight only (else after it,
  `Core.AfterCombat`).
- **The planner** (`Board.lua`; Core's `Neighbours.lua`, the one file that names the addons Sane UI knows): the
  part `planner`, present while `Core.Neighbours.Window("talents")` gives a handle. Its panel shown, the planner
  is opened by its own function and seated in the body (Core's `Seat.lua`: only its place, scale and layer lent),
  a frame later (`Core.Later`); the panel hidden, given back and closed. Its opening followed once, from the
  login or when its addon is first there: while its panel is on the layout, the full screen comes.
- **Quest marks** (`QuestMarks.lua`): on `NAME_PLATE_UNIT_ADDED` a frame of ours on the plate the game gives
  (`C_NamePlate.GetNamePlateForUnit`: none for a forbidden plate; none for players), left of its health bar
  where it has one (its fields read with `rawget`, never written), one per plate, kept while it shows.
  `QuestMarks.Read`: `C_QuestLog.UnitIsRelatedToActiveQuest` first, then the tooltip data's lines of the kind
  `QuestObjective` (`C_TooltipInfo.GetUnit`): the first not `completed` and not full ("8/8") is the mark, the
  sword (`Interface\CURSOR\Attack`) where its text names the creature, else the sack
  (`Interface\CURSOR\LootAll`), the count left of it. A secret value (a fight) leaves the mark as it was.
  Looked at again on `QUEST_LOG_UPDATE` and `UNIT_QUEST_LOG_CHANGED`, once a frame (`Core.Later`).
- **Standing down** (`ns.GiveBack`): each part gives back what it lent (the planner) and hides what is protected
  (the book's secure buttons, now or after the fight), the keys are the game's again, the window hides, the
  quest marks hide.
- Tests: `dev/tests/combat.lua` (the window, the board, the keys, the planner, the quest marks),
  `dev/tests/book.lua` (the spellbook), `dev/tests/talents.lua` (the talents).

## Files

| File | What it holds |
|---|---|
| `SaneUI_Combat.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Bindings.xml` | Combat's keys in the game's key bindings, under Sane UI (the game reads it by itself) |
| `Combat.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (the keys, the quest marks, Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Window.lua` | Its window: docked at the bottom middle, filling the screen from the bottom edge's middle half; full, Core's board; the game's windows in *Classic windows* |
| `Board.lua` | The full screen's windows on Core's board, each a part that registers itself; the talent planner's |
| `Book/Layout.lua` | Where each entry stands on the pages, by the game's rules |
| `Book/Data.lua` | What the book holds: the game's tabs, their spells as its book shows them, the search |
| `Book/Item.lua` | One entry, as the game's |
| `Book/Casts.lua` | The game's secure buttons over the icons, which cast out of a fight |
| `Book/Book.lua` | The spellbook: pages, tabs, the game's paging controls and settings |
| `Talents/Talents.lua` | The talents: the part on the board, the game's shared talent frame loaded and fitted into its panel, its words |
| `Talents/Nodes.lua` | The nodes: the game's shared node buttons with the class talents' glow, tooltip and sounds; the arrows |
| `Talents/Art.lua` | What the trees stand on: the class's picture, its clouds and lights, the frame and dividers, the commit's flash |
| `Talents/Headers.lua` | Each tree's head with the points spent in it, and the unspent points |
| `Talents/Specs.lua` | The primary and secondary specialization: the game's tabs, Active or Activate |
| `Talents/Foot.lua` | Apply Changes, Undo and the Reset menu |
| `Talents/Commit.lua` | The commit's and the switch's cast over the trees, on a cast bar of ours from the game's template |
| `Talents/Changes.lua` | Buying, refunding, applying, undoing and resetting, where the game allows it |
| `Talents/Tree.lua` | The frame: the game's shared talent frame with the class layer over it, its events while shown |
| `Keys.lua` | Your spellbook, pet book and talents keys opening ours |
| `QuestMarks.lua` | A mark beside a creature's nameplate while it belongs to an objective of your quests still to do |

## History
- **2026-10-16:** set up as a module of its own, for party, raid, buffs, unit frames, nameplates and pets.
- **2026-10-20:** its window, docked at the bottom middle (Saneroki); the bottom edge's middle half fills the
  screen with the talents and the spellbook as panels; a talent planner Sane UI knows as the Talents panel.
- **2026-10-20:** quest marks beside nameplates (Saneroki), from the game's own tooltip data.
- **2026-10-20:** the full screen on Core's board (Saneroki): layouts behind tabs, the windows arranged as on
  every board; an empty window of the game's opens with a click anywhere in it instead of an *Open* button.
- **2026-10-20:** our own spellbook (Saneroki: the spellbook and talents are Combat's own windows, as the game's;
  the book casts out of a fight only); your spellbook and talents keys open ours; the talent planner a window
  of its own; the game's window no longer seated.
- **2026-10-20:** our own talents (the game's shared talent frame with the Camelot class layer ported).
