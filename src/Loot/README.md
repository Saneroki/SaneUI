# Sane UI: Loot

**Status:** built: the loot window on a page of the journal, things taken at once by your own rules, a loot list, a master looter's menu, a page that finds room when your bags are full, cards for your group's rolls with who chose what, a feed of what you and your group receive · **Since:** 2026-10-28 · **Addon:** `SaneUI_Loot` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Stands in for the game's loot window and its roll frames. What a corpse, a chest or a catch holds is a page of
Sane UI's journal at the mouse: a line a thing, its picture in a pencil slot, its name in its quality's colour, a
note under it (how it binds, its kind, a quest's). A click takes it; your rules take coins, quest items, the things on
your own loot list and everything up to a quality at once, never what binds when picked up. As master looter a click
gives the thing away from a menu. With your bags full a page beside the window weighs the thing against the cheapest
thing you carry. Your group's rolls are paper cards (Need, Greed, Pass; how many chose each and who), and what you and
your group receive rises over the world. When it fails, the game's own loot window and roll frames are back.

## How to use
- **Switch it on or off:** tick or untick *Loot* under *Sane UI* in the game's addon list (the game needs a restart
  when it was not in the list before). Its options: Esc > Options > AddOns > Sane UI > *Loot*.
- **The loot window** opens where the mouse is, its first line under it (*At the mouse*; off: where you placed it in
  Edit Mode). Its title is what you loot: the corpse's name, *Fishing*, else *Loot*.
  - **Click** a line: the thing is taken, as in the game's window (the game asks first for a thing that binds when
    picked up). **Shift-click** links it in the chat, **Ctrl-click** tries it on.
  - **Alt-click** puts the thing on your **loot list**, or takes it off: what is on it is taken at once wherever it
    drops. `/sane loot list` names what is on it.
  - **Take all** at the foot takes every thing a click could take.
  - A thing that is not yours to take now (locked to a roll) is faint and says so.
  - Close it with its X or Esc: the loot closes with it. Everything taken, it closes by itself.
  - Many lines scroll with the mouse wheel.
- **Taken at once,** as the loot opens and without a click (options, *Taken at once*): *Coins and currencies* (on),
  *Quest items* (on: things a quest wants, and things that begin one), *Your loot list* (on), *Everything up to* a
  quality (Nothing more at first; Poor to Rare). Never a thing that binds when picked up: the game would ask. When
  everything is taken at once the window does not open. The game's own Auto Loot (Esc > Options > Controls) takes
  everything itself; the window then shows only what is left a moment later (bags full, a thing locked to a roll).
- **Master looter:** a thing of the group's quality or better is yours to give, not to take: a click opens a menu
  beside its line with the thing, *Give to* and everybody who may have it (in a raid under their classes, each name
  in its class's colour), and *Request Roll*. A name chosen, the game asks yes or no, then gives it. *Take all* leaves
  those things alone.
- **Bags full** (*Make room for loot*, on): with your bags full while the loot window holds a thing, a page of paper
  hangs out from the window's right edge: *This one*, the thing with what a vendor pays for it, and *Make room*, the
  thing of yours worth the least at a vendor; the pencil arrows go through the next cheapest ("2 of 9"). Click it
  (or drag it) to pick it up, then drop it on the world: the game asks before it is gone. Never offered: what a vendor
  will not take, a quest's things, epics and better. The page goes once there is room.
- **Group rolls** (*Sane UI's roll cards*, on): when your group rolls for a thing, a card of paper: its picture and
  name, then the choices the game offers as pencil boxes (*Need*, *Greed* or *Transmog*, *Disenchant* where offered,
  *Pass*); a choice the game refuses is faint, its reason in the tooltip. A pencil line along the card's foot shrinks
  with the time left. *Who chose what* (on): each choice counts how many chose it ("Greed 2"); the mouse on it names
  them. A modified click on the picture links it or tries it on. The cards stack up from their place (Edit Mode,
  *Group rolls*). Off: the game's own roll frames.
- **Loot feed** (*What you receive*, on): each thing you receive rises over the world for a few seconds, its picture,
  name, how many and (faint) how many you carry; the same thing again adds to its line. *Coins* (on): money you loot.
  *Your group's* (on): what the others receive, named, from the quality *From* (Uncommon at first). Placed in Edit
  Mode (*Loot feed*).
- **Edit Mode** (Esc > Edit Mode): the loot window (while *At the mouse* is off), a roll card and the feed show there
  to be placed.
- `/sane loot try` shows a roll card and the feed as they will look.

## Technical details
- **The game's parts** (`Game.lua`): the game's loot window (`LootFrame`) no longer hears `LOOT_OPENED`, so it never
  opens and never takes a place among the game's panels; what else it hears it still hears. The game's questions are
  its event handlers', not the window's: `LOOT_BIND_CONFIRM` (a thing that binds), `CONFIRM_LOOT_ROLL`,
  `CONFIRM_DISENCHANT_ROLL`, so taking and rolling from our parts asks as the game's would. The roll frames
  (`GroupLootContainer`) are lent to a hidden frame of ours (`Core.Lend`): the game adds, times and removes its rolls
  by its own code, unseen, so switched back they stand right. Nothing of Blizzard's is written, no function
  replaced. Switched off or standing down (`ns.GiveBack`): `LOOT_OPENED` registered again, the container's parent
  given back, ours closed.
- **Reading the loot** (`Slots.lua`): `GetNumLootItems`, `GetLootSlotInfo`, `GetLootSlotType` (`Enum.LootSlotType`),
  `GetLootSlotLink`; a currency through `CurrencyContainerUtil.GetCurrencyContainerInfo` as the game's window does;
  an item's kind, where it is worn, its vendor price and how it binds from `C_Item.GetItemInfo`. Every value through
  `Core.Plain`. `Slots.Wanted` is the rules, `Slots.Note` the note under a name.
- **The window** (`Window.lua`, `Row.lua`): `Core.Journal.Dress` (the journal's window), a scroll frame, rows made once
  and used again; Take all a pencil box (`Journal.Box`). Placed by `Core.Window.New` (key `windowPlace`, no title bar:
  Edit Mode only); at the mouse its first line's middle under the cursor, clamped to the screen. `LOOT_OPENED` (the
  rules take, then the window or a check `Core.Later` 0.4 s after for Auto Loot and for rules that took everything),
  `LOOT_SLOT_CLEARED` (the last one closes the loot), `LOOT_SLOT_CHANGED`, `LOOT_CLOSED`, `UI_ERROR_MESSAGE` with
  `ERR_INV_FULL` (what the rules could not take shows). Hidden, it closes the loot (`CloseLoot`). Esc by
  `Core.Escape`. The game's sounds for a container opened and a catch (`Core.Sound`).
- **Master looter** (`Master.lua`): `C_PartyInfo.GetLootMethod` (`Enum.LootMethod.Masterlooter`, the party's or the
  raid's index of the looter), `GetLootThreshold`, `GetMasterLootCandidate(slot, i)`; the game's menu
  (`MenuUtil.CreateContextMenu`), `Core.Confirm`, `GiveMasterLoot`, `DoMasterLootRoll`. The thing is not
  `LootSlot`ted, so the game's own master loot list (`OPEN_MASTER_LOOT_LIST`) does not come.
- **Bags full** (`Full.lua`): free room only in bags for any thing (`C_Container.GetContainerNumFreeSlots`, its
  family 0); the bags' things from `C_Container.GetContainerItemInfo` and `GetContainerItemQuestInfo`, the vendor
  price from `C_Item.GetItemInfo`; `Full.Rank` the cheapest stack first. A click picks the thing up
  (`C_Container.PickupContainerItem`, nothing while the cursor holds a thing); Sane UI destroys nothing:
  `DeleteCursorItem` has restrictions, and the game's own drop asks first. `BAG_UPDATE_DELAYED` looks again.
- **Roll cards** (`Rolls.lua`): `START_LOOT_ROLL` (rollID, time), `CANCEL_LOOT_ROLL`, `CANCEL_ALL_LOOT_ROLLS`;
  `GetLootRollItemInfo` (what may be chosen, the reasons `LOOT_ROLL_INELIGIBLE_REASON<n>`), `GetLootRollItemLink`,
  `GetLootRollTimeLeft` every 0.1 s while a card shows, `RollOnLoot` with the game's roll kinds (Pass 0, Need 1, Greed
  2, Disenchant 3, Transmog 4). Switched on, the rolls already open get cards (`GetActiveLootRollIDs`,
  `C_Loot.GetLootRollDuration`). Who chose what from `CHAT_MSG_LOOT` (`Chat.Rolled`), on the card of that item whose
  chooser has not chosen yet. Placed by `Core.Window.New` (key `rollsPlace`).
- **The feed** (`Feed.lua`): `CHAT_MSG_LOOT` (`Chat.Received`), `CHAT_MSG_MONEY` (`Chat.Money`), `CHAT_MSG_CURRENCY`
  (`Chat.Currency`, `C_CurrencyInfo.GetCurrencyInfoFromLink`); how many carried by `C_Item.GetItemCount`. Eight lines
  at most, 5 s each, then a 1.2 s fade; in Edit Mode they stand. Placed by `Core.Window.New` (key `feedPlace`).
- **The game's sentences** (`Chat.lua`): each of the game's strings (`LOOT_ITEM_SELF_MULTIPLE`, `LOOT_ROLL_GREED`,
  `YOU_LOOT_MONEY`, `GOLD_AMOUNT`, `CURRENCY_GAINED`...) made once into a pattern: its `%s` and `%d` (and `%1$s`)
  marked, the rest made plain, the marks made captures. A string the client lacks is left out.
- **Settings** (`Loot.lua`, `Core.Options`): `window`, `atMouse`, `notes`; `takeCoins`, `takeQuest`, `takeKept`,
  `takeUpTo` (-1 nothing, else a quality); `kept` (the loot list: item ID = true, no control); `rolls`, `tally`;
  `feed`, `feedMoney`, `feedGroup`, `feedQuality`; `full`. The places: `windowPlace`, `rollsPlace`, `feedPlace` in
  `Core.Store("Loot")`.
- **Forever and Retail:** one way for both; every function asked for exists in both clients (the Forever-Retail
  lookup). Transmog is offered where the game offers it (Retail). Master loot only where the game has it.
- **Tests:** `dev/tests/loot.lua`.

## Files
| File | What it does |
| --- | --- |
| `SaneUI_Loot.toc` | The addon: its files in order |
| `Loot.lua` | The module's table, words, sizes, settings, `/sane loot`, standing down |
| `Slots.lua` | The open loot as plain lines; the rules that take at once; the note under a name |
| `Chat.lua` | The game's sentences about loot read back into their parts |
| `Game.lua` | The game's loot window and roll frames kept out of the way, and given back |
| `Row.lua` | One line of the loot window |
| `Window.lua` | The loot window |
| `Master.lua` | The master looter's menu |
| `Full.lua` | The page that makes room when the bags are full |
| `Rolls.lua` | The roll cards |
| `Feed.lua` | What you and your group receive, over the world |

## History
- 2026-10-28 — Built (Saneroki asked for a loot module with its own loot window): the window on the journal's page,
  the rules, the loot list, the master looter's menu, the bags-full page (board #34's note), the roll cards with who
  chose what, the feed, Edit Mode places, `/sane loot`.
