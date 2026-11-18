# SaneUI Combat: changelog

What changed in each version of SaneUI Combat (SaneUI Nameplates until 2026-11-18), newest first: a version's part is its file's changelog on CurseForge.
`saneui makechangelog` drafts a part from the commits; a person writes it for players.

## 0.3.2 (2026-11-18)

- SaneUI Nameplates is now **SaneUI Combat**: the nameplates, your unit frames, one frame for your party and raid,
  and the auras you track, in one addon. Each part is yours or the game's, one tick each (the options' first section,
  the setup, or Classic windows on a full screen).
- After the update, delete the old folder `SaneUI_Nameplates` if it is still in Interface\AddOns: Sane UI keeps it
  off and tells you once. The nameplates' settings start at their defaults on the page Combat.
- A setup that walks you through it all, with your party and raid at 5, 10, 20 and 40 players and a button that
  opens Edit Mode to place and size them by their corners and sides. `/sane setup combat`, or `/sane setup nameplates`
  for the nameplates' pages.

## 0.3.1 (2026-11-16)

- First public alpha, as SaneUI Nameplates: one health bar with round corners, with quest progress, level,
  threat, name and health on a single line inside it.
- A border for your target, focus, party, raid, guild and friends; gold and silver for elites, bosses and rares; a
  red glow when a unit is after you.
- The unit's power and your combo points along the bar, your debuffs above it, a foe's buffs and crowd control
  beside it, the cast bar under it.
- Less clutter: friendly players you do not know and critters get no plate, and plates are smaller far away.
- Combat text over the plates and over your character.
- A setup that walks you through the plates page by page, with sample plates that change as you choose
  (`/sane setup nameplates`).
- Needs SaneUI Core, which the CurseForge app installs with it.
