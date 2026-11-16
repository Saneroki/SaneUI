# SaneUI Core: the CurseForge project

What goes into the project's fields on CurseForge (authors.curseforge.com). The file uploads come from
`saneui publish` (`dev/tools/release`); their changelog is this project's own,
[changelogs/Core.md](changelogs/Core.md).

| Field | Value |
| --- | --- |
| Name | SaneUI Core |
| Folder in the game | `SaneUI` (*Sane UI*) alone: the auction data's addons (*Data: Auction House*, *Data: Auction Scans*) come with Sane UI Economy, the module that uses them (Saneroki, 2026-11-15), so Core never scans the auction house for a player without it |
| Summary | The shared base of every Sane UI addon: one options page, profiles and safe error handling. |
| Category | Libraries |
| Avatar | `core-avatar.png` of `saneui makelogos` (400 x 400) |
| Banner | `core-banner.png`, at the top of the description: after the project is made, uploaded under its Images and put in by its address (Markdown: `![SaneUI Core](<address>)`) |
| Slug | goes into `~/.config/saneui/curseforge.json` (`projects.Core.slug`): each module names it its dependency |
| Release type | the highest any module uploaded with it needs (the pipeline sees to it) |

## Description

The editor set to *Markdown* when the project is made.

```markdown
**SaneUI Core** is what every Sane UI addon shares. Sane UI is a set of interface addons for
**WoW: Forever** (English client), each a download of its own, so you take only the parts you like.
The CurseForge app installs Core with any of them; you do not need to get it yourself.

On its own, Core changes nothing you can see on your screen. It gives the Sane UI addons:

- **One options page.** Esc > Options > AddOns > Sane UI: *General*, *Appearance* and *Profiles*, and a
  page for each Sane UI addon you have.
- **Profiles,** off at first: turn them on to share your settings between your characters. Your first
  account-wide profile is made from the settings you have.
- **Safe error handling.** If a Sane UI addon ever runs into an error, Core catches it: no error pop-up,
  one line in your chat, and that part goes back to the game's own interface until your next `/reload`, so
  nothing stays broken. `/sane errors` lists what happened.
- **Setup step by step.** The first time a Sane UI addon with a setup is on, a window walks you through it
  a step at a time, with a sample that shows each choice as you make it. Close it at any step: what you chose
  is kept. Open it again from the addon's options page, or with `/sane setup`.
- **Names and notes for players.** Right click a player's name: *Set Alias* and *Set Note*, kept on your
  computer only.
- **Game data** the addons share: places, NPCs, items, quests and more, in one place.
- **The `/sane` command:** which Sane UI addons are on, and their commands.

## Sane UI addons

- **SaneUI Navigation:** your minimap and world map in one window.
- More are on the way.

## Feedback and bug reports

- GitHub: https://github.com/Saneroki/SaneUI/issues
- Discord: https://discord.gg/saneui
```

## Onboarding, in this project

Onboarding (`SaneUI_Onboarding`, *Onboarding* under *Sane UI* in the addon list) has no project of its own: it
always ships with Core, in Core's download (Saneroki, 2026-11-16). Its part of the description is the bullet
*Setup step by step* above. Its words where a single line is asked for (a gallery picture's caption, a post):

> Sane UI's setup, step by step: a window that walks you through a Sane UI addon and shows each choice on a
> sample as you make it.

Its logo (`onboarding-icon.png`, the steps and the flag in a silver ring) is its icon in the addon list;
`onboarding-banner.png` can head that part of the description, uploaded under Core's Images like Core's banner.
