# Sane UI: Inventory

**Status:** its window and full screen built; the windows on it (character sheet, bags, other characters) are being built · **Since:** 2026-10-20 · **Addon:** `SaneUI_Inventory` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for what you carry and wear. Push the mouse into the screen's bottom right corner and the screen
fills with the module's windows: your character sheet, your bags and your other characters' things, Sane UI's
own, arranged as you like. Push it there again, or press Esc, and they go. The game's own character sheet and
bags stay as they are, and their keys open them as before. The plan is in `Doc/ideas/Inventory.md`.

## How to use
- **Switch it on or off:** tick or untick *Inventory* under *Sane UI* in the game's addon list.
- **The full screen:** push the mouse all the way into the bottom right corner. Push it there again, or press
  Esc, to go back. Not in Edit Mode, and not with *Can expand to fullscreen* off (*Sane UI > Inventory >
  Expand window*). In Edit Mode the window can be docked in another corner; the push goes with it.
- **Arranging the windows:** as on every Sane UI full screen (Core's board): drag a window's head to move it,
  the gap between two to share their room anew, its X to take it off; the dropdown *Windows* adds one; layouts
  behind tabs in the title bar.
- **Settings:** *Sane UI > Inventory*: the section *Expand window* (whether it fills the screen, its kind of
  motion, the background's opacity and texture) and *Window corners*.

## Technical details
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked at `BOTTOMRIGHT` at first,
  `Window.WIDTH` x `Window.HEIGHT`, not sizable, see-through and empty while small (no mouse); in Edit Mode its
  box. Docked in a corner, Core gives it the corner's square (`Edge.lua`, `Edge.CORNER` screen pixels, the
  strata `DIALOG`): its push fills the screen. `docked` lays the board out once the full window stands,
  `filled` takes it away as soon as the window starts back; the search box goes to every part.
- **The board** (`Board.lua`): Core's (`Core.Board`), the module's windows in the order `Board.ORDER`
  (`character`, `bags`, `alts`). Each window is a part in files of its own, listed after `Board.lua` in the TOC,
  that registers itself: `Board.Part(key, title, least, part)`, `part.Build(panel)`, `part.Show(on)`,
  `part.Size(width, height)`, `part.Search(text)`; each step runs `ns.Safe`, so a part that fails is noted and
  the others go on. The first layout puts the parts side by side, each as wide as its least width, the last
  taking the rest; later the layout is the player's (kept in the module's store, `board`).
- **Never the game's panels** (2026-10-20, from the error log): our code neither opens nor closes the game's
  character sheet or any other panel of its window manager (`UIParentPanelManager.lua`). Opened by our code,
  the manager ran tainted and the sheet's `OnShow` failed on the player frame's secret health
  (`ShowStatusBarText`, `TextStatusBar.lua`); the manager's slots, written by our call, made the game's own
  close button fail too until a `/reload` (`Doc/guides/addon-standards.md`, *Known traps*). Hence our own
  windows.
- **Standing down** (`ns.GiveBack`): the board's windows go and the window with them. A `/reload` starts the
  module afresh.
- Tests: `dev/tests/inventory.lua`.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Inventory.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Inventory.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Window.lua` | Its window: docked in the bottom right corner, filling the screen from that corner |
| `Board.lua` | The full screen's windows on Core's board; the parts register theirs |

## History
- **2026-10-20:** set up as a module of its own. First the bottom right corner opened the game's own bags and
  character sheet; the sheet failed in the game (tainted by our call, on the player frame's secret health), so
  the corner opened the bags only. Then (Saneroki) our own windows instead: the module's window docked in the
  bottom right corner, its corner filling the screen with the character sheet, the bags and the other
  characters' snapshots on Core's board (`Doc/ideas/Inventory.md`).
