# SaneUI Core: changelog

What changed in each version of SaneUI Core, newest first: a version's part is its file's changelog on CurseForge.
`saneui makechangelog` drafts a part from the commits; a person writes it for players.

## 0.3.2 (2026-11-15)

- Dungeon maps (SaneUI Navigation): floors whose terrain view left bosses standing on nothing (the Deadmines'
  Ironclad Cove, Blackfathom Deeps, Blackrock Depths) show their map in every view; Shadowfang Keep's tower floors
  each show their own rooms.

## 0.3.1 (2026-11-15)

- First public alpha of SaneUI Core, the base every Sane UI addon needs. On its own it changes nothing you can
  see.
- One options page for all Sane UI addons: Esc > Options > AddOns > Sane UI.
- Profiles, off at first: turn them on to share your settings between your characters.
- Light on your game: every question a Sane UI addon asks the game costs half the time it did.
- Safe error handling: if a Sane UI addon runs into an error, that part goes back to the game's own until your
  next `/reload`, with one line in your chat. `/sane errors` lists them.
- Sane UI's Discord: copy its link from the options page. A bug report, an idea or other feedback written there
  says which Discord channel to paste it into.
