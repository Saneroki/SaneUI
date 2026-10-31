# Social

Was the Chat module (`SaneUI_Chat`, `src/Chat`) until 2026-10-16; today it holds the chat window only.

## Message pipeline

`Social.lua` receives events → `Log.Read` (plain message, no frames) → `Log.Add` → `Log.added`
→ `Window.lua` filtered provider → recycled `Bubble.lua` rows. Every other line: a `hooksecurefunc` on the
`AddMessage` of each of `CHAT_FRAMES` (not the combat log) → `Log.Line`: a line of an event we read (its eighth
value, or the event the game's chat filter `Log.Before` was told; `Log.After` clears it at its `OnEvent`'s end) or
of a kind of chat we read (fifth value) is left out; the same line in two windows in one frame once (`Fresh`).
A failed read drops/reports one message; a guarded mutation/view failure restores native chat and
stands the module down until reload.

Message fields: `side` (`left/right/center`), `text`, `name/class/tie`, `label/short/group`, `r/g/b`,
`time/at`; render caches `fits/sized/widest/textWidth/textHeight/meta`; `gone` marks pruned records.
Own messages use sender GUID against `Core.charKey`, not name. Inform events are always right.
System/emotes/prints are centered without bubbles. Log keeps at least 200 messages (more when the saved
history is longer, `Log.Keep`), prunes 25 together. With `history` on (default; `historySize` messages) the
last messages are saved per character at logout and put back at login (`Log.Saved`/`Restore`).

| File | Responsibility |
| --- | --- |
| `Social.lua` | Module, options/words (incl. `presence`, the game-channel wishes, no control), event hooks, commands and stepwise fallback; `Choose(on)` = `Core.Set(ns.name, "window", on)`, the one source of truth for ours/the game's chat (Classic toggle, close, Esc, the dropdown, `/sane social`, `ns.Toggle` for the key `SANEUI_SOCIAL` in `Bindings.xml`); `ns.options = Core.Settings(ns.name)`; *Expand window* via `Core.Edge.Options(..., { motion = "animations" })`, its changes followed by Core; bubble backs `Core.Skin.Choices` |
| `Log.lua` | Decode/store messages; cache speaker class/ties; `EVENTS` and `GROUPS` |
| `Layout.lua` | Pure geometry and colours; central dimensions |
| `Links.lua` | Links in a message: tooltip on hover, click handled by the game's `SetItemRef` (frame with `SetHyperlinksEnabled`) |
| `Fade.lua` | How much of a message is seen (in, there, out, gone), kept on the message as from/to/since/span; `Fade.Alpha` (`Core.Motion.Ease`, `Fade.CURVE` InOutQuadratic), `Fade.Times`; at once with Core's animations off; knows no frames |
| `Bubble.lua` | Ruler measurement/cache, recycled row content, class icon/tie ring (`Core.Shape.Round`), cut; the plate is a `Core.Shape` of fixed `Layout.RADIUS` painted from one shared look (repainted when its counter changes), `Core.Font` for the size, `Core.Skin.Tile` for a tile |
| `Channels.lua` | Current writable chats, showable groups, localized/community names, UTF-8 initials; `Flip` by `Core.Set` |
| `Menu.lua` | Blizzard radios for writing destination, checkboxes for visible groups, a submenu per game channel (three wishes) |
| `Picker.lua` | Smiley right of the input (`Layout.FACE`, `GRIP_ROOM`): MenuUtil list with a row of raid marks (`{rt<n>}` inserted; none in Zone channels, which suppress them) and popular emotes (`C_ChatInfo.PerformEmote`, named by `EMOTE<n>_CMD1`); own art `Art/smiley.blp` (`dev/tools/smiley-art`); tip by `Core.Tip` |
| `Native.lua` | Native chat parts lent (`Core.Lend`: layer noted, then parent) to a hidden frame; given back only if still ours. Not Core's holder: the chat is never closed |
| `Input.lua` | Seat/style/restore **Blizzard's own** edit boxes (place, art, layer, rest each a `Core.Lend`), growing input, callbacks; its plate a `Core.Shape` that follows |
| `Join.lua` | Game channels by wish (`options.presence[name]` true/false/nil; `ns.Safe`, not Guarded): joins only where `EnumerateServerChannels` offers it, once per zone (`GetRealZoneText`), leaves when false; a public channel (Zone kind) left once per channel and character, `char.public` made only with no row saved, joins asked for noted by a hook on `JoinPermanentChannel` and two more (Core's guard); looks 8 s after each PEW, 2 s after `CHAT_MSG_CHANNEL_NOTICE`, after lockdown if owed, at once on a wish; `Join.List` (joined Zone channels by number, then on offer, then wished); the list's ticks `Join.In`, `Join.Flip`; a leave the game refuses (`CHAT_MSG_CHANNEL_LEAVE_PREVENTED`) noted in `kept` for the login |
| `Board.lua` | Full screen windows on Core's board (`Core.Board`, made by `Board.Take(handle)` in `Window.Build`; `Board.layouts`, `Board.panels` = its panels): specs `talks`/`friends`/`guild`/`chat` (the chat's own window: `board.own`, column in its body) + one `view:<id>` per chat view (parts' `Build/Show/Size/Search` behind `ns.Safe`, `least`; guild `present` = `Guild.Size(inside) ~= nil`), first layout `Default` from `Layout.Board` rooms (guild framed with head + edges); `Board.Show(inside, w, h)` → `layouts:Show` rects → `Guild.Hold(body)` → returns `{ talks, chat }` (chat nil without talks → column hidden); `changed` → `Window.Reboard`; `Board.Hide` (→ `Select.Clear`, `Guild.Leave`), `Board.Search`, `Board.Has`; shared `Board.List`/`Fill`/`Row`/`Button`. Part API: `Build(panel)`, `Show(on)`, `Search(text)`, `Size(w, h)`. Layouts kept in `store.board` |
| `Guild.lua` | The guild window held in its board panel's body (in a guild, while the layout has it; reopened by the player → `OnShow` hook → back): whichever `ToggleGuildFrame` opens, found generically (newly shown among `UISpecialFrames` + `UIPanelWindows`, largest, `Guild.LOOK` 0.2 s later; name kept in `store.guildWindow`), never named; held by `Core.Seat` (one per window, `sized` → `Reboard`, `gone` → `dismissed` out of a fight): room handed to `seat:Hold` = its own `seat:Size()` × min(1, body fit) at the body's top middle, in UIParent's units, so the seat's fit keeps exactly that scale; `Guild.Least` = `GUILD_LEAST` × size + edges; `Measure` = `seat:Size()` in the full screen's units; closes what it opened (`HideUIPanel` for a game panel, else `Hide`), also when the layout leaves it no room; out of a fight only; `Try` gives it back on failure |
| `Talks.lua` | Conversations, no frames: `Talks.Add(entry)` from `Heard` (`ns.Safe`) for `entry.with` (whispers; `account` for BN) or `Talks.GROUPS` (PARTY/RAID/INSTANCE_CHAT); keys `W:<PlayerKeyOf>`, `B:<BattleTag>`, `G:<partyGUID>` (one per group joined: `GROUP_JOINED`/`GROUP_LEFT` → `Begin`/`End`, `Talks.current[category]`, kept as `char.talkGroups`; `category`, `members`, `started`, `ended`; kind follows IsInRaid; named `Kind: A, B, C +n`; `Talks.Groups()` for listing); copies of `Log.KEPT` + `stamp`; `talkSize` trim except `Talks.reading`; `MOST` 50; `Send` (SendChatMessage / `C_BattleNet.SendWhisper`), `Writable`, `Account` (by BattleTag), `Save`/`Restore` in `chars[key].talks` (BN messages without name/link) |
| `Conversations.lua` | Full screen panel at the left, all the room the right leaves (`Board.PANELS` talks, `boardTalks`; `Layout.TALKS_MIN`/`TALK_LIST`/`TALK_HEAD`; list width dragged by a grip on the divider, kept in `store.talkList`, bounded by `Layout.TalkList`, applied on release via `Window.Reboard`): `Board.List` with two pinned rows first (`CHAT`, `FEED` while `boardFeed`; `pinned` field, never a talk), then talks; choosing a pinned row hides `mine` (own list + `EditBox`) and calls `Window.Pick("chat"/"feed")`, a talk `Window.Pick(nil)`; the name line's filter dropdown (`Channels.Shown` ticks or `Feed.Menu`); `Conversations.Chat` (the game's line opened while a talk is chosen, a frame later: empty non-whisper → `Input.Close` + own line focused; whisper to a known talk → that talk; else `CHAT`); `Said` (pinned rows' previews, `Core.Later`); `Relist`; `Part.Size(w,h)` from `Board.Put`; `Talks.added` hook; redrawn by `Window.Repaint`/`Resize` |
| `Select.lua` | Full screen word picking to copy: `Select.Attach(box, list)` (HookScript OnMouseDown/Up; mouse only via `Select.Allow`, the chat's only while full), `FindCharacterIndexAtCoordinate` hit test, ends `{entry, caret}` + places at press time, `Select.Span(entry)` → `Bubble.Mark` on every `Bubble.Init`; copy = hidden focused `EditBox` with the words highlighted (Ctrl+C; `CopyToClipboard` is protected), freed a frame later; `Select.Words` strips markup; `Select.Clear` on `Window.Pick`, `Choose`, `Board.Hide` |
| `Feed.lua` | Chat views (`store.views = { next, list = { { id, name, shows } } }`, first = `TEXT.feed` with `Feed.FIRST`): `Feed.Views/View/Make/Rename/Remove/Flip/Shows/Menu(view)/Last(view)/Unread(view)`; lists `Feed.New(view, parent, top)` with `:Show/Point/Fit/Rewrap/Refill/Added` (own ScrollBox each, `Select.Attach`); `Feed.Added(entry)` feeds all lists and, for views with no list shown, counts unseen messages and their colour per view, this session only (`Feed.Unread`; never kept with the view); `Feed.Refill(view?)`, `Feed.Rewrap()`. Board windows `view:<id>` (Board.lua `View`: list in body, filter dropdown on head); conversations' page has one list pointed at the chosen view |
| `Friends.lua` | Friends panel (as wide as the guild window above it, `Friends.Size` → tabs anew): head (`Contacts.Account`), tabs `Friends`, `Allies`, `Requests`, `Raid`, `Quick`, `Finder` (a view each, `Usable`/`Label`), search box and filter (dropdown doors behind `ns.Guard`); a list made on first show, only the one shown listens; `Relabel` (`Core.Later`) nothing before the panel exists; the ignore list in the friends' place |
| `Contacts/Contacts.lua` | What the lists share: the game's colours and status icons, `Status` (away before busy, as the game's), `Ago`, `StatusMenu`, `Tell`, `NameOf(unit)` (Forever: `Core.FullName`, else Name-Realm), `Targeted()`, `Mark`, `Divider`, `Entry` |
| `Contacts/Account.lua` | Head: your status (`C_BattleNet.SetAFK/SetDND`), BattleTag, friends online, contacts menu (broadcast `SetCustomMessage`, ignore list) |
| `Contacts/Friends.lua` | The friends list: `BNGetNumFriends`/`C_BattleNet.GetFriendAccountInfo`/`GetFriendGameAccountInfo`, `C_FriendList`; game order (favourites, online, offline); click selects, `Contacts.Tell`, `FriendsFrame_ShowDropdown/ShowBNDropdown`; invite by `GetDisplayedInviteType` (`C_BattleNet.InviteFriend`, `BNRequestInviteFriend`), refusals as the game's; filter ticks → `Changed` |
| `Contacts/Requests.lua` | Requests (`BNGetNumFriendInvites`, `C_BattleNet.GetFriendInviteInfo`): Accept, Decline (`ns.Safe`), Block Invites only with a known `friendLevel` not `Title`; add line (`BNSendFriendInvite` / `SendTitleFriendInviteByName` / `C_FriendList.AddFriend`), the target by `Contacts.Targeted` |
| `Contacts/Ignored.lua` | Ignore list (`C_FriendList.GetIgnoreName`/`DelIgnoreByIndex`/`AddIgnore`, the target by `Contacts.Targeted`) and blocked invites (`BNGetBlockedInfo`, `C_BattleNet.SetBlocked`) |
| `Contacts/Allies.lua` | Recent allies (`C_RecentAllies`; never asked for, waits for the game's data), game menu `RECENT_ALLY`, filter by status and activity (`SearchRecentAllies`) |
| `Contacts/Raid.lua` | Raid groups (`GetRaidRosterInfo`), drag to swap/move (`SwapRaidSubgroup`/`SetRaidSubgroup`, leader or assistant), right click a menu of our own (whisper, `C_PartyInfo.PromoteToLeader`/`PromoteToAssistant`/`DemoteAssistant`/`UninviteUnit` by the game's checks; never the game's `RAID` menu: its Set Focus is protected), Raid Info (saved instances, extend) |
| `Contacts/Quick.lua` | Quick Join (`C_SocialQueue`): groups, roles (`GetLFGRoles`), `RequestToJoin` |
| `Contacts/Finder.lua` | Group finder, the friends panel's last tab (vanilla style, Camelot): `C_LFGList.Search` only on a click (restricted; "searching" once it returned, dropped when the tab is shown again), reads `GetFilteredSearchResults` with every field `Core.Plain` (a listing with hidden state/size/age left out); in chat lockdown the last rows stay, its line says so (`ADDON_RESTRICTION_STATE_CHANGED` → anew); whisper leader, invite solo; listing stays the game's (`ns.OpenFinder(1)`) |
| `Window.lua` | A Core window of kind `screen` (`first.dock = "BOTTOMLEFT"`), list in `handle.inside` (no top bar), scroll provider, bottom alignment, follow state, `Core.Hover` for the mouse, slide by `Core.Motion.Slide`; `Window.Follow` (ours or away as `options.window` says), `Show` opens through `handle:Open()` |

Speakers' class/tie caches share a 500-entry cap. Ties clear on friend/guild/group changes;
priority friend → guild → raid/party. Filtering preserves the log; `store.mute[group] = true`
hides it from the provider, so unmuting restores earlier messages. Channels use `CHANNEL:<word>` (`Channels.Group`: the game's shortcut, not the number). `mute` starts with `REWARDS` and General, Trade, TradeLocal, LocalDefense, Services.

## View and input traps

The chat stands in `column` (child of the window; the list, its scroll bar and the write button are its
children): all of `handle.inside`, or `board.chat` while standing full (`Lay` in `Placed`; panels go in
`Filled(false)`); with the conversations `board.chat` is their part beside the list, and `Shows()` (`picked`,
set by `Window.Pick`) hides the column for a talk or shows the feed's list in it. `Window.Room` tells
`Feed.Room` and, while a talk is chosen, `Conversations.Chat`. Measure with `Area()`, never the window's
size. Tests: the stand-in makes one list per `WowScrollBoxList` (`boxes`; `box` is the chat's, the first;
`window` is `box._parent._parent`).
Use Core Window for movement/sizing/docking; default 380×260 docked bottom left, minimum 180×130, MEDIUM level 100.
Rows need height before creation: one invisible ruler measures wrapping, caches by width/font epoch,
and rendering uses that same width. Rewrap after resizing ends, not every drag tick. Bottom padding
keeps newest messages low; following new messages stops when the user scrolls up.
A fade is kept on the message (`Fade.lua`: from/to/since/span, `Fade.Alpha`) and drawn by an `OnUpdate` that
runs only while a row fades; fade in 0.4 s, fade out 1 s (options, 0..2 s). Only the list's slide is an
animation group (`Core.Motion.Slide`). The mouse wheel or writing reveals messages, the mouse's coming does
not (it only shows the button for the line); the window takes mouse motion only
(clicks go through): `Core.Hover` starts at its `OnEnter` and looks every 0.2 s until the mouse has gone
(the button for the line to write in shown meanwhile); nothing runs while the mouse is away. Back at the
newest message with the mouse away, the messages fade again; none fades while the window stands full
(`FadeAfter` asks `edge.full`). Top-cut rows hide their inner body so fading row alpha remains independent.

Native edit boxes preserve slash commands, history, whispers and secure action execution.
`Input.Take`/`Release` keeps state in tables keyed by edit box; restores anchors, look, layers and
resting alpha/mouse. It grows to six lines and replaces pasted newlines before send.
Listen to `ChatFrame.OnEditBoxShow/Hide/FocusGained/PreSendText`. For IM style, after native
`Deactivate`, rest via alpha 0 and mouse disabled. **Do not call native edit box Hide:** its OnHide
mutates secure chat state under addon taint. Chat picker still calls native SetChatType/StickyType/
ChannelTarget and ActivateChat; the taint log (`/console taintLog 1`) shows its effect.

`Native.Hide` reparents windows/dock/tabs/minimized buttons but keeps logging active. On restoration,
only return a frame if its parent is still ours: Blizzard may move it meanwhile. Temporary whisper
and minimized windows are hooked. `Window.Native` must show native chat during messaging lockdown,
even when `showNative=false`; recheck restriction events a frame later. Secret texts are dropped.

Saved `modules.Social` (moved from `modules.Chat` once, Core `Saved.lua`): `options` (with `window`, `mute`),
`place={x,y,width,height,dock,full,native}` (`native` true exactly while `options.window` is off: `Window.Follow`); per character
(`chars[key]`) `history`, `historyVersion`.
Defaults: history on (100 messages kept); system/creature/addon messages on, channel joins off; fade on,
after 60 s (5..300), out 1 s, in 0.4 s, floor off (30%); slide 0.3 s; text 14 (10..24); bubble
transparency 50% (0..100), solid 26262B or a game tile; every game channel left to the game (no wish);
short names on; **native chat shown alongside ours by default**.
`/sane social` (or `/sane chat`) and the key toggle; `reset` shows it and puts it back at its first place and size.
Tests: `dev/tests/social.lua`.
