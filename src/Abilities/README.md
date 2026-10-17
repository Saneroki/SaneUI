# Sane UI: Abilities

**Status:** written and tested offline · **Since:** 2026-10-08 (as the addon *Actionbar Organizer*), a Sane UI module since 2026-10-14 · **Addon:** `SaneUI_Abilities` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for your spells and abilities (it was called *Spellbook*; it will do more than the spellbook).
Your normal spellbook (P) also lists the spells you have **not learned yet**, in grey, in the tab where
they will end up. Drag a grey spell onto an action bar button: the button is *reserved* and becomes the
real spell the moment you learn it. A **Home** page, the first tab of the spellbook, says what your
trainer can teach you right now and which spells you get from quests.

## How to use
- **Switch it on or off:** tick or untick *Abilities* under *Sane UI* in the game's addon list.
  Switched off, the game's spellbook is the game's own again; your reservations and settings are kept
  for when you switch it back on.
- **Open the spellbook (P).** It opens on **Home**, the tab with the hearthstone in front of the
  spellbook's own tabs (they stand one tab further right to make room). Left page: what your trainer
  teaches you now, each with its price, and the total above. Right page: the spells that are quest
  rewards, under the level you get them at (fainter for a level you have not reached), with the place
  the quest starts. Click any other tab to go to your spells; click the hearthstone to come back.
- **Move and resize the spellbook.** Drag the bar at the top of the window to move it. Drag the grip in
  its lower right corner to give it any size and shape; the pages fill it with as many columns and rows
  as fit. The size (one for the open book, one for the small spellbook) and the place are kept. Not in a
  fight. `/sane ab window reset` gives the game's own size back. Switch: *Move and resize the
  spellbook*.
- **Compact pages** (switch *Compact spellbook pages*, on): entries are drawn at three quarters of
  their size and stand closer, four columns of ten instead of three of seven on the game's own page.
- **The General tab** has two sections under its own spells: *Passive spells to learn* (every passive
  spell still to come, whichever tab it would otherwise be in) and *Skills to learn* (the weapon skills
  your class can learn from a weapon master).
- **Ranks fold into one entry.** With *Show all spell ranks* on, a spell with several ranks takes one
  place: the highest rank you have, or the lowest you can still learn. Click the small **+** on it and
  all its ranks stand in a section of their own under the tab's spells; click that section's heading
  (the **−** and the spell's name) to fold them away again. Folding is forgotten at `/reload`.
- **The checkbox next to the page buttons,** *Show unlearned spells*, switches the grey entries, the two
  General sections included, on and off. It is the same switch as in the menu and the options.
- **In the other tabs,** grey entries are spells still to come. The third line says when:
  *Available at level 12*, *Available at a trainer* (you can train it now), *Needs the rank before it*,
  *Needs Bear Form first*, *Needs a talent first*, *Talent*, *From a quest*.
- **Two marks on an icon:** a yellow **!** at the top left means *a quest reward*: not learned yet, and
  not sold by the trainer; you get it from a quest. A small **clock** at
  the bottom right means *a button is reserved for this*. The reserved button on your action bar carries
  the same clock; point at it for the spell's tooltip. With *Show all spell ranks* on, only the rank you
  dragged carries the clock; while the ranks are folded into one entry, that entry carries it.
- **The small arrow at the top right of the spellbook** has the options:
  - *Show unlearned spells*: the grey entries on or off.
  - *Open the spellbook on its Home page* (options page only): off = the spellbook opens on the tab you
    last looked at.
  - *Show all spell ranks*: off = one icon per spell; on = one icon for every rank, learned or not.
    (The game's own option; the module adds the line for warriors and rogues, who do not get it.)
  - *Show reservations on the action bars*, *Say in chat when a reserved button is filled*.
  - *Action bar layouts*: save all your bars under a name, load them again later (per class).

  The switches are also in the game's options:
  Esc > Options > AddOns > Sane UI > Abilities, or `/sane options`.
- **Reserve a button:** drag a grey spell onto any button of action bars 1–8. A gold frame shows the
  button you are over. What was on that button is on your cursor afterwards, as when you swap two buttons.
- **Move a reservation:** drag the grey icon on the action bar to another button, the way you move a
  real action: with the bars unlocked, or with the pick-up key (Shift by default) held. On a reserved
  button the two change places; on a real action, that action goes onto your cursor. Let go where there
  is no button and the reservation is taken off, as a real action is. Also where the bar hides its empty buttons.
- **Remove a reservation:** right-click the grey spell in the spellbook → *Remove from Bar 2, button 5*.
  Or drop any real spell on the button. Or `/sane ab clear` for all of them.
- **Link a spell in chat:** Shift-click it (grey ones too).
- **Visit your class trainer once.** Not needed for the list, but his window says which spellbook tab
  each spell belongs to. Until then a few new spells sit under *Other spells to learn* in the first class tab.
- **Rules to know:**
  1. What you put on a button last wins. A real spell dropped on a reserved button ends the reservation.
  2. Real buttons only change out of combat (a game rule). An empty button can be reserved in a fight.
  3. Spells count by name: a reservation for *Fireball* is met by any rank.
- **Commands:** `/sane abilities` lists them; `/sane ab` is short for it. `/sane ab list` shows your
  reservations, `/sane ab debug` what the lists were built from.
- **If the spellbook ever looks wrong:** `/sane ab pages off`, then `/reload`. The game then draws its pages
  itself again (no grey entries); everything else keeps working. `/sane errors` shows what went wrong.

## Technical details
- **Part of Sane UI, and an addon of its own** (`SaneUI_Abilities.toc`: `## Dependencies: SaneUI`,
  `## Group: SaneUI`). The module is made with `Core.NewModule(ADDON, "Abilities", ns)` in `Abilities.lua`;
  `ns` in every file is that table, the one the game hands every file of this addon. Chat lines, game
  events, error catching and the saved settings come from Core. It needs no other module: the Settings
  module only shows its switches on a page (see their READMEs). The small tools every module shares
  come from Core too: what waits for the end of a fight (`Core.AfterCombat`), the game's frames changed for a while
  (`Core.Lend`), the switches (`Core.Settings`, `Core.Set`), the game's dialogs, tooltips, pools of frames
  and sounds (`Core/Kit.lua`).
- **Its words** stand in one table, `ns.TEXT` (`Abilities.lua`); where the game has a word of its own
  (`HOME`, `SAVE`, `SPELL_PASSIVE`, `SPELLBOOK_TRAINABLE`, `SPELLBOOK_AVAILABLE_AT`, `SHOW_ALL_SPELL_RANKS`)
  that comes first (`Core.Word`). The switches' own words are in their description (`OPTIONS`), which the
  menu and the checkbox read too (`Core.Described`).
- **The switches** are `ns.options`, the table Core keeps for the module (`Core.Settings`). The
  spellbook's menu, the checkbox next to the page buttons and `/sane ab pages` set one with `Core.Set`:
  the module hears it as from the options page, and an open options page shows it at once.
- **Why reservations:** the game refuses a spell you do not know in an action slot. The module keeps
  `slot → spell/item/macro` in its saved settings, draws a grey icon on the button, and places the real
  thing when you have it (`Engine.lua`).
- **How the grey entries get into Blizzard's spellbook (`Book/Book.lua`).** The game's spell entries are
  never touched by addon code beyond *where they stand*:
  1. The first page's column is made 60000 high. The game then puts a whole tab on "page 1" and creates
     every entry of it.
  2. After each time the game draws a tab, the module moves those entries to their place on the real
     pages, with its own grey entries in between. Entries of other pages wait far off the screen.
  3. The game's page buttons are moved off the screen; the module shows its own.
- **Why so careful ("taint"):** casting from the spellbook only works while nothing an addon wrote is
  read on the way. One addon-written value in the spellbook's page number or data breaks casting until
  `/reload` and can block the action bars in combat. So the module writes no value on any Blizzard frame
  and calls none of its functions that change something; placing a frame leaves no such trace. It is told
  about redraws through the game's event registry, which keeps addon code apart from its own.
- **In a fight** the game forbids an addon to move a frame that holds one of its protected frames. A
  spellbook entry does so after you opened its spell flyout; that entry is left alone until the fight ends.
  Whatever a fight holds up asks Core once, under a key of its own, to be done when it ends
  (`Core.AfterCombat`): an update, the layout, giving the pages back, taking them over, the window's size.
- **"Jump to the new spell"** (the spellbook button after learning a spell) turns the game's pages, of
  which there is only one now; a hook after `GoToSpell` turns the module's page to that entry.
- **Fallback:** with a controller in use, if something keeps moving the entries, or on an error,
  `Book.StandDown` tidies the page once, gives the column and the page buttons back and says so in chat.
  The tab on show stays one long page until the game draws it afresh (come back to it from another tab).
  An error while taking the pages over is told once and gives back whatever was taken already; it is not
  tried again until `/reload`. What a fight keeps from being given back (the column, the page buttons,
  the row of tabs, an entry's own size, the window's size) is given back when it ends. The page buttons
  and the row of tabs are lent (`Core.Lend`): their place is noted once and given back exactly.
- **Keeping the entries in place** (`Book.lua`, `Watch`): the game lays its entries out again now and
  then, sometimes a frame after it said it drew. For ten frames after each layout of the module every
  frame is looked at, then five times a second while the spellbook is open; closed, nothing runs.
- **Grey entries are frames of the module** (`Book/Item.lua`), drawn with the game's art but sharing no code
  with the game's entries. They copy colours from a real entry, so a skin carries over.
- **The pages follow the window** (`Book.lua`, `Measure`): every time a tab is drawn, the page's width and
  height are taken from the spellbook's size (680 x 590 at the game's own two sizes), and from them the
  columns and rows. The right page hangs on the left page's frame, right of the window's middle, because
  the game's own frame for it keeps its distance from the right edge. `Layout.Paginate` takes the
  columns, the entry height and the paddings. Compact entries are scaled (`SetScale` 0.75), the game's
  and ours; a scaled frame counts the way to its anchor in its own measure, so offsets are divided by
  the scale. On a fallback every entry gets the game's size back.
- **Moving and sizing (`Book/Window.lua`).** The window is the game's (`PlayerSpellsFrame`, shared with
  the talents), and the game sizes and places it at every opening, tab change and minimise. The module
  puts its size and place on it again a moment later (hooks after `OnShow`, `UpdateSize` and
  `UpdateUIPanelPositions`), only while the spellbook tab is on show, the pages are the module's, and
  out of a fight. The spellbook frame inside is sized to fill the window, with the game's own margins
  (6 open, 3 small). The drag bar and the grip are
  frames of the module, the dragging and the sizing are Core's (`Core.Window.Mover`, `Sizer`); nothing is
  written into the window. Saved in `SaneUIDB.modules.Abilities.window`.
- **Sections of a tab** (`Book.lua`, `Build`): the tab's own spells with the grey active ones merged in;
  then the unfolded ranks (`Fold`); in General the passive ones (`Sources.UnlearnedPassives`); what the
  game lists further down; then *Skills to learn* (General, `Sources.UnlearnedSkills`) or *Other spells
  to learn* (first class tab). The game's entries of folded ranks are parked off the screen like those
  of other pages. The **+** and the fold headings are buttons of the module above the game's entries.
- **Weapon skills** (`Data/WeaponSkills.lua`): which class can learn which, as the spell that teaches it;
  10 silver each, polearms 1 gold at level 20. Whether one is learned is asked like for any spell.
- **The row of the game's tabs** is moved 46 to the right while the pages are the module's
  (`Home.lua`, `PlaceTabs`): only `ClearAllPoints` and `SetPoint`, and it is put back on a fallback.
  The game fits its search box to the room right of the row only when the row changes size or the
  spellbook opens; after moving the row, and after the window got another size, the module does the
  game's sum (`SpellBookFrameMixin:ResizeSearchBox`) and sets the box's width, nothing else.
- **Order in a tab** (`Book/Layout.lua`, `Order`): the spells you have first, in the game's own order;
  then the grey ones you can learn now; then the rest by the level they come at, then by name and rank
  (`Layout.ByLevel`, also used for the sections below the tab's spells). Pages are filled by the game's
  rule: column by column, in as few rows as needed.
- **Which tab a new spell belongs to** (`Sources.lua`, `FindTab`), first hit wins: a rank you already have ·
  the class trainer's list (grouped by tab, read at a visit) · the game's skill-line table
  (`C_TradeSkillUI.IsRecipeInSkillLine`, not known to work for class spells) · a built-in list of English
  spell names (`Data/SkillLines.lua`, as in Classic) · the talent tree for talent abilities.
  `/sane ab debug` counts how each was found.
- **Where the spell list comes from** (`Data/`): `Data/Classes/` holds what each class trainer teaches,
  `Data/QuestSpells.lua` the spells that are quest rewards, by race. Checked in the game, 2026-10-08:
  Forever's own spellbook lists no future spells. Talents come from the game's talent tree. Prices are the
  trainer's base prices: a discount from reputation is not counted.
- **The class files** are edited by hand. Each returns two tables from a function (`D.Class`):
  1. *Families*, one string per spell with its ranks from first to last, ordered by the level of the
     first rank, then by spell ID: `"5176 5177:6:100 5178:14:900", -- Wrath`. A rank is
     `spell:level:copper`; a bare `spell` is a rank the trainer does not sell (you start with it, or a
     quest gives it). Every rank needs the one before it, so no rank lists its predecessor.
  2. *Conditions*, by spell ID, for the few ranks that differ: `talent = spell` (a talent first),
     `after = spell` (another spell first), `alone = true` (sold without the rank before it, as the
     rogue's poisons), `side = "Alliance"` or `"Horde"`, `raceIDs = { ... }` (the game's race IDs). A condition holds for its rank and every later rank of the family, until a later
     rank sets that field again.

  At login (`Data.Fill`, when class, faction and race are certain) only your class's function runs:
  the other classes' tables are never built. `Data/Trainer.lua` turns your families into one list of
  ranks (`D.spells`, each with its level, price, the rank before it and its conditions), leaves out what
  your faction or race cannot learn, and links each rank to the next. **A rank counts as learned** when
  you have it or any later rank of its family (`D.Learned`), in every class: where a new rank takes the
  old one's place in the spellbook, the game no longer reports the old one. A spell to come is checked
  in the order of the game's own spellbook: a level not reached yet first, then a talent, the rank
  before it or another spell it needs (`Sources.lua`, `State`). `Dire Bear Form` follows `Bear Form` as
  its next rank, as it takes its place. `D.Info` gives a spell's name, rank line and icon once the game
  has fetched them; a name with a numeral that repeats the rank (*Instant Poison II*, *Rank 2*) is the
  family's name (`D.FamilyName`).
- **The Home tab (`Book/Home.lua`)** is a button of the module that looks like one of the spellbook's icon
  tabs and stands in the gap left of the first one. The game's tabs are not touched: adding a tab to them
  or switching them from addon code would taint the spellbook. While Home is on show, `Book.lua` parks
  every entry of the tab underneath off the screen (`Book.SetHome`), so the page is empty paper and Home's
  rows are drawn on it with the same entry frames and the same page rule (`Layout.Paginate`). The game's
  own selected tab still looks selected, so a second button covers it and looks unselected; a click on it,
  on any other tab, a search, or the game jumping to a spell closes Home. Home needs the pages to be the
  module's: with `/sane ab pages off`, a controller, or after a fallback, the tab is not there.
  What does not fit on the pages (about 21 spells each) is counted in a line at the bottom, not shown.
- **Slots, not buttons:** Bar 1 = slots 1–12 (73–120 in a form or stance), Bar 2 = 61–72, Bar 3 = 49–60,
  Bar 4 = 25–36, Bar 5 = 37–48, Bars 6–8 = 145–180. A button's slot is read from its secure attribute `action`
  (`ns.ActionOf`), then from its field. A bar addon's own buttons may keep the slot only in that
  attribute: dragging finds any button under the mouse that carries a slot.
- **Bar ghosts** (`Ghosts.lua`) hang on the button's bar in the button's place, so a reservation shows also
  where the bar hides its empty buttons ("always show buttons" off).
- **Moving a reservation** (`Ghosts.lua`, `Engine.Move`): a hook after the button's own `OnDragStart` picks
  the reservation up where the game would let you pick up a real action (`lockActionBars` off, or
  `IsModifiedClick("PICKUPACTION")`), only on an empty button and with an empty cursor; `OnDragStop` drops
  it. While its button is hidden the grey icon takes the mouse itself (tooltip and drag) and tells the
  drag its slot; over a shown button it takes no mouse, so clicks and drops reach the button.
- **Finding the button under a carried spell** (`Buttons.lua`, `Book/Drag.lua`). The game refuses an
  unlearned spell on its own cursor, so the module carries it, and the game cannot show the bars' empty
  slots for it (a bar shows them only while the game's cursor carries something). So: every action
  button is found by what it is, any frame that carries an action slot (walked with `EnumerateFrames`
  when a drag starts), whatever the bar addon calls it. The frames under the mouse are asked first;
  then every button on a bar you can see, shown ones before hidden ones. A shown button is asked
  `IsMouseOver`; a hidden one is measured by its place, worked out from its first anchor when the game
  gives a hidden frame none (`Buttons.Rect`). The gold frame is put on that place. Stand-in macros on
  the real cursor would make it fully native but cost a macro slot per spell: not done, by choice.
- **One update pipeline** (`Abilities.lua`, `QueueUpdate`): game events only *ask* for an update; 0.2 s later
  it reads the spellbook (out of a fight only: nothing real can be placed in one), places what can be
  placed and redraws.
- **The list of spells to come is built when it is read** (`Sources.All`): by the spellbook's pages, Home or
  a command, and only when something changed since (what you have, a name that arrived, the trainer's
  window, a spell added by hand). So nothing is built, and no spell names are asked of the game, while the
  spellbook stays closed. At the trainer, a row already kept is not read again.
- **A spell the game puts on a button by itself** (`SPELL_PUSHED_TO_ACTIONBAR`: the spell and the slot) is
  moved off that one slot only; the same spell on a button of yours stays. A slot the game hides from
  addons (a secret value) is neither ended nor filled.
- **Saved layouts** (`Presets.lua`) ask in the game's own dialogs: a name to save under (`GENERIC_INPUT_BOX`,
  `Core.AskText`), yes or no to load or delete (`GENERIC_CONFIRMATION`, `Core.Confirm`). The module puts
  no dialog of its own into the game's list. Without the game's dialog the command to type is said.
- **Saved data of another shape** (an older version, a hand edit) is mended or passed over: a reservation
  without a kind is dropped at login, a broken layout is refused, a trainer row without a name is skipped.
- **Saved settings:** `SaneUIDB.modules.Abilities` in `WTF/Account/<account>/SavedVariables/SaneUI.lua`:
  `options` (the switches), `chars` (reservations per character, kept by GUID), `presets`, `extras` and
  `trainer` per class, `pageNames`, `diag`.
- **Names in the game:** frames `SaneUISpellbook`, `SaneUISpellbookPager`, `SaneUISpellbookHome`,
  `SaneUISpellbookShowHidden` (the checkbox), `SaneUISpellbookDragBar`, `SaneUISpellbookSizeGrip`.
- **Tests:** `lua5.1 dev/tests/abilities.lua` runs the module against a small stand-in for the game client,
  with a stand-in spellbook (339 checks). It proves the rules, not the look. A few made-up rows stand in for
  `Data/Classes/`, whose files are only checked for their format.
  The page rule in `Book/Layout.lua` was also run against Blizzard's own paging code: same result in
  42,000 generated cases.
- **Not verified in the game yet:** all of the spellbook part. To check first:
  1. clicking a learned spell in the spellbook still casts it, also after ticking one of the game's own
     lines in the options menu, and in a fight (no "blocked by an AddOn" message);
  2. the pages look like the game's own with *Show unlearned spells* off;
  3. the look next to a skin;
  4. `/sane ab debug`: how many tabs came from "asked from the game" (the skill-line table);
  5. the Home tab: that it is no longer under the book's round icon, that the search box still has
     room next to the moved tabs, that the tab under it looks
     unselected while Home is open, and that the page is empty paper behind Home's rows;
  6. the yellow mark and the clock on the icons: their size and place, also on the action bar;
  7. that a weapon skill you have is not listed under *Skills to learn* (the game may not report
     weapon skills as known spells), and that the **+** on a folded spell can be clicked;
  8. the place of the checkbox next to the page buttons;
  9. moving and resizing: that the window stays where you put it when another window opens next to
     it, that the page art stretches well, that the talents tab still has its own size, that making
     the spellbook small and large still works, and that nothing is blocked after a fight;
  10. compact pages: that the smaller text is readable and the game's own entries shrink with ours.
  11. A bar addon: a grey spell drops on every bar (9 and 10 too) and on empty spots it hides
      ("always show buttons" off); the gold frame sits on the button; the reservation's grey icon
      shows there; a carried real spell still drops on those buttons;
  12. moving a reservation (bars unlocked or Shift held), swapping two, dropping one on a real action
      (that action comes onto the cursor), and dragging one off the bars to remove it;
  13. the order in a tab: known spells, then what you can learn now, then by level;
  14. after the rename to Abilities: settings, reservations and layouts carried over from Spellbook.
- **References:** `references/` is Blizzard's interface source and art for this build
  (`Blizzard_PlayerSpells`, `Blizzard_PagedContent`, `Blizzard_Menu`).

## Files
| File | What it is |
|---|---|
| `SaneUI_Abilities.toc` | The addon `SaneUI_Abilities` |
| `Abilities.lua` | The module: bars and slots, saved settings, events, `/sane abilities` |
| `Sources.lua` | What you have, what is to come, which tab; reads the trainer window |
| `Data/Trainer.lua` | Reads the trainer data: your ranks, what counts as learned, a spell's texts |
| `Data/Classes/`, `Data/QuestSpells.lua` | The trainer data: each spell's ranks with level and price, quest rewards |
| `Data/WeaponSkills.lua` | The weapon skills each class can learn |
| `Data/SkillLines.lua` | Spell name → spellbook tab, the last-resort list |
| `Buttons.lua` | Every action button, by what it is; where a (hidden) one stands |
| `Engine.lua` | Reservations and turning them into real buttons |
| `Ghosts.lua` | Grey icons on the real bars, their clock and tooltip |
| `Presets.lua` | Save and load bar layouts |
| `Book/Layout.lua` | Page layout and the order of entries (no frames) |
| `Book/Item.lua` | One grey spellbook entry: look, the two marks, tooltip, link, menu |
| `Book/Drag.lua` | Carrying a grey spell to a real action bar button |
| `Book/Book.lua` | Placing the game's entries and ours; page buttons; fallback |
| `Book/Home.lua` | The Home tab and its page |
| `Book/Window.lua` | Moving the spellbook, giving it a size, keeping both |
| `Book/Menu.lua` | The module's lines in the spellbook's options menu |
| `dev/tests/abilities.lua`, `dev/tests/wowstub.lua` | The tests and the stand-in game client |

## History
- 2026-10-17 — On Core's shared tools. Saving, loading and deleting a layout ask in the game's own
  dialogs (loading asks *Yes* or *No*). A switch flipped in the spellbook's menu, by the checkbox next to
  the page buttons or by `/sane ab pages` shows on an open options page at once. The checkbox sounds as
  the game's do, on and off. After a fallback in a fight, an entry the fight held gets its own size back
  when the fight is over (it kept the compact size).
- 2026-10-17 — New format for the trainer data: one string per spell with its ranks in order, and a small
  table of conditions per class. A higher rank you have counts every rank before it as learned,
  in every class. The hunter's list no longer holds his pet's abilities, which showed as grey hunter
  spells. A spell to come says *Available at level N* until then (the level comes first, as in the game's
  spellbook), and names a spell it needs first.
- 2026-10-16 — No warning any more about Actionbar Organizer, the module's obsolete former addon.
- 2026-10-16 — Renamed from *Spellbook* to **Abilities** (folder `src/Abilities`, addon `SaneUI_Abilities`,
  `/sane abilities` or `/sane ab`; `/sane spellbook` and `/sane sb` still work). Its saved settings move
  to the new name by themselves.
- 2026-10-15 — After a review. Fixed: made small or large without a size of its own, the spellbook kept the
  height ours gave it in the other size and stood out of the window. Home was drawn anew on every update
  while the spellbook was closed. A rank named with a numeral (the rogue's *Instant Poison II*) is known by
  the trainer's name of it too: its grey ranks fold with it, and a new rank goes to the button reserved for
  it. Reservations, layouts and the kept window size of another shape (a hand edit) are left out before
  anything trips over them. Giving the game's size back while the talents are shown leaves the window alone.
- 2026-10-14 — After a review: the list of spells to come is only built when something shows it, and
  nothing is read in a fight; a cheaper watcher and trainer read; a failed start, a fallback in a fight and
  a window reset in a fight give everything back; Home no longer reappears over the game's page after a
  fallback; a spell the game pushes is only moved off the slot it used; the search box keeps its room
  next to the moved tabs; the small spellbook's margin is the game's; trainer data is read at login, for
  your class only; saved data of another shape is mended.
- 2026-10-14 — 0.3.0, evening: the spellbook can be moved and resized and its pages follow the size;
  compact pages.
- 2026-10-14 — 0.3.0, later the same day: ranks fold into one entry; General lists passive spells and
  weapon skills to learn; quest rewards by level on Home; a checkbox for hidden spells next to the page
  buttons; the game's tabs make room for the Home tab.
- 2026-10-14 — 0.3.0: the Home tab and page; the yellow mark on unlearned quest rewards and the clock on reserved
  ones, also on the action bar, with the spell's tooltip there. The built-in training list and its window
  are gone: the spellbook and Home show what is to come.
- 2026-10-14 — 0.2.0: an addon of its own (`SaneUI_Spellbook`), switched on and off in the addon list.
  Its switches have a page of their own in the options.
- 2026-10-14 — Became the Spellbook module of Sane UI (0.1.0): `/abo` is `/sane spellbook`, settings live
  in `SaneUIDB`, the switches are also on the game's options page.
- 2026-10-13 — Actionbar Organizer 0.3.0: lives in the game's own spellbook (grey entries, drag to a bar,
  options in the spellbook's menu); the planner window is gone; a training list built in; bars 5–8.
- 2026-10-08 — Actionbar Organizer 0.2.0: reads the class trainer's list and the talent tree (the game
  offered no not-learned spells by itself); characters kept by GUID; load-event fix.
- 2026-10-08 — First version (Actionbar Organizer 0.1.0).
