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
| Character | `character` | Our character sheet (*The character sheet*) |
| Bags | `bags` | Our bags (*The bags*) |
| Characters | `alts` | The other characters' snapshots (*The other characters*) |

The first layout: the character sheet at the left as wide as the game's, the bags beside it, the snapshots at
the right. Each part is a file (or folder) of its own that registers its window with the module's board; the
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
- **Built from Blizzard's code,** its layout, sizes, art (atlases and textures by path), the game's words
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

## The other characters

A snapshot of each of the account's other characters: its bags, its bank (as last seen), what it wears, its
gold and level, from Core's data framework (`Core.Data.Characters`, read only; `Doc/guides/data.md`,
*Characters*). The window chooses whose things it shows; the search box finds an item across all of them.
What Core keeps today is item IDs and counts per place, not slots: the snapshot shows the items of a place as
a grid (in the order the place keeps them), and the gear as a list. Gear by slot (to draw a paper doll of an
alt) needs Core's Characters to keep what is worn per slot: a change to Core's data framework, decided when
that part is built.

Built 2026-10-20 (`src/Inventory/Alts/`, the window *Characters*): **one window that switches between
characters**, a roster of them all down its left (the one logged in first, its bank as last seen is worth a look
too; the account's own bank last), the chosen one's places in one scrolling list. Core gives a character's places
item by item (`Data.Items`). Gear by slot is still the next step.

## Order

1. **The window and the board** (built 2026-10-20): docked in the bottom right corner, its corner fills the
   screen with the parts there are.
2. **The character sheet:** the paper doll (slots and model), then the stats, then the tabs one by one.
3. **The bags:** the grid of all bags, the game's item buttons; then sorting, categories, the other views,
   the bank.
4. **The other characters** (built 2026-10-20): the snapshot window from `Core.Data.Characters`; next, gear by
   slot for an alt's paper doll.
5. **The game's keys:** whether C and B open ours (Core's holder, `Holder.lua`, keeps the game's window out
   of sight while ours is chosen), and *Classic windows* in the full window's dropdown for the game's own.

## Open questions

- What the small window shows while docked (nothing yet: only its corner works).
- ~~Whether the snapshots are one window that switches between characters, or a window per character on the
  board.~~ One window with a roster (2026-10-20).
