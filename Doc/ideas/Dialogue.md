# Dialogue

Planning notes for **Dialogue**, the talk with an NPC, a part of the **Lore** module (Saneroki, 2026-10-28:
"make that a lore module"; before, 2026-10-16, a feature of Social). It shows talking to an NPC, and reading a
book or a letter, as a conversation instead of a parchment window. Saneroki asked for it on 2026-10-16.
**Built (2026-10-28, `src/Lore/`, its README):** gossip and the quest windows as a scene, the interface out of
sight meanwhile, the rewards read for you. Books and letters and Edit Mode are still to come.

## What it is

When the player talks to an NPC, the game opens its gossip window (`GossipFrame`) or its quest window
(`QuestFrame`: greeting, quest offered, progress, reward). Dialogue shows the same talk in one box of its
own: the NPC's face and name, its words a paragraph at a time, and under the words, inside the same box,
what the player can answer. One key, *Continue*, takes the talk forward; the mouse does everything else.
The game's windows stay where they are and come back at once whenever ours steps aside or fails.

- **Stands for:** `GossipFrame`, `QuestFrame` and the book and letter window `ItemTextFrame`
  (`Blizzard_UIPanels_Game`, this client's `Mainline` and `Shared` files).
- **Not:** vendors, trainers, the bank, the auction house. Economy's windows take those
  (`Doc/ideas/Economy.md`). When the talk turns into one of them, Dialogue closes and that window opens.

## What the player sees

### The talk box

- **Where (Saneroki, 2026-10-28: the dialogues "the same way", more transparent):** low in the middle of the
  screen, see-through over the world: the face at its left, the name and the words beside it; the answers in a
  column of their own right of the words; a quest's objectives and rewards under the words, lifting the box (the
  column's foot stays put). Moving it in Edit Mode is still to come.
- **The face:** the NPC's own 3D model (`PlayerModel:SetUnit` of `questnpc`, else `npc`), with no frame or
  background (see-through, Sane UI's own look: `Doc/guides/interface-style.md`, *The talk over the world*). It
  plays its talk animation while a paragraph is new and stands at rest otherwise. A thing with no face (a board,
  a chest) shows the game's quest book.
- **Name and title:** in the game's fancy gold font. Beside them, the friendship or reputation bar
  where the NPC has one (Blizzard's own `NPCFriendshipStatusBarMixin`).
- **A close button**, and the background of the quest's theme where the game gives one
  (`C_QuestLog.GetQuestDetailsTheme`, else the game's talking-head text plate,
  `TalkingHeads-TextBackground`).

### The words

- **A paragraph at a time:** the NPC's text is split where the game's own text breaks (`$B`, a new line);
  each paragraph appears whole, with no typing out letter by letter.
- **Going on** (Saneroki, 2026-10-30): the words wait for the player. A left click cycles through the paragraphs,
  after the last the first again, and never answers. A right click accepts the quest, or closes the window on the
  goodbye screen: the answer that needs no choosing, never a reward. Space goes on, and on the last paragraph gives
  that same answer. With *Words go on by themselves* and a reading speed above 0, the next one follows after the
  time the paragraph takes to read at that speed, counted in words per minute; at 0, as at first, never. While Lore
  speaks the text (`Doc/ideas/Lore.md`), the voice sets the pace instead.
- **Text in `<...>`** is what the NPC does, not says: shown in the game's emote colour
  (`ChatTypeInfo.MONSTER_EMOTE`), and the face does not talk for it.
- **The voice is Lore's:** Dialogue shows text only; where a voice pack has the line, Lore plays it,
  whichever window shows the talk.

### The answers

- **Beside the words, in a column of their own** (Saneroki, 2026-10-28), from the start of the talk: quests to
  hand in, quests offered, the NPC's other options, quests not done yet, Goodbye, each with the game's picture
  for its kind (its `Interface\GossipFrame` files; not `QuestUtil`, whose quest cache our code would write). A
  quest far below the player's level is dimmed, as the game does. A quest's own answers stand there too
  (Accept, Decline; Complete Quest, Goodbye).
- **Chosen by a click.** Highlighted under the mouse the way the game's gossip buttons are.
- **The services as big pictures over the talk** (Saneroki, 2026-11-11): the hearthstone, a vendor, a trainer, a
  flight master and the like, without words, in a row over the talk, a click away; their words in the tooltip.
- **Continue** on the last paragraph does what needs no choosing: accept the quest offered, hand in the
  quest whose reward is chosen, the one option there is, or goodbye when there is nothing to answer. Where
  there is a real choice, Continue waits for a click.

### A quest

- **Offered:** the quest's text, then in the same box its objectives, a spell to learn for it, the group
  it needs, and the rewards. The box grows downward for them.
- **In progress:** what it still asks for (items, money, currencies), what the player lacks in red.
- **Handed in, rewards compared inline:** each item to choose from stands in one line with what it changes
  against the item the player wears in that slot (the stats that go up and down, as the game's own
  comparison tooltip works them out), an item the player cannot use marked as the game marks it. A click
  chooses one; Continue then takes it.
- **Every reward item says, without its tooltip (Saneroki, 2026-10-28):** what gear it is (cloth, leather, mail,
  plate and its slot; a weapon's kind), whether you can use it, what a vendor pays for it, and how much it
  improves on what you wear (its item level against the one worn, the stats up and down). Its tooltip and the
  game's comparison are still there, in sight over the faded interface.
- **Rewards in the game's order:** items to choose, spells, a title, money, experience, items,
  currencies, honour. Each has the game's own tooltip on mouseover.
- **From our data (later):** where the quest stands in its chain (*part 3 of 5*), and the breadcrumb
  that leads to it. These come from Core's database (`Doc/ideas/Data.md`, `Quests:Chain`), read only.
  Without the data they are not shown.

### Continue, the one key

- **One binding:** *Continue* is Space (built: the switch *Space goes on* on Lore's page; nothing in a talk
  needs a jump). While the box shows, Space is bound to Continue over whatever it does elsewhere
  (`SetOverrideBindingClick` on a button of ours), and given back the moment the box closes. Every other
  key works as always.
- **Esc** ends the talk, as for the game's own windows.
- **A controller:** the player binds a button to Continue the same way, on the same page (to come).

### Books and letters (Saneroki: yes)

- **A book, a letter, a plaque** (`ITEM_TEXT_BEGIN`, `ITEM_TEXT_READY`, `ITEM_TEXT_CLOSED`) opens in the
  same box, a page at a time: the title (`ItemTextGetItem`), the page's text (`ItemTextGetText`), who
  wrote it (`ItemTextGetCreator`), and the game's paper behind it (`ItemTextGetMaterial`). The face shows
  the item's icon.
- Continue or a click turns the page (`ItemTextNextPage`); an arrow in the box's corner goes back
  (`ItemTextPrevPage`); Esc closes (`CloseItemText`).
- The game's window ends the reading when hidden (its `OnHide` calls `CloseItemText`), so it is held the
  same way as the others (*Taking over from the game's windows*).

### The rest of the screen (a choice)

- **The interface hidden while talking, its tooltips in sight** (Saneroki, 2026-10-28, in place of the dark
  veil planned before, so the world stays in sight around the see-through talk): the whole interface
  (`UIParent`) fades out with the talk and back in when it ends, at once in a fight. Nothing is hidden, only
  clear. The rewards' tooltips and their comparisons, the game's questions (`StaticPopup1`–`4`) and its error
  lines stay in sight (`SetIgnoreParentAlpha`). A setting keeps the interface in sight.

## How it is built

### Taking over from the game's windows

- **The holder from Economy** (`Doc/ideas/Economy.md`, *Hidden, not closed*):
  - Both game windows end the talk when they are hidden: `GossipFrameSharedMixin:OnHide` calls
    `C_GossipInfo.CloseGossip`, and the quest window's `OnHide` calls `CloseQuest`. So they are never
    hidden while in sight.
  - Between talks they get a hidden parent of ours. The game shows them as always, but they never come
    into sight, so their `OnShow` and `OnHide` do not run.
  - The quest window checks after `ShowUIPanel` that it is shown (`QuestFrame:IsShown()`), else it ends
    the quest. A held window still counts as shown, so this holds.
  - Parent, strata and level are noted before they are changed and put back exactly (built: `src/Lore/Native.lua`).
  - No events of the game's windows are taken away, no global is replaced, and `UIPanelWindows` is left
    alone.
- **The way back:**
  - The switch *Talks as a scene* gives the game's windows back (built); a *Classic* button on our box for
    one talk, and a *Sane UI* button on the game's window, are not built.
  - If our code fails (`module.Guarded`), the game's window is given back at once (built).
  - A talk the game shows in its window while ours does not show it (one of the kinds below, or one ours does
    not know) is given back into sight at once (built: `Native.Check`).
- **Talks the game shows its own way:**
  - Gossip with its own special window (`CustomGossipFrameManager`, by the talk's texture kit) is left to
    the game.
  - So is an offer from an item or an area that the game turns into a popup in the quest tracker. That
    follows the game's own `QuestFrame` code: the popup, then `CloseQuest`.
- **Only one option, and no quests:** where the game chooses that option by itself, Dialogue does the
  same (`selectOptionWhenOnlyOption`), and shows nothing.
- **Another window takes over** (a vendor, a trainer, a flight map): at
  `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` of any other kind, our box closes.

### Events and calls

- **Events:** `GOSSIP_SHOW`, `GOSSIP_CLOSED`, `QUEST_GREETING`, `QUEST_DETAIL`, `QUEST_PROGRESS`,
  `QUEST_COMPLETE`, `QUEST_ITEM_UPDATE`, `QUEST_FINISHED`, `QUEST_ACCEPTED`,
  `PLAYER_INTERACTION_MANAGER_FRAME_SHOW`.
- **Calls:** the game's own:
  - for gossip, `C_GossipInfo` (`GetText`, `GetOptions`, `GetAvailableQuests`, `GetActiveQuests`,
    `SelectOptionByIndex`, `SelectAvailableQuest`, `SelectActiveQuest`, `CloseGossip`);
  - for quests, `GetQuestText`, `GetObjectiveText`, `GetProgressText`, `GetRewardText`,
    `GetGreetingText`, `AcceptQuest`, `CompleteQuest`, `GetQuestReward`, `CloseQuest`;
  - for rewards, the game's reward calls.
- **Each call goes through `Core.Ask`**, so a call this client lacks is nil, not an error.

### Combat and the key

- **Combat closes the dialogue** (Saneroki): at `PLAYER_REGEN_DISABLED` the talk ends with the game's own
  call (`C_GossipInfo.CloseGossip`, `CloseQuest`, `CloseItemText`), and the box and the veil fade out. A
  talk that begins in combat is not shown by Dialogue: the game's own window comes, as with *Classic*.
- **So the Continue binding is never set in combat:** override bindings cannot change there, and the box is
  gone before it would have to be.

### Resilience and secrets

- **A failure gives the game its window back** (above). The talk itself is the game's, so it goes on.
- **Secret values:** the NPC's name can be a secret value in this client, so every value goes through
  `Core.Plain`. A secret name is shown as the game shows it, and is never compared or kept.

### Performance

- **Nothing before the first talk:** Lore registers the talk's events at login, and makes its frames at
  the first talk.
- **Reused, not made anew:** answers and reward lines come from pools or are made once.
- **One timer**, and only while paragraphs go on by themselves (`C_Timer.After`; a later talk or paragraph makes
  it do nothing). An `OnUpdate` only while something fades.
- **No tables made per frame.**

### Rules Dialogue keeps

- **One key, only while shown:** Continue's binding lives exactly as long as the box.
- **The game's windows held, never changed:** what Dialogue moves it notes first and puts back; no table
  of the game's is written.
- **Made once:** frames, pools and hooks at the first talk, then reused.

### Data

- **Dialogue gathers nothing** (CLAUDE.md, *Backend and views*). What a talk shows the game is Core's
  watchers' business, whether Dialogue is on or not (`Doc/ideas/Data.md`, *What the game tells, and
  when*).
- **Dialogue only reads:** the quest's chain, the breadcrumb, and later the NPC's services.
- **Reading a talk again** is Lore's library (*Tales*, `Doc/ideas/Lore.md`), not Dialogue's.

## Settings

On Lore's page, section *Talks*; account-wide (built 2026-10-28, `src/Lore/README.md`).

| Setting | Default |
| --- | --- |
| Talks as a scene (off: the game's gossip and quest windows) | on |
| Fade out the interface while talking | on |
| Shade behind the words (0: the words alone over the world) | 30 % |
| Size | 100 % |
| Words go on by themselves | on |
| Reading speed (words a minute; 0: never by themselves) | 0 |
| Space goes on | on |
| Services as icons (an NPC's services as big pictures over the talk; off: in the column) | on |
| Straight to the service (an NPC's only service at once; Shift: the talk) | on |

- **Moving the talk:** in Edit Mode like every Sane UI window (`Doc/ideas/Windows.md`): still to come.

## Decided

Saneroki, 2026-11-11:

- **The services as big icons:** "The dialogue option has common things like The hearthstone, Trainer, Vendor etc.
  Can you make those big icons that don't have any text on them. The icons are self expenatory. Make those big and
  over the conversation window so you can quickly click them to open them quickly" (`src/Lore/Icons.lua`). Claude's
  picks, for Saneroki to change: the row centred over the talk on its own shade, each picture 48 at Size 100 %; the
  game's own large pictures (the cursor the game shows over such an NPC, its tip cut away; the bank's and the auction
  house's map pictures, which have no cursor); the hearthstone, vendor, trainer, flight master, battlemaster,
  transmogrification, bank and auction house as pictures, the rest (a tabard, a guild charter, unlearning, the spirit
  healer, an option marked *(Quest)*) in the column; a refused one greyed, its reason in the tooltip; a setting,
  on at first.

Saneroki, 2026-11-06:

- **Straight to the service:** talking to an NPC whose gossip is only "I need a ride" or "Show me your wares" opens
  that window at once, without Speed Leveling; Shift shows the choices (`src/Lore/Service.lua`). And with a word to
  say beside the service ("Skip those too"). Claude's picks, for Saneroki to change: the services by the game's own
  icons (vendor, flight master, trainer, banker, auction house, battlemaster, tabard, charter), a trainer's unlearning
  may stand beside one too; never with a quest there, an option the game marks *(Quest)* or two services, nor in the
  talk that opens again after a quest handed in there, nor over an option Speed Leveling's guide takes; on at first.

Saneroki, 2026-10-30:

- **Reading speed 0 at first:** the quest text moves on by itself only where Speed Leveling's *Take the guide's
  quests* and *Hand in the guide's quests* do the quest; else it waits. Left click cycles, right click answers.

Saneroki, 2026-10-16:

- **Hiding the rest of the interface:** on by default, with a setting to keep it in sight.
- **Combat** closes the dialogue.
- **Books and letters:** yes.

Saneroki, 2026-10-28 (superseding the name and the place of 2026-10-16, and the veil):

- **A part of the Lore module** (`SaneUI_Lore`), not of Social.
- **The same way as the talk he likes, more transparent:** the talk low in the middle of the screen, see-through
  over the world; the answers in a column beside the words; the quest under them.
- **The interface hidden while talking, the tooltips in sight** to see and compare the rewards.
- **The rewards say what they are without their tooltip:** the gear's kind (cloth, leather, mail, plate, ...),
  whether you can use it, what a vendor pays for it, what it improves.

Claude's picks (2026-10-28), for Saneroki to change: Space as the Continue key (on by default, a switch); the
answers there from the start of the talk; a quest that costs money handed in only by its answer; Expressway and
the game's gold, as the guide over the world.

## Open questions for Saneroki

- **Accepting and handing in by themselves** (board #107: "with auto accept quest and rewards"): every quest
  offered accepted at once, and a quest with one reward or none handed in at once? Speed Leveling does so for the
  guide's quests already (its *Quest givers*).

## Order of work

1. ~~The holder and the way back, proven with the gossip window and plain talk.~~ Built 2026-10-28, in Lore.
2. ~~The talk box: face, name, paragraphs, answers, Continue; combat closes it.~~ Built.
3. ~~Quests: offered, in progress, handed in, the rewards compared inline, the choice.~~ Built, with each reward
   read for you.
4. Moving the talk in Edit Mode. Books and letters.
5. The chain from Core's data, once it is there.
