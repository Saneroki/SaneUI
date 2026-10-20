# Sane UI: Inventory

**Status:** its window and full screen built; the character sheet's paper doll, stats, side tabs and reputation built; its other tabs, the bags and the other characters are being built · **Since:** 2026-10-20 · **Addon:** `SaneUI_Inventory` · **Game:** WoW: Forever (interface 16001)

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
- **The character sheet:** the game's sheet, Sane UI's own: your model in the middle (drag to turn it, the
  wheel or the buttons over it to zoom), your gear round it in the game's places, your level and class above.
  A click on a slot picks the item up or puts the one you hold there (a drag the same), Shift or Ctrl and a
  click links it or tries it on, the tooltip is the game's; an item let go over the model is put on. Using an
  equipped item with a right click stays on the game's own sheet and the action bars. At the right, your stats
  as the game lists them, with its tooltips; in a fight they show what they were before it, and are brought up
  to date when it is over.
- **The sheet's tabs:** right of the sheet, as on the game's: Character (the paper doll), Reputation, and the
  others to come. Reputation lists your factions as the game does: a click on a header folds or unfolds it, a
  click on a faction chooses it (its standing in numbers under the mouse). At the right the chosen faction: its
  standing, its description, and the game's switches At War, Move to Inactive and Show as Experience Bar.
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
- **The character sheet** (`Sheet/`, the part `character`): the game's Camelot character window rebuilt from
  Blizzard's code (`CharacterFrame.xml`, `PaperDollFrame.xml`, `PaperDollFrame.lua`), at its size (`Sheet.LEFT`
  398 + `Sheet.RIGHT` 233 by `Sheet.HEIGHT` 464 under the panel's head; the board's least is that and the panel's
  edges), at the top of its panel's body. The left pane on the game's `UI-Character-Info-General-BG`, its top strip
  (the game's rock and edge) with the level line (`PaperDollFrame_SetLevel`: the effective level, the
  specialization where the game has one, the class in its colour); the right pane on the game's stat background and
  stone (`UI-Character-Info-Stat-BG`, `…-StoneBG3`, the divider) with the stats under it. The panel's head is
  `UnitPVPName`.
  - **Slots** (`Sheet/Slots.lua`): the game's `ItemButton` on its slot frame (`UI-Character-Info-GearSlot`), in
    its places (`Slots.TOP`, `LEFT`, `RIGHT`, `BOTTOM`, `SIZE`, `GAP`); the ranged slot only where
    `C_PaperDollInfo.IsRangedSlotShown`, the ammo slot (`…GearSlotSmall`) and the weapons moved left while
    `UnitUsesAmmo`. Drawn as `PaperDollItemSlotButton_Update` draws (the game's `SetItemButton…` functions:
    icon, count, quality, red while broken or unusable, grey while locked; empty, `GetInventorySlotInfo`'s picture).
    Clicks: `PickupInventoryItem` (left click, drag, drop), `HandleModifiedItemClick` (a modified click); a right
    click calls nothing (`UseInventoryItem` is the game's own). Tooltip: `GameTooltip:SetInventoryItem`.
  - **Model** (`Sheet/Model.lua`): a `ModelScene` of the game's `PanningModelSceneMixinTemplate` set up by
    `ModelSceneUtil.SetUpCharacterSheetScene` when shown and at `UNIT_MODEL_CHANGED`, the game's turn and zoom
    buttons (`ModelSceneControlFrameTemplate`), the race's background in four parts (`DressUpTexturePath`, greyed)
    under `UI-Character-Info-RaceBG-Overlay`; an item let go over it: `AutoEquipCursorItem`.
  - **Stats** (`Sheet/Stats.lua`): the game's `CharacterStatsPaneScrollBoxTemplate` under the stone, its rows the
    game's element templates (a category's head, a stat, a stat with an icon) filled by the game's `Init`, which
    calls the game's function for that stat (`PAPERDOLL_STATINFO`). The list is put together by our code as
    `CharacterStatsPaneScrollBoxMixin:UpdateStats` does (the player's categories of `PAPERDOLL_STATCATEGORIES`,
    `primary`, `roles`, `showFunc`, a stat left out at its `hideAt`, a scratch row of ours for the values; then the
    resistances, `Stats.RESISTANCES`, with `UnitResistance` and the game's tooltip and bonus formatting): the game's
    list builder borrows the game's own sheet's frame pool, which our code must not touch. Under a restriction
    (`Core.Restricted`) the stats are secret to addon code (`SecretWhenUnitStatsRestricted`; the player's health
    always is), so the list is not drawn then: it waits (`Stats.Owed`) and is drawn after `PLAYER_REGEN_ENABLED` or
    `ADDON_RESTRICTION_STATE_CHANGED`. Drawn when shown and a frame after the game's stat events (`Core.Later`).
  - **Side tabs** (`Sheet.lua`): the game's `LargeSideTabButtonTemplate` right of the sheet (`Sheet.TABS_Y`,
    `TAB_GAP`), the Character tab with the character's portrait, the others with the game's icons; the template's
    left button handler chooses (`Sheet.Choose`), guarded. A tab is a table a file registers (`Sheet.Tab`: `key`,
    `tip`, `title`, `icon` or `portrait`, `Build(left, right)`, `Show(on)`): its frames over the two panes are made
    when it is first chosen; it is told when it shows and hides (another tab chosen, the panel shown or hidden), so
    it listens to the game only while shown. The panel's head says the tab's title. The board's least is the sheet
    and the side tabs' width (the game's tab art, `SidePanelTabButtonMixin.CalculateTabSizeBasedOnTabArt`).
  - **Lists and side pane** (`Sheet/List.lua`, `Sheet/Side.lua`): what the tabs share. A list in the game's look
    (`WowScrollBoxList`, `MinimalScrollBar`, the long lines) whose rows (plain buttons) the tab draws, every call of
    the game's list into our code `ns.Safe`; the side pane over the right pane as the game's
    `CharacterFrameSidePaneTemplate` lays it out (title, subtitle, line, description, rows, foot, the empty word).
    The game's template itself registers into the game's sheet when made, so it is not used.
  - **Reputation** (`Sheet/Reputation.lua`): the factions of `C_Reputation` in the game's three looks (a header with
    `common-button-list-collapseExpand` and its fold sign; a header with a standing, its `campaign_headericon` fold
    button; a faction), the game's heights (`Reputation.HEADER`, `SUBHEADER`, `ENTRY`), its coloured bar
    (`ColoredProgressBarTemplate`: the standing's word and colour, `FACTION_BAR_COLORS`, friendships green, renown
    blue; the progress under the mouse), its light (`Reputation.LIT`, `WAR`: brighter chosen or under the mouse,
    red at war). The choice is the game's (`C_Reputation.SetSelectedFaction`), the first faction chosen when none
    is. The side: name, standing, description, bar, the account-wide line, and the switches
    (`ToggleFactionAtWar`, `SetFactionActive`, `SetWatchedFactionByIndex`, the game's tooltips and sounds). The
    game's own rows are wired to its sheet (its frame, the event registry's selection, its side pane), so ours are
    our own. Drawn anew a frame after `UPDATE_FACTION` and the game's other reputation events, while shown.
  - **Events, while shown only** (`Sheet.Show`): `PLAYER_EQUIPMENT_CHANGED`, `ITEM_LOCK_CHANGED`,
    `UPDATE_INVENTORY_DURABILITY`, `UPDATE_INVENTORY_ALERTS`, `UNIT_INVENTORY_CHANGED` and `UNIT_MODEL_CHANGED`
    (the player's), `PLAYER_LEVEL_UP`, `UNIT_NAME_UPDATE`, `PLAYER_ENTERING_WORLD`. Every value read goes through
    `Core.Plain` or `Core.Ask`; every function of the game's is called only if this client has it.
- **Never the game's panels** (2026-10-20, from the error log): our code neither opens nor closes the game's
  character sheet or any other panel of its window manager (`UIParentPanelManager.lua`). Opened by our code,
  the manager ran tainted and the sheet's `OnShow` failed on the player frame's secret health
  (`ShowStatusBarText`, `TextStatusBar.lua`); the manager's slots, written by our call, made the game's own
  close button fail too until a `/reload` (`Doc/guides/addon-standards.md`, *Known traps*). Hence our own
  windows.
- **Standing down** (`ns.GiveBack`): the board's windows go and the window with them. A `/reload` starts the
  module afresh.
- Tests: `dev/tests/inventory.lua` (the window, the board, the paper doll, the stats), `dev/tests/sheet.lua` (the
  side tabs and the tabs).

## Files

| File | What it holds |
|---|---|
| `SaneUI_Inventory.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Inventory.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Window.lua` | Its window: docked in the bottom right corner, filling the screen from that corner |
| `Board.lua` | The full screen's windows on Core's board; the parts register theirs |
| `Sheet/Slots.lua` | The character sheet's equipment slots |
| `Sheet/Model.lua` | The character sheet's model, its background and buttons |
| `Sheet/Stats.lua` | The character sheet's stats: the game's list and rows, put together by our code |
| `Sheet/Sheet.lua` | The character sheet: its panes, the side tabs and the tab chosen, the Character tab (paper doll, level line, stats); registers the part `character` |
| `Sheet/List.lua` | A tab's scrolling list in the game's look |
| `Sheet/Side.lua` | The side pane at the sheet's right, as the game lays it out |
| `Sheet/Reputation.lua` | The reputation tab |

## History
- **2026-10-20:** set up as a module of its own. First the bottom right corner opened the game's own bags and
  character sheet; the sheet failed in the game (tainted by our call, on the player frame's secret health), so
  the corner opened the bags only. Then (Saneroki) our own windows instead: the module's window docked in the
  bottom right corner, its corner filling the screen with the character sheet, the bags and the other
  characters' snapshots on Core's board (`Doc/ideas/Inventory.md`). The character sheet's paper doll: its slots,
  the model, the level line; its stats; its side tabs and the reputation tab.
