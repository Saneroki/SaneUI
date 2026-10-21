# Known Issues

Issues found in QA that could be looked at. One section per module.

## Core

## Social

## Abilities

## Tooltips

- When equipment is viewed in the Auction House, the comparison tooltip flickers. (2026-10-21: comparisons are now
  placed after their main tooltip is drawn, the probable cause.)
- Lines the game adds after a tooltip's data (the auction house's seller, time left and bid; the repair cost in
  repair mode) are taken for other addons' lines: hidden without Alt, under *Addons* with it. Which of them to show
  under *Details* instead is still to be chosen.

## Guild

- *The Game's Guild Window* (the roster's button) opens the game's guild window from our code (`ToggleGuildFrame`), a
  panel the game's window manager handles; that may leave the manager tainted (Doc/guides/addon-standards.md,
  section 5), as showing the character sheet did; the taint log (`/console taintLog 1`) names it if so (the button,
  then C).

## Nameplates

- The game's aura icons on a dressed plate are only made invisible (alpha 0): they may still show their tooltip under
  the mouse where ours shows no aura.
