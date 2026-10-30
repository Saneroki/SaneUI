# Sane UI: Tooltips

**Status:** working · **Since:** 2026-10-14 · **Addon:** `SaneUI_Tooltips`

## TL;DR
Draws the game's tooltips anew on dark panels with round corners and a soft edge, each in the colour of what it is about:
an item's quality, a player's class, a spell's school. Items, spells, players and creatures, buffs and
quests each have a layout of their own; everything else gets its name and its lines. Text size and
opacity can be set, and a switch anchors tooltips to the mouse cursor. An item's panel also shows the
quests that need it, the professions that use it, which of your characters have it (each by first name and
surname: *Sane Lunatic*) and what it brings from a vendor and at the auction house, with one clear line on
what to do with it for gold, what its materials bring if you disenchant it, and with Alt the price to post
it at and a graph of how its price went. Every section has its name in the middle of its divider (*INFO*, *QUEST*, *GOLD*, ...), the name in
grey, its rules the same grey; a thing's own lines (its numbers, what it
does, its description, its durability) are one section, *Info*; a spell's numbers are a table of four
columns and two rows. A tiny grey line in the middle at the bottom says that Alt shows more: the technical details, which of your characters
have the item (*Inventory*), and what other addons write into a tooltip, wherever they write it, in one
section of its own at the end, *Addons*, never among the panel's own lines. Where a thing has a 3D model (a
creature, a player, a mount, a pet) it stands in the picture's place; over a piece of gear, Alt shows your
own character wearing it beside the panel, turning slowly. A herb or an ore, and what it gives, show under
*Professions* how likely gathering it raises your skill, in the game's orange, yellow, green and grey. The
quest, gathering and disenchanting facts are Sane UI's database (Core's data framework), which the panels
only read.

## How to use
- **Switch it on or off:** tick or untick *Tooltips* under *Sane UI* in the game's addon list. Switched
  off, the tooltips are the game's own again.
- **Nothing to set up.** Point at an item, a spell, a player.
- **Seven settings**, on the page *Tooltips* of the options (Esc > Options > AddOns > Sane UI). A change counts from the next tooltip on.

  | Setting | At first | What it does |
  |---|---|---|
  | *Show tooltips* | While Shift is held | A dropdown: *Always* (at once, as the game does), or only while Shift, Ctrl, Alt, or Shift and Alt are held. Until the key is held a tooltip is there but unseen; pressing it shows the tooltip at once, letting go hides it again. (Shift is also the game's key for comparing an item with what you wear; with Alt, the technical details show too.) |
  | *Tooltips at the mouse cursor* | Default | A dropdown: *Default* (where the game puts them), while Shift, Ctrl or Alt is held, or *Always*. The tooltips that stand in the corner of the screen (creatures, players, things in the world, your action bars) follow the mouse instead. Pressing or letting go of the key moves a shown tooltip at once, to the mouse and back |
  | *Colour players by their class* | on | Off: a player's tooltip takes the colour the game gives the name |
  | *Show the icon of items and spells* | on | Off: no icon of an item, spell or buff, and no portrait for units: the level stands beside the name |
  | *3D model in tooltips* | on | Where the thing has a 3D model, it stands in the picture's place (see *3D models* below): a creature or player, moving, its face in view; a mount or a pet. Over a piece of gear, with Alt held: your own character wearing it, beside the panel. Off, or where the game cannot load the model: the picture (the portrait, the item's icon), and no character beside the panel |
  | *Text size* | 14 | From 10 to 20: how large a tooltip's name and lines are written; the smaller texts follow |
  | *Opacity* | 97 % | From 30 to 100 percent: how solid the background is. Texts and pictures stay as they are |

- **What each panel shows:**

  | Tooltip | In its panel |
  |---|---|
  | **Item** | *Equipped* over the name on what you wear in a comparison. Name in the colour of its quality; under it, small and grey: kind and slot (what it is, for a thing that is not worn: *Trade Goods · Cloth*) and at the right the level it needs (red while yours is lower) and under it, also at the right, what else it asks of you: a class (*Classes: Mage*), a profession's skill (*Requires Tailoring (75)*), a reputation (red while you lack it); icon with the item's level under it (a mount's or a pet's item: its 3D model). Then its own lines under **Info**, in the game's colours: a weapon's damage per second large, its hit and speed smaller in the same line (*3.2 DPS · 1 - 3 dmg · 2.00 spd*), or an armour's armour; its plain lines (*+5 Agility*, *Unique*), what it does (the game's green: *Equip:*, *Use:*, *Chance on hit:*), what is told about it (the game's gold); last its durability as a bar with *Durability* at its left and *61 / 120* at its right inside, flat with round corners like a unit's health bar. The set it belongs to (its name, its pieces and its bonuses) under **Set**. **Quest** (a section under its caption): *Starts* and the quest it starts, then *Needed for* and the quests that need it (each heading with *Questlog* at the right, over the words that say where you stand: *Not yet* is not yet in your quest log); each with its level small after its name and, at a glance, where you stand with it: *In log* with the ? and your count (*In log 1/4*, gold, green when complete), *Available* with the ! (you can take it now), *Not yet* dim (your level, a quest to do first), *Done* with a tick, grey; first those in your log, then to take, for later, done; without Alt three of those not in your log and *Press ALT for +2 more*. A quest for another class, race or side, or closed to you, is left out. Then, for a trade good, **Professions** (a section under its caption): *Used in* and the professions that use it, with their icons (by the item's kind), and for what a herb or an ore gives, the node that gives it (see *Gathering* below). With Alt, **Inventory** (see *Inventory* below): which of your characters have it and where. Then **Gold** (see *Gold* below), its first row how it binds, short as players write it (*BoP*, *BoE*, *BoU*, *BoA*, *WuE*, *Soulbound*, *Quest*; red until it is bound to you), and at the right whether you have its look (*Uncollected*, *Look known*); with Alt, last, other addons' lines under *Addons*. Each section is there only when something is known for it. Whatever you cannot use is red, as the game colours it. What you wear beside an item (a comparison) has its changes under *Info* and none of the sections from data, only its vendor price for one under *Gold* (and, with Alt, other addons' lines under *Addons*) |
  | **Recipe** | Like an item; what it makes stands under the caption *Creates*, with that thing's icon |
  | **Spell, pet ability** | Name; what it is (its school in its colour; without one *Healing* in green, *CC* in blue for crowd control, *Physical* in red, *Utility*) and rank, or *Passive*; under that what it asks of you, each in a row of its own (*Requires Defensive Stance*, *Requires Cat Form*, *Requires Ranged Weapon*, its reagents and tools; red while you lack it, as the game colours it); icon (a mount's spell: the mount's 3D model). Under **Info** a table of four columns, each cell a caption over its value, the captions in the dark see-through shade, the values white, *---* where nothing is known. A spell that hurts or heals has two rows: *Dmg* or *Heal* (what one cast does on average), its cost (*Rage*, *Mana*, *Energy*; a mana cost also as a share of all yours), *Cast* (the melee swing and the shots: their *Speed*), *Range* (*Melee* for melee range); then *DPS* or *HPS*, what it does *Per Rage* or *Per Mana*, *CD* (its cooldown), and *Crit* (your chance), or for one that lasts *Duration* (see *Spell numbers* below). Any other spell has one row: its cost, *Cast*, *CD*, *Range*. Then, a little apart, the description in the middle, its digits in the panel's colour; any other line of the game's under **Details**. The panel has the colour of the spell's school (fire, frost, arcane, nature, shadow, holy in the colours the game's combat log gives them; physical, for one that only hurts, in red), green if it only heals, none otherwise |
  | **Player** | Name in the colour of the class; the gold dragon round the portrait; close under the name and as large: the guild, with the player's rank in it small after it; then small: the race and the side (*Human · Alliance*), and under it the class line: spec and class with the talent points (*Feral Combat Druid 0/31/20*; in Retail the specialization alone, *Guardian Druid*; yours at once, another player's once inspected), the title (a PvP rank, *Sergeant*), and what is true now (*PvP* in red, *AFK*, *DND* in orange, *Offline*, *Dead*, *Ghost*; then the panel has no colour of its own); a large portrait in the top right corner with the level on its lower edge (the unit's live 3D model, see *3D model in tooltips*). Under **Status** the health bar with the current health and its share in percent written in its middle (over the power bar), and over its lower part the bar of mana, rage or energy (an empty one shows nothing): flat colours, half see-through, round corners; whom the player targets right above the bars (*Target* and the name right after it; *You*, in red, when it is you). The plaque under the portrait says the item level before the level, *iLvl 50 - 60* (yours at once; another player's after the game has inspected them, see below). Buffs and debuffs as small icons. With Alt, last, other addons' lines under *Addons* |
  | **Creature, NPC** | The same; in place of the guild its title (*Bowyer*, *<Flight Master>*: the game's line before its level line) or, for a pet, its owner; in place of the race what it is, its family and its faction (*Beast · Wolf*, *Humanoid · Stormwind*: the faction is the game's line after the level line); on the class line its class (*Warrior*, *Mage*; not for a friendly NPC), its rank in the game's words (*Elite*, *Boss* in gold, *Rare* in silver; a rare elite both), *Tapped* (somebody else's kill), *PvP*, *Dead*; a dead one's panel has no colour of its own. Under **Status**, after its health, what killing it gives you and how many such kills to your next level; then under **Quest** each quest's name in gold with a sword before what you must still kill and a sack before what you must still loot with how often it drops after its name (*33%*), the count at the right (*5/7*; what is done is left out, and a quest with nothing left to do for it, too; the game's own quest lines, and what it drops for your quests from the module's quest facts: see *Quests* below); the quests it takes back and offers you, each name in gold with a line under it: *Turn in* (ready, green) or *In progress* with the game's ?, *Offers* with the game's !, and the quest's level; a dead creature says *Dead* and what it yields (*Skinnable*) on the class line, the game's *Corpse* line is left out; what killing it gives you (*145 XP*) and how many such kills to your next level (*Next level in 12*), see *Experience* below; the game's own dragon from its target frame curls round the portrait: gold for an elite, gold with a great wing for a raid or dungeon boss, silver and winged for a rare or rare elite; a creature without a rank has none. Your quests' lines for it in gold: a sword beside what you must kill it for, a bag beside what you must loot |
  | **Buff, debuff** | Name; *Buff* or *Debuff* and what takes it away (*Magic*); icon; under **Info** the description, in the middle; under **Duration** a bar that runs out with its time, with how long it still runs and who cast it written inside (flat, round corners). The panel has the game's colour of what takes it away (the colour of a debuff's border: magic, curse, poison, disease); a debuff nothing takes away the game's colour for that, a buff nothing takes away none |
  | **Quest** | Name; level (in the colour of its difficulty) and where it stands for you (*In progress*, *Ready to turn in*, *Completed*); under **Info** its text; under **Objectives** a box for each thing to do, ticked and green when it is done |
  | **Herb, ore** (a thing in the world Core's data knows) | As anything else, and under **Professions** the skill it needs and your chance (see *Gathering* below); the game's own line of the skill is left out |
  | **A creature on a map** (a boss on a dungeon's map: Core's `TipLook`) | As a creature's: its name, under it as large its title (the dungeon), small *Boss*; its 3D model in the portrait's place with the dragon of its rank (gold and winged for a boss) and its level on the plaque (*??*); then its sections (*Abilities*, *Loot*), each line's icon at its start, and with Alt its details set in under it, small |
  | **Anything else** the game fills from data (things in the world such as a mailbox or a chest, macros, the minimap, currencies, mounts, totems, equipment sets, ...) | Name and its lines under it as the game has them, no sections (an empty line is a small gap); a panel without a colour of its own, whatever colour the name has |

  **Sections:** every part of a panel under its header is a section with its name on its divider, in small
  capitals in the middle with a rule at each side (*——— GOLD ———*), name and rules in one grey, as a table's
  captions and the lines between its cells (Saneroki, 2026-10-23: the dark see-through shade they had read
  badly); a table's values keep their colour: there is no divider without a name. A thing's own lines are *Info*: an item's numbers, what it
  does, its description and its durability; a spell's facts and its description; a buff's and a quest's
  text. An item's *Set*, *Creates* (a recipe's thing), *Quest*, *Professions* (also the node that gives it),
  *Inventory* (with Alt), *Gold*; a herb's or an ore's *Professions*; a unit's *Status* and *Quest*; a buff's
  *Duration*; a quest's *Objectives*; a line of the game's of no other kind under *Details*; Alt's numbers
  under *IDs*; other addons' lines under *Addons* (with Alt). Two neighbours of the same kind are one section
  (the game's empty line between them is a small gap).

  **Unconfirmed Data:** a tooltip about something the game has not confirmed yet (a map's pin from Sane UI's
  data, a boss's abilities and loot) ends with a quiet note at its very bottom, *! Unconfirmed Data !*: small grey
  words in the middle, as written, no rules, the marks in the game's red (Saneroki, 2026-10-23). In such a tooltip a
  red ! stands before the name of each thing not yet confirmed (Core's `Core.UNCONFIRMED_MARK`), so the note says
  which.

  **Too tall for the screen:** a panel that would not fit the screen's height goes on in a second column beside
  the first (and a third...), each as wide as the first, a fine groove between them; no column is taller than the
  screen, and a section's name never stays alone at a column's foot. The icon or portrait stays at the first
  column's corner.

  **Hold ALT for more:** at the bottom of every panel of the game's data, while Alt is not held, a tiny grey
  line in the middle, without rules, says so (under *Unconfirmed Data* where both are there); with Alt it gives way to what
  Alt shows. A button's hint has none: Alt shows
  nothing more there.

  **Addons:** whatever other addons write into a tooltip (one addon or five) stands, while Alt is held, in one
  section of its own at the very end of every panel, under the caption *Addons*; without Alt it is not shown.
  Their lines as they wrote them, small and quiet,
  in their order, an empty line between two of them a small gap. Wherever an addon writes its line, at the
  end or right after one of the game's lines, it comes here: never between the panel's own lines and
  sections, not before a buff's time bar, not before a quest's objectives, not among an item's sections.
  Lines that only repeat a number (*Spell ID: 1459*) are left out: Alt shows the numbers.

  **3D models** (the setting *3D model in tooltips*): a creature's or a player's portrait is its live 3D
  model, moving, its face in view, always, without Alt (Saneroki, 2026-10-21); the flat portrait only stands
  in while the model is not there, and stays only where the game cannot give it. A mount (the item that teaches
  it, the spell that summons it) and a pet (the item that teaches it) show their model, a little from the side.
  The icon stands until the game has loaded the model; a unit the game refuses at first (its model not ready
  yet) is asked for again ten times a second for a second (`Panel.RETRY`, `Panel.RETRIES`), so its model comes
  without a new draw. A piece of gear keeps its icon. **Hold Alt** over a piece you can see on a character (a
  helm, a chest, a weapon, a cloak; not a ring): your own character wearing it, as the game's dressing room
  puts it on you, stands beside the panel, as high as the panel, see-through (no ground of its own), turning
  slowly round (once in ten seconds). It stands at the panel's left; at its right where the left has no room
  on the screen or the comparisons stand there. Let go of Alt and it is gone; where your character cannot
  try the piece on, there is none.

  **Gathering:** on a herb or an ore in the world, under *Professions*, the skill it needs with its icon, in
  the colour of your chance of a point for gathering it: orange (a point each time), yellow, green, grey (no
  points any more), red while your skill is below what it needs or you do not have the profession. On the
  node's own tooltip that is the colour the game gives its line of the skill, where it gives one of its
  colours of difficulty; else it is worked out. After it, small, your skill (*160/225*) or *Not learned*; at
  the right where each colour begins, each number in its colour (*125  150  188  225*: what it needs, the
  node's own yellow, green halfway from there to grey as the game colours a recipe, the node's own grey).
  On what herbs and ores give (a herb, an ore, a stone, *Swiftthistle*), the node that gives it by its name
  the same way, in the same section as the professions that use it, the easiest first; without Alt only that
  one and *Press ALT for +1 more*. From Core's data (the nodes, the skill each needs, where each turns yellow
  and grey, what each gives); a node is known by its name, in English.
- **Hold Alt** for the technical details: a small section at the bottom of every panel, *IDs*, with the number of
  the thing at the left (*Spell ID*, *Item ID*, *NPC ID*, *Quest ID*, ...; a player's GUID) and the number
  of its icon at the right (*Icon ID*), and after it other addons' lines (*Addons*). Pressing or letting go
  of Alt redraws the panels that are shown. On an item Alt shows more too: every quest that needs it
  (without Alt, three of those not in your log), every node that gives it (*Professions*), which of your
  characters have it (*Inventory*), in the Gold section each material of disenchanting it and the price to
  post it at (*Sell at*), under the advice where its numbers come from (the lowest price, how many are on offer and when that was seen, the market price; the cut
  and the deposit), and over a piece of gear your character wearing it beside the panel.
- **A link clicked in chat** (an item, a spell, a quest): its tooltip opens in the middle of the screen and
  stays. Click it to close it (Esc does too); it has no X. It can still be dragged, and Shift over it
  compares an item with what you wear.
- **A comparison** (Shift over a weapon or armour): the panel of what you wear says *Equipped* at its
  top, where another item says how it binds, and is a little transparent, so the item you look at stands
  out. The changes the game lists (*+2.2 DPS*) are lines of the panel, without the sentence over them.
  The panels of what you wear stand at fixed places on the screen beside the panel of the item, so far
  apart that their soft edges just meet, their tops in a line: the first next to it, the second next to the first, on the side there is
  room for. While you point at the same thing they stay there, whatever the game does with its own
  comparison tooltips; when the item's panel moves (it follows the mouse), they follow once it has
  stood still for a moment.
- **Gold** (`Kinds/Gold.lua`): the game's own *Sell Price* line is left out; the section at the panel's end
  has these rows, each only when it is known, and **always for one** of the item, also when you point at a
  stack, so the two ways compare one to one:

  | Row | What it is |
  |---|---|
  | *Vendor* | What a vendor pays for one; on every item (from the game's item data, `GetItemInfo`, also where the tooltip has no price line), *Can't be sold* where no vendor buys it |
  | *AH profit* | What a sale of one at the auction house brings: the lowest price there now, less the house's cut (5%, 15% at a neutral house). Not for a thing that is bound |
  | *Disenchant* | What disenchanting it brings, on a weapon or an armour of uncommon quality and up: every material it gives, as often and as many as disenchanting gives it (Core's data, by the item's class, quality and item level), each at the lowest price you saw for it less the house's cut. *no prices seen* while a material has no price yet. With Alt, under it, each material: how often, how many, what one brings (*80%  1-2 Strange Dust*) |
  | *Sell at* | With Alt, where the item can go to the auction house: the price to post one at, just under the lowest offer you saw (a copper for what stacks, 1s for what does not, whose prices are whole silver), never so low that a sale (after the cut) brings less than a vendor pays |

  **With Alt, a graph** ends the section (`PriceGraph.lua`), on what can be sold at the auction house: how its price went
  there, the lowest price in gold, the market's in grey, between the highest and the lowest price of the range. Buttons
  over it choose the range: *24h*, *1w*, *2w*, *1m*, *All*. A tooltip goes when the mouse leaves what it stands for, so
  **tap Ctrl** for the next range, a key that does nothing in the game by itself and so also works in a fight; the buttons
  light up as you go. Only the tooltip of a chat link stays, and there they are clicked as well. The range is kept, and
  stands in the settings as *Price graph's range*. Over the last two days each scan is a point, before that each day.

  Last, **the advice** in one line: the way that brings the most (the auction house must bring 5% more
  than a vendor, for the trouble). *Disenchant it for 1s 40c* (green; only for a character with the spell, and it too must bring 5% more than the way before); *Sell on the AH for 3s 09c* (green; the lowest price now); *Sell to
  a vendor* (at the right how much more than the auction house, *+12c over the AH*, where a vendor pays
  more). On an item the auction house lists to you (you buy it: the game filled the tooltip by the item's
  key, `GetItemKey`, or by its link without the vendor's price, `GetHyperlink` with `hideVendorPrice`, which
  only the house's lists ask for; and while it shows what it sells, not your own auctions:
  `AuctionHouseFrame:GetDisplayMode()`) it is *Buy if under 2s 79c* instead: the most it is worth paying, what it brings again at
  the auction house (less the cut) or from a vendor; green while the lowest price now is under it, red
  over it, *now* and that price at the right. A vendor's price alone (no auction price known) stands under
  the caption *Gold* too, with no advice. With Alt, small under the advice: *Lowest* and the price the
  numbers come from, then the cut and the post: the deposit for the duration you last chose in the game's Sell tab, at the least 1s.

  **When to buy and sell** (Saneroki, 2026-10-30): as the scans build up, the advice looks ahead. Core learns from each full
  scan what an item usually costs, where that is heading, how it swings with the time of day (three-hour stretches, by your
  clock) and the day of the week, and how much of it sells; a time is named only where it stands clear of the item's own noise.
  From three days of an item's prices on:

  | Where | What it says |
  | --- | --- |
  | On the auction house's list | *Buy if under 15s 40c*, *now 10s*: the most worth paying, so that a sale at its best time still brings 10% more after the cut and the post. Green while it costs less. Under it, in green, *Sell Fri 18:00-21:00 for 20s*, *+8s 80c each*, and small, *12 on offer under 15s 40c*. Too dear now: *Buy Tue 03:00-06:00 for 14s* if it will be cheap enough then |
  | Anywhere else | *Sell Fri 18:00-21:00 for 20s*, *+1s 90c more*, in place of the advice to sell now, where a sale then brings 5% more than the best way now. *Sell Sat for 11s*: the day counts, not the hour |
  | With Alt | *Usually 18s*, with *rising 2% a day* or *falling*; *Dearest ...* and *Cheapest ...*, each about what; *Sells 34 a day at about 17s*, or *No sales seen*; away from the list *Worth buying under ...*; *Too few scans for a forecast yet* before the three days |

  **The post** counts in everything the auction house is weighed by: the deposit (Core's *Fees*, `Doc/guides/data.md`), at the least 1s
  for an auction, shared by as many as others put in one auction. A sale gives the deposit back and an auction that runs out keeps it (the
  game's mail reckons so), so it counts in full, as one failed post for each sale: what is advised stays worth it even then. An
  item nobody was seen buying, in half a day of watching or more, gets no advice to buy it to sell on.
  **The prices** are Core's (`Data.Series("Prices")`, `Doc/guides/data.md`, *Prices*): what the auction house
  lists right now while you look at it, else its last full scan. A price not seen for 30 days counts for
  nothing. The shown panels are read anew when prices change. The module keeps none of its own.
- **Quests** (`Quests.lua`): what you must kill the game says in the tooltip's own quest lines. Which
  creature drops a quest item, who gives which quest and who takes it back, the game does not say; Sane UI's
  database has it (Core's data framework, `Doc/guides/data.md`), in two data packs that load soon after the
  login: *Data: Quests* (the set *Quests*: 4796 quests with their levels, side, races and classes, what they
  ask first, who gives and takes them back (1805 NPCs), the items that start them (370) and the items their
  objectives ask for (2395)) and *Data: World* (the set *Drops*: what 3883 creatures drop for quests, with
  how often). The module only reads them (`Data.Set("Quests")`, `Data.Set("Drops")`): it asks for them at
  the login, has no quest part in a panel until they are there, and draws the shown panels anew when they
  come. With *Data: Quests* switched off in the addon list, the panels have no quest part and nothing fails.
  An item's panel shows every quest for you that wants it, and the quest it starts, each with where you
  stand with it: in your quest log (with your count), done, one you can take now (here also one far below
  your level), or one for later; quests of the same name (the same quest at other places) once. A
  creature's shows an item it drops that starts a quest you can take, with how often. Both under the
  caption *Quest*. Every quest's name in a creature's section has its level at the right, in the colour of
  how hard it is (the game's quest line says which quest it is); in an item's, small after the name (*[12]*).
  **Drop chances** are in the data where they are known (6381 of 10034 drops; most without one are
  Forever's own quests), in whole percent: *33%* after the item's name, on the game's own objective line
  too, *<1%* below one. Your progress comes from your quest log (`C_QuestLog.GetQuestObjectives`).
  What is found for a creature is kept until your quest log, your level or the data
  changes (`QUEST_LOG_UPDATE`, `QUEST_TURNED_IN`, `PLAYER_LEVEL_UP`, `PLAYER_LEVEL_CHANGED`, the sets'
  stamps): its tooltip is read many times a second. At most 400 creatures' lists are kept, and 400 items',
  then they are forgotten together. A failure while the list is made is noted and told once;
  what was found before it stays.
  Whether you may take a quest: it is meant for you (your side, also for this client's own races; your race
  by the game's race ID, your class by its class ID), you have reached its lowest level and not passed its
  highest, the quests it asks first are done and none that closes it is in your log or done. An NPC leaves
  out what the game shows grey for your level (`UnitQuestTrivialLevelRange`). A quest that repeats is
  offered by no NPC in the data: it shows while it is in your quest log.
- **Inventory** (`Kinds/Inventory.lua`): on an item's panel while Alt is held, under the caption *Inventory*, every character
  of your account that has it, each by its whole name, first name and surname (*Sane Lunatic*, never
  *Sane*), in its class's colour (see *Colour players by their class*): you first, then the others by name,
  the account's own bank last; at the right where and how many (*Bags 12 · Bank 8*, *Worn 1*). With two or
  more, *Total* and how many in all. Two characters
  with the same first name are two characters. Sane UI keeps this itself (Core's data framework: the pack
  *Data: Characters*, which ships nothing and keeps what your characters have in its own saved file, never
  shared): each character's bags, what it wears and its bank as last seen. A character's bags are known
  once it has logged in, its bank once you have opened the bank with it; the panel follows a change at once
  (read a moment later, never in a fight).
- **Spell numbers** (`Numbers.lua`): the amounts come from the spell's description, whose numbers on
  this client already hold your spell power and talents. The description is cut at its numbers and the
  words between them say what each is: an amount (*16 to 25* counts as its middle), an amount spread over
  a time (*45 damage over 15 sec*) or repeated each second for it, a time; the words before the first
  amount say whether it heals. Per second means cast again and again: one cast takes its cast time, at
  least the global cooldown the game gives for it, and waits for its cooldown; of what it does over time
  only the part before the next cast counts (for a heal or damage over time alone: per second of its
  time). Per point of what it costs; your chance of a critical strike with spells (`GetSpellCritChance`:
  one chance for all schools on this client). English descriptions only. A strike that adds to the
  weapon's damage, a shield and the like have no numbers.
- **Experience** (worked out, not recorded): the original game's rule, one table by your level of how
  far below you a creature's gain fades to nothing and from how far below it is grey (nothing); a creature
  above you gives 5 % more a level, for four levels; twice for an elite, twice again while you are rested.
  The kills are what is left to your next level divided by that. Not for players, friends, a creature
  somebody else has tapped, nor at the highest level. Forever's rule only: Retail gives experience otherwise
  (its creatures' levels follow yours) and does not say how much, so there a creature has no such row.
- **The test realm's line** *Press F6 to submit an issue for this ...* is left out of every panel.
- **Hints** (a button's name and explanation, lines somebody wrote into a tooltip) get a panel too: their
  lines as written, in their colours.
- **What stays the game's own:** a tooltip with a bar, an item or another frame inside (the panel could not
  show it in full); a tooltip with a line the game hides in a fight (it cannot be read); a tooltip nobody
  sees (another addon's, to read things with).
- **In a fight** a unit's buffs are not shown (the game does not hand them out then), and a tooltip the
  game hides lines of stays the game's own.
- **In Retail** the panels are the same, but for what needs Forever's rules or Sane UI's database, which holds
  no Retail data yet: there an item's and a creature's panel have no quests from the database (the game's own
  quest lines stay), no chances of gathering under *Professions*, no *Disenchant* row under *Gold*, and a
  creature no experience row; a player's class line has the specialization without talent points.
- **After an update of this module, restart the game** if the update brought new files: a `/reload` does
  not read new files. The module notices and says so in chat; until the restart the tooltips are the
  game's own.
- **If something goes wrong** the module says so once in chat. If it went wrong while one kind of tooltip
  was read (an item's, a spell's, ...), only that kind is the game's own until the next `/reload`; the
  others keep their panels. Anything else takes all panels away and leaves the game's own tooltips until
  the next `/reload`. `/sane errors` shows what it was.

## Technical details
- **A panel over the game's tooltip.** The game's tooltip cannot be laid out differently: it places its
  lines itself. So a panel of our own is drawn over it and the tooltip is made invisible (alpha 0). The
  tooltip stays in charge: the game places, fills and hides it as always, other addons read and extend
  it, and the panel follows.
- **Reading** (`Read.lua`): the tooltip's own lines as they stand (`GetLeftLine`, `GetRightLine`: text and
  colour), so every language and other addons' lines come along. The data the game filled the tooltip
  from (`TooltipDataProcessor`) says what kind of thing it is and what kind each line is
  (`Enum.TooltipDataLineType`; a line is found by its `lineIndex`, or by its text if the data has none).
- **Kinds** (`Kinds/`): one file per kind of thing. Each sorts the lines of its kind into rows with the
  tools of `Read.lua` and asks the game for what the lines do not say (an item's quality, a unit's guild,
  a buff's caster). A kind without a file gets `Read.Generic`. Each reader runs in an `xpcall` of its own
  (`ns.Read`): one that fails (a client update renamed a function it uses) is noted and told once
  (`ns.Report`) and switched off, and the tooltips of its kind are the game's own from then on.
- **Columns** (`Panel.lua`, `Columns`): the rows are laid once in one column; where that would be taller than the
  screen in the panel's units (`Tallest`: `UIParent`'s height by the scales, less `SCREEN_MARGIN` and the soft edge
  above and below), each column ends before the row that would run past it (a caption goes on with its rows), the
  lines and icons of the first laying are given back (`Pools.Rewind`) and the rows laid again, each column starting
  at the top `width` further right (`ox`); the panel is `width` times the columns wide, a groove between two.
- **Notes at the bottom** (`Read.lua`, `Note`): a line that is Core's `Core.UNCONFIRMED` is left out where it stands
  (`Read.Rest`) and becomes, after everything else (Alt's details and other addons' lines too), a caption row that
  is `bare` (no rules) in the font kind `hint` and grey (`NOTE`, `COLOR.ASIDE`), with `mark`: a red *!*
  (`FONTS.mark`, `COLOR.RED`) at each side of the words; then, without Alt, *Hold ALT for more* the same way.
- **A creature on a map** (`ns.Figure`, in `Kinds/Unit.lua`): a tooltip without the game's data that carries a look
  of Core's (`Core.LookOf`: `display`, `dragon`, `badge`, `sections` by line) is read as a creature's: its model as
  the head's `display` model (zoom 1: the face), the skull (`SKULL`) while none loads; each line after a heading of
  `Core.TipSection` in that section (`ctx.name`); a row's `|T...|t` icon at its start, a line set in by spaces
  (`ctx.each`) set in under the icon (`DETAIL_IN`), small.
- **The model** (`Model.lua`): a head and a list of rows, plain data. It has two copies, the one that is
  drawn and one to fill. A shown tooltip is filled again several times a second; after a fill the copies
  are compared, and only a difference draws the panel again. The tables are used again, texts put
  together from parts are kept (`Read.Memo`): reading the same tooltip again makes no new tables.
- **Lines known only by what they say.** The game has no kind for "Durability 61 / 120", "Requires Level
  58", "(53.8 damage per second)", "115 Armor". Where the game keeps the sentence in a global
  (`DURABILITY_TEMPLATE`, `ITEM_MIN_LEVEL`, `DPS_TEMPLATE`, `ARMOR_TEMPLATE`), a pattern is made from that
  and every language works; `Texts.lua` has the English wording as a fall-back. A spell's cost, range,
  cast and cooldown are found the same way, by the game's own sentences for them (`ns.FACTS`: `MANA_COST`,
  `SPELL_RANGE`, `SPELL_CAST_TIME_SEC`, and its sentences for a cooldown; the game has no function for a
  spell's cooldown as such): a number is shown with a short unit of ours (*3 min*), a sentence without one
  as written (*Channeled*). Its school is found by English words only: in another language the panel has
  no school colour.
- **Drawing** (`Panel.lua`): one frame per tooltip, made when that tooltip is first filled or shown (not
  at login), with pools of texts, thin lines and small icons (`Pools.lua`: each pool a `Core.Pool`,
  a list of the parts made and how many the draw has taken; a draw hides only what the last one took).
  A draw goes in four steps: every text made and measured (`Measure`), the icon or portrait with its
  plaque (`Picture`), the rows top to bottom (`Lay`), then the background, the dragon and the frame
  levels (`Finish`). The rows before the first section's caption stand beside
  the icon. The width follows the content, in steps of 8 (from 224 to 432), so a line a little longer or
  shorter leaves the edge where it was; a line that wraps counts as 22 ems at most (22 times its text size).
  Where a row's two sides do not both fit, the left one keeps its room and the right one is cut short on
  one line; it keeps 4 ems at least. A text's size is hidden from addons while what it
  hangs on is placed by something hidden, so a panel lets go of its tooltip before it measures and is
  placed again after; a size that is still hidden spoils that draw, and the tooltip is the game's that
  time (`Pools.Spoilt`). The tooltip's frame level is used only when it is not hidden.
- **One look.** Behind everything lies the game's own tooltip ground (`TOOLTIP_DEFAULT_BACKGROUND_COLOR`)
  taken toward the panel's colour: 28% of the way at the top; at the bottom the ground darkened, and 6%
  of the way. The opacity setting is its alpha. Its shape has round corners and an edge that fades out
  softly: it reaches 8 past the panel's sides, and the panel's content stands on its solid part. No
  border, no band behind the name, no boxes. The only dividers are the sections' captions: a section's name
  stands in the middle in small capitals, grey (`NOTE`), and a rule runs from each side of the panel to it, one
  hairline each, 6 from the name; the rules in the same grey (`COLOR.NOTE`), as are a table's captions, the lines
  between its cells and the line between two columns; a hairline is one unit of
  the interface rounded to whole dots of the screen (`Core.Pixels`, by the game's `PixelUtil.GetNearestPixelSize`). An empty line of the
  game's inside a section is a small gap (a row's `space`).
- **The icon** (or a unit's portrait) is 64 large and stands out over the panel's top right corner, 10 past
  the right side and 10 over the top; the rows beside it make room for it. Its edge fades out softly, like the panel's: a
  square icon has round corners (`Art/icon-mask.tga` as a mask), a portrait is a circle
  (`Art/portrait-mask.tga`). A level or
  item level stands on a plaque on the icon's lower edge, half on it and half under it: a gold rectangle
  whose edge fades out softly like the panel's (`Art/plaque.tga`, stretched with its corners kept, darker
  gold at the bottom), hardly larger than its words. Its right side stays where a plaque with a level
  alone has it; longer words reach left, and the rows beside it make room for it. Outlined words: a unit's level in the colour of how hard it is for you
  (`GetCreatureDifficultyColor`), an item level light. Without an icon or portrait (*Show the icon* switched
  off, or none) there is no plaque: the level stands right of the name, in the same colour.
- **The dragon round a portrait** is the game's own from its target frame (`Interface\HUD\UIUnitFrameBoss2x`,
  which the game lays round the target's portrait by rank): gold for an elite and for a player, gold with a
  great wing for a boss (`UnitIsBossMob`, or a world boss), silver and winged for a rare and a rare elite. Moved in by 4, as the portrait's round picture is a
  little narrower than its square.
  Each curls round a circle; its place on the sheet and the middle and inner radius of that circle were
  measured from the art (`DRAGONS`, `DRAGON_RING` in `Panel.lua`; the reference has no atlas file for the
  sheet), and it is scaled and placed so that the circle lies on the portrait and covers its edge by 2.
  Over the portrait, under the texts.
- **The 3D model** (`Figure` in `Panel.lua`, `Figures.lua`): a model frame of the game's in the picture's
  place, 64 large, on a see-through ground, so no picture of it is shipped. A unit's: a `PlayerModel` given
  the unit (`SetUnit`) and turned to its face (`SetPortraitZoom(1)`), moving. A mount's and a pet's: the same
  frame given the creature's display (`SetDisplayInfo`; the display from the game's collections:
  `C_MountJournal.GetMountFromItem`, `GetMountFromSpell`, `GetMountInfoExtraByID` or the first of
  `GetMountAllCreatureDisplayInfoByID`; `C_PetJournal.GetPetInfoByItemID`'s twelfth answer), turned a little
  (`SetFacing(-0.5)`). What a thing has is asked once per thing and kept (at most 400 things, then they are
  forgotten together). The frame is made for a panel's
  first model. It is given its model only when that changes (the unit's GUID, the display): giving it again would load the model anew and start its moves over,
  and a panel is drawn many times while it is shown. It keeps its model while hidden (`SetKeepModelOnHide`):
  the same thing shown again is not drawn anew, and its model stands at once. The picture stands until the
  model is there: a unit's at once when `SetUnit` says it can draw it; the others when the game has loaded
  the model (`OnModelLoaded`, or `GetModelFileID` at once). Where the game does not take the model (the unit
  out of sight, its identity hidden, an error) or the client has no such frame, the picture
  (`SetPortraitTexture`, the icon) stays, as with the option switched off, and the game is asked again at the
  next draw. A model needs the picture's place:
  with *Show the icon of items and spells* off there is none. A frame draws over the panel's own pictures, so the
  dragon, the plaque and the level stand on a frame over it (`panel.front`; the level's text is lifted onto
  it, `Pools.Lift`). Its alpha follows the panel's by itself (`Panel.Strength`): a model frame need not follow
  the frame it is in. Unlike the picture it has no round soft edge (a mask works on pictures only): it is cut
  square.
- **Your character beside a piece of gear** (`Panel.Stage`, `head.dress` from `Figures.lua`): which pieces, by
  `C_Item.IsDressableItemByID` (where the client lacks it, by where it is worn, `GetItemInfoInstant`); the
  link from the tooltip (`GetItem`, else `item:<id>`). A frame of its own beside the panel, made the first
  time Alt is held over a piece, see-through (no ground: your character stands free), and in it a
  `DressUpModel`, 4 in from its edge. As high as the panel, 0.6 of that wide, 16 from the panel (as far as two
  panels stand apart); at its left, at its right where `GetLeft` leaves no room or the
  comparisons stand on the left (`Host.CompareSide`). Your character is given once (`SetUnit("player")`) and
  kept while hidden (`SetKeepModelOnHide`); each time the stage is shown, or the piece changes, it is dressed
  in what you wear (`Dress`), the whole of you (`SetPortraitZoom(0)`), and tries the piece on (`TryOn`); a
  piece it cannot wear (`TryOn`'s reason) leaves no stage and is not tried again until another piece comes.
  It stands unseen until the game has loaded your character (`OnModelLoaded`, or `GetModelFileID` at once).
  It turns by its `OnUpdate`, which runs only while it is shown: `SetFacing`, from where the game's dressing
  room turns you (`MODELFRAME_DEFAULT_ROTATION`), one turn in ten seconds (the
  game's own turning of a model, `ROTATIONS_PER_SECOND`, is five times as fast: made for turning it by
  hand). `Panel.Stage` runs at every draw and once a frame while the panel is shown (`Watch` in
  `Tooltips.lua`), so Alt, the comparisons and a move on the screen are followed at once; it sets the
  stage's size, side and frame levels only when they change. Its alpha follows the panel's
  (`Panel.Strength`). Not for what you wear beside an item (a comparison), not with the option off.
- **Rare drops** (`Gathering.lua`): under the skill, small, what comes seldom as Core's `Data.Drops()` counted it: on a herb or a vein its
  rare drops (at most three), on a rare item where it came from, each with how often (`Star Ruby  7.5% (3 of 40)`, `1 of 40` while too few came).
- **Gathering** (`Gathering.lua`, `Kinds/Object.lua`): Core's sets *Objects* (a node's name, kind, skill line,
  the skill it needs, and where it turns yellow and grey, `yellowAt` and `greyAt`; the index `byName`) and *Drops* (`object:<id>`, what it gives, `how = "gather"`;
  the index `byItem`). A thing in the world is found by its name (`Objects:Keys("byName", ...)`: the tooltip
  of a thing in the world gives no ID), what a node gives by `Drops:Keys("byItem", ...)`; each kept by name
  and by item until the data changes (`OnStamp`), nothing kept while the packs are not there; at most 400
  names, then they are forgotten together. Your skill: `C_SkillInfo.GetSkillLineInfoByID` (rank, its bonus
  `modifier`, `maxRank`, the skill's name in your language), kept until `SKILL_LINES_CHANGED`. The chance:
  red while rank and bonus are below what the node needs, orange from it, yellow from its `yellowAt`, green
  from halfway between that and its `greyAt` (rounded up: the game's way with a recipe's colours), grey from
  its `greyAt` (by the rank alone); a node without the two is orange while you can gather it. On a node's
  own tooltip the colour of the game's line of the skill wins where it is one of the colours of difficulty
  (`ns.Like`). The rows join the section *Professions* (`Read.Section`). The colours are the game's (`IMPOSSIBLE_`, `DIFFICULT_`, `FAIR_`,
  `EASY_` and `TRIVIAL_DIFFICULTY_COLOR`; where the client lacks them, `QuestDifficultyColors`), the icons
  the professions' (`Trade_Herbalism`, `Trade_Mining`). On a node's tooltip the game's line that names the
  skill (*Herbalism*, *Requires Mining 175*) is left out. The packs are asked for at the login (`Prepare`).
- **The price graph** (`PriceGraph.lua`, its row asked for by `Kinds/Gold.lua`, its room by `Panel.lua`): a row of kind
  `graph` holds only the item, the range and `Prices:Stamp()`, so a read of the tooltip costs a look at `Prices:Last`, and the
  panel is drawn anew only when the range or a price changed. The points come from `Prices:Range` when it is drawn (a house's
  history taken apart once per item, kept for 64 items until the next scan). Marks at most one per 3 units of the width: the
  lowest price and the last market price that fall there, each at its true place on the time line. Strokes are a pool of
  `Line`s (`Pools.Stroke`), laid after the rows have their final places, in columns too. Keys: a tooltip goes when the
  mouse leaves what it stands for, so `Graph.Key` hears `MODIFIER_STATE_CHANGED`: Ctrl pressed, with a graph in sight and
  the tooltip allowed. No keyboard frame: the game restricts the call that hands keys on, and a key of its own would run
  into bindings. A tooltip that takes the mouse (the chat link's) gets real buttons over the words (`Hit`), whose click stays
  theirs, so it does not close it; no other panel has any, so a tooltip never catches the mouse.
- **Disenchanting and the price to post** (`Kinds/Gold.lua`): Core's set *Disenchants* (pack *Data: Items*,
  asked for at the login; keyed by the game's rows of disenchanting: the items' class, quality and item
  levels, and the materials with their chance per disenchant, in percent, and how many, from and to). An
  item's row is found by its class (`GetItemInfoInstant`: weapons and armour), quality (uncommon and up) and
  item level (`GetItemInfo`'s fourth answer) through the index `byQuality`; kept per item until the data
  changes (at most 400 items). Its value: Σ chance × the average count × the lowest price now less the
  cut (`Gold.Sale`), rounded; none while a material has no price. *Sell at* (`Gold.PostAt`): the lowest
  offer you saw less a step (Core's `Prices:PostAt`, `Prices:Step`), never under what makes a sale after the cut bring a vendor's
  price (`ceil(vendor / 0.95)`); with Alt, for a thing that is not bound.
- **The forecast** (`Kinds/Gold.lua`, from `Prices:Outlook`, Core's `Data/Rhythm.lua`, `Doc/guides/data.md`, *The forecast*): `Work`
  fills `post` (`Prices:Post`) and, from `Prices.TRUSTED` (3) days on, `outlook` and `limit` (`Prices:Limit`), none where `daily` is 0: the
  numbers are Core's (`Data/Fees.lua`), so Economy's tab says the same. The advice *later* needs `highAt` after now and `Prices:Later`
  (5% over the best way now). `Plan` writes the rows under *Buy if under*, `Forecast`
  Alt's. `When` names a stretch (`STRETCH`, 3 hours) by `Core.ClockAt`, or the day alone with `allDay`. A tooltip's read costs a look at a
  table: `Prices:Outlook` holds what it read per item for the hour, and until a scan is kept.
- **The durability bar** (`Panel.lua`, a row with `inside`): a bar like a unit's health bar (`LiveBar`, 18
  high, flat and half see-through, under the panel's mask for round corners) with the word and the numbers
  written inside (`BarText`, left and right); its values are plain, so it is set like any bar.
- **The line that Alt shows more** (`Read.lua`): the last row of every panel of the game's data while Alt is
  not held, a `bare` caption as written (no `caps`, no rules) in the font kind `hint`, grey; with Alt the details
  and other addons' lines come in its place.
- **A spell's table** (`Kinds/Spell.lua`, `Panel.lua`): two rows of the kind `strip`, four cells each (one row
  for a spell that neither hurts nor heals), every cell filled (`TEXT.NONE` where nothing is known). The
  columns of all of a panel's tables are alike, each a quarter of the panel, which is made wide enough for
  the widest cell of them all (`widestCell`), so the rows line up. What a spell asks of you is known by the
  game's sentences (`SPELL_REQUIRED_FORM`, `SPELL_EQUIPPED_ITEM`; reagents and tools by the beginning of
  `SPELL_REAGENTS` and `SPELL_TOTEMS`) and stands under its school as rows of its own. Melee range is the
  game's word `MELEE`. Where the spell states no cost, the cost's caption is your own power's name
  (`UnitPowerType`). The last cell is *Duration* where what it does lasts (`Numbers.Spell`'s `lasting`), else
  *Crit*.
- **Fonts and the text size.** The font file is asked of the game's font objects at every draw
  (`GameTooltipText`, `GameTooltipHeaderText`), so the game's language and a UI addon's font are
  followed; the size is set by us (`SetFont`), because it is the player's setting. Name and lines have
  that size, a weapon's number 4 more, subtitles and the strip's values 2 less; another addon's lines,
  captions and a unit's details 4 less (10 at the default size, as the game's own small font); the line that
  Alt shows more 6 less (8 at the default size, never under 7). Every kind of text has its font's own shadow
  (offset and colour, `Pools.lua`).
- **Colours.** The panel's colour is the game's own for the thing: `ITEM_QUALITY_COLORS`,
  `RAID_CLASS_COLORS`, the colour of what takes an aura away (`AuraUtil.GetDebuffDisplayInfoTable`, the
  game's for the borders of debuffs), the colours the game's combat log gives the spell schools,
  `PowerBarColor`, `GetCreatureDifficultyColor`, or that of the tooltip's first line. A line keeps its
  colour, except the game's white, which is toned down a little toward its grey, and its gold (which it
  writes descriptions in), which is made lighter. Every other colour of ours (`ns.COLOR` in `Model.lua`)
  is one of the game's font colours (`HIGHLIGHT_FONT_COLOR`, `NORMAL_FONT_COLOR`, `GRAY_FONT_COLOR`,
  `RED_FONT_COLOR`, `GREEN_FONT_COLOR`, ...) moved part of the way toward another of them (`Tone`): a
  name nearly white, a table's values white, what is said about a thing light grey, a section's name, its rules,
  a table's captions and its lines and the notes at the bottom one grey (`COLOR.NOTE`), what is done green, what you
  cannot do red. A physical spell is the game's red (its combat log has physical yellow, too close to holy). A line's colour is known by being close to one of
  the game's (`ns.Like`). A colour inside a line is written by `ns.Hex`.
- **Five pictures are ours,** made by `dev/tools/tooltip-art` (the game has none like them):
  `Art/soft.tga` (64 x 64), a white square with round corners and a soft edge, with which the background
  is drawn, stretched with its corners kept (`SetTextureSliceMargins`) and coloured by the gradient; and
  four masks (`CreateMaskTexture`), all with an edge that fades out softly: `Art/icon-mask.tga` (64 x 64,
  round corners, the outer 6 fading) for a square icon, `Art/portrait-mask.tga` (64 x 64, a circle) for a
  portrait, `Art/bar-mask.tga` (256 x 16, round corners) for a unit's bars and a buff's bar, and
  `Art/aura-mask.tga` (32 x 32) for the small icons of a unit's buffs. A mask is stretched
  whole (slice margins do not keep its corners: tried, it cut the icon to a strip), so each mask is made
  in the shape it is used in.
- **What changes while a panel is shown** (`Live.lua`): a unit's health and power, its target, its buffs,
  a buff's running time. `Panel.lua` lays these parts out, `Live.lua` fills them ten times a second (the
  buffs twice), from the panel's `OnUpdate`, which only runs while the panel is shown. When the unit gets
  or loses a row (a target, its buffs), the tooltip is read anew. The unit is asked for by a token
  (`mouseover`); once the mouse has left it, that token is another unit or none: the unit's GUID is kept
  in the model, and while the token's GUID differs, the panel stands still.
- **Gone at once when the mouse leaves.** The game lets a tooltip fade out slowly once the mouse has left
  what it is about (a unit or a thing in the world, a unit frame: `FadeOut`). `FadeOut` is hooked, and
  the panel hides at once (`Faded` in `Tooltips.lua`); a draw that waited is dropped. The game's tooltip
  is left to fade and hide as the game does (hiding it from an addon would taint it); its parts keep alpha
  0 meanwhile, so it is not seen either.
- **Texts that may hold a hidden number are kept apart.** A text that was once given a number the game
  hides (a unit's health in a fight) answers every question about its size with a hidden number from then
  on. The texts `Live.lua` writes are therefore not from the pool: one for each use (`LiveText` in
  `Pools.lua`), never measured, never used for another line.
- **Another player's item level** (`Inspect.lua`, Core's `Core.Inspect` since 2026-10-23, `src/Core/Inspect.lua`,
  shared with the nameplates) can only be had by inspecting them: the game asks the
  server (`NotifyInspect`) and says when the answer is there (`INSPECT_READY`, then
  `C_PaperDollInfo.GetInspectItemLevel`). Paced: only out of a fight, when `CanInspect` and
  `CheckInteractDistance` allow it and the game's inspect window is closed; one question at a time, 2
  seconds after anybody's last (`NotifyInspect` is hooked to see other addons' too), the same player not
  again for 15 seconds, no answer after 5 seconds counts as none. An answer is kept 5 minutes. When it comes,
  the panel is drawn anew and the plaque says it. Your own is
  `GetAverageItemLevel` (the equipped one). Past 200 players, the old answers and questions are forgotten.
- **Secret values.** Everything read goes through `Core.Plain`. A hidden line leaves the tooltip to the
  game; a hidden colour makes the panel grey. A unit's health and power are handed to the bars and to
  `SetFormattedText` as they are (`BreakUpLargeNumbers`, `UnitHealthPercent` with
  `CurveConstants.ScaleTo100`), without computing. Buffs are only asked for outside a fight and when
  `C_Secrets.ShouldAurasBeSecret` says they are open, in a `pcall`. A buff's bar is driven by the game's
  own timer (`StatusBar:SetTimerDuration` with `C_UnitAuras.GetAuraDuration`) where the client has it.
- **The game's tooltip behind the panel** (`Host.lua`): out of sight (alpha 0), and so is each piece of it
  that can be seen (border and ground, lines, small pictures, the bar under a unit's, coins, the tab over
  a comparison: `Host.Blank`), because the game sets the tooltip's own alpha when it shows it and when it
  fades it out, but never its pieces'. Nothing else of it is changed (but the chat link's tooltip, below),
  not its size, not its place: the game lines up comparison tooltips by the tooltips' sizes, and a size of
  ours would come back as comparisons that jump. The panels place themselves: a panel takes the corner its
  tooltip hangs by (`GetAnchorType`, or its points). **Comparisons** (the `shoppingTooltips` of
  `GameTooltip` and `ItemRefTooltip`) stand at places of the module's own: the game sets its two
  comparisons again several times a second (each hidden, filled and placed anew, now one on the other,
  now the other way round, the lines of what would change a moment after the rest;
  `TooltipComparisonManager`), and a panel that followed all of that would flicker. So they stand at
  absolute places (`Pin`: a point on `UIParent`), worked out from what holds still (`Compare`, `Lay`): the
  main panel's place, taken when it shows a new thing (owner and item) or shows again after it was gone,
  once it is drawn for it (the game fills the comparisons before it tells of the tooltip they belong to; the
  end of the frame draws that tooltip first), and afterwards only once it has
  rested in a new place for 0.12 seconds (`Host.Track`, every frame of the main panel: a wobble is never
  followed, a move is); a side decided once for that thing (right where all of them fit, else left, else
  where there is more room; the game's side where nothing can be measured); and for each comparison a
  slot as wide as the widest its panel has been for that thing, so the second does not move while the
  first is hidden, refilled or narrower for a moment. The slots are as far apart as two panels' soft edges
  reach (16), tops in a line. A panel is only placed again when its place changes.
  Any other tooltip the game set beside a tooltip with a panel (a comparison of another tooltip) has its
  panel set beside that panel, on the same side, tops in a line (`Beside`). Each panel keeps itself on the
  screen. When the panel goes, `Host.Free` sets every alpha back: the tooltip's first, then each piece's by
  itself (`pcall`), and the panel lets go of what it hung on. The pieces found by their names
  (`GameTooltipTexture1`, `...StatusBar`, `...MoneyFrame1`) are looked up once per tooltip. A tooltip held
  by its middle alone has its panel in its middle.
- **The chat link's tooltip** (`ItemRefTooltip`, `Pin` in `Tooltips.lua`) is the one tooltip whose place is
  ours: its `OnShow` puts it in the middle of the screen (the game opens it with `ANCHOR_PRESERVE`, so it
  stays there). A press on it that did not drag it closes it with `Hide`, which is what the game's X does
  for it (`HideUIPanel`, which an addon may not call in a fight). It is the one tooltip the mouse can be
  on: it shows the comparisons while hovered with Shift, and it is dragged. So it takes the mouse where
  its panel is seen (`Reach` in `Host.lua`: its hit rect set to the panel's edges, its size and place left
  as they are), and its X, out of sight, takes no click of its own; `Host.Free` gives both back. These hooks run in
  `ns.Safe`, like the mouse switch: they work on the game's tooltip whether or not the panels do.
- **Hints:** `GameTooltip`, `ItemRefTooltip` and `ShoppingTooltip1/2` are hooked at login. A tooltip that is
  shown after it was cleared and the game told us of no data was written in by hand: it is drawn at the end
  of the frame like any other, with `Read.Generic` and its name as written.
- **When** (`Tooltips.lua`): `TooltipDataProcessor.AddTooltipPostCall(AllTypes)` queues the tooltip, and it
  is drawn at the end of that frame, because what fills a tooltip often goes on writing into it (a
  comparison's last lines come after the game told us); `OnTooltipCleared`
  marks the panel stale; `OnHide` gives the tooltip back; `OnShow`, `Show` and `SetShown` (the game's way
  to show a comparison) hide it again and fit it. Data the game adds to a filled tooltip is not read by
  itself: a tooltip is always read by the data it was first filled from (`GetPrimaryTooltipData`). Only a
  tooltip the player sees is drawn: visible, owned (`GetOwner`) and placed (an anchor other than
  `ANCHOR_NONE`, or points). Other addons read things with tooltips nobody sees; those get no panel, and a
  panel whose tooltip is no longer seen goes at once (its `OnUpdate` with it).
- **The mouse switch** is the game's own anchor: a hook on `GameTooltip_SetDefaultAnchor` sets the owner
  again with `ANCHOR_CURSOR_RIGHT`, and the game moves the tooltip. No `OnUpdate` of ours. It runs in
  `ns.Safe`: an error is noted and told, and the switch works whether or not the panels do.
- **Nothing is written into a tooltip.** What belongs to one is kept on its panel. Hooks only
  (`HookScript`, `hooksecurefunc`).
- **Falling back:** every step runs in Core's `ns.Guarded` (an `xpcall` that makes no table and no
  closure). An error outside the kind readers calls Core's `ns.StandDown`: it gives every tooltip back
  (`ns.GiveBack`: nothing waits to be drawn any more, then each tooltip's alpha, each step in `ns.Safe`), says so once
  (`ns.GIVEN_BACK`) and ends the module's work for the session. A kind reader's error costs its kind only
  (see *Kinds*).
- **Sections** (`Read.Section`, `Read.Caption`): a reader opens each section of its own rows under its name;
  `Read.Rest` puts each of the game's lines into the section its kind names (`ctx.name`: an item's by the
  line's kind or colour, a set by the game's `ITEM_SET_NAME`; others by `Read.Named`: a description or the
  details). A line of another name than the one before it starts a new section; one of the same name stays
  in it, the game's empty line before it a gap (`ctx.gap`, a row's `space`). `Read.Generic` has no sections
  (`ctx.flat`). There is no divider without a name: the model's rows have no `rule` any more.
- **Other addons' lines** stay the game's lines of the tooltip: a line no data of the game names is another
  addon's (`Read.Added`). Where the data says where each of its lines stands (`lineIndex`), wherever it stands
  after the game's first line: an addon may write a line right after one of the game's
  (`TooltipDataProcessor.AddLinePostCall`), not only at the end; where the game's lines are only found by
  their text, after the last of them. `Read.Rest` shows the game's lines only; while Alt is held, after
  everything of the panel's own (its sections, Alt's details) `Others` in `Read.lua` puts all other addons'
  lines into one section of their own, *Addons* (`TEXT.ADDONS`), small and quiet, an empty line among them a
  gap; without Alt they are not shown. Every kind gets it the same way: no reader handles other addons' lines.
- **Core's data** (`Doc/guides/data.md`): the module keeps no data of its own; the auction
  prices are Core's too (`Data.Series("Prices")`, `OnChange` redraws). `Quests.lua` reads the sets *Quests* and
  *Drops* (`Prepare` at the login, `OnStamp` redraws the shown panels), `Gathering.lua` the sets *Objects* and
  *Drops* (the same way), `Kinds/Gold.lua` the set *Disenchants* (the same way), `Kinds/Inventory.lua` reads
  `Data.Count`, `Data.Character` and `Data.Characters` (`Data.OnCharacters` redraws). Nil from Core means not
  known: the part is left out.
- **Not there yet:**
  - A recipe's reagents with icons and counts (they stay the game's one line), drop tables of ore, herbs
    and skins, spell coefficients: each needs Core's data first. Disenchanting epic items, and uncommon and
    rare ones of item level 61 and up: Core's data leaves them out until their materials are certain.
  - Gathering for skinning (by the creature's level) and fishing (by the water), and for nodes in other
    languages than English (Core's data has the names in English).
  - Things in the world (a chest, a *Wanted* poster): the quests they start or end, the quest items in them.
    The game gives only the thing's name; the quest facts would have to know it by its name in your zone.
  - Markers in front of an item's stats, colours for kinds of stats.
  - Icons for things in the world (the game has none for them), flight path tooltips.
  - A spell's school and its numbers in other languages than English (its facts strip works in every
    language, by the game's own sentences).
  - Small pictures the game puts into a tooltip's lines (`AddTexture`).
- **Tests:** `lua5.1 dev/tests/tooltips.lua`, on a few made-up quests, drops, nodes and a row of
  disenchanting compiled
  into set files on the real schemas (`dev/tests/data/tooltips/`, `dev/tests/data/sets.py`): the quest part,
  the Inventory section (whole names, two characters with one first name,
  the account's bank, the total, bags and the bank read in steps, the bank only while open; only with Alt),
  the line that Alt shows more (tiny, between two rules, gone with Alt, none on a button's hint), a thing's own
  lines in one section Info, the durability bar with its words inside and round corners, a section's name in
  the middle with a rule at each side, both in the groove's shade, its words with their light edge, a spell's table (two rows
  of four, --- for what is not known, Melee, rage, Duration in place of Crit for one that lasts, one row for a
  utility spell), what a spell asks of you in its header (a stance in red while you lack it, a weapon,
  reagents, tools), a physical spell in red, other addons' lines only with Alt, in their own section after a buff's bar and a quest's objectives and from right after
  one of the game's lines, every section under its name (a set, a gap inside a section, a hint without
  sections), the 3D models of a mount and a pet (the icon until loaded, a mount's spell, switched off), gear
  with its icon and your character beside the panel with Alt (as high as the panel, at its left or its right,
  unseen until loaded, turning, dressed anew, not asked again each frame, a failed try-on, a ring without,
  gone without Alt, no ground of its own), how it binds and its look in Gold, Disenchant (no prices seen, the
  value, each material with Alt, none for another class or level), Sell at (one copper under, never under a
  vendor's price after the cut), Gathering under Professions on a herb, a vein and what veins give (each
  colour of the chance from the node's own yellow and grey, green halfway, the game's own colour on a node,
  not learned, a bonus, your skill changing, Alt for every node, a chest without); how the lines of each kind are sorted, the
  strips (only the facts stated, found by the game's sentences, in its order; numbers per cell), the
  description by its kind or by a gold sentence, digits coloured, the palette and the background from the
  game's colours, widths in steps and the right side giving way, a section's name at the left with its
  rule, a unit's rows and their live parts, when a panel is drawn and when not, the tooltip under it,
  the chat link's tooltip (in the middle, closed by a click, its area for the mouse),
  the settings, hidden values and sizes, the quest list kept until the quest log changes, old prices
  forgotten, the fall-back of one kind and of the whole module, an item's quests and requirements, the
  quest-starting drops, the gold rows (a vendor's price, a bound thing, prices noted at the auction
  house), the advice to sell there, Alt's details, the live 3D portrait (given the unit once, the flat
  picture where it cannot be drawn, switched off, unseen with its panel). They cannot judge the look.

## Files
| File | What it is |
|---|---|
| `SaneUI_Tooltips.toc` | The addon `SaneUI_Tooltips` |
| `Art/banner.blp` | The module's banner, shown at the top of its options page (by Core's options). Original art of Sane UI (see the project's `LICENSE`), made by `dev/tools/art` from `assets/SaneTooltip-banner.png` |
| `Tooltips.lua` | The module's table, its settings, the hooks, the fall-back, the chat link's tooltip |
| `Texts.lua` | The module's own words; the sentences of the game it must know, as patterns |
| `Model.lua` | What a panel shows, as data: head and rows (a strip's cells in its array part), in two copies; the palette (`ns.COLOR`, each colour one of the game's moved toward another), `ns.Hex`, `ns.Like` |
| `Read.lua` | A tooltip's lines, the tools to sort them into a model and its named sections (`Read.Section`; also `Read.Prose`, `Read.NpcId`), other addons' lines in *Addons*, the details with Alt held; runs each kind's reader by itself |
| `Figures.lua` | Which 3D model a thing has: a mount's or a pet's for its picture's place (the game's collections); gear, for your character beside the panel |
| `Gathering.lua` | How likely gathering a herb or an ore raises your skill, in the section Professions, on the node and on what it gives, from Core's data (the sets Objects and Drops) and your skill |
| `Kinds/Item.lua` | Items and recipes; their sections Quest and Professions |
| `Kinds/Gold.lua` | An item's Gold section: how it binds, vendor, auction house, disenchanting (Core's set Disenchants), the price to post, the advice, when to buy and sell |
| `Kinds/Inventory.lua` | An item's Inventory section, with Alt: which of your characters have it, where and how many (Core's characters' data) |
| `Kinds/Spell.lua` | Spells and pet abilities: the strip, the school |
| `Kinds/Unit.lua` | Players and creatures |
| `Kinds/Aura.lua` | Buffs and debuffs |
| `Kinds/Quest.lua` | Quests |
| `Kinds/Object.lua` | Things in the world: their name and lines; a herb's or an ore's Gathering |
| `Inspect.lua` | Another player's item level and talents: Core's (`Core.Inspect`), its arrivals redraw the panel |
| `Quests.lua` | The quest lists of a creature, an NPC or an item, from Core's quest data (the sets Quests and Drops) and your quest log, kept until the log or the data changes; whether you may take a quest; a quest's name and level as a row |
| `Numbers.lua` | Numbers that follow from what the game says: a spell's damage per second, per mana and crit; a swing; experience per kill |
| `Live.lua` | A unit's health, power, target and buffs, and a buff's time, while the panel is shown |
| `Pools.lua` | The parts a panel is drawn with (texts, lines, small icons, bars, a graph's strokes), used again; a text's size |
| `Panel.lua` | The panel: its parts, the layout, the 3D model in the picture's place, your character beside it (the stage) |
| `PriceGraph.lua` | How an item's price went, at the end of its Gold section while Alt is held: the ranges as buttons, the two lines, Ctrl for the next range |
| `Host.lua` | Where each panel stands (by its tooltip's corner, beside another panel, comparisons at slots of their own); the game's tooltip out of sight meanwhile, its mouse area the panel's, all set back after |
| `Art/soft.tga` | The background's shape; made by `dev/tools/tooltip-art`, like the masks and `Art/plaque.tga` (the level's plaque) |

## History
- 2026-10-30 — Forever's real fees (Core's *Fees*): 15% at a neutral house, the deposit by the duration you chose, prices of what does
  not stack in whole silver. Money is written 1g1s1c, with the game's coin icons (Saneroki).
- 2026-10-30 — The Gold section tells when to buy and sell for a profit, as the scans build up: the most worth paying, when an
  item fetches most and what one brings then, how many cost less, when it is cheapest, with the house's cut and the post of at
  least 1s counted (Saneroki).
- 2026-10-30 — With Alt, the Gold section ends in a graph of how the item's price went: the lowest price and the market's
  over 24 hours, a week, two weeks, a month or all there is, from whichever of the account's auction file and the
  database is most current. Ctrl goes to the next range; on a chat link's tooltip the ranges are clicked (Saneroki).
- 2026-10-25 — Retail: a player's class line has the specialization without talent points (*Guardian Druid*); a
  creature has no experience row there (Retail's rule differs); quests, gathering and disenchanting from the
  database stand down while Retail has no data.
- 2026-10-23 — A section's rules, a table's captions and the lines between its cells (a spell's numbers) in the grey
  of the section names, the values in their colours (Saneroki).
- 2026-10-23 — A red ! before the name of each thing not yet confirmed in a tooltip that ends with *! Unconfirmed
  Data !* (Saneroki).
- 2026-10-23 — Section names grey; *! Unconfirmed Data !* and *Hold ALT for more* small grey notes in the middle
  at the bottom, without rules, as written (Saneroki).
- 2026-10-23 — A tooltip too tall for the screen goes on in columns beside the first. *! Unconfirmed Data !* as a
  divider of its own, the marks red. A boss on a dungeon's map drawn as a creature: its model, the boss's dragon,
  *??*, its abilities and loot in sections (Saneroki).
- 2026-10-19 — Section names in the middle with a rule at each side, both in a dark see-through shade like
  grooves; so are a spell's table captions and lines, its values white. A spell's numbers in a table of four
  columns and two rows (every cell filled, *---* where unknown); what it asks of you (a stance, a form, a
  weapon, reagents) in its header under its school; *Melee* for melee range; physical spells red. The bottom
  line *Hold ALT for more* between two rules.
- 2026-10-19 — A tiny line at the bottom, *Hold ALT for more info*. A thing's own lines (stats, effects,
  description, durability) are one section, *Info*. *Inventory* and *Addons* only with Alt. The node that gives
  a herb or an ore stands under *Professions* (no section *Gathering* any more), each node with its own skills
  for yellow and grey. Your character beside gear is see-through. The durability bar has its words inside and
  round corners. A section's name in its rule's quiet grey, without a shadow. *Gold*: what disenchanting
  brings, and with Alt each material and *Sell at*, the price to post.
- 2026-10-18 — A player with an alias (Core's `Core.People`, *Set Alias* in the game's menu of a player): the
  alias in the name's place, the character's name small under the guild, then the note if there is one.
- 2026-10-18 — A piece of gear keeps its icon; with Alt held, your own character wearing it stands beside the
  panel, as high as the panel, turning slowly. How an item binds and whether you have its look are the first
  row of *Gold* (were over the name). Other addons' lines are shown only while Alt is held. New section
  *Gathering*: on a herb or an ore and on what it gives, how likely gathering raises your skill, in the game's
  colours, from Core's data.
- 2026-10-17 — Every section has its name on its divider (*Stats*, *Effects*, *Set*, *Description*,
  *Durability*, *Status*, *Duration*, *Details*, *IDs*; *Gold* also for a vendor's price alone); there is no
  divider without a name, an empty line inside a section is a small gap, a hint has no sections. Other
  addons' lines all in one section, *Addons* (was *Other addons*), also those an addon writes right after one
  of the game's lines. The setting *3D model in tooltips* (was *Live 3D portraits*): mounts, pets and gear on
  your own character get their 3D model in the icon's place too, the icon until it is loaded.
- 2026-10-17 — Other addons' lines stand in a section of their own, *Other addons*, at the end of every
  panel, never among the panel's own lines (they stood before a buff's bar and a quest's objectives). New
  section *Inventory* on items: which of your characters have it, each by first name and surname, where and
  how many, from Core's characters' data. The quest facts are Core's (the packs *Data: Quests* and *Data:
  World*); the module's own quest file is gone.
- 2026-10-17 — On Core's shared tools: the panels' pools (`Core.Pool`), the hairline (`Core.Pixels`), the
  switches (`Core.Settings`). Where the client has no `C_StringUtil.StripHyperlinks`, another addon's ID
  line is read without its colours, links, icons and atlases (`Core.Fuzzy.Plain`), so it is left out
  there too.
- 2026-10-17 — The look built on the game's colours: every colour is one of the game's font
  colours moved toward another, the schools' are the combat log's, the background is the game's tooltip
  ground tinted by the panel's colour. A spell's strip holds only what its tooltip states, found by the
  game's own sentences (every language), in the game's order; its numbers in a second strip. Sections
  have their name at the left with a rule after it. Widths in steps of 8; a row's right side gives way to
  its left. A player's side is a word on the race line (no emblem); a rare elite says *Rare · Elite*; the
  target's name follows the word *Target*. An aura's panel has the colour of what takes it away.
  `Native.lua` is `Host.lua`.
- 2026-10-16 — A unit's portrait is its live 3D model (the game's, moving, its face in view), the flat
  picture where the game cannot draw it; the setting *Live 3D portraits* switches it off.
- 2026-10-16 — Lines other addons add to a tooltip are shown as they are, small, at the end of a panel.
  Gone: the sections Loot, Guild and Inventory, *Crafted by* and
  *Disenchants into*; in the Gold section the disenchant row, the odds of a sale, the fair and quick prices
  and the price chart. The Gold section has *Vendor* and *AH profit* from the prices you saw yourself, and
  one line of advice.
- 2026-10-16 — Comparisons at absolute places on the screen, worked out from steady things and moved only
  once the item's panel has stood still in a new place (they still flickered: the second hung on the
  first, which the game hides and refills several times a second). *Press ALT for +2 more* where Alt shows
  more.
- 2026-10-16 — Comparisons placed by the module: beside the item's panel, a gap apart, on one side for
  as long as you point at the same thing (they jumped between two places, following the game). *Questlog*
  over the quests' standing; the chart's words without plates.
- 2026-10-16 — An item's quests in a section of their own under *Quest*: the quest it starts, and every quest
  for you that needs it, each with where you stand with it (*In log* with your count, *Available*, *Not yet*,
  *Done*). A creature's quests under the caption *Quest* too. The chart's words over its lines, each on a
  dark plate.
- 2026-10-16 — The Gold section is for one item always, and every item has its vendor price (*Can't be
  sold* when no vendor buys it); the advice has no coin; the chart no dark ground. Captions *Loot* (was
  *Gear*) and *Inventory* (over *You have*). The level an item needs and its class or profession stand one
  under the other at the right.
- 2026-10-16 — The Gold section with vendor, disenchant and auction house profit, a price chart, and one
  line of advice (*Sell on the AH for*, *Disenchant it*, *Sell to a vendor*, *Buy if under*); Alt shows
  more. An item's quests (wanted by your log, the quest it starts), creatures that drop quest-starting
  items, quest levels on every quest name, an item's class and profession requirements in its header.
- 2026-10-16 — A creature's loot objectives say how often it drops the item (*33%*), from the quest
  database; a drop the database knows has a sack even when its name names the creature.
- 2026-10-15 — After a review. Fixed: with the icons switched off an item's and a unit's level were gone (the
  plaque needs the icon): they stand right of the name now. A line of the game's data without text took the
  type of the line before it (the game gives it that line's index). Inspecting no longer lets go of an
  inspection another addon asked for since; talents without an item level are asked for again. A spell's
  school is not kept before its description has come. Of several auction rows of one item the lowest price
  counts. A failing live value (health, buffs) is noted once and stands nothing else down. A boolean mouse
  switch of version 2 is put right in every profile too. Cheaper: another addon's unseen tooltip is no longer
  hidden part by part on every fill.
- 2026-10-15 — A chat link's tooltip opens in the middle of the screen and closes with a click; no X.
- 2026-10-14 — A player is named by first name and surname (`Core.FullName`): the target in a unit's panel, who
  cast a buff; a title is found in the name with its surname too.
- 2026-10-14 — After a review. Fixed: a debuff's panel had no colour of its kind (`DebuffTypeColor` is not
  in this client); a unit's panel showed another unit's numbers, or none, while the game faded its tooltip;
  sizes the game hides could stand the whole module down; two comparisons hung on each other could too;
  other addons' hidden tooltips got panels. One kind that fails now leaves only that kind to the game.
  Faster: a creature's quests are worked out once until the quest log changes; panels are made when first
  needed; fewer strings per read. Old auction prices are forgotten after 30 days. `Pools.lua` split off
  `Panel.lua`; one palette for the rows (the green of what is done is the unit section's).
- 2026-10-14 — The *Auction* price is the module's own, noted as you browse the auction house.
- 2026-10-14 — The module's own quest database: what a creature drops for your quests, what an NPC offers
  and takes back. Dead creatures: *Skinnable* on the class line, no
  *Corpse* line, no name taken for a class.
- 2026-10-14 — The quest database knows 969 more quests, mostly Forever's own. Dead, ghost and offline
  units: a grey panel fading to black.
- 2026-10-14 — A little room between the name and the guild or an NPC's title; no class for friendly NPCs.
- 2026-10-14 — Fixed: a dead creature's tooltip (the game fills it as a corpse's) had no portrait and no dragon.
- 2026-10-14 — *Tooltips at the mouse cursor* is a dropdown: never, while Shift, Ctrl or Alt is held, or always.
  *Show tooltips* and it are *Always* and *Default* at first.
- 2026-10-14 — *Show tooltips*: only while a key is held (Shift at first), or always.
- 2026-10-14 — The quest database knows what is one side's only. A tooltip without a colour of its own (a
  mailbox) is grey, fading to black. More of the game's tooltips take hints.
- 2026-10-14 — NPCs: their title (*Bowyer*) under the name, their faction in the header, a creature's class
  always. A section for experience and quests: a sword before what to kill, a sack before what to loot,
  the quests an NPC offers and takes back.
- 2026-10-14 — Units: guild rank, spec and talent points (yours, and another player's after an inspection),
  title, a creature's title, family and *Tapped*; the health numbers in the bar's middle. Spells: the
  numbers in columns (DPS over Damage, Cast over Cooldown, Mana over Per Mana, Range over Crit); *Healing*,
  *CC*, *Physical* or *Utility* under the name when no school is named.
- 2026-10-14 — Units: the guild as large as the name, close under it; race and class on two lines, the class
  line with PvP, AFK, DND, offline, dead and a creature's rank. A weapon's DPS, hit and speed in one line.
  The plaque hardly larger than its words; the rows beside it make room for it.
- 2026-10-14 — Items: binding short over the name (*BoE*), *Equipped* there on a comparison, *Uncollected*;
  kind small and grey; *DPS* before the number; the sell price once, as *Vendor*, and *Auction*; *Used in*
  for trade goods; a comparison's changes without their sentence. Spells:
  a second strip of their numbers. Creatures: XP and kills to level, class.
  The plaque a soft-edged gold rectangle.
- 2026-10-14 — No dragon for a creature without a rank again; the dragons moved 4 in, against the portrait.
- 2026-10-14 — A player's side emblem in the top left corner (was: at the right, in the middle).
- 2026-10-14 — The images' soft edge narrower; a unit's bars and its buff icons fade out at their edge too.
- 2026-10-14 — Icons and portraits fade out at their edge like the panel; no frame behind an icon; the
  silver dragon for every creature without a rank.
- 2026-10-14 — The dragons are the game's own from its target frame, by rank (boss, elite, rare), fitted
  round the portrait; players have the gold one.
- 2026-10-14 — The plaque is the game's gold plaque from the dragon's set, and a player's item level stands
  on it (*iLvl 50 - 60*), the plaque reaching left; the power bar lies over the health bar's lower part.
- 2026-10-14 — Fixed: square icons were cut to a strip and the bars' corners stayed square (masks do not
  keep fixed corners); masks of their own shape now. Other addons' ID lines are left out (Alt shows the
  numbers); a buff's time line is found more carefully, and its bar is wide enough for its words.
- 2026-10-14 — A player's item level (inspected, paced, kept); a unit's level coloured by difficulty again,
  outlined on a quieter plaque; PvP at the end of the race and class line.
- 2026-10-14 — Square icons with round corners; the level on a gold plaque; the dragon smaller, so it
  covers the icon's edge at the top and the bottom.
- 2026-10-14 — The icon out over the corner, the dragon covering its edge; a buff's time inside its bar,
  flat with round corners; with Alt held, the technical details (IDs of the thing and its icon).
- 2026-10-14 — The icon 64 large in the top right corner, the level on its edge, an elite's dragon curled
  round it; a unit's bars one block with round corners; dividers more visible; the background almost
  solid (97, was 90; saved settings at the old default are moved). The game's tooltip is hidden part by
  part, so it no longer shows through while the game fades it.
- 2026-10-14 — After a look in the game: the elite's dragon round the top right corner, larger and looking left;
  no frame behind a portrait; flat, half see-through unit bars, taller, the health's numbers inside; a
  unit's details small, *PvP* short. Hints get panels too. The game's tooltip is no longer made larger: the
  comparisons no longer jump between two places, their panels stand beside the first one.
- 2026-10-14 — No border any more: the background has round corners and an edge that fades out softly
  (`Art/soft.tga`). Fixed: an error while drawing after a unit's tooltip was shown in a fight
  (`attempt to perform arithmetic on a secret number value`).
- 2026-10-14 — Fixed: after an update with new files and only a `/reload`, the module failed at the first tooltip. It now asks for a restart of the game.
- 2026-10-14 — Layouts per kind of tooltip: items (large damage, binding, durability bar, price), recipes,
  spells (school colour), players and creatures (portrait, level, health and power bars, target, buffs,
  side emblem, elite dragon, quest marks), buffs (time bar, caster),
  quests (state, objectives). One gradient per panel and no band behind the name; quiet dividers; roomier.
  New setting *Opacity*.
- 2026-10-14 — After the first try in the game: round corners, more compact, captions over values, no divider, the setting *Text size*, *Equipped* on a comparison, the F6 line left out.
- 2026-10-14 — Fixed: comparison panels changing their size on every refresh; they also stand on the right side now.
- 2026-10-14 — Fixed: flicker between the panel and the game's tooltip while a comparison is open.
- 2026-10-14 — The tooltips are drawn anew on panels (was: art behind the game's own lines). New: the
  strip, the health bar, the switch for the mouse. Gone: the switch for the border.
- 2026-10-14 — First version.
