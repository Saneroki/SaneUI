# Sane UI: Social

**Status:** a prototype, written and tested outside the game; the input line and the hiding of the game's chat are **not yet tried in the game** · **Since:** 2026-10-14 · **Addon:** `SaneUI_Social` (was `SaneUI_Chat` until 2026-10-16)

## TL;DR
A chat window in the style of a messenger: every message in a bubble, yours at the right edge,
everybody else's at the left with name and class icon. In Blizzard's Edit Mode you move it and size it
by its lower right corner; the bubbles wrap to whatever width you give it. While it is open it stands in for
the game's chat: that one is out of sight, and you write in a line at the bottom of this window.

## How to use
- **Switch it on or off:** tick or untick *Social* under *Sane UI* in the game's addon list.
- **Move and size,** as the game's own frames: only in Blizzard's Edit Mode (Esc > Edit Mode). There the
  window shows Edit Mode's blue box, with *Social* on it while the mouse is on it: drag the box to move
  it, the grip in its lower right corner to size it. Smallest size 180 × 130. Place and size are kept.
  Outside Edit Mode it has no grip and stays where it is.
- **Dock:** in Edit Mode, let the window go near a corner of the screen or the middle of one of its edges, and it
  snaps there (a tinted shape shows where). It then
  stays at that edge at any size; the grip moves to a corner that is not at the screen's edge. Drag it
  away to free it, or to the screen's middle to dock it there. At first it is docked in the lower left
  corner (if another of Sane UI's windows is docked there, it stands beside it).
- **No title bar while small:** the small chat is see-through by design and has no title bar of Core's;
  it moves in Edit Mode only.
- **Full screen title bar:** filling the screen, the window has Core's title bar at its top: *Social* with a
  magnifier before it, the dropdown *Classic windows* and three buttons (the game's own chat: this window is
  put away, as *Chat* in *Classic windows* does; back to its small size; close, which puts it away too).
  **Search:** click *Social* (or the magnifier) and type: only the messages that have every word you type
  are shown, found as a quick finder finds them (the letters in their order, *gld* finds *Guild*), in the
  message, the speaker's name or the chat's name. Esc empties it and every message is back.
- **Full screen:** docked, push the mouse against that screen edge (the game window's very edge, where the
  chat window touches it; docked in a corner, all the way into that corner): the window springs open to fill the whole screen, above the game's bars, on a
  background that hides the game as much as set, every message there to read. Nothing behind it takes the
  mouse: no click, no turn of the camera. On the way its corners start round, with a thin bronze trim, and
  flatten as it grows: full, it is square. Move the mouse away and push it against that edge again: it
  springs back to its size and place. The section *Expand window* (below) says whether it can, how it
  moves, its background and how round its corners start.
- **Classic windows:** full, the dropdown *Classic windows* in the top right corner offers the game's own
  windows instead: *Chat* puts this window away (the switch *Chat window* goes off) and the game's chat is
  back; its button *Sane UI* (the game's square button with circling arrows, just above its chat menu
  button, left of the game's chat), `/sane social` or the switch brings this one again. *Friends list*: the window goes back to its
  place and the game's friends list opens (in a fight the game refuses that to an addon: a line says to use the
  game's own key).
- **Scroll:** mouse wheel, or the bar at the right, which is only there while you are scrolled up from
  the newest message. At the newest message the window follows new ones; scrolled up to read, it stays
  where you are.
- **No background, no border, clicks go through:** the messages stand over the game, and a click on them
  is a click into the game. Only a link, a speaker's name and the chat button take the mouse. The chat
  button is only there while the mouse is over the window; the window has no bar of its own.
- **Click a speaker's name** to whisper to them, right click it for their menu, as in the game's chat.
- **Write:** press Enter or `/` as always, or click the chat button in the window's lower left corner
  (there with the mouse over the window, as high as the line to write in, which opens right of it).
  The line to write in opens at the bottom of the window and the messages move up above it. It is the
  game's own line: slash commands, `/w`, `/r`, the history (Alt + arrow up) and name completion work as
  before. Esc, or the button again, closes it. The line is only there while you write.
- **Icons and emotes:** the smiley at the right end of the line to write in opens a list. At its top the
  game's eight raid marks (star to skull): a click puts one into the line where the cursor is, and once
  sent it shows as its icon in everybody's chat. These are the only icons the game's chat draws from what
  a player writes; it shows none in its public channels (General, Trade, ...), so while you write in one
  the list says so instead. Under them emotes played most (`/hello`, `/wave`, `/bye`, `/thank`,
  `/welcome`, `/cheer`, `/applaud`, `/congratulate`, `/laugh`, `/dance`, `/bow`, `/hug`): a click does it
  at once, at your target if you have one, as typing it would.
- **The newest message is at the bottom.** A few messages stand at the bottom of the window, not at its top.
- **Messages fade out,** each by itself, 60 seconds after it came. The mouse over the window leaves them
  out of sight; turn the mouse wheel over it, or open the line to write in, and all of them fade back in
  to read. They fade out again once the mouse has left at the newest message (scrolled up, they stay),
  or the line has closed.
- **Nothing jumps:** a new message fades in quickly, and the others slide up to make room for it; they
  slide for the line to write in too, and the mouse wheel scrolls smoothly.
- **A message cut by the window's top edge is not shown** until it fits whole.
- **The ring around a class icon** says what the speaker is to you: yellow a friend, green a guild
  member, purple somebody of your raid, blue of your party (the first that holds). White: a stranger.
- **Settings** (Esc > Options > AddOns > Sane UI > Social), in two tabs:
  - *General:* *Chat window*: *Chat window* (on: the window itself), *Show the game's chat too* (on), *Save chat history* (on) with *Messages kept* (slider
    0 to 500, at first 100). *Messages to show*: *System messages*, *Creature messages*, *Addon messages*
    (on), *Channel joins and leaves* (off: somebody joined or left a channel, also the hidden channels addons
    use, such as FGLayer). The same four ticks are in the list on the chat's name.
  - *Appearance:* *Expand window* (Core's, the same for every window that can fill the screen):

    | Line | At first |
    | --- | --- |
    | [x] Can expand to fullscreen (off: the screen edge does nothing; all below greyed out) | on |
    | Animation type: Use global type (Sane UI > Appearance), Glide, Swing, Even, Instant | Use global type |
    | Background opacity, slider 0 to 100 % (100: the game is hidden) | 50 % |
    | Background texture: Solid black, or one of the game's own, as for the bubbles: Marble, Rock, Slate, Iron, Night | Solid black |
    | Corner radius, slider 0 to 100 % of half the window's shorter side at its size (100: a square window is a circle); full, it is square | 10 % |
    | [x] Don't round corners on screen edges (off: every corner is round, also those on the screen's edges, until it is full) | on |

    *Messages*: *Text size* (10 to 24, at first 14), *Bubble opacity* (100 % solid to 0 % text
    only, at first 50 %), *Bubble background* (*Solid colour*, or one of the game's own textures: *Marble*,
    *Rock*, *Slate*, *Iron*, *Night*; at first solid), *Bubble colour* (a swatch that opens the game's colour
    picker, at first a dark grey `26262B`; greyed out while a texture is chosen), *Short names* (on). *Animations*:

    | Line | At first |
    | --- | --- |
    | [x] All animations and fades (off: nothing fades, slides or springs, every message stays, the window fills the screen at once; all below greyed out) | on |
    | [x] Fade in, slider *Fade-in time* 0 to 2 seconds | on, 0.40 seconds |
    | [x] Fade out, slider *Fade-out time* 0 to 2 seconds (off: every message stays) | on, 1.00 seconds |
    | Fade messages after, slider 5 to 300 seconds | 60 seconds |
    | [ ] Opacity, slider 5 to 95 %: how visible a faded message stays | off, 30 % |
    | [x] Slide up, slider *Slide time* 0 to 2 seconds | on, 0.30 seconds |

    A speed is the time a whole fade (out of sight to all there, or back) or a slide takes. A line under one
    that is off is greyed out.
- **The game's chat channels, the same on every character:** last in the list on the chat's name, under *On
  every character*, each of the game's channels (as the game names them, in its language: those you are in,
  those on offer where you are, and any you chose for) opens three choices: *The game decides* (at first),
  *Always in it* or *Never in it*. A channel you are always in is joined wherever the game offers it (a city's
  channels only in a city); one you are never in is left whenever the game puts you in it. It acts a while
  after a character comes into the world, when the game changes its channels, and at once when you choose.
  It works whether the window is open or not, and on every character (the settings of *Social* are account
  wide unless unticked in *Profiles > Accountwide*).
- **The bubbles and the line to write in** are plain fills with round corners: no border, no ornament.
  Every bubble, yours too, and the line are drawn the same way: the same fill (a color or one of the game's
  textures, as set), the same corners, as see-through. Only the text's color tells the kind of message.
  A texture runs on across the plate's pieces without a seam: each piece shows the part of it where it lies
  (texture coordinates from the plate's top left, measured anew at each size: Core's `Shape.lua`). The
  textures are quiet tiles the game fills its own windows with (Core's `Skin.TILES`, the same as for a full
  window's background: `UI-Background-Marble`, `UI-Background-Rock`, `CollectionsBackgroundTile`,
  `BlackMarketBackground-Tile`, `UIFrameOribosBackground`).
- **The line grows with its text:** when the text is wider than the line, it wraps and the line gets
  taller (up to 6 lines), and the messages move up.
- **The chat button also shows where you can write:** it opens the line and, with it, the list of the
  chats you can write in, the one you write in marked. A click on the chat's name in the line shows
  the same list.
- **Links in messages** (an item, a spell, a quest, an achievement): the mouse over one shows its
  tooltip; a click does what it does in the game's chat (the item's window, Shift+click puts the link
  into the line you write in, a player's link opens the player's menu).
- **Short chat names:** above a message the chat is named by the first letter of each word of its
  name: G for Guild, P for Party, R for Raid, RW for Raid Warning, S for Say, T for a trade channel,
  G for General. Guild and General share the G; their colours differ. A setting, on at first.
- **Choose what the window shows:** the same list (the chat button, or a click on the chat's name in
  the line) has, under the chats to write in, a tick for every kind of chat (say, yell, emote,
  whisper, party, raid, instance, guild, officer, creatures, system, addons and the game's notes) and
  for every channel you are in. Untick one and its messages leave the window; tick it and they are
  back, the earlier ones too. Kept between sessions.
- **Choose the chat to write in:** the line starts with the chat's name (*Say:*, *Guild:*). Click it
  for the list of chats you can write in right now (say, yell, party, raid, instance, guild, officer,
  the channels you joined) and pick one. It stays chosen until you pick or type another (`/g`, `/2`).
  A whisper is not in the list: it needs a name (`/w name`, `/r`).
- **The game's own chat stays on show next to this window** by default (setting *Show the game's chat too*).
  Switched off, the game's chat (its windows, tabs and buttons) is out of sight while this window is open.
  `/sane social` (or `/sane chat`, its word from before) switches between the two: our window, or the game's chat as it was. So does a key
  of your choice (Esc > Options > Keybindings, section *Sane UI*: *Show or hide the chat window*). The game's chat goes
  on collecting every line meanwhile, so nothing is missing when it comes back.
- **In a fight or a dungeon** the game may give addons no chat at all (*chat lockdown*). For that time
  the game's own chat is on show, whatever the setting; afterwards it goes out of sight again.
- `/sane social reset` puts the window back at its first place and size.
- **What it shows:**

  | Message | Where | With |
  |---|---|---|
  | Somebody else's (say, yell, whisper, party, raid, instance, guild, officer, channels, creatures) | Left, bubble | Round class icon, name in the class's colour and as large as the message, the chat's name in its colour, time |
  | Your own, and whispers you sent | Right, bubble | The chat's name (*To Thrall* for a whisper), time |
  | Emotes, achievements, the guild's message of the day | Centred, bubble | — (the text says whose; an achiever's name is a link) |
  | Every other line the game's chat shows: the system's (also your time played, a slash command's answer), pings, loot, money, experience, skill ups, reputation, battlegrounds, pet battles, a boss's emote, a channel's notices (joined, left), a friend coming online, AFK and DND answers, a line an addon printed | Centred, bubble | — (as the game's chat writes it) |

  The list of what to show has them as *Pings*, *Loot, money and experience*, *Battlegrounds*, *Pet
  battles*, *Channel joins and leaves* (all channels' notices, hidden at first), *System* (with Battle.net
  notices) and *Addons and the game's notes*. The combat log is not shown.

  The text has the colour the game gives that kind of chat (guild green, whisper pink, ...).
- **If something goes wrong** the module closes its window, gives the game's chat back and says so
  once there, until the next `/reload`. `/sane errors` shows what it was. A single message that cannot
  be read is left out (and noted once); the window goes on. Should no chat be left to type in at all,
  the game menu (Esc) has the button *AddOns*: untick *Social* under *Sane UI* there.

## Technical details
- **The way of a message:** game event → `Log.Read` (what it says) → `Log.Add` (the list) → `Log.added`
  → `Window` (shows it, if the window is open). `Log.Read` touches nothing: an error in it leaves that
  one message out and is noted (`ns.Report`); an error after it stands the module down.
- **Log** (`Log.lua`) knows no frames. A message is a plain table (`side`, `text`, `name`, `class`,
  `label`, `r g b`, `time`). At most 200 are kept (`Log.MAX`), in memory only: a `/reload` empties the
  window. The oldest go 25 at a time (`Log.PRUNE`, marked `gone`), so the window's list drops them in
  one update (`RemoveIndexRange`) instead of one per message. Which events are read, and on which side
  they land, is the table `Log.EVENTS`.
- **Yours or not** is decided by the sender's GUID, not the name (a Forever name is two words and the
  game hands out only the first). `..._INFORM` events are always yours.
- **Layout** (`Layout.lua`) is every size, distance and own colour, and the arithmetic from the window's
  width: row width → widest text (a bubble takes 82 % of the row beside the icon) → bubble → row height.
  Plain numbers, no frames.
- **Responsive, and why it needs measuring:** the scrolling list must know a row's height before the row
  exists, and the height depends on where the text wraps. `Bubble.Measure` sets the text into an unseen
  ruler of the widest allowed width and reads the wrapped width and height. The result is kept on the
  message for that row width, so a message is measured once per width, and drawing (`Bubble.Init`) uses
  the same numbers.
- **Sizing:** while the window is sized the messages keep their wrapping and only settle at the
  bottom. When the sizing is over, Core's window places the window and tells us (`docked`, `Window`
  `Refit`): a new *width* (whole pixels) then rebuilds the list once, which measures every kept message
  again (at most 200 texts). A change of the *height* alone costs nothing of ours.
- **Full screen** (Core's `Edge.lua`, `Window.New` with `edge`): the list is not given to Core as the window's
  `content` (which Core would fade out while the size moves): the messages stay in sight. On every frame of
  the way `Sized` puts them at the list's bottom anew (`Resettle`, with the heights known for the wrapping
  they keep, so nothing is measured), and once the window stands, `docked` (`Placed`) wraps them for the new
  width once. The window is in the layer `HIGH` while it fills the screen: the line to write
  in follows it (`Input.Layer`, at the start and at the end). Full, every message is there to read (`Reveal`, as
  after a turn of the wheel). Its kind of motion is `options.motion`; `off` while all animations are off.
  The list stands in what Core lays out for what a window holds (`window.inside`): the whole window while it
  is small (it has no bar of its own), under Core's title bar while it is full (`Top`: `handle.top`;
  `Layout.ListHeight`'s `top`). The title bar's search goes to
  `Window.Search`: `Core.Fuzzy.Query`, and `Visible` keeps a message only if `Core.Fuzzy.Match` finds every
  word in its readable text (colours, links' codes and icons taken out: `Core.Fuzzy.Plain`), its `name` or its
  `label`. The log is at most a few hundred messages, so it is searched at once (`Core.Fuzzy.Filter` is for
  longer lists).
  The title bar holds Core's dropdown *Classic windows*, whose list is `ns.CLASSIC` (`Social.lua`): *Chat* (`Choose(false)`, a
  line in chat says how to bring the window back), *Friends list* (`ToggleFriendsFrame(FRIEND_TAB_FRIENDS)`,
  as the game's key opens it, only if `FriendsFrame` is not shown; nothing if the game has no such function). The
  section *Expand window* is Core's (`Edge.Options`, with its corner switches, `Shape.Options`), put at the
  top of the tab, before the first switch of the tab *Appearance*, its *Animation type* also under *All
  animations and fades* (`Edge.Options`' `under`); the window reads it by `edge = ns.options`, and Core
  itself follows a change of one of its switches (`edge:Update`).
- **Ours or the game's chat, one switch:** the setting *Chat window* (`options.window`) is the one place it
  is kept. Every way to change it sets it (`Choose`, `Core.Set`: an open options page follows): the button
  for the game's own window in the full window's title bar, its close button, *Chat* in *Classic windows*,
  the button *Sane UI* on the game's chat, `/sane social`, the key (`Bindings.xml`: `ns.Toggle`). Its change
  goes to `Window.Follow`, which shows ours (through Core's `window:Open()`, full again if it was left so) or
  puts it away, and keeps Core's memory of the window (`place.native`) the same.
- **The line to write in is the game's edit box** (`Input.lua`), only moved. An edit box of our own
  could not run `/cast`, `/target` and the like (they must come from the game's code), and would have
  to rebuild history, completion, `/w` and `/r`. The game says when one of its edit boxes is shown or
  hidden (`EventRegistry`: `ChatFrame.OnEditBoxShow` / `OnEditBoxHide`): shown, it is anchored to our
  window's bottom and the list ends `Layout.INPUT` higher (`Window` `Room`); hidden, the list gets the
  room back. Its own anchors are remembered and put back when our window goes.
- **Only there while you write.** The game puts a line nobody writes in to rest itself (its edit box's
  `Deactivate`: after Esc, after sending, when the cursor leaves an empty line). In its classic style
  that hides the line. Its IM style (the default) keeps it on show, faded and without the chat's name;
  here such a line is made invisible and lets the mouse through instead (`Input` `Rest`: alpha 0,
  `EnableMouse(false)`, a `hooksecurefunc` on `Deactivate`), and the window has its room back. A line
  the game shows empty and without the cursor rests a frame later. When the game gives a resting line
  the cursor (`ChatFrame.OnEditBoxFocusGained`; it does not show it anew) it is seen again (`Rise`). A
  line with text in it stays. So a visible line always carries the chat's name. Our code never calls
  the edit box's `Hide`: its `OnHide` would tidy up the game's chat state (`DeactivateChat`, which
  writes `ACTIVE_CHAT_EDIT_BOX`) under our taint.
- **Drawn above the action bars, as one:** the window is in the strata the action bars are in
  (`MEDIUM`) at frame level 100 (theirs is 50 and a few); all its parts are its children. The game puts
  the edit box above everything while you write (`DIALOG`); a frame after it was shown it gets the
  window's strata and a level just above the window's. Strata and level are given back when our window
  goes (unless the game has set its own strata since), and so are the alpha and the mouse of a line at rest.
- **No background, clickthrough:** the window is a plain frame that takes no click; it takes only the
  mouse's coming (Core's `Core.Hover`: `SetMouseMotionEnabled`, its `OnEnter`), and the list the wheel. Its
  chrome (the chat button, which takes clicks) is hidden while the mouse is not over the window, so then
  nothing but links does. The box to move it by and the grip are Core's, in Blizzard's Edit Mode only
  (Core's `Window.lua`, `EditMode.lua`; the window's `title` is on the box). From the mouse's coming a watch
  (5 a second) asks whether it is still over the window, until it has gone (`Wake`, `Left`); a held mouse
  button counts, so a drag that leaves the window does not lose its grip.
- **Scroll bar** (`Window` `Bar`): shown while the list does not follow the newest message (`follow`,
  set on every scroll), whatever the mouse.
- **Names are links** (`Log` `Link`): a speaker's name is the game's own link to them, `GetPlayerLink`
  (name with realm, line ID, kind of chat), or `GetBNPlayerLink` for a Battle.net whisper (by account),
  so a click goes the game's way through `SetItemRef`: left whispers, right opens their menu, Shift puts
  the name into the line.
- **Cut rows** (`Window` `Trim`, `Bubble.Cut`): after the list has laid out or scrolled (`OnLayout`,
  `OnScroll`, and once more a frame later), a row whose top is above the list's top edge has its
  content hidden. The content is one frame inside the row, so the row's alpha stays the fading's.
- **Round icons and rings** (`Bubble.lua`): the class icon cut round by Core (`Core.Shape.Round`: Core's
  circle mask, else the game's portrait mask `Interface\CharacterFrame\TempPortraitAlphaMask`), on a round
  disc of plain colour 2 pixels larger;
  the disc's rim is the ring. What a speaker is to you is asked when the message comes (`Log.lua`
  `Tie`: `C_FriendList.IsFriend`, `C_BattleNet.GetAccountInfoByGUID`, `IsGuildMember`,
  `C_PartyInfo.IsGUIDInGroup`, `IsInRaid`) and kept with the message. The ring's colour is the only sign
  of it (the chat's name says guild and party chat, but not a friend).
- **Asked once per speaker:** the class (`GetPlayerInfoByGUID`) and what a speaker is to you are kept
  per GUID (at most 500 speakers, then all are asked anew). What a speaker is to you is asked anew
  when your friends, your guild or your group change (`FRIENDLIST_UPDATE`, `BN_FRIEND_INFO_CHANGED`,
  `BN_FRIEND_LIST_SIZE_CHANGED`, `GUILD_ROSTER_UPDATE`, `PLAYER_GUILD_UPDATE`, `GROUP_ROSTER_UPDATE`).
- **Text size** (`Bubble.Size`): a font object of ours (`SaneUIChatFont`, `Core.Font`) copies the game's chat font and
  only sets the size, as the game does for its own chat windows; messages, names and notes use it. A
  change measures every message anew and sets the height of the line above a bubble (`Layout.HEAD`).
- **Links** (`Links.lua`): a bubble's frame and a row's body have links enabled
  (`SetHyperlinksEnabled`), so only the links take the mouse. Over a link of a kind the game's tooltip
  shows by itself, `GameTooltip:SetHyperlink` (in a `pcall`: a link the game cannot show shows
  nothing); a click is the game's own `SetItemRef`, with the main chat window as the chat frame.
- **Short names** (`Channels.Brief`): the first letter (UTF-8) of each word of the chat's name, the
  game's own word or the channel's name before its " - " (`Channels.Base`); made once per name and
  kept, chosen when a message is drawn. Not for *To Thrall*.
- **A channel's name** is the one the game shows (`Channels.Name`, the game's
  `ChatFrameUtil.ResolveChannelName`): a community's channel is called `Community:<club>:<stream>`
  inside and shows as the community's name.
- **What is shown** (`Log.GROUPS`, `Channels.Shown(group)`): a message carries a group (`"GUILD"`,
  `"CHANNEL:2"`, `"PRINT"`; a channel by its number, which is what the list has). `Log.GROUPS` is the one
  list of them, in the order the list of what to show offers them, each with the kinds of chat that
  belong to it (a leader's and a warning's lines belong to their chat, Battle.net whispers to
  whispers). The switched-off groups are kept in the setting `mute`, but for the four with a
  setting of their own (`ns.SHOWS`: `SYSTEM`, `MONSTER`, `PRINT`, `CHANNEL_NOTICES`): their tick in the list and
  the switch in the settings are the same value (`Channels.Shown`, `Channels.Flip`, by `Core.Set`). The log keeps every
  message; the window's list is the log without the switched-off groups, made anew when a tick
  changes. The channels listed are those the game says you are in (`GetChannelList`): only they bring
  messages.
- **The plate** (Core's `Shape.lua`): the game has no round-cornered fill that takes any colour, so a
  bubble stands on a Core Shape of a fixed radius (`Layout.RADIUS`, 8): strips and a square piece in each
  corner, the corners cut by Core's circle mask (a whole mask twice the radius wide on the arc's centre),
  of plain colour or of a tile. No piece lies over another, so the fill can be see-through; the text is not
  part of it and stays solid. One look is shared by every bubble (`Bubble` `Paint`: colour, tile, alpha), and
  a bubble is painted again only when that look changed; a plate without a trim makes none. The line to
  write in has a plate too, which follows its size (`shape:Follow`).
- **The line's look and height** (`Input.lua` `Dress`, `Grow`): the six pieces of the game's border
  around the edit box are made invisible (alpha 0, not hidden: the game shows and hides them itself)
  and a plate of ours lies behind it. The edit box is set to several lines (`SetMultiLine`), so its
  text wraps; its height is measured with a text of ours in the box's font and width
  (`Layout.InputHeight`), after every change of the text (`HookScript` `OnTextChanged`) and of the
  label (`hooksecurefunc` on its `UpdateHeader`, which also sets the text's insets anew). The label
  hangs on the line's top so it stays on the first line. A line break in the text (pasted) becomes a
  space when the message is sent (`ChatFrame.OnEditBoxPreSendText`). The window is only told of a new
  height (`Give`), not of every key. All of it is undone when our window goes (`Release`: each edit
  box by itself, its anchors first).
- **The button** (`Input.Toggle`) calls what the keys call: `ChatFrameUtil.OpenChat(nil)`
  (Enter) or the edit box's `ClearChat` (Esc). Its art is the game's chat button
  (`Interface\ChatFrame\UI-ChatIcon-Chat-Up` / `-Down`).
- **The smiley** (`Picker.lua`) is a child of the window at its lower right, left of the grip
  (`Layout.GRIP_ROOM`, `Layout.FACE`; the line ends before it, `Layout.INPUT_RIGHT`), on the first line's
  height, shown by `Input` whenever the line is dressed and hidden when it rests, closes or is given back.
  Its list is the game's menu (`MenuUtil.CreateContextMenu`): a title, the marks, a divider, a title, the
  emotes. The marks are one line of the menu (`CreateFrame` with an initializer), eight buttons attached
  to it with `MenuTemplates.AttachBasicButton`, each with the game's mark art
  (`Interface\TargetingFrame\UI-RaidTargetingIcon_<n>`, as `ICON_LIST`) and its name (`RAID_TARGET_<n>`)
  as tooltip; the initializer returns the line's size. A click puts `{rt<n>}` into the edit box
  (`Insert`, the tag every language knows) and closes the menu. Not offered while the line writes in a
  channel of the kind *Zone* (`C_ChatInfo.GetChannelInfoFromIdentifier`, `Enum.PermanentChatChannelType`):
  those are the game's public channels, whose messages come with `suppressRaidIcons`. An emote by the
  game's token (`Picker.EMOTES`) is done with `C_ChatInfo.PerformEmote` (`DoEmote` where that is all the
  client has), as the game's chat menu does; its name is its command `EMOTE<n>_CMD1`, found once among
  the game's emotes (`EMOTE<n>_TOKEN`, up to `MAXEMOTEINDEX`). The art is our own (the game has no
  smiley); missing, the button falls back to the game's chat button art.
- **Newest at the bottom** (`Window` `Settle`): the scrolling list starts at its top, so the view gets
  a top padding of whatever the messages leave free (list height minus their heights), none once they
  fill it. Set anew for a message, a new size and the line to write in.
- **Fading** (`Fade.lua`, no frames): a message's fade is its own, kept on the message (`from`, `to`,
  `since`, `span`), never on a row: the list hands its rows from one message to another whenever it
  lays them out, and a fade kept on a row was cut off or begun anew by a new message, a scroll or a
  slide. `Fade.Alpha(entry, now)` follows from those four alone (eased on the game's curve `InOutQuadratic`,
  `Fade.CURVE`, through `Core.Motion.Ease`: slow at both ends); a fade that
  turns back starts from where it is and takes only the time for the rest of the way. In 0.4 s
  (`Layout.APPEAR`), out 1 s (`Layout.FADE`). A new message enters from nothing (`Fade.Enter`).
- **Painting** (`Window` `Paint`): every row shows its message's alpha, when it is drawn (`DrawRow`)
  and every frame while one in view fades (`OnUpdate` on the window, removed once none does). No
  animation groups for fading.
- **When** (`Window` `Refade`): every message is told where to go: in if fading is off, the list is
  revealed or you write, otherwise in until `entry.at + fadeAfter`. One timer (`C_Timer.After`, a counter
  makes older ones do nothing) looks again when the next message's time is over. Messages that came
  while the window was hidden are set at once when it is shown (`Refade(true)`).
  `Window` `Reveal`: a turn of the wheel (`HookScript` `OnMouseWheel` on the list, also at its end where
  nothing scrolls) shows all; it ends when the mouse leaves while the list follows, or when the list comes
  back to its newest message with the mouse away. The
  list's own `OnScroll` does not reveal: it comes for the list's own moves too, and while a message is
  added the list is for a moment not at its end.
- **Sliding** (`Window` `Slide`): when the messages move up at once (a new one at the newest, the line to
  write in opening or growing), the list's `ScrollTarget` slides (`Core.Motion.Slide`: two Translation
  animations together, as the game's own do: one of no time back down by the move, one of the slide time,
  0.3 s at first, smoothed, up by it). A slide still going on adds what it had left (`GetSmoothProgress`). The list clips its children,
  so a new row slides in from its bottom edge, fading in on its way (0.4 s, so most of it is seen). Wheel scrolling is the list's own interpolation
  (`SetInterpolateScroll` on list and scroll bar). The slide moves the list's content and touches no
  alpha; the fades touch no position: neither knows the other.
- **The list of chats** (`Channels.lua`, no frames) is built when the label is clicked: `IsInGroup`,
  `IsInRaid`, `IsInGuild`, `C_GuildInfo.IsGuildOfficer`, `GetChannelList`. The menu (`Menu.lua`) is the
  game's (`MenuUtil.CreateContextMenu`, radio lines). A choice calls the edit box's own `SetChatType`,
  `SetStickyType`, `SetChannelTarget` and `ChatFrameUtil.ActivateChat`, as the game's friends list
  does for a whisper. The button on the label is a child of the edit box (above it, shown with it);
  no field is written into the edit box.
- **The game's chat out of sight** (`Native.lua`): every chat window (`CHAT_FRAMES`), the tab of an
  undocked one, the button of a minimised one (`ChatFrame<n>Minimized`, a child of the screen), the
  dock and the chat's buttons get a hidden frame of ours as parent (lent, `Core.Lend`: their strata and
  level noted first, so they are drawn as before once back, as the game's own way of moving them keeps
  them), and their own parent back later,
  but only while their parent is still ours: the game moves some of them itself (tabs into and out of
  the dock, all of them under a window that fills the screen). Nothing is hidden or unregistered, so
  the game's chat stays complete. Done again when the game makes a whisper window
  (`FCF_OpenTemporaryWindow`) or a minimised window's button (`FCF_MinimizeFrame`).
- **Chat lockdown:** in a fight, a dungeon or a PvP match the game hands addons the chat events with
  secret texts (`SecretInChatMessagingLockdown`), and `Log.Read` leaves them out. While
  `C_ChatInfo.InChatMessagingLockdown()` says so, the game's own chat is on show (`Window.Native`); the
  game tells before a lockdown begins and after it ended (`ADDON_RESTRICTION_STATE_CHANGED`), and it is
  asked again a frame later. A secret text is never measured or compared.
- **Every other line** (`Log.Line`): only the speakers' events, emotes and achievements are read
  (`Log.EVENTS`); everything else is taken as the game's chat writes it, so it has the game's own wording,
  links and filters. Many system lines have no event at all (`ChatFrameUtil.DisplaySystemMessageInPrimary`),
  a ping is only put together by the game's chat. A hook on the `AddMessage` of each of the game's chat
  windows (`CHAT_FRAMES`, not the combat log) gets the text, the colour, the chat type's number (fifth value;
  `ChatTypeInfo[kind].id`) and, for a speaker's line, its event (eighth value). A line of an event of ours,
  or of a kind of chat we read, is left out; any other is a note in the group of its kind (none: `PRINT`, a
  `CHANNELn`: that channel's). The same line in two windows is one: one event reaches the windows in a row,
  in one frame, so a window adds a line only when it writes that text more often in that frame than any
  other did (`Fresh`). The time the game puts in front of a line is taken off. Not every client writes the
  number: this one writes loot and skill lines with neither number nor event. So a filter of the game's chat
  (`ChatFrame_AddMessageEventFilter`, for every chat event we do not read: `Log.Unread`) is told the window
  and the event right before the window writes that event's line (`Log.Before`); the window's `OnEvent`
  ending clears it (`Log.After`). The filter filters nothing. A number not known is learned anew once.
- **The game's channels** (`Join.lua`, no frames): the wishes are the setting `presence` (`[channel name] =
  true` always in it, `false` never in it; none: the game decides), kept with the settings, no control on the
  page. Listed (`Join.List`) from the game: the channels you are in whose kind is the game's (*Zone*,
  `C_ChatInfo.GetChannelInfoFromIdentifier`), by their number; then those on offer where you are
  (`EnumerateServerChannels`); then any other with a wish. Joined with `JoinPermanentChannel` (into the first
  chat window, as `/join` does) only where the game offers it, asked for once per zone (`GetRealZoneText`), so a
  refused join is not asked for again and again; left with `LeaveChannelByName`. Looked at 8 seconds after each
  `PLAYER_ENTERING_WORLD` (the game joins its own first, so their numbers stay the game's), 2 seconds after the
  game tells of its channels (`CHAT_MSG_CHANNEL_NOTICE`, once that first look is done), and at once when a wish
  changes (also by a profile). While chat is
  locked down (`C_ChatInfo.InChatMessagingLockdown`) it waits, and looks again at the next
  `ADDON_RESTRICTION_STATE_CHANGED`. It runs through `ns.Safe`, not `ns.Guarded`: an error there is noted and
  does not close the window. The menu's three choices per channel are submenus (`Menu.lua`).
- **Moving, sizing, docking and the kept place** are Core's (`Core.Window.New` of the kind `screen`, docked
  at first in the lower left corner: `first.dock`; [src/Core/README.md](../Core/README.md)); the place is
  `SaneUIDB.modules.Social.place`.
- **The window** (`Window.lua`) is made at the first show, from the game's parts:

  | Part | The game's |
  |---|---|
  | Fill of bubbles and of the line to write in | Core's `Shape`, of plain colour or one of the game's tiles (`Skin.TILES`); the round corners are Core's circle mask |
  | List | `WowScrollBoxList` + `MinimalScrollBar` + a linear view with `SetElementExtentCalculator`; rows only for the messages in view |
  | Grip | `PanelResizeButtonTemplate` (it sizes the window and holds the smallest size) |
  | Text | `ChatFontNormal`; the line above a bubble `GameFontHighlightSmall` |
  | Icon | `GetClassAtlas` (`classicon-<class>`); a question mark for a speaker without a known class |
  | Colours | `ChatTypeInfo` (per chat and per channel), `RAID_CLASS_COLORS` |

  The only colours of our own are the rings (`Layout.TIES`) and the bubbles' first grey (`26262B`).
- **No art is shipped.**
- **Saved** (in Core's `SaneUIDB.modules.Social`, which Core moves there once from `modules.Chat`): `place = { x, y, width, height, dock, full, native }` (top left corner from
  the screen's bottom left; Core's window), the settings (`options`, with `window` and `mute`). No frame name, so the client itself saves nothing.
- **The history** (`Log.Saved`, `Log.Restore`): at `PLAYER_LOGOUT` (also at a `/reload`; the game writes the
  saved settings right after) the last *Messages kept* messages go into `chars[character].history`, only
  what a message is made of (`KEPT`: side, text, name, link, class, tie, labels, group, colour, time). A message
  with a Battle.net friend's name (`|K…|k`, `|HBNplayer`) is not kept: that name stands for the friend in that
  session only, and may be another's after a restart; a player's link is kept without its line number
  (`:0`, as the game writes none), which is this session's. At the
  login, before the window shows, they stand in front of the log as long gone by (`at` a day back), so they
  are faded out at once and there when you scroll back. The log keeps at least as many (`Log.Keep`: 200, or
  the history's length). 500 small tables are no cost worth naming in the saved settings or the list (it
  draws only the rows in view); the login measures each kept message once. The history says what it is
  (`historyVersion`, `Log.HISTORY` = 2): one saved before lines went by their event has prints that are
  none; at loading those are sorted anew (`Guess`): one with a channel's link (`|Hchannel:`) is a channel's
  notice, a white one stays a print, else the group of the kinds of chat with its very colour (the
  system's first, none if they differ). A line it has twice at once, as a print and in a group (the
  guild's message of the day), is there once.
- **Cost.** Per chat event: one table for the message, one measurement, one update of the list (and
  every 25 messages one more, for the oldest that go). A speaker is asked about once. No `OnUpdate` at
  rest: the fades' runs only while a message in view fades, Core's watch of the mouse only from its coming
  over the window until it has gone. Timers: a look a frame later
  (`Core.Later`) after the list scrolled, the line was shown or chat lockdown changed. Hidden, the
  window draws nothing; the messages still go into the log.
- **Secret values.** In a fight the game may hide a message from addons. Everything read goes through
  `Plain`; a hidden text is left out (the game's own chat shows it, see *chat lockdown*), a hidden
  sender has no name.
- **Following the newest message** is a flag of the window (`follow`), set by the list's `OnScroll`:
  true at the end or while everything fits. A new message, a new size and the line to write in keep
  the list at the end only while it is true.
- **Falling back** (Core's `ns.Guarded`, `ns.StandDown`; `ns.GiveBack` here): every step runs through
  `ns.Guarded` (an `xpcall` that keeps where the error happened), also what the list, the menu, the
  game's edit boxes and the mouse call outside our own code. An error stands the module down for the
  session: the edit boxes are given back first (each by itself, its anchors before its look), the
  module stops listening to them, the window goes and the game's chat is back. Each of those steps
  runs by itself; one that fails is noted (`Social: giving back`) and does not stop the next.
- **Taint** (not yet checked in the game). Our code still changes the game's edit box in two ways:
  a choice in the list of chats calls its `SetChatType` / `SetStickyType` / `SetChannelTarget`
  (frame attributes, then written by addon code), and the window's button calls `ChatFrameUtil.OpenChat`
  and the edit box's `ClearChat`. The game reads the chat type when it sends (`SendText`, then
  `C_ChatInfo.SendChatMessage`, which has restrictions). Whether a message sent, or a `/cast` typed,
  after such a choice is blocked must be tried in the game with `/console taintLog 1` (`Logs/taint.log`;
  switch it off afterwards). Enter, `/`, Esc and sending themselves stay the game's code.
- **Tests:** `lua5.1 dev/tests/social.lua` (349 checks): what an event says, the layout arithmetic, sides and
  bubbles, wrapping anew once a sizing is over, following the newest message, place and size, the game's
  chat out of sight and back (also a minimised window's button, a frame the game moved meanwhile, chat
  lockdown), printed lines, the line to write in and its button, the line at rest in both chat styles
  and given back as it was, the list of chats, messages at the bottom, fading, the settings, text size,
  rings, a speaker asked about once, community channels, the handles with the mouse over the window,
  cut rows, the oldest messages going in batches, a message that cannot be read, the fall-back, the
  game's channels and their wishes (the list, once a zone, only where offered, not in lockdown, a profile's
  wishes, with the window closed), the switch *Chat window*, Core's window and the game's chat agreeing
  whichever way it changed, and the key.
  They cannot judge the look.

## Files
| File | What it is |
|---|---|
| `SaneUI_Social.toc` | The addon `SaneUI_Social` |
| `Social.lua` | The module's table, its texts and switches (also the wishes for the game's channels), the events, `/sane social`, the fall-back |
| `Log.lua` | What an event says; the list of messages. Knows no frames |
| `Layout.lua` | Sizes, distances, fills; the arithmetic from the window's width. Knows no frames |
| `Links.lua` | The links in a message: tooltip on the mouse, the game's click |
| `Bubble.lua` | One message: measured and drawn |
| `Channels.lua` | The chats you can write in right now. Knows no frames |
| `Native.lua` | The game's own chat: out of sight, and back |
| `Input.lua` | The line to write in: the game's edit box in our window, at rest, given back |
| `Menu.lua` | The list on the line's label: where to write, what the window shows, the game's channels on every character |
| `Picker.lua` | The smiley beside the line and its list: raid marks to write, emotes to do |
| `Art/smiley.blp` | The smiley (24 x 24). Original art of Sane UI (see the project's `LICENSE`), drawn by `dev/tools/smiley-art` into `assets/SaneSocial-Smiley.png`, made by `dev/tools/art`; the game has no smiley of its own |
| `Join.lua` | The game's chat channels, the same on every character as wished. Knows no frames |
| `Window.lua` | The window: moved, sized, scrolled, kept |
| `Bindings.xml` | Its key in the game's key bindings (section *Sane UI*, Core's): the chat window shown or hidden |

## To check in the game
- The smiley stands right of the line while you write and goes with it. Its list: a click on a mark puts
  `{rt1}` ... into the line, the cursor stays there, and the sent message shows the icon (say, guild,
  party, a whisper); in Trade the list offers no marks. A click on an emote does it (also during a fight;
  in an instance while chat is locked down). The menu row of marks is as wide as the list, each with its
  name as tooltip. In a channel of your own (not the game's) the marks are offered: check that they show
  there too (only the game's *Zone* channels are taken to hide them).
- With the mouse over the window, a unit of the world behind it still shows its tooltip and highlight, and
  a click goes through (the window takes only the mouse's motion, for `Core.Hover`); the chat button comes
  as the mouse does and goes a moment after it has left.
- At the first login the window stands docked in the lower left corner, over the game's chat there.
- Filling the screen and going back, the bubbles stay in sight and at the bottom all the way, and are
  wrapped for the new width once the window stands.
- Joins and leaves of channels (FGLayer) stay hidden with *Channel joins and leaves* off, also those
  restored from the saved history after `/reload`.
- With our window put away (*Chat* in *Classic windows*, its close button, or the switch off before a
  login), the game's chat has the button *Sane UI* just above its chat menu button, fading with the
  game's buttons there; a click brings our window back and the button goes. Not there while ours is.
- The small window's bar has no title *Social* any more.
- The window appears at the left edge, moves by its bar, sizes by its grip, and is back in place after `/reload`.
- Bubbles wrap anew once the window has been sized narrower or wider (not during the drag); no text leaves its bubble; nothing overlaps.
- A very narrow window (180 wide) is still readable; the line above a bubble is cut with an ellipsis.
- Sizing with a full log (200 messages) does not stutter.
- The class icons show (`classicon-...` exists in this client), and the tooltip border looks right as a bubble.
- The scroll bar ends above the grip; the window follows new messages only when it is at the newest one.
- A click on a bubble is a click into the world (target, turn the camera); the links and names in it still show their tooltip and answer a click with the window taking no mouse.
- The mouse wheel over the list scrolls it; the scroll bar shows only while scrolled up.
- A click on a name opens a whisper to them in the line; a right click their menu.
- A very long word without spaces (a link) wraps inside its bubble.
- Enter and `/` open the line at the bottom of the window; the messages move up and the newest stays in view.
- The game's edit box art fits the window's bottom and ends before the grip.
- `/cast`, `/target` and a macro's slash commands typed there are not blocked ("action blocked by an addon").
- A click on *Say:* opens the list and the line keeps the cursor; the choice is still there after sending.
- Nothing of the game's chat is left on screen (tabs, the buttons beside it, an undocked window, the
  combat log), also after a loading screen and after Edit Mode; `/sane social` brings all of it back in place.
- In both chat styles (Options > Social > Chat style) the line is gone when you are not writing, and
  shows the chat's name whenever it is there. In IM style: Enter, `/`, a click on the window's button
  and a click on a chat tab bring it back; a click where the invisible line is does nothing; after
  `/sane social` the game's faded line is back at its place, clickable.
- `/console taintLog 1`, then write in the window, choose a chat in the list, send, type `/cast ...`, fight:
  no "action blocked", and nothing of Sane UI Social in `Logs/taint.log`.
- In a fight or a dungeon with *Show the game's chat too* off: the game's own chat comes back while chat is
  locked down, and goes again afterwards.
- A minimised undocked chat window's button is out of sight with *Show the game's chat too* off, and back after.
- Community channels show the community's name, not `Community:…`; party and raid rings show.
- The bubbles' corners are round and clean (no seam or darker line between the pieces, also half
  see-through) at every size; the text reads well over a bright and a dark world at 50 %.
- The ring around an icon is thin and even.
- **The line to write in, set to several lines** (the riskiest part, untried): Enter still sends and
  adds no line break; the chat's name and the first line of text stand level; a long text wraps and
  the line grows; arrow keys, the history (Alt + up), name completion and `/cast` work as before;
  after `/sane social` the game's own edit box is as it was.
- The mouse over an item, spell or quest link in a bubble shows its tooltip; a click opens it as in the
  game's chat; Shift+click puts it into the line; clicks elsewhere in the window still reach the world.
- The short names read well; the list is not too long with many channels; a tick keeps the list
  open and changes the window at once.
- The button opens the line and the list of chats together; the list does not take the cursor away.
- The button in the lower left corner appears with the mouse over the window, opens and closes the
  line, and sits well beside it.
- The window is drawn over the action bars, and so is the line to write in (not over open windows).
- Without a background: the messages read well over the world; the handles appear on mouse-over of
  the list too, not only of the top strip; a drag by the bar or the grip is not lost outside the window.
- The top message is hidden while the edge cuts it, also right after scrolling stops.
- The class icons are round, the rings even and in the right colours; the name is as large as the text.
- The text size slider changes messages and names at once, and nothing overlaps at 10 and at 24.
- One message alone stands at the bottom of the window, also while the line is open.
- A message fades after its seconds; the mouse over the window leaves them faded, the mouse wheel
  brings all back, and they fade again when the mouse leaves. The slider and the switch count at once.
- A new message fades in and the others slide up smoothly, without a flicker in the first frame; many
  messages at once (a busy trade channel) do not stutter. The wheel scrolls smoothly.
- `/sane` and an error line are readable as notes, in a bubble in the middle.
- A guild member's achievement and the guild's message of the day at login come in, once each (not again from the game's own chat).
- The list on the chat's name ends with *On every character* and the game's channels; *Never in it* leaves
  at once, *Always in it* joins where the game offers it (a city's channels only in a city: check that
  `EnumerateServerChannels` leaves them out elsewhere), also after a zone change, and the channel numbers
  stay the game's at login.

## Not there yet
Tabs or filters per chat (more chat views, `Doc/ideas/Social.md`), messages of one speaker in a row drawn as
a group, a close button, a sign besides colour for what a speaker is to you.

## History
- 2026-10-17 — On Core's parts: a window of the kind `screen`, docked at first in the lower left corner, its
  list in Core's `window.inside` (the small window's bar is gone); the mouse seen by `Core.Hover` (the ticker
  is gone); the switch *Chat window* the one place ours or the game's chat is kept (`Choose`, `Core.Set`,
  `Window.Follow`; Core's window remembers the same); a key in the game's key bindings (`Bindings.xml`). The
  bubbles on Core's `Shape` (`Plate.lua` is gone), their tiles Core's `Skin.TILES` (`ns.BACKS` is gone), the
  icons `Core.Shape.Round`, the slide `Core.Motion.Slide`, the fade's curve the game's (`Core.Motion.Ease`),
  the game's chat and edit boxes lent with `Core.Lend`, `Core.Font`, `Core.Tip`, `Core.Fuzzy.Plain`.
- 2026-10-17 — The game's chat channels moved from the page *Social* into the list on the chat's name
  (*On every character*: *The game decides*, *Always in it*, *Never in it*), listed from the game, joined only
  where the game offers them; their wishes are the setting `presence` (the earlier switches are not read).
- 2026-10-16 — The button *Sane UI* on the game's chat (Core's `Attach`, placed by `ns.NATIVE.anchor` above
  `ChatFrameMenuButton` in `ChatFrame1ButtonFrame`), there only while our window is away (`Back` in
  `Window.lua`); off at login, the window is made out of sight for it (`Window.Away`). The small window's bar
  lost its title *Social* (Saneroki). Not yet tried in the game.
- 2026-10-16 — No title bar while small (Core's buttons left the small window); filling the screen, Core's
  title bar at its top with the search over the messages (fuzzy), the dropdown and the buttons. Not yet
  tried in the game.
- 2026-10-16 — Free or docked in the screen's middle, Core's three buttons in the top right corner (with the
  bar): the game's chat (`ns.NATIVE`), full screen, close (`ns.Close`: both put our window away); the list
  starts under them then (`Top`). Not yet tried in the game.
- 2026-10-16 — Moved and sized only in Blizzard's Edit Mode (Core's box and grip); outside it no grip on the
  mouse's coming, and the bar is only the title, taking no click. Not yet tried in the game.
- 2026-10-16 — Fixed: the messages went out of sight and came in again whenever the window filled the screen
  or went back. They stay in sight and at the bottom all the way now, and are wrapped for the new width once
  it stands.
- 2026-10-16 — A smiley right of the line to write in: its list puts the game's raid marks (`{rt1}` to
  `{rt8}`) into the line, except in the game's public channels, which show none, and does emotes played
  most (`/hello`, `/cheer`, `/thank`, ...). Not yet tried in the game.
- 2026-10-16 — Full, the dropdown *Classic windows* (Core's): *Chat* puts our window away and the game's chat
  is back, *Friends list* opens the game's friends list; the list starts under the dropdown. The full screen
  background is always square. Not yet tried in the game.
- 2026-10-16 — The section *Expand window* is first in the tab *Appearance* again (it had come after
  *Animations*), with *Corner radius* (10 %) and *Don't round corners on screen edges* (on): the full screen
  background has round corners and a bronze trim on its way, square where it meets the screen's edge.
  Not yet tried in the game.
- 2026-10-16 — Renamed from Chat to Social (`src/Social`, `SaneUI_Social`, page and title *Social*), the
  module that is to hold everything social (`Doc/ideas/Social.md`). Core moves the saved settings from
  `modules.Chat` to `modules.Social` once; `/sane chat` still works next to `/sane social`. The banner
  is still the drawing that reads *Sane Chat*.
- 2026-10-15 — After a review. Fixed: a whisper's name the game hides (messaging lockdown) made the line's
  insets hidden too, and growing the line stood the module down (the insets are read plain now). Scrolled
  up, the oldest messages leaving (a full log) no longer move what you read. The unseen button on the chat's
  name of a line at rest no longer takes clicks. Raid marks (`{skull}`) are their icons, as in the game's
  chat; a letterbox's (a cinematic's) messages are not shown. The game's channels are joined or left once
  chat's lockdown ends. A saved history keeps no Battle.net names nor line numbers, and one spoiled by hand
  (no time, a tie or class that is none) can still be drawn. Cheaper: a measured message's height is known
  without a guard; no closure per printed line; the speakers' caches count each by itself.
- 2026-10-15 — Fixed (seen in the game): a white copy of the last message measured stood in the window's upper left corner. The texts that measure (`ns.Ruler`) were hidden by their own alpha, which the game sets anew from the font object when the font changes; now they stand in a see-through frame of their own.
- 2026-10-15 — Fixed: a history saved before lines went by their event had loot, skill ups, joins and leaves among the addons' messages, so their ticks left them in the window; such a history is sorted anew when it is loaded (`Log.HISTORY`, `Guess`). A line with a channel's link that the game told nothing of is a channel's notice.
- 2026-10-15 — Fixed (seen in the game, in the saved history): loot, skill ups and channel joins went with the addons' messages, because this client's chat writes them without the number of their kind; now their event, told by the game's chat filters, says where they belong. The guild's message of the day is there once. The game's time in front of a line is taken off.
- 2026-10-15 — Fixed: a channel's message the game's chat writes with an event we do not read (a community's channel) goes with its channel, so its tick hides it; it went with the channels' joins and leaves. Every tick of the list is tested to hide its messages and only those.
- 2026-10-15 — *Save chat history* (the last 100 at first, up to 500); *Messages to show*: the system's, creatures', addons' messages and the channels' joins and leaves as switches (joins and leaves hidden at first); less room between the bubbles (3, was 8). Not yet tried in the game.
- 2026-10-15 — All bubbles alike, yours too: *Bubble background* (a solid color, or Marble, Rock, Slate, Iron, Night from the game's art) and *Bubble color* (the game's color picker) in the tab *Appearance*. Not yet tried in the game.
- 2026-10-15 — Every line the game's chat shows is in the window: the system's (also those without an event), pings, loot, money, experience, battlegrounds, channel notices, friends online, ... (`Log.Line`, a hook on every chat window); new kinds to show or hide. The line to write in is grey, as the bubbles. Not yet tried in the game.
- 2026-10-15 — Full screen: docked in a corner, only that very corner sets it off; nothing behind the window takes the mouse; the section *Expand window* at the top of the tab *Appearance*: *Can expand to fullscreen*, *Animation type* (moved here), *Background opacity* (half at first, was solid), *Background texture*. Not yet tried in the game.
- 2026-10-15 — Full screen: docked, the window fills the screen when the mouse is pushed against that screen edge, and goes back when pushed there again (Core's `Edge.lua`); *Animation type* in the tab *Appearance*. Not yet tried in the game.
- 2026-10-14 — The game's chat channels (As the game does, Always join, Always leave) are here now, on the page *Chat*; they were on the page *Profiles* (Sync module).
- 2026-10-14 — After a review: party and raid rings show again (`C_PartyInfo`); community channels by their names; the game's chat comes back during chat lockdown and stays complete (a minimised window's button; frames the game moved); the line at rest is made invisible instead of hidden by our code and given back as it was; one unreadable message no longer closes the window; failing safer (`Guarded`, `GiveBack`); cheaper: the oldest messages go in batches, a speaker is asked about once, the window rewraps once a sizing is over; the list of chats in `Menu.lua`.
- 2026-10-14 — Moved, sized and kept by Core's window code; docks to the screen's edges. Docking is not yet tried in the game.
- 2026-10-14 — Links in messages show their tooltip on the mouse and answer a click as in the game's chat.
- 2026-10-14 — Fixed: the bubbles' corners (seen in the game); a channel's tick in the list now counts by the channel's number. New setting *Show native chat*, on.
- 2026-10-14 — Chat names in short (a setting); ticks in the list for what the window shows.
- 2026-10-14 — A thinner ring; bubbles half see-through, with a setting for it; the line to write in drawn as your own bubbles.
- 2026-10-14 — Bubbles and the line to write in as plain round-cornered fills; a white ring for strangers; the line grows with its text; the button also opens the list of chats.
- 2026-10-14 — No background; handles and the chat button (now lower left) only with the mouse over the window; drawn above the action bars; cut rows hidden; round icons with rings for friend, guild, raid, party; names as large as the text; a text size setting.
- 2026-10-14 — The line only while you write, a button for it, no tooltip on the chat's name; newest message at the bottom; messages fade, with a switch and a slider.
- 2026-10-14 — The line to write in, the list of chats on its label, the game's own chat out of sight, printed lines as notes.
- 2026-10-14 — First prototype, with the look of a messenger.
