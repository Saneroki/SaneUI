# Sane UI: Combat

**Status:** its window and full screen built: docked at the bottom middle, the bottom edge's middle half fills the screen with your talents and spellbook; quest marks beside nameplates · **Since:** 2026-10-16 · **Addon:** `SaneUI_Combat` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for everything about the fight: your own frame, your target's (and its target's), your
focus and your pet, the party and the raid, your buffs and debuffs, the nameplates, and what goes with
them (cast bars, totems, bosses). Each part, once built, gives the game's own frame back when it fails.
The plan is in `Doc/ideas/Combat.md`.

Built so far: its window, docked in the screen's bottom middle. Push the mouse against the middle half of
the bottom edge and it fills the screen with your talents and your spellbook side by side, as panels; push
there again, or Esc, and it goes back. With a talent planner Sane UI knows installed, the planner's window
is the Talents panel.

## How to use
- **Switch it on or off:** tick or untick *Combat* under *Sane UI* in the game's addon list.
- **The full screen:** push the mouse against the bottom edge of the screen anywhere in its middle half
  (a quarter of the screen's width either side of the middle). Push there again, or press Esc, to go back.
  Not in Edit Mode, and not with *Can expand to fullscreen* off (*Sane UI > Combat > Expand window*).
- **What it holds:** the *Talents* panel at the left, the *Spellbook* panel at the right, each as wide as
  its share of what both hold.
  - The game's talents and spellbook are one window that shows one of them at a time: it stands in the
    panel of what it shows (the talents, or the spellbook).
  - With a talent planner Sane UI knows installed, its window is the Talents panel: it opens with the full
    screen and closes when it goes, and the game's window stands in the Spellbook panel, whatever it shows.
- **Opening the game's window:** its keys and micro menu buttons work as always and bring the full screen
  with it. An empty panel says the game's key for it and has an *Open* button that clicks the game's own
  micro menu button for you. In a fight the button is away (the game allows such a button to change only
  out of a fight); the key still works, and the button is back once the fight is over.
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
  length follows `DISPLAY_SIZE_CHANGED` and `UI_SCALE_CHANGED`). `filled` lays the board out for the full
  screen as the motion begins (`Board.Show(..., moving)`), `docked` once it stands; going back,
  `Board.Hide`.
- **The board** (`Board.lua`): the room is the screen under the title bar (`Core.Window.BAR`), in UIParent's
  units. `Board.Layout` cuts it into two panels with `Board.MARGIN` round them and `Board.GAP` between, each
  as wide as its share of the widths both want (what it holds at its own scale, else the game's sizes for an
  empty one, `Board.TALENTS`, `Board.SPELLBOOK`: Camelot's `talentsWidth`/`talentsHeight`,
  `spellBookMinimizedWidth`/`spellBookHeight`).
- **Seated, not taken** (Core's `Seat.lua`): a window in a panel keeps its parent; only its place, scale and
  layer are lent (`Core.Lend`), so it stands over the full window (`HIGH`, at least `Board.LEVEL` above it)
  in its panel's middle, as large as fits and never larger than it is. Hooks after its `SetPoint` and
  `SetScale` put it back when the game places or scales it anew (the panel manager); a new size (another
  tab, made small) lays the board out again; closed, it is given back exactly (`Core.Lent(frame)` is false
  again) and its panel shows its plate. A protected window in a fight is left as it is.
- **The game's window** (`PlayerSpellsFrame`, `Blizzard_PlayerSpells`, loaded on demand: followed from
  `EventUtil.ContinueOnAddOnLoaded`): hooks after its `OnShow` (any way it opens: the full screen comes, or it
  takes its panel) and after its tabs' `OnShow` (`SpecFrame`, `TalentsFrame`, `SpellBookFrame`: another
  panel). Our code never shows or hides it: its `OnShow` and `OnHide` show the action bars' grids (protected
  buttons), and a panel shown by addon code runs the game's window manager tainted
  (`Doc/guides/addon-standards.md`, *Known traps*). Abilities leaves its own placing of the window alone
  while it is lent (`Core.Lent`, `src/Abilities/Book/Window.lua`).
- **The open buttons:** one per panel of the game's window, `SecureActionButtonTemplate` with
  `UIPanelButtonTemplate`'s look, `type = "click"`, `clickbutton` the game's `TalentMicroButton` or
  `SpellbookMicroButton`, `useOnKeyDown = false` (on the button's release). On UIParent in the strata
  `DIALOG`, not in our window: a protected child would lock the full window in a fight (`window:Locked()`).
  Made, placed, shown and hidden out of a fight only; hidden at `PLAYER_REGEN_DISABLED`, back after
  `PLAYER_REGEN_ENABLED`.
- **The planner** (Core's `Neighbours.lua`, the one file that names the addons Sane UI knows):
  `Core.Neighbours.Window("talents")` gives a handle while that addon is loaded; Combat opens and closes the
  window by its own functions, follows its opening by a hook after its opening function (any way it opens,
  the full screen comes) and seats it as above. Closed while the full screen stands, its panel shows our own
  *Open* button.
- **Quest marks** (`QuestMarks.lua`): on `NAME_PLATE_UNIT_ADDED` a frame of ours on the plate the game gives
  (`C_NamePlate.GetNamePlateForUnit`: none for a forbidden plate; none for players), left of its health bar
  where it has one (its fields read with `rawget`, never written), one per plate, kept while it shows.
  `QuestMarks.Read`: `C_QuestLog.UnitIsRelatedToActiveQuest` first, then the tooltip data's lines of the kind
  `QuestObjective` (`C_TooltipInfo.GetUnit`): the first not `completed` and not full ("8/8") is the mark, the
  sword (`Interface\CURSOR\Attack`) where its text names the creature, else the sack
  (`Interface\CURSOR\LootAll`), the count left of it. A secret value (a fight) leaves the mark as it was.
  Looked at again on `QUEST_LOG_UPDATE` and `UNIT_QUEST_LOG_CHANGED`, once a frame (`Core.Later`).
- **Standing down** (`ns.GiveBack`): everything seated is given back, the planner closes, the window hides;
  the open buttons hide now or once the fight is over; the quest marks hide.
- Tests: `dev/tests/combat.lua`.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Combat.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Combat.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Window.lua` | Its window: docked at the bottom middle, filling the screen from the bottom edge's middle half |
| `Board.lua` | The full screen's panels: the talents and the spellbook, the windows that hold them seated there, the open buttons |
| `QuestMarks.lua` | A mark beside a creature's nameplate while it belongs to an objective of your quests still to do |

## History
- **2026-10-16:** set up as a module of its own, for party, raid, buffs, unit frames, nameplates and pets.
- **2026-10-20:** its window, docked at the bottom middle (Saneroki); the bottom edge's middle half fills the
  screen with the talents and the spellbook as panels; a talent planner Sane UI knows as the Talents panel.
- **2026-10-20:** quest marks beside nameplates (Saneroki), from the game's own tooltip data.
