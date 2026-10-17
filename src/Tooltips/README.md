# Sane UI: Tooltips

**Status:** written and tested offline · **Since:** 2026-10-14 · **Addon:** `SaneUI_Tooltips`

## TL;DR
Draws the game's tooltips anew on dark panels with round corners and a soft edge, each in the colour of what it is about:
an item's quality, a player's class, a spell's school. Items, spells, players and creatures, buffs and
quests each have a layout of their own; everything else gets its name and its lines. Text size and
opacity can be set, and a switch anchors tooltips to the mouse cursor. An item's panel also shows the
quests that need it, the professions that use it and what it brings from a vendor and at the auction
house, with one clear line on what to do with it for gold; Alt shows more.

## How to use
- **Switch it on or off:** tick or untick *Tooltips* under *Sane UI* in the game's addon list. Switched
  off, the tooltips are the game's own again.
- **Nothing to set up.** Point at an item, a spell, a player.
- **Seven settings**, on the page *Tooltips* of the options (Esc > Options > AddOns > Sane UI). A change counts from the next tooltip on.

  | Setting | At first | What it does |
  |---|---|---|
  | *Show tooltips* | Always | A dropdown: *Always* (at once, as the game does), or only while Shift, Ctrl, Alt, or Shift and Alt are held. Until the key is held a tooltip is there but unseen; pressing it shows the tooltip at once, letting go hides it again. (Shift is also the game's key for comparing an item with what you wear; with Alt, the technical details show too.) |
  | *Tooltips at the mouse cursor* | Default | A dropdown: *Default* (where the game puts them), while Shift, Ctrl or Alt is held, or *Always*. The tooltips that stand in the corner of the screen (creatures, players, things in the world, your action bars) follow the mouse instead. Pressing or letting go of the key moves a shown tooltip at once, to the mouse and back |
  | *Colour players by their class* | on | Off: a player's tooltip takes the colour the game gives the name |
  | *Show icons and portraits* | on | Off: no icon of an item, spell or buff, and no portrait for units: the level stands beside the name |
  | *Live 3D portraits* | on | A unit's portrait is the game's 3D model of it, moving, its face in view. Off, or where the game cannot draw the model (the unit out of sight): the flat picture |
  | *Text size* | 14 | From 10 to 20: how large a tooltip's name and lines are written; the smaller texts follow |
  | *Background opacity* | 97 % | From 30 to 100 percent: how solid the background is. Texts and pictures stay as they are |

- **What each panel shows:**

  | Tooltip | In its panel |
  |---|---|
  | **Item** | Over the name, short: how it binds as players write it (*BoP*, *BoE*, *BoU*, *BoA*, *WuE*, *Soulbound*, *Quest*; red until it is bound to you), or *Equipped* on what you wear in a comparison; beside it whether you have its look (*Uncollected*, *Look known*). Name in the colour of its quality; under it, small and grey: kind and slot (what it is, for a thing that is not worn: *Trade Goods · Cloth*) and at the right the level it needs (red while yours is lower) and under it, also at the right, what else it asks of you: a class (*Classes: Mage*), a profession's skill (*Requires Tailoring (75)*), a reputation (red while you lack it); icon with the item's level under it. Then a weapon's damage per second large, its hit and speed smaller in the same line (*3.2 DPS · 1 - 3 dmg · 2.00 spd*), or an armour's armour; its lines in groups (what it is, what it does in green, what is told about it); its durability as a small bar. **Quest** (a section under its caption): *Starts* and the quest it starts, then *Needed for* and the quests that need it (each heading with *Questlog* at the right, over the words that say where you stand: *Not yet* is not yet in your quest log); each with its level small after its name and, at a glance, where you stand with it: *In log* with the ? and your count (*In log 1/4*, gold, green when complete), *Available* with the ! (you can take it now), *Not yet* dim (your level, a quest to do first), *Done* with a tick, grey; first those in your log, then to take, for later, done; without Alt three of those not in your log and *Press ALT for +2 more*. A quest for another class, race or side, or closed to you, is left out. Then, for a trade good, **Professions** (a section under its caption): *Used in* and the professions that use it, with their icons (by the item's kind). Then other addons' lines, small; last **Gold** (see *Gold* below). Each section is there only when something is known for it. Whatever you cannot use is red, as the game colours it. What you wear beside an item (a comparison) has no sections, only other addons' lines and its vendor price for one |
  | **Recipe** | Like an item; what it makes stands under the caption *Creates*, with that thing's icon |
  | **Spell, pet ability** | Name; what it is (its school in its colour; without one *Healing* in green, *CC* in blue for crowd control, *Physical*, *Utility*) and rank, or *Passive*; icon. A strip of what its tooltip states, each caption over its value, in the order the game writes them: its cost (*Mana*, *Rage*, *Energy*; a mana cost also as a share of all yours), *Range*, *Cast*, *Cooldown*; a fact the tooltip does not state has no cell. A spell that hurts or heals has a second strip of what follows from it (see *Spell numbers* below): *DPS* or *HPS*, *Damage* or *Healing* on average, what it does *Per Mana* (the melee swing and the shots: their *Speed*), *Crit* (your chance); again only what is known. The description in the middle, its digits in the panel's colour. The panel has the colour the game's combat log gives the spell's school (fire, frost, arcane, nature, shadow, holy; physical for one that only hurts), green if it only heals, none otherwise |
  | **Player** | Name in the colour of the class; the gold dragon round the portrait; close under the name and as large: the guild, with the player's rank in it small after it; then small: the race and the side (*Human · Alliance*), and under it the class line: spec and class with the talent points (*Feral Combat Druid 0/31/20*; yours at once, another player's once inspected), the title (a PvP rank, *Sergeant*), and what is true now (*PvP* in red, *AFK*, *DND* in orange, *Offline*, *Dead*, *Ghost*; then the panel has no colour of its own); a large portrait in the top right corner with the level on its lower edge (the unit's live 3D model, see *Live 3D portraits*). The health bar with the current health and its share in percent written in its middle (over the power bar), and over its lower part the bar of mana, rage or energy (an empty one shows nothing): flat colours, half see-through, round corners; whom the player targets right above the bars (*Target* and the name right after it; *You*, in red, when it is you). The plaque under the portrait says the item level before the level, *iLvl 50 - 60* (yours at once; another player's after the game has inspected them, see below). Buffs and debuffs as small icons. Then other addons' lines |
  | **Creature, NPC** | The same; in place of the guild its title (*Bowyer*, *<Flight Master>*: the game's line before its level line) or, for a pet, its owner; in place of the race what it is, its family and its faction (*Beast · Wolf*, *Humanoid · Stormwind*: the faction is the game's line after the level line); on the class line its class (*Warrior*, *Mage*; not for a friendly NPC), its rank in the game's words (*Elite*, *Boss* in gold, *Rare* in silver; a rare elite both), *Tapped* (somebody else's kill), *PvP*, *Dead*; a dead one's panel has no colour of its own. A section of its own for experience and quests: what killing it gives you and how many such kills to your next level; then each quest's name in gold with a sword before what you must still kill and a sack before what you must still loot with how often it drops after its name (*33%*), the count at the right (*5/7*; what is done is left out, and a quest with nothing left to do for it, too; the game's own quest lines, and what it drops for your quests from the module's quest facts: see *Quests* below); the quests it takes back and offers you, each name in gold with a line under it: *Turn in* (ready, green) or *In progress* with the game's ?, *Offers* with the game's !, and the quest's level; a dead creature says *Dead* and what it yields (*Skinnable*) on the class line, the game's *Corpse* line is left out; what killing it gives you (*145 XP*) and how many such kills to your next level (*Next level in 12*), see *Experience* below; the game's own dragon from its target frame curls round the portrait: gold for an elite, gold with a great wing for a raid or dungeon boss, silver and winged for a rare or rare elite; a creature without a rank has none. Your quests' lines for it in gold: a sword beside what you must kill it for, a bag beside what you must loot |
  | **Buff, debuff** | Name; *Buff* or *Debuff* and what takes it away (*Magic*); icon; the description, in the middle; a bar that runs out with its time, with how long it still runs and who cast it written inside (flat, round corners). The panel has the game's colour of what takes it away (the colour of a debuff's border: magic, curse, poison, disease); a debuff nothing takes away the game's colour for that, a buff nothing takes away none |
  | **Quest** | Name; level (in the colour of its difficulty) and where it stands for you (*In progress*, *Ready to turn in*, *Completed*); its text; under the caption *Objectives* a box for each thing to do, ticked and green when it is done |
  | **Anything else** the game fills from data (things in the world such as a mailbox or a herb, macros, the minimap, currencies, mounts, totems, equipment sets, ...) | Name and lines; an empty line becomes a divider; a panel without a colour of its own, whatever colour the name has |

  Lines another addon adds to a tooltip are shown as they are, small, at the bottom (on an item, over the
  Gold section).
- **Hold Alt** for the technical details: a small section at the bottom of every panel with the number of
  the thing at the left (*Spell ID*, *Item ID*, *NPC ID*, *Quest ID*, ...; a player's GUID) and the number
  of its icon at the right (*Icon ID*). Pressing or letting go of Alt redraws the panels that are shown.
  On an item Alt shows more too: every quest that needs it (without Alt, three of those not in your log),
  and under the Gold section where its numbers come from (the lowest price you saw; the cut and the
  deposit).
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
  has two rows, each only when it is known, and **always for one** of the item, also when you point at a
  stack, so the two ways compare one to one:

  | Row | What it is |
  |---|---|
  | *Vendor* | What a vendor pays for one; on every item (from the game's item data, `GetItemInfo`, also where the tooltip has no price line), *Can't be sold* where no vendor buys it |
  | *AH profit* | What a sale of one at the auction house brings: the lowest price you last saw for it there, less the house's cut (5%). Not for a thing that is bound |

  Last, **the advice** in one line: the way that brings the most (the auction house must bring 5% more
  than a vendor, for the trouble). *Sell on the AH for 3s 09c* (green; the lowest price you saw); *Sell to
  a vendor* (at the right how much more than the auction house, *+12c over the AH*, where a vendor pays
  more). On an item the auction house lists to you (you buy it: the game filled the tooltip with
  `GetItemKey`) it is *Buy if under 2s 79c* instead: the most it is worth paying, what it brings again at
  the auction house (less the cut) or from a vendor; green while the lowest price now is under it, red
  over it, *now* and that price at the right. A vendor's price alone (no auction price known) stands under
  a divider with no caption and no advice. With Alt, small under the advice: *Lowest* and the price the
  numbers come from, then the cut and the deposit (taken as 15% of the vendor price for every 12 hours of
  a 48-hour auction, an estimate), *back when it sells*.
  **The prices** are the module's own: whenever the game lists auctions to you (browsing the auction
  house), the lowest buyout of each thing is noted and kept in the saved settings (`Auction.lua`); a price
  not seen again for 30 days is forgotten at the login. Nothing is asked of the server.
- **Quests** (`Quests.lua`, `Data/Quests.lua`): what you must kill the game says in the tooltip's own quest
  lines. Which creature drops a quest item, who gives which quest and who takes it back, the game does not
  say; the module ships its own quest facts for that (`ns.QuestFacts`, described at the top of
  `Data/Quests.lua`): 4796 quests, 1805 NPCs that give or take back quests, 3738 creatures that
  drop quest items, 2395 items that quests ask for, 370 items that start a quest and 865 creatures that drop
  those; 546 KB. A quest is one string, `levels;rule;races;classes;title`: its levels in one field
  (*20-30*, *10-19-19* with the highest that may take it), what it asks first as one small expression
  (`+` must be done, `/` one of these must be done, `!` closed once you have it or had it: a quest that
  excludes it, its chain's next step, the quest it leads to), the side as a letter or the game's race and
  class IDs. An NPC or an item is one string of lettered groups (*g* gives, *t* takes back, *d* drops for
  an objective, *s* drops an item that starts a quest; *n* an objective asks for it, *b* it starts the
  quest). What only one side has carries the side's letter, and only your side's counts. Each string is
  taken apart when a tooltip first asks for it.
  An item's panel shows every quest for you that wants it, and the quest it starts, each with where you
  stand with it: in your quest log (with your count), done, one you can take now (here also one far below
  your level), or one for later; quests of the same name (the same quest at other places) once. A
  creature's shows an item it drops that starts a quest you can take, with how often. Both under the
  caption *Quest*. Every quest's name in a creature's section has its level at the right, in the colour of
  how hard it is (the game's quest line says which quest it is); in an item's, small after the name (*[12]*).
  **Drop chances** are in the facts where they are known (11731 of 15653 drops; most without one are
  Forever's own quests), in whole percent: *33%* after the item's name, on the game's own objective line
  too, *<1%* below one. Your progress comes from your quest log (`C_QuestLog.GetQuestObjectives`).
  What is found for a creature is kept until your quest log or your level
  changes (`QUEST_LOG_UPDATE`, `QUEST_TURNED_IN`, `PLAYER_LEVEL_UP`, `PLAYER_LEVEL_CHANGED`): its tooltip
  is read many times a second. A broken record is noted and told once; what was found before it stays.
  Whether you may take a quest: it is meant for you (your side, also for this client's own races; your race
  by the game's race ID, your class by its class ID), you have reached its lowest level and not passed its
  highest, the quests it asks first are done and none that closes it is in your log or done. An NPC leaves
  out what the game shows grey for your level (`UnitQuestTrivialLevelRange`). A quest that repeats is
  offered by no NPC in the facts: it shows while it is in your quest log.
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
  somebody else has tapped, nor at the highest level.
- **The test realm's line** *Press F6 to submit an issue for this ...* is left out of every panel.
- **Hints** (a button's name and explanation, lines somebody wrote into a tooltip) get a panel too: their
  lines as written, in their colours.
- **What stays the game's own:** a tooltip with a bar, an item or another frame inside (the panel could not
  show it in full); a tooltip with a line the game hides in a fight (it cannot be read); a tooltip nobody
  sees (another addon's, to read things with).
- **In a fight** a unit's buffs are not shown (the game does not hand them out then), and a tooltip the
  game hides lines of stays the game's own.
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
  at login), with pools of texts, thin lines, small icons and bars (`Pools.lua`: each pool a `Core.Pool`,
  a list of the parts made and how many the draw has taken; a draw hides only what the last one took).
  A draw goes in four steps: every text made and measured (`Measure`), the icon or portrait with its
  plaque (`Picture`), the rows top to bottom (`Lay`), then the background, the dragon and the frame
  levels (`Finish`). The rows before the first divider stand beside
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
  border, no band behind the name, no boxes. A divider is a dark band two hairlines high with a faint
  light hairline under it; a hairline is one unit of the interface rounded to whole dots of the screen
  (`Core.Pixels`, by the game's `PixelUtil.GetNearestPixelSize`). A section's name stands at the left in
  small capitals, in the game's gold made darker, and a rule runs on from it to the right side.
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
- **The live 3D portrait** (`Figure` in `Panel.lua`): a model frame of the game's (`PlayerModel`) in the
  portrait's place, 64 large, given the unit (`SetUnit`) and turned to its face (`SetPortraitZoom(1)`): the
  game draws the unit's own model, moving, on a see-through ground, so no picture of it is shipped. One per
  panel, made for the first unit it shows. It is given the unit only when the unit changes (its GUID): giving
  it again would load the model anew and start its moves over, and a panel is drawn many times while it is
  shown; once hidden it forgets the unit. Where `SetUnit` does not say it can draw it (the unit out of
  sight, its identity hidden, an error) or the client has no such frame, the flat picture
  (`SetPortraitTexture`) stands there, as with the option switched off. A frame draws over the panel's own
  pictures, so the dragon, the plaque and the level stand on a frame over it (`panel.front`; the level's
  text is lifted onto it, `Pools.Lift`). Its alpha follows the panel's by itself (`Panel.Strength`): a model
  frame need not follow the frame it is in. Unlike the picture it has no round soft edge (a mask works on
  pictures only): it is cut square.
- **Fonts and the text size.** The font file is asked of the game's font objects at every draw
  (`GameTooltipText`, `GameTooltipHeaderText`), so the game's language and a UI addon's font are
  followed; the size is set by us (`SetFont`), because it is the player's setting. Name and lines have
  that size, a weapon's number 4 more, subtitles and the strip's values 2 less; another addon's lines,
  captions and a unit's details 4 less (10 at the default size, as the game's own small font).
- **Colours.** The panel's colour is the game's own for the thing: `ITEM_QUALITY_COLORS`,
  `RAID_CLASS_COLORS`, the colour of what takes an aura away (`AuraUtil.GetDebuffDisplayInfoTable`, the
  game's for the borders of debuffs), the colours the game's combat log gives the spell schools,
  `PowerBarColor`, `GetCreatureDifficultyColor`, or that of the tooltip's first line. A line keeps its
  colour, except the game's white, which is toned down a little toward its grey, and its gold (which it
  writes descriptions in), which is made lighter. Every other colour of ours (`ns.COLOR` in `Model.lua`)
  is one of the game's font colours (`HIGHLIGHT_FONT_COLOR`, `NORMAL_FONT_COLOR`, `GRAY_FONT_COLOR`,
  `RED_FONT_COLOR`, `GREEN_FONT_COLOR`, ...) moved part of the way toward another of them (`Tone`): a
  name and a value nearly white, what is said about a thing light grey, captions the game's gold made
  darker, what is done green, what you cannot do red. A line's colour is known by being close to one of
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
- **Another player's item level** (`Inspect.lua`) can only be had by inspecting them: the game asks the
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
  main panel's place, taken when it shows a new thing (owner and item) and afterwards only once it has
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
  (`ns.GiveBack`: each tooltip's alpha, each in a `pcall` of its own), says so once
  (`ns.GIVEN_BACK`) and ends the module's work for the session. A kind reader's error costs its kind only
  (see *Kinds*).
- **Other addons' lines** stay the game's lines of the tooltip: an item's panel puts the game's own lines
  first (`Read.Rest("own")`), then its sections, then the lines other addons added after the game's
  (`Read.Rest("added")`), small and as they are, then the Gold section.
- **Not there yet:**
  - Auction house prices from Sane UI's own price database, the biggest part of an item's panel: the
    Economy module (being written) keeps the auction house's prices and their history from what the game
    shows, and the Gold section is to take them from there instead of the last price you saw.
  - A recipe's reagents with icons and counts (they stay the game's one line), drop tables of ore, herbs
    and skins, what an item disenchants into, spell coefficients: each needs data of the module's own.
  - Things in the world (a chest, a *Wanted* poster): the quests they start or end, the quest items in them.
    The game gives only the thing's name; the quest facts would have to know it by its name in your zone.
  - Markers in front of an item's stats, colours for kinds of stats.
  - Icons for things in the world (the game has none for them), flight path tooltips.
  - A spell's school and its numbers in other languages than English (its facts strip works in every
    language, by the game's own sentences).
  - Small pictures the game puts into a tooltip's lines (`AddTexture`).
- **Tests:** `lua5.1 dev/tests/tooltips.lua` (363 checks): how the lines of each kind are sorted, the
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
| `Read.lua` | A tooltip's lines, the tools to sort them into a model (also `Read.Prose`, `Read.NpcId`), the details with Alt held; runs each kind's reader by itself |
| `Kinds/Item.lua` | Items and recipes; their sections Quest and Professions |
| `Kinds/Gold.lua` | An item's Gold section: vendor, auction house, the advice |
| `Kinds/Spell.lua` | Spells and pet abilities: the strip, the school |
| `Kinds/Unit.lua` | Players and creatures |
| `Kinds/Aura.lua` | Buffs and debuffs |
| `Kinds/Quest.lua` | Quests |
| `Inspect.lua` | Another player's item level, by inspecting them, paced and kept |
| `Auction.lua` | The lowest auction price of each thing, noted as you browse the auction house, kept |
| `Quests.lua` | The quest lists of a creature, an NPC or an item, from the quest facts and your quest log, kept until the log changes; whether you may take a quest; a quest's name and level as a row |
| `Data/Quests.lua` | The module's quest facts (`ns.QuestFacts`); their shape is described at its top |
| `Numbers.lua` | Numbers that follow from what the game says: a spell's damage per second, per mana and crit; a swing; experience per kill |
| `Live.lua` | A unit's health, power, target and buffs, and a buff's time, while the panel is shown |
| `Pools.lua` | The parts a panel is drawn with (texts, lines, small icons, bars), used again; a text's size |
| `Panel.lua` | The panel: its parts, the layout |
| `Host.lua` | Where each panel stands (by its tooltip's corner, beside another panel, comparisons at slots of their own); the game's tooltip out of sight meanwhile, its mouse area the panel's, all set back after |
| `Art/soft.tga` | The background's shape; made by `dev/tools/tooltip-art`, like the masks and `Art/plaque.tga` (the level's plaque) |

## To check in the game
- **A player:** guild, race and side, class, PvP in small letters; portrait (nothing behind it) and level;
  *Target* with the name right after it (*You* in red); then the health bar with its numbers inside, the
  power bar over its lower part; buff icons. Do the game's own lines for guild, class, side and level still
  show a second time?
- **A comparison** (Shift over a weapon, mouse still; a ring or trinket with two worn): the panels stand
  still beside each other, a small gap between them, no flicker, also the second. Near the right edge of
  the screen: on the left, and staying there. With *Tooltips at the mouse cursor*: moving the mouse over
  one item, the comparisons follow once the mouse rests.
- **A button's hint** (bags, menu buttons): a panel, not the game's tooltip.
- **The live 3D portrait:** a creature, a player: is the model there, moving, its face in view, the dragon
  and the level over it? Its square edge: how does it look? Out of sight (a party member far away): the flat
  picture? A dead creature, a ghost, a critter, a totem, a boss far larger than its box: how does it stand?
  With *Show tooltips* waiting for a key: is the model unseen until the key is held? The frame rate with
  it and without (the option).
- **The dragons:** an elite (gold), a boss (gold, great wing), a rare (silver), a player (gold): does each
  lie round the portrait, covering its edge? (Measured from the art, not seen in the game.)
- **A creature for a quest:** the sword and the bag at the right of the objective lines. Kill until one
  objective is full (*7/7*): is it gone, and the others still there? With all done, the quest's name too?
- **Drop chances:** a creature that drops a quest item (Wolf Meat on a wolf): *33%* in grey after the
  item's name, the count still at the right, and a sack, not a sword? Does the chance look right? A rare
  drop says *<1%*.
- **A weapon:** *BoE* in red over the name, small grey kind and slot, *3.2 DPS* large with *· 1 - 3 dmg · 2.00 spd*
  smaller on its base line, level
  under the icon, durability bar, the Gold section at the bottom. Is any line there twice (the sell
  price), or missing?
- **The Gold section** (an item you have seen at the auction house): *Vendor*, *AH profit* (the lowest price
  you saw less 5%) and the advice under the caption *Gold*. Does the advice make sense? Alt: *Lowest*, the
  cut and the deposit. At the auction house: *Buy if under*, green or red. With an addon switched on that
  writes into item tooltips: its lines small, over the Gold section; nothing else of the panel changes.
- **Requirements:** a class scroll or an engineering item: *Classes: Mage*, *Requires Engineering (50)*
  at the right, one under the other with the level it needs, red while you lack it, and not again further
  down.
- **Prices for one:** a stack of cloth: *Vendor* and *AH profit* each for one cloth. A chat
  link or a loot window's item: *Vendor* there too; a hearthstone: *Can't be sold*.
- **Quests on items:** a quest item in your bags (*In log* and your count); an item several quests want
  (Linen Cloth): each with *Available*, *Not yet* or *Done*, and is it clear which one you have? An item
  that starts a quest (*Starts*, its name, level and *Available*); a creature that drops such an item. Quest levels at the right
  of the quest names in a creature's section.
- **A comparison:** *Equipped* in place of the binding; the changes (*+2.2 DPS*) without the sentence.
- **A spell that hurts or heals:** the second strip. Do the amounts match the description (a range, a
  damage over time)? Does the crit match the character sheet?
- **A creature below and above your level:** the XP; does it match what a kill gives? Rested doubles it.
  *Next level in 12* at the right.
- **Spell figures:** a spell with damage now and over time (Immolate), a channel (Arcane Missiles), a
  spell with a cooldown: do *DPS* and *Crit* look right? Does `GetSpellBaseCooldown` exist on this client
  (without it a cooldown is not counted)?
- **Linen Cloth or Copper Ore:** *Used in* with the profession's icon; *Trade Goods · Cloth* under the name.
- **The plaque:** a small gold rectangle with a soft edge, hardly larger than its words; can the level be
  read on it? Do the race and class lines stay clear of a wide one (*iLvl 30 - 30*)?
- **A player's header:** the guild as large as the name and close under it, the guild rank small after it;
  race, then spec and class with points, title, PvP, AFK. Does the spec come after an inspection (it is read
  from the talent groups, `C_Traits` with the inspect configuration)? Yours at once?
- **A creature:** its title (*Bowyer*, *<Flight Master>*), family and faction (*Humanoid · Stormwind*), its class,
  *Tapped* when somebody else hit it. Is the faction line found (the line after the level line), and nothing else
  taken for it?
- **The quest section:** a creature for a quest, one that drops a quest item, a quest
  giver with quests to offer and to take back. Does the list of offers match the ! over the NPC (a grey
  quest far below you is left out, as the game's range for it says; a quest that repeats is not offered)?
  A Skyborne character: its own race's quests and its whole side's, not another race's.
- **A dead creature:** *Dead* and *Skinnable* on the class line, no *Corpse* line, no name in place of a class.
- **The health numbers:** in the middle of the bar, readable over the power bar.
- **Spells:** the strip of facts (cost, range, cast, cooldown: only those the tooltip states; *Channeled*,
  *Instant*, *Melee Range* as the game writes them) and, for one that hurts or heals, the strip DPS, Damage,
  Per Mana, Crit; are the cells as wide as their words, the room shared out? Are the game's sentences for
  the facts the ones this client writes (a fact read as a plain row instead means its global is worded
  otherwise)? *Healing*, *CC*, *Utility*, *Physical* under the name of spells without a school.
- **The new palette:** the school colours from the combat log (frost cyan, shadow blue-violet, physical
  yellow), captions in a darker gold, values near white, details light grey; readable on every panel
  colour, at the bright top and the dark bottom? The background's navy ground from the game's tooltips,
  taken toward the panel's colour: too dark, too blue?
- **Captions:** the name at the left with a rule after it (*QUEST ———*), in the Gold, Quest and
  Professions sections and a recipe's *Creates*.
- **Widths:** panels in steps of 8; a long right side (a price, a count) cut short only when the panel is
  at its widest; descriptions wrapping at a good measure at text sizes 10 and 20.
- **Hairlines:** dividers and the strip's separators at UI scales 0.64 to 1 and on a 4K screen: sharp, not
  too heavy?
- **A recipe:** *Creates* with the made thing's icon.
- **A spell:** school colour and word, the strip, coloured numbers.
- **A buff on you:** time line with caster, and the bar running out. A magic buff blue, one nothing takes
  away without a colour; a debuff without a kind in the game's red for it. Buffs the game shows by their
  own number (`...ByAuraInstanceID`): found, with their time?
- **A rare elite:** *Rare · Elite* on the class line, the silver dragon. Are *Elite*, *Boss*, *Rare* the
  game's words (`ELITE`, `BOSS`, `RARE`)?
- **A quest link:** level, state, objectives with boxes.
- **In a fight:** do the panels stay, or do tooltips fall back to the game's look?
- **The soft edge:** does the background fade out evenly around the panel, corners included, in the panel's colour? Is it too wide or too narrow?
- The dividers: visible but quiet, at the bright top and at the dark bottom of a panel.
- The opacity and text size sliders.
- **The mouse off a creature, a player, a mailbox, a unit frame:** is the tooltip gone at once, with
  nothing of the game's tooltip fading out after it? Back onto it: there again?
- **A link clicked in chat** (an item, a spell): in the middle of the screen, no X. A click anywhere on the
  panel closes it, also its edge where the game's tooltip is smaller, and nothing next to it does. Shift
  over an item: the comparisons beside it. Dragged, it moves and stays open. In a fight: closed by a
  click, no *Interface action blocked*? Opened again: in the middle again.
- **After the review of 2026-10-14:** A debuff's panel in the colour of its kind (magic
  blue, curse purple, poison green, disease brown). Two comparisons (Shift over a ring or trinket, both
  worn), the mouse moved from left to right over the screen: no error, the panels side by side. An addon
  that reads tooltips (an auction or loot addon) and the frame rate. A creature's quest section after a
  quest is taken, progressed or handed in, and after a level-up.

## History
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
