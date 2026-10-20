# Sane UI: Inventory

**Status:** first part built: the bottom right corner opens the game's own bags · **Since:** 2026-10-20 · **Addon:** `SaneUI_Inventory` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for what you carry and wear. Its first part is a corner: push the mouse into the screen's
bottom right corner and the game's own bags open; push it there again and they close. The game's bags
stay as they are, and their key works as before. The character sheet opens by its own key (C): the game
lets no addon open or close it without breaking it (below).

## How to use
- **Switch it on or off:** tick or untick *Inventory* under *Sane UI* in the game's addon list.
- **Open:** push the mouse all the way into the bottom right corner of the screen: the bags open, all of
  them, as their key does. In a fight too.
- **Close:** take the mouse away from the corner and push it there again: the bags close, however they
  were opened (their key, a vendor, the corner).
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
- **What a push does** (`Corner.Toggle`): a bag open (`IsAnyBagOpen`): `CloseAllBags()`; none:
  `OpenAllBags()`. Each is called only if this client has it. The game made its bags to be opened by
  addons: a bag's item buttons keep their bag in a secure attribute (`ContainerFrameItemButtonMixin:SetBagID`,
  "Prevent bagID from tainting all interaction with items"), so an item used from them is the game's own
  click, in a fight too.
- **Never the character sheet** (2026-10-20, from the error log): the game's panels are placed by its
  window manager (`UIParentPanelManager.lua`), and a panel that addon code shows or hides
  (`ToggleCharacter`, `ShowUIPanel`, `HideUIPanel`) leaves the manager's slots written by tainted code until
  a `/reload`. The sheet's `OnShow` and `OnHide` set the player frame's bars to show their numbers
  (`ShowStatusBarText`, `TextStatusBar.lua`), which compares the health and mana, secret values to tainted
  code: the sheet failed at once when the corner opened it ("attempt to compare a secret number value
  (execution tainted by 'SaneUI_Inventory')"), the module stood down, and the game's own close button failed
  the same way afterwards. The sheet has no place of its own (the manager places it), so showing it from a
  secure snippet past the manager is no way either. Only the game's key and its micro button open it cleanly.
- **Standing down** (`ns.GiveBack`): the square is hidden; what is open stays open, and the game's keys
  work as always. A `/reload` starts the module afresh.
- Tests: `dev/tests/inventory.lua`, which also sees that the module never calls the window manager.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Inventory.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Inventory.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); `GiveBack`, the start |
| `Corner.lua` | The bottom right corner that opens and closes the game's bags |

## History
- **2026-10-20:** set up as a module of its own; first part: the bottom right corner opens and closes the
  game's own bags. The character sheet it opened with them at first failed in the game (tainted by our
  call, on the player frame's secret health) and is left to its own key.
