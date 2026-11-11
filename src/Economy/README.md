# Sane UI: Economy

A tab *Deals* on the game's auction house window: what to buy and what to sell right now, each a click away. And a tick *Send to banker* on the mail window's *Send Mail* tab: the mail to your banker filled in with your trade goods, reagents, recipes, waylaid crates and writs, for one press of Send, or sent by itself while you speed level.

## TL;DR

The auction house opens on **Deals**: two columns, what to buy on the left and what to sell on the right, and in the window's corner how much gold you have on sale. It all comes from the prices your full scans gather, so the left column fills as they build up.

Tick **Send to banker** on the mail window's *Send Mail* tab, with your banker's name in *To:*. From then on the mailbox opens on *Send Mail* with the mail to your banker filled in: its name, today's date as the subject, and every trade good, reagent, recipe, waylaid crate and writ in your bags that is not soulbound. Press **Send**. With **Speed Leveling** on it goes by itself as the mailbox opens.

## How to use

- **Buy now** lists what is cheap right now and likely to bring a profit: clearly under its usual price, under the most worth paying after the house's cut and the post, and seen selling. Each line says what it costs, when and for how much to sell it, and what one brings. How many it buys is capped by what sells in a week.
- **Both houses:** your side's auction house and a neutral one each keep their own prices. *Buy now* also lists what costs much less here than it fetches in the other house, reckoned by that house's cut and deposit: *10s, sell at the neutral AH for 20s*. *Sell now* says *Sell at the neutral AH for 20s*, with no button, where a sale there pays clearly more. It takes scans at both: the other house's prices must be under three days old, and its sales seen.
- **Sell now** lists what any of your characters has that a sale now brings more for than a vendor pays, the cut and the post counted, unless the price is soon clearly better. Only what is in the bags of the character you play can be posted; the rest says who has it.
- **Buy:** a thing sold whole buys on one click, the cheapest offer. A thing sold by the unit takes two clicks on the same button: the first asks the server what they cost now, the second buys them, with the sum on the line.
- **Post** puts up all you have of it in your bags, for the duration you last chose in the game's Sell tab, just under the lowest offer.
- **On sale** in the top corner is what your auctions are worth together: all your characters' in the last full scan, and what you posted here since.
- The mouse on a line shows the item's tooltip with its Gold section and price graph (hold Alt).

The option *Open on Deals* lets the window open on the game's own first tab instead.

### Send to banker (the mail window)

- **The tick** stands right of the window's tabs while *Send Mail* is open. Tick it with your banker's name in *To:* (on Forever the first name and the surname), or tick it and type the name there: the name in *To:* while it is ticked is your banker. Name and tick are remembered for all your characters of that faction on that realm, the only ones a mail reaches; the tooltip says who your banker is.
- **Ticked,** the mailbox opens on *Send Mail* instead of the inbox, with *To:* your banker, the subject today's date (2026-11-11), and on the mail every trade good and reagent in your bags (the bags' category *Trade Goods*), every recipe, pattern and plan (its category *Professions*), and Forever's crafting orders: waylaid crates and supplies, sealed and craftsman's writs. What is soulbound or a quest item stays with you. Press **Send**.
- **More than twelve stacks:** a mail holds twelve. When one went, the next is filled in the same way, for the next press; beside the tick stands how many more mails it takes.
- **What you wrote stays:** a name or subject you typed is left as it is, and only free slots are filled. A reply to a mail in the inbox gets nothing of the banker's, and leaving *Send Mail* for the inbox takes it off again.
- **Unticked,** what was put on the mail goes back into your bags, the name and date leave the boxes, and *Send Mail* is as the game made it.
- It opens on the inbox as ever on your banker itself, and when nothing would go.
- **Send by itself:** with the tick on, the mail goes as the mailbox opens, without a press of Send, and each next one as the last went, until nothing is left or the game refuses one. On in the profile *Speedleveling*, so the box *Speed Leveling* at the foot of the bags turns it on and off; an option of its own on the page Economy in any profile. Hold Shift as you open the mailbox to leave it to you, as at a vendor.

## Technical details

- **Data:** Core's alone (`Doc/guides/data.md`, *Prices*, *The forecast*, *Fees*, *Characters*). The module keeps no data.
- **The window stays the game's:** nothing is written into it. Our page covers its page, our tab stands after its tabs, the game's `PanelTemplates_DeselectTab` marks them, and a hook on `SetDisplayMode` tells when it wants its page back.
- **A purchase goes by the server's answer, never by a scan** (`Live.lua`): the lines in sight are searched one at a time as `IsThrottledMessageSystemReady` allows, so the button is ready before the click. An answer counts for 90 seconds.
- **The game's restricted calls** (`PlaceBid`, `StartCommoditiesPurchase`, `PostItem`, `PostCommodity`) run inside the button's `OnClick`, one each, never in a loop. `ConfirmCommoditiesPurchase` too runs on a click.
- **Prices:** what does not stack moves by whole silver, what stacks by the copper (`Prices:PostAt`).
- **Standing down:** `GiveBack` takes the tab, its page, the corner and the tick away; a purchase that waits is called off when the window closes, what we put on a mail goes back into the bags.
- **Send to banker** (`Banker.lua`): a `UICheckButtonTemplate` of ours on the game's `SendMailFrame`, right of `MailFrameTab2`. What is filled in is what a player types and drags: the boxes' `SetText` (`SendMailNameEditBox`, `SendMailSubjectEditBox`) only where they are empty, `C_Container.PickupContainerItem` then `ClickSendMailItemButton` into a free slot only (each slot of ours remembered, taken off again with `ClickSendMailItemButton(slot, true)`); the game's own Send sends, and after `MAIL_SEND_SUCCESS` (the game's `SendMailFrame_Reset` empties the boxes) the next mail is filled in. At `MAIL_SHOW` (a frame later) with the tick on, a banker named, not the banker, something to go: `MailFrameTab_OnClick(nil, 2)`, as the game's own Reply opens the tab. A hook on `MailFrameTab_OnClick` fills in half a second after Send Mail opens, so a reply has set `SendMailFrame.sendMode` to `"reply"` and gets nothing, and takes ours off when the game goes to the inbox. A name typed into To: while ticked (a hook on its `OnTextChanged`, the player's typing only) is the banker. What goes: the item classes Trade Goods, Reagent, Recipe and Profession (`Enum.ItemClass`: the bags' categories *Trade Goods* and *Professions*; Forever has no item of the class Profession), and by the game's English names `^Waylaid `, `Writ$`, `Writ[:%s%-]` (the crates, supplies and writs of Forever's crafting orders), never the class Quest, not bound, not locked. *Send by itself* (`bankerAuto`, given to the profile Speedleveling by Core's `Presets.lua`) sends the mail filled in with `SendMail` and the boxes' words, the game's button disabled until the game answers, one mail on its way at a time; it stops at `MAIL_FAILED`, with too little gold for the postage, or with Shift held at `MAIL_SHOW`. The game's own tools stay as they are filed (card #434: Flint and Tinder and the Gyromatic Micro-Adjustor are Trade Goods).
- **Kept:** `Core.Store("Economy")`: `bankers` (`["Realm|Faction"] = name`) and `toBanker` (`["Realm|Faction"] = true`, the tick), the account's own, never shared.
- **When the game warns about a post** (`AUCTION_HOUSE_POST_WARNING`), nothing is posted: the line says so, and the game's Sell tab takes it from there.

## Files

| File | Holds |
| --- | --- |
| `Economy.lua` | The module, its words, sizes, option, standing down |
| `Deals.lua` | What is worth buying and selling right now: plain lists |
| `Live.lua` | What the server says of the items in sight |
| `Trade.lua` | A purchase and a post, from a click |
| `Tab.lua` | The tab, its two columns, the gold on sale |
| `Banker.lua` | Send to banker, a tick on the Send Mail tab: what goes, the name and tick kept, the mail filled in, by itself with Send by itself |

## History

- 2026-11-11: the tab Banker gone; in its place the tick *Send to banker* on the *Send Mail* tab: ticked, the mailbox opens there with the mail to the banker filled in (its name, today's date, the trade goods, reagents, recipes, waylaid crates and writs not soulbound) for one press of Send (Saneroki).
- 2026-11-09: profession items go to the banker too (the bags' *Professions*: recipes, Retail's profession items); *Send by itself*, on in the profile Speedleveling: all of it sent as the mailbox opens (Saneroki).
- 2026-11-07: the tab Banker on the mail window, open first: the banker's name remembered, every trade good and reagent sent to it with one Send (Saneroki).
- 2026-10-30: both houses weighed against each other, each by its own fees (Saneroki).
- 2026-10-30: the tab Deals, open first: what to buy and sell right now, and the gold on sale in the window's corner (Saneroki).
