# SaneUI: Lore

**Status:** built: talks with NPCs as a scene (gossip, a quest giver's greeting, a quest offered, in progress and handed in), see-through over the world, the interface out of sight meanwhile, a quest's rewards read for you · **Since:** 2026-10-28 · **Addon:** `SaneUI_Lore` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Lore is the world's words (plan: [Doc/ideas/Lore.md](../../Doc/ideas/Lore.md)). Its first part is the talk with an
NPC ([Doc/ideas/Dialogue.md](../../Doc/ideas/Dialogue.md)): instead of the game's gossip and quest windows, the NPC's
own 3D face, name and words stand low in the middle of the screen on a dark plate whose round edge fades softly into the world, a
paragraph at a time. What you can answer stands beside them as dark bars; the NPC's services (the hearthstone, a
vendor's goods, a trainer, flights, the bank) and Goodbye as big pictures without words over them; a quest's objectives
and rewards on a plate under them, each reward a line of the group's loot rolls (its bar in its quality's colour). While you talk the rest of the interface fades out; the rewards' tooltips, the game's questions and its error
lines stay in sight. Each reward says, without its tooltip, what it is (Leather · Chest, Plate · Legs, a weapon's
kind, a ring by its slot), whether you can use it, what a vendor pays for it and what it changes against what you
wear (item level, stats). The words wait for you: a left click turns them, a right click accepts or says goodbye,
Space goes on. An NPC that has only its service for you (a vendor, a flight master, a trainer) opens it at once, with
no talk; Shift shows the talk. A fight ends the talk; the game's own windows are back whenever Lore steps aside or fails.

## How to use
- **Switch it on or off:** tick or untick *Lore* under *SaneUI* in the game's addon list (the game needs a
  restart when it was not in the list before). Its options: Esc > Options > AddOns > SaneUI > Lore.
- **Talk to an NPC** as always (a right click, the interact key, Speed Leveling's key). The talk appears:
  - **the face** at the left: the NPC's own model, talking while a paragraph is new; something with no face (a
    board, a book) shows the game's quest book;
  - **the name** in the game's gold beside it, **the words** under the name, one paragraph at a time, an action
    in `<...>` in the game's emote colour; at the bottom right which paragraph of how many (*2/4*);
  - **the answers** in a column right of the words, each a dark bar of its own (a little lighter and its words gold
    under the mouse), in this order: quests to hand in, quests offered, the NPC's other options (words to say),
    quests not done yet. Each has the game's picture for its kind; a quest far below your level is dimmed. The column always stays on the screen: a long one (a city guard's way
    to every place) is lifted until it ends above the screen's bottom; one taller than the screen (a large *Size*)
    shows the lines that fit, with the game's small scroll arrows over and under them where more lie that way:
    the mouse wheel over the column or a click on an arrow goes on a line. Where the column would pass the
    screen's right side, the whole talk moves left;
  - **the services** in a row over the talk, as big pictures without words: the hearthstone (*Make this inn your
    home*), a vendor's goods (the bag), a trainer (the book), a flight master (the winged boot), a battlemaster (the
    two shields), transmogrification (the helmet), the bank and the auction house (their map pictures), the spirit
    healer's resurrection (the game's Guardian Spirit, a hooded spirit). A click on
    one takes it; the mouse on one shows its words, and where the game refuses it for now its picture is greyed and
    the tooltip says why. A tabard, a guild charter, a trainer's unlearning and an option the game marks *(Quest)*
    keep their words in the column. **Goodbye** (on a quest offered *Decline*) is the last picture,
    the game's raised open hand. Each picture on a dark plate of its own. *Services as icons* off: all of them in
    the column;
  - **a quest**, under the words on a plate of its own: its title, its objectives and the group it is for when it is
    offered, what it asks for while in progress, its rewards when offered and handed in.
  - **the look:** every part on a dark plate of its own with round corners and no border, its edge fading softly
    into the world (the panels more widely than the bars), the fade inside the part, so two parts side by side never
    run into each other; the words in the game's outlined nameplate font. *Shade behind the words* says how solid the
    plates are.
- **Going on:** the words wait for you.
  - **A left click** on the words, or on the quest under them, shows the next paragraph, after the last the first
    again. It only turns the words: it never answers.
  - **A right click** there gives the answer that needs no choosing, on whichever paragraph: it accepts the quest
    offered, hands in a quest in progress that is done, hands in a quest with its reward chosen (or with one or none
    to choose), takes the one answer there is, or says *Goodbye* when nothing is left to answer.
  - **Space** shows the next paragraph, and on the last gives that same answer.
  - **Where the choice is yours,** both wait for you: several answers to pick from, a reward to choose, a quest that
    costs money. A right click on a reward to choose or on an answer does nothing, and neither does one in the first
    moment of a screen or right after an answer, so a double click on the NPC gives nothing you have not seen.
  - **By themselves:** at a *Reading speed* above 0, with *Words go on by themselves* on, a paragraph gives way to
    the next once it is read at that speed; the last one waits for you. At 0, as at first, the words never go on by
    themselves.
  - **Speed Leveling** takes and hands in the guide's quests as ever (its *Take the guide's quests*, *Hand in the
    guide's quests*): the words waiting do not hold it up.
- **The rewards** (offered and handed in), each a line as the group's loot rolls draw theirs, so choosing a reward and
  rolling on loot look the same: the bar in its quality's colour (green for an uncommon thing, a light grey for a
  common one, the game's gold for a quest's own thing), its picture round with the bar's left end, the game's green
  arrow before the name where it betters what you wear: the ones to choose from first (*Choose one*), then what you get besides,
  then experience, money, honor and a title in one line. A reward's line:
  - its icon with how many, its name in white, at the right what a vendor pays for all of it;
  - under the name **what it is**: armour by its kind and slot (*Leather · Chest*, *Plate · Feet*); a cloak, a
    ring, a neck, a trinket, a shirt by its slot alone (anybody wears them); a weapon by its kind (*Daggers*,
    *Two-Handed Axes*), with its hand where only one hand holds it (*One-Handed Swords · Main Hand*); anything else
    by its kind (*Potion*, *Bag*). **Can't use** in red where you cannot, its icon reddened, as in the game's
    window;
  - at the right **what a vendor pays** for all of them (*Sells for nothing* where it does not sell);
  - under that **what it changes** against what you wear in its slot: its item level and how far above (green) or
    below (red) the one worn, then up to four stats that go up (green) and down (red), as the game works them out
    (the tooltip has them all). For rings and trinkets against the weaker of your two. *Your slot is empty* where
    you wear nothing there.
  - The mouse on it shows its tooltip with the game's comparison, in sight over the faded interface.
  - **Choosing:** a left click on a reward to choose chooses it (its border gold); the hand-in
    answer then reads *Complete Quest* (before that *Choose a reward first*). A double click hands the quest in
    with that reward at once.
  - **A quest that costs money** to hand in says the price in its answer (*Complete Quest, paying 1g*), and is
    handed in only by a click on it, never by Space or a right click.
- **At the spirit healer:** the game asks twice before it resurrects you (what it costs, then whether you are sure),
  below level 10 once. Under its last question stands a tick, **Don't ask me again**: accepted with it ticked, the
  setting *Ask at the spirit healer* goes off, and from then on choosing the resurrection resurrects you at once,
  the costs the same. Lore's page turns the questions back on.
- **Ending:** *Goodbye*, *Decline*, Esc, walking away (the game ends the talk), or a fight. When the talk turns into
  another window (a vendor, a trainer, a flight map), that window opens and the talk goes.
- **In a fight:** the talk ends when the fight begins and the interface is back at once. A talk begun in a fight
  is the game's own window.
- **Straight to the service:** a vendor, a flight master, a trainer, a banker, the auction house, a battlemaster,
  a tabard or charter vendor that has no quest for you (none to take, hand in or go on with) and no other service
  opens its window at once, without the talk, even with something to talk about or a trainer's unlearning beside it;
  as a scene or in the game's own windows alike, with Speed Leveling or without it. Hold Shift as you talk to them
  for the talk and its choices. Two services (an innkeeper's home and goods), an option the game marks *(Quest)*, a
  quest there, and the talk that opens again after a quest handed in there stay a talk; so does an option Speed
  Leveling's guide takes there.
- **Left to the game:** gossip that has a window of its own in the game, an only option the game takes by itself,
  and an offer the game turns into a popup in its quest tracker (from an item, an area).
- **Settings** (Lore's page, section *Talks*):

  | Setting | At first |
  | --- | --- |
  | *Talks as a scene* (off: the game's own gossip and quest windows) | on |
  | *Fade out the interface while talking* | on |
  | *Shade behind the words* (how solid the plates are; 0: the words alone over the world) | 60 % |
  | *Size* | 100 % |
  | *Words go on by themselves* | on |
  | *Reading speed* (words a minute; 0: the words never go on by themselves) | 0 |
  | *Space goes on* | on |
  | *Services as icons* (an NPC's services as big pictures over the talk; off: in the column) | on |
  | *Straight to the service* (an NPC's only service at once; Shift: the talk) | on |
  | *Ask at the spirit healer* (off: the window's *Don't ask me again*, it resurrects you at once) | on |

## Technical details
- **The game's windows held, never changed** (`Native.lua`): `GossipFrame` and `QuestFrame` get a hidden frame of
  ours as their parent while they are closed (`Core.Lend`: their parent, strata and level noted and given back
  exactly). The game opens and closes them as always (`ShowUIPanel` from its own event handlers): they count as
  shown, so the quest window's check after `ShowUIPanel` holds, but they never come into sight, and their `OnShow`
  and `OnHide` do not run (each `OnHide` ends the talk: `C_GossipInfo.CloseGossip`, `CloseQuest`). No event of
  theirs is taken away, no field written, `UIPanelWindows` untouched. A window open when it is to be held is held
  once it closes. Given back: in a fight, with *Talks as a scene* off, when the module stands down (an open one into
  sight at once), and for a talk the game shows while ours does not (`Native.Check`, a moment after the game's own
  handler): never a talk out of sight.
- **The talk** (`Talk.lua`) follows the game's events: `GOSSIP_SHOW`, `GOSSIP_CLOSED`, `QUEST_GREETING`,
  `QUEST_DETAIL`, `QUEST_PROGRESS`, `QUEST_COMPLETE`, `QUEST_FINISHED`, `QUEST_ITEM_UPDATE`,
  `GET_ITEM_INFO_RECEIVED`, `PLAYER_INTERACTION_MANAGER_FRAME_SHOW`, `PLAYER_REGEN_DISABLED`/`ENABLED`. Every answer is
  the game's own call: `C_GossipInfo.SelectAvailableQuest`, `SelectActiveQuest` (by quest ID), `SelectOptionByIndex`
  (by the option's `orderIndex`), `CloseGossip`; `SelectAvailableQuest`/`SelectActiveQuest` (by index) for a greeting;
  `AcceptQuest` (a PvP quest asks first, `CONFIRM_ACCEPT_PVP_QUEST`; an offer the game made by itself is
  acknowledged, `AcknowledgeAutoAcceptQuest`), `CompleteQuest`, `GetQuestReward(choice)`, `CloseQuest`. Its skips
  follow the game's own code: `CustomGossipFrameManager:GetHandler(textureKit)`, `selectOptionWhenOnlyOption`,
  `QuestIsFromAdventureMap`, a `questStartItemID`, `QuestGetAutoAccept` with `QuestIsFromAreaTrigger`. A talk ended by
  the game waits `Talk.WAIT` before it goes, so a gossip turning into a quest (and a quest handed in, the gossip
  again) stays one scene; one left by the player goes at once.
- **The rewards** (`Rewards.lua`): `GetNumQuestChoices`, `GetQuestItemInfoLootType`, `GetQuestItemInfo`,
  `GetQuestItemLink`, `C_QuestOffer.GetQuestRewardCurrencyInfo`, `GetNumQuestRewards`,
  `C_QuestInfoSystem.GetQuestRewardCurrencies`/`GetQuestRewardSpells`/`GetQuestRewardSpellInfo` (spells already in
  the spellbook left out, as the game does), `GetRewardMoney`, `GetRewardXP`, `GetRewardHonor`, `GetRewardTitle`; an
  offer's rewards only where `C_QuestLog.ShouldShowQuestRewards` says so. Each item: `C_Item.GetItemInfo` (its
  class, subclass, equip slot, sell price; the slot's word is the game's `INVTYPE_*` string),
  `C_Item.GetDetailedItemLevelInfo`, the item worn in its slot (`GetInventoryItemLink` by the game's `INVSLOT_*`
  numbers; the ranged slot where `GetInventorySlotInfo("RangedSlot")` knows one, else the main hand: Retail), and
  `C_Item.GetItemStatDelta(new, worn)` (keys are the game's stat strings, `ITEM_MOD_*_SHORT`, `RESISTANCE0_NAME`).
  The usability is the game's own (`GetQuestItemInfo`'s `isUsable`). An item the game has not described yet shows
  its name and icon; the rewards are read anew a moment after `QUEST_ITEM_UPDATE` or `GET_ITEM_INFO_RECEIVED`.
- **The interface out of sight** (`Quiet.lua`): `UIParent`'s alpha (lent, `Core.Lend`) fades to 0 with the talk and
  back to what it was when the talk ends; at once when a fight begins. Nothing is hidden, so no `OnHide` of the
  game's runs from our code. Kept in sight by `SetIgnoreParentAlpha(true)` for that time (what each did before
  noted and put back): the talk's frame (always), `StaticPopup1`–`4`, `UIErrorsFrame`; `GameTooltip`,
  `ShoppingTooltip1` and `2` only while the mouse is on one of the talk's rewards, so the clear frames under the
  mouse show no tooltip. SaneUI's tooltip panels (Tooltips) follow their tooltip's setting. The clear frames still
  take the mouse where the talk does not lie over them.
- **Straight to the service** (`Service.lua`): Talk's `GOSSIP_SHOW` asks `Service.Take` first. An option's kind is
  the game's own icon of it (`option.icon`, `Interface\GossipFrame\*GossipIcon`): vendor, taxi, trainer, banker,
  auction house, battlemaster, tabard, petition are services; the talk icons (gossip, chat bubble) and the unlearn
  icon may stand beside one, an option with the `QuestLabelPrepend` flag never. Taken with the game's
  `C_GossipInfo.SelectOptionByIndex(orderIndex)` a frame after `GOSSIP_SHOW` (`Core.Later`) when there are no quests
  (`GetNumAvailableQuests`, `GetNumActiveQuests`) and exactly one service whose `status` is `Available`; not when the
  gossip was answered in between (`hooksecurefunc` on `C_GossipInfo`'s `SelectOption`, `SelectOptionByIndex`,
  `SelectAvailableQuest`, `SelectActiveQuest`, `CloseGossip` counts every answer, by anyone: Speed Leveling's guide
  answers in the event itself), not with `IsShiftKeyDown()`, within `Service.AFTER` (5) seconds of a
  `QUEST_FINISHED` at that NPC (`UnitGUID("npc")`), for a custom gossip frame, or for an only option the game takes
  itself. The game's gossip window is left as it is (held
  with the scene on, so nothing comes into sight; with the game's own windows it shows until the server answers).
  When neither `GOSSIP_CLOSED` nor another interaction (`PLAYER_INTERACTION_MANAGER_FRAME_SHOW`) comes within
  `Service.WAIT`, the talk shows after all.
- **The services as pictures** (`Icons.lua`): Talk gives each gossip option the large picture of its kind
  (`Icons.Picture`, by the option's `icon`, else its `overrideIconID`), none for an option with the
  `QuestLabelPrepend` flag; `Answers.Draw` leaves out what `Icons.Shown` takes, `Icons.Draw` lays those in a row of
  buttons centred over the box (`BOTTOM` on the box's `TOP`), each on a plate of its own (`Icons.INSET` round the
  picture), the answers marked `goodbye` last as `Icons.GOODBYE`, the game's open hand (`UIOpenhandCursor2x`, its 128
  piece; no tip, so no mask). They stay among the talk's answers, so a right click and Space find the same answer as
  before. The pictures are the game's: the cursor it shows
  over that NPC (`Interface\CURSOR\UIInnkeeperCursor2x`, `UIBuyCursor2x`, `UITrainerCursor2x`, `UITaxiCursor2x`,
  `UICursorPVP2x`, `UITransmogrifyCursor2x`; their 128 piece, at the same place in both games), the cursor's tip in its
  top left corner cut away by the game's diamond mask (`Interface\COMMON\common-mask-diamond`, twice the picture's
  side, its middle on the diagonal at 92/128, so its edge runs between the tip and the picture); the bank and the
  auction house by the map's own atlases of them (`PICTURES` in `Icons.lua`), unmasked. A `status` other than `Available` greys the
  picture (`SetDesaturated`) and the tooltip adds the option's `failureDescription` in the game's red; the click is
  still the game's call, which decides. Under the mouse the picture is laid over itself, added (`HIGHLIGHT` layer).
- **The column on the screen** (`Answers.Place`, after each draw and each paragraph, as the box's height changes
  with the words): its top level with the box's (`Box.Top`: `Box.FOOT` plus the box's height, plus the quest's frame
  and `Box.GAP` when one is under it), lifted to `Answers.MARGIN` (24) plus its height while its foot would be lower.
  The room is `UIParent`'s height divided by the talk's scale, less the margin twice; taller than that, the lines
  from `first` that fit in the room less two `Answers.ARROW` (22) bands, the game's `minimal-scrollbar-small-arrow-top`
  and `-bottom` (with their `-over` and `-down` looks, half as large again) in those bands where lines lie that way,
  `EnableMouseWheel` only then; `Answers.Scroll` moves `first` a line and clamps it so the last lines fill the room. A
  new talk starts at its first line. Across: when the box's half, `Answers.GAP` and `Answers.WIDTH` reach past the
  screen's right margin, `Box.Shift` moves the box (and the quest's frame, the column and the pictures hung on it) left
  that far, but not past the left margin; what is still over, the column's offset takes over the box's right side.
- **The spirit healer** (`Spirit.lua`): its option is the game's kind 4 (`GossipNPCOptionDisplayInfo`: icon
  `HealerGossipIcon`, 132054), drawn as `Interface\Icons\Spell_Holy_GuardianSpirit` (`Icons.lua`, its border cut off by
  its texture coordinates). The game asks with `StaticPopup_Show("XP_LOSS")` on `CONFIRM_XP_LOSS` (below
  `MIN_RES_SICKNESS_LEVEL` `XP_LOSS_NO_SICKNESS_NO_DURABILITY`, one step); `XP_LOSS`'s first `OnAccept` (its data the
  sickness's time) turns its text to `CONFIRM_XP_LOSS_AGAIN` and keeps it open, the second calls
  `C_PlayerInteractionManager.ConfirmationInteraction` and `ClearInteraction` of `Enum.PlayerInteractionType.SpiritHealer`
  (not restricted). Followed, never changed: `hooksecurefunc` on `StaticPopup_Show` and on both dialogs' `OnAccept`
  (read from their table at the click). On the last step (`XP_LOSS`'s accept with data, or the one-step window's
  show) a `UICheckButtonTemplate` of ours, its label *Don't ask me again*, stands centred under the window (strata
  `DIALOG`, over its level, ignoring the faded interface's alpha), gone with it (`OnUpdate`: the window hidden or
  showing another dialog); the last accept with it ticked sets `spiritAsk` off. Off, `StaticPopup_Show` of either is
  answered in the same frame with the window's own two calls and `StaticPopup_Hide`, so nothing is seen.
- **Space** (`Keys.lua`): `SetOverrideBindingClick` on a button of ours (`SaneUILoreContinue`) while the talk shows,
  `ClearOverrideBindings` when it ends; never in a fight (the talk ends before the lock).
- **Esc** ends the talk through Core's one stand-in in `UISpecialFrames` (`Core.Escape`).
- **The clicks** (`Talk.Click`): the box, the quest's frame and its rewards' lines take both mouse buttons; an answer's
  line keeps a button's default, the left alone. `Talk.Cycle` only moves `talk.at`. `Talk.Reply` gives what `Default`
  finds, as Space does on the last paragraph; `Default` finds nothing on a reward not chosen (the hand-in answer is
  disabled) or a quest that costs money (that answer is no default). `talk.ready` holds a right click back
  `Talk.SETTLE` seconds after a talk shows and after each answer. On a reward to choose at the hand-in the right button
  does nothing, even with another chosen, and `OnDoubleClick`, which the game also fires for the right button, looks
  at the button before it hands in.
- **Speed Leveling's quest givers** (`src/SpeedLeveling/Quests.lua`) touch none of this: at `QUEST_DETAIL`,
  `QUEST_PROGRESS` and `QUEST_COMPLETE` they call `AcceptQuest`, `CompleteQuest` and `GetQuestReward` themselves, not
  through the game's frames or ours. The talk shows for that moment and goes with the game's `QUEST_FINISHED`.
- **The look** (`Look.lua`, `Box.lua`, `Answers.lua`, `Quest.lua`, `Icons.lua`;
  [interface-style.md](../../Doc/guides/interface-style.md), *The talk over the world*): each part on a plate
  (`Look.Plate(frame, corner)`: nine pieces of Core's `Shape.SOFT_CORNER`, the corners turned by their texture
  coordinates and `corner` large, never more than half the frame's width or height (`plate:Fit`), the sides its last
  column or row stretched, the middle its whole part; the fade, half the corner, wholly inside the frame;
  `Look.PANEL` 32 for the words and the quest, `Look.BAR` 14 for an answer and a picture): `Look.DARK`, as solid as
  *Shade behind the words* (`Look.SHADE` 60 at first); under the mouse `Look.LIGHT` of the way to white. No border. A
  reward's line is the loot rolls' (`Quest.lua`): Core's `Shape.Bar` (the bar Loot's lines and rolls are made of,
  `Quest.ROW` 38 high as theirs) painted `Shape.Quality`, `Shape.Gold` for an item the quest asks for; the picture
  in a holder at its left end inside its border, round by `Shape.Caps`; `bags-greenarrow` before the name where the
  reward betters what is worn (`Better`: an empty slot, a higher item level; not where it cannot be used); the words
  by `Shape.BarFont` (18 and 13 as a loot line's), white, the line under the name `SOFT`, a rise white and a drop in
  the game's red (`Change`); `bar:SetLit` grey under the mouse, `bar:SetChosen` gold round the reward chosen. The parts stand `Box.GAP`, `Answers.GAP` and
  `Icons.GAP` (10) apart. The words in the game's font of its nameplates (`SystemFont_NamePlate_Outlined`, its file
  and outline at `Look.SIZES`), the game's gold for names and headings. One frame of ours (strata `HIGH`, so the game's questions and tooltips stand
  over it) holds every part, sized by *Size*; it appears and goes with a quick fade of its alpha. The face is a
  `PlayerModel` (`SetUnit` of `npc` or `questnpc`, `SetPortraitZoom`, the game's talk animation 60 while a paragraph
  is new). The column's foot is fixed over the screen's bottom: the quest under the words lifts the box.
- **Resilience:** every script, hook and timer behind `ns.Guard`, the events behind Core's event frame. An error
  stands the module down: Space unbound, the interface back, our talk hidden, the game's windows its own (an open
  one into sight at once, so the talk goes on there).
- **Data:** Lore gathers nothing (CLAUDE.md, *Backend and views*).
- **Tests:** `dev/tests/lore.lua` (the stand-in client): the windows held and given back, the talks and their
  answers' order, Continue, the words waiting at speed 0 and going on at a raised one, the clicks (the left going
  round, the right on every screen, no reward taken and nothing paid by it, a double click), Speed Leveling's own
  `Quests.lua` beside the talk, the rewards read (kinds, slots, value, changes, an empty slot, a bow's slot), a choice,
  a quest that costs money, a fight, a talk left to the game, a vendor's window, an NPC's only service taken (beside
  a word to say too, and each case that stays a talk, an answer given in between), the services as pictures over the
  talk (their pictures, the tip cut away, a click, the tooltip, greyed where refused, what stays in the column, the
  setting), a city guard's fourteen answers kept on the screen (lifted at Size 100 %; at 150 % the lines that fit,
  the wheel and the arrows through the rest, the talk moved left, the column placed anew as the words turn, a new
  talk at its first line), the look (an answer on its plate, lit under the mouse, the plates following *Shade behind
  the words* down to none, of nine pieces of the soft corner; a reward a loot roll's line of Core's bar, as high, the
  green arrow on an upgrade and none where it cannot be used, its border gold when chosen), the spirit healer's
  resurrection a picture and its questions (the tick on the last step only, cancelled or unticked nothing kept, ticked
  and accepted never asked again, both windows answered at once then, on again from the setting), Goodbye as the hand
  at the row's end, the settings,
  Retail, standing down. The interface lab's scene `talk` (`saneui showuilab`)
  draws an innkeeper's talk with the real code, `LabGuard()` a guard's, `LabQuest("detail")`, `("progress")` and
  `("complete")` a quest with its rewards.

## Files
| File | What it does |
| --- | --- |
| `SaneUI_Lore.toc` | The addon: its files in order |
| `Lore.lua` | The module, its words, settings, `GiveBack` |
| `Native.lua` | The game's gossip and quest windows held out of sight, given back |
| `Quiet.lua` | The interface faded out while talking; tooltips, questions and errors kept in sight |
| `Rewards.lua` | A quest's rewards, each item read: what it is, usable, value, what it changes |
| `Look.lua` | The font, the plates, the frame the parts stand in, its fade; coins and numbers |
| `Box.lua` | The NPC's face, name and words; the column's foot, its top's height, its shift left |
| `Answers.lua` | The answers beside the words, kept on the screen: lifted, paged by the wheel and arrows |
| `Quest.lua` | The quest under the words: objectives, what it asks for, rewards |
| `Icons.lua` | An NPC's services as big pictures without words in a row over the talk |
| `Keys.lua` | Space goes on while the talk shows |
| `Service.lua` | Straight to an NPC's only service, no talk before it; Shift shows the talk |
| `Spirit.lua` | The spirit healer's questions: Don't ask me again under the last one, then resurrected at once |
| `Talk.lua` | The talk as the game tells it, Continue, the answers' calls, fights |

## Not there yet
- Moving the talk in Edit Mode.
- Books, letters and plaques in the same scene (`ItemTextFrame`, [Dialogue.md](../../Doc/ideas/Dialogue.md)).
- The rest of [Lore.md](../../Doc/ideas/Lore.md): voices, the library, tidbits.

## History
- 2026-10-28: the module made, with talks as a scene (Saneroki asked: the talk see-through, the interface hidden
  while talking with its tooltips there, the rewards saying what they are, whether you can use them, what they sell
  for and what they change).
- 2026-10-30: the words wait for you (Saneroki asked: reading speed 0 at first, so the quest text never moves on by
  itself; a left click cycles through it; a right click accepts, or closes the window on the goodbye screen; Speed
  Leveling's taking and handing in go on as before).
- 2026-11-06: straight to the service (Saneroki asked: past the gossip window of "I need a ride" and "Show me your
  wares" without Speed Leveling; Shift shows the choices). The same day, "Skip those too": a word to say beside the
  service no longer keeps the talk.
- 2026-11-11: the services as big pictures over the talk (Saneroki asked: the hearthstone, the trainer, the vendor
  and the like as big icons with no text on them, over the talk, to click them quickly). The same day, the column of
  answers always on the screen (Saneroki: a guard's many answers went so far down that some were off the screen and
  could not be clicked). Then the talk redesigned (Saneroki: the shades and the answers faded into each other; side by
  side, Goodbye a picture over the talk too): every part on a plate of its own, as the loot window's lines. Then
  their edges soft (Saneroki: "instead of the black sharp border ... a fuzzy fadeout with rounded corners so they
  blend naturally into the world"): no border, the edge fading into the world inside each part. And the rewards as the
  group's loot rolls' lines (Saneroki: "So that rolling on loot or choosing the quest reward looks the same"). Then the
  spirit healer's resurrection a big picture too, and "Don't ask me again" on its last question, counting for both.
