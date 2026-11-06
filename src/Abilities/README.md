# Sane UI: Abilities

**Status:** working · **Since:** 2026-10-08 (as the addon *Actionbar Organizer*), a Sane UI module since 2026-10-14 · **Addon:** `SaneUI_Abilities` · **Game:** WoW: Forever and Retail (interface 16001, 120105; in Retail the reservations and layouts, see *In Retail*)

## TL;DR
The module for your spells and abilities (it was called *Spellbook*; it will do more than the spellbook).
Your normal spellbook (P) also lists the spells you have **not learned yet**, in grey, in the tab where
they will end up. Drag a grey spell onto an action bar button: the button is *reserved* and becomes the
real spell the moment you learn it. A **Home** page, the first tab of the spellbook, says what your
trainer can teach you right now and which spells you get from quests. **Combat's spellbook** on its full screen,
which your spellbook key opens there, shows all of it too: the grey spells, the weapon skills, Home, the reservations.
**Action Bar 1 keeps the page you chose:** no stance, form or stealth changes it, and bars 6 to 8 stand beside
its pages, so every page and bar holds buttons of its own. **A druid's Bar 6 swaps with the form:** Bar 9 in Bear
Form, Bar 10 in Cat, Aquatic and Travel Form, with arrows and a checkbox beside it. **The buttons of every bar touch,**
with no space between them.
In Retail the game's spellbook lists the spells still to come itself and stays the game's own; there the
module keeps reserved buttons, saved bar layouts, Bar 1's page and the buttons that touch.

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
  - *Show all spell ranks*: off = one icon per spell; on = one icon for every rank, learned or not.
    (The game's own option; the module adds the line for warriors and rogues, who do not get it.)
  - *Open the spellbook on its Home page*: off = the spellbook opens on the tab you last looked at.
  - *Compact spellbook pages* and *Move and resize the spellbook* (both above).
  - *Show reservations on the action bars*, *Say in chat when a reserved button is filled*.
  - *Move buttons up to a new rank*, *Action Bar 1 keeps the page you chose* and *Action bar buttons touch* (below).
  - *Action bar layouts*: save all your bars under a name, load them again later (per class).

  The switches are also in the game's options:
  Esc > Options > AddOns > Sane UI > Abilities, or `/sane options`.
- **Reserve a button:** drag a grey spell onto any button of action bars 1–8, on whichever page Bar 1 shows. A gold frame shows the
  button you are over. What was on that button is on your cursor afterwards, as when you swap two buttons.
- **Move a reservation:** drag the grey icon on the action bar to another button, the way you move a
  real action: with the bars unlocked, or with the pick-up key (Shift by default) held. On a reserved
  button the two change places; on a real action, that action goes onto your cursor. Let go where there
  is no button and the reservation is taken off, as a real action is. Also where the bar hides its empty buttons.
- **Remove a reservation:** right-click the grey spell in the spellbook → *Remove from Bar 2, button 5*.
  Or drop any real spell on the button. Or `/sane ab clear` for all of them.
- **A new rank moves your buttons up** (switch *Move buttons up to a new rank*, on; WoW: Forever). The game
  leaves the old rank on a button when you learn a new one. Here every button with the rank you had until
  now changes to the new rank, on all your bars and form rows, after the fight if you are in one and once
  your cursor is free. A button with an **older** rank stays: it would have moved up with an earlier rank,
  so you keep it on purpose, such as a cheap heal. Macros are left alone. Should the game also put the new
  rank on a free button, that copy is taken off again.
- **Action Bar 1 keeps its page** (switch *Action Bar 1 keeps the page you chose*, on). The game puts another row
  of buttons on Bar 1 in a stance, a form or stealth. Here the bar stays on its page, in a fight too: only its
  arrows or your page keys change it, and a key casts what its button shows. Where the game puts a bar of its own
  in Bar 1's place (a vehicle, a possessed creature, a temporary shape, skyriding) the buttons are the game's
  for that time, and the keys of Bar 6 press them, as the keys of a main bar do; afterwards your page is back.
  The switch takes effect at once. A spell the game drops on a form's row, which never shows now, comes to the
  first free button.
- **Bars and pages that are all your own.** Bar 1's six pages are slots 1 to 72: page 2 is its own, pages 3 to 6
  are also Bars 4, 5, 3 and 2, and the game leaves such a page out while that bar is on. Bars 6, 7 and 8 are
  slots 145 to 180, on none of its pages, and no form changes them. So with Bars 6 to 8 on and Bars 2 to 5 off
  you have three fixed bars and six pages, 108 buttons, none of them a copy of another. Bars 6 to 8 are the
  game's own: switched on in its options, placed in Edit Mode, bound in its key bindings under *Action Bar 6* to
  *8*, clean as all its bars and with your reservations on them. Page 2 is saved in your layouts too, and a button
  on a bar that is off is named by its page: *Bar 1 (page 3), button 2*.
  The setup this is made for, from the bottom of the screen up: Bar 1 with its pages on Alt + 1 to =, Bar 8 on Ctrl,
  Bar 7 on Shift, and at the top Bar 6, the main bar, on the plain keys.
- **A druid's Action Bar 6 swaps with the form** (Saneroki, 2026-11-06). The same keys show **Bar 9** in Bear Form and
  **Bar 10** in Cat, Aquatic and Travel Form (Prowl included), in a fight too; as a human and in Moonkin Form Bar 6 is
  itself. Bars 9 and 10 are buttons of their own (slots 97–120), on none of Bar 1's pages and of no other bar. Beside
  Bar 6, where Bar 1 has its page number and arrows: the number of the bar it shows (6, 9 or 10), an **arrow up** and
  an **arrow down** that turn it through the three without a change of form (to fill Bar 9 as a human, say; in a fight
  too), and between them a **checkbox**, *Swap with your form*: ticked (at first), the next change of form shows that
  form's bar again; not ticked, the bar stays on the one the arrows show. The checkbox is this druid's alone (another
  character on the same profile keeps its own) and changes out of a fight; also the line *Action Bar 6 swaps with this
  druid's form* in the spellbook's menu, or `/sane ab formbar on` / `off`. Drag to a button of Bar 9 or 10 while it
  shows, reserve and save them in a layout, as on any bar; in chat they are *Bar 9, button 3*. A Sane Macro put on Bar 6
  while it shows Bar 9 or 10 is that bar's and swaps with it too (Combat's Sane Macros). Other classes keep a
  plain Bar 6, and the rows of Bar 1's other forms (Cat Form's 73–84, Prowl's 85–96) stay out of sight.
- **Buttons that touch** (switch *Action bar buttons touch*, on). No space between the buttons of any action bar,
  the stance, pet and possess bars too, side by side or between the rows of a bar: the icons stand directly against
  each other, and the mouse has no gap to fall in. Edit Mode's *Icon Padding* stops at 2, so its slider does nothing
  while this is on. A row closes towards the middle of its bar, so a bar's box in Edit Mode is a little wider than
  its row (padding 2: 22 wider on 12 buttons) and stays where it is. Bars snapped together in Edit Mode touch as well,
  on top of each other or side by side, and bars snapped by a corner have their first buttons in line: drag a bar
  against another and let go. Your layout keeps the game's place, so with the switch off they stand as the game
  snaps them. Bars in the game's own places keep its spacing, and one moved by the arrow keys stays where you put it.
- **In Combat's spellbook** (Saneroki, 2026-11-06; on the full screen of the module *Combat*, which your spellbook key
  opens while Combat's switch *Your spellbook and talents keys open ours* is on): the same grey spells in each tab after
  its own, with the same third line and the two marks; in General the sections *Passive spells to learn* and *Skills to
  learn* (the weapon skills); in the first class tab *Other spells to learn*. Drag a grey spell onto an action bar
  button of the full screen to reserve it, right-click it for its menu, Shift-click to link it, as above. **Home** is the
  first tab there (the hearthstone), its page as above, and the book opens on it while *Open the spellbook on its Home
  page* is on. The full screen's search finds the grey spells too, each in its tab. Beside the page buttons the checkbox
  *Show unlearned spells*; in its settings menu (the arrow at its top right) the module's lines under the book's own:
  the same as in the game's book, without *Compact spellbook pages* and *Move and resize the spellbook*, which are the
  game's book's. These need neither the switch *Sane UI lays out the spellbook pages* nor the game's book opened once.
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
- **In Retail:** the game's own spellbook already shows the spells you learn at later levels, in grey, so the
  spellbook, its options menu and the trainers stay the game's: no grey entries of ours, no Home page, no
  compact pages, no moving or resizing, and the spellbook's switches are not on the options page. What is
  there: reserved buttons with their grey icon and clock on the bars (moved as above), saved bar layouts
  (*Action bar layouts* in the spellbook's menu, or `/sane ab save`, `load`: what you do not have yet is
  reserved), `/sane ab item`, `list`, `clear`, `debug`, and the switches *Show reservations on the action
  bars*, *Say in chat when a reserved button is filled*, *Action Bar 1 keeps the page you chose* and *Action bar
  buttons touch*.

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
- **Bar 1's page (`Bar1.lua`).** A button of Bar 1 reads its own `actionpage` before its bar's
  (`SecureActionButtonMixin:CalculateAction`, `useparent-actionpage`), and the game writes a form's row to the bar
  alone (`MainActionBar`, in `ActionBarController_UpdateAll`, on page 1 only). So each of the twelve holds a page of its
  own and that writing reaches neither what it shows nor what its key casts, which goes through the same lookup
  (`ActionButtonDown`, `SecureActionButton_OnClick`, `SECURE_ACTIONS.action`). A header of ours
  (`SecureHandlerStateTemplate`) has the buttons as frame references, and the game's state driver gives it
  `Bar1.STATES`: `[bar:n]` the page, or `game` under `[vehicleui][overridebar][possessbar][shapeshift][bonusbar:5][petbattle]`.
  On every change its snippet writes the page to the buttons, whose `OnAttributeChanged` runs `UpdateAction`, in a fight too;
  `game` clears it, so they read the bar's again, and for that time gives the keys of `MULTIACTIONBAR5BUTTONn` to
  `ACTIONBUTTONn` as override bindings of the header. `ACTIONBAR_PAGE_CHANGED` wakes the driver: a page turns a frame
  after the arrows. A wrap of the main bar's `OnAttributeChanged` is no way: the game runs a wrap only on a frame
  that is explicitly protected, which the main bar is not. With the switch off or standing down the driver goes and `state-page` is
  cleared, which lets go of the buttons and the keys; out of a fight. Without the twelve buttons the bar stays the game's.
- **A druid's Bar 6 (`FormBar.lua`).** The same way, a header of ours holds Bar 6's twelve buttons (`MultiBar5ButtonN`),
  with two states. The game's state driver gives `form`: `[bonusbar:3] 9; [bonusbar:4] own; [form] 10; own` (Bear Form's
  row, Moonkin Form's none, every other form 10, so Retail's Prowl row too); its snippet sets `state-row` to it while the
  attribute `swap` is on. The snippet of `row` writes that page to each button's `actionpage` (none for `own`). The arrows
  are secure buttons of ours (`SecureHandlerClickTemplate`) with the header as a frame reference: a click's snippet sets
  `state-row` to the next or the one before of `row1`..`rowN` (`own`, `9`, `10`), round past the ends, so they turn the
  bar in a fight too. The checkbox (`UICheckButtonTemplate`, insecure) writes `swap` out of a fight and, ticked, sets
  the form's row at once; in a fight it says it waits. A hook after the header's `OnAttributeChanged` writes the number.
  The pager is a child of the bar (so it rests, fades and is seated with it), `ignoreInLayout` as the game's page number
  is, at the left of its first button, wherever Edit Mode puts the bar; the arrows are the game's page arrows of Bar 1
  (`ui-hud-actionbar-pageuparrow-*`, `-pagedownarrow-*`). `ns.char.formBar` is `false` when unticked. With the module
  standing down, or another class, the driver goes, `state-row` is `own` and the pager hides.
- **Buttons that touch (`Spacing.lua`).** `ActionBar_OnLoad` gives each button a small frame of its own (`button.container`,
  parented to the bar), `UpdateGridLayout` lays out those frames with `max(minButtonPadding, buttonPadding)` between
  them, and Edit Mode's icon size is the frames' scale. `minButtonPadding` is the game's field and stays unwritten:
  the grid stays the game's, and each button only leaves the `CENTER` of its frame, by its place in the line times the
  padding, towards the line's middle. Offsets stand in the button's own scale, as the padding does, so the icon size
  needs no sums. Lines as in the grid: `stride` buttons, rows on a horizontal bar and columns on a vertical one,
  `shownButtonContainers` in order (the stance and possess bars have no spacers). A hook after `UpdateGridLayout` looks
  again; the line of what a bar's places depend on (`Shape`) skips what has not changed. A button moves out of a fight
  (`Core.AfterCombat`). A ghost hangs on the same frame and covers the button (`SetAllPoints`), wherever it stands.
- **Bars that touch (`Spacing.lua`).** `GetSelectionOffset` counts `SELECTION_PADDING` (2) around each box, so
  `SnapToFrame` leaves 4 between two bars. The layout keeps that: a bar moves after the game, in hooks after
  `OnSystemPositionChange` (the layout has taken the snap) and `ApplySystemAnchor` (a login, Revert, another layout).
  `Snapped` takes a bar whose `systemInfo.anchorInfo` names another of the bars and that stands at that anchor now, so
  not one in the mouse's hands or at `isInDefaultPosition`. `Stand` gives it the offset at which the buttons of both
  meet, on each axis where the anchor names a side; `Insets` is what the closed lines leave inside a box. It goes
  through `SetPointBase`, the frame's own `SetPoint`: `SetPointOverride` writes `snappedToFrame` and runs the manager,
  which our taint must not reach. The game's link between the two stays, so dragging the lower bar takes the upper along.
- **How the grey entries get into Blizzard's spellbook (`Book/Book.lua`).** The game's spell entries are
  never touched by addon code beyond *where they stand*:
  1. The first page's column is made 60000 high. The game then puts a whole tab on "page 1" and creates
     every entry of it.
  2. After each time the game draws a tab, the module moves those entries to their place on the real
     pages, with its own grey entries in between. Entries of other pages wait far off the screen.
  3. The game's page buttons are moved off the screen; the module shows its own.
- **The grey entries in Combat's spellbook (`Book/Offer.lua`).** In Forever the module serves Core's spellbook offer
  (`Core.Spellbook.Serve`): Combat's book asks it for a tab's spells still to learn (`S.Unlearned`, in `Layout.ByLevel`'s
  order), for its sections (General: `S.UnlearnedPassives` unless the game hides passives, `S.UnlearnedSkills`; the
  first class tab of the lines it names: `S.Unlearned(nil)`), and for a search's finds by tab (`S.Matching`: a passive
  spell or a skill in General, one without a tab in the first class tab). It lays them out among its own and draws each
  in a frame of this module's (`Item.Create`, `Item.Set` without a style: the game's colours), so the tooltip, the
  marks, the drag (`Drag.Start(entry, button)`; the drag ends when that entry hides, `Drag.Source`) and the menu are
  this module's. Home draws on that book's two views (`Home.Offer`: `Surface(parent, Header)` once, on a pane the book
  shows only while Home is chosen, `Draw(surface, left, right)` at the game's sizes, the same `Groups` and layout as on
  the game's book); the menu's lines are `ns.BookMenu` (`Menu.lua`'s, without compact pages and moving, and without
  waiting for the game's pages); the checkbox is `Switch` (`showHidden` through `Core.Set`). Each part runs behind
  `ns.Guard`; every `REFRESH` tells the book (`Core.Spellbook.Changed`, once a frame); giving back tells it too, and
  `Offer()` is nil while the module is off.
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
- **When the whole module stands down** (an error that no step of its own caught, at one of its doors:
  the update's timer, the watcher, the drag, an event; Core's error guard): `ns.GiveBack` takes the
  ghosts off the bars, drops a drag in hand, puts the class trainer's filter back and leaves the
  spellbook to the game (`Book.StandDown`), each step on its own, so one that fails keeps none of the
  others. From then on the trainer's window is the game's alone. The reservations stay saved; after
  the next `/reload` the module starts afresh.
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
  Bar 4 = 25–36, Bar 5 = 37–48, Bars 6–8 = 145–180, a druid's Bars 9 and 10 = 97–108 and 109–120. A button's slot is read from its secure attribute `action`
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
- **A new rank on your buttons** (Forever's; `NoteNewRanks` in `Sources.lua`, `RaiseRanks` in `Engine.lua`).
  Every read of the spellbook compares the rank to cast with the last read; the first read has nothing to
  compare with, so a login moves nothing. A rank that went up notes the old one in `S.outranked`, and
  `Reconcile`, once neither a fight nor the cursor blocks it, puts the newest rank on each button holding the
  old one. So two ranks learned at once land on the newest, however long the wait. Only that one rank
  moves, which keeps the low ranks you put on a button on purpose. Compared by the number in the rank
  line, a rank given back moves nothing down; without a rank line (a profession's *Journeyman*) any change
  counts. All slots but 121 to 144, which none of your bars shows, so they are left to the game. A pick-up the game
  refuses stays noted for the next update. When a button moved up, the game's own copy of that rank on a free button
  goes too (`UndoPushes`).
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
  with a stand-in spellbook. It proves the rules, not the look. A few made-up rows stand in for
  `Data/Classes/`, whose files are only checked for their format.
  The page rule in `Book/Layout.lua` was also run against Blizzard's own paging code: same result in
  42,000 generated cases.
- **Forever and Retail** (`Doc/guides/addon-standards.md`, *Forever and Retail*). One code for both; what
  differs is told apart by `Core.FOREVER`. The spells still to come are Forever's: its class trainers teach
  them rank by rank, and its spellbook does not list them. Retail's spellbook lists them itself (its
  *future spells*), Retail has no class trainers and no ranks, and its spellbook is of another measure
  (pages 680 x 650 from 65 down, headings 51 high, text tabs, no `UpdateSize` on the window). So in Retail:
  - Forever's trainer data is not read: the class files, `Data/QuestSpells.lua`, `Data/WeaponSkills.lua` and
    `Data/SkillLines.lua` end in `[ExcludeLoadGameType standard]` in the TOC. `Data/Trainer.lua` is read in
    both: its functions (`D.Learned`, `D.FamilyName`, `D.Info`) serve the reservations too. Without
    `SkillLines.lua` a spell finds no built-in tab, and no error (`Sources.lua`, `FindTab`).
  - The spellbook's pages are not taken (`Book.TryArm`), so Home and the window, which follow them, stay away;
    the trainer's window is not listened to (`Abilities.lua`, `OnLogin`); the five spellbook switches are kept
    without words, so they have no control (`OPTIONS`); the spellbook's menu gets only the bars' lines
    (`Menu.lua`); `/sane ab add`, `pages` and `window` are not there and the help leaves them out
    (`TEXT.helpRetail`); `/sane ab debug` tells the reservations only.
  - What you have is read as in Forever, without the question about low ranks
    (`C_SpellBook.IsSpellBookItemLowRank`, Forever's only). The reservations, the bars' ghosts, moving a
    reservation, the saved layouts and the spell the game puts on a button by itself work the same: the bars,
    their slots, the events and the functions they use are the same in both games.
- **References:** Blizzard's interface source and art of the newest export (`dev/tools/blizzard where`):
  `Blizzard_PlayerSpells`, `Blizzard_PagedContent`, `Blizzard_Menu`.

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
| `Engine.lua` | Reservations and turning them into real buttons; buttons that follow a new rank |
| `Ghosts.lua` | Grey icons on the real bars, their clock and tooltip |
| `Presets.lua` | Save and load bar layouts |
| `Bar1.lua` | Action Bar 1 keeps the page you chose; its buttons and the keys of Bar 6 under the game's own bars |
| `FormBar.lua` | A druid's Action Bar 6 swaps with its form (Bars 9 and 10); its number, arrows and checkbox |
| `Spacing.lua` | The buttons of every action bar touch, and bars snapped together |
| `Book/Layout.lua` | Page layout and the order of entries (no frames) |
| `Book/Item.lua` | One grey spellbook entry: look, the two marks, tooltip, link, menu |
| `Book/Drag.lua` | Carrying a grey spell to a real action bar button |
| `Book/Book.lua` | Placing the game's entries and ours; page buttons; fallback |
| `Book/Home.lua` | The Home tab and its page |
| `Book/Window.lua` | Moving the spellbook, giving it a size, keeping both |
| `Book/Menu.lua` | The module's lines in the spellbook's options menu |
| `Book/Offer.lua` | The spells still to learn, Home and the menu's lines for Combat's spellbook, through Core (`Core.Spellbook`) |
| `dev/tests/abilities.lua`, `dev/tests/wowstub.lua` | The tests and the stand-in game client |

## History
- 2026-11-06 — Combat's spellbook on its full screen shows what the game's book shows here: the grey spells, the weapon
  skills, Home, the reservations by drag, the clock and quest marks, the checkbox and the menu's lines; through Core
  (`Book/Offer.lua`, `Core.Spellbook`), so neither module needs the other.
- 2026-11-06 — A druid's Action Bar 6 swaps with the form: Bar 9 in Bear Form, Bar 10 in Cat, Aquatic and Travel Form,
  Bar 6 as a human and in Moonkin Form. Beside it the bar's number, arrows up and down that turn it through 6, 9 and 10
  without a change of form, and a checkbox whether it swaps (ticked at first). Replaces the switch of 2026-11-01 that
  let any character's Bar 7 follow its form, which no character had on.
- 2026-11-02 — Bars snapped together in Edit Mode touch, on top of each other or side by side: the 4 the game's snap
  leaves is closed, and the layout keeps the game's place.
- 2026-10-31 — The buttons of every action bar touch (switch *Action bar buttons touch*, on), the stance, pet and possess
  bars too. A bar that is off is named as its page of Bar 1 (the first try asked the wrong frame).
- 2026-10-31 — Action Bar 1 keeps the page you chose (switch *Action Bar 1 keeps the page you chose*, on): no stance,
  form or stealth changes it. Bars 6 to 8 are your fixed bars, on none of its pages. Page 2 of Bar 1 is kept in
  layouts and named in chat, and a bar that is off is named as its page.
- 2026-10-31 — New ranks: when you learn a new rank, the buttons with the rank you had until now change to
  it (switch *Move buttons up to a new rank*, Forever only). Older ranks on a button and macros stay.
- 2026-10-25 — Retail: the module runs there with the reservations, their ghosts on the bars and the saved
  layouts. The spellbook stays the game's own (it lists the spells still to come itself): no grey entries,
  Home, compact pages or window of ours, no spellbook switches in the options or the spellbook's menu, no
  trainer reading, and Forever's trainer data is not read. Reading your spellbook no longer asks Retail
  about low ranks, which it does not know (the error at login).
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
