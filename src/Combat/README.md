# Sane UI: Combat

**Status:** its window and full screen built: docked at the bottom middle, the bottom edge's middle half fills the screen with your talents and spellbook on Core's board; quest marks beside nameplates · **Since:** 2026-10-16 · **Addon:** `SaneUI_Combat` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for everything about the fight: your own frame, your target's (and its target's), your
focus and your pet, the party and the raid, your buffs and debuffs, the nameplates, and what goes with
them (cast bars, totems, bosses). Each part, once built, gives the game's own frame back when it fails.
The plan is in `Doc/ideas/Combat.md`.

Built so far: its window, docked in the screen's bottom middle. Push the mouse against the middle half of
the bottom edge and it fills the screen with your talents and your spellbook, as windows on Core's board
that you arrange; push there again, or Esc, and it goes back. With a talent planner Sane UI knows installed,
the planner's window is the Talents panel.

## How to use
- **Switch it on or off:** tick or untick *Combat* under *Sane UI* in the game's addon list.
- **The full screen:** push the mouse against the bottom edge of the screen anywhere in its middle half
  (a quarter of the screen's width either side of the middle). Push there again, or press Esc, to go back.
  Not in Edit Mode, and not with *Can expand to fullscreen* off (*Sane UI > Combat > Expand window*).
- **The game's own windows:** the full screen's dropdown *Classic windows* has *Spellbook* and *Talents*: the
  full screen goes back and the game's key for them is said (our code does not open the game's spellbook).
  The game's spellbook has the button *Sane UI* left of its sizing button: the game's closes and this full
  screen comes.
- **What it holds:** two windows on Core's board, at first the *Talents* at the left and the *Spellbook* at
  the right, each as wide as its share of what both hold.
  - The game's talents and spellbook are one window that shows one of them at a time: it stands in the
    window of what it shows (the talents, or the spellbook), as large as fits there, never larger than it is.
  - With a talent planner Sane UI knows installed, its window is the *Talents*: it opens with the full
    screen and closes when it goes, and the game's window stands in the *Spellbook*, whatever it shows.
- **Arranging them:** as on every board of Sane UI's. Drag a window's head onto the other to swap them or put
  it above, below or beside it; drag the gap between them to share the room anew; the X takes a window off,
  the dropdown *Windows* puts it back. Layouts are tabs after the title: *+* makes one, a right click
  renames it, resets the first or deletes another. With its own window taken off, the game's window stands
  in the other one, or in the middle of the screen: it is never left behind the full screen.
- **Opening the game's window:** whatever opens it (its keys, its micro menu buttons, a link) brings the full
  screen with it, and it stands in its window there. One that is closed is a click away: its window says so,
  and a click anywhere in it opens the game's window right there (it clicks the game's own micro menu button
  for you). Sane UI cannot open it by itself (*Technical details*). In a fight the click is away (the game
  lets it change only out of a fight); the key still works, and the click is back once the fight is over.
  Before the game gives you talents, the *Talents* says from which level.
- **Going back:** Esc closes the game's window and the planner with the full screen. The bottom edge
  closes the planner and leaves the game's window open where the game puts it: Sane UI never opens or
  closes the game's window itself (*Technical details*).
- **Quest marks beside nameplates:** a creature that belongs to a quest in your log shows a small mark left of
  its nameplate while an objective of it is still to do: a sword to kill it, a sack to loot it, with the count
  still open ("3/8"). It goes once the objective is done. As the game says it in the creature's tooltip; a
  creature the game says nothing about has none. *Quest marks on nameplates* switches it off.
- **Settings:** *Sane UI > Combat*: *Quest marks on nameplates*, the section *Expand window* (whether it fills
  the screen, its kind of motion, the background's opacity and texture) and *Window corners*.

## Technical details
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked at `BOTTOM` at first,
  `Window.WIDTH` x `Window.HEIGHT`, not sizable, see-through and empty while small (no mouse); in Edit Mode
  its box, to be docked elsewhere. Core's option `strip = Window.STRIP` (0.5): the strip that fills the
  screen is half the screen's side, in its middle, whatever the window's width (Core's `Edge.lua`; its
  length follows `DISPLAY_SIZE_CHANGED` and `UI_SCALE_CHANGED`). `docked`, once it stands full, lays the
  board out (`Board.Show`); `filled` on its way back, and `docked` at rest, take it away (`Board.Hide`).
- **The board** (`Board.lua`): Core's (`Core.Board.New`, kept in `store.board`: layouts behind tabs, a panel
  per window with its head, X and body, the dropdown *Windows*). Combat's windows: `talents` and `spellbook`,
  each at least `Board.LEAST` of the game's size there. The first layout (`default`): side by side, the shares
  the widths each wants (what it holds at its own scale, else the game's size for an empty one,
  `Board.TALENTS`, `Board.SPELLBOOK`: Camelot's `talentsWidth`/`talentsHeight`,
  `spellBookMinimizedWidth`/`spellBookHeight`), made anew at each laying out until the layout is changed.
  Laid out anew (`Window.Reboard`, a frame later by `Core.Later`) when a layout changes, a window opens or
  closes, takes another size or another tab, and when a fight begins and ends.
- **Seated, not taken** (Core's `Seat.lua`): a window in a panel's body keeps its parent; only its place,
  scale and layer are lent (`Core.Lend`), so it stands over the full window (its strata, at least
  `Board.LEVEL` above what it holds) in the body's middle, as large as fits and never larger than it is.
  Hooks after its `SetPoint` and `SetScale` put it back when the game places or scales it anew (the panel
  manager); a new size (another tab, made small) lays the board out again; closed, it is given back exactly
  (`Core.Lent(frame)` is false again) and its panel says what opens it. A window whose own panel is not in the
  layout stands in the other one while that has nothing of its own, else in the middle of the whole board.
  A protected window in a fight is left as it is.
- **The game's window** (`PlayerSpellsFrame`, `Blizzard_PlayerSpells`, loaded on demand: followed from
  `EventUtil.ContinueOnAddOnLoaded`): hooks after its `OnShow` (any way it opens: the full screen comes, or it
  takes its panel) and after its tabs' `OnShow` (`SpecFrame`, `TalentsFrame`, `SpellBookFrame`: another
  panel). Our code never shows, hides or loads it, so the full screen cannot bring it by itself: opening it
  (`TogglePlayerSpellsFrame`, `ShowUIPanel`) from our code would run, tainted, the panel manager
  (`UIParentPanelManager.lua`), its tab and minimizing fields (`TrySetTab`, `SetTab`), its `OnShow`
  (`MultiActionBar_ShowAllGrids`: every action bar's `showAllButtons` and its protected buttons' `SetShown`,
  `Blizzard_ActionBar/Shared/ActionBar.lua`) and its spellbook's `OnShow` (`UpdateAllSpellData`: each entry's
  `slotIndex` and `spellBank`, which its click passes to `C_SpellBook.CastSpellBookItem`, a protected call:
  `SpellBook/Blizzard_SpellBookItem.lua`). The game's own later opening and closing, the grids and a spell
  clicked in the spellbook would then be refused (`Doc/guides/addon-standards.md`, *Taint*). Abilities leaves
  its own placing of the window alone while it is lent (`Core.Lent`, `src/Abilities/Book/Window.lua`).
- **The clicks:** the body of an empty panel of the game's window is a button of its own,
  `SecureActionButtonTemplate`, `type = "click"`, `clickbutton` the game's `TalentMicroButton` or
  `SpellbookMicroButton`, `useOnKeyDown = false` (on the button's release), lit under the mouse
  (`Board.LIGHT`): a click is the player's own, and the game's code opens its window as its own. On UIParent,
  in the full window's strata `Board.LEVEL` above what it holds, over the panel's body, not in our window: a
  protected child would lock the full window in a fight (`window:Locked()`). Made, placed, shown and hidden
  out of a fight only; hidden at `PLAYER_REGEN_DISABLED`, back after `PLAYER_REGEN_ENABLED`. None while the
  game's micro menu button is off (talents before their level: the panel says from which, its `minLevel`).
- **The planner** (Core's `Neighbours.lua`, the one file that names the addons Sane UI knows):
  `Core.Neighbours.Window("talents")` gives a handle while that addon is loaded; Combat opens it by its own
  function once the full screen stands with a layout that has the Talents panel, closes it when the full
  screen goes, follows its opening by a hook after its opening function (any way it opens, the full screen
  comes) and seats it as above. Closed while the full screen stands, its panel's body is a click of ours that
  opens it again.
- **Quest marks** (`QuestMarks.lua`): on `NAME_PLATE_UNIT_ADDED` a frame of ours on the plate the game gives
  (`C_NamePlate.GetNamePlateForUnit`: none for a forbidden plate; none for players), left of its health bar
  where it has one (its fields read with `rawget`, never written), one per plate, kept while it shows.
  `QuestMarks.Read`: `C_QuestLog.UnitIsRelatedToActiveQuest` first, then the tooltip data's lines of the kind
  `QuestObjective` (`C_TooltipInfo.GetUnit`): the first not `completed` and not full ("8/8") is the mark, the
  sword (`Interface\CURSOR\Attack`) where its text names the creature, else the sack
  (`Interface\CURSOR\LootAll`), the count left of it. A secret value (a fight) leaves the mark as it was.
  Looked at again on `QUEST_LOG_UPDATE` and `UNIT_QUEST_LOG_CHANGED`, once a frame (`Core.Later`).
- **Standing down** (`ns.GiveBack`): everything seated is given back, the planner closes, the board and the
  window hide; the clicks hide now or once the fight is over; the quest marks hide.
- Tests: `dev/tests/combat.lua`.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Combat.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Combat.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Window.lua` | Its window: docked at the bottom middle, filling the screen from the bottom edge's middle half; full, Core's board |
| `Board.lua` | The full screen's windows on Core's board: the talents and the spellbook, the windows that hold them seated there, the clicks of an empty one |
| `QuestMarks.lua` | A mark beside a creature's nameplate while it belongs to an objective of your quests still to do |

## History
- **2026-10-16:** set up as a module of its own, for party, raid, buffs, unit frames, nameplates and pets.
- **2026-10-20:** its window, docked at the bottom middle (Saneroki); the bottom edge's middle half fills the
  screen with the talents and the spellbook as panels; a talent planner Sane UI knows as the Talents panel.
- **2026-10-20:** quest marks beside nameplates (Saneroki), from the game's own tooltip data.
- **2026-10-20:** the full screen on Core's board (Saneroki): layouts behind tabs, the windows arranged as on
  every board; an empty window of the game's opens with a click anywhere in it instead of an *Open* button.
