# Sane UI: Loot

**Status:** built: the loot window (a line a thing on a plate with round corners trimmed in its quality's colour, its worth, the game's green arrow on an upgrade, an A to take it at once from now on, Link and Close at its foot), things taken at once by your own switches as soon as the loot is ready (nothing at first), your word on each item and a list of them in the options, a master looter's menu, a page that finds room when your bags are full, cards for your group's rolls with who chose what, a feed of what you and your group receive · **Since:** 2026-10-28 · **Addon:** `SaneUI_Loot` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Stands in for the game's loot window and its roll frames. What a corpse, a chest or a catch holds stands at the
mouse with no window round it: a line a thing on a dark plate with round corners, trimmed in its quality's colour (a quest's in gold), a green arrow on what would make your character better,
its picture, its name, its kind and what a vendor pays for it, and an A; Link and Close at the foot. A click takes it
and the next comes under the mouse. What is taken at once, as soon as the loot is ready, is yours to say: nothing at
first, then everything or kinds (coins, currencies, quest items, trade goods, gear, consumables, junk), and over them
your word on an item (its A, or the options' list *Your items*). As master looter a click gives the thing away from a
menu. With your bags full a page beside the window weighs the thing against the cheapest thing you carry. Your
group's rolls are paper cards (Need, Greed, Pass; how many chose each and who), and what you and your group receive
rises over the world. When it fails, the game's own loot window, its Auto Loot and its roll frames are back.

## How to use
- **Switch it on or off:** tick or untick *Loot* under *Sane UI* in the game's addon list (the game needs a restart
  when it was not in the list before). Its options: Esc > Options > AddOns > Sane UI > *Loot*, in four tabs: *Loot
  window*, *Taken at once*, *Rolls and feed*, *Your items*.
- **The loot window** opens where the mouse is, its first line's picture under it (*At the mouse*; off: where you
  placed it in Edit Mode). No window round it: a line a thing, each on a dark plate half see-through with smooth
  round corners and a thin trim in its quality's colour (a quest's things, and things that begin a quest, in the
  game's gold). In it the thing's picture on a small round plate trimmed in that colour, how many, its name in that
  colour; under the name, small, its kind and how it binds,
  and at the right what a vendor pays for all of it (*A line under each name*, on); at the top right an **A**. At the
  foot two buttons on the same round plates, **Link** and **Close** (Close alone when there is nothing to link).
  - **The green arrow** (the game's own, as its bags show it) on a picture: the thing would make your character
    better: gear you can wear now (as the game says, and of your level) where you wear nothing, or with a higher item
    level than what you wear there (of two rings or trinkets, the weaker one); never armour lighter than what you
    wear there, nor an off hand while you hold a two-handed weapon. Its tooltip says which.
  - **Click** a line: the thing is taken, as in the game's window (the game asks first for a thing that binds when
    picked up). The lines close up, and the next thing stands where the taken one stood, under the mouse; the last
    one taken, the window comes down a line so the one before is under it. Click and click again where you are.
    **Shift-click** links it in the chat, **Ctrl-click** tries it on.
  - **The A** (or **Alt-click**): the thing is taken at once wherever it drops from now on (the A turns gold), and is
    taken now; on the list, the A takes it off. `/sane loot list` names the items you gave a word on.
  - **Link** puts the links of the loot's things into the chat box (into the one you are writing in, else it opens
    one): Enter sends them where you write. Sane UI sends nothing itself.
  - A thing that is not yours to take now (locked to a roll) is faint and says so.
  - **Close** or Esc closes it, and the loot with it. Everything taken, it closes by itself.
  - Many lines scroll with the mouse wheel.
- **Always show upgrades** (tab *Taken at once*, on): a thing with the green arrow is never taken at once, whatever
  the switches and your word on it say: it waits in the loot window to be seen.
- **Taken at once** (tab *Taken at once*; every switch off at first): as soon as the game has the loot ready, before
  the window opens, what the switches want is taken, a few things a frame so a big pile goes quickly without flooding
  the game: *Everything*, or kinds: *Coins*, *Currencies*, *Quest items* (things a quest wants, things that begin
  one), *Trade goods* (cloth, herbs, ore, leather, meat, reagents), *Gear* (armour and weapons), *Consumables* (food,
  drink, potions, scrolls, bandages), *Junk* (the grey things). Never by a switch: a thing locked to a roll, or one
  that binds when picked up (the game would ask). Your word on an item goes over the switches: the A (taken) or the
  list *Your items* (taken, or never). When everything is taken at once the window does not open.
- **The game's own Auto Loot** (Esc > Options > Controls) is off while Sane UI's loot window is on, so the switches
  decide; it is set back as it was when the window is switched off. Held Shift while looting still takes everything,
  as the game has it; the window then shows only what is left a moment later (bags full, a thing locked to a roll).
- **Your items** (tab of the options): the things you met in loot of late (the newest first) and those you gave a
  word on, in two parts: *Taken at once* (ticked; at the right why: *your word*, *Everything* or the kind's switch)
  and *Left for a click* (*your word: never* where you said so). A tick changes it for that item alone; a word that
  says what the switches say anyway is dropped. *Forget the rest* clears the things without a word.
- **Master looter:** a thing of the group's quality or better is yours to give, not to take: a click opens a menu
  beside its line with the thing, *Give to* and everybody who may have it (in a raid under their classes, each name
  in its class's colour), and *Request Roll*. A name chosen, the game asks yes or no, then gives it.
- **Bags full** (*Make room for loot*, on): with your bags full while the loot window holds a thing, a page of paper
  stands at the right of the window's lines: *This one*, the thing with what a vendor pays for it, and *Make room*, the
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
- **Edit Mode** (Esc > Edit Mode): the loot window (two lines as they will look, while *At the mouse* is off), a roll
  card and the feed show there to be placed.
- `/sane loot try` shows a roll card and the feed as they will look.

## Technical details
- **The game's parts** (`Game.lua`): the game's loot window (`LootFrame`) no longer hears `LOOT_OPENED`, so it never
  opens and never takes a place among the game's panels; what else it hears it still hears. The game's questions are
  its event handlers', not the window's: `LOOT_BIND_CONFIRM` (a thing that binds), `CONFIRM_LOOT_ROLL`,
  `CONFIRM_DISENCHANT_ROLL`, so taking and rolling from our parts asks as the game's would. The roll frames
  (`GroupLootContainer`) are lent to a hidden frame of ours (`Core.Lend`): the game adds, times and removes its rolls
  by its own code, unseen, so switched back they stand right. The game's Auto Loot (`autoLootDefault`) is lent `0`
  while our window is on, through Core's Sync (`Sync.Lend`, `Sync.Return`): Sync then leaves it alone instead of
  writing the profile's value a moment after the login, and keeps the player's own value in the profile. What it
  was is kept in `lent` the first time too, for the next session's lend; given back only if nobody changed it
  meanwhile. Nothing of Blizzard's is written, no function replaced. Switched off or standing down
  (`ns.GiveBack`): `LOOT_OPENED` registered again, Auto Loot as it was, the container's parent given back, ours
  closed.
- **Reading the loot** (`Slots.lua`): `GetNumLootItems`, `GetLootSlotInfo`, `GetLootSlotType` (`Enum.LootSlotType`),
  `GetLootSlotLink`; a currency through `CurrencyContainerUtil.GetCurrencyContainerInfo` as the game's window does;
  an item's kind, where it is worn, its vendor price, how it binds and its class (`Enum.ItemClass`) from
  `C_Item.GetItemInfo`. Every value through `Core.Plain`. `Slots.Rule` is the rules (the player's word in `kept`,
  then `takeAll`, then `Slots.KINDS` by the game's item classes: Tradegoods and Reagent, Weapon and Armor,
  Consumable, Questitem; junk by quality 0), `Slots.Wanted` whether one takes it, `Slots.Note` the line under a name,
  `Slots.Item(id)` a line for an item by its ID (the list *Your items*).
- **The window** (`Window.lua`, `Row.lua`): no art of its own; a scroll frame, rows made once and used again, each on
  a plate of Core's `Shape` (`Row.Plate`: round corners of `SIZE.radius`, a black fill at half, darker under the
  mouse, a trim of `SIZE.trim` in `ITEM_QUALITY_COLORS`, the game's gold `NORMAL_FONT_COLOR` for a quest's thing:
  `Slots.Quest`), laid out for the window's width at each fill (`Row.Fit`); the picture on a smaller plate of its own
  (`SIZE.iconRadius`), set in so its square corners stay inside the plate's round; the game's atlas
  `bags-greenarrow` on an upgrade; Kalam outlined, the worth by `Core.Coins` (vendor price times the count), the A a
  small button on a plate of its own. Link and Close are buttons on the same plates, trimmed grey. As wide as its widest line (`SIZE.least` to `SIZE.width`). Placed by
  `Core.Window.New` (key `windowPlace`, no title bar: Edit Mode only); at the mouse the first line's picture under the
  cursor, kept on the screen. A thing the player took (`LOOT_SLOT_CLEARED` of the slot clicked): the rows are laid
  out anew and, at the mouse, the window moved so the line now at the clicked place (the one before it, when the last
  was taken) stands where the taken one stood, the scroll counted in. Link: the links of the items and currencies, as
  many as the chat box holds (255 letters on show, 1280 bytes), into `ChatFrameUtil.GetActiveWindow()`, else
  `ChatFrameUtil.OpenChat`; `SendChatMessage` has restrictions, so the player sends them. `LOOT_READY` (not with
  the game's Auto Loot: the rules' slots queued, `SIZE.burst` of them `LootSlot`ted at once, the rest that many a frame
  by a hidden frame's `OnUpdate`; a slot asked once a loot), `LOOT_OPENED` (read again, the items met noted in `seen`,
  the newest first, `SIZE.seen` at most; then the window, or a check `Core.Later` 0.4 s after for Auto Loot and for
  rules that took everything),
  `LOOT_SLOT_CLEARED` (the last one closes the loot), `LOOT_SLOT_CHANGED` (taken if the rules want it now),
  `LOOT_CLOSED`, `UI_ERROR_MESSAGE` with
  `ERR_INV_FULL` (what the rules could not take shows). Hidden, it closes the loot (`CloseLoot`). Esc by
  `Core.Escape`. The game's sounds for a container opened and a catch (`Core.Sound`).
- **Upgrades** (`Upgrade.lua`): `C_PlayerInfo.CanUseItem` and the item's level asked (`UnitLevel`); where it is worn
  from its `INVTYPE_*` (the game's `INVSLOT_*`, the ranged place by `GetInventorySlotInfo("RangedSlot")`, else the
  main hand); what is worn by `GetInventoryItemLink`, its item level by `C_Item.GetDetailedItemLevelInfo` (else
  `GetItemInfo`); armour's weight by its subclass (cloth 1 to plate 4). `Slots.Line` marks `line.upgrade` ("empty",
  "better"); `Slots.Rule` takes none while `showUpgrades` is on.
- **Your items** (`Items.lua`): a tab of the module's own on its options page (`Core.Options`' hook `tabs`; the page
  is then one in tabs). The items of `seen`, then those of `kept`, each a line of the game's parts
  (`UICheckButtonTemplate`, its picture, its name in its quality's colour, why in grey), ticked by `Slots.Rule`; a tick
  writes `kept[id]` (true or false), or clears it where `Slots.Rule(line, options, false)` says the same. An item the
  game has not told yet is asked for (`C_Item.RequestLoadItemDataByID`) and drawn anew on `GET_ITEM_INFO_RECEIVED`.
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
- **Settings** (`Loot.lua`, `Core.Options`, in tabs): `window`, `atMouse`, `notes`, `full`; `takeAll`,
  `takeCoins`, `takeCurrency`, `takeQuest`, `takeTrade`, `takeGear`, `takeConsumable`, `takeJunk` (all off at
  first); `rolls`, `tally`, `feed`, `feedMoney`, `feedGroup`, `feedQuality`. Kept without a control: `kept` (the
  player's word: item ID = true taken at once, false never), `seen` (item IDs met in loot, the newest first), `lent`
  (the game's settings lent). The places: `windowPlace`, `rollsPlace`, `feedPlace` in `Core.Store("Loot")`.
- **Forever and Retail:** one way for both; every function asked for exists in both clients (the Forever-Retail
  lookup). Transmog is offered where the game offers it (Retail). Master loot only where the game has it.
- **Tests:** `dev/tests/loot.lua`. To look at it: the interface lab's scene `loot` (`Doc/guides/ui-lab.md`).

## Files
| File | What it does |
| --- | --- |
| `SaneUI_Loot.toc` | The addon: its files in order |
| `Loot.lua` | The module's table, words, sizes, settings, `/sane loot`, standing down |
| `Slots.lua` | The open loot as plain lines; the rules that take at once; the note under a name |
| `Upgrade.lua` | Whether a thing would make the character better |
| `Chat.lua` | The game's sentences about loot read back into their parts |
| `Game.lua` | The game's loot window, Auto Loot and roll frames kept out of the way, and given back |
| `Row.lua` | One line of the loot window: its shade and outline, picture, name, kind, worth and A |
| `Window.lua` | The loot window; the rules' things taken as the loot is ready |
| `Items.lua` | The options' tab *Your items* |
| `Master.lua` | The master looter's menu |
| `Full.lua` | The page that makes room when the bags are full |
| `Rolls.lua` | The roll cards |
| `Feed.lua` | What you and your group receive, over the world |

## History
- 2026-10-28 — Built (Saneroki asked for a loot module with its own loot window): the window on the journal's page,
  the rules, the loot list, the master looter's menu, the bags-full page (board #34's note), the roll cards with who
  chose what, the feed, Edit Mode places, `/sane loot`.
- 2026-10-29 — The window as little as it can be (Saneroki): no paper, frame or title, the lines straight on the
  world, Link and the X over them; borders in the quality's colour, a quest's in gold; a thing taken, the next under
  the mouse. Take all and the title gone; the note under a name off at first.
- 2026-10-29 — Each thing on a dark shade outlined in its quality's colour, its worth, an A for the list (Saneroki):
  Link and Close as buttons at the foot; nothing taken at once at first, the switches by kind (Everything, coins,
  currencies, quest items, trade goods, gear, consumables, junk), taken as soon as the loot is ready; the game's Auto
  Loot lent off; the options in tabs with the list *Your items*; the line under a name on again.
- 2026-10-29 — The Auto Loot lend through Core's Sync: on a second account the profile's Auto Loot on was written a
  moment after the login and everything was taken at once. The line under a name reaches the line's end where a
  thing sells for nothing (the quest's and the coins' words were not drawn).
- 2026-10-29 — Smooth round corners (Saneroki: "our current loot window is very ugly"): every line, the picture, the
  A and the buttons on plates of Core's `Shape`, as the chat's bubbles. Upgrades: the game's green arrow on a thing
  that would make the character better, and the switch *Always show upgrades* (on) keeps them out of every rule.
