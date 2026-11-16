# SaneUI Nameplates: the CurseForge project

What goes into the project's fields on CurseForge (authors.curseforge.com). The
file uploads come from `saneui publish` (`dev/tools/release`); their changelog is this project's own,
[changelogs/Nameplates.md](changelogs/Nameplates.md).

| Field | Value |
| --- | --- |
| Name | SaneUI Nameplates |
| Folder in the game | `SaneUI_Nameplates` (listed under *Sane UI* as *Nameplates*) |
| Summary | Clean nameplates: one round health bar with name, level and health inside, auras around it, less clutter. |
| Category | Unit Frames (and Combat) |
| Avatar | `nameplates-avatar.png` of `saneui makelogos` (400 x 400) |
| Banner | `nameplates-banner.png`, at the top of the description: after the project is made, uploaded under its Images and put in by its address (Markdown: `![SaneUI Nameplates](<address>)`) |
| Relations | SaneUI Core: Required Dependency (each upload sends it too) |
| Release type | Alpha, by the module's stage (since 0.3.1, 2026-11-16) |

## Description

The editor set to *Markdown* when the project is made.

```markdown
**SaneUI Nameplates** dresses the game's nameplates in a clean style: one health bar with round corners,
everything you need on a single line inside it, the unit's power along its bottom, your debuffs above it and
crowd control beside it. The game's own nameplate options (size, stacking, which plates show) keep working.

Made for **WoW: Forever** (English client). It is part of **Sane UI**, a set of interface addons you can
take one by one. It needs **SaneUI Core**, which the CurseForge app installs with it.

## What it does

- **One line inside the bar.** Your quest progress on the unit, its level, its raid marker, a player's item
  level, your threat, its name and its health ("1.32m | 100%"), each only while it shows. The bar is as wide
  as that line, no wider.
- **A border that tells you something.** Grey on your target, red while it is out of reach of your attacks,
  orange on your focus, and blue, green, purple or pink for your party, guild, raid and friends.
- **Rank and danger.** A gold line behind the bar for an elite, a thick one for a boss, silver for a rare. A
  red glow when a unit is after you, or a player may attack you.
- **Power and combo points.** The unit's mana, rage or energy as a thin line along the bottom of the bar. As a
  rogue or a druid in cat form, your combo points in a row under the bar of your target.
- **Auras where you look.** Your own debuffs right above the bar, up to three of a foe's buffs at its left,
  crowd control at its right.
- **Cast bar** under the bar: the spell's icon with the seconds left, the spell and its target.
- **Less clutter.** Friendly players you do not know and critters get no plate (a setting shows them), and
  every plate is smaller the farther away it is. Your target's plate stays full size.
- **Combat text.** What a unit takes rises over its plate, what you take over your character: damage, critical
  hits, heals, misses and parries.
- **Simpler looks if you like.** *Plates show* can leave out the auras, or show the spells only: a faint dot
  where each plate is and an arrow over your target.
- **Set up step by step.** The first time, a window walks you through the plates page by page, with sample
  plates that show each choice at once.

## How to use

- **Nothing else to do:** the plates show wherever the game shows its nameplates.
- **The setup again:** Esc > Options > AddOns > Sane UI > Nameplates, *Set up step by step*, or
  `/sane setup nameplates`.
- **Options:** the same page: what the bar says, the auras, the sizes and the combat text. The plates' size,
  style and which plates show are the game's own options (Options > Gameplay > Nameplates).
- Switched off, the plates are the game's own again.

## Alpha

SaneUI Nameplates is in alpha: it works, but it is still changing, and you may find bugs. If it ever runs into
an error, Sane UI gives the plates back to the game's own until your next `/reload`, so your game keeps
working. `/sane errors` lists what went wrong.

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
