# Economy

Planning notes for the **Economy** module (`SaneUI_Economy`, title *Economy*). This is not a spec yet: it
collects what Saneroki has decided so far (2026-10-16) and proposals for the rest, marked *proposal*. No code
yet. Checked on 2026-10-16 against Core's code, Blizzard's code (`references/`) and `Doc/ideas/Data.md`;
*Building it*, at the end, is the plan for the one who writes the code.

## What it is

Economy is the module for trading with the game: the **auction house**, the **vendor**, the **trainer** and
the **bank**. It helps the player buy, sell and post at the right price, and shows the market and its
history, all from Sane UI's own database.

Two parts:

- **Windows of our own,** one for each of the game's trade windows (below), later also the mailbox, the
  guild bank and the bags (*More windows*). This is Economy.
- **A full scan of the auction house every time it is opened,** kept as a full and growing history of every
  item at the auction house, its prices and everything else a full scan tells. This is the most important
  part. It is done by **Core's database** (`Doc/ideas/Data.md`): Core and its data are the backend, the
  modules are logic and views on top (Saneroki). Economy shows what the database found.

| Our window | Opens when the player talks to | Blizzard window it stands for | The talk ends with |
| --- | --- | --- | --- |
| Auction house | an auction house NPC | `AuctionHouseFrame` (`Blizzard_AuctionHouseUI`, loaded on demand) | `AUCTION_HOUSE_CLOSED` |
| Vendor | a merchant | `MerchantFrame` (`Blizzard_UIPanels_Game`) | `MERCHANT_CLOSED` |
| Trainer | a trainer | `ClassTrainerFrame` (`Blizzard_TrainerUI`, loaded on demand) | `TRAINER_CLOSED` |
| Bank | a banker (character and account bank) | `BankFrame` (`Blizzard_UIPanels_Game`: this client's own `Camelot/BankFrame.lua` on the shared `BankFrameTemplates`) | `BANKFRAME_CLOSED` |

The game opens these four through its player interaction manager
(`Blizzard_UIPanels_Game/Shared/PlayerInteractionFrameManager.lua`, events
`PLAYER_INTERACTION_MANAGER_FRAME_SHOW` and `_HIDE`, with the `Enum.PlayerInteractionType` of the auction
house, *Merchant*, *Trainer*, *Banker*, *CharacterBanker* and *AccountBanker*), which shows and hides each
window with `ShowUIPanel` and `HideUIPanel` and loads the auction house, the trainer and the guild bank
first. On this client the trainer and the auction house also come by a second path: `TRAINER_SHOW` and
`AUCTION_HOUSE_SHOW` / `_CLOSED` are routed to the same show and hide functions
(`Blizzard_Game/Camelot/EventImplementation.lua`, `Mainline/EventRouting.lua`). So Economy follows **the
talk's own events** (`MERCHANT_SHOW`, `TRAINER_SHOW`, `AUCTION_HOUSE_SHOW`, `BANKFRAME_OPENED`, later
`MAIL_SHOW`, `GUILDBANKFRAME_OPENED`, and the close events in the table), not the manager, and asks
`C_PlayerInteractionManager.IsInteractingWithNpcOfType` where it must know. This client's auction house is
the modern one (`C_AuctionHouse`, commodities and items).

## Our window or Blizzard's (Saneroki)

- **Setting *Hide Blizzard's window*, one per window** (auction house, vendor, trainer, bank), each ticked by
  default. Ticked: only our window shows, Blizzard's is hidden. Not ticked: both show, ours next to
  Blizzard's.
- **A button *Classic* on every one of our windows,** always, whatever the setting: our window goes away and
  Blizzard's own window is shown. The player always has a way back to the game's window.
- **A button *Sane UI* on every Blizzard window that one of ours stands for,** next to its close button: Blizzard's window
  goes away and ours comes back.
- **Remembered, also across sessions:** after *Classic*, that trade window opens as Blizzard's every time,
  after a `/reload` and the next login too, until its *Sane UI* button is pressed. Kept per window (auction
  house, vendor, trainer, bank) in Economy's settings.
- With a window's *Hide Blizzard's window* not ticked, *Classic* puts ours away (remembered the same way) and Blizzard's
  stands alone; *Sane UI* brings ours back beside it.
- **Core has the buttons and the memory** (done in Core, `src/Core/Window.lua`; `Doc/ideas/Windows.md`, *The
  middle, and windows not docked* and *The game's own triggers*): a window with a title bar (`titleBar`) has
  the buttons [the game's window] [full screen / back] [close] at its right end. With `native = { frame,
  show, back }` the first swaps to Blizzard's window (tip *Classic window*), and `window:Attach()` puts the
  same button on Blizzard's window, beside its close button, to come back (tip *Sane UI window*). Both call
  `window:Native(on)`, which keeps the choice with the window's place (`window:Remember("native", on)`, in
  the store Economy hands over) and then calls Economy's `show` or `back`. When the player talks to the NPC,
  Economy calls `window:Open()`: it calls `show` if Blizzard's was chosen last, else shows ours, full screen
  again if it was left so. Economy writes none of this memory itself; `show` and `back` only swap the two
  windows.
- **Resilience:** if our window fails (`module.Guarded`), it stands down and Blizzard's window is shown at
  once, as with *Classic*. The scan does not hang on our window: Core's database runs it whether Economy is
  switched on or not.

### Hidden, not closed (notes for building it)

Each of these Blizzard windows ends the talk with the NPC when it is hidden (checked in `references/`):
`AuctionHouseFrameMixin:OnHide` calls `C_AuctionHouse.CloseAuctionHouse()`, `MerchantFrame_OnHide`
`CloseMerchant()`, `ClassTrainerFrame_OnHide` `CloseTrainer()`, the bank's `BankFrameBaseMixin:OnHide`
`C_Bank.CloseBankFrame()`, later the mailbox `CloseMail()` and the guild bank `CloseGuildBankFrame()`. So
Economy cannot `Hide()` a window that is in sight, nor give it a hidden parent then: either fires its
`OnHide` and ends the talk.

But a frame that never comes into sight never runs `OnShow` or `OnHide`. That gives the way (*proposal*,
to prove at the vendor first, *Order of work*):

1. **A holder, set between talks.** While the player has ours for a window (*Hide Blizzard's window* on,
   *Sane UI* chosen), Blizzard's window is made a child of a hidden frame of ours (`SetParent`, at UIParent's
   scale), and only while no talk is open: at login for the windows always loaded, once its addon is loaded
   for the others (`EventUtil.ContinueOnAddOnLoaded`), and again at the end of each talk. The game then shows
   it as always (`ShowUIPanel` sets it shown), but it never comes into sight: its `OnShow` and `OnHide` do
   not run, so it neither ends the talk nor does its own work (no searches of its own, no events, no bags),
   and it takes no mouse. When the talk ends the game hides it, unseen. To check in the game: whether a
   window loaded on demand at the first talk gets its holder before the game shows it (if `ADDON_LOADED`
   comes inside the load, it does; if not, that first talk uses step 2).
2. **In the middle of a talk,** when Blizzard's window is already in sight (*Sane UI* pressed after
   *Classic*): a hidden parent would end the talk, so Blizzard's window is made tiny and clear instead
   (`SetScale` very small, alpha 0), until the talk ends; then step 1 again. Its buttons and lists shrink to
   a point and take no clicks (alpha 0 alone would leave them taking the mouse), and the game's panel
   layout, which counts a window's own scale (`GetUIPanelWidth`), leaves almost no empty place for it.
3. ***Classic*** gives Blizzard's window back to UIParent: it comes into sight and its `OnShow` runs now (its
   searches, its events, the bags), as if it had just opened. Our window's failure does the same.

- **What we changed is put back exactly:** parent, scale and alpha are noted in our own table, keyed by the
  frame, before they are changed. Nothing is written into Blizzard's frames, no global replaced,
  `UIPanelWindows` untouched (`Doc/guides/addon-standards.md`, *Taint*). `SetParent` and `SetScale` are plain
  widget calls on the frame: they set no field of it and replace none of its functions.
- **The empty place:** the game's panel layout still counts a held window as shown (alpha and sight are not
  looked at), so a panel opened beside it (the character window) stands where Blizzard's would have been:
  left for the vendor, trainer, bank and mailbox, the doublewide place for the auction house and guild
  bank. To see in the game whether that disturbs.
- To check in the game: what the game does with a held window when another panel needs its place. If it
  hides it, *Classic* finds it hidden: then *Classic* shows it with the game's own show function
  (`MerchantFrame_MerchantShow`, `ShowAuctionHouseFrame`, ...), out of combat only, with the taint log on.
- **Closing ours** (its close button, Esc) ends the talk with the game's own call
  (`C_AuctionHouse.CloseAuctionHouse`, `CloseMerchant`, `CloseTrainer`, `C_Bank.CloseBankFrame`); the game
  then hides its window on its own path. Not `HideUIPanel` from our code (a known taint trap). Esc alone
  would not do it with a held window: Esc hides the game's panels (`CloseWindows`), but a held one hides
  unseen and ends nothing. So Esc reaches our window's close (*The window*, Core's Esc option).
- **Walking away** ends the talk on the game's side: its events close ours.
- **The bags:** Blizzard's auction house, vendor and bank open all bags in their `OnShow` (`OpenAllBags`),
  the mailbox in its show function. A held window's `OnShow` does not run, so Economy opens them where it
  would (`OpenAllBags` with our named frame, so `CloseAllBags` of ours closes them again; to check with
  the taint log), until Economy's bag window exists (*More windows*).

## The window (Saneroki)

- **Core's window handling** (`Core.Window.New`): Economy fills each window and gives its first size; Core
  does the rest (skin, round corners, trim, buttons, docking, full screen, the kept place).
- **Opens in the middle of the screen** by default: docked in Core's zone `CENTER`, the dock place made for
  the windows the player talks to.
- **Moving, sizing and docking are Core's window system's (Saneroki),** not Economy's: the modules do not
  build that wheel again. Economy's windows are dragged and sized as Core allows every window, snap to Core's
  dock zones, and keep `place` and `dock` in Economy's settings, opening there next time. As Core is today:
  the title bar (`titleBar = true`) moves a small window at any time and docks it only in the middle; Edit
  Mode moves it to any zone and sizes it (`sizable`). A window that only shows at an NPC is not there while
  Edit Mode is open away from one, so today it is sized at the NPC with Edit Mode open; Core plans a preview
  of such windows in Edit Mode (`Doc/ideas/Windows.md`). In the window guide's words (`Doc/guides/windows.md`,
  *Kinds of window*) Economy's trade windows are of the kind **Talk**: title bar, docked in `CENTER` at
  first, full screen by the maximize button, Esc closes and ends the talk, `native` and `close`; the bags
  are a **Panel**.
- **Opens with Core's motion (Saneroki):** the window comes onto the screen with the kind of motion of
  *Appearance → Animation type* (Core's default, `Motion.DEFAULT`; a window may have its own, like
  Social's). Core has the motion for a window's size today (`Motion.lua`, `Expand.lua`, `Edge.lua`), not
  yet for opening: *proposal* a `window:Appear()` in Core's `Window`, so every module's windows open the
  same way.
- **Expand and collapse:** Core's full screen button in the window's top right corner (Blizzard's maximize
  and minimize button, `edge:Fill`) fills the screen and brings it back, with the same motion.
- **The last view is remembered:** each window opens in the view it was last left in, small or full screen,
  kept in Economy's settings.
- **Esc closes the window, also in full screen (Saneroki),** and so ends the talk with the NPC; it does not
  bring a full window back to small first. That would change what the window system remembers (the last
  view) when the player only wanted to leave, so the next visit opens full screen again. Core's `Edge` brings
  a full window back on Esc today (right for Social's chat window, which never closes): its stand-in frame
  in `UISpecialFrames` calls `Fill(false)`, which writes `full = false`. For Economy's windows Core has a
  window option to close instead, `escape = "close"` (being added to Core on 2026-10-16 by the window
  review: *What Economy needs from Core*). Walking away while full is right already: Edge's `OnHide` puts
  the window back in its zone without writing `full`.
- **Small:** the everyday part, about the size of Blizzard's window. **Full screen:** all views side by side
  (lists with more columns, the item's details and chart next to them).
- The auction house window also shows the full scan's progress bar and the time to the next scan (Core's
  `Bar.lua`).

## The full scan (Saneroki, the most important part)

Every time the auction house window opens, the whole auction house is scanned by itself and what is found
is added to the history. The server allows a full scan about once every 15 minutes.

**Core's database runs it** (`Doc/ideas/Data.md`, *Learned* and *Series*: Core's `Data/Scan.lua`), whether
Economy is switched on or not, and shares it with the guild once per auction house in 15 minutes (*Sharing
in the game*, *Scans*). Its switches are Core's, on the page *General* (*The switches*). Economy shows the
scan's progress and result. The notes below are how the scan works, for the database's scan.

### What the game offers

From `Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua`:

- `C_AuctionHouse.ReplicateItems()` asks the server for a snapshot of every auction, commodities included
  ("to query the entire auction house"). The answer is the event `REPLICATE_ITEM_LIST_UPDATE`; then
  `C_AuctionHouse.GetNumReplicateItems()` rows can be read by index, from 0.
- Per row, `GetReplicateItemInfo(index)`: name, icon, count, quality, usable, level and level type, minimum
  bid, minimum increment, buyout (for the whole row), current bid, high bidder (name and full name),
  owner (name and full name), sale status, item ID, and whether the client knows the item fully
  (`hasAllInfo`). Also `GetReplicateItemLink` (item level, suffix, a pet's species in its `battlepet:`
  link), `GetReplicateItemTimeLeft` (time left band) and `GetReplicateItemBattlePetInfo` (a pet's creature
  and display, for its picture).
- The client has **no call that says when the next scan is allowed.** The database keeps its own time.
- Ordinary searches (`SendBrowseQuery`, ...) are limited to 100 a minute and are not meant to read the whole
  house; buying, bidding, posting and cancelling need a click of the player each (`HasRestrictions`).

### How it runs

1. **The auction house opens** (`AUCTION_HOUSE_SHOW`). If 15 minutes have passed since the last answered
   scan, the scan is asked for at once (a moment after the window is up). If not, our window shows *Next
   full scan in 9:41* and, while the auction house stays open, the scan starts by itself when the time is
   up.
2. **The time is noted when the answer comes,** not when it was asked for: a request the server ignores
   does not lock the scan for 15 minutes. It is the server's time (`GetServerTime`), kept in the saved
   file, so a `/reload` or another character of the account knows it too. No answer within about 90
   seconds counts as refused; the window says so. Only the event counts as the answer (whether it always
   comes is one of the checks in the game below). The request waits for `IsThrottledMessageSystemReady()`,
   so it is not lost behind the window's own first searches.
3. **Read in steps** within the database's frame budget, out of combat (`Doc/ideas/Data.md`, *Speed*), so
   the game does not stutter, with the progress bar in our window. Nothing runs between scans.
4. Rows whose item the client does not know yet (no name, `hasAllInfo` false) still give the item ID and the
   prices, which is enough; names come from the game's item cache when the item is shown. Only a weapon,
   armour or pet needs its link for the key (*What a row becomes*); those rows wait for the item's data
   (`ContinueOnItemLoad`) in steps, and one still not there after a while is left out of this scan, not
   keyed wrongly. An item ID the game does not know at all (`C_Item.DoesItemExistByID`) is skipped.
5. **Kept in one go at the end.** An empty or unreadable snapshot is never kept: the database keeps the last
   good one.
6. The scan goes on with our window put away by *Classic*, as long as the auction house is open.

**What a row becomes** (*proposal*, for the database's scan):

- **The key is the game's own item key** (`ItemKey` in the documentation: item ID, item level, suffix, pet
  species), the one the auction house itself groups offers by, written `item` when the other three are 0
  and `item:level:suffix:species` else. Then the scan, the series, Tooltips (which today keys by the item
  ID alone and so mixes item levels) and Economy all mean the same thing by *an item*. `Data.md` does not
  say this yet.
- **The link only where it matters:** `C_Item.GetItemInfoInstant(itemID)` (no server question) gives the
  class; only weapons, armour and pets ask `GetReplicateItemLink` for level, suffix and species.
  Everything else is keyed by its ID straight away, so most rows cost one call.
- **The price per unit** is the row's buyout divided by its count. A row with no buyout (bid only) counts
  for the auctions and units but not for the prices.
- Owner and bidder go through `Core.Plain`, and may be missing; nothing depends on them but *sold between
  two scans* and the sellers.

To try in the game: whether the rows can still be read after the auction house closed in the middle (if not,
the half read is dropped); whether the 15 minutes are per character or per account; how many rows a scan of
this client's auction houses has, and how long reading them takes; whether `REPLICATE_ITEM_LIST_UPDATE`
comes once or again as item data arrives; whether the owner is given; whether the auction houses are split
by faction (`Data.md` asks the same).

## The history (Saneroki: kept in full)

The whole history is kept, nothing thrown away (Saneroki). Core's database is built for that: the pack
`SaneUI_Data_Market` with the series *Prices*, its own saved variable, loaded only when asked for
(`Doc/ideas/Data.md`, *Sets by concern*, *Saved variables*, *Series*). The history is per auction house:
region, realm and side, never mixed with another realm's, and with no other realm's price where one is
missing (`Doc/ideas/Data.md`, *Realms and regions*). Economy only reads:

```lua
local Prices = SaneUI.Core.Data.Series("Prices")   -- this realm's (and faction's) auction prices
Prices:Last(item)
Prices:Range(item, fromDay, toDay)
```

What Economy shows from the database:

- **Per item and day** (in `Data.md` today): lowest price, market price, units, auctions.
- **Vendors** (set *Vendors*, pack Market): which vendor sells what for how much, learned by Core's watchers
  at every vendor. An item a vendor sells without a limit is never worth more than that at the auction
  house.
- **The characters' data** (`Data.Character`, `Data.Count`, `Data.AuctionLog`): own auctions, bags, bank,
  gold, and the auction log (posted, sold, expired, cancelled, bought).

**How big "in full" gets** (an estimate to measure, not measured): `Data.md` reckons with 6,000 items a
scan. A day's point (lowest, market, units, auctions) is about 20 bytes as packed text, so a year of daily
points is about 7 KB an item and **about 45 MB a year** for one auction house. Read and run at the
auction house's opening, that would take far more than a frame (`Data.md`, *Speed*: 11 ms for 2 MB). So
"in full" has to mean what `Data.md` plans: every day kept for good in the repository's master (the
harvest), and in the game the recent days day by day and older ones rolled into weeks and months, with the
long archive in a pack of its own that loads only for a chart (`Data.md`, *Sets by concern*: "long price
history gets its own"). Economy's views ask `Range` and do not care which. `Data.md` also gives every saved
variable a budget (100,000 values, below Lua's limit of 262,143 that would lose the whole file), so
whatever Economy wishes kept below is one packed string per item, not a table per auction.

Wished from the database for Economy's views, **not yet in `Data.md`:**

- **The scan's state,** for the progress bar and *Next full scan in 9:41*: running (rows read of how
  many), the next scan allowed at, the last one kept at, refused; and a callback when it changes.
- **A stamp for series** like the sets' `Stamp()`, moving when a scan was kept, so views redraw without
  polling.
- **One item key** for every price (*What a row becomes*).
- **How a day's point is made from several scans** (the lowest of the day's lowest; the market price of
  the day's last scan or their mean), so Economy's numbers mean the same day after day.
- **The last scan, whole:** every auction as it stood (item, count, buyout, bid, owner, time left), replaced
  by each new scan. For the offers of an item step by step by price, who sells, *someone sells cheaper* on
  the player's auctions, and browsing the whole auction house when the player is not there. One packed
  string per item, taken apart only when the item is looked at; owners as numbers into one list of names.
  Some 50,000 auctions at about 25 bytes is about 1.3 MB, replaced, not growing (to measure).
- **Sold between two scans:** an auction seen in one scan and gone in the next before its time ran out was
  most likely sold (or cancelled). A snapshot has no auction IDs, so they are matched by item, owner, count
  and price, as many of each as there were (several equal stacks of one seller are counted, not paired by
  guess). That gives how much of an item sells per day, the one thing a single snapshot cannot tell.
  Not counted as sold: an auction whose time left was *short* (it may have run out); one whose owner lists
  the same item again, cheaper, in the next scan (cancelled and posted anew); anything when the two scans
  are more than an hour or so apart (too much else happened between). It is an experiment: it is checked
  against the player's own auctions, whose end the auction log knows for sure (sold, expired, cancelled),
  and shown only once it guesses those right.
- Per item and day also **how many sellers** offered it.
- *If the last scan whole proves too big:* keep it whole only for the items the player has a stake in (in
  the bags or bank of any character, on the player's auctions, in a saved search), and for every other item
  only the day's point. Then *someone sells cheaper* and the offers by price still work where they matter,
  and *sold between two scans* is counted for those items only.

## Prices from the history

Economy's own reckoning over the database's numbers (the logic is the module's, the data Core's):

- **Market value:** what an item really fetches now, built on what Sane UI alone can see: *sold between two
  scans*. *Proposal*, its shape fixed here, its window and limits set on real data (no number before that):
  - **What sold first:** where auctions of the item were seen selling, the value is the median of the
    prices they sold at, each unit counted once, over a recent window of server days (as `Data.md` counts
    them). Only once *sold between two scans* has proven itself (*The history*); until then, the offers.
  - **Else what was offered:** with too few sales seen, the median of the days' lowest prices over that
    window, after leaving out the days far from the rest. *Far* is measured by the median absolute deviation
    (the median of every day's distance from the median), so one wild day can neither set the value nor
    hide its own oddness.
  - **How sure:** each value says what it stands on (*from 23 sales*, *from 9 days of offers*), and how
    tightly those agreed. Too little behind it: shown as *few data*. Nothing at all: no value, never a
    guess.
- **Lowest now:** the cheapest offer of the last scan, and how far it lies from the market value, as a
  share (*12 % under*).
- **Sells per day:** units sold between scans, per day. Beside the units on offer it gives **days of
  stock**: how long the offers standing now would last at that pace.
- **Price to post:** the lowest offer less an undercut (setting: one copper or a share), never so low that
  the player gets less than a vendor pays: buyout × (1 − the house's cut) ≥ the vendor's price. The cut is
  read from the game's sale mails (`GetInboxInvoiceInfo`: buyout and consignment), as the client names no
  number for it; until one is seen, 5 % (to check). The deposit is shown beside it
  (`C_AuctionHouse.CalculateItemDeposit`, `CalculateCommodityDeposit`), as it is lost if the auction does
  not sell.
- **Price history:** per day the lowest offer and, where sales were seen, the prices they went at, on one
  time line.
- `Prices.lua` holds only these functions, plain Lua over plain numbers, so the tests feed them made-up
  days and scans.

Tooltips reads the same series for its prices (`Doc/ideas/Data.md`, *What moves over*: its own price list
moves into the series *Prices*).

## The auction house window

Views as tabs in the small window, side by side in full screen. The first three carry Blizzard's own tab
names (`AUCTION_HOUSE_BUY_TAB`, `AUCTION_HOUSE_SELL_TAB`, `AUCTION_HOUSE_AUCTIONS_SUB_TAB`). *Proposal*:

- **Buy:** search by name and Blizzard's categories. Results from the server's search, and from the last
  scan in the meantime. Saved searches (lists of items to buy, searched in one go). Buying needs a click
  per purchase; commodities with quantity and the total price to confirm.
- **Sell:** the bags' items with their value and their *days of stock*. One picked: price to post, quantity,
  duration and deposit filled in, its offers and history beside it, *Post* (one click per auction); after a
  post, *Post next* brings up the next item of the bags.
- **Auctions:** the player's auctions, marked when someone sells cheaper; cancel with a click each;
  *Reprice* goes through the marked ones (*Rules for the code*).
- **Movement** (full screen): what moved on this auction house between the last scans, from *sold between
  two scans*: the items that sold, how many and at what prices; the items that sell fastest; an item's
  history (lowest offer and sold prices by day) and its offers by price from the last scan.
- **Sales:** what the player's characters sold, bought, let expire and cancelled, from the database's
  auction log (`Data.AuctionLog`).

## The vendor window

- **What the vendor sells:** price, stock, and the auction house value next to it.
- **Selling:** the bags with what the vendor pays and what the auction house would give, marked *Better at
  the auction house* or *Vendor it*. *Sell junk* button (`C_MerchantFrame.SellAllJunkItems`, which needs no
  click; Blizzard's window asks first with a dialog, ours too); *proposal*: an option to do it on opening.
  Selling one item is the game's own: a right click on a bag item (`C_Container.UseContainerItem`) while
  the vendor is open. *Better at the auction house* only with a market value (*few data* or none: no mark).
- **Repair all:** own gold or the guild's (`RepairAllItems`, `RepairAllItems(true)`), the cost shown.
- **Buyback.**

## The trainer window

- The trainer's services, from the game: name, cost, level needed; what can be learned now, later, or not.
- *Train all* for everything learnable now, with the total cost (each service a click, if the game asks for
  one: `BuyTrainerService` is the old global API, not in the game's documentation, so whether it needs a
  click is to try in the game).
- The game's list is read with `GetNumTrainerServices` and `GetTrainerServiceInfo`; its filters
  (`SetTrainerServiceTypeFilter`: available, unavailable, used) are the game's and shared with Blizzard's
  window. Ours reads with all of them on and puts the player's back as they were, so *Classic* shows
  Blizzard's window as the player left it.
- What comes at the next levels from the database's set *Trainers* (pack Spells), which the Abilities
  module reads too.

## The bank window

- **Character bank and account bank,** with their tabs (`C_Bank`, `Enum.BankType.Character` and
  `.Account`; buying a tab as Blizzard's window does, with `C_Bank.PurchaseBankTab`, which needs a click).
  This client's own bank window (`Camelot/BankFrame.lua`) is one window, `BankFrame` with its `BankPanel`,
  and side tabs for the pages of both banks.
- One view with search, sorting and filters; the value of each stack and of the whole bank from the
  history.
- Gold in and out of the account bank.

## More windows (Saneroki)

The mailbox, the guild bank and the player's own bags get windows of their own too, built the same way:
Core's window, *Classic* and *Sane UI* remembered, *Hide Blizzard's window* for each. Their content is a
*proposal*.

- **Mailbox** (`MailFrame`, `Blizzard_MailFrame`, not loaded on demand; the interaction type *MailInfo*; the talk
  ends with `MAIL_CLOSED`): the inbox with *Take all* (Blizzard's own *Open All* takes one mail after the
  other, waiting for the game between them: `OpenAllMailMixin` in `MailFrame.lua`, the pattern to follow),
  the auction house's mails summed up (sold, bought, expired, with their amounts; the house's cut for
  *Price to post*), sending. The mailbox opens the bags in its show function, not in `OnShow`, so they open
  with a held mailbox too.
- **Guild bank** (`GuildBankFrame`, `Blizzard_GuildBankUI`, loaded on demand; *GuildBanker*;
  `GUILDBANKFRAME_CLOSED`): its tabs in one view with search, the value of each tab, deposit and withdraw,
  the log.
- **Bags** (the game's bag windows, `ContainerFrame1` and on, `ContainerFrameCombinedBags`): no NPC; the
  player opens them (the bag key, the bag buttons), and hiding them ends nothing. One view with search,
  sorting, each stack's value, junk marked, and how many the other characters have (`Data.Count`). The
  trade windows open it where Blizzard's open all bags. To build it: the game's bag windows held (as in
  *Hidden, not closed*); ours opened after the game's own functions (`hooksecurefunc` on `OpenAllBags`,
  `ToggleAllBags`, `ToggleBackpack`, `ToggleBag`; none replaced); each slot the game's own button
  (`ContainerFrameItemButtonTemplate`), so a click uses, sells or banks an item the game's way; the buttons
  made out of combat, in a pool filled after login and topped up when a fight ends, never in combat (where
  the game's bags show instead if ours lacks a button).

## Settings (page *Economy*)

- *Hide Blizzard's window*, one per window (Saneroki): *Auction house*, *Vendor*, *Trainer*, *Bank* (later
  *Mailbox*, *Guild bank*, *Bags*), each ticked by default.
- *Undercut* for the price to post.
- Core's section **Expand window** (`Edge.Options`, as on Social's page, made by Core, not by Economy):
  *Can expand to fullscreen*, *Animation type* (*Use global type* by default), the full screen's
  background, the corners. One section for all of Economy's windows (*proposal*: they are one kind of
  window; one per window only if Saneroki wants it). Its header tip speaks of a screen edge; for windows in
  the middle it is the full screen button: Core's wording to widen.
- Kept without a switch, per window: *Classic* or ours, small or full screen, place and dock (Core's
  `Remember`, in the window's key in Economy's settings).
- The scan's and the sharing's switches are Core's (`Doc/ideas/Data.md`, *The switches*).

## Building it

The plan for writing the code: who does what, a window's life step by step, what is needed from Core, the
rules, the tests and when each step is done. Read with `Doc/guides/addon-standards.md` and
`Doc/guides/gui-development.md`.

### Who does what

| Part | Owner | Does |
| --- | --- | --- |
| The window: skin, title bar, buttons, dock, drag, size, full screen, motion, what it was left as | Core (`Window.lua`, `Edge.lua`, `Dock.lua`, `Motion.lua`) | Everything about the frame. Economy hands over a frame, a store and `native`. |
| The scan, the series *Prices*, vendors, trainers, the characters' data, sharing | Core's database (`Doc/ideas/Data.md`) | Gathers and keeps. Economy never writes data. |
| Which window for which talk, Blizzard's window out of sight and back | Economy (`Economy.lua`, `Native.lua`) | The life of each window (below). |
| Market value, sells per day, price to post | Economy (`Prices.lua`) | Plain functions over the database's numbers: no frames, no events, so the tests run them directly. |
| The views (Buy, Sell, the vendor's list, ...) | Economy | Draw what `Prices.lua` and the database give; the game's actions on the player's clicks. |

### A window's life

One small table per window (`Native.lua`), the same for every trade window; the bags differ only in having
no talk to end. States: **closed**, **ours** (ours shown; Blizzard's held or tiny, or beside it with *Hide
Blizzard's window* off), **classic** (Blizzard's in sight, ours hidden). *Held*, *tiny* and *in sight* are
the three ways of *Hidden, not closed*.

| What happens | From | Economy does | To |
| --- | --- | --- | --- |
| Between talks, ours chosen, the switch on | closed | Blizzard's window held (step 1) | closed |
| The talk begins (its event: `MERCHANT_SHOW`, ...); the game shows its window, unseen if held | closed | `window:Open()`: Core calls `show` if Blizzard's was chosen last, else shows ours (full screen if left so); bags opened for a held window | ours or classic |
| *Classic* (`native.show`) | ours | ours hidden, **the talk goes on**; Blizzard's back to UIParent, in sight | classic |
| *Sane UI* (`native.back`) | classic | ours shown; Blizzard's made tiny (step 2) while the switch is on | ours |
| Ours closed (its close button; Esc through Core's option) | ours | the window's `close`: the game's close call (`CloseMerchant`, ...), which ends the talk; the game hides its window on its own path | closed (by the event) |
| The talk ends (its close event: walked away, Blizzard's closed, the server, `/reload`) | ours, classic | ours hidden; Blizzard's scale and alpha back; held again if ours is the choice | closed |
| Our window fails (`module.Guarded` stands down) | ours | Blizzard's back to UIParent, in sight, at once; ours hidden; the talk goes on | classic, not remembered |

- **Hiding ours is not closing it.** Only `close` (the close button, Esc) ends the talk; our frame's
  `OnHide` does nothing to the talk, so *Classic* and the talk's own end can hide it freely.
- **Every step is idempotent.** The events can come twice or in any order (the manager's `_HIDE` and the
  close event both come): a step for a state the window is not in does nothing, and the game's close call
  is made at most once per talk.
- **Blizzard's window is changed only by these steps,** each noting first what it changes, and put back
  exactly, whatever happened in between (an error included). A switch or choice changed during a talk
  takes effect for the held state at the talk's end.
- **Loaded on demand:** the auction house, the trainer and the guild bank are Blizzard addons loaded at the
  first talk. Economy holds their window once its addon is there (`EventUtil.ContinueOnAddOnLoaded`), then
  calls `window:Attach()` again (Core's way for such windows).

### What Economy needs from Core

| Need | State |
| --- | --- |
| `Window.New` with `titleBar`, `dock`, `sizable`, `skin`, `edge`, `native`, `close`, `store`, `key` (one key per window: `auction`, `vendor`, ...) | done |
| `window:Open()`, `window:Native(on)`, `window:Remember()`, `window:Attach()` | done; no module uses them yet, Economy is the first with an NPC |
| Esc closes a window instead of bringing it back from full screen (*The window*) | `escape = "close"`, being added to Core (2026-10-16), below |
| An opening motion, `window:Appear()` | Core work (*proposal*) |
| `Core.Bar` for the scan's progress | done |
| The scan's state for the window: running (read of how many), next allowed at, last kept at, refused; a callback when it changes | database work: not yet in `Data.md` |
| `Data.Series("Prices")` with `Last`, `Range` and a stamp that moves when a scan was kept, so views redraw without polling | database work: `Stamp` is there for sets, to be had for series too |
| One item key for prices, the same in the scan, the series, Tooltips and Economy (*The full scan*) | database work: not yet in `Data.md` |
| The last scan whole, sold between scans (*The history*) | database work: wishes |

**The Esc option** (`escape = "close"` in `Window.New`, as Core is getting it): while such a window is
shown, a named stand-in of Core's (`SaneUIWindowEscape`, one for all such windows) stands in
`UISpecialFrames`; when the game hides it (Esc: `CloseAllWindows`, after the game's own panels), Core runs
the window's `close`, as its close button does, and Edge's own stand-in leaves such a window full, so
`full` stays kept and the next talk opens it full again. Economy's `close` is the game's close call, so Esc
ends the talk also while Blizzard's window is held (*Hidden, not closed*).

### Rules for the code

- **A click of the player is needed** for buying, bidding, posting, cancelling and buying commodities
  (`HasRestrictions` in the game's documentation): the call is made inside the button's `OnClick`, never
  after a timer, an event or a second frame. *Post next* and *Reprice* are one click per auction, never a
  loop: after each, the next auction stands ready under the same button, so the mouse need not move. The
  restricted calls (also `ConfirmPostItem`, `ConfirmPostCommodity` and the bank's `PurchaseBankTab`) are
  never queued.
- **Buying works from the server's answer, never from the scan.** The scan has no auction IDs and may be 15
  minutes old: a purchase always searches the item first (`SendSearchQuery`), then buys what that answer
  shows; commodities with `StartCommoditiesPurchase`, the price the server confirms
  (`COMMODITY_PRICE_UPDATED`) shown, and marked if it rose, then `ConfirmCommoditiesPurchase` on a second
  click. `COMMODITY_PRICE_UNAVAILABLE` searches again; the window closed or the dialog left while a
  purchase waits calls `CancelCommoditiesPurchase`.
- **The server's searches are throttled:** send only when `C_AuctionHouse.IsThrottledMessageSystemReady()`,
  queue the rest, and go on at `AUCTION_HOUSE_THROTTLED_SYSTEM_READY`. Searches the player did not ask for
  (a saved list) go one at a time.
- **Nothing written into Blizzard's frames,** no global replaced, `UIPanelWindows` not touched, no
  `ShowUIPanel`/`HideUIPanel` from our code (`Doc/guides/addon-standards.md`, *Taint*). What we change on
  Blizzard's window (parent, scale, alpha) is noted in our own table, keyed by the frame.
- **Never a hidden parent for a window in sight:** `SetParent` to the holder only while
  `IsInteractingWithNpcOfType` says no talk of that kind is open, or the frame is not shown.
- **Values from the game go through `Core.Plain`** before arithmetic or as table keys: a secret value is
  skipped, never stored (*Secret values* in the guide).
- **Lists are Blizzard's scroll boxes** (`WowScrollBoxList` with a data provider; rows recycled, every field
  set in the initializer). A list of the whole auction house draws only its visible rows.
- **Nothing runs while nothing is open:** at login Economy registers its events and nothing else; each
  window and its views are made the first time they are needed; no `OnUpdate` of Economy's own (Core's
  `Motion.Clock` and the database's scheduler do the moving and the steps).
- **Prices are worked out once per item and stamp:** `Prices.lua` keeps its answers per item until the
  series' stamp moves.
- **Fail small:** each view drawn through `module.Guarded`; a broken view stands the window down to
  Blizzard's (*A window's life*), never a broken trade.

### Tests

`dev/tests/economy.lua` (Lua 5.1 with `wowstub.lua`, run by `dev/tests/run`), with stubs for the game's
trade windows and their close calls:

- **A window's life:** every row of the table above; the events twice and out of order; the close call at
  most once per talk; *Classic* never ends the talk; the holder never set on a window in sight (the stub's
  `OnHide` would end the talk, and the test fails if it does); Blizzard's window put back exactly as it
  was, after an error too; a failing view leaves Blizzard's in sight.
- **Remembered:** *Classic*, then a new talk, opens Blizzard's; *Sane UI* brings ours back; full screen
  left full opens full; Esc on a full window closes it and keeps `full`.
- **The switch per window:** off, both shown and nothing held; on, Blizzard's held; each window's own;
  changed during a talk, it holds from the talk's end.
- **Prices:** market value (sold prices before offers, the median, a far day left out by the median
  absolute deviation, too little behind it: *few data*, nothing: no value); price to post (the undercut,
  never below the vendor's floor); sells per day and days of stock from two made-up scans (a sold auction,
  an expired one, a cancel and repost).
- **No click-bound call outside `OnClick`:** the stubs of the restricted calls fail when called without a
  click in the stub.

The scan itself is tested with the database (`dev/tests/data.lua`, `Doc/ideas/Data.md`, *Tests*).

### Files (proposal)

```
src/Economy/
  SaneUI_Economy.toc
  Economy.lua      module, options, which window for which talk
  Native.lua       a window's life: Blizzard's window out of sight and back (Classic, Sane UI, failure)
  Prices.lua       market value, sells per day, days of stock, price to post (plain functions over Core.Data)
  Window.lua       what Economy's windows share: Core's window, buttons, progress, the kept view
  Auction/         Buy.lua, Sell.lua, Auctions.lua, Movement.lua, Sales.lua
  Vendor.lua  Trainer.lua  Bank.lua
  Mail.lua  GuildBank.lua  Bags.lua   (later)
  README.md
```

The scan and the history are Core's (`Data/Scan.lua`, series *Prices*), not Economy's.

### Order of work, and when each step is done (proposal)

1. **Core's database first:** the scan and the series *Prices* (`Doc/ideas/Data.md`; its build plan
   `Doc/ideas/Data-build.md`, steps 1c.2 *Series* and 1e *The auction scan*, which do not have Economy's
   wishes yet), with Blizzard's auction house window still in use. Done when: the in-game checks of *The full scan* are answered and
   written here, a scan is kept and survives a `/reload`, and no frame of the reading takes over 5 ms.
2. **Core's two pieces:** the Esc option (being added) and `window:Appear()`, with their tests in
   `dev/tests/window.lua`. The window guide asks to decide first whether windows animate, as Blizzard's
   panels do not; for Economy Saneroki has decided it (*The window*: they appear with Core's motion).
3. **The vendor window first, then the auction house:** the vendor is the simplest talk and proves the
   window's life (hiding, *Classic*, *Sane UI*, Esc, walking away) before the auction house's views are
   built on it. Done when: every row of *A window's life* works in the game, `/console taintLog 1` shows no
   Sane UI line after a talk, and the tests pass.
4. **Auction house window:** Buy, Sell, Auctions. Done when: a purchase, a post and a cancel work with one
   click each, and the throttle never shows the game's *too many requests* error.
5. **Bank and trainer windows.**
6. **Movement and Sales,** and the price history, once *sold between two scans* guesses the player's own
   auctions right.
7. **Mailbox, guild bank and bags.**

## Open questions

- The wishes to the database (*The history*: the scan's state, a stamp for series, one item key, a day's
  point from several scans, the last scan whole, sold between scans) go into `Doc/ideas/Data.md`?
- The bags: Economy's, or the bottom right place's *Character and bags* window (`Doc/ideas/Windows.md`)?
- *Kept in full* (*The history*): every day for good in the repository, and in the game the recent days
  day by day and older ones as weeks and months, as `Data.md` plans it for speed. Is that what Saneroki
  means, or should the game itself keep every day too (about 45 MB a year, loaded only for a chart)?
