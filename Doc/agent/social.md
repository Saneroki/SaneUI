# Social

Was the Chat module (`SaneUI_Chat`, `src/Chat`) until 2026-10-16; today it holds the chat window only.

## Message pipeline

`Social.lua` receives events → `Log.Read` (plain message, no frames) → `Log.Add` → `Log.added`
→ `Window.lua` filtered provider → recycled `Bubble.lua` rows. Native `DEFAULT_CHAT_FRAME.AddMessage`
hook captures printed notes only when the fifth argument has no chat kind, avoiding event duplicates.
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
| `Join.lua` | Game channels by wish (`options.presence[name]` true/false/nil; `ns.Safe`, not Guarded): joins only where `EnumerateServerChannels` offers it, once per zone (`GetRealZoneText`), leaves when false; looks 8 s after each PEW, 2 s after `CHAT_MSG_CHANNEL_NOTICE`, after lockdown if owed, at once on a wish; `Join.List` (joined Zone channels by number, then on offer, then wished) |
| `Board.lua` | Full screen parts (stand full only, built on first show, `ns.Safe` per part): `Board.Show(inside, w, h)` → `Guild.Size` → `Layout.Board(w, h, { friends, talks, guild })` rects → panels → `Guild.Hold`; `Board.Hide` (→ `Guild.Leave`), `Board.Search`; shared `Board.List`/`Fill`/`Row`/`Button`. Part API: `Build(panel)`, `Show(on)`, `Search(text)`, `Size(w, h)` |
| `Guild.lua` | The guild window held at the full screen's top right (`boardGuild`, in a guild): whichever `ToggleGuildFrame` opens, found generically (newly shown among `UISpecialFrames` + `UIPanelWindows`, largest, `Guild.LOOK` 0.2 s later; name kept in `store.guildWindow`), never named; held by `Core.Seat` (one per window, `sized` → `Reboard`, `gone` → `dismissed` out of a fight): room handed to `seat:Hold` = its own `seat:Size()` × the layout's scale (`rect[5]`) at the layout room's top right, in UIParent's units, so the seat's fit keeps exactly that scale (the layout's room is whole units); `Measure` = `seat:Size()` in the full screen's units; closes what it opened (`HideUIPanel` for a game panel, else `Hide`), also when the layout leaves it no room; out of a fight only; `Try` gives it back on failure |
| `Talks.lua` | Conversations, no frames: `Talks.Add(entry)` from `Heard` (`ns.Safe`) for `entry.with` (whispers; `account` for BN) or `Talks.GROUPS` (PARTY/RAID/INSTANCE_CHAT); keys `W:<PlayerKeyOf>`, `B:<BattleTag>`, the group; copies of `Log.KEPT` + `stamp`; `talkSize` trim except `Talks.reading`; `MOST` 50; `Send` (SendChatMessage / `C_BattleNet.SendWhisper`), `Writable`, `Account` (by BattleTag), `Save`/`Restore` in `chars[key].talks` (BN messages without name/link) |
| `Conversations.lua` | Full screen panel at the left, all the room the right leaves (`Board.PANELS` talks, `boardTalks`; `Layout.TALKS_MIN`/`TALK_LIST`/`TALK_HEAD`): `Board.List` with two pinned rows first (`CHAT`, `FEED` while `boardFeed`; `pinned` field, never a talk), then talks; choosing a pinned row hides `mine` (own list + `EditBox`) and calls `Window.Pick("chat"/"feed")`, a talk `Window.Pick(nil)`; the name line's filter dropdown (`Channels.Shown` ticks or `Feed.Menu`); `Conversations.Chat` (the game's line opened while a talk is chosen, a frame later: empty non-whisper → `Input.Close` + own line focused; whisper to a known talk → that talk; else `CHAT`); `Said` (pinned rows' previews, `Core.Later`); `Relist`; `Part.Size(w,h)` from `Board.Put`; `Talks.added` hook; redrawn by `Window.Repaint`/`Resize` |
| `Feed.lua` | Second chat, a pinned row of the conversations: `options.split` ticks (`Channels.Split/FlipSplit`, `Feed.Menu`), its list made in the window's `column` on first `Feed.Show(on, column)`, bottom over the chat's line (`Feed.Room`), same `rowWidth` as the chat (`Feed.Fit`), told by `Log.added`; `Feed.Last`; no fade/slide |
| `Friends.lua` | Friends panel (as wide as the guild window above it, `Friends.Size` → tabs anew): `BNGetNumFriends`/`C_BattleNet.GetFriendAccountInfo`, `C_FriendList`; game order; click selects, `ChatFrameUtil.SendTell/SendBNetTell`, `FriendsFrame_ShowDropdown/ShowBNDropdown`, `FriendsFrame_InviteOrRequestToJoin` |
| `Contacts/Finder.lua` | Group finder, the friends panel's last tab (vanilla style, Camelot): `C_LFGList.Search` only on a click (restricted), reads `GetFilteredSearchResults`; whisper leader, invite solo; listing stays the game's (`ns.OpenFinder(1)`) |
| `Window.lua` | A Core window of kind `screen` (`first.dock = "BOTTOMLEFT"`), list in `handle.inside` (no top bar), scroll provider, bottom alignment, follow state, `Core.Hover` for the mouse, slide by `Core.Motion.Slide`; `Window.Follow` (ours or away as `options.window` says), `Show` opens through `handle:Open()` |

Speakers' class/tie caches share a 500-entry cap. Ties clear on friend/guild/group changes;
priority friend → guild → raid/party. Filtering preserves the log; `store.mute[group] = true`
hides it from the provider, so unmuting restores earlier messages. Channels use `CHANNEL:<number>`.

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
animation group (`Core.Motion.Slide`). Hover/writing reveals messages; the window takes mouse motion only
(clicks go through): `Core.Hover` starts at its `OnEnter` and looks every 0.2 s until the mouse has gone
(the button for the line to write in shown meanwhile); nothing runs while the mouse is away. Back at the
newest message with the mouse away, the messages fade again. Top-cut rows hide their inner body so fading
row alpha remains independent.

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
