# SaneUI Social: the CurseForge project

What goes into the project's fields on CurseForge (authors.curseforge.com). The file uploads come from
`saneui publish` (`dev/tools/release`); their changelog is this project's own,
[changelogs/Social.md](changelogs/Social.md).

**Made 2026-11-18:** *SaneUI Social*, id 1814483, slug `saneui-social`, with the fields below; in
`~/.config/saneui/curseforge.json` its key is `Social`. Social promoted to alpha the same day (tag
`Social/0.3.1-alpha`); its first upload: 0.3.1 alpha, 2026-11-18 (with SaneUI Core 0.3.4, file 9684944), file
9684945.

| Field | Value |
| --- | --- |
| Name | SaneUI Social |
| Folder in the game | `SaneUI_Social` (listed under *SaneUI* as *Social*) |
| Summary | Chat like a messenger: message bubbles, a conversation per whisper, and friends, guild and groups on one screen. |
| Category | Chat & Communication |
| Avatar | `social-avatar.png` of `saneui makelogos` (400 x 400: two speech bubbles, the purple ring) |
| Banner | `social-banner.png`, at the top of the description: after the project is made, uploaded under its Media (not featured) and put in by its address as the description's first line, `![SaneUI Social](<address>)` (README, *The API and the website*) |
| Relations | SaneUI Core: Required Dependency, in the project's Default Relations (checked 2026-11-18, after the first upload); each upload sends it too |
| Release type | By the module's stage: alpha since 2026-11-18 |

## Description

The editor set to *Markdown* when the project is made. *SaneUI addons* (2026-11-18): every SaneUI project with its
link, the same list in each description; put in on CurseForge the same day. The part *Alpha* is written for a first
upload as alpha; at another stage it takes that stage's name.

```markdown
**SaneUI Social** turns the game's chat into a messenger: every message in a bubble, yours on the right,
everybody else's on the left with their class icon and name in their class colour. Left-click the screen's
edge where it is docked and it fills the screen: your conversations, your friends, your guild and the group
finder, side by side.

Made for **WoW: Forever** (English client). It is part of **SaneUI**, a set of interface addons you can
take one by one. It needs **SaneUI Core**, which the CurseForge app installs with it.

## What it does

- **Messages in bubbles.** Each message with its chat's short name (*G*, *P*, *T*, ...) and its time, in the
  game's colours. A ring round the class icon tells you who it is: a friend, a guild member, somebody of your
  party or raid. Links show their tooltip and work as in the game's chat; click a name to whisper.
- **Quiet while you play.** No background, no border, and clicks go through to the game. Messages fade out
  after a few seconds, new ones slide in; turn the mouse wheel over the chat and they are all back to read.
- **Write as always.** Enter or `/` opens the line at the bottom: slash commands, `/w`, `/r`, the history and
  name completion all work. Click the chat's name in it to choose where to write and what the window shows.
  The smiley gives you raid marks and the emotes played most.
- **Channels the same on every character.** Tick a channel of the game once and you are in it on all your
  characters; untick it and you stay out. You start in no public channel: join one with its tick or `/join`.
- **A full screen for everything social.** Docked at a screen edge, left-click that edge and the window
  fills the screen. Its windows share the screen and never overlap; drag them to arrange
  them, and keep several layouts behind tabs.
- **Conversations.** Every whisper, and the chat of every party or raid you join, is a conversation of its
  own, like a messenger's, newest first, with what you have not read yet counted. Whispers and groups stand
  apart, each part under a head that folds it away. They are kept over a logout.
- **Chat views.** As many as you like, each with its own chats: Trade alone, guild and officers, any mix.
- **More chat windows.** Put any chat view on the screen as a chat window of its own beside the chat, with
  its own chats; move and size each in Edit Mode.
- **Friends list and group finder.** Battle.net friends and characters with where they are and what they
  play, friend requests, ignored players, your raid, and the group finder's listings. Send a message or
  invite with one click.
- **Your guild window,** the very one the guild key opens, held in its place on the full screen.
- **Search and copy.** One search finds messages, friends, groups and conversations. Drag over messages and
  press Ctrl+C to copy them.

## How to use

- **Move and size it** in Edit Mode (Esc > Edit Mode), like the game's own frames. Let it go near a corner
  or an edge of the screen and it docks there. At first it is docked in the lower left corner.
- **The full screen:** left-click the screen's very edge where the chat is docked; click it again to go
  back. With *Hotcorner requires leftclick* off (Appearance), pushing the mouse there is enough; with
  *Hotcorner* off, the edge does nothing and a key of your choice opens it (Keybindings > SaneUI).
- **A setup** shows it all the first time, a step at a time: the hot corner (not at all, a left click or
  the mouse), a key for the full screen, and which chat windows you want. Again: `/sane setup social`.
- **The game's chat** is out of sight while Social is open, but keeps every line. `/sane social`, a key of
  your choice (Keybindings > SaneUI) or *Classic windows* on the full screen switches between the two. In a
  fight or a dungeon, while the game gives addons no chat, the game's own chat comes back by itself.
- **Options:** Esc > Options > AddOns > SaneUI > Social: what to show, how many messages to keep, text
  size, the bubbles' look, fades, and how the full screen opens.
- Switched off, the chat is the game's own again.

## Alpha

SaneUI Social is in alpha: it works, but it is still changing, and you may find bugs. If it ever runs into
an error, SaneUI closes its window and gives you the game's chat back until your next `/reload`, so your
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

*You start in no public channel* is how Social starts today (`src/Social/README.md`, *How to use*); card #505
(Public release: Social leaves every public channel) may change that, and the line changes with it. The group
finder's tab is Forever's only: Retail's is its own (card #143).

## Gallery

Real screenshots from the game only, no edited or generated pictures (CurseForge's moderation policies ask
for a visible note on any AI-made showcase image):

1. The small chat over the game: bubbles left and right, class icons with their rings, the line to write in.
2. The full screen's first layout: conversations, guild window, friends list.
3. A whisper's conversation chosen, with its day pill and unread counts in the list.
4. The list on the chat's name: where to write, what to show, the channels on every character.
5. The friends list's group finder tab with its listings.
6. Edit Mode: the window docked, the tinted shape where it snaps.
