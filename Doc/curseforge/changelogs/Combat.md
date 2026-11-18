# SaneUI Combat: changelog

What changed in each version of SaneUI Combat (SaneUI Nameplates until 2026-11-18), newest first: a version's part is its file's changelog on CurseForge.
`saneui makechangelog` drafts a part from the commits; a person writes it for players.

## 0.3.3 (2026-11-18)

DRAFT: rewrite these lines for players (short, the bigger changes), then delete this line.

- Your unit frames in Edit Mode: click a frame for its width and what it shows (level, the level hidden at 60, raid
  marker, item level, name, health, health in percent, your resource's current, maximum and percent), each frame
  its own. While Edit Mode is open, every frame shows a preview: your target and its target, your focus, your pet,
  your breath and fatigue, and as a druid both your powers.
- Your frame, your target's and your focus's are always in sight at first. Each can show only on mouseover, and
  still show in combat and in a group if you like: the setup's last step, or the frame's own box in Edit Mode.
- Each unit frame can show its resource's numbers on the right: its box in Edit Mode.
- The party and raid preview no longer changes by itself: pick 5, 10, 20 or 40 in its box in Edit Mode or in the
  setup.

## 0.3.2 (2026-11-18)

- SaneUI Nameplates is now **SaneUI Combat**: the nameplates, your unit frames, one frame for your party and raid,
  and the auras you track, in one addon. Each part is yours or the game's, one tick each (the options' first section,
  the setup, or Classic windows on a full screen).
- After the update, delete the old folder `SaneUI_Nameplates` if it is still in Interface\AddOns: SaneUI keeps it
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
