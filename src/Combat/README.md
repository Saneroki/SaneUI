# Sane UI: Combat

**Status:** set up, nothing built yet: the module loads and changes nothing · **Since:** 2026-10-16 · **Addon:** `SaneUI_Combat` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for everything about the fight: your own frame, your target's (and its target's), your
focus and your pet, the party and the raid, your buffs and debuffs, the nameplates, and what goes with
them (cast bars, totems, bosses). Each part, once built, gives the game's own frame back when it fails.
The plan is in `Doc/ideas/Combat.md`.

## How to use
- **Switch it on or off:** tick or untick *Combat* under *Sane UI* in the game's addon list.
- **For now it does nothing:** the game's own frames stay as they are. It has no page in the options
  yet; that comes with its first part.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Combat.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Combat.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`) |

## History
- **2026-10-16:** set up as a module of its own, for party, raid, buffs, unit frames, nameplates and pets.
