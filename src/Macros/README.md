# Sane UI: Macros

**Status:** built · **Since:** 2026-11-02 · **Addon:** `SaneUI_Macros` · **Game:** WoW: Forever and Retail · **Tests:**
`dev/tests/macros.lua`; the lab's scene `macros`.

## TL;DR
*Sane Macros* stands in for the game's macro window. A macro is a list of steps, as long as you like, and there are no
slots to run out of. One step is what a normal macro is; several make a sequence that goes on with every press. Every
condition of the game's macros is an option with its explanation, behind a **+** button. A macro goes on a key or on one
of your normal action bar buttons. The macros are your account's, on every character.

## How to use
- **Open it:** `/macro`, the game menu's *Macros*, `/sane macros`, or the key *Open or close Sane Macros* (Sane UI, in
  the game's key bindings). The first button in its title bar goes to the game's own macro window, and that window has a
  button back. The game's macros stay as they are.
- **New macro:** *New* makes an empty one, or takes one over from the game's macros as macro text. *Copy*, *Delete*.
- **Its key:** *Set key*, then press the key, with Shift, Ctrl or Alt if you like, or a mouse's extra button. Esc leaves it
  as it was; a right click takes it away. For this character, and it stays out of the game's own key settings.
- **Its bar button:** *Place on bar*, or drag the macro's picture, and choose a button on your action bars. It works and
  looks like a normal button, with that button's keys, on that page of Bar 1. What the button holds stays underneath and is
  back when the macro is taken off (a right click on the same button in the window). One button a macro, for this character.
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
- **Back to the first step after a fight:** a tick, on at first.
- **The checks:** a red **!** on a macro or a step says something would not work as it stands; the mouse on it says what. The
  switch *Check macros*.
- **What it cannot do:** the game keeps rage, cooldowns and auras from anything that decides a press. So a step is never
  skipped because a spell is on cooldown. The game refuses it, that press is spent, and the next press goes on: keep pressing
  and what can be cast gets its turn. "If no Rend on the target, cast Rend" is not possible in any addon.
- **Game macros to bars:** nothing here touches them. Sane Macros needs no macro slots.

## Technical details
- **The press** (`Press.lua`). Every macro with a key or a bar button has a hub, a secure button holding its turns in
  numbered attributes (`m<n>` the line, `c<n>` the condition). A key clicks the hub. The snippet, wrapped on `OnClick`, runs before the
  button's action, in a fight too: it walks from where the macro stands (`at`, or 1 with `top`) past every turn whose condition
  fails, by `SecureCmdOptionParse`, sets the first that holds as the button's `macrotext`, and moves on. Nothing true: no text, and
  the game runs nothing. A press is one edge only (`Press.Ready`, the game's key-down setting): the snippet runs on every edge
  registered. Numbered attributes keep a snippet's text free of the game's bans (no closure's keyword, no brace) whatever a step says.
- **What secure code can do.** On a press it may rewrite its own button in a fight. It cannot read rage, cooldowns, auras or
  the clock, and addon code cannot write to it then. An addon's change waits for `Core.AfterCombat`.
- **Written out** (`Write.lua`). Plain text, testable alone. How often: each turn of a step gets a mark at its share of a
  round, half a share in, and the marks are read in order.
- **A bar button** (`Face.lua`, `Reach.lua`). Our own secure button in the bar's frame, anchored to the game's button, so it
  goes with the bar at rest and in Edit Mode's moves, and its own press reads the same hub (`GetFrameRef("hub")`). The game's
  button is never touched. A state driver per place says `ours` while the bar shows that button; a snippet then shows ours
  and takes the button's keys by override bindings, and gives them back on another page of Bar 1, in a vehicle or on a bar the
  game puts in place of yours, in a fight too. Keys read from the game's bindings; `UPDATE_BINDINGS` takes a change.
- **What shows.** The picture of the turn the next press would take (`Press.Next`, the game's parser answers plainly in a fight),
  its cooldown by the game's duration object (a hidden value is taken as it is), dimmed by `C_Spell.IsSpellUsable` (plain in a
  fight). `isActive` of a cooldown is true during the GCD too.
- **The list of conditions** (`Conditions.lua`). The game takes a word it does not know as true, without a sound, and a word
  that is always true cannot be told from an unknown one by asking it. So the words stand here, for the + and for the check of
  macro text.
- **The checks** (`Check.lua`) run at an edit, on opening, and at `SPELLS_CHANGED` and `BAG_UPDATE_DELAYED` while the window shows.
  They say what can be known ahead; a clean check does not mean a spell is ready.
- **Saved.** Macros in `Core.Store` (the account, every profile); keys and places in `Core.Character`.
- **The game's window** is held by Core (`native.hold`, `Blizzard_MacroUI`), so the frame is made at login, empty; what it
  holds is made when first shown. A hub is made only for a macro with a key or a place.
- **Standing down** (`ns.GiveBack`): no key and no bar button of ours, the game's macro window back.
- **Tried in the game:** one step a press, 5,000 attributes on one button, a button over a bar slot with paging and left
  and right click, on Retail. A plain macro stopped at its first `/cast` line on Retail 12.1.5, cast or refused, so a step should
  hold one `/cast` (the check says so).

## Files
| File | What it does |
| --- | --- |
| `Macros.lua` | The module's table, words, switches, the plain button (`ns.Button`), standing down |
| `Conditions.lua` | The game's conditions in plain words; the words the game knows |
| `Book.lua` | Macros and steps as data: cleaned, made, copied, moved, deleted; keys and places looked up |
| `Write.lua` | A macro as lines, conditions and turns |
| `Check.lua` | What would not work as it stands |
| `Press.lua` | The hub, the snippet, loading a macro, the turn that comes next, a step's picture |
| `Face.lua` | Our button over a bar button: picture, swirl, dimming, key |
| `Reach.lua` | Keys and bar buttons, the state drivers, what is given back |
| `Place.lua` | Choosing a bar button with the mouse |
| `Picker.lua` | The list behind the + |
| `Steps.lua` | The steps in a list: choosing, dragging, dropping |
| `Detail.lua` | The chosen step's settings |
| `Editor.lua` | The window, the macros' list, its head, the key's capture |
| `Bindings.xml` | The window's key |
