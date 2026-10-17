# Docked windows: the screen layout

Planning notes for how Sane UI's own windows share the screen, built on Core's docking window system:
what Saneroki has decided (2026-10-16), each section marked *in Core* where it is built, *plan* where not.
How it is built, its states, rules and the recipe for a module's window: [the window system
guide](../guides/windows.md) (reviewed 2026-10-16; its section *Not built yet* orders what is left).

## What Core does today

Core's window system (`Core.Window.New`, `Dock.lua`, `Edge.lua`, see `src/Core/README.md`):

- **Nine dock zones:** the four corners, the middle of each edge (top, bottom, left, right), and the
  middle of the screen.
- **Full screen from the edge:** a docked window made with `edge` fills the whole screen when the mouse is
  pushed against its screen edge (docked in a corner: into that corner), and goes back when pushed again.
- **Moving and sizing:** in Blizzard's Edit Mode; a window with a title bar also moves by it at any time.
- **Since 2026-10-17:** a first place in a zone (`first.dock`), Esc by one stand-in for all of Sane UI,
  tabs in the game's style, a click bringing a panel to the front, the holder (the game's window out of
  sight while ours is chosen), and in Edit Mode a window chosen by a click on its box, with its dialog
  *Reset To Default Position* and Edit Mode's grid.

The Chat window uses all of this; the Navigation window is planned on it (`Doc/ideas/Navigation.md`).

## Nine places

The screen has **nine places** (Saneroki, 2026-10-16; in Core): eight at its edges, three at the top, one on
each side, three at the bottom, and the middle.

```
TOPLEFT        TOP          TOPRIGHT
LEFT          (CENTER)      RIGHT
BOTTOMLEFT     BOTTOM       BOTTOMRIGHT
```

Plus the **middle of the screen** (`CENTER`, Saneroki 2026-10-16), below.

The quarter places along the top and the bottom are gone (Core's `TOP1`, `TOP3`, `BOTTOM1`, `BOTTOM3`);
the middle ones are now Core's `TOP` and `BOTTOM` (were `TOP2`, `BOTTOM2`). A window still saved in an
old place needs nothing: Core's `Window` ignores a zone it does not know and puts the window at its
kept coordinates (and Sane UI is not given out yet, so nobody else has such a saved place).

Each place at an edge is both a dock zone and a **trigger zone** for full screen; the middle has no edge to
push against (its window fills the screen by its maximize button).

**A place holds one window at a time** (Saneroki, 2026-10-16; in Core, `Dock.lua`): while a window is docked
there and shown, the place takes no other. Dragged there (Edit Mode, or a title bar), another window gets no
shape and, let go, stays free where it was let go. A window that opens while its kept place is taken stands
free that time, clear of the window there: at its kept spot, or beside the place, a little down and aside
from each window already there (in Core, 2026-10-17); it docks there again the next time the place is
free. A window that is not
shown holds nothing, so the talk windows (vendor, trainer, auction house, bank), which are never open
together, share the middle.

## The middle, and windows not docked (Saneroki, 2026-10-16; in Core)

- **A dock place in the middle of the screen** (Core's zone `CENTER`), for the windows the player talks
  to: trader, auction house, trainer, vendor. The modules fill them and keep their place and dock, as
  every window's (Core's `Window` keeps `place` and `dock` in the module's settings).
- **Buttons in the title bar's right end** (below): **[the game's own window] [maximize / minimize]
  [X close]**. Maximize fills the screen as a docked window's edge does, minimize brings it back; X closes
  it (the module says what closing means).
- **Ours or the game's, never both** (Saneroki, 2026-10-16): our window does not replace the game's. Each
  window is set to one of the two, that choice is kept, and the player sees only that one. Set to Sane UI,
  ours opens wherever the game would open its own, and the game's stays out of sight (Core sees to it:
  *The game's own triggers* below). Set to the game's, ours is hidden and the game's window works as
  always, untouched, with one Sane UI button on its title bar next to its close button to switch back. The
  first button of our title bar switches to the game's. A window that stands for no Blizzard window has no
  such button.
- Done in Core (`Dock.lua`, `Window.lua`: options `native`, `close`, `window:Attach()`); used by Social (its
  game's window is the game's chat) and planned for Economy (`Doc/ideas/Economy.md`).

## Title bars (Saneroki, 2026-10-16; in Core)

- **Per kind of window.** A window has a title bar if its kind has one (Core's `titleBar`): a vendor's,
  a trainer's, a spellbook. The small chat (see-through by design) has none. Unit frames, nameplates,
  buffs and action bars are no windows at all (below).
- **What it holds:** the window's name at the left, the three buttons at the right.
- **A ? before them** (Saneroki, 2026-10-16; to come with the Onboarding module, `Doc/ideas/Onboarding.md`):
  help with the window, over it. Only on our window (the Sane UI view), never on the game's own window;
  only where the window has help.
- **It moves the window, at any time:** a drag anywhere on it moves a small (not full screen) window, also
  outside Edit Mode. A window docked at a screen edge is Edit Mode's to move; a window may override that
  (`dragDocked`). Outside Edit Mode a title bar's drag docks only in the middle (or not at all), so a
  window cannot end at an edge where only Edit Mode moves it again. Sizing stays in Edit Mode.
- **It is a search bar:** a click on its left side (a magnifier before the name, where the window can be
  searched) opens a search box over the whole bar but the buttons, the cursor in it. Typing searches the
  window's content forgivingly (Core's `Fuzzy.lua`: the whole text first, then its beginning, a word's
  beginning, the first letters of its words such as *tb* for *Thunder Bluff*, a piece inside a word, and
  last letters spread out in their order; every word typed must match). Esc, or leaving it empty, closes it
  and the name is back.
- **Full screen** has the same title bar at its top: the name, the search, the dropdown *Classic windows*
  and the buttons (minimize to come back). Done for Social: the small chat has no title bar, the full
  screen has one, and its search filters the messages (their text, the speaker's and the chat's name).

## Full screen views (Saneroki, 2026-10-16; plan)

- **A full screen is a collected, predefined view of several windows' views**, laid out by its module:
  Social's full screen holds its chat, friends list, guild and group finder side by side; Navigation's,
  the map and the quest log. Today Core grows one window to full screen (`Edge.lua`) and the module lays
  out what it holds; a view that holds several windows' views is still to come in Core.
- **How: a board per module** (proposed in the review, Saneroki agreed 2026-10-16): one full screen frame per
  module (its background, title bar, dropdown *Classic windows*, Esc) and a layout that gives each of the
  module's windows its rectangle there. Going full screen, each window moves from its own place to its
  rectangle with the same motion; the ones not open come in; the search goes to every window; back, each
  returns to its place. What a window holds stays its own, so it looks the same alone and on the board
  (`Core.Board`, the guide's section 8).

## Kinds of window (Saneroki, 2026-10-16; in Core)

- **Windows are panels like the game's own:** the chat, the spellbook, the talents, a vendor, the bank, the
  bags. Each is made with its kind (Core's `kind`), and the windows of one kind behave alike:
  - **screen:** on the screen all the time (the chat, later the minimap): no title bar while small,
    see-through, docked at an edge, full screen from it; Esc only brings it back from full screen.
  - **panel:** opened and closed by the player (the spellbook, the talents, the guild, the bags): title bar,
    skin, Esc closes it.
  - **talk:** an NPC's (vendor, trainer, auction house, bank): as a panel, at first in the middle; closing
    it ends the talk.
- **What the Combat module shows is no window:** nameplates, unit frames, buffs, action bars. The Combat
  module handles them its own way, not as Core's windows.

## The game's own triggers (Saneroki, 2026-10-16; in Core but the secure switch)

- **Every window is handled the same way, by Core's system.** What the game opens by a key, a button of
  its micro menu, a slash command or an NPC (the spellbook, the guild, the friends list, a vendor) opens
  ours instead, as the player last left it.
- **Each window remembers** its place, size and dock, whether it was **maximized or small**, and whether
  the player chose **the game's own window or ours**, and acts on that when the game asks for the window.
  In Core: `window:Remember(what, value)` (with the place in the module's settings), `window:Native(on)`
  (the toggle buttons), `window:Open()` (the game asked: the game's own window if that was chosen, else
  ours, full screen again if it was left so). Done in Core; Social's switch *Chat window* opens its window
  by `Open`.
- **Core keeps the game's window out of sight** (Saneroki, 2026-10-16: the window system handles it, one way
  for every window), by Economy's holder made Core's (`Doc/ideas/Economy.md`, *Hidden, not closed*): set to
  Sane UI, the game's window is a child of a hidden frame of Core's, set while it is closed. The game then
  opens and closes it as always, by its key, its micro menu button, a link, an NPC, but unseen: its `OnShow`
  and `OnHide` do not run, so it neither ends a talk nor touches anything. Core follows (hooks after its own
  `Show` and `Hide`) and opens and closes ours. No key and no button of the game's is taken over, nothing of
  Blizzard's replaced. In Core since 2026-10-17 (`Holder.lua`, a window's `native.hold`); the game's chat is
  never closed, so Social keeps it out of sight its own way.
- **Switching while it is open:** to the game's, ours closes and the game's window is given back to its
  parent and comes into sight. That runs its `OnShow` from our code: fine for most windows; not for the
  spellbook (its `OnShow` changes the action bars, protected) and the map (an emote). Those are given back
  by a secure click on the game's own button (to come; until then the switch closes the game's window
  unseen, `native.unseen`, and it opens normally at its key's next press). To ours, the game's window is made
  tiny and clear until it closes (a hidden parent would end a talk), then held again. The guide (section 7)
  has the rules and the facts.
- **The spellbook (Saneroki):** the Abilities module changes the game's own spellbook today. It goes back to
  the game's spellbook as it is, untouched, and Abilities gets a spellbook window of its own on Core's
  window system (title bar, buttons, search, Edit Mode, the game's key opening it), with the functions it
  has today.

## Full screen only where a window is docked

A trigger zone does something only while a window is docked there: a left click on it fills the screen
with that window (below), another brings it back. A place with no window docked does nothing; there are no
empty hot corners. (This is how `Edge.lua` already works, per window.) A window in the middle or not docked
fills the screen by its title bar's maximize button (in Core).

## Click to expand, not hover

- **A left click expands.** The window fills the screen only when the mouse is on the trigger area and the
  left button is clicked. The trigger area is today's: the strip along the screen edge the window is docked
  to, or the square in its corner, where the mouse stops when it is pushed against the edge.
- **Left click is the default.** Right and middle click are kept free for now; they may get other
  functions later (per window).
- **Hover does not expand**, unless a window is designed that way.
- **Setting *Click required to expand window*:** only a toggle. Ticked: a left click on the trigger area
  is required. Not ticked: hover is enough (reaching the trigger area with the mouse, today's behaviour).
  Ticked by default. It is in two places, a plain toggle in both:
  - **Core: section *Hotcorners*** in Sane UI's own settings: for the windows of all modules. Changing it
    there sets every module's toggle to the same.
  - **Each module:** the same toggle in its settings (section *Expand window*, under *Can expand to
    fullscreen*), for that module's windows only; it overrides Core's toggle for them, until Core's is
    changed again. Each module handles hover and click only for its own windows. A module whose window is
    designed for hover has it not ticked by default.
  - The tooltips say so. Core's, for example: *Ticked, a hot corner expands the window docked there only
    when you click it; not ticked, moving the mouse there is enough. For the windows of all modules; each
    module can override it on its own page, under Expand window.* A module's: *For this module's windows
    only; overrides Sane UI > Hotcorners.*

Notes for building it: today `Edge.lua`'s strip takes only the mouse's motion (`SetMouseMotionEnabled`,
`OnEnter`), so a click there goes into the game. For the click it also takes the left button
(`SetMouseClickEnabled`, `OnMouseUp` with `LeftButton`) and lets the others through
(`SetPassThroughButtons`) until they get a function; it does so only while the window is docked and may
expand. The strip is two physical pixels wide (the corner square four), so it takes almost nothing of the
game's screen. These calls are fine on our own frames, which are not protected.

## Classic windows (Saneroki, 2026-10-16)

- **Every full screen view has a dropdown *Classic windows*** (Core's, in the full screen's title bar left
  of its buttons, `Edge.lua`). It lists the Blizzard windows that window stands for (the last column of the table
  below). One chosen, our window goes back to its small size in its zone and the Blizzard window comes
  instead. Done for Social (2026-10-16): *Chat* puts our chat window away (its switch *Chat window* off)
  and the game's own chat is back; *Friends list* opens the game's friends list.
- **Navigation's** full screen lists the map's: the **native minimap** and the **native map and quest
  log** window (one Blizzard window in this client).
- **Only a small window may be round.** A full screen view's background is always square, whatever the
  window's corner switches say; on its way to full screen it flattens from the small window's corners.

## Esc (Saneroki, 2026-10-16; in Core)

- **A panel or a talk window closes on Esc,** small or full, as the game's panels do; full, it is not made
  small first, so it opens full again next time (Core's `escape = "close"`: one stand-in of ours,
  `SaneUIEscape`, in `UISpecialFrames` for all of Sane UI, `Core.Escape`). Closing a talk window ends the talk
  (the module's `close`). In a fight a window holding protected frames closes once the fight is over.
- **A screen window** (the chat, the minimap) does not close on Esc; full, Esc brings it back to its size.

## Default places

| Place | Window | Views in it | Blizzard windows it stands for (to confirm) |
| --- | --- | --- | --- |
| Top left | Party and raid (tentative, "I think"; module **Combat**, `Doc/ideas/Combat.md`) | Party and raid | Party and raid frames (`Blizzard_CompactRaidFrames`, `Blizzard_RaidFrame`) |
| Top middle | Journal and progress (working name) | Journal, information, XP, reputation, honor, PvP info, library, journey | Adventure Guide with its Journeys (`Blizzard_EncounterJournal`), reputation, honor and PvP (`Blizzard_PVPUI`) |
| Top right | **Navigation** | Minimap; full screen: map and quest log | Minimap, world map and quest log |
| Left | to be decided | | |
| Right | to be decided | | |
| Bottom left | **Social** (was **Chat**) | Chat, more chat views, guild, group finder, friends list (`Doc/ideas/Social.md`) | Chat, Communities and guild, Group Finder, Friends list |
| Bottom middle | **Abilities** (was Spellbook) | Spellbook, action bars, talents, legacy | `Blizzard_PlayerSpells` (spellbook and talents), action bars, `Blizzard_LegacySystem` |
| Bottom right | Character and bags (working name) | Character sheet, bags | Character frame, bags |

Small, docked, the window shows its everyday part (the minimap, the chat); full screen it shows all its
views. A window's first place is its zone (Core's `first.dock`, 2026-10-17): Social starts docked bottom
left, a talk window in the middle. Bold names are modules that exist (Social, Abilities, Combat) or are planned (Navigation); the others have
no module yet.

## Edit Mode

Sane UI's windows work with Blizzard's Edit Mode the way Blizzard's own frames do, keeping to its
functions and the way it works.

- **Moving and resizing in Edit Mode.** Edit Mode is where the player arranges the screen: every window
  shows Edit Mode's blue box with its name, is dragged by it and docks where it is let go, and has its
  grip; the screen's edge does nothing then. *Done 2026-10-16* (Core's `EditMode.lua`, `Window.lua`).
  Outside Edit Mode only a window with a title bar moves, by that bar (*Title bars* above; Saneroki,
  2026-10-16), and nothing is sized. Still to do: the layouts, Save and Revert (below).
- **Kept in Edit Mode's layouts.** Edit Mode's profile system (its layouts: *Modern*, *Classic* and the
  player's own, for the account or one character) keeps the size and place of every Sane UI window too.
  Each layout has its own window places; switching the layout moves our windows along with Blizzard's
  frames.
- **Save and Revert as Blizzard's.** A move in Edit Mode counts as a change of the layout until *Save*.
  Leaving Edit Mode with changes not saved asks, as Blizzard does. In a preset layout (*Modern*,
  *Classic*), which cannot be changed, saving asks for a new layout, as Blizzard does; there our windows
  stand at their default places.
- **Revert puts the windows on their default position** (Saneroki). Note: Blizzard has two buttons for this.
  *Revert Changes* takes the layout back to its last save (`RevertAllChanges`: the layouts read again);
  for a window never saved in that layout that is its default place. *Reset To Default Position*, in the
  dialog of the frame selected, puts that one frame at its default place
  (`EditModeSystemMixin:ResetToDefaultPosition`). Both should do for our windows what they do for
  Blizzard's frames. *Reset To Default Position* is in Core (2026-10-17, `Selection.lua`): a click on a
  window's box in Edit Mode selects it (the box in Edit Mode's selected look) and Core's dialog names it,
  with that button. With Edit Mode's *Snap* on, a free window let go near a line of its grid lines up with
  it (the grid only read).

Notes for building it (from `references/`):

- Blizzard announces Edit Mode with `EventRegistry` callbacks `EditMode.Enter` and `EditMode.Exit`
  (`Blizzard_EditMode/Shared/EditModeManager.lua`); `EditModeManagerFrame:IsEditModeActive()` says
  whether it is open now (for a window made while it is open).
- Core's `Window` would show bar and grip on `EditMode.Enter` and hide them on `EditMode.Exit`, one place
  for every window of every module. Our windows only listen: they are not registered as Edit Mode systems
  in Blizzard's manager (that is Blizzard's secure list and would risk taint).
- Blizzard keeps the layouts on the server (`C_EditMode.SaveLayouts`), and only for its own frames (a
  fixed list of systems); an addon cannot add to them. So Core keeps our window places in Sane UI's own
  settings, one set per Edit Mode layout, and follows Blizzard (corrected in the review of 2026-10-16,
  facts in [the guide](../guides/windows.md), sections 8 and 9):
  - **Which layout:** a preset (*Modern*, *Classic*, their names are the game's language) by its number,
    the player's own by its type and name; a character's layout also by the character (the store is the
    account's, and two characters may each have a layout of the same name).
  - **Following it:** one hook after `EditModeManagerFrame:UpdateLayoutInfo`, through which every way to a
    layout passes (the login, switching, *Revert Changes*, a new or imported layout, the server's
    `EDIT_MODE_LAYOUTS_UPDATED`); `EventRegistry` `EditMode.SavedLayouts` for *Save*; hooks after
    `RenameLayout` and `DeleteLayout` (a renamed layout keeps its places, a deleted one's are dropped).
  - Sync already keeps the Edit Mode layout with Sane UI's settings (page *Profiles*), so the two travel
    together.
- **Save and Revert for our moves:** Blizzard's *Save* and *Revert Changes* buttons are enabled only while
  Blizzard's own frames have changes (its flag, set by `SetHasActiveChanges`). Core never calls that: the
  flag an addon's code writes is tainted, and Blizzard's own code reads it back. Our moves are held apart
  as Core's unsaved changes, and Core only enables the two buttons themselves (`SetEnabled`, a widget's
  state, no field of Blizzard's), again after each time Blizzard sets them (a hook after
  `SetHasActiveChanges`). Their own clicks then do the rest: *Save* (`SaveLayouts`, `EditMode.SavedLayouts`)
  keeps our places too, *Revert Changes* (`UpdateLayoutInfo`) drops ours. Leaving Edit Mode with only our
  changes unsaved asks in a dialog of Core's own in Blizzard's look, as Blizzard's asks for its frames
  (to build).
- Edit Mode can be opened in a fight: a window holding protected frames does not move then
  (`window:Locked()`).
- A window selected in Edit Mode gets a small dialog of Core's in the style of Blizzard's, with
  *Reset To Default Position*: our windows are not Blizzard systems, so Blizzard's dialog does not know
  them (built 2026-10-17).
- A layout shared as text (Edit Mode's export and import) carries only Blizzard's frames, not our windows.
- Resilience: if the client has no Edit Mode (or no event registry to hear it), `/sane arrange` gives Sane
  UI's windows the same mode (in Core, `EditMode.lua`), so they never get stuck.
- **Windows that are not open while Edit Mode is** (a talk window exists only at an NPC): to be arranged
  and sized there too, Core shows a preview of each in Edit Mode (plan; the guide, *Not built yet*).

## Open questions

- **Saneroki to decide (2026-10-16, from the window work):**
  - Edit Mode's layouts, *Save* and *Revert* for our windows (section *Edit Mode* above): next? Today a
    window's place is kept the moment it is let go.
  - The button for the game's own window is Blizzard's square button with its circling arrows (the game
    has no plain red button to put a sign on). Our own art in the red style instead?
  - The window look keeps Sane UI's dark fill and bronze trim (`Doc/guides/gui-development.md`: bronze is
    Sane UI's one colour of its own). One of Blizzard's own panel backgrounds (its dark stone, its
    parchment) wanted as a choice of *Background texture*?
- Party and raid at the top left is not final.
- What goes to the left and the right place.
- Where a window may go: any of the nine places (and free), or only its own place? (One window to a place
  at a time: decided, above.)
- How the views of one window are switched: tabs like Blizzard's, in a row at the top of what the window
  holds (built in Core 2026-10-17, `Views.lua`; `/sane window` shows two).
- What right and middle click on a trigger area do.
- On which of Sane UI's own pages the section *Hotcorners* stands (*General* or *Appearance*, where
  *Animation type* is).
