# Social

Planning notes for the **Social** module. This is not a spec yet: it collects what Saneroki has decided so far
(2026-10-16). No code yet.

## Chat becomes Social

The **Chat** module (`SaneUI_Chat`) is renamed **Social** (`SaneUI_Social`, done 2026-10-16). It keeps today's chat
window and grows into the window for everything social. Its window is docked to the **bottom left corner**
by default and fills the screen from there (`Doc/ideas/Windows.md`).

## What it holds

- **Chat:** today's chat window (`src/Social/README.md`).
- **More chat views:** options to add more chat window views, **each with its own chat channel filter**
  (which chats and channels it shows). Today's window has one filter, the ticks in its list of chats
  (`Channels.Shown`); every view would get its own set of ticks. A chat view can be **a window of its
  own and a tab** of the small (not expanded) Social window, like the game's chat windows, which stand
  alone or sit as tabs in the general chat, each with its own choice of chats and channels.
- **Dialogue** (Saneroki, 2026-10-16): talking to an NPC, and reading a book or a letter, as a scene in
  the middle of the screen instead of the game's gossip, quest and book windows (`Doc/ideas/Dialogue.md`).
- **Guild:** the guild (Blizzard: Communities and guild, `Blizzard_Communities`).
- **Group finder** (Blizzard: `Blizzard_GroupFinder_VanillaStyle` in this client). *Built 2026-10-17* as a
  panel of the full screen (`Finder.lua`): browse and whisper/invite; listing yourself stays the game's.
- **Friends list** (Blizzard: `Blizzard_FriendsFrame`). *Built 2026-10-17* as a panel of the full screen
  (`Friends.lua`).
- **A second chat with its own filter** *built 2026-10-17* on the full screen, above the chat (`Feed.lua`).
  The small window's tabs of chat views are still to come.
- **Classic windows** (Saneroki, 2026-10-16, done): full screen, Core's dropdown *Classic windows* lists the
  game's own windows Social stands for. *Chat* puts our chat window away (the switch *Chat window* off)
  and shows the game's chat; *Friends list* brings our window back to its zone and opens the game's
  friends list. Guild and group finder join the list once Social holds them.

## The rename

Done 2026-10-16:

- Folder, TOC and addon name: `src/Social/`, `SaneUI_Social.toc`; title *Social* in the addon list and on
  the settings page.
- Saved settings move from `modules.Chat` to `modules.Social` once, so players keep their settings.
- The old `SaneUI_Chat` folder is deleted: `dev/build` removed it from the game's AddOns folder, and it is
  gone from `src/` and `BUILD/`. Sane UI is not given out yet, so no player has an old copy to handle.
- Docs that named Chat (now `Doc/agent/social.md`, the READMEs, CLAUDE.md's examples) follow.
- `/sane chat` still works next to `/sane social`.
- Open: the banner is still the drawing that reads *Sane Chat*; a new one is to be drawn.

## Open questions

- Saneroki to decide (2026-10-16): a new banner for *Social* (today's still reads *Sane Chat*); whether the
  smiley stays Sane UI's drawn one (`dev/tools/smiley-art`) or gets a drawing by hand; whether the bubbles
  keep their wrapping when the window fills the screen (today they are wrapped for the full width once it
  stands); what a player's old `SaneUI_Chat` folder gets (today: nothing; both would load).
- Saneroki to decide (2026-10-16, from the window work): *Chat* in *Classic windows*, and the window's
  buttons *Classic window* and *close* (free or in the middle) switch our window off for good (the switch
  *Chat window*, kept with the settings). Or only until the next `/reload`? And the corner switches in
  *Expand window* (*Corner radius*, *Don't round corners on screen edges*): Social's small window has no
  background and a full screen is square, so they only shape the start of the motion. Keep them there, or
  take them out for Social?
- How the views are switched (tabs like Blizzard's chat tabs, a bar at the top).
- What the small, docked window shows (the chat only?) and what only full screen shows (guild, group
  finder, friends list).
