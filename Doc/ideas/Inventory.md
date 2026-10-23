# Inventory

Planning notes for the **Inventory** module (`src/Inventory/`, addon `SaneUI_Inventory`): what the player
carries and wears. What Saneroki decided (2026-10-20), the shape of the module, and the order it is built in.

## What it is

Saneroki, 2026-10-20: **push the mouse into the screen's bottom right corner and your bags and character sheet
open; push it there again and they close.** The first try opened the game's own bags and character sheet.
The bags worked; the sheet did not: opened by our code, the game's window manager ran tainted and the sheet's
own code failed on the player's secret health (`src/Inventory/README.md`, *History*;
`Doc/guides/addon-standards.md`, *Known traps*). So, decided (Saneroki, 2026-10-20):

- **Our own character sheet,** in Sane UI's window system: a window that holds everything the game's character
  sheet holds and does, built from Blizzard's own code for it (`references/BlizzardInterfaceCode`, Camelot's
  `CharacterFrame`, `PaperDollFrame`, `PaperDollFrameStats`, `ReputationFrame`, `SkillsFrame`,
  `PVPRankFrame`), as close to it as the game lets an addon be.
- **Our own bags,** a window of Sane UI's that shows and handles the player's bags: a bag view of its own,
  with views and tools of its own (below).
- **Snapshots of the other characters:** windows that show what the account's other characters have (their
  bags, bank and what they wear, their gold), from Core's data (`Core.Data.Characters`).
- **All of them on the module's full screen:** the corner fills the screen with them, laid out on Core's board,
  arranged as the player wants.

## The window

One window of Core's (`Core.Window`, kind `screen`), docked in the screen's **bottom right corner** at first,
empty and see-through while small (as Combat's at the bottom middle). Docked in a corner, Core gives it the
corner's square (`Edge.lua`: four of the screen's pixels): the mouse pushed into the corner fills the screen with
it, pushed there again (or Esc) it goes back. That is the corner Saneroki asked for, with nothing of the game's
opened or closed by our code. In Edit Mode it can be docked elsewhere, and its push goes with it.

Full, it holds the module's windows on **Core's board** (`Core.Board`, `Doc/guides/windows.md`, *The board*):

| Window | Key | What it holds |
|---|---|---|
| Character | `character` | The paper doll (*The character sheet*) |
| Character Stats | `stats` | The stats, with the game's sidebar: gear sets, titles, the pet's stats |
| Reputation, Skills, PvP, Currency, Statistics | `reputation` … `statistics` | What the game's sheet has behind its tabs, each a window |
| Bags | `bags` | Our bags (*The bags*) |
| Characters | `alts` | The other characters' snapshots (*The other characters*) |

The first layout: the paper doll, the stats, the bags and the snapshots side by side; the windows of the game's
tabs come from the dropdown *Windows*. Each part is a file (or folder) of its own that registers its window with the module's board; the
board lists only the parts that are there.

The game's own sheet and bags stay as they are: their keys (C, B) and buttons open them as always. Whether those
keys open ours instead is a later step (*Order*).

## The character sheet

Everything the game's (Camelot) character window has, in our panel:

- **The paper doll:** the character's 3D model in the middle, the equipment slots around it (head to
  ranged/relic, shirt, tabard: the game's `INVSLOT_*`), each with its item's icon, quality border, count and
  durability colour, the game's tooltip (`GameTooltip:SetInventoryItem`), and its clicks: pick up, put down,
  swap, link, compare (the game's own item functions, where the game lets addon code call them).
- **The stats** as the game's right pane lists them (`PaperDollFrameStats.lua`): its categories, values and
  tooltips.
- **Its tabs:** Reputation, Skills, Honor (PvP rank), and what else Camelot's `CHARACTER_FRAME_TAB` lists, each
  as the game draws it.
- **Windows of their own (Saneroki, 2026-10-20):** not one sheet with side tabs, but each part a window on the
  module's board, moved and sized there like every other: the paper doll (scaled to fit), the stats with the
  game's sidebar (gear sets, titles, the pet), and each of the game's tabs; what is in a window follows its size.
- **Sane UI's own look (Saneroki, 2026-10-22):** the character, the bags, the bank and the alts in the new art and
  style (`Doc/guides/interface-style.md`), still sized on the board by dragging the lines between windows. Built
  the same day: the character on the doll (its own leather and paper; slots in arcs, strips with each item's
  words, the live model on the doll's ground), the bags, the bank and the alts on the journal's page (Core's
  `Core.Journal`, the board's `dress`). The stats and the game's tabs' windows keep the game's art for now; they
  are next.
- **Built from Blizzard's code,** its behaviour, layout and sizes (and, for the windows not made over yet, its
  art by path), the game's words
  (`GlobalStrings`) and behaviour, rewritten for our panel where it must be:
  - no frame named like one of Blizzard's (`CharacterFrame`, `PaperDollFrame`, `Character…Slot`): ours carry
    `SaneUI` names or none, and nothing of Blizzard's is written;
  - every value read from the game goes through `Core.Plain` (health, power and some stats are secret to
    addon code: a comparison of one is an error), every script behind its guard (`ns.Guard`);
  - what the game allows only its own code (equipping in a fight, some protected calls) is left to the game.

## The bags

Sane UI's own bag view of the player's bags (and the bank, while it is open): one window with every slot,
the items as the game's own item buttons (`ContainerFrameItemButtonTemplate`, which keeps its bag in a secure
attribute, so using an item from our window is the game's own click, in a fight too), with views and tools
designed for Sane UI: a grid of all slots, items sorted and grouped into categories, a list, a compact view,
the search box of the full window, the free slots, the gold. Designed on its own terms (CLAUDE.md, *Our own
shape*): our layout, names, words and numbers; Blizzard's art and colours where it has them.

**Built (2026-10-20):** the window on the full screen with the bags and, while it is open, the bank; the game's
own item buttons; four views (every slot, categories, a list, compact), sorted inside a group by quality, name or
item level; the search; the game's clean-up of the bags and of each bank; new items first while the window is
open; the free slots by kind of bag; the bag bar (a bag's items lit, bags put on and picked up); selling the junk
at a vendor and depositing the reagents at a banker by the game's own calls; the watched currencies; the gold with
every character's (`src/Inventory/README.md`, *The bags*).

**Built (2026-10-20), the next step:** pinned items (a group of their own at the top, set and unset in the item's
menu: Alt and a right click on it); the player's own groups and the game's renamed, moved, hidden or joined into
another (a right click on a group's head); items put into a group by letting them go over its head or from their
menu, taken out again; items marked as junk and sold with it (the game's own sell-all where the junk is just the
game's, else item by item), a grey item unmarked and kept. Kept for the account by item ID, in the module's store.

**Built (2026-10-20), the bags made over (Saneroki asked for a much richer bag view):** a flat, dark look (items
34 wide in a thin border of their quality's colour, quest items in gold, item level, BoE, a quest's mark, red for
what the character cannot use); a bar with the slots taken, the bags in a
strip, the clean-up and the dropdown *View*; a sidebar with *All Items*, *One Bag*, *Each Bag*, Pinned, Recent and
every category with its count; new categories (Weapons / Trinkets, Armor, Item Set Gear, Consumables, Gear
Enhancements, Camp Items, Trade Goods, Professions, Reagent Bag, Miscellaneous, Quest Items, Special Bags, Junk) in
two groups at first (The Armory, Adventure Prep); the player's own categories with an icon, groups of categories,
renamed, moved, hidden from All Items or switched off; pins by a middle click, a second look in Pinned and Recent
(what came in lately); stacks of one item merged; three displays (grid, list, compact); a foot with the currencies
and the gold.

**Built (2026-10-21):** our own sort in One Bag (the items moved into the categories' order in passes, partial
stacks joined first; the other views keep the game's clean-up); categories and groups dragged to another place in
the bags' sidebar, or onto another to group them; the bank as a list under its own column head, a tab's settings
(its name, what it takes, left out of the clean-up) by the game's call, and Buy Tab with the game's own purchase
button over it (`src/Inventory/README.md`, *The bags*).

**Built (2026-10-23), Saneroki asked:** in the grid the categories share lines, as many side by side as fit; each
category that takes items shows its items and one empty slot after them, more only to fill its last line, all
alike: an item let go or clicked on any goes into that category.

**Built (2026-10-23), Saneroki asked:** the items' icons without a border, their corners rounded by the game's own
icon mask; the bar on the window's title line (the count after *Bags*, round buttons with a soft edge for the junk
marker, the bags and the clean-up, then *View*); the sidebar folds to a narrow edge and the strip of the bags goes
with it; an empty bag slot in the strip the pencil slot alone, a bag's icon rounded without a border. The setting
*Quality Borders* is gone with the borders.

**Built (2026-10-23), Saneroki asked:** one empty slot a category, never more; no rule under a category's name;
the icons' corners rounder (Core's own mask). The Armory by the gear's slot (Head ... Ranged, then shirts, tabards
and other gear, and Item Set Gear), Adventure Prep as Potions, Buffs (elixirs, flasks, scrolls, gems, enchantments,
and consumables lasting 15 minutes or more by Core's data), Camp Items and Consumables; a group in All Items as its
title over its members that hold something, each its own block with its slot. The character doll: no turn and
zoom buttons, the model still and a quarter larger on the page's plain paper (the column behind it painted over),
the head and hands slots as large as the others, the icons without the quality border, the strips the item's stats
in their middle (DPS, armor, the primary stats, then the rest).

**Built (2026-10-23), Saneroki asked:** an item let go over the bags' paper goes into the bags, into the category the
rules give it; a group has one empty slot for the whole group; its sidebar row folds its members away (an arrow)
and ticks whether All Items divides it into its members or shows it whole (a box); the bar's buttons small enough
for the title line's pencil lines, *View* and *Sell All Junk Items* pencil boxes on the paper.

**Built (2026-10-23), Saneroki asked:** items and empty slots twice the game's size (68), the bags' strip the same
size and look; a waste bin, a pencil drawing (`assets/interface/bags-trash.png`, made with
`dev/imagegen/sets/bags/trash.txt`, bucket-1), Junk's first slot (Saneroki asked: the bin, the junk, the empty
slot): an item let go there opens the game's own question to destroy it.

**Built (2026-10-23), Saneroki asked:** the doll's model down onto the strap drawn under the hero's column, a
quarter larger again (1.5625 times its place), turned by the left button's drag and zoomed by the wheel (the game's
scene that takes the mouse, over the hero's place only); left alone for ten seconds it glides back to how it stood.

**Built (2026-10-23), Saneroki asked:** the model between his two lines: a full-grown character from under the
level line down to the ground (681), a smaller race on the same ground at the same scale (the scene's own sizes per
race taken out); the feet placed where the scene says it draws them.

**Built (2026-10-23), Saneroki asked:** the wheel moves the camera into the model's head (all the way in, the top of
its head at the top of its place), not toward its hips; the model cut off at the foot of the hero's column, so its
legs never cover the weapons' slots.

**Built (2026-10-23), Saneroki asked:** a group's fold arrow in the sidebar is the sidebar's own pencil arrow (the
"<" that folds the sidebar), turned down or up; its box a square drawn in pencil with a light tick drawn by hand.
Then an arrow of its own (Saneroki asked: centred and as large as the box): a pencil chevron made with an image
model (`dev/imagegen/sets/bags/arrow.txt`, stroke-1, Saneroki's pick; `assets/interface/bags-arrow.png`), made exactly symmetric,
centred and a little thicker by `dev/tools/journal-art` (Core's piece `arrow`), the sidebar's head and the groups'
rows alike.

**Next, each its own step:**
- Spells that work on an item (disenchanting, picking a lock) right from the window: a secure button of the
  game's over the item, out of a fight.
- The bank: depositing account-bound items, moving gold; a tab's icon chosen.
- Gold over time and every character's currencies, from Core's data.

## The other characters

A snapshot of each of the account's other characters: its bags, its bank (as last seen), what it wears, its
gold and level, from Core's data framework (`Core.Data.Characters`, read only; `Doc/guides/data.md`,
*Characters*). The window chooses whose things it shows; the search box finds an item across all of them.
Core keeps item IDs and counts per place, not a bag's slots: the snapshot shows the items of a bag or bank place
as a grid (in the order the place keeps them). What is worn Core keeps slot by slot too (`Data.Worn`), and the
snapshot draws it as the game's paper doll.

Built 2026-10-20 (`src/Inventory/Alts/`, the window *Alts*, first called *Characters*): **one window that switches between
characters**, a roster of them all down its left (the one logged in first, its bank as last seen is worth a look
too; the account's own bank last), the chosen one's places in one scrolling list. Core gives a character's places
item by item (`Data.Items`). An alt's gear on a paper doll, slot by slot (`Data.Worn`), built the same day; a
character Core has not read slot by slot yet (it has not logged in since) shows its gear as a list.

## Order

1. **The window and the board** (built 2026-10-20): docked in the bottom right corner, its corner fills the
   screen with the parts there are.
2. **The character sheet** (built 2026-10-20): the paper doll (slots and model), the stats with the sidebar (gear
   sets, titles, the pet), reputation, skills, PvP, currency and statistics, each a window on the board.
3. **The bags** (built 2026-10-20): the bags and the bank, the game's item buttons, four views, sorting, the
   search; then pins, the player's own groups and junk marks; next, the steps under *The bags*.
4. **The other characters** (built 2026-10-20): the snapshot window from `Core.Data.Characters`, an alt's gear
   on a paper doll.
5. **Sane UI's own look** (built 2026-10-22): the character, the bags, the bank and the alts in the journal's
   look; next the stats and the windows of the game's tabs.
6. **The game's keys:** whether C and B open ours (Core's holder, `Holder.lua`, keeps the game's window out
   of sight while ours is chosen), and *Classic windows* in the full window's dropdown for the game's own.

## Open questions

- What the small window shows while docked (nothing yet: only its corner works).
- ~~Whether the snapshots are one window that switches between characters, or a window per character on the
  board.~~ One window with a roster (2026-10-20).
