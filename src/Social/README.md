# SaneUI: Social

**Status:** a prototype · **Since:** 2026-10-14 · **Addon:** `SaneUI_Social` (was `SaneUI_Chat` until 2026-10-16)

## TL;DR
A chat window in the style of a messenger: every message in a bubble, yours at the right edge,
everybody else's at the left with name and class icon. In Blizzard's Edit Mode you move it and size it
by its lower right corner; the bubbles wrap to whatever width you give it. While it is open it stands in for
the game's chat: that one is out of sight, and you write in a line at the bottom of this window.

## How to use
- **Switch it on or off:** tick or untick *Social* under *SaneUI* in the game's addon list.
- **Move and size,** as the game's own frames: only in Blizzard's Edit Mode (Esc > Edit Mode). There the
  window shows Edit Mode's blue box, with *Social* on it while the mouse is on it: drag the box to move
  it, the grip in its lower right corner to size it. Smallest size 180 × 130. Place and size are kept.
  Outside Edit Mode it has no grip and stays where it is. A click on the box: its dialog has *Can expand to
  fullscreen*, *Hotcorner*, *Hotcorner requires leftclick* and a box for the key of its full screen
  (`SANEUI_SOCIAL_FULL`; Core's `Selection.lua`).
- **Dock:** in Edit Mode, let the window go near a corner of the screen or the middle of one of its edges, and it
  snaps there (a tinted shape shows where). It then
  stays at that edge at any size; the grip moves to a corner that is not at the screen's edge. Drag it
  away to free it, or to the screen's middle to dock it there. At first it is docked in the lower left
  corner (if another of SaneUI's windows is docked there, it stands beside it).
- **No title bar while small:** the small chat is see-through by design and has no title bar of Core's;
  it moves in Edit Mode only.
- **Full screen title bar:** filling the screen, the window has Core's title bar at its top: *Social* with a
  magnifier before it, the dropdown *Classic windows* and three buttons (the game's own chat: this window is
  put away, as *Chat* in *Classic windows* does; back to its small size; close, which puts it away too).
  **Search:** click *Social* (or the magnifier) and type: only the messages that have every word you type
  are shown, found as a quick finder finds them (the letters in their order, *gld* finds *Guild*), in the
  message, the speaker's name or the chat's name. Esc empties it and every message is back.
- **Full screen:** docked, left-click that screen edge (the game window's very edge, where the
  chat window touches it; with *Hotcorner requires leftclick* off, the mouse pushed there is enough; docked in a corner, all the way into that corner; with *Hotcorner* off, the edge does nothing and the key *Social's full screen (and back)* is the way in): the window springs open to fill the whole screen, above the game's bars, on a
  background that hides the game as much as set, every message there to read: while it stands full, none
  fades, wherever the mouse is. Nothing behind it takes the
  mouse: no click, no turn of the camera. On the way its corners start round, with a thin bronze trim, and
  flatten as it grows: full, it is square. Move the mouse away and push it against that edge again: it
  springs back to its size and place. The section *Expand window* (below) says whether it can, how it
  moves, its background and how round its corners start.
- **Copy messages:** on the full screen, press the mouse on the words of a bubble and drag over as many
  messages as you like, yours and everybody else's, in the chat, a chat view or a conversation (the
  mouse wheel scrolls on while you drag). What you picked is lit grey; press Ctrl+C (Cmd+C on a Mac) to copy
  it. From one message you get just the words picked; from several, each message on its own line after the
  name of whoever said it. The next click, Esc or any other key lets the words go. A click on a link or a
  name still does what it did.
- **Full screen windows and layouts:** standing full, the window holds more than the chat: windows that share
  the screen and never overlap, arranged as you like.
  - **Arrange them** on the full screen itself: drag the gap between two windows to share their room anew
    (the mouse shows the game's sizing cursor there); drag a window by its head onto another, near one of
    its sides to stand there beside it, in its middle to swap the two, or near a side of the screen for a
    strip along it (a gold shape shows where it would go); its X takes it off and the others take its room.
    The dropdown *Windows* in the title bar ticks the windows in the layout: tick one to add it, untick it to
    take it off.
  - **Layouts behind tabs** in the title bar, after *Social*: the first (*Default*) is the arrangement below,
    fitted to your screen until you change it; then it is kept as you left it. *+* makes an empty layout. A
    right click on a tab renames it, resets the first to the arrangement below, or deletes another. The
    layouts are the same on all your characters.
  - **At first** (the tab *Default*; Saneroki, 2026-11-18: "on the social full screen as default there should only
    be the conversation window 2/3rd of the fullscreen and one third of the window to the right is the friendslist
    window"): two windows side by side, each as high as the screen: the conversations on two thirds at the left,
    the friends list on the third at the right. On a smaller screen the friends list keeps its least width; where
    the two lack theirs, the friends list is left out. The guild window comes only when you put it there (the
    dropdown *Windows*, or the setup's tick: beside the friends list, sharing its room).
  - **Guild window** at the right: the very window the guild key opens, held in its window there and
    working as always: the game's own guild and communities window, or the window of another addon that
    answers the guild key instead. With the module Guild on, Guild's own guild window stands here instead (offered
    to this board through Core, `Core.Board.Offer`), and the game's is left alone. Its room is as large as the window is (it follows when the window is
    sized or made small); in a smaller room it is made smaller, never larger. The full screen opens it and
    closes it again when it goes; one open already stays open, back at its place. Closed while the full
    screen stands (its close button, Esc), the others take its room; opened again with the guild key, it is
    back. In a fight the game opens no window for an addon: one that closes in a fight comes back after it.
    Only while you are in a guild.
  - **Friends list** between the conversations and the guild window (the game's friends list's width at
    least), as the game's: online Battle.net friends, online characters, a divider,
    then the offline ones; each with the game's status icon (online, away, busy, offline), the name (a
    Battle.net friend with the character they play in brackets), where they are or what they play, and the
    icon of the game they are in. The head says how many are online. Click a friend to choose them, then
    *Send Message* (the line to write in opens with the whisper) or *Invite*; a right click opens the game's
    own menu of a friend; *Add Friend* opens the tab *Requests*, whose line adds a friend as the game's dialog
    does (a BattleTag, an e-mail address or a character's name; a friendly player you have targeted is in it
    already, by first name and surname). On the tab *Raid* a right click on a member opens a short menu of
    its own: *Whisper*, and as the game allows it you *Promote to Leader*, *Promote to Assistant*, *Demote*
    and *Remove*. The game's own raid menu is not opened there: opened by an addon, its *Set Focus* is refused.
  - **Group finder**, the last tab of the friends list (*Group Finder*), as the game's browse view: on its
    line under the tabs choose a *Category* (it is searched then), the
    refresh button searches again. A row for every group or player listed: the leader in their class colour
    (alone: their level and class icon), the activity and the comment, how many are in it. Choose one, then
    *Send Message* to its leader, or *Invite* a player who is alone. *List yourself* opens the game's own
    finder (its comment can only be typed there). Nothing is searched by itself: only a click of yours does.
    In a fight or a dungeon (chat lockdown) the game hides the listings from addons: the list stays as it was,
    its line says so, and it is read anew once that ends. WoW: Forever only: in Retail, whose group finder is its
    own (the dungeon finder and premade groups), the tab and its switch are not there.
  - **Conversations** at the left, all the room the right leaves: first the **chat** itself (unless the layout
    has it as a window of its own), then your **chat views**, then every whisper, and the chat of each group
    you join, each a conversation of its own, the newest message first. Every party or raid you join (and
    every instance group) starts a new one, as a whisper does, named by the others in it (*Party: Thrall,
    Jaina +2*; a party that becomes a raid stays one conversation); only that group's chat goes there. When
    you leave the group it stays in the list to read, and the line says you left it. They stand in two
    parts, not mixed (Saneroki, 2026-11-18): **Whispers** (characters and Battle.net friends), then **Groups**
    (party, raid, instance), each under a head with the game's − before its name (its quest log's): a click
    folds that part away (+), another shows it again, kept. Folded, its head counts the messages waiting in it
    and is lit as a row is; a search finds in a folded part all the same, and a conversation chosen by itself
    (your first whisper to somebody, a reply) shows its part again. The one
    chosen stands beside the list: the chat with its line to write in, as the window has it small; a chat
    view, the same bubbles but only the chats ticked for it, whatever the chat shows, every message in it to
    read; or a conversation. The chat's and a chat view's name line has *Chats*, the list of the chats each
    shows (the chat's are the same ticks as in the list on its line's name). **New chat view** (above
    *Whisper*) makes one more, as many as you like, showing nothing until you tick its chats: one for a
    channel (Trade, a channel of your own), one for your guild and officers, any mix. A right click on a chat
    view renames or removes it, or puts it on the screen as a chat window of its own (*Its own window on the
    screen*, below). Each chat view is a window for the layouts too (the dropdown *Windows*), with
    its own *Chats* on its head; the first, the **second chat**, shows your whispers, party, raid, instance,
    guild and officer chat at first. A row with messages you have not seen yet is lit with the game's own
    new-message glow of its chat tabs, in that chat's colour, and counts them: a conversation's waiting to be
    read, a chat view's or the chat's that came while it was out of sight. A conversation's row shows the class icon (a Battle.net
    friend: the game's Battle.net portrait; a group: the game's conversation icon), the name (your alias for
    them), the last message, its time and how many messages wait to be read; the panel's title counts them
    all. Click one to read it: its messages in the chat's bubbles, a pill for each day, the name and your note
    about them above. Write in the line under them and press Enter: it goes to that conversation (a line
    starting with `/` goes to the game's line, where Enter runs it). Enter while a conversation is chosen puts
    the cursor into its line; a reply (or *Whisper* on a name) to somebody with a conversation chooses
    theirs; anything else the game's line opens with (`/`, a whisper to somebody new) chooses the chat, whose
    line it is. A right click on a whisper opens the
    game's menu of that player, with *Add Friend*, *Pin them on the map*, *Show on map* and *Delete conversation*
    under it; on a group's conversation, its name and *Delete conversation* (asked first; Saneroki, 2026-11-18:
    "rightclick on whispers and group windows to say Delete the conversation"). *Whisper* opens the game's line with `/w` to name whom; your first message
    chooses the new conversation. *Remove* takes the one chosen away (a conversation with its messages, or a
    chat view), once confirmed. A
    group you are in is listed though nobody spoke yet. Each keeps its last messages (a setting), for each
    character, also over a logout (then 1,000 of them all together at most, the newest conversations' first).
    Drag the line between the list and the one chosen to make the list
    wider or narrower (the mouse shows the game's sizing cursor on it); let go, the one chosen takes the rest,
    and the width is kept.
  - A layout without the conversations has no chat in it (the line to write in still opens, at the screen's
    bottom). On a narrow screen the first layout leaves the friends list out. The search in the
    title bar finds in all of them: messages (in the chat and the chat views), friends (name, where, note),
    groups (leader, activity, comment) and conversations (by name or by their messages). Going back, the
    panels go at once, the guild window with them, and the chat has the whole window.
- **Classic windows:** full, the dropdown *Classic windows* in the top right corner offers the game's own
  windows instead, each a tick, ticked while the game's own is the one (Saneroki, 2026-11-18: "Make sure you can
  check all of them"; untick it for ours again): *Chat* puts this window away (the switch *Chat window* goes off) and the game's chat is
  back; its button *SaneUI* (the game's square button with circling arrows, just above its chat menu
  button, left of the game's chat), `/sane social` or the switch brings this one again. *Friends list*: the window goes back to its
  place and the game's friends list opens (in a fight the game refuses that to an addon: a line says to use the
  game's own key), and its keys are the game's again. *Group finder*: the same for the game's group finder (in Retail its own).
- **The friends list's and the group finder's keys open ours:** the game's keys for its friends list (*Toggle Social*,
  *Toggle Friends Tab*, O at first) and its group finder (*Toggle Group Finder*) open this full screen with the
  friends list at that tab; pressed again, back to its size. Until their tick in *Classic windows* says the game's
  own; not while *Can expand to fullscreen* is off or Edit Mode is open; the group finder's only in WoW: Forever.
  Their own keys are in the game's key bindings under SaneUI too. The game's friends
  list (or its newer social window, where the game has that on) and group finder have the button *SaneUI* beside
  their close button: it closes the game's window and this one fills the screen. The dropdown lists the other modules' game windows too, each under its module's name.
- **Scroll:** mouse wheel, or the bar at the right, which is only there while you are scrolled up from
  the newest message. At the newest message the window follows new ones; scrolled up to read, it stays
  where you are.
- **No background, no border, clicks go through:** the messages stand over the game, and a click on them
  is a click into the game. Only a link, a speaker's name and the chat button take the mouse. The chat
  button is only there while the mouse is over the window; the window has no bar of its own.
- **Click a speaker's name** to whisper to them, right click it for their menu, as in the game's chat; on the full
  screen a right click anywhere on someone's message does the same. Under the game's lines Social adds *Add Friend*
  (not for a friend already), *Pin them on the map* (the map pin at their place, with its golden line: a member of
  your group whose place the game tells) and *Show on map* (the full map searching for them: in your group, a guild
  member's SaneUI that says where it stands, else their zone; while the map is SaneUI's). The game's own lines are
  *Whisper*, *Invite*, *Ignore*, *Report*, *Copy Character Name* and the like (Saneroki, 2026-11-18: "invite, whisper,
  set alias, set note, Ignore, copy character name, pin, show on map, add wow friend, report player").
  Its *Set Alias* (Core's) gives the character a name of your own: their messages, and the friends list,
  show it in place of theirs (a click still whispers to the character), and the search finds it.
- **More chat windows on the screen** (Saneroki, 2026-11-18: "the option to have more then one chat window on the
  screen if people want that"): the list behind the chat button (or the chat's name in the line) has a last column,
  *Chat windows*: a tick for each chat view (the second chat first: your whispers, groups and guild) puts it on the
  screen as a chat window of its own beside the chat; *New Window* makes one more and opens its list, to tick what it
  shows. The same as a chat view's right click on the full screen. Each looks and fades as the chat does: no
  background, a click goes through but on a link or a name, the newest at the bottom, the wheel brings every message
  back, the settings of *Animations*. Moved, sized and docked in Edit Mode, its name on its box there, its place kept
  per profile. The mouse over it shows its name at its top and its button at its lower left: a click there opens its
  list, *Rename Window*, *Close Window* (off the screen; the chat view stays, on the full screen) and the chats it
  shows. Showing nothing, its name, its button and what to do stand there, so it is never lost unseen. You write in
  the chat's line (Enter). While the chat fills the screen they are out of sight (the views are on the full screen),
  and while the chat is put away.
- **Write:** press Enter or `/` as always, or click the chat button in the window's lower left corner
  (there with the mouse over the window, as high as the line to write in, which opens right of it).
  The line to write in opens at the bottom of the window and the messages move up above it. It is the
  game's own line: slash commands, `/w`, `/r`, the history (Alt + arrow up) and name completion work as
  before. Esc, or the button again, closes it. The line is only there while you write.
- **Icons and emotes:** the smiley at the right end of the line to write in opens a list. At its top the
  game's eight raid marks (star to skull): a click puts one into the line where the cursor is, and once
  sent it shows as its icon in everybody's chat. These are the only icons the game's chat draws from what
  a player writes; it shows none in its public channels (General, Trade, ...), so while you write in one
  the list says so instead (on an empty line too: a click on the smiley is the line's, so the line stays open;
  Saneroki, 2026-11-18: "While the input field is empty clicking the smiley will close the input"). Under them emotes played most (`/hello`, `/wave`, `/bye`, `/thank`,
  `/welcome`, `/cheer`, `/applaud`, `/congratulate`, `/laugh`, `/dance`, `/bow`, `/hug`): a click does it
  at once, at your target if you have one, as typing it would. While chat is locked down (a fight, a
  dungeon) the list offers no emotes and says so: the game refuses them to an addon then.
- **The newest message is at the bottom.** A few messages stand at the bottom of the window, not at its top.
- **Your messages** stand on the right, or on the left with your class icon and name as everybody else's (*Your
  messages*, tab *Appearance*, and the setup; Saneroki, 2026-11-18).
- **Messages fade out,** each by itself, 10 seconds after it came (*Fade messages after*). Neither the mouse over the window nor
  the line to write in brings them back: turn the mouse wheel over it and all of them fade back in to
  read. They fade out again once the mouse has left at the newest message (scrolled up, they stay). On
  the full screen every message stays.
- **A note shows its time:** a line of the game or of an addon, in the middle of the chat, has the time
  it came in grey inside its bubble, right of its text (`Bubble.Init`, `clock`). Its text wraps as
  before, and a day's pill in a conversation has no time.
- **Nothing jumps:** a new message fades in quickly, and the others slide up to make room for it; they
  slide for the line to write in too, and the mouse wheel scrolls smoothly.
- **A message cut by the window's top edge is not shown** until it fits whole.
- **The ring around a class icon** says what the speaker is to you: yellow a friend, green a guild
  member, purple somebody of your raid, blue of your party (the first that holds). White: a stranger.
- **Set up step by step** (Saneroki, 2026-11-18): the button at the top of the options page, or `/sane setup social`
  (`/sane setup chat`), and by itself once after the login with the other setups (the addon Onboarding's window): what
  the chat is; the hot corner, one choice of three: *Not at all: only by a key*, *With a left click in it*, *When the
  mouse goes into it*, the tutorial arrow pointing into the corner the chat is docked in; the keys (*Social's full
  screen*, *The chat window*) on the same page (Saneroki, 2026-11-18); the windows (*Chat window*, *Show the game's chat
  too*, *The second chat on the screen*, *Group finder*); your messages (*Your messages* on the right or the left, *Fade
  out* and *Fade messages after*, *Bubble opacity*; that the mouse wheel scrolls back to older ones); what is kept
  (*Save chat history* and *Messages kept*, *Messages kept per conversation*, *A new conversation for each group*); the full screen (the conversations' parts, chat views, and ticks for *The friends list on the full
  screen* and *The guild window on the full screen*, in or out of the layout chosen, as the dropdown *Windows* there
  puts them; Saneroki, 2026-11-18: "Add the friends list and guild window to the setup too").
- **Settings** (Esc > Options > AddOns > SaneUI > Social), in two tabs:
  - *General:* *Chat window*: *Chat window* (on: the window itself), *Show the game's chat too* (off), *Save chat history* (on) with *Messages kept* (slider
    0 to 500, at first 100). *Messages to show*: *System messages*, *Creature messages*, *Addon messages*
    (on), *Channel joins and leaves* (off: somebody joined or left a channel, also the hidden channels addons
    use). The same four ticks are in the list on the chat's name. *Full screen*: *Messages kept per
    conversation* (20 to 500, at first 100), *Group finder* (on: its tab in the friends list). Which windows
    stand on the full screen, and where, is arranged there (its layouts); the chat views and their ticks are
    made there too (kept the same on all your characters).
  - *Appearance:* *Expand window* (Core's, the same for every window that can fill the screen):

    | Line | At first |
    | --- | --- |
    | [x] Can expand to fullscreen (off: the screen edge does nothing; all below greyed out) | on |
    | [x] Hotcorner (off: the screen edge does nothing; the full screen opens by its key) | on |
    | [x] Hotcorner requires leftclick (off: the mouse pushed there is enough; greyed out with Hotcorner off) | on |
    | Animation type: Use global type (SaneUI > Appearance), Glide, Swing, Even, Instant | Use global type |
    | Background opacity, slider 0 to 100 % (100: the game is hidden) | 50 % |
    | Background texture: Solid black, or one of the game's own, as for the bubbles: Marble, Rock, Slate, Iron, Night | Solid black |
    | Corner radius, slider 0 to 100 % of half the window's shorter side at its size (100: a square window is a circle); full, it is square | 10 % |
    | [x] Don't round corners on screen edges (off: every corner is round, also those on the screen's edges, until it is full) | on |

    *Messages*: *Text size* (10 to 24, at first 14), *Bubble opacity* (100 % solid to 0 % text
    only, at first 50 %), *Bubble background* (*Solid colour*, or one of the game's own textures: *Marble*,
    *Rock*, *Slate*, *Iron*, *Night*; at first solid), *Bubble colour* (a swatch that opens the game's colour
    picker, at first a dark grey `26262B`; greyed out while a texture is chosen), *Short names* (off). *Animations*:

    | Line | At first |
    | --- | --- |
    | [x] All animations and fades (off: nothing fades, slides or springs, every message stays, the window fills the screen at once; all below greyed out) | on |
    | [x] Fade in, slider *Fade-in time* 0 to 2 seconds | on, 0.50 seconds |
    | [x] Fade out, slider *Fade-out time* 0 to 2 seconds (off: every message stays) | on, 1.00 seconds |
    | Fade messages after, slider 5 to 300 seconds | 10 seconds |
    | [ ] Opacity, slider 5 to 95 %: how visible a faded message stays | off, 30 % |
    | [x] Slide up, slider *Slide time* 0 to 2 seconds | on, 0.50 seconds |

    A speed is the time a whole fade (out of sight to all there, or back) or a slide takes. A line under one
    that is off is greyed out.
- **The game's chat channels, the same on every character:** in the last column of the list on the chat's name,
  under *Joined on every character*, each of the game's channels (as the game names them, in its language: those you
  are in, those on offer where you are, and any you chose for) has a tick, on while you are in it. Tick one and you
  join it, wherever the game offers it (a city's channels only in a city); untick it and you leave it, and it is left
  again whenever the game puts you in it. It acts a while after a character comes into the world, when the game
  changes its channels, and at once when you click. The game may refuse to let you leave one (Retail's Newcomer Chat,
  for one): it says so in a line of its own, the tick comes back on, and SaneUI does not ask again until the next
  login or your next click on that tick.
  It works whether the window is open or not, and on every character (the settings of *Social* are account
  wide unless unticked in *Profiles > Game settings*).
- **You start in no public channel.** On a character's first load SaneUI takes it out of every channel of the game
  (General, Trade, Local Defense, Services, Looking For Group, Newcomer Chat, ...): each is left the first time the
  character is seen in it, so also a city's when it first comes to one. That happens once per channel and character,
  on every profile. Join one when you want it, with `/join Trade` or with its tick above: it stays, on that
  login and any other. A channel you made yourself is not touched.
- **Retail's Newcomer Chat is left every time the game lets go of a character.** The game puts a character in it by
  itself, so *Accountwide* and *Speedleveling* hold it unticked, on every character, old ones too. To stay in it, tick it.
- **Not shown at first** in the list of what to show: *Loot, money and experience*, and General, Trade (Forever's Trade
  (Local) too), Local Defense, Services and Newcomer Chat, also after you join one: tick it there to read it. A tick belongs to the
  channel, whatever number the game gives it.
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
  the same list. Each part of it has its own column: where you write, what the window shows, the game's channels.
  It stays open while you choose and when the mouse leaves the window; a click outside it, or on the button it
  came from, closes it.
- **Links in messages** (an item, a spell, a quest, an achievement): the mouse over one shows its
  tooltip; a click does what it does in the game's chat (the item's window, Shift+click puts the link
  into the line you write in, a player's link opens the player's menu), but only where that opens none of
  the game's panels: a click with the dressing room's key (Ctrl), on a calendar event and the like does
  nothing here (a panel of the game's opened by SaneUI's code can break the game's own panels until a
  `/reload`).
- **Short chat names:** above a message the chat is named by the first letter of each word of its
  name: G for Guild, P for Party, R for Raid, RW for Raid Warning, S for Say, T for a trade channel,
  G for General. Guild and General share the G; their colours differ. A setting, on at first.
- **Choose what the window shows:** the same list (the chat button, or a click on the chat's name in
  the line) has, beside the chats to write in, a tick for every kind of chat (say, yell, emote,
  whisper, party, raid, instance, guild, officer, creatures, system, addons and the game's notes) and
  for every channel you are in. Untick one and its messages leave the window; tick it and they are
  back, the earlier ones too. Kept between sessions.
- **Choose the chat to write in:** the line starts with the chat's name (*Say:*, *Guild:*). Click it
  for the list of chats you can write in right now (say, yell, party, raid, instance, guild, officer,
  the channels you joined) and pick one. It stays chosen until you pick or type another (`/g`, `/2`).
  A whisper is not in the list: it needs a name (`/w name`, `/r`).
- **The game's own chat is out of sight while this window is open** (its windows, tabs and buttons). The setting
  *Show the game's chat too* keeps it on show next to this window.
  `/sane social` (or `/sane chat`, its word from before) switches between the two: our window, or the game's chat as it was. So does a key
  of your choice (Esc > Options > Keybindings, section *SaneUI*: *Show or hide the chat window*); another there,
  *Social's full screen (and back)*, fills the screen and brings it back (the chat window first, if it was put away),
  as the hot corner does. The game's chat goes
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

  The list of what to show has them as *Pings*, *Loot, money and experience* (hidden at first), *Battlegrounds*, *Pet
  battles*, *Channel joins and leaves* (all channels' notices, hidden at first), *System* (with Battle.net
  notices) and *Addons and the game's notes*. The combat log is not shown.

  The text has the colour the game gives that kind of chat (guild green, whisper pink, ...).
- **If something goes wrong** the module closes its window, gives the game's chat back and says so
  once there, until the next `/reload`. `/sane errors` shows what it was. A single message that cannot
  be read is left out (and noted once); the window goes on. Should no chat be left to type in at all,
  the game menu (Esc) has the button *AddOns*: untick *Social* under *SaneUI* there.

## Technical details
- **The way of a message:** game event → `Log.Read` (what it says) → `Log.Add` (the list) → `Log.added`
  → `Window` (shows it, if the window is open). `Log.Read` touches nothing: an error in it leaves that
  one message out and is noted (`ns.Report`); an error after it stands the module down.
- **Log** (`Log.lua`) knows no frames. A message is a plain table (`side`, `text`, `name`, `class`,
  `label`, `r g b`, `time`). At most 200 are kept (`Log.MAX`, more for a longer history), and with *Save
  chat history* on the last of them come back after a `/reload` or the next login (*The history*, below).
  The oldest go 25 at a time (`Log.PRUNE`, marked `gone`), so the window's list drops them in
  one update (`RemoveIndexRange`) instead of one per message. Which events are read, and on which side
  they land, is the table `Log.EVENTS`.
- **Discord:** with a guild linked to a Discord channel, its messages come in the guild's chat or in a
  Discord stream of its own (`CHAT_MSG_GUILD_DISCORD`, read too, shown with the guild); the event's 18th value
  (`discordInfo`) tells one written on Discord. Such a message is always on the left, even one its writer
  wrote as the character playing: under their Discord name where they chose that, else the character they
  last played, with its class (as `ChatFrameUtil.GetDecoratedSenderName`), with the game's words for an
  attachment, a poll or a sticker in front (`ChatFrameUtil.FormatDiscordMessage`; a picture alone has only
  those). It has no link: a click would whisper a character of that name, and the game's own link to a
  Discord writer carries their Discord ID, which the saved history does not keep (board #327).
- **Forever and Retail:** one code for both. What differs is asked for where it is used: the group finder
  (`ns.RetailFinder`, Retail's `PVEFrame`: the tab *Group Finder* and its switch stand down there, the switch's
  `hidden`), blocking invites (`Contacts.Blocker`: `C_BattleNet.SetBlocked` or Retail's `BNSetBlocked`), extending a
  raid lock (Forever asks `C_RaidLocks`, Retail always can), the kinds of Recent Allies' filter (none where the game has
  no `Enum.RecentAlliesInteractionCategoryFilter`), names (Forever's first name and surname, Retail's name and realm:
  `Core.Surnames`). The chat, its edit boxes and events, Battle.net, the friends list's other tabs and the guild window
  are the same in both.
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
  after a turn of the wheel), and none fades while it stands full (`FadeAfter` asks `edge.full`): the mouse on
  a panel or on the guild window, which is not ours, ends the reveal but fades nothing. On the way back
  (`Filled(false)`) the messages are told anew (`Refade`). Its kind of motion is `options.motion`; `off` while all animations are off.
  The list stands in what Core lays out for what a window holds (`window.inside`): the whole window while it
  is small (it has no bar of its own), under Core's title bar while it is full (`Top`: `handle.top`;
  `Layout.ListHeight`'s `top`). The title bar's search goes to
  `Window.Search`: `Core.Fuzzy.Query`, and `Visible` keeps a message only if `Core.Fuzzy.Match` finds every
  word in its readable text (colours, links' codes and icons taken out: `Core.Fuzzy.Plain`, made once per
  message and kept on it: `Log.Readable`, `plain`), its `name` or its `label`. The chat views and the
  conversations find by it too, thousands of messages with all conversations full (`Talks.MOST` × *Messages kept
  per conversation*): the lists are filtered anew 0.15 s after a key (`Core.Later`), once for the keys typed
  meanwhile, not at every key.
  The title bar holds Core's dropdown *Classic windows*, whose list is `ns.CLASSIC` (`Social.lua`), each a kept choice
  (`checked`, `back`): *Chat* (`Choose(false)`, a line in chat says how to bring the window back; ticked while
  `window` is off), *Friends list* (`friendsKey` off, then `ToggleFriendsFrame(FRIEND_TAB_FRIENDS)`,
  as the game's key opens it, only if neither `FriendsFrame` nor `SocialUIFrame` is shown; nothing if the game has no
  such function), *Group finder* (`finderKey` off, then `ns.OpenFinder`: Forever's `ToggleGroupFinderFrame`, Retail's
  `PVEFrame_ToggleFrame`; its button on `LFGParentFrame` or `PVEFrame`). The keys (`Keys.lua`): override bindings of
  `SANEUI_SOCIAL_FRIENDS` and `SANEUI_SOCIAL_FINDER` (`Bindings.xml`) on the keys of `TOGGLESOCIAL`, `TOGGLEFRIENDSTAB` and
  `TOGGLEGROUPFINDER` while `Keys.Taken` (the switch, the module, `expand`, Edit Mode closed; the finder's not where
  `ns.RetailFinder` or with `boardFinder` off), out of a fight; `Keys.Press(tab)`: `Window.Standing`, `Board.Put`,
  `Friends.Want` (the tab once the panel is made). The player menu (`PlayerMenu.lua`): `Open(owner, who, what)` builds
  the context the game's `FriendsFrame_ShowDropdown` and `FriendsFrame_ShowBNDropdown` build (name, `lineID`,
  `chatType`, `chatTarget`, `chatFrame` the game's `DEFAULT_CHAT_FRAME`, `bnetIDAccount`, `battleTag`), with
  `ownerFrame` the part of ours clicked on, and opens it by `UnitPopup_OpenMenu` (`FRIEND` or `BN_FRIEND`): Forever's
  versions of those make the chat frame the owner, and the game's menu manager closes a menu at once whose owner is
  out of sight (`ownerRegion:IsVisible()`), as the game's chat is under ours (`Native.lua`). `PlayerMenu.With(what,
  fn, ...)` opens it with `asked` set, and `Menu.ModifyMenu` on `MENU_UNIT_FRIEND`, `_OFFLINE`, `BN_FRIEND`, `_OFFLINE`
  adds Social's lines only then (and to that menu made anew: a weak table by its context). `PlayerMenu.Who(link)`
  reads a player's link (`player:`, `BNplayer:`, not your own account's); `PlayerMenu.Link(owner, link)` from
  `Links.lua` (a plain right click on a player link, the frame with the link its owner), `PlayerMenu.Message(box,
  entry)` from `Select.lua` (on the full screen, `Let` with the right button: the message under the mouse, its link)
  and `PlayerMenu.Talk(row, ...)` from `Conversations.lua`. *Pin them on
  the map*: the game's user waypoint (`C_Map.SetUserWaypoint`, `C_SuperTrack`), only for a member of your group whose
  place `C_Map.GetPlayerMapPosition` tells; *Show on map*: `Core.Ways.Look(name)`, served by Navigation's map search. The
  section *Expand window* is Core's (`Edge.Options`, with its corner switches, `Shape.Options`), put at the
  top of the tab, before the first switch of the tab *Appearance*, its *Animation type* also under *All
  animations and fades* (`Edge.Options`' `under`); the window reads it by `edge = ns.options`, and Core
  itself follows a change of one of its switches (`edge:Update`).
- **Ours or the game's chat, one switch:** the setting *Chat window* (`options.window`) is the one place it
  is kept. Every way to change it sets it (`Choose`, `Core.Set`: an open options page follows): the button
  for the game's own window in the full window's title bar, its close button, *Chat* in *Classic windows*,
  the button *SaneUI* on the game's chat, `/sane social`, the key (`Bindings.xml`: `ns.Toggle`). Its change
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
  The chat's frame stands as high as the panels of Core's board (`Board.LEVEL` above what the window holds), so
  on the full screen the messages lie on their panel's see-through plate, not under it, and the line to write in
  stands over them (`Layout.INPUT_LEVEL`).
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
  the name into the line. A creature's name (`MONSTER_*`, `RAID_BOSS_*`) is no link, and nothing is asked
  about it, as in the game's chat.
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
  nothing); a click is the game's own `SetItemRef`, with the main chat window as the chat frame (`ns.Safe`:
  one the game fails on is noted, the window stays), but only for the kinds whose handling opens none of the
  game's panels (`CLICKED`: players, items, spells, quests, achievements, channels, ...), with no key held or the
  one that puts a link into the line (`CHATLINK`; not on a channel's link, where it opens the game's list of
  channels): a panel shown by our code runs the game's panel manager tainted (Doc/guides/addon-standards.md,
  section 5; the dressing room of a Ctrl+click is one). In a fight a plain click on a kind the game answers with
  its link tooltip (an item, a spell, a quest, ...) does nothing: the game refuses that window to our code then
  ("Interface action failed"), and the tooltip on the mouse shows the link already.
- **Short names** (`Channels.Brief`): the first letter (UTF-8) of each word of the chat's name, the
  game's own word or the channel's name before its " - " (`Channels.Base`); made once per name and
  kept, chosen when a message is drawn. Not for *To Thrall*.
- **A channel's name** is the one the game shows (`Channels.Name`, the game's
  `ChatFrameUtil.ResolveChannelName`): a community's channel is called `Community:<club>:<stream>`
  inside and shows as the community's name.
- **What is shown** (`Log.GROUPS`, `Channels.Shown(group)`): a message carries a group (`"GUILD"`,
  `"CHANNEL:Trade"`, `"PRINT"`; a channel by its own word, `Channels.Group`: the game's shortcut,
  `C_ChatInfo.GetChannelShortcut`, by which its chat windows know it too, else its name; not by its number, which
  moves as channels are joined and left, nor its full name, which has the zone in it). `Log.GROUPS` is the one
  list of them, in the order the list of what to show offers them, each with the kinds of chat that
  belong to it (a leader's and a warning's lines belong to their chat, Battle.net whispers to
  whispers). The switched-off groups are kept in the setting `mute`, but for the four with a
  setting of their own (`ns.SHOWS`: `SYSTEM`, `MONSTER`, `PRINT`, `CHANNEL_NOTICES`): their tick in the list and
  the switch in the settings are the same value (`Channels.Shown`, `Channels.Flip`, by `Core.Set`). `mute` is not empty
  at first: `REWARDS` and the channels `General`, `Trade`, `TradeLocal` (Forever's Trade (Local)), `LocalDefense` and
  `Services` (shown as Trade (Services)). It is the module's default, so both standard profiles and Character specific
  have it, and it is kept whole: what you tick stays ticked. The game's chat windows keep their kinds of chat: they
  write the lines the log reads (`Log.Line`), and the list decides what the window shows. So Sync, which keeps those
  windows, has nothing to bring back. The log keeps every
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
  label (`hooksecurefunc` on its `UpdateHeader`, which also sets the text's insets anew). The box is
  only as tall as its text (`OneLine`): the room above and below the text is the plate's, the box's
  hit rectangle reaches over it, and the box keeps the game's insets. The game's own blinking cursor
  does not show in the line, so a bar of ours stands where it would (`Core.Caret`). The label
  hangs on the box's top so it stays on the first line. A line break in the text (pasted) becomes a
  space when the message is sent (`ChatFrame.OnEditBoxPreSendText`). The window is told of a new
  height and the box is given it (`Give`) only when a line comes or goes, not with every key. All of it is undone when our window goes (`Release`: each edit
  box by itself, its anchors first).
- **The button** (`Input.Toggle`) calls what the keys call: `ChatFrameUtil.OpenChat(nil)`
  (Enter) or the edit box's `ClearChat` (Esc). Its art is the game's chat button
  (`Interface\ChatFrame\UI-ChatIcon-Chat-Up` / `-Down`).
- **The smiley** (`Picker.lua`) is a child of the window at its lower right, left of the grip
  (`Layout.GRIP_ROOM`, `Layout.FACE`; the line ends before it, `Layout.INPUT_RIGHT`), on the first line's
  height, shown by `Input` whenever the line is dressed and hidden when it rests, closes or is given back. It takes
  only the mouse's coming (`SetMouseMotionEnabled`, not `SetMouseClickEnabled`): its light and tooltip, `hovered`.
  The line's hit rectangle reaches over it (`Input` `Dress`: right inset `-(INPUT_RIGHT - GRIP_ROOM)`), so a press
  there is the line's, which keeps its cursor (a press elsewhere takes it, and the game puts an empty line to rest,
  `ShouldDeactivateChatOnEditFocusLost`); the line's `OnMouseUp` (hooked once per line, `Picker.Show`) over the
  smiley opens the list (`Picker.Open`). A client without those two ways clicks the smiley itself (`OnClick`).
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
  the game's emotes (`EMOTE<n>_TOKEN`, up to `MAXEMOTEINDEX`). None while chat is locked down
  (`C_ChatInfo.InChatMessagingLockdown`; `PerformEmote` has restrictions): one line says so instead. The art is
  our own (the game has no smiley); missing, the button falls back to the game's chat button art.
- **Newest at the bottom** (`Window` `Settle`): the scrolling list starts at its top, so the view gets
  a top padding of whatever the messages leave free (list height minus their heights), none once they
  fill it. Set anew for a message, a new size and the line to write in.
- **Picking words to copy** (`Select.lua`): the chat's list (only while the window stands full: `Select.Allow`
  from `Filled`; at its size it takes no click), every chat view's list and a conversation's take the mouse
  (`Select.Attach`: `HookScript` `OnMouseDown`/`OnMouseUp` on the scrolling list, a frame of its own runs
  `OnUpdate` while the mouse holds). The letter under the mouse is the game's text's own answer
  (`FindCharacterIndexAtCoordinate`, the cursor over the list's effective scale, as the game's
  `ScrollingMessageFrame` asks it; beside a bubble the nearest line by height), a caret into the text with its
  codes. What is picked is two ends, `{ message, caret }`, and each message's place in its list when the press
  came (`pick.at`, a copy of the list's order): `Select.Span(entry)` says what of a message is picked, and
  `Bubble.Init` lights it on every draw (`Bubble.Mark`: textures from `CalculateScreenAreaFromCharacterSpan`, a
  piece per line, on the bubble's `BACKGROUND` sublevel 1 between its fill and its text, the game's grey
  `Layout.PICKED`, 0.37), so the list's rows, handed from message to message by a scroll, stay right. Days'
  pills (`pill`) are skipped. The words (`Select.Words`): the span's letters without `|c` colours, `|r`,
  a link's `|H…|h` part, `|T`/`|A` icons and `|K` names; `||` reads as a bar, `|n` as a new line; a caret
  inside a UTF-8 letter takes the whole letter. Several messages: one line each, after `Bubble.Speaker` (or
  `Core.FullName("player")` for yours). The game's `CopyToClipboard` is for its secure code only, so the
  words wait in an `EditBox` of ours (`UIParent`'s, alpha 0, multi-line, no letter limit), highlighted
  (`HighlightText`) and focused: the edit box copies on Ctrl+C itself, and a frame later (`Core.Later`) the
  keyboard is let go (the words stay lit). Any other key (`OnKeyDown`, modifiers alone aside), Esc, focus taken
  elsewhere (`OnEditFocusLost`), the next press, another row of the conversations chosen (`Window.Pick`,
  `Choose`) or the full screen going (`Board.Hide`) drops it. Every step runs in `ns.Safe("selection", …)`:
  one that fails is noted and the chat goes on.
- **Fading** (`Fade.lua`, no frames): a message's fade is its own, kept on the message (`from`, `to`,
  `since`, `span`), never on a row: the list hands its rows from one message to another whenever it
  lays them out, and a fade kept on a row was cut off or begun anew by a new message, a scroll or a
  slide. `Fade.Alpha(entry, now)` follows from those four alone (eased on the game's curve `InOutQuadratic`,
  `Fade.CURVE`, through `Core.Motion.Ease`: slow at both ends); a fade that
  turns back starts from where it is and takes only the time for the rest of the way. In 0.5 s
  (`Layout.APPEAR`), out 1 s (`Layout.FADE`). A new message enters from nothing (`Fade.Enter`).
- **Painting** (`Window` `Paint`): every row shows its message's alpha, when it is drawn (`DrawRow`)
  and every frame while one in view fades (`OnUpdate` on the window, removed once none does). No
  animation groups for fading.
- **When** (`Window` `Refade`): every message is told where to go: in if fading is off, the list is
  revealed or the window is full, otherwise in until `entry.at + fadeAfter`. One timer (`C_Timer.After`, a counter
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
  0.5 s at first, smoothed, up by it). A slide still going on adds what it had left (`GetSmoothProgress`). The list clips its children,
  so a new row slides in from its bottom edge, fading in on its way (0.5 s, so most of it is seen). Wheel scrolling is the list's own interpolation
  (`SetInterpolateScroll` on list and scroll bar). The slide moves the list's content and touches no
  alpha; the fades touch no position: neither knows the other.
- **The list of chats** (`Channels.lua`, no frames) is built when the label is clicked: `IsInGroup`,
  `IsInRaid`, `IsInGuild`, `C_GuildInfo.IsGuildOfficer`, `GetChannelList`. The menu (`Menu.lua`) is the
  game's (`MenuUtil.CreateContextMenu`, radio lines) in its grid (`SetGridMode`): the grid runs down each column and
  on at the top of the next, all equally long, so the shorter ones are filled up with spacers. It stays open: its
  owner is the window, not the button clicked (the game closes a menu whose owner goes, and the chat button goes
  with the mouse), its radio lines answer `MenuResponse.Refresh`, and the two buttons that open it say a press on
  them is theirs (`HandlesGlobalMouseEvent`, as the game's dropdown buttons), so `Menu.Toggle` can close it. A
  channel joined or left shows or goes in the first two columns the next time the list opens. A choice calls the edit box's own `SetChatType`,
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
  does not close the window. In the menu each channel is a check box (`Join.In`, `Join.Flip`, `Menu.lua`): a wish
  counts at once, never ticked it is what the game says, and every notice of the game shows an open list's ticks as
  they are (`Menu.Refresh`). `Settle` goes through every wish at each click, and the game writes a line of its own at
  each leave it refuses, so `CHAT_MSG_CHANNEL_LEAVE_PREVENTED` notes the channel for this login (`kept`).
- **Out of the public channels, once** (`Join.lua`, `char.public`): a wish that never leaves again would throw out a
  channel you join yourself, so this is no wish but a note per character (`Core.Character`), `[a channel's word in lower
  case] = true`, made only at a first load: when no row is saved for the character yet (`Join.Notes`, which is why it asks
  before `Core.Character` makes one). A second character on the same profile therefore starts empty and leaves its own
  channels, and a `/reload` finds the notes it saved. A character saved before has no notes and leaves nothing. At each
  look after the first (`LeaveOnce`, so the game has joined its own, and only then), every channel the character is in
  whose kind is the game's is noted, and left unless it carries a wish: *always in it* stays, *never in it* is the wish's
  own. That is by kind, not by a list of names: the game's table has channels of one game only (Forever's Trade (Local),
  HardcoreDeaths), by zone (Local Defense), by city (Trade, Services), for newcomers (Newcomer Chat, Chromie Time) or
  never joined by itself (Looking For Group). One the game lists as switched off (third value of `GetChannelList`) waits:
  a leave may not hold there, and the game turns it on with a notice. Left once is enough: the game remembers per
  character what it left. A join someone asks for is told apart from the game's own by where it runs: everything of the
  game's that joins for a person (`/join`, its channels window, its dialogs) calls `JoinPermanentChannel`, and nothing of
  its interface calls that by itself, while its own joins come from the server. So those three functions are hooked
  (`JOINS`) and the name is noted, also for a channel never seen yet, in the word it was asked by; `Noted` looks a channel
  up by all three of its words (`Services`, `Trade (Services)`, the full name). The hook has Core's guard, not the
  module's: the channels go on when the window has stood down, and a join missed then would be left after the next load.
- **Sync and these channels** (`Core/Sync/Chat.lua`): a public channel is never one of your own (`ownChannels` goes by the
  same kind), so no character rejoins it. A kept window's list of channels is matched only for channels the kept windows
  name and the character is in (`Arranged`, plus your own joined in that writing): `AddChatWindowChannel` is not called for a
  channel it left, and a new character's General, gone a moment later, is no change to offer a `/reload` for.
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
- **Conversations** (`Talks.lua`, no frames; `Conversations.lua`, the panel): `Log.Read` puts on a whisper
  whom it is with (`with`: the sender, or whom you told; `account`: a Battle.net friend's account this
  session). `Social.lua`'s `Heard` hands a whisper or a party, raid or instance message to `Talks.Add`
  (`ns.Safe`, apart from the window), which keeps a copy (`Log.KEPT` and `stamp`, `time()`) in its
  conversation: `W:<player key>` (`Core.PlayerKeyOf`), `B:<BattleTag>` (`C_BattleNet.GetAccountInfoByID`; one
  the game names no BattleTag for is kept this session only), or `G:<the group's GUID>`: each group joined
  (`GROUP_JOINED`'s `partyGUID`; the game has no call for it, so a group you were in already when it is first
  asked about gets a key of its category and the time) is a conversation of its own (`category`, `started`,
  `ended`, `members`: the others as the game names them, from the raid's roster or the party's units, in the order
  they came, `Talks.MEMBERS` at most; named by `Talks.NAMES` of them and how many more), the current one per
  category in `Talks.current` (kept over a `/reload` in `talkGroups`). Its `kind` follows the group (a party
  become a raid is a raid); party, raid and raid warning go to the home group's, instance chat to the instance
  group's; none once you left (`GROUP_LEFT` ends it: `ended`, written in no more, `TEXT.groupOver`). `Talks.Groups`
  makes the current ones for the list. A whisper's copy has no
  chat's name (the conversation says whose). Each keeps its last `talkSize`, the one read (`Talks.reading`) all
  until it is left; at most 50 conversations (`Talks.MOST`), the quietest goes. Sending is the game's way
  (`ChatFrameUtil.SubstituteChatMessageBeforeSend`, `SetLastToldTarget`, then `C_ChatInfo.SendChatMessage` or
  `C_BattleNet.SendWhisper`, the account found anew by BattleTag); the message joins from its `_INFORM` or
  group event. The line is an `EditBox` of ours, not the game's; `/` lines go to `ChatFrameUtil.OpenChat`; in
  chat lockdown (`InChatMessagingLockdown`) nothing is sent. Saved at `PLAYER_LOGOUT` in
  `chars[character].talks` (`talksVersion` 2): `Talks.SAVED` (1,000) messages of all conversations together at
  most, the newest conversations' first (the saved settings are read at every login, of every character); a
  Battle.net friend's messages without their name and link (`|K…|k` is this session's), links without line numbers,
  without what follows from the rest (a whisper's colour, from its kind and side; a group's chat in short, from its
  name); restored at the login, checked field by field.
  The panel is a part of `Board.lua` (`Part.Size` tells it its width); `Layout.Board` gives it all the room
  the right part leaves, `TALKS_MIN` (460) at least. Its list is `TALK_LIST` (190) wide at first; the line
  beside it is dragged by a strip over it (`TALK_GRIP`, 8 wide, `OnMouseDown`/`OnUpdate`/`OnMouseUp`, the
  cursor `UI_RESIZE_CURSOR` as Core's grip): only the line follows (`GetCursorPosition` over the panel's
  effective scale), and once let go the width is kept (`store.talkList`) and `Window.Reboard` lays the full
  screen out once, so the messages are measured once for the new width. `Layout.TalkList` keeps it between
  `TALK_LIST_LEAST` (150) and what leaves the one chosen `TALK_PAGE` (269); `Layout.Board` (`want.list`) and
  `Conversations.Size` both count it so, the chat's frame and the panel's parts at one width. First in its list stands a row of its own, the chat
  (`pinned = "chat"`; not while `Board.Has("chat")`), then a row per chat view (`pinned = "view"`, `view`, made
  once per view: `Row`), their last message from `Window.Last` and `Feed.Last(view)` (redrawn a frame after a
  message, `Conversations.Said`). The chat chosen stands where a conversation's messages and line do:
  `Board.Show`'s `chat` is that part of the panel (beside the list, under the line with the name, `TALK_HEAD`),
  and the window seats its frame for the chat (`column`) there; `Window.Pick("chat")`, else (a conversation or a
  chat view chosen) the frame is hidden, with the list, its scroll bar and the button on it. A chat view chosen
  stands in the page's own list of a view (`views = Feed.New(nil, page, TALK_HEAD)`, pointed at the one chosen:
  `Point`). The name line's dropdown (`WowStyle1FilterDropdownTemplate`) holds the ticks of the one chosen
  (`Channels.Shown` for the chat, as the line's own list; `Feed.Menu(view)`). *New chat view* (`Feed.Make`, a
  button over the two of the foot; the list ends above both rows) makes and chooses one; a right click on one
  (`MenuUtil.CreateContextMenu`) renames it (`Core.AskText`, `Feed.Rename`, its window's head too:
  `Board.Retitle`) or removes it (`Core.Confirm`, `Feed.Remove`, out of every layout: `Board.Forget`). Unseen:
  `Unread(element)` (a talk's `unread`, `Feed.Unread(view)`, `Window.Unread()`) lights the row with the game's
  `ChatFrameTab-NewMessage` (additive, `BORDER`, tinted with the last message's chat colour, as the game tints
  its tabs' glow; steady, no flash) and counts it (`99+` above 99), not on the one chosen. The game's line opened while a conversation is chosen (`Window`'s
  `Room`, then `Conversations.Chat`, a frame later): empty and not a whisper, it is closed
  (`Input.Close`: its `ClearChat`, as Esc) and the conversation's line takes the cursor; a whisper whose
  target has a conversation (`Talks.Whisper`, by `GetTellTarget`) chooses that one, the same; anything else
  chooses the chat. A conversation chosen while the game's line is in use (`Window.Writing`) closes it; one
  you began is chosen only once the line is out of use. Its list is `Board.List`, its
  messages a list like a chat view's (`Bubble.Init`, no fade, no slide), a pill per day (`CALENDAR_WEEKDAY_NAMES`,
  `FormatShortDate`). The search uses `Window.Found` for messages. Shown, it listens to group and Battle.net
  events; `Window.Repaint` and `Resize` redraw it (an alias, the bubbles' look, the text size).
- **Chat views** (`Feed.lua`): kept in `store.views = { next, list = { { id, name, shows } } }` (account-wide, as
  the layouts that name them as windows, `view:<id>`); at first one, `TEXT.feed`, with `Feed.FIRST`'s ticks. A
  list of a view (`Feed.New(view, parent, top)`: its own scrolling list and scroll bar, made when first shown,
  `Point` to show another view, `Fit` its row width, `Refill`, `Rewrap`, `Added`) stands wherever the view does:
  the conversations' page (one list, pointed at the view chosen) and each of its windows on the board (its panel's
  body; a `WowStyle1FilterDropdownTemplate` with `Feed.Menu(view)` on its head). The window hands every new
  message to every list (`Feed.Added`, before its own); one out of sight notes it is stale. A view none of whose
  lists is on show counts a message it shows as not seen, for this session only, not kept with the view (`unseen`,
  and the last one's colour in a table made once for each view, `tints`, both by view); a list of it
  shown clears that (`Conversations.Said` redraws the rows). The chat's own unseen are counted by the window
  (`Window.Unread`: its messages that come while it stands out of sight on the full screen).
- **Chat windows** (`ChatWindows.lua`): a chat view on the screen as a window of its own, `view.screen = true` (kept with
  the views, account-wide; `Feed.Views` keeps it true or nothing). Made the first time it is wanted: a frame on
  `UIParent` (`MEDIUM`, `Layout.LEVEL`, as the chat), Core's window of the kind `screen` with `edge = false` (it never
  fills the screen), `key = "view:<id>"` (its place in the profile's places, `Social:view:<id>`), `title` its name (its
  box in Edit Mode; `Feed.Rename` → `ChatWindows.Retitle`), its first place above the chat's first, each new one a
  `Core.Window.CASCADE` step aside. Its list is the game's `WowScrollBoxList` and `MinimalScrollBar` as the chat's, its
  name over it (`NAME` 18), and it is a list of its view as Feed's are (`Feed.Join`: `Added`, `Refill`, `Rewrap`,
  `Point(nil)` when the view is removed); shown, its view's unseen are cleared (`Feed.Saw`). Newest at the bottom
  (`Settle`), cut rows hidden (`Trim`, again a frame later), a new message slides the others up (`Core.Motion.Slide`).
  Its fading goes by a message's age alone (`entry.at`, the chat's settings: in over *Fade-in time*, out after *Fade
  messages after* over *Fade-out time* to the opacity set), not by the fade kept on the message (`Fade.lua`, the
  chat's): the same message stands in both, revealed in one and not the other. The wheel lifts all (`lift`, a table
  `Fade.To` moves, so it fades in and out as a message does); the mouse leaving at the newest, or the list back there
  with the mouse away, lets them fade again. An `OnUpdate` only while a row in view or the lift moves, then one timer
  (`C_Timer.After`) for the next row in view to begin fading (`dueAt`: an older timer does nothing). The mouse's coming
  only (`Core.Hover`): its name and the button (the game's chat button art) while it is over the window, its list is
  open or it shows nothing (then a word on what to do, `windowPick` / `windowQuiet`); the button's list
  (`MenuUtil.CreateContextMenu`, `ns.Menu.Button`): its name, *Rename Window* (`RENAME_CHAT_WINDOW`, `Core.AskText`),
  *Close Window* (`CLOSE_CHAT_WINDOW`), the chats it shows (`Feed.Flip`). On the screen while the chat stands at its
  size (`ChatWindows.Stand`: `Window.Show`, `Window.Hide`, `Filled`); `Window.Animate` tells them (`Animate`). The
  chat's list has the column *Chat windows* (`Menu.lua`: a tick per view, `ChatWindows.Flip`; *New Window*,
  `NEW_CHAT_WINDOW`, `ChatWindows.Make`: a view named `newWindow`, on the screen, its list opened a frame later).
  Every step in `ns.Safe("chat windows", ...)`: a failure is noted, the chat goes on.
- **The conversations' parts** (`Conversations.lua`): after the chat and the chat views the list holds a head per part
  with conversations in it (`PARTS`: `whispers`, then `groups` by `Talks.GROUPS`; `heads[key]`, the same table always:
  `head`, `part`, `folded`, `unread`), lower than a row (`Layout.TALK_PART`, 24: `Board.List`'s new `extent`). A head:
  the game's `UI-MinusButton-Up` / `UI-PlusButton-Up` on a texture of its own (the row's icon is cut round), its name
  in gold, folded the sum of its `unread` at its right and the new-message glow in its chat's colour (`WHISPER`,
  `PARTY`). A click folds or shows (`store.talkFolds[key] = true`, mended when it is not a table); while the search
  has words nothing is folded. The one chosen stays chosen in a folded part; one chosen by itself (`Choose` from
  `Added` or `Opened`) shows its part again (`Unfold`). The first chosen when the one before is gone is the first that
  is no head.
- **The setup** (`Setup.lua`, `Core.Onboarding.Add`; the addon Onboarding's window draws it): steps `intro`, `corner`
  (the hot corner and the keys on one page; Saneroki, 2026-11-18: "Same for Social setup with the Hotcorner and or a
  key page"), `windows`, `full`. The corner's choice is one control over three switches (Onboarding's choice of a table,
  `parent = false` so it is never greyed out): `{ expand = true, expandCorner = false }` (not at all),
  `{ expand, expandCorner, expandClick = true }` (a left click), `{ expand, expandCorner, expandClick = false }` (the
  mouse). `expandCorner`, *Hotcorner*, is a switch of Core's section *Expand window* (every module's), right under
  *Can expand to fullscreen* (`Edge.lua`: off, no strip and no square; the full screen still fills by `Window.Full`, the key
  `SANEUI_SOCIAL_FULL` in `Bindings.xml`, `ns.Full`, behind `ns.Safe`); *Hotcorner requires leftclick* stands under
  both. Under the corner's choice, the same page binds `SANEUI_SOCIAL_FULL` and `SANEUI_SOCIAL`; the windows' step has `window`, `showNative`, a
  tick the module answers (`check`/`set`: the first view's `screen`, `ChatWindows.Put`) and `boardFinder`; the full
  screen's step two such ticks, the friends list and the guild window in the layout chosen (`Board.Holds`, `Board.Put`:
  Core's `board:Holds`, `board:Put`, also while the full screen is away; the friends list at the conversations' right,
  the guild window over it, `BESIDE`). Each step a
  board on the stage: a drawn screen with the chat where it is docked (`Window.Zone`), the game's tutorial arrow
  (`NPE_ArrowRight`, its glow) into that corner as the choice says, the keys bound now, the windows ticked, a drawn
  full screen with the parts.
- **The full screen's windows** (`Board.lua` on Core's board, `Core.Board`, Doc/guides/windows.md section 7, *The
  board*): Social gives Core its windows (`talks`, `friends`, `guild`: each a part's `Build`, `Show`, `Size`,
  `Search` behind `ns.Safe`, and its `least`; the guild window's `present` asks `Guild.Size`) and the first
  layout (`Default`: the rooms of `Layout.Board` made a layout: the conversations and the friends list side by
  side, shares as large as the rooms). Core lays the layout chosen out, makes and places the panels (`Board.panels` is its table) and gives
  back each window's rect; `Board.Show` holds the guild window in its panel's body (`Guild.Hold`) and returns
  the chat's place (`chat`: the conversations' part beside their list and under the line with the name), none
  without the conversations (then `Window`'s `Shows` is nil and the chat is out of sight). A change on the
  board (a tab, a drag, a window added or taken off) calls `Window.Reboard`. The layouts are kept in
  `store.board`. `Layout.HEADER` and `Layout.PAD` are Core's board's `HEAD` and `PAD`.
- **The guild window** (`Guild.lua`): not built anew but held. `Board.Show` asks `Guild.Size` for its own size
  (in the full window's units: its seat's `Size`, the size it has when not seated, times `UIParent`'s effective
  scale over ours): whether there is one to hold (its spec's `present`), then `Guild.Hold` seats it in its panel's body. Which window: the one open after the guild key's work (`ToggleGuildFrame`,
  the game's way, out of a fight once per full screen), found among the windows the game knows by name, those
  Esc closes (`UISpecialFrames`) and its panels (`UIPanelWindows`): the largest that was not open before,
  `Guild.LOOK` (0.2 s) later. So it is the game's `CommunitiesFrame`, or the window another addon shows when it
  answers the key, with no name of it in our code; its name is kept (`store.guildWindow`) to know it when it is
  open already. Held by Core's seat (`Core.Seat`, one per window, label `Social: guild window`): its scale,
  layer (the full window's strata, at least `GUILD_LEVEL` above what it holds) and points lent and given back,
  its parent never changed, placed at the screen's place of its room against `UIParent` (`BOTTOMLEFT`), not
  anchored to our window: a window with protected buttons would otherwise tie ours to the fight's rules, and a
  drag still moves it as its own. The room `Guild.Hold` hands the seat is the window's own size at the scale that
  fits the body (at most 1), at the body's top in its middle: a seat fits a window into its room (centred, as
  large as fits), so a room exactly that size leaves nothing round it. A window you open again yourself while
  the full screen stands (its `OnShow`, hooked once) is back in its panel; `Guild.Least` gives its panel's least
  (`GUILD_LEAST` of its size). The seat's hooks put it back when the game places or
  scales it anew (`SetPoint`, `SetScale`), fit it anew and tell `sized` when its size changes (its room anew:
  `Reboard`), and give it back and tell `gone` when it closes (not opened again while the full screen stands;
  closed in a fight it comes back after it, `PLAYER_REGEN_ENABLED`). Guild's own: which window, opening it
  once per full screen, `opened`, `dismissed`, the fights. `Guild.Leave` (the full screen gone) gives it back
  and closes one it opened as Esc does (`HideUIPanel` for a panel of the game's, else its `Hide`); so does a
  full screen that leaves it no room. A step that fails gives it back and holds it no more until a `/reload`
  (`Social: guild window` in the error log).
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
- **Taint.** Our code still changes the game's edit box in two ways:
  a choice in the list of chats calls its `SetChatType` / `SetStickyType` / `SetChannelTarget`
  (frame attributes, then written by addon code), and the window's button calls `ChatFrameUtil.OpenChat`
  and the edit box's `ClearChat`; words picked to copy take the keyboard from it, and the game closes it
  then if it is empty (its `OnEditFocusLost`), as `ClearChat` would. The game reads the chat type when it sends (`SendText`, then
  `C_ChatInfo.SendChatMessage`, which has restrictions). The taint log shows whether a message sent, or a
  `/cast` typed, after such a choice is blocked (`/console taintLog 1`, `Logs/taint.log`; switch it off
  afterwards). Enter, `/`, Esc and sending themselves stay the game's code.
- **Tests:** `lua5.1 dev/tests/social.lua`: what an event says, the layout arithmetic, sides and
  bubbles, wrapping anew once a sizing is over, following the newest message, place and size, the game's
  chat out of sight and back (also a minimised window's button, a frame the game moved meanwhile, chat
  lockdown), printed lines, the line to write in and its button, the line at rest in both chat styles
  and given back as it was, the list of chats, messages at the bottom, fading, the settings, text size,
  rings, a speaker asked about once, community channels, the handles with the mouse over the window,
  cut rows, the oldest messages going in batches, a message that cannot be read, the fall-back, the
  game's channels and their wishes (the list, once a zone, only where offered, not in lockdown, a profile's
  wishes, with the window closed), the switch *Chat window*, Core's window and the game's chat agreeing
  whichever way it changed, the key, the full screen's panels and the conversations' list dragged to its
  width, words picked to copy (lit while dragged, waiting for Ctrl+C, let go by the next press or key), the
  conversations' parts (their heads, folded and kept, counted and lit, found in a search, shown again for one chosen by
  itself), the chat windows (made from the chat's list and a view's right click, Core's window and its key, fading by
  age, the wheel, their button's list, New Window, out of sight with the chat, messages not seen, a view removed), both
  keys (the full screen's also with the hot corner off), the setup (its steps, the corner's three choices, the second
  chat's tick, every board drawn), and
  Retail (`W.Play`: the group finder's tab and switch away, the game's own finder opened, its unblock, raid locks).
  They cannot judge the look.

## Files
| File | What it is |
|---|---|
| `SaneUI_Social.toc` | The addon `SaneUI_Social` |
| `Art/banner.blp`, `Art/icon.blp` | The module's logo (speech bubbles): one of SaneUI's family of logos (`dev/tools/logo-art`), its banner at the top of its options page, its icon in the addon list (the TOC's `IconTexture`). Original art of SaneUI (see the project's `LICENSE`), made by `dev/tools/art` from `assets/Logos/social-banner.png` and `social-icon.png` |
| `Social.lua` | The module's table, its texts and switches (also the wishes for the game's channels), the events, `/sane social`, the fall-back |
| `Log.lua` | What an event says; the list of messages. Knows no frames |
| `Layout.lua` | Sizes, distances, fills; the arithmetic from the window's width. Knows no frames |
| `Links.lua` | The links in a message: tooltip on the mouse, the game's click |
| `Bubble.lua` | One message: measured and drawn, lit where words of it are picked |
| `Select.lua` | Words picked out of the messages on the full screen by a drag, waiting highlighted in a hidden edit box for Ctrl+C |
| `Channels.lua` | The chats you can write in right now. Knows no frames |
| `Native.lua` | The game's own chat: out of sight, and back |
| `Input.lua` | The line to write in: the game's edit box in our window, at rest, given back |
| `Menu.lua` | The list on the line's label: where to write, what the window shows, the game's channels on every character |
| `Picker.lua` | The smiley beside the line and its list: raid marks to write, emotes to do |
| `Art/smiley.blp` | The smiley (24 x 24). Original art of SaneUI (see the project's `LICENSE`), drawn by `dev/tools/smiley-art` into `assets/SaneSocial-Smiley.png`, made by `dev/tools/art`; the game has no smiley of its own |
| `Join.lua` | The game's chat channels, the same on every character as wished. Knows no frames |
| `Board.lua` | The full screen's windows on Core's board, its first layout, the guild window held in its panel, the search to all; the list, row and buttons the friends list's tabs share |
| `Guild.lua` | The guild window on the full screen: the one the guild key opens (the game's, or the one that answers the key instead), held at its right |
| `Feed.lua` | The chat views: as many as you make, each its own ticks, rows of the conversations' list and windows of the layouts, a list of its own wherever one stands, their messages not seen counted |
| `ChatWindows.lua` | A chat view on the screen as a chat window of its own beside the chat: Core's window, moved and sized in Edit Mode, fading by age, its button's list (rename, close, what it shows), New Window |
| `Setup.lua` | Social's setup, step by step, for the addon Onboarding's window: the hot corner (not at all, a left click, the mouse) and the keys on one page, the windows, the full screen; a drawn board for each |
| `PlayerMenu.lua` | A right click on someone (a name, a message on the full screen, a whisper's row): the game's menu of the player with Social's lines (Add Friend, Pin them on the map, Show on map, Delete conversation); a group's row: its own menu |
| `Keys.lua` | The game's friends list and group finder keys open the full screen with ours, until their ticks in Classic windows say the game's |
| `Talks.lua` | The conversations: whispers, and each group you join (its chat apart, named by its members, ended when you leave), kept per character. Knows no frames |
| `Conversations.lua` | The conversations' panel at the full screen's left: the chat, the chat views and the conversations in a list (rows with messages not seen lit), the one chosen beside it, a conversation's line to write in, *New chat view* |
| `Friends.lua` | The friends list's panel: you on Battle.net at its head, its tabs, the search box and the filter, the list of the tab chosen |
| `Contacts/Contacts.lua` | What the lists share: the game's colours and status icons, a status, how long ago, the filter by status, a whisper, a player's name to add, ignore or group |
| `Contacts/Account.lua` | The head: your status, your BattleTag, how many friends are online, the contacts menu (broadcast in Retail alone, ignore list) |
| `Contacts/Friends.lua` | The friends list, as the game's (`C_FriendList`, `C_BattleNet`); the game's own menu, whisper and invite |
| `Contacts/Requests.lua` | Friend requests (Accept, Decline, Block Invites where the game offers it) and the line to add a friend |
| `Contacts/Ignored.lua` | The players ignored and the accounts whose invites are blocked, in the friends list's place |
| `Contacts/Allies.lua` | Recent allies (`C_RecentAllies`), once the game has read them |
| `Contacts/Raid.lua` | The raid's groups, arranged by dragging, a menu of its own on a member; Raid Info |
| `Contacts/Quick.lua` | Quick Join (`C_SocialQueue`): the groups of your friends and guild you may ask to join |
| `Contacts/Finder.lua` | The group finder, the friends list's last tab, as the game's browse view (`C_LFGList`); searches only on a click, paused in chat lockdown; WoW: Forever only |
| `Window.lua` | The window: moved, sized, scrolled, kept |
| `Bindings.xml` | Its key in the game's key bindings (section *SaneUI*, Core's): the chat window shown or hidden |

## Not there yet
Tabs of chat views in the small window (`Doc/ideas/Social.md`), messages of one speaker in a row drawn as
a group, a close button, a sign besides colour for what a speaker is to you. The picker's marks in our own
style in place of the game's (Saneroki, 2026-10-21; `Doc/guides/interface-style.md`, *To redesign*).

## History
- 2026-11-18 — Going through the onboarding again (Saneroki: "the changes we made during that prompt including the
  fix to the smiley never worked"): a right click on a name, a message or a whisper's row opens the game's menu of
  that player owned by Social's part (`PlayerMenu.Open`, by `UnitPopup_OpenMenu`; Forever's game code made its hidden
  chat frame the owner, and its menu manager closed the menu as it opened); the smiley takes no click, the line
  reaching over it takes the press and keeps its cursor (`Picker.lua`, `Input.lua`'s hit rectangle). The full
  screen's first layout: the conversations on two thirds, the friends list on the third at the right
  (`Layout.SHARES` 2 and 1, `Layout.Board` without the guild window); the guild window only when put there (the
  dropdown *Windows*, the setup's tick: sharing the friends list's room); the setup's drawn full screen so.
- 2026-11-18 — The chat window at first 686 × 307.5, docked in the lower left corner (`Layout.WIDTH`, `HEIGHT`), as
  Saneroki has it.
- 2026-11-18 — Going through the onboarding (Saneroki): a right click on a whisper's or a group's row has *Delete
  conversation*; one on a name or (on the full screen) a message opens the game's menu of that player with *Add Friend*,
  *Pin them on the map* and *Show on map* (`PlayerMenu.lua`, new in the TOC; Core's `Ways.Look`); the smiley works on an
  empty line (`Picker.lua`: the list the window's, the line opened again); every entry of *Classic windows* a tick, the
  friends list's and group finder's keys opening the full screen (`Keys.lua`, new in the TOC; `friendsKey`,
  `finderKey`); *Your messages* on the left or right (`mineSide`, `Bubble.Mine`); *A new conversation for each group*
  (`groupEach`, `Talks.lua`: one conversation per category while off); the setup's pages *Your messages* and *What is
  kept*; the corner board's key words no longer take the drawn chat's name (*keyFull*, *keyChat*).
- 2026-11-18 — The full screen's first layout as Saneroki likes it (his picture): the conversations, the friends list
  and the guild window side by side and as high as the screen, as wide as `Layout.SHARES` share it (650, 390 and 889
  pixels on his screen), each at its least at most (`Layout.Board`: the guild window left out first, then the friends
  list; one left out gives its share to the conversations); the setup ticks the guild window in at the friends list's
  right (`BESIDE`), its drawn full screen in those columns.
- 2026-11-18 — Social's setup: the hot corner and the keys on one page, *The hot corner, or a key* (Saneroki: "Same for
  Social setup with the Hotcorner and or a key page"): the corner's choice, then the keys of the full screen and the
  chat window; its board the corner and both keys as they are set now.
- 2026-11-18 — More than one chat window on the screen (Saneroki): a chat view stands on the screen as a chat window of
  its own (`ChatWindows.lua`, new in the TOC; the chat's list's column *Chat windows*, *New Window*, a view's right
  click, its own button). The conversations in two parts, Whispers and Groups, under heads that fold. Social's setup
  (`Setup.lua`, new in the TOC): the hot corner not at all, by a left click or by the mouse (the switch *Hotcorner*,
  `expandCorner`, read by Core's edge), a key of its own for the full screen (`SANEUI_SOCIAL_FULL`), the windows.
- 2026-11-07 — Discord's messages on the left, as a speaker's (Saneroki): the guild's Discord stream is read
  from its event (`CHAT_MSG_GUILD_DISCORD`), not taken as a note in the middle; one from Discord in the guild's
  chat is never yours.
- 2026-11-01 — The game's channels in the list: a tick each, joined or left, instead of three choices; a leave the
  game refuses is not asked for at every click (Saneroki).
- 2026-10-30 — Defaults (Saneroki): the game's chat out of sight, whole chat names; a character starts in no public
  channel, each left once and never again, whatever you join later; loot, money, experience, General, Trade, Local
  Defense and Services not shown at first. A tick now belongs to the channel, not its number.
- 2026-10-30 — Full screen: the chat lies on its panel's see-through plate, no more under it; the list on the chat's
  name in columns, open until a click outside it or on its button (Saneroki).
- 2026-10-25 — Retail: the tab *Group Finder* and its switch stand down (Retail's finder is its own), *Group finder*
  in *Classic windows* opens Retail's, invites are blocked by Retail's own function, *Extend Raid Lock* as Retail's
  raid info offers it; the button *SaneUI* also on the game's newer social window.
- 2026-10-20 — Recent Allies asks the game for them no more (an addon may not); it waits until the game has read them.
- 2026-10-20 — Every group you join a conversation of its own, named by the others in it, ended when you leave
  (by the group's GUID; Saneroki).
- 2026-10-20 — Chat views (Saneroki): *New chat view* in the conversations, as many as you like, each with its
  own ticks, rows of the list and windows of the layouts (`Feed.lua` anew; the switch *Second chat* and the
  setting `split` are gone, the second chat is the first view); the chat as a window of its own (`chat`); rows
  with messages not seen yet lit with the game's new-message glow.
- 2026-10-20 — The full screen's windows on Core's board (Saneroki): layouts behind tabs, the windows sharing the
  screen as you arrange them (drag a gap, a head; the X; the dropdown *Windows*); the switches *Conversations*,
  *Guild window* and *Friends list* are gone (a layout has the windows or not); the guild window held in a panel.
- 2026-10-20 — Words picked out of the messages on the full screen by a drag, over as many messages as wished,
  lit grey, copied with Ctrl+C (`Select.lua`, new in the TOC; Saneroki).
- 2026-10-20 — The conversations' list dragged wider or narrower by the line beside it, its width kept
  (`store.talkList`, `Layout.TalkList`); full, no message of the chat fades, wherever the mouse is (Saneroki).
- 2026-10-20 — The guild window held by Core's seat (`Core.Seat`, as Combat's panels are): `Guild.lua` keeps only
  which window, its opening and closing and its room; the seat lends, places, follows and gives back. Its room
  is its own size at the layout's scale, so it stands exactly at that scale, its top right at the room's.
- 2026-10-20 — The full screen anew (Saneroki): the guild window at its top right (`Guild.lua`: the one the
  guild key opens, held there as large as it is; setting `boardGuild`), the friends list under it and as wide
  (`Friends.Size`); the conversations take the rest, and the chat and the second chat are two rows of their
  list, standing beside it when chosen (`Window.Pick`; the second chat in the chat's frame, `Feed.Show`), not
  apart in the middle any more. The game's line opened while a conversation is chosen goes to that
  conversation's line, or chooses the chat. `feedShare` is gone; `Layout.Board` takes no share.
- 2026-10-18 — Conversations at the full screen's left (`Talks.lua`, `Conversations.lua`): every whisper (a
  Battle.net friend by BattleTag), the party's, raid's and instance group's chat, each apart, with its own line
  to write in; kept per character. Settings `boardTalks`, `talkSize`; `Log.KEPT`, a whisper's `with` and
  `account`; `Board`'s `Part.Size`.
- 2026-10-18 — Aliases (Core's `Core.People`): above a bubble the alias in the speaker's link
  (`Bubble.Speaker`), in the friends list in place of a character's name and of a Battle.net friend's
  character; the chat's search finds it; a change redraws both (`Core.People.Watch`).
- 2026-10-18 — The group finder is a tab of the friends list (`Contacts/Finder.lua`, the last of its tabs; the
  switch *Group finder* offers it), no panel of its own; the friends list stands at the full screen's right,
  the chat left of it (`Layout.Board`).
- 2026-10-17 — Full screen panels (`Board.lua`): the friends list (`Friends.lua`), the group finder
  (`Finder.lua`) and a second chat with its own ticks (`Feed.lua`) around the chat, which stands in a frame of
  its own (`Window.lua`: `column`, `Area`; the line to write in and the smiley hang on it). Settings
  `boardFriends`, `boardFinder`, `boardFeed`, `feedShare`, `split`; *Group finder* in *Classic windows*.
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
- 2026-10-16 — The button *SaneUI* on the game's chat (Core's `Attach`, placed by `ns.NATIVE.anchor` above
  `ChatFrameMenuButton` in `ChatFrame1ButtonFrame`), there only while our window is away (`Back` in
  `Window.lua`); off at login, the window is made out of sight for it (`Window.Away`). The small window's bar
  lost its title *Social* (Saneroki).
- 2026-10-16 — No title bar while small (Core's buttons left the small window); filling the screen, Core's
  title bar at its top with the search over the messages (fuzzy), the dropdown and the buttons.
- 2026-10-16 — Free or docked in the screen's middle, Core's three buttons in the top right corner (with the
  bar): the game's chat (`ns.NATIVE`), full screen, close (`ns.Close`: both put our window away); the list
  starts under them then (`Top`).
- 2026-10-16 — Moved and sized only in Blizzard's Edit Mode (Core's box and grip); outside it no grip on the
  mouse's coming, and the bar is only the title, taking no click.
- 2026-10-16 — Fixed: the messages went out of sight and came in again whenever the window filled the screen
  or went back. They stay in sight and at the bottom all the way now, and are wrapped for the new width once
  it stands.
- 2026-10-16 — A smiley right of the line to write in: its list puts the game's raid marks (`{rt1}` to
  `{rt8}`) into the line, except in the game's public channels, which show none, and does emotes played
  most (`/hello`, `/cheer`, `/thank`, ...).
- 2026-10-16 — Full, the dropdown *Classic windows* (Core's): *Chat* puts our window away and the game's chat
  is back, *Friends list* opens the game's friends list; the list starts under the dropdown. The full screen
  background is always square.
- 2026-10-16 — The section *Expand window* is first in the tab *Appearance* again (it had come after
  *Animations*), with *Corner radius* (10 %) and *Don't round corners on screen edges* (on): the full screen
  background has round corners and a bronze trim on its way, square where it meets the screen's edge.
 
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
- 2026-10-15 — *Save chat history* (the last 100 at first, up to 500); *Messages to show*: the system's, creatures', addons' messages and the channels' joins and leaves as switches (joins and leaves hidden at first); less room between the bubbles (3, was 8).
- 2026-10-15 — All bubbles alike, yours too: *Bubble background* (a solid color, or Marble, Rock, Slate, Iron, Night from the game's art) and *Bubble color* (the game's color picker) in the tab *Appearance*.
- 2026-10-15 — Every line the game's chat shows is in the window: the system's (also those without an event), pings, loot, money, experience, battlegrounds, channel notices, friends online, ... (`Log.Line`, a hook on every chat window); new kinds to show or hide. The line to write in is grey, as the bubbles.
- 2026-10-15 — Full screen: docked in a corner, only that very corner sets it off; nothing behind the window takes the mouse; the section *Expand window* at the top of the tab *Appearance*: *Can expand to fullscreen*, *Animation type* (moved here), *Background opacity* (half at first, was solid), *Background texture*.
- 2026-10-15 — Full screen: docked, the window fills the screen when the mouse is pushed against that screen edge, and goes back when pushed there again (Core's `Edge.lua`); *Animation type* in the tab *Appearance*.
- 2026-10-14 — The game's chat channels (As the game does, Always join, Always leave) are here now, on the page *Chat*; they were on the page *Profiles* (Sync module).
- 2026-10-14 — After a review: party and raid rings show again (`C_PartyInfo`); community channels by their names; the game's chat comes back during chat lockdown and stays complete (a minimised window's button; frames the game moved); the line at rest is made invisible instead of hidden by our code and given back as it was; one unreadable message no longer closes the window; failing safer (`Guarded`, `GiveBack`); cheaper: the oldest messages go in batches, a speaker is asked about once, the window rewraps once a sizing is over; the list of chats in `Menu.lua`.
- 2026-10-14 — Moved, sized and kept by Core's window code; docks to the screen's edges.
- 2026-10-14 — Links in messages show their tooltip on the mouse and answer a click as in the game's chat.
- 2026-10-14 — Fixed: the bubbles' corners (seen in the game); a channel's tick in the list now counts by the channel's number. New setting *Show native chat*, on.
- 2026-10-14 — Chat names in short (a setting); ticks in the list for what the window shows.
- 2026-10-14 — A thinner ring; bubbles half see-through, with a setting for it; the line to write in drawn as your own bubbles.
- 2026-10-14 — Bubbles and the line to write in as plain round-cornered fills; a white ring for strangers; the line grows with its text; the button also opens the list of chats.
- 2026-10-14 — No background; handles and the chat button (now lower left) only with the mouse over the window; drawn above the action bars; cut rows hidden; round icons with rings for friend, guild, raid, party; names as large as the text; a text size setting.
- 2026-10-14 — The line only while you write, a button for it, no tooltip on the chat's name; newest message at the bottom; messages fade, with a switch and a slider.
- 2026-10-14 — The line to write in, the list of chats on its label, the game's own chat out of sight, printed lines as notes.
- 2026-10-14 — First prototype, with the look of a messenger.
