# Sane UI: Lore

**Status:** built: talks with NPCs as a scene (gossip, a quest giver's greeting, a quest offered, in progress and handed in), see-through over the world, the interface out of sight meanwhile, a quest's rewards read for you · **Since:** 2026-10-28 · **Addon:** `SaneUI_Lore` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Lore is the world's words (plan: [Doc/ideas/Lore.md](../../Doc/ideas/Lore.md)). Its first part is the talk with an
NPC ([Doc/ideas/Dialogue.md](../../Doc/ideas/Dialogue.md)): instead of the game's gossip and quest windows, the NPC's
own 3D face, name and words stand low in the middle of the screen, straight on the world on a faint shade, a
paragraph at a time. What you can answer stands in a column beside them; a quest's objectives and rewards under
them. While you talk the rest of the interface fades out; the rewards' tooltips, the game's questions and its error
lines stay in sight. Each reward says, without its tooltip, what it is (Leather · Chest, Plate · Legs, a weapon's
kind, a ring by its slot), whether you can use it, what a vendor pays for it and what it changes against what you
wear (item level, stats). The words wait for you: a left click turns them, a right click accepts or says goodbye,
Space goes on. A fight ends the talk; the game's own windows are back whenever Lore steps aside or fails.

## How to use
- **Switch it on or off:** tick or untick *Lore* under *Sane UI* in the game's addon list (the game needs a
  restart when it was not in the list before). Its options: Esc > Options > AddOns > Sane UI > Lore.
- **Talk to an NPC** as always (a right click, the interact key, Speed Leveling's key). The talk appears:
  - **the face** at the left: the NPC's own model, talking while a paragraph is new; something with no face (a
    board, a book) shows the game's quest book;
  - **the name** in the game's gold beside it, **the words** under the name, one paragraph at a time, an action
    in `<...>` in the game's emote colour; at the bottom right which paragraph of how many (*2/4*);
  - **the answers** in a column right of the words, in this order: quests to hand in, quests offered, the NPC's
    other options (training, a flight, the inn), quests not done yet, *Goodbye*. Each has the game's picture for
    its kind; a quest far below your level is dimmed;
  - **a quest**, under the words: its title, its objectives and the group it is for when it is offered, what it
    asks for while in progress, its rewards when offered and handed in.
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
- **The rewards** (offered and handed in): the ones to choose from first (*Choose one*), then what you get besides,
  then experience, money, honor and a title in one line. A reward's line:
  - its icon with how many, its name in its quality's colour;
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
  - The mouse on it shows its tooltip with the game's comparison, in sight over the faded interface, without the key
    the module Tooltips waits for (`Core.tipsWanted`).
  - **Choosing:** a left click on a reward to choose chooses it (its shade darker, a gold line at its left); the hand-in
    answer then reads *Complete Quest* (before that *Choose a reward first*). A double click hands the quest in
    with that reward at once.
  - **A quest that costs money** to hand in says the price in its answer (*Complete Quest, paying 1g*), and is
    handed in only by a click on it, never by Space or a right click.
- **Ending:** *Goodbye*, *Decline*, Esc, walking away (the game ends the talk), or a fight. When the talk turns into
  another window (a vendor, a trainer, a flight map), that window opens and the talk goes.
- **In a fight:** the talk ends when the fight begins and the interface is back at once. A talk begun in a fight
  is the game's own window.
- **Left to the game:** gossip that has a window of its own in the game, an only option the game takes by itself,
  and an offer the game turns into a popup in its quest tracker (from an item, an area).
- **Settings** (Lore's page, section *Talks*):

  | Setting | At first |
  | --- | --- |
  | *Talks as a scene* (off: the game's own gossip and quest windows) | on |
  | *Fade out the interface while talking* | on |
  | *Shade behind the words* (0: the words alone over the world) | 30 % |
  | *Size* | 100 % |
  | *Words go on by themselves* | on |
  | *Reading speed* (words a minute; 0: the words never go on by themselves) | 0 |
  | *Space goes on* | on |

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
  mouse show no tooltip. Sane UI's tooltip panels (Tooltips) follow their tooltip's setting. The clear frames still
  take the mouse where the talk does not lie over them.
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
- **The look** (`Look.lua`, `Box.lua`, `Answers.lua`, `Quest.lua`): as the guide over the world
  ([interface-style.md](../../Doc/guides/interface-style.md), *The talk over the world*): Expressway with a thin
  dark outline, the game's gold for names and headings, soft dark shades whose sides fade out
  (`Texture:SetGradient`), no window. One frame of ours (strata `HIGH`, so the game's questions and tooltips stand
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
  a quest that costs money, a fight, a talk left to the game, a vendor's window, the settings, Retail, standing down.

## Files
| File | What it does |
| --- | --- |
| `SaneUI_Lore.toc` | The addon: its files in order |
| `Lore.lua` | The module, its words, settings, `GiveBack` |
| `Native.lua` | The game's gossip and quest windows held out of sight, given back |
| `Quiet.lua` | The interface faded out while talking; tooltips, questions and errors kept in sight |
| `Rewards.lua` | A quest's rewards, each item read: what it is, usable, value, what it changes |
| `Look.lua` | Fonts, shades, the frame the parts stand in, its fade; coins and numbers |
| `Box.lua` | The NPC's face, name and words; the column's foot |
| `Answers.lua` | The answers beside the words |
| `Quest.lua` | The quest under the words: objectives, what it asks for, rewards |
| `Keys.lua` | Space goes on while the talk shows |
| `Talk.lua` | The talk as the game tells it, Continue, the answers' calls, fights |
| `Fonts/Expressway.ttf` | The words' font (from `assets/optimized/Lore/Fonts/`) |

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
