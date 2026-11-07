# Sane UI: Economy

A tab *Deals* on the game's auction house window: what to buy and what to sell right now, each a click away. And a tab *Banker* on the game's mail window: your trade goods and reagents sent to your banker with one click.

## TL;DR

The auction house opens on **Deals**: two columns, what to buy on the left and what to sell on the right, and in the window's corner how much gold you have on sale. It all comes from the prices your full scans gather, so the left column fills as they build up.

The mailbox opens on **Banker**: type your banker's name once, and every trade good and reagent in your bags is lined up in a mail to it; **Send** sends them all.

## How to use

- **Buy now** lists what is cheap right now and likely to bring a profit: clearly under its usual price, under the most worth paying after the house's cut and the post, and seen selling. Each line says what it costs, when and for how much to sell it, and what one brings. How many it buys is capped by what sells in a week.
- **Both houses:** your side's auction house and a neutral one each keep their own prices. *Buy now* also lists what costs much less here than it fetches in the other house, reckoned by that house's cut and deposit: *10s, sell at the neutral AH for 20s*. *Sell now* says *Sell at the neutral AH for 20s*, with no button, where a sale there pays clearly more. It takes scans at both: the other house's prices must be under three days old, and its sales seen.
- **Sell now** lists what any of your characters has that a sale now brings more for than a vendor pays, the cut and the post counted, unless the price is soon clearly better. Only what is in the bags of the character you play can be posted; the rest says who has it.
- **Buy:** a thing sold whole buys on one click, the cheapest offer. A thing sold by the unit takes two clicks on the same button: the first asks the server what they cost now, the second buys them, with the sum on the line.
- **Post** puts up all you have of it in your bags, for the duration you last chose in the game's Sell tab, just under the lowest offer.
- **On sale** in the top corner is what your auctions are worth together: all your characters' in the last full scan, and what you posted here since.
- The mouse on a line shows the item's tooltip with its Gold section and price graph (hold Alt).

The option *Open on Deals* lets the window open on the game's own first tab instead.

### Banker (the mail window)

- **To:** your banker's name, as you would write it on a mail (on Forever the first name and the surname). It is remembered for all your characters of that faction on that realm, the only ones a mail reaches.
- **The list** holds every trade good and reagent in your bags (the bags' category *Trade Goods*), one line an item with how many you carry and in how many stacks; what is bound is left out. Untick a line to keep it: it stays in your bags at every mailbox until you tick it again.
- **Send** puts the stacks into mails of twelve, the game's most, and sends them one after the other: the first on the click, each next one as soon as the game says the last went. The line under the list says how many mails it takes, and at the end how many went.
- **Not sent:** where the game refuses a mail (no such character, the other faction), its reason stands on the line and the items are back in your bags. Too little gold for the postage, something you put on the *Send Mail* tab yourself, or an item on the cursor stops it too. A mail the game takes longer than ten seconds over gives the button back: *Send again*.
- It opens first unless you play your banker, or nothing would go to it: then the inbox, as always. The option *Open on Banker* turns it off.

## Technical details

- **Data:** Core's alone (`Doc/guides/data.md`, *Prices*, *The forecast*, *Fees*, *Characters*). The module keeps no data.
- **The window stays the game's:** nothing is written into it. Our page covers its page, our tab stands after its tabs, the game's `PanelTemplates_DeselectTab` marks them, and a hook on `SetDisplayMode` tells when it wants its page back.
- **A purchase goes by the server's answer, never by a scan** (`Live.lua`): the lines in sight are searched one at a time as `IsThrottledMessageSystemReady` allows, so the button is ready before the click. An answer counts for 90 seconds.
- **The game's restricted calls** (`PlaceBid`, `StartCommoditiesPurchase`, `PostItem`, `PostCommodity`) run inside the button's `OnClick`, one each, never in a loop. `ConfirmCommoditiesPurchase` too runs on a click.
- **Prices:** what does not stack moves by whole silver, what stacks by the copper (`Prices:PostAt`).
- **Standing down:** `GiveBack` takes both tabs, their pages and the corner away; a purchase that waits is called off when the window closes, a mail of ours still in the mail goes back into the bags.
- **The tab Banker** (`Banker.lua`) stands on the game's mail window as *Deals* does on the auction house: our page covers the window's page, our tab stands after its two (marked with the game's `PanelTemplates_` calls), and a hook on `MailFrameTab_OnClick` tells when the game wants its page back (its tabs, a reply, the window's own show, which picks the inbox). What goes: the item classes Trade Goods and Reagent (`Enum.ItemClass`), not bound, not locked. A mail is put together by the game's own calls, `C_Container.PickupContainerItem` then `ClickSendMailItemButton`, never into a slot the player filled, and sent with `SendMail`; the next on `MAIL_SEND_SUCCESS`, the reason of a refusal from `UI_ERROR_MESSAGE` before `MAIL_FAILED`. After a mail went the game gives the keys to its own hidden name box (`SendMailFrame_Reset`): they are let go.
- **Kept:** `Core.Store("Economy")`: `bankers` (`["Realm|Faction"] = name`) and `kept` (`[item] = true`, an item unticked), the account's own, never shared.
- **When the game warns about a post** (`AUCTION_HOUSE_POST_WARNING`), nothing is posted: the line says so, and the game's Sell tab takes it from there.

## Files

| File | Holds |
| --- | --- |
| `Economy.lua` | The module, its words, sizes, option, standing down |
| `Deals.lua` | What is worth buying and selling right now: plain lists |
| `Live.lua` | What the server says of the items in sight |
| `Trade.lua` | A purchase and a post, from a click |
| `Tab.lua` | The tab, its two columns, the gold on sale |
| `Banker.lua` | The tab Banker on the mail window: what goes, the name kept, the mails sent |

## History

- 2026-11-07: the tab Banker on the mail window, open first: the banker's name remembered, every trade good and reagent sent to it with one Send (Saneroki).
- 2026-10-30: both houses weighed against each other, each by its own fees (Saneroki).
- 2026-10-30: the tab Deals, open first: what to buy and sell right now, and the gold on sale in the window's corner (Saneroki).
