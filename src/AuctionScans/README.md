# Sane UI: Data: Auction Scans

## TL;DR

Every full scan of the auction house, every auction in it, in a file of its own. It has no code and no options: Core
fills it. It is what the database is filtered from later, so nothing in it is thrown away.

## How to use

Nothing to do. The file is `WTF/Account/<account>/SavedVariables/SaneUI_AuctionScans.lua`, one per WoW account, for
WoW: Forever. Sane UI loads it when the auction house opens, so opening the auction house for the first time in a
session takes longer as the file grows. A login and a `/reload` do not read it.

## Technical details

- It is apart from *Data: Auction House* because every account reads that one at each login, and these scans grow by
  about 2 MB each.
- Core's `Data.APART` names it: `Data.Saved("Scans", fn)` hands over the part once this addon has loaded.
- What it holds: [Doc/guides/data.md](../../Doc/guides/data.md), *The full auction scan*.

## History

- 2026-10-30 — First version: the whole scans moved out of *Data: Auction House* (Saneroki).
