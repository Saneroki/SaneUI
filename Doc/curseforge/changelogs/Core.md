# SaneUI Core: changelog

What changed in each version of SaneUI Core, newest first: a version's part is its file's changelog on CurseForge.
`saneui makechangelog` drafts a part from the commits; a person writes it for players.

## 0.3.3 (2026-11-17)

- The auction house's full scan line has a pause and resume button and an X: pause the scans (they stay paused on
  your account, after a logout too, until you resume) or cancel the one running, nothing of it kept.
- The setups' key boxes take your key again: click a box, then press the key, with Shift, Ctrl or Alt held if you
  like (Alt-Shift-V), or a mouse button past the two main ones.
- The setups of several Sane UI addons come together in one window a few seconds after the login: a first page lists
  them, then they follow one after another. Each is remembered once you reach its end; one closed early comes back at
  your next login where you left it, and every step says where to start it again. *Choose defaults*, on the first
  page and in each setup, keeps an addon as Sane UI sets it up instead. After a big change an addon can ask you
  through its setup again; your settings stay. The first page also shows the button with the circling arrows (the
  game's classic window instead of Sane UI's, and back) and the full screen's *Classic windows* dropdown, which picks
  which one opens by default.

## 0.3.2 (2026-11-15)

- Full screens open with a left click on their screen edge or corner, not when the mouse merely reaches it. Each
  addon's *Expand window* settings can turn the click off.
- Sound profiles start on *Disabled*: Sane UI leaves your game's sound settings alone until you choose a profile
  (SaneUI Navigation's minimap satchel).
- Comes with Onboarding, under Sane UI in the addon list: the step-by-step setup of Sane UI's addons, with a sample
  that shows each choice at once. It is read only when a setup opens; `/sane setup` lists them.
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
