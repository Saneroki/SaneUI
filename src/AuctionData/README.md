# Sane UI: Data: Auction House

## TL;DR

The file that holds the auction house's history and current prices, apart from Sane UI's settings. It has no code and
no options: Core fills and reads it. Switched off in the game's addon list, Sane UI neither scans the auction house nor
shows its prices.

## How to use

Nothing to do: the game loads it with Sane UI, in the loading screen. The file is
`WTF/Account/<account>/SavedVariables/SaneUI_AuctionData.lua`, and it grows with every scan, so a login and a `/reload`
take longer as it grows.

## Technical details

- The game keeps saved variables in a file per addon, so a file of its own takes an addon of its own. It declares
  `SaneUIData_Market` and holds nothing else.
- Core's `Data.APART` names it: `Data.Saved("Market", fn)` hands over the part once this addon has loaded.
- What the file holds and how the scans fill it: [Doc/guides/data.md](../../Doc/guides/data.md), *The full auction scan*.

## History

- 2026-10-30 — First version, for the full scans' history and the current prices (Saneroki).
