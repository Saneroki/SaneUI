# Sane UI: Inventory

**Status:** first part built: the bottom right corner opens the game's own bags and character sheet · **Since:** 2026-10-20 · **Addon:** `SaneUI_Inventory` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for what you carry and wear. Its first part is a corner: push the mouse into the screen's
bottom right corner and the game's own bags and character sheet open together; push it there again and
they close. The game's bags and sheet stay as they are, and their keys work as before.

## How to use
- **Switch it on or off:** tick or untick *Inventory* under *Sane UI* in the game's addon list.
- **Open:** push the mouse all the way into the bottom right corner of the screen. Whatever of the two is
  not open yet opens: the bags (all of them, as their key does) and the character sheet (at its first tab,
  the character, as its key does).
- **Close:** take the mouse away from the corner and push it there again: once both are open, a push
  closes both.
- **In a fight** the game opens and closes its character sheet only by its own key, so there the corner
  opens and closes the bags alone and leaves the sheet as it is.
- **Nothing happens** while a mouse button is held (a drag), in Edit Mode, while one of Sane UI's windows
  fills the screen, or when the mouse was in the corner already as the interface came back (after Alt-Z).
- **A window of Sane UI's docked in that corner** keeps the corner for itself: the push fills the screen
  with that window instead.
- It has no page in the options yet.

## Technical details
- **The corner** (`Corner.lua`) is a square of `Core.Edge.CORNER` of the screen's pixels at UIParent's
  bottom right, in the strata `DIALOG` at level 1, that takes only the mouse's coming
  (`SetMouseMotionEnabled`): clicks and the wheel go on to what is under it. Its `OnEnter` is the push.
- **One push, one change,** as at a docked window's corner (Core's `Edge.lua`): after a push the corner
  counts again only once the mouse has gone `Core.Edge.AWAY` of the screen's pixels from it, seen by a
  look every `Core.Edge.LOOK` seconds that stops once the mouse is gone. For `Core.Edge.QUIET` seconds
  after the square was shown (login, the interface back after Alt-Z) a push counts for nothing.
- **What a push does** (`Corner.Toggle`): open are the bags (`IsAnyBagOpen`) and the sheet
  (`CharacterFrame:IsShown()`; in a fight it does not count). All open: `CloseAllBags()` and
  `HideUIPanel(CharacterFrame)`. Else `OpenAllBags()` and, if the sheet is closed,
  `ToggleCharacter("PaperDollFrame")`, the game's own key's call. In a fight the sheet is not touched: the
  game's panel manager refuses addons there and says so. Each function of the game's is called only if
  this client has it.
- **Standing down** (`ns.GiveBack`): the square is hidden; what is open stays open, and the game's keys
  work as always. A `/reload` starts the module afresh.
- Tests: `dev/tests/inventory.lua`.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Inventory.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Inventory.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); `GiveBack`, the start |
| `Corner.lua` | The bottom right corner that opens and closes the game's bags and character sheet |

## History
- **2026-10-20:** set up as a module of its own; first part: the bottom right corner opens and closes the
  game's own bags and character sheet.
