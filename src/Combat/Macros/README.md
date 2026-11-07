# Sane UI: Combat: Sane Macros

**Status:** built · **Since:** 2026-11-02 · **Part of:** the module Combat (`SaneUI_Combat`, `src/Combat/Macros/`) · **Game:** WoW:
Forever and Retail · **Tests:** `dev/tests/macros.lua`; the lab's scene `combat-full`.

## TL;DR
*Sane Macros* stands in for the game's macro window. A macro is a list of steps, as long as you like, and there are no
slots to run out of. One step is what a normal macro is; several make a sequence that goes on with every press. Every
condition of the game's macros is an option with its explanation, behind a **+** button. A macro goes on a key or on one
of your normal action bar buttons. The macros are your account's, on every character.

## How to use
- **Open it:** `/macro`, the game menu's *Macros*, `/sane macros`, or the key *Open or close Sane Macros* (Sane UI, in
  the game's key bindings). It opens on Combat's full screen, beside your action bars; where that cannot come (Edit Mode, the
  full screen switched off) as a window of its own, whose first title bar button goes to the game's own macro window. The
  game's macros stay as they are.
- **New macro:** *New* makes an empty one, or takes one over from the game's macros as macro text. *Copy*, *Delete*.
- **Whose it is and the filter** (Saneroki, 2026-11-04: "only the relevant ones for each class ... a dropdown that is show all
  ..., a general one ... and a per character one"): a macro is every character's (a general one: Sit, Follow, the potions),
  a class's (every warrior's) or one character's. The dropdown over the list shows *This character* (its class's and its
  own), *General* or *Show all* (every one of the account's), as the character chose it last, *Show all* at first; the
  game's macros under them follow it (its account macros are general ones, its character macros this character's). A
  right click on a macro says
  whose it is and changes it. A new macro is this character's under *This character*, else a general one; a copy keeps whose
  it is. A key or a bar button works whoever's the macro is.
- **The list** (Saneroki, 2026-11-04): as the game's macro window shows its macros, squares of their pictures with the names
  under them, yours first, the one chosen lit in gold; a key shows at the picture's corner as on a bar button, a red **!** where
  the checks found something. A macro's picture is its own where it has one (Saneroki, 2026-11-04), else that of its first
  step switched on; macro text with no spell shows the question mark. A game's macro taken over keeps its picture. On its bar
  button the step that comes next shows, and the macro's own picture where that step has none (macro text, a spell not known).
- **Its picture** (Saneroki, 2026-11-04): click the picture at the top of the macro. A large window opens over everything,
  the full screen too: on the left the groups (All, In the game, each class, Weapons, Armor, Consumables, Trade goods,
  Other items, Spells and abilities, Mounts and pets, Achievements, Other), at the top a search box over the names and
  groups, then every icon of the game's. The mouse on one names it and says which spells and items show it. A click
  gives the macro that picture; *Steps' picture* takes its own away. Esc closes it.
- **The game's macros** (Saneroki, 2026-11-03) stand in the list under yours, under their own line and marked with a gold **W**. A click opens it in the
  game's own macro window, on that macro; a drag puts it on an action bar as the game's macro; a right click makes a Sane
  Macro of it. The button *Game macros* over the list opens the game's window, from the full screen too; its button *Sane UI*
  brings Sane Macros back. Until then `/macro` opens the game's.
- **Its key:** *Set key*, then press the key, with Shift, Ctrl or Alt if you like, or a mouse's extra button. Esc leaves it
  as it was; a right click takes it away. For this character, and it stays out of the game's own key settings.
- **Its bar button:** drag the macro from the list, or its picture, onto a button of your action bars, or click *Place on
  bar* and choose one. Its picture follows the mouse and the button under it gets a gold frame; the bars stay clear. It works and
  looks like a normal button, with that button's keys, on that page of Bar 1. What the button holds stays underneath and is
  back when the macro is taken off (a right click on the same button in the window). One button a macro, for this character.
  On the bar it acts as the game's buttons do (Saneroki, 2026-11-06): drag a spell from the spellbook, an item or an action
  onto it, or click one onto it, and that takes its place (the macro comes off; what the button held underneath goes onto
  your cursor, as when two buttons swap). Drag the macro itself with the pick-up key (Shift) held, or with the bars
  unlocked: let go on another button and it stands there, on no button and it is off the bars. Out of a fight.
  On a druid's Bar 6, which swaps with the form (Abilities), a macro is on the bar it showed when placed, as a spell is
  (Saneroki, 2026-11-06): put there while it shows Bar 9, it is Bar 9's, shows in Bear Form alone and says *Bar 9*.
- **Order:**
  - *Each press takes the next step:* a sequence. Every press goes on to the next step and comes round again.
  - *Every press starts at the top:* a normal macro. A press takes the first step whose conditions hold.
- **Steps:** *Add step*, or drop a spell, an item or one of the game's macros on the list. Drag a step to move it, untick it to
  leave it out, X deletes it.
- **A step:** a spell, an item, or macro text (any commands, up to 255 characters in a step), who it is cast on, and how
  often it comes up in a round (spread out evenly among the others).
- **Only when:** the **+** lists the conditions by group, each explained. Click a condition for its opposite, right click
  to take it away. A step whose conditions do not hold is skipped in that same press. In macro text the **+** beside the box
  writes the condition where the cursor stands.
- **Once per target** (Saneroki, 2026-11-07: "/cast [if no rend] Rend", "not only Rend"): the **+**'s group *Target* holds
  it for a spell's or an item's step; it works with *Each press takes the next step*. The step is cast once on each target: a Rend, a Hunter's Mark, a Faerie
  Fire. After the cast its turn does nothing (no global cooldown, no rage) until you change target or the fight ends, so
  the next press goes on; its bar button shows it dimmed meanwhile, and its tooltip says why. It only knows that it was
  cast, not whether the aura is still on, missed or was taken off. It has no opposite; a right click takes it away. From
  the top, or on macro text, it would not work: the check says so.
- **Start over after a fight:** a tick, on at first.
- **The checks:** a red **!** on a macro or a step says something would not work as it stands; the mouse on it says what. The
  switch *Check macros*. A spell not learnt yet or an item none of is held is said at its step but marks nothing in the
  list (Saneroki, 2026-11-04: "many have red !"): so it is for now, nothing is wrong with the macro.
- **What it cannot do:** the game keeps rage, cooldowns and auras from anything that decides a press. So a step is never
  skipped because a spell is on cooldown. The game refuses it, that press is spent, and the next press goes on: keep pressing
  and what can be cast gets its turn. "If no Rend on the target, cast Rend" is not possible in any addon; *Once per target*
  comes closest, by your casts and your target instead of the aura.
- **Game macros to bars:** nothing here changes them. Sane Macros needs no macro slots.

## Technical details
- **The press** (`Press.lua`). Every macro with a key or a bar button has a hub, a secure button holding its turns in
  numbered attributes (`m<n>` the line, `c<n>` the condition). A key clicks the hub. The snippet, wrapped on `OnClick`, runs before the
  button's action, in a fight too: it walks from where the macro stands (`at`, or 1 with `top`) past every turn whose condition
  fails, by `SecureCmdOptionParse`, sets the first that holds as the button's `macrotext`, and moves on. Nothing true: no text, and
  the game runs nothing. A press is one edge only (`Press.Ready`): the snippet runs on every edge registered. A key's
  button, the hub, acts on the edge of the game's key-down setting; our bar button is the mouse's and acts on the release,
  the only edge the game acts on for a mouse's click of a secure button (`SecureActionButton_OnClick`); the bar slot's keys
  press the hub (Saneroki, 2026-11-04). The game's Press and Hold Casting (`ActionButtonUseKeyHeldSpell`) stops a cast at
  the key's release, which it hands to its own buttons only (`typerelease`): while it is on, a macro that casts says so
  (`Check.lua`, a red **!**); Speed Leveling's profile has it off. Numbered attributes keep a snippet's text free of the game's bans (no closure's keyword, no brace) whatever a step says.
- **Once per target** (`Write.lua`). The snippet cannot read auras (the newest export's `RestrictedEnvironment.lua` gives
  it no aura call, the game's conditions have no aura word), and addon code that reads them may not write to the hub in a
  fight. The game's own cast sequence (`Blizzard_ChatFrameBase`, `CastSequenceManager.lua`) goes on to its next name only
  at `UNIT_SPELLCAST_SUCCEEDED` of that spell, and starts over at `PLAYER_TARGET_CHANGED` and `PLAYER_REGEN_ENABLED` (and
  at death), in a fight too. So the step's line is `/castsequence [@unit,conditions] reset=target/combat Rend, null`
  (`Write.Sequence`, an item as `item:<number>`): Rend, then `null`, a name the game casts nothing for, until it starts
  over. The word is Sane Macros' own (`Conditions.OURS`): never between the brackets, not asked by the press, no `no`
  (`Book` cleans one away), offered only for a spell's or an item's step (`Picker.Open`'s `ours`; from the top too, so
  it is found there, and the check says why it waits for a sequence). From the
  top the turn would be taken on every press and do nothing, so there it is written as a plain cast and `Check` says
  so; on macro text too. What shows: a turn keeps its sequence (`turn.sequence`), and `Press.Waits` asks the game's
  `QueryCastSequence` (plain, in a fight too) whether it stands past its first name: dimmed, a line in the tooltip. The
  game moves its sequences at the same news as ours, so a new target, a fight's end and the player's cast paint a frame
  later (`Core.Later`).
- **What secure code can do.** On a press it may rewrite its own button in a fight. It cannot read rage, cooldowns, auras or
  the clock, and addon code cannot write to it then. An addon's change waits for `Core.AfterCombat`.
- **Written out** (`Write.lua`). Plain text, testable alone. How often: each turn of a step gets a mark at its share of a
  round, half a share in, and the marks are read in order.
- **A bar button** (`Face.lua`, `Reach.lua`). Our own secure button in the bar's frame, anchored to the game's button, so it
  goes with the bar at rest and in Edit Mode's moves, and its own press reads the same hub (`GetFrameRef("hub")`). The game's
  button is never touched. A state driver per place says `ours` while the bar shows that button; a snippet then shows ours
  and takes the button's keys by override bindings, and gives them back on another page of Bar 1, in a vehicle or on a bar the
  game puts in place of yours, in a fight too. Keys read from the game's bindings; `UPDATE_BINDINGS` takes a change.
  A button of Bars 2 to 8 that holds a row of its own says so by its own `actionpage` (a druid's Bar 6 holds 9 or 10 in
  a form, Abilities' `FormBar.lua`; the game's bars set theirs on the bar, never on a button): a place made there names
  it (`MultiBar5Button4:9`, `Reach.Row`, `Reach.PlaceOf`). The game's secure code turns the row, in a fight too, so a
  wrap of the button's `OnAttributeChanged` (`SecureHandlerWrapScript`, `Reach.ROW`; the button is explicitly protected,
  so it runs in a fight) sets the place's frame's `state-row`; one snippet (`Reach.SLOT`) runs for `slot` and `row` and
  shows ours while `slot` is `ours` and the row is the place's (0 the bar's own). The wrap is made once a place and stays.
- **A bar button, as the game's** (`Face.lua`). Something on the game's cursor (`GetCursorInfo`) let go on our button
  (`OnReceiveDrag`) or clicked onto it (`OnMouseDown`, left: the button hides at once, so the click runs no step) takes the
  macro off (`Macros.TakeOff`), and the game's own `PlaceAction` puts it on the game's button beneath, by that button's
  `action`; what it held goes onto the cursor, as the game swaps two. A drag (`RegisterForDrag`) lifts the macro where the
  game's button would lift its action (`lockActionBars` off, or `IsModifiedClick("PICKUPACTION")`): `Place.Start` with
  its picture, and at `OnDragStop` `Place.Drop` says where: a button (true: `Reach.SetPlace`), none (false: off the
  bars), or the placing ended before (nil: Esc, a fight; it stays). In a fight nothing changes, and it says so.
- **Choosing a bar button** (`Place.lua`). An unseen square over every button of every bar that shows takes the click, so a click
  casts nothing; nothing is drawn over the bars (Saneroki, 2026-11-04: a gold wash over every button hid them). The button under
  the mouse comes from the frames the game says are under it (`GetMouseFoci`), only then from each square's `IsMouseOver`: a
  square hangs on the game's button, and where the game keeps that button's place to itself the answer is hidden (`Core.Plain`: no).
- **The picture window** (`Icons.lua`). A Core window of kind panel at `FULLSCREEN_DIALOG` (over the full screen, HIGH,
  and its meter, DIALOG; tooltips above), most of the screen up to 1180 x 820, made at its first opening, with a dark
  ground under Core's plate. The icons are Core's set `Icons` (`Doc/guides/data.md`, *The icons*), read once a part per
  frame (`Data` `Each`), sorted by name whatever the case. Groups: a class's where its spells show the icon (`classes`)
  or the name begins `Ability_<class>_`, `Spell_<class>_` or `ClassIcon_<class>`; an item group where items of that class
  show it (`itemClasses`) or its name begins as such icons do (`Icons.ITEMS`); then by name (`Icons.NAMED`), the first that
  fits; *Other* for none; *In the game* for an icon a spell or item of the set shows. Only groups with icons are listed.
  The grid is the game's scroll box grid (`CreateScrollBoxListGridView`, its buttons handed round); the search is
  `Core.Fuzzy.Filter` over the name (underscores as spaces) and the groups' words, a moment after the last key, in the
  group chosen. A tooltip's spells and items by the game's names (`C_Spell.GetSpellName`, `C_Item.GetItemNameByID`;
  an item not read yet is asked for). Without the set (refused), the game's own lists (`GetMacroIcons`,
  `GetMacroItemIcons`) stand in, by file number. It closes when Sane Macros goes, at Esc, and at standing down.
- **What shows.** The picture of the turn the next press would take (`Press.Next`, the game's parser answers plainly in a fight),
  its cooldown by the game's duration object (a hidden value is taken as it is), dimmed by `C_Spell.IsSpellUsable` (plain in a
  fight). `isActive` of a cooldown is true during the GCD too.
- **The list of conditions** (`Conditions.lua`). The game takes a word it does not know as true, without a sound, and a word
  that is always true cannot be told from an unknown one by asking it. So the words stand here, for the + and for the check of
  macro text.
- **The checks** (`Check.lua`) run at an edit, on opening, and at `SPELLS_CHANGED` and `BAG_UPDATE_DELAYED` while the window shows.
  They say what can be known ahead; a clean check does not mean a spell is ready.
- **On the full screen.** The part `macros` of Combat's board (`Board.Part`). One page, made once, goes where it is shown: the panel's
  body or the window of its own (`Into`), and takes the room it has (`Editor.Size`, `Steps.Width`, `Detail.Width`). Opening the window
  of its own tries the full screen first (`ToBoard`), and it shuts unseen.
- **Saved.** Macros in `Core.Store("Macros")` (the account, every profile; whose: `class`, `char`), keys, places and the list's
  filter in `Core.Character("Macros")`: apart
  from Combat's own, so that their names cannot meet. The switches are Combat's (`macroChecks`, `macroDim`, `macroKey`). Its parts
  stand in `ns.Macros`, as Combat already has a `Book`, a `Face` and a `Press`-like name or two.
- **The game's window** is held by Core (`native.hold`, `Blizzard_MacroUI`), so the frame is made at login, empty; what it
  holds is made when first shown. A hub is made only for a macro with a key or a place. `Editor.OpenGame` brings the game's
  (`window:Native(true)`, the full screen left first) and chooses a macro there by the game's own `ChangeTab` and
  `SelectMacro`, where the client has them; the list reads the game's macros again at `UPDATE_MACROS`.
- **The way in for other code:** `SaneUI.Combat.Macros.Add(name, body, picture, owner)` makes a macro under that name, once, with that
  picture where one is given (a texture's path or number; `Book.Icon` keeps no question mark): of macro
  text a normal macro, of a table `{ top, fresh, steps = { step, ... } }` a macro of those steps, each step in the shape
  `Book.lua` saves (`kind`, `what`, `unit`, `when = { { word, no, value } }`, `often`) and cleaned as a saved one is
  (`Book.FromSteps`). `owner`: nil every character's, `"class"` this character's class's, `"character"` its own. One of that
  name and owner already there is left as it is (a setup addon, a script). `Macros.Set(name, body, owner)` makes that macro anew from a body as Add takes it, its number, picture, keys and places kept, its button taking it at once or after a fight (Saneroki, 2026-11-04: a potion macro kept on the best potion held). `Macros.PlaceOn(name, place)` puts the macro of
  that name this character uses (its own or its class's before a general one) on a bar button by its place
  (`"MultiBar5Button4"`, `"ActionButton1:1"`, a druid's Bar 9 on Bar 6 `"MultiBar5Button4:9"`), `Macros.TakeOff(place)` takes it off, `Macros.On(place)` names the one there
  (Saneroki, 2026-11-04: a setup addon puts his macros on his keys and changes them as spells are learned).
- **Standing down** (`Macros.GiveBack`, from Combat's): no key and no bar button of ours, the game's macro window back.
- **Tried in the game:** one step a press, 5,000 attributes on one button, a button over a bar slot with paging and left
  and right click, on Retail. A plain macro stopped at its first `/cast` line on Retail 12.1.5, cast or refused, so a step should
  hold one `/cast` (the check says so).

## Files
| File | What it does |
| --- | --- |
| `Macros.lua` | Its table (`ns.Macros`), words, the plain button (`Macros.Button`), its start and standing down |
| `Conditions.lua` | The game's conditions in plain words, and Sane Macros' own (Once per target); the words the game knows |
| `Book.lua` | Macros and steps as data: cleaned, made, copied, moved, deleted; keys and places looked up |
| `Write.lua` | A macro as lines, conditions and turns; a step cast once a target as the game's cast sequence |
| `Check.lua` | What would not work as it stands |
| `Press.lua` | The hub, the snippet, loading a macro, the turn that comes next, a step's picture |
| `Face.lua` | Our button over a bar button: picture, swirl, dimming, key; something dropped on it, the macro dragged off it |
| `Reach.lua` | Keys and bar buttons, the state drivers, what is given back |
| `Place.lua` | Choosing a bar button with the mouse: unseen squares, the picture at the mouse, the gold frame |
| `Icons.lua` | The picture window: the game's icons by group, searched, a macro's picture chosen |
| `Picker.lua` | The list behind the + |
| `Steps.lua` | The steps in a list: choosing, dragging, dropping |
| `Detail.lua` | The chosen step's settings |
| `Editor.lua` | The window, the macros' list as squares (yours, then the game's marked W), its head, the key's capture, the game's window |
