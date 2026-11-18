# SaneUI Tooltips: the CurseForge project

What goes into the project's fields on CurseForge (authors.curseforge.com). The file uploads come from
`saneui publish` (`dev/tools/release`); their changelog is this project's own,
[changelogs/Tooltips.md](changelogs/Tooltips.md).

| Field | Value |
| --- | --- |
| Name | SaneUI Tooltips |
| Folder in the game | `SaneUI_Tooltips` (listed under *SaneUI* as *Tooltips*) |
| Summary | The game's tooltips redrawn as tidy panels: quests, professions and gold for every item, at a glance. (put in 2026-11-18, in place of a shorter one) |
| Category | Tooltip |
| Avatar | `tooltips-avatar.png` of `saneui makelogos` (400 x 400) |
| Banner | `tooltips-banner.png`, under the project's Media (not featured) and at the top of the description since 2026-11-18, the description's first line |
| Relations | SaneUI Core: Required Dependency, under Default Relations (set 2026-11-18; each upload sends it too) |
| Release type | Alpha, by the module's stage (since 0.3.1, 2026-11-16) |
| Uploads | 0.3.1 alpha (2026-11-16); 0.3.2 alpha (2026-11-18, with SaneUI Core 0.3.3), file 9682011 |

## Description

The editor set to *Markdown* when the project is made. *SaneUI addons* (2026-11-18): every SaneUI project with its
link, the same list in each description; put in on CurseForge the same day. Changed with 0.3.2 (2026-11-18): *How
to use* has the setup and says tooltips show at once (no longer *Hold Shift*); put in on CurseForge the same day.

```markdown
![SaneUI Tooltips](https://media.forgecdn.net/attachments/2229/799/tooltips-banner-png.png)

**SaneUI Tooltips** redraws the game's tooltips as tidy dark panels with round corners, each in the colour
of what it shows: an item's quality, a player's class, a spell's school. Every kind of tooltip has a layout
of its own, and an item's panel tells you what it is for and what it is worth.

Made for **WoW: Forever** (English client). It is part of **SaneUI**, a set of interface addons you can
take one by one. It needs **SaneUI Core**, which the CurseForge app installs with it.

## What it does

- **A panel for each kind.** Items, spells, players, creatures, buffs and quests each have their own layout,
  in sections with a name (*Info*, *Quest*, *Gold*, ...). Every other tooltip gets its name and its lines.
- **Items at a glance.** Name in its quality's colour, kind and slot, the level it needs (red while yours is
  lower), stats and effects in the game's colours, durability as a bar, and the set it belongs to.
- **Quests that need it.** The quests an item starts or is needed for, and where you stand with each: in your
  log with your count, available now, not yet, or done.
- **Professions.** Which professions use a trade good. Over a herb or an ore, how likely gathering it raises
  your skill, in the game's orange, yellow, green and grey.
- **Gold.** What a vendor pays for it and how it binds (*BoP*, *BoE*, ...). Once **SaneUI Economy** is out,
  its auction scans add what the item brings at the auction house and one line on what to do with it for gold.
- **Spells.** What school a spell is and what it asks of you, its numbers in a small table: damage or healing
  per cast and per second, cost, range, cast time and cooldown.
- **Players and creatures.** Health and power, their target, their buffs and debuffs, a player's item level.
  Creatures, players, mounts and pets stand as a moving 3D model in place of the picture.
- **Hold Alt for more.** The IDs, which of your characters have the item and where, your own character
  wearing a piece of gear beside the panel, and what other addons write into a tooltip, gathered in one
  section at the end instead of mixed into the panel.

## How to use

- **Point at an item, a spell or a player:** that is all it needs.
- **A short setup** opens the first time (again with `/sane setup tooltips`): when tooltips show, where, the 3D
  model, and how solid they are, with your own tooltip showing each choice at once.
- **Tooltips show at once**, as the game's do. *Show tooltips* on the options page, or the setup, keeps them
  hidden until you hold Shift, Ctrl or Alt.
- **Options:** Esc > Options > AddOns > SaneUI > Tooltips: when tooltips show, tooltips at the mouse cursor,
  text size, opacity, class colours, icons and 3D models.
- Switched off, the tooltips are the game's own again.

## Alpha

SaneUI Tooltips is in alpha: it works, but it is still changing, and you may find bugs. If a part of it ever
runs into an error, SaneUI gives that kind of tooltip back to the game until your next `/reload`, so your
game keeps working. `/sane errors` lists what went wrong.

## SaneUI addons

Every SaneUI addon is a download of its own: take the ones you like.

- **[SaneUI Core](https://www.curseforge.com/wow/addons/saneui-core):** the shared base of every SaneUI addon:
  one options page, profiles and safe error handling. The CurseForge app installs it with any of them.
- **[SaneUI Navigation](https://www.curseforge.com/wow/addons/saneui-navigation):** your minimap and world map
  in one window.
- **[SaneUI Tooltips](https://www.curseforge.com/wow/addons/saneui-tooltips):** the game's tooltips as tidy
  panels, with quests, professions and gold for every item.
- **[SaneUI Combat](https://www.curseforge.com/wow/addons/saneui-combat):** unit frames, party and raid frames
  and nameplates in one clean look.
- **[SaneUI Social](https://www.curseforge.com/wow/addons/saneui-social):** chat like a messenger, with message
  bubbles, a conversation per whisper, and friends, guild and groups on one screen.
- More are on the way.

## Feedback and bug reports

- GitHub: https://github.com/Saneroki/SaneUI/issues
- Discord: https://discord.gg/saneui
```

*Tooltips show at once* is how Tooltips starts (since 0.3.2, card #506); when that default changes, that line
of *How to use* changes with it.

## Gallery

Real screenshots from the game only, no edited or generated pictures (CurseForge's moderation policies ask
for a visible note on any AI-made showcase image):

1. A weapon's panel: its stats, *Quest* and *Gold*.
2. A trade good's panel with *Professions*, and a herb's chance to raise the skill.
3. A creature's panel with its 3D model, health and buffs.
4. A spell's panel with its table of numbers.
5. A piece of gear with Alt held: your character wearing it beside the panel.
