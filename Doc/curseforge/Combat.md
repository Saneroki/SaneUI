# SaneUI Combat: the CurseForge project

What goes into the project's fields on CurseForge (authors.curseforge.com). The file uploads come from
`saneui publish` (`dev/tools/release`); their changelog is this project's own,
[changelogs/Combat.md](changelogs/Combat.md).

**A project of its own since 2026-11-18:** *SaneUI Combat*, id 1814318, slug `saneui-combat` (Saneroki made it
when the nameplates became a part of Combat; the project *SaneUI Nameplates*, id 1809723, 0.3.1 alpha of
2026-11-16, he deletes). Its first upload: 0.3.2 alpha, 2026-11-18 (with SaneUI Core 0.3.3), file 9681843. In
`~/.config/saneui/curseforge.json` its key is `Combat`. A first upload of 0.3.2 had gone to the old project (file
9681798) before the new one was known; it goes with that project.

| Field | Value |
| --- | --- |
| Name | SaneUI Combat |
| Folder in the game | `SaneUI_Combat` (listed under *SaneUI* as *Combat*; was `SaneUI_Nameplates`, which Combat tells players to delete) |
| Summary | Clean unit frames, party and raid frames and nameplates in one look, each yours or the game's. |
| Category | Unit Frames (and Combat) |
| Avatar | `combat-avatar.png` of `saneui makelogos` (400 x 400) |
| Banner | `combat-banner.png`, at the top of the description: after the project is made, uploaded under its Images and put in by its address (Markdown: `![SaneUI Combat](<address>)`) |
| Relations | SaneUI Core: Required Dependency (each upload sends it too) |
| Release type | Alpha, by the module's stage (since 0.3.2, 2026-11-18) |

## Description

The editor set to *Markdown* when the project is made.

```markdown
**SaneUI Combat** gives you clean frames for the fight in one look: your own frame, your target's and your focus's,
one frame for your party and your raid, and the game's nameplates dressed in the same style: one bar with round
corners, everything you need on a single line inside it. Each part is yours or the game's: keep our party and unit
frames and the game's nameplates, say, with one tick.

Made for **WoW: Forever** (English client). It is part of **SaneUI**, a set of interface addons you can
take one by one. It needs **SaneUI Core**, which the CurseForge app installs with it.

Formerly **SaneUI Nameplates**: the nameplates are now one part of SaneUI Combat.

## What it does

- **Unit frames.** You, your target and your focus in a nameplate's look: level, name, health on one line, your
  pet and their targets in rows under them, casts and your breath part of the frame. Out of sight at rest.
- **Party and raid frames.** One frame for both, up to forty, each player's health in their class colour, roles,
  ready checks, dispellable debuffs and aggro at a glance. Place and size it in Edit Mode by its corners and sides.
- **Nameplates.** One line inside the bar (quest progress, level, raid marker, item level, threat, name, health), a
  border that tells you who it is, gold and silver for elites, bosses and rares, a red glow on aggro, power and
  combo points along the bar, auras round it, less clutter, plates smaller far away, combat text over them.
- **Aura tracking.** Mark a buff or debuff Important, Unimportant or Hidden, or track it: its icon on a bar of its
  own, on the health bars or under the nameplates, when it is missing or about to run out.
- **Yours or the game's.** Each part switched on or off on its own, in the options, the setup or a full screen's
  Classic windows.
- **Set up step by step.** The first time, a window walks you through it all with samples that show each choice
  at once: your party and raid at 5, 10, 20 and 40 players, and a button that opens Edit Mode to place them.

## How to use

- **Nothing else to do:** the frames and plates show as soon as Combat is on.
- **The setup again:** Esc > Options > AddOns > SaneUI > Combat, *Set up step by step*, or `/sane setup combat`
  (`/sane setup nameplates` for the nameplates' pages).
- **Options:** the same page, the first section which parts are ours. The plates' size, style and which plates show
  stay the game's own options (Options > Gameplay > Nameplates).
- Switched off, everything is the game's own again.

## Alpha

SaneUI Combat is in alpha: it works, but it is still changing, and you may find bugs. If it ever runs
into an error, SaneUI gives the frames and plates back to the game's own until your next `/reload`, so your game
keeps working. `/sane errors` lists what went wrong.

## Feedback and bug reports

- GitHub: https://github.com/Saneroki/SaneUI/issues
- Discord: https://discord.gg/saneui
```

## Gallery

Real screenshots from the game only, no edited or generated pictures (CurseForge's moderation policies ask
for a visible note on any AI-made showcase image):

1. A pull of several creatures: the plates with their lines, the target's border, auras above.
2. An elite and a rare side by side, the red glow on aggro.
3. A rogue's target with combo points and a cast bar.
4. The setup window with its sample plates.
5. *Plates show: spells only*, the dot and the arrow over the target.
6. Your frame, your target's and your focus's in a fight, with their rows.
7. A raid's frames, roles, aggro and a ready check; the setup's party page at 40.
