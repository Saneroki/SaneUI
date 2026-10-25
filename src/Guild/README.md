# Sane UI: Guild

**Status:** first views · **Since:** 2026-10-20 · **Addon:** `SaneUI_Guild` · **Plan:** [Doc/ideas/Guild.md](../../Doc/ideas/Guild.md)

## TL;DR
Everything a guild needs in one window, on Social's full screen: the guild's crest and name, tabs for the overview,
the guild, quests, dungeons, loot, professions, the raid and the officers, and the views behind them. Built so far:
the window with all its tabs, the **overview** (who is where, the guild's news, its chat, the race to the highest
level), the **roster** and **everybody's gear**. What members share with the guild (now: who their characters are,
what they wear, their professions) is kept on this computer only, per guild, and only while each player's switch
is on. The other views say they come later.

## How to use
- **Switch it on or off:** tick or untick *Guild* under *Sane UI* in the game's addon list. A new addon: the game
  must be restarted once.
- **Open it:** your guild key (the game's, J by default), or `/sane guild`. With Social on, it opens Social's full
  screen with the guild window in it (in the layout chosen; if that layout lacks it, it is put in beside the largest
  window there). Without Social, or with the switch *On Social's Full Screen* off, it is a window of its own: moved
  by its title bar, sized in Edit Mode, closed by Esc, its place and size kept. The game's micro menu button still
  opens the game's own guild window, and so does *The Game's Guild Window* on the roster. Outside a guild nothing
  opens (`/sane guild` says so; the guild key opens the game's own window, where a guild is found).
- **The head:** the guild's own emblem in its ring (the game's tabard), the guild's name and realm, how many are
  online, when the guild last answered (*Synced 2 min*); the gear opens the options page *Guild*; *Sync* asks the
  guild for what is newer (once a minute at most) and the game for the roster.
- **The tabs:** *Overview*, *Guild* (*Roster*, *Equipment*, *Guild Bank*, *Handbook*), *Quests*, *Dungeons* (*Runs*,
  *Together*), *Loot* (*Session*, *History*, *Wishlist*, *Rules*), *Professions*, *Raid* (*Plan*, *Numbers*),
  *Officers* (*Mains and Alts*, *Promotions*, *Notices*; only for the guild's officers). The tab and view last chosen
  are kept.
- **Overview:** at the left the quest requests over the planned runs (to come); in the middle the guild's news (who
  joined, left, was promoted or demoted, reached a level, as noted since Sane UI first read the roster) over the
  guild's chat since you logged in, with a line to write in it (Enter sends); at the right who is where (the
  members online by zone, the zone with most first, their class icons), what members offer the guild (to come),
  and the race to the highest level: the first three on a podium, the next seven under it. On a narrow screen the
  right column folds under the left.
- **Roster:** the guild's head (name, members and online, the message of the day: click it to change it if your
  rank may; *Invite to Guild*, *Guild Information* in its tooltip, *The Game's Guild Window*). The members: class icon,
  name over class and rank, level, rank, zone (*here* where you are), note, when last online; online and offline
  under rows that fold them (a click). A click on a column's head sorts by it, again the other way, a third time
  back to online first by rank. The search box finds every word in name, notes, zone and rank. Click a member: at
  the right its name, level, class, where it is, since when in the guild (for those who joined after Sane UI first
  read the roster), its rank with *-* and *+* (demote and promote, where your rank may: the next rank down and up are
  named under them), its note and the officer's note (click to change, where your rank may), its last four events in
  the guild, *Whisper* and *Invite*. A right click on a member: *Whisper*, *Invite*.
- **Equipment:** at the left every member, those who share their gear with their item level, highest first (click a
  column's head to sort by another), searched by name. At the right the one chosen: name, level, class, rank, when
  it was shared (*not live*) or *Your own, live*, its item level large, its slots (the game's empty-slot pictures, the
  item's icon in its quality's colour, its item level; the item's tooltip under the mouse; the ranged slot only where
  the game's own paper doll has one, not in Retail) around a figure: yours as
  you stand; another member's gear is dressed on your own figure, as in the game's dressing room (this client cannot
  show another's race). A member that shares nothing yet says so.
- **Sharing** (options page *Guild*, section *Sharing with the Guild*): *Share My Gear and Professions* (on): your
  guild's Sane UI sees who your characters are, what they wear and their professions. Nothing goes to anybody outside
  your guild, and nothing into the data Sane UI ships. Off: nothing of it is sent, and nobody who asks gets it.
- **Settings:** *On Social's Full Screen* (on), *The Guild Key Opens It* (on), *Share My Gear and Professions* (on).
- **Keys:** in the game's key bindings, section *Sane UI*: *Open or close the guild window*. The guild key itself
  runs it while *The Guild Key Opens It* is on and you are in a guild; outside one it opens the game's own window,
  where a guild is found.

## Technical details
- **The page** (`Page.lua`) is one frame, made the first time the window opens, that moves between its two homes
  (`Page.Into`): the body of Social's board panel, or `window.inside` of the window of its own. It listens to Core's
  guild data (`Core.Data.Guild.OnChange`) once shown; a change redraws the head and the view on show once a frame at
  most (`Core.Later`), a hello heard only the head. While it shows, the game is asked for the roster anew whenever it
  lets (`Guild.Watch`, as the game's own guild window does). Lists are refilled where they were scrolled to. A view
  (`Views/`) is a table: `Build(frame)` the first time it is shown, `Show(on)`,
  `Refresh()`, `Title()` (the line beside its title), `Search(text)`. `Views.Later(name)` makes a view still to come.
- **Its sections** (`Page.lua` `Sections`): each a tab of the game's tab system (`TabSystemTemplate` with
  `TabSystemTopButtonTemplate`, as Core's windows), its views under the game's small tabs (`MinimalTabTemplate`) where
  it has several; *Officers* shown only while `Guild.Rights().officer`.
- **Where it stands** (`Window.lua`): at the load the guild window is offered to Social's board (`Core.Board.Offer("Social",
  spec)` with the key `guild`): Social's board lists it in place of its own guild window and Social then leaves the
  game's guild window alone (`Core.Board.Offered`). `Window.Toggle` opens Social's full screen with it
  (`Core.Board.Open`), closes it when it shows (`Core.Board.Close`), and falls back to the window of its own
  (`Core.Window.New`, kind `panel`) where no board answers; outside a guild it opens nothing and says so (a window of
  its own still open closes). The switch *On Social's Full Screen* withdraws the offer (`Core.Board.Withdraw`).
- **The guild key** (`Keys.lua`, `Bindings.xml`): override bindings on the keys of the game's `TOGGLEGUILDTAB` run our
  `SANEUI_GUILD_TOGGLE` while the player is in a guild, set out of a fight (or after it), again when the bindings
  change or the player joins or leaves a guild, taken away when the switch is off or the module stands down.
- **The data** is Core's (`src/Core/Data/Guild.lua`, `Doc/guides/data.md` *Guild records*): the roster, its history,
  members' records (`card`), this character's card (`Guild.Card()`), what the player may do (`Guild.Rights()`). The
  module tells Core what the player allows (`Guild.Allow("card", on)`) and starts it (`Guild.Start()` at the login).
- **The game's own calls** for the roster's actions: `C_GuildInfo.Promote`, `Demote`, `Invite`, `SetMOTD`, `SetNote`
  (by the member's GUID; `GuildRosterSetPublicNote`/`OfficerNote` by its index where the client lacks it), the party's
  `C_PartyInfo.InviteUnit`, the chat's `SendTell`; none in a fight (the status line says so). What the game refuses
  is noted by Core (`ADDON_ACTION_BLOCKED`).
- **Pictures** (`Art.lua`): by name, placeholders of the game's art until our own are drawn (`Doc/ideas/Guild.md`,
  *Pictures*; quick sketches of the look: `dev/imagegen/sets/guild/`). Everything else is the game's: insets
  (`InsetFrameTemplate`), buttons (`UIPanelButtonTemplate`), search boxes (`SearchBoxTemplate`), lists
  (`WowScrollBoxList`, `MinimalScrollBar`), class circles, paper-doll slots, `DressUpModel`, the gear, status icons.
- **Forever and Retail:** the same module in both; the one difference is the doll's ranged slot
  (`Equipment.Weapons`, as the game's `C_PaperDollInfo.IsRangedSlotShown`).
- **Words** are in `ns.TEXT` (`Guild.lua`), the game's own strings where it has one (`Core.Word`).
- **Cost:** at rest only Core's reading of the roster after the game says it changed (by the scheduler: never in a
  fight or while the game restricts addons). The page and its views are made when first opened; a view redraws only
  while on show; the overview keeps the guild's chat since login (100 lines) whether shown or not.
- **Falling back** (`ns.GiveBack`): the guild key back to the game's first, the window closed, the offer withdrawn
  (Social holds the game's guild window again), the roster no more asked for; each step on its own.
- **Tests:** `lua5.1 dev/tests/guild.lua`: the wire (parts numbered wrongly, a block that does not fit), the guild's
  records (a roster that shrinks, a fight, asks and answers, a switch turned off, Sync), a window offered to a board,
  what the views show, the page with every tab, the guild key (in a guild and outside one), Esc on the window of its
  own, the window and its tabs in Retail (`W.Play`) with the doll's weapons there, standing down.

## Files
| File | What |
| --- | --- |
| `SaneUI_Guild.toc` | The addon: its files in order |
| `Guild.lua` | The module: words, settings, starting, standing down |
| `Layout.lua` | Sizes and spacing, the overview's columns, how long ago (no frames) |
| `Art.lua` | The module's pictures by name: placeholders of the game's art for now |
| `Kit.lua` | Insets, panels, tables, class icons and colours, the guild's crest |
| `Page.lua` | The page: head, tabs, view title, small tabs, status line; the views behind them |
| `Views/Overview.lua` | The overview: who is where, news, guild chat, the race |
| `Views/Roster.lua` | The roster and the member chosen |
| `Views/Equipment.lua` | Everybody's gear on a paper doll |
| `Views/Later.lua` | A view still to come |
| `Window.lua` | Where the page stands: Social's full screen or a window of its own |
| `Keys.lua`, `Bindings.xml` | The guild key opening ours |

## Not there yet
Every view that says it comes later (Doc/ideas/Guild.md, *Build order*); the pictures of our own; the player's page
(*Player*); news cards; the notification strip at the minimap.

## History
- 2026-10-25 — Retail: the doll without the ranged slot, as the game's own.
- 2026-10-20 — The module (Saneroki): the window with all its tabs on Social's full screen or alone, the overview, the
  roster, everybody's gear; the guild key; sharing of the character card with the guild.
