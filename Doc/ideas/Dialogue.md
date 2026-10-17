# Dialogue

Planning notes for **Dialogue**, a feature of the **Social** module (Saneroki, 2026-10-16: not a module of
its own; `src/Social/`, `Doc/ideas/Social.md`). It shows talking to an NPC, and reading a book or a
letter, as a conversation instead of a parchment window. Saneroki asked for it on 2026-10-16. Nothing is
built yet.

## What it is

When the player talks to an NPC, the game opens its gossip window (`GossipFrame`) or its quest window
(`QuestFrame`: greeting, quest offered, progress, reward). Dialogue shows the same talk in one box of its
own: the NPC's face and name, its words a paragraph at a time, and under the words, inside the same box,
what the player can answer. One key, *Continue*, takes the talk forward; the mouse does everything else.
The game's windows stay where they are and come back at once whenever ours steps aside or fails.

- **Stands for:** `GossipFrame`, `QuestFrame` and the book and letter window `ItemTextFrame`
  (`Blizzard_UIPanels_Game`, this client's `Mainline` and `Shared` files). Social's *Classic windows*
  list names them.
- **Not:** vendors, trainers, the bank, the auction house. Economy's windows take those
  (`Doc/ideas/Economy.md`). When the talk turns into one of them, Dialogue closes and that window opens.

## What the player sees

### The talk box

- **Where:** in the middle of the screen (Saneroki), at Core's dock place `CENTER`, where the windows the
  player talks to stand (`Doc/ideas/Windows.md`), moved in Edit Mode like every Sane UI window. The face at
  its left, the words and the answers beside it, top to bottom.
- **The face:** the NPC's own 3D model (`PlayerModel:SetUnit` of `questnpc`, else `npc`) in Blizzard's
  talking-head frame (atlas `TalkingHeads-PortraitFrame`). It plays its talk animation while a paragraph is
  new and stands at rest otherwise. A thing with no face (a board, a chest) shows its quest's or item's icon
  in the same frame.
- **Name and title:** in the game's fancy gold font. Beside them, the friendship or reputation bar
  where the NPC has one (Blizzard's own `NPCFriendshipStatusBarMixin`).
- **A close button**, and the background of the quest's theme where the game gives one
  (`C_QuestLog.GetQuestDetailsTheme`, else the game's talking-head text plate,
  `TalkingHeads-TextBackground`).

### The words

- **A paragraph at a time:** the NPC's text is split where the game's own text breaks (`$B`, a new line);
  each paragraph appears whole, with no typing out letter by letter.
- **Going on:** *Continue* (or a click on the words) shows the next paragraph. With *Paragraphs go on by
  themselves*, the next one follows after the time the paragraph takes to read at the player's reading
  speed, counted in words per minute; while Lore speaks the text (`Doc/ideas/Lore.md`), the voice sets the
  pace instead.
- **Text in `<...>`** is what the NPC does, not says: shown in the game's emote colour
  (`ChatTypeInfo.MONSTER_EMOTE`), and the face does not talk for it.
- **The voice is Lore's:** Dialogue shows text only; where a voice pack has the line, Lore plays it,
  whichever window shows the talk.

### The answers

- **Under the words, inside the box,** once the last paragraph is shown: the game's own order (quests to
  hand in, quests offered, the NPC's other options, quests not done yet), each with the game's icon for
  its kind (`QuestUtil`). A quest far below the player's level is dimmed, as the game does.
- **Chosen by a click.** Highlighted under the mouse the way the game's gossip buttons are.
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
- **Rewards in the game's order:** items to choose, spells, a title, money, experience, items,
  currencies, honour. Each has the game's own tooltip on mouseover.
- **From our data (later):** where the quest stands in its chain (*part 3 of 5*), and the breadcrumb
  that leads to it. These come from Core's database (`Doc/ideas/Data.md`, `Quests:Chain`), read only.
  Without the data they are not shown.

### Continue, the one key

- **One binding:** *Continue*, chosen on Social's page (*proposal*: Space, as nothing in a talk needs a
  jump). While the box shows, that key is bound to Continue over whatever it does elsewhere
  (`SetOverrideBindingClick` on a button of ours), and given back the moment the box closes. Every other
  key works as always.
- **Esc** ends the talk, as for the game's own windows.
- **A controller:** the player binds a button to Continue the same way, on the same page.

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

- **A veil while talking** (Saneroki: the rest of the interface out of sight by default; a setting keeps
  it in sight): one dark full-screen frame of ours at the strata just under the box. It covers the bars,
  the frames and the minimap, while everything the game puts on the dialog strata and above (questions,
  alerts, tooltips) stands over it by the game's own layering. No frame of the game's is hidden, faded or
  listed: nothing to keep in step with the game's own frames.
- **Its darkness** is a setting; the veil fades in with the box and out when the talk ends.

## How it is built

### Taking over from the game's windows

- **The holder from Economy** (`Doc/ideas/Economy.md`, *Hidden, not closed*):
  - Both game windows end the talk when they are hidden: `GossipFrameSharedMixin:OnHide` calls
    `C_GossipInfo.CloseGossip`, and the quest window's `OnHide` calls `CloseQuest`. So they are never
    hidden while in sight.
  - Between talks they get a hidden parent of ours. The game shows them as always, but they never come
    into sight, so their `OnShow` and `OnHide` do not run.
  - The quest window checks after `ShowUIPanel` that it is shown (`QuestFrame:IsShown()`), else it ends
    the quest. A held window still counts as shown, so this holds. *To check in the game.*
  - Parent, scale and alpha are noted before they are changed and put back exactly.
  - No events of the game's windows are taken away, no global is replaced, and `UIPanelWindows` is left
    alone.
- **The way back:**
  - A *Classic* button on our box gives the game's window back for that talk. It is remembered as
    Economy's choice is (Core's `window:Native`).
  - A *Sane UI* button on the game's window brings ours back.
  - If our code fails (`module.Guarded`), the game's window is given back at once.
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

- **Nothing before the first talk:** Social registers Dialogue's events at login, and makes its frames at
  the first talk.
- **Reused, not made anew:** answers, reward lines and the veil come from pools or are made once.
- **One timer**, and only while paragraphs go on by themselves (`C_Timer.NewTimer`, cancelled when the talk
  ends). There is no `OnUpdate` while nothing moves.
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

Under a heading *Dialogue* on Social's page; account-wide, with a switch for the whole feature (on).

| Setting | Default |
| --- | --- |
| Hide Blizzard's windows (gossip and quest) | on |
| Continue key | Space (*proposal*) |
| Paragraphs go on by themselves | on |
| Reading speed (words per minute) | to be chosen in play |
| The veil while talking (its darkness; none keeps the interface in sight) | dark (Saneroki) |
| Size of the talk box | 100 % |

- **Moving the box:** it is moved in Edit Mode like every Sane UI window (`Doc/ideas/Windows.md`).

## Decided (Saneroki, 2026-10-16)

- **Name:** *Dialogue*, a feature of Social, not a module of its own.
- **Place:** the middle of the screen.
- **Hiding the rest of the interface:** on by default (the veil), with a setting to keep it in sight.
- **Combat** closes the dialogue.
- **Books and letters:** yes.

## Open questions for Saneroki

- **The answers:** under the words, inside the box (as planned here), or beside it?
- **Continue's default key:** Space, or none until the player picks one?

## Order of work

1. In Social: its files (`Dialogue*.lua`, in Social's TOC), its settings, its part of the README. The holder
   and the way back, proven with the gossip window and plain talk.
2. The talk box: face, name, paragraphs, answers, Continue; combat closes it.
3. Quests: offered, in progress, handed in, the rewards compared inline, the choice.
4. Books and letters. The veil.
5. The chain from Core's data, once it is there.
