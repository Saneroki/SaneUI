# SaneUI Core: changelog

What changed in each version of SaneUI Core, newest first: a version's part is its file's changelog on CurseForge.
`saneui makechangelog` drafts a part from the commits; a person writes it for players.

## 0.3.6 (2026-11-18)

- The map and the tooltips know 193 more quests of Forever, more of the quests' givers and takers and the quests
  they need first, 186 more creatures, and the places of many creatures brought up to date.
- What Forever's servers say about its quests and creatures, up to the newest build: the experience, money and
  rewards of some 2,000 quests more, the right counts of their objectives, the quests filed under dungeons and raids
  as the game files them, and the drop chances of about 800 creatures and nodes counted again from three weeks of
  play.
- Scanned the auction house with another addon? The prices of the two auction addons SaneUI knows count too: the
  tooltips' gold section, its advice and the price graph use them wherever SaneUI's own scans saw an item earlier or
  never, also with *Data: Auction House* switched off.
- Their daily prices feed the forecast too: from them the gold section tells which day of the week an item sells or buys
  best (*Sell Wed for 14s*) and where its price is heading, before SaneUI's own scans have seen enough.
- *Reset all settings* at the top of the options page *SaneUI*: every SaneUI setting back to its default and its
  windows back at their first places, then the setup from its first page. It asks first; the game's own settings,
  your map pins and conversations stay.
- The options page *SaneUI* links SaneUI's code on GitHub; the empty *Website* row is gone.
- No more error in SaneUI's log when the mouse is over a creature on Zephras Isle or another of Forever's newest
  maps; those creatures are counted again.

## 0.3.5 (2026-11-18)

- The setups' first page has a *Place and size in Edit Mode* button, so you can place and size your frames, SaneUI's
  and the game's, before you start.
- Every entry in a full screen's *Classic windows* is a tick: ticked, the game's own window is the one its key opens;
  unticked, SaneUI's.
- A *SaneUI* layout in the game's Edit Mode: the action bars in four rows at the bottom middle, the minimap, chat, micro
  menu and buffs as SaneUI arranges them. A new character starts with it; a layout of your own stays yours, and SaneUI
  is in Edit Mode's list to pick.
- Edit Mode's window no longer offers ticks for the game's frames a SaneUI addon stands in for: the unit frames, party
  and raid frames, cast bar and timers, the loot window, the vehicle exit and the bars SaneUI hides.

## 0.3.4 (2026-11-18)

- Edit Mode shows its blue boxes only under the mouse, on SaneUI's frames and the game's alike, so you see your
  interface as it looks; the frame you picked keeps its yellow box.
- Edit Mode draws red guide lines for SaneUI's windows too, as it does for the game's frames, where a window lines
  up with the screen's middle, its edges or another frame, and the window snaps onto them when you let go. A small
  SaneUI panel under Edit Mode's window has two ticks: *Snap to hot corners* (on) and *Snap to grid* (off).
- Every full screen's hot corner can be switched off (*Hotcorner*, in the section *Expand window* of each addon's
  options): the corner does nothing, and the window's key still opens the full screen. Click a full screen window's
  box in Edit Mode for the same switches and a box to set its key.
- A setup's *Place and size in Edit Mode* button works again, and a setup closes the game's options window and its
  menu when it opens.

## 0.3.3 (2026-11-18)

- The auction house's full scan line has a pause and resume button and an X: pause the scans (they stay paused on
  your account, after a logout too, until you resume) or cancel the one running, nothing of it kept.
- The setups' key boxes take your key again: click a box, then press the key, with Shift, Ctrl or Alt held if you
  like (Alt-Shift-V), or a mouse button past the two main ones.
- The setups of several SaneUI addons come together in one window a few seconds after the login: a first page lists
  them, then they follow one after another. Each is remembered once you reach its end; one closed early comes back at
  your next login where you left it, and every step says where to start it again. *Choose defaults*, on the first
  page and in each setup, keeps an addon as SaneUI sets it up instead. After a big change an addon can ask you
  through its setup again; your settings stay. Where your addons have them, the first page also shows the button
  with the circling arrows (the game's classic window instead of SaneUI's, and back), the red buttons beside a full
  screen window's X (a window of its own, and back onto the full screen), and the *Classic windows* dropdown, which
  picks which one opens by default and works right there. `/sane setup` starts the whole onboarding again, every
  addon's setup from its first step.
- A setup steps aside while Edit Mode is open and comes back at the same page when you leave it, and a setup can open
  Edit Mode for you (SaneUI Combat's party and raid frames, placed and sized there by their corners and sides).
- The *Classic windows* dropdown also offers SaneUI Combat's unit frames, party and raid frames and nameplates: each
  the game's own or SaneUI's, one tick.
- An old `SaneUI_Nameplates` folder left in your AddOns stays off, and SaneUI says once to delete it: the nameplates
  are part of SaneUI Combat now.

## 0.3.2 (2026-11-15)

- Full screens open with a left click on their screen edge or corner, not when the mouse merely reaches it. Each
  addon's *Expand window* settings can turn the click off.
- Sound profiles start on *Disabled*: SaneUI leaves your game's sound settings alone until you choose a profile
  (SaneUI Navigation's minimap satchel).
- Comes with Onboarding, under SaneUI in the addon list: the step-by-step setup of SaneUI's addons, with a sample
  that shows each choice at once. It is read only when a setup opens; `/sane setup` lists them.
- Dungeon maps (SaneUI Navigation): floors whose terrain view left bosses standing on nothing (the Deadmines'
  Ironclad Cove, Blackfathom Deeps, Blackrock Depths) show their map in every view; Shadowfang Keep's tower floors
  each show their own rooms.

## 0.3.1 (2026-11-15)

- First public alpha of SaneUI Core, the base every SaneUI addon needs. On its own it changes nothing you can
  see.
- One options page for all SaneUI addons: Esc > Options > AddOns > SaneUI.
- Profiles, off at first: turn them on to share your settings between your characters.
- Light on your game: every question a SaneUI addon asks the game costs half the time it did.
- Safe error handling: if a SaneUI addon runs into an error, that part goes back to the game's own until your
  next `/reload`, with one line in your chat. `/sane errors` lists them.
- SaneUI's Discord: copy its link from the options page. A bug report, an idea or other feedback written there
  says which Discord channel to paste it into.
