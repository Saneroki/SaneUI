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
  alone or sit as tabs in the general chat, each with its own choice of chats and channels. *A window of its own
  built 2026-11-18* (Saneroki: "the option to have more then one chat window on the screen if people want that"):
  `ChatWindows.lua`, put on the screen from the chat's list (*Chat windows*, *New Window*) or a view's right click;
  the tab of the small window is still to come (board #325).
- **Dialogue** (Saneroki, 2026-10-16): talking to an NPC, and reading a book or a letter, as a scene in
  the middle of the screen instead of the game's gossip, quest and book windows (`Doc/ideas/Dialogue.md`).
- **Guild:** the guild (Blizzard: Communities and guild, `Blizzard_Communities`). *Held 2026-10-20*
  (Saneroki) at the full screen's top right (`Guild.lua`): the very window the guild key opens, the game's or
  the one that answers the key instead, as large as it is, the friends list under it. A guild view of our own:
  *built 2026-10-20* as the module Guild (`Doc/ideas/Guild.md`), whose window stands here in its place while Guild is on
  (`Core.Board.Offer`), the guild key opening it; showing the aliases the player gave (Core's `Core.People.Shown`) is
  still to come.
- **Group finder** (Blizzard: `Blizzard_GroupFinder_VanillaStyle` in this client). *Built 2026-10-17* as a
  panel of the full screen (`Finder.lua`): browse and whisper/invite; listing yourself stays the game's.
- **Friends list** (Blizzard: `Blizzard_FriendsFrame`). *Built 2026-10-17* as a panel of the full screen
  (`Friends.lua`).
- **Conversations** (Saneroki, 2026-10-18) *built 2026-10-18* as a panel at the full screen's left
  (`Conversations.lua`, `Talks.lua`): every whisper and the party's, raid's and instance group's chat, each a
  conversation of its own, listed by the last message; the one chosen in the chat's bubbles with a line to
  write in it; kept per character. Since 2026-10-20 (Saneroki) the chat and the second chat are the first
  two rows of its list and stand beside it when chosen; the panel takes all the room left of the guild
  window and the friends list. Since 2026-11-18 (Saneroki: "group conversations into whispers, party
  conversations so they are not mixed") the conversations stand in two parts, Whispers and Groups, under heads
  that fold; folders by hand and a folder read as one conversation are board #324.
- **A second chat with its own filter** *built 2026-10-17* on the full screen (`Feed.lua`), above the chat
  until 2026-10-20, a row of the conversations' list since. The small window's tabs of chat views are still
  to come.
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
  gone from `src/` and `BUILD/`. SaneUI is not given out yet, so no player has an old copy to handle.
- Docs that named Chat (now `Doc/agent/social.md`, the READMEs, CLAUDE.md's examples) follow.
- `/sane chat` still works next to `/sane social`.
- Open: the banner is still the drawing that reads *Sane Chat*; a new one is to be drawn.

- **Its setup** (Saneroki, 2026-11-18; `Setup.lua`, the addon Onboarding's window): the hot corner taught again and
  chosen (not at all, a left click, the mouse alone: the switch *Hotcorner* beside *Hotcorner requires leftclick*),
  a key for the full screen if wanted (`SANEUI_SOCIAL_FULL`), ticks for the windows.

## Open questions

- Saneroki to decide (2026-10-16): a new banner for *Social* (today's still reads *Sane Chat*); whether the
  smiley stays SaneUI's drawn one (`dev/tools/smiley-art`) or gets a drawing by hand; whether the bubbles
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
