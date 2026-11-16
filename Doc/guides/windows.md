# The window system

How Sane UI's windows are built: the one system every window uses, its parts, the states a window goes
through, what is kept, the rules that keep it fast, safe from taint and never stuck, and the recipe for a
module's window. Read this before building or changing any window.

- **What Saneroki decided, and what is still to come:** [Doc/ideas/Windows.md](../ideas/Windows.md) (the plan;
  where this guide and the plan differ, the plan's newest decision wins and this guide gets corrected).
- **Every call:** `src/Core/README.md`, section *Windows*, and the head of each file in `src/Core/`.
- **Look and behaviour:** [gui-development.md](gui-development.md); **code rules:**
  [addon-standards.md](addon-standards.md). This guide adds what is particular to windows.

Blizzard's code is the ground truth, its newest export (`dev/tools/blizzard where`); every fact below marked
*verified* was checked in the in-game export of then on 2026-10-16, with the file it was read in.

## 1. One system for every window

- **Every window of Sane UI is a `Core.Window.New`:** the chat, the spellbook, a vendor's window, later the
  minimap. A module never builds moving, sizing, docking, full screen, the title bar, the search, Esc or the
  kept place again. When a window needs something Core does not have, Core gets it, once, for all.
- **Ours or the game's, never both** (Saneroki, 2026-10-16). A window that stands for one of the game's own
  (its `native`) does not replace it: the window is set to one of the two, the choice is kept, and the
  player sees only that one. Set to Sane UI, what opens the game's window (its key, a micro menu button, a
  slash command, a link, an NPC) opens ours, as the player last left it (`window:Open()`). Set to the
  game's, ours is hidden and the game's works as always, with one Sane UI button on its title bar to switch
  back. Core sees to it for every window, one way (section 7, *The holder*).
- **The game's own window is left as it is.** Sane UI does not restyle, move or resize Blizzard's windows
  (the spellbook is being moved off that today). While ours is chosen, the game's is only kept out of sight.

## 2. Kinds of window

Windows are panels like the game's own (Saneroki, 2026-10-16): the chat, the spellbook, the talents, a vendor,
the bank, the bags. Combat's window at the bottom middle (2026-10-20) is one of kind screen, whose full screen
holds the talents and the spellbook. What the Combat module shows (nameplates, unit frames, buffs, action bars) is no window
and does not use `Core.Window`. Pick the kind first: `kind = "screen" | "panel" | "talk"` gives the
window its kind's options (`Window.KINDS`); what the module gives itself wins.

| Kind | Examples | Title bar | Docked at first | Full screen by | Esc | Moved outside Edit Mode |
| --- | --- | --- | --- | --- | --- | --- |
| **screen** | the chat, the minimap | no (`titleBar` off): see-through or a look of its own | a screen edge zone (`first.dock`: the chat `BOTTOMLEFT`) | its screen edge (push, or click: section 8) | brings it back from full screen | no |
| **panel** | the spellbook, the talents, the guild, the bags | yes | a screen edge middle, or free | its maximize button (and its edge, if docked there) | closes it (`escape = "close"`) | by its title bar, not docked at an edge |
| **talk** | vendor, trainer, auction house, bank | yes | the middle (`first.dock = "CENTER"`, the kind's) | its maximize button | closes it, ends the talk | by its title bar |

| Option | screen | panel | talk |
| --- | --- | --- | --- |
| given by the kind | `dock`, `edge`, `sizable` | `titleBar`, `dock`, `skin`, `edge`, `sizable`, `escape = "close"`, `toplevel` (a click brings it to the front) | as panel, and `first = { dock = "CENTER" }` |
| the module's | `store`, `first`, `title`, `search`, `content`, `docked`, `classic`, `native`, `close`, `minWidth`, `minHeight`, `insets`, `buttons`, `tabs`, `strip` | the same | the same; `close` ends the talk |
| left out | `skin` (see-through), `titleBar` (only while full) | | |

A table the module gives where its kind has one (`first`) is merged: the module's keys win, the kind's fill
in the rest.

## 3. The parts, and who does what

| Core file | It does |
| --- | --- |
| `Dock.lua` | The nine zones (corners, edge middles, `CENTER`); which zone a let-go window docks to, kept `insets` from the screen's edges; the tinted shape while dragging. Plain numbers, no frames but the shape. |
| `Window.lua` | The window: its place and size kept and restored (its first zone, standing clear of a zone another holds), the title bar (title, `SetTitle`, search box, Core's buttons and the module's; on the full screen the options' cog and the question mark), `window.inside` (where what it holds stands), dragging by the title bar, Edit Mode's box or, on a window without a title bar, a part of its own (`DragBy`; snapping to Edit Mode's grid), sizing by the grip, to the front (`toplevel`), the combat lock, what it was left as (`Remember`, `Recall`, `Native`, `Open`), the button on the game's window (`Attach`), every window (`All`, `ResetAll`). |
| `EditMode.lua` | Whether Blizzard's Edit Mode is open (its event registry); `/sane arrange` where there is none. |
| `Selection.lua` | A window chosen in Edit Mode by a click on its box, and Core's dialog in Edit Mode's look (*Reset To Default Position*). |
| `Escape.lua` | Esc: one stand-in in the game's `UISpecialFrames` for everything of Sane UI's that Esc closes (`Core.Escape`). |
| `Watch.lua` | `Core.Watch` (a look a few times a second, only while out and shown) and `Core.Hover` (the mouse on a window: its coming by `OnEnter`, a watch until it has gone). |
| `Edge.lua` | Full screen: the trigger at the screen edge, the motion there and back, the background, the dropdown *Classic windows*, the section *Expand window* (its changes followed by Core). The switch *Hotcorner requires leftclick* there (`expandClick`, on at first in every module since 2026-11-16) makes the edge strip take the left button; off, the mouse's coming is enough. |
| `Classic.lua` | The game's windows ours stand for (`classic`): the dropdown *Classic windows* with every module's, each under its name; the button *Sane UI* on each game window (a secure one clicking the game's close button on its panels), ours instead, full where the entry says. |
| `Views.lua` | A window's views behind the game's tabs (`tabs`), the tab last chosen kept. |
| `Holder.lua` | The game's window kept out of sight while ours is chosen, and the game's own opening and closing of it followed (section 7, *The holder*). |
| `Motion.lua` | The kinds of motion (Glide, Swing, Even, Instant), each a time and one of the game's easing curves (`EasingUtil`), a clock that runs only while something moves, a region's fade and slide (`Motion.Fade`, `Motion.Slide`). |
| `Shape.lua`, `Skin.lua` | The plate: round corners (a share of the window, or a fixed radius; square at the screen's edges, always square in full screen), the trim, a round icon (`Shape.Round`); the skin, a window's background and border; the game's background tiles (`Skin.TILES`). |
| `Expand.lua` | A window that opens larger once the mouse has rested on it, closes a moment after the mouse has gone, and can be kept open (`Stay`). |
| `Seat.lua` | A window that is not ours (the game's spellbook, a known addon's: `Neighbours.lua`) seated in a room of a full window: its place, scale and layer lent, never its parent; followed after the game's `SetPoint` and `SetScale`; given back when it closes (section 7, *Seated*). |
| `Board.lua` | A module's full screen of windows (section 7, *The board*): layouts the player arranges, behind tabs in the full window's title bar; the windows share the screen and never overlap (a tree of splits), a line between two dragged to share their room, a head dragged onto another to go beside it or swap, an X to take one off, the dropdown *Windows* to add one; each window a panel of Core's (plate, head, body) holding the module's part. |
| `Fuzzy.lua` | Fuzzy finding for the search; a list ranked by it, a long one a part per frame (`Fuzzy.Filter`). |
| `Bar.lua` | A progress bar in the art of the game's experience bar. |

**The module does:** what the window holds and its layout (laid out once in `docked`, not on every step of a
motion); what the search finds (`search`); what closing means (`close`); what its window stands for
(`native.frame`) and what changes besides when the player switches (`native.show`, `native.back`); its settings (the section *Expand window* through `Edge.Options`).
**Core does:** keeping the game's window out of sight while ours is chosen and following the game's own
opening and closing of it (`native.hold`; section 7, *The holder*).

## 4. States

A window's state is held in a few flags; Core keeps them, the module reads them.

| State | Flag | Begins | Ends | While in it |
| --- | --- | --- | --- | --- |
| shown | `frame:IsShown()` | the module, `Open` | the module, `close`, Esc | — |
| at rest | not `edge.away` | `Place` | a full screen motion | it may be moved, sized, dragged |
| away (to full screen and back) | `edge.away`, `edge.full` | `edge:Fill(true)` (edge, button, `Open`) | back in its place (`Place`); another window filling the screen sends it back | not moved, not sized, not dragged; content faded out while moving |
| in hand | `window.moving`, `window.sizing` | a drag (title bar, Edit Mode's box), the grip | let go, Edit Mode closing, hidden | the dock shape shows |
| arranging | `Core.EditMode.active` | Edit Mode opens (or `/sane arrange`) | it closes | Edit Mode's box over every window, grips shown, buttons hidden, no full screen (full windows put back), title bars do not drag |
| locked | `window:Locked()` | a fight, for a window holding protected frames | the fight's end | nothing of ours moves, sizes, shows or hides it; `Place` waits; `Open` says `"locked"` |
| the game's own chosen | `store.place.native` | the toggle (`Native(true)`) | the toggle on the game's window (`Native(false)`) | `Open` shows the game's window |
| holding its zone | `Dock.Holder(zone)` is it | placed docked, shown | hidden, or docked elsewhere | no other window docks there (no shape on a drag; one opening with that zone kept stands clear of it) |
| selected | `Core.Selection.window` is it | a click on its box in Edit Mode | another chosen (ours or the game's), Edit Mode closing | its box in Edit Mode's selected look, Core's dialog names it |
| the game's held | `window.holder.held` | ours chosen and the game's closed (`native.hold`) | the game's chosen (`Native(true)`), a failure, `GiveBack` | the game's window is under our hidden frame: opened by the game, it opens ours |

A window with `grip = "hover"` (the minimap's) has its grip at rest outside Edit Mode too: unseen until the mouse
is on the window (`window:Hover(on)`, which its module calls) or on the grip, hidden while its `usable()` says no
and while it is away (Edge).

**Invariants** (keep them when changing anything):

1. **One mover at a time.** A window's size or place is changed by one part only: Edge while away, a drag
   or a sizing while in hand, Expand while it opens or closes (its `still` must give way to Edge: `/sane
   window` does). A new part that moves windows joins this rule.
2. **The kept place is the window at rest.** It is written only when a drag or a sizing ends (`Keep`), never
   while away. Expand's open size passes too, but Core cannot tell it from a size of the player's: a window
   that opens under the mouse is not `sizable`, so its kept place holds no size.
3. **What the window was left as is written only by the player's intent:** full screen by the edge or the
   button (`Edge.Fill`), the game's own window by the toggle (`Native`). Not by Edit Mode putting a window
   back, not by hiding, not by Esc on a window Esc closes (it opens full again next time).
4. **Hidden means at rest.** A window hidden while away is back in its place at once: nothing moves out of
   sight.
5. **Nothing runs at rest.** No `OnUpdate` while nothing changes: the dock shape only during a drag, the
   motion clock only during a motion, Expand's watch only from the mouse's coming until the window is closed
   (none while it is kept open). A module that must look at something does so by `Core.Watch` or
   `Core.Hover` (the chat's mouse), which run only while out and shown.
6. **A protected window is never touched in a fight** (section 7).
7. **One window to a zone at a time** (Saneroki, 2026-10-16): the first one shown there holds it; a zone's
   kept name is never dropped because it was taken (the window docks there again once it is free). One
   opening meanwhile stands clear: where it stood, or beside the zone, `Window.CASCADE` down and to the side
   of each window already there.
8. **A module's hooks never break a window.** Every hook (`docked`, `filled`, `motion`, Expand's `changed`,
   `motion` and `still`, a bar's `moved`, the Mover's and Sizer's) runs through `Core.Safe`; Core's own flags
   (`moving`, `sizing`, `away`) are set back whatever a hook did.

## 5. What is kept

- **Where:** `store[key]`, `store` the module's (`Core.Store(module)`: `SaneUIDB.modules.<Module>`, for the
  account, not in profiles), `key` the window's (`"place"` at first, another name for a second window).
- **What:** `{ x, y, width, height, dock, full, native, tab }`: `x`, `y` the top left corner from the screen's
  lower left one; `width`, `height` only for a sizable window; `dock` a zone's name (a zone that no longer
  exists: the kept coordinates count); `full` it was left in full screen; `native` the game's own window was
  chosen; `tab` the tab last chosen (none: the first).
- **Read with care:** a kept size larger than the screen is cut to it; a place that cannot be read gives the
  first place; `Reset` (Edit Mode's dialog, `/sane window reset all` for all: `Window.ResetAll`) puts the
  first place and size back and keeps `full`, `native` and `tab`.
- **To come:** one place per Edit Mode layout, following Save, Revert and switching layouts (section 8,
  item 2, has the keys and the new shape of the store).

## 6. Building a window: the recipe

1. **Make the frame when it is first needed** (`CreateFrame("Frame", nil, UIParent)`), not at login.
2. **`Core.Window.New(frame, options)`** with its `kind` (section 2) and what its kind does not give. A
   frame Esc may close needs nothing more: Core keeps one stand-in for all of Sane UI in `UISpecialFrames`
   (`SaneUIEscape`). Anything else of a module's that Esc should close (a small window that is no
   `Core.Window`) takes `Core.Escape(owner, close)` while it is shown and `Core.Escape(owner, nil)` when it
   hides; never an entry of its own in that list.
3. **Build what it holds in `window.inside`,** which stands under the title bar while there is one (also
   when a window without one fills the screen) and the whole window otherwise; `window.top` says how far
   down it starts. Name the part that fades while the size moves (`content`). Several views: `tabs`, each
   built in the frame its tab gives when first chosen. Buttons of the module's own in the title bar:
   `buttons = { { atlas, tip, text, click } }`, left of Core's. Full, Core adds two left of them: the game's
   cog (Sane UI's options over the full screen, `Settings/Screen.lua`) and a question mark, the full screen's
   tour: `help = function()` (without, it does nothing yet).
4. **Lay out in `docked(zone)`,** which comes once the window stands (placed, or full screen reached), not in
   `OnSizeChanged` while `window.edge.away` (every step of a motion is a new size).
5. **Search:** `search = function(text)`, then `Core.Fuzzy.Filter(rows, text, fields, done)`: `fields` the
   keys of a row (or functions of it) to look in, `done(found, ranks)` the rows every word is in, best
   first. Up to `Fuzzy.AT_ONCE` (200) rows it answers at once; a longer list is ranked a part per frame on
   `Core.Steps`, and a newer search stops an older one. A short list may do it by hand: `Core.Fuzzy.Query`
   once, `Core.Fuzzy.Match(query, row's texts...)` per row (Social's log, `Core.Fuzzy.Plain` for the game's
   coded texts). `Core.Fuzzy.Rank(word, text, nil, spots)` and `Core.Fuzzy.Highlight` only for the rows on
   screen.
6. **The game's own window** (`native`): `frame` (a function if its addon loads on demand), `hold = true`
   (Core's holder keeps it out of sight while ours is chosen), `addon` (the addon that brings it: held, and
   our button attached, once it has loaded), `unseen` (a window whose `OnShow` must not run from our code:
   closed unseen before it is given back), `anchor` (optional: where the button back to ours goes on the
   game's window, for one without a close button, such as the chat), `show` and `back` (what else changes
   when the player switches to the game's and back). Without `hold` (the chat, which is never closed) the
   module hides and shows the game's itself, out of a fight only.
7. **The game's triggers** need nothing of the module with `hold` (section 7): the game opens its own window
   as always, unseen, and Core opens ours (`window:Open()`: `"ours"`, `"native"`, or `"locked"` in a fight
   when ours holds protected frames and is closed). A module that stands down calls `window:GiveBack()`.
8. **`close`:** what closing means (end the talk with the game's own call; hide). Without, Core hides it.
9. **`window:Place()`** once it is built.
10. **Settings:** `Core.Edge.Options(list, at, tab, under)` puts the section *Expand window* (with the
    corners) into the module's switches (`under`: a switch of the module's own one of them stands under
    too, `{ motion = "animations" }`); a change of one is followed by Core (`window.edge:Update()` for every
    window with those settings), before the module's `changed` is told: the module need do nothing.
11. **Test** with the stand-in client (`dev/tests/window.lua` shows how: frames that know their place, a
    clock that is run by hand, Edit Mode by `EventRegistry:TriggerEvent`).

## 7. Rules

### Taint and the game's own windows

Blizzard's code that our code starts runs as ours, *tainted*. In a fight the game refuses it where it
matters; out of one it runs, but what it writes is tainted for Blizzard's own code that reads it later
(section 9 has every fact with its file).

- **Nothing of Blizzard's is written:** no global, no field, no function replaced (`ToggleFriendsFrame`,
  `SocialUIControl`, `DISALLOW_FRAME_TOGGLING`, a micro menu button's `OnClick`), no flag of Edit Mode's
  (`SetHasActiveChanges`). Only hooks after (`hooksecurefunc`, `HookScript`) and the event registry's
  callbacks; their code changes nothing of Blizzard's either.
- **Blizzard's panels are not shown or hidden by our code where it can be avoided.** `ShowUIPanel`,
  `HideUIPanel`, `ToggleFrame` and every `Toggle…` that ends in them refuse an addon in a fight
  ("Interface action failed because of an AddOn"). Out of one they run the panel's `OnShow` and `OnHide`
  as ours: the spellbook's show and hide the action bars' grids (their buttons are protected); a vendor's,
  trainer's, bank's and the auction house's `OnHide` ends the talk; the map's `OnShow` does an emote (an
  API with restrictions). Hiding the game's window in a hook after its `OnShow` does all of that.
- **Opening the game's own by its toggle** from our code works out of a fight only (Social's friends list
  does so today, and in a fight says to use the game's own key); the holder below replaces that.
- **Not taken** (considered in the review, 2026-10-16): override bindings on the game's keys and a button
  of ours over its micro menu button (they miss links, tutorials and other ways in, and change only out of
  a fight), and `RegisterPlayerInteraction` for a talk (it cannot be given back without a `/reload`, so
  the switch to the game's would need one).
- **Never alpha 0** for a game's window: it keeps its place among the game's panels, and its buttons still
  take clicks.
- **Ours are plain frames,** shown with `:Show()`, not registered as the game's panels (`UIPanelWindows`), so
  they open in a fight; Esc by Core's one stand-in in `UISpecialFrames` (`Core.Escape`).
- **Load on demand:** the spellbook's addon (`Blizzard_PlayerSpells`) loads when the game first opens it.
  Our code never loads it; it waits (`EventUtil.ContinueOnAddOnLoaded`) to attach its button.
- **Try it in the game with the taint log:** `/console taintLog 1`, `/reload`, the test, then the game
  folder's `Logs/taint.log`: no line where Sane UI's code touched a Blizzard frame or value.

### The holder: ours or the game's (`Holder.lua`)

One way for every window, from Economy's plan (`Doc/ideas/Economy.md`, *Hidden, not closed*), made
Core's: a frame of ours that is never shown, and the game's windows held in it while ours is chosen
(`native.hold = true`; `window.holder`).

- **Held while closed.** Set to Sane UI, the game's window gets the holder as its parent (lent,
  `Core.Lend`: its parent and layer noted and put back exactly, the parent only if it is still ours), only
  while it is not open: at once, once its addon has loaded (`native.addon`, `EventUtil.ContinueOnAddOnLoaded`),
  and again each time it closes. The game then opens and closes it as always, by its own code: it counts as
  shown (`IsShown()`), but it never comes into sight, so its `OnShow` and `OnHide` do not run (no talk
  ended, no action bar touched, no bags).
- **Followed.** Hooks after the game's window's own `Show`, `Hide` and `SetShown` (`hooksecurefunc`; every
  way passes there: its key, a micro menu button, a link, an NPC, Esc) open and close ours (`window:Open()`;
  `"locked"`: the game's is given back for that time). Nothing of the game's is taken over or replaced.
- **To the game's** (our title bar's first button, the dropdown *Classic windows*): ours closes; the game's
  window goes back to its parent and comes into sight, so its `OnShow` runs from our code. Fine for most
  windows (the friends list, the guild, a vendor: as if it had just opened). Not for the spellbook (its
  `OnShow` sets the action bars' grids: their buttons are protected, and the fields it writes would be
  tainted) or the map (it does an emote, an API with restrictions): with `native.unseen` the held window
  is closed unseen first and given back, and the game's opens at its key's next press. The secure switch
  that opens it at once is still to come (section 8).
- **To ours** (the Sane UI button on the game's window, while it is in sight): the game's window is not
  hidden (its `OnHide` would end a talk, or touch the action bars) but made tiny and clear (`SetScale`
  `Holder.TINY`, alpha 0: its buttons shrink to a point and take no clicks; the game's panel layout counts
  its scale) until the game closes it; then it is held again. Ours opens at once. Ours closed while the
  game's is held open: the game's is closed too, unseen.
- **The empty place:** the game's panel layout still counts a held window as open (sight is not looked at),
  so another of the game's panels opened beside it stands where it would stand beside the game's. To see in
  the game whether that disturbs.
- **A failure gives the game's back:** a step of the holder that fails gives the game's window back at once
  and holds it no more (`holder.off`); a module whose window fails calls `window:GiveBack()` (*Resilience*).
- **Not for the chat:** the game's chat frames are never closed, so Social keeps them out of sight itself
  (`src/Social/Native.lua`, on `Core.Lend` as well).

### Seated: a window not ours on a full screen (`Seat.lua`)

A full window may hold windows that are not ours as panels (Combat: the game's talents and spellbook, a talent
planner Sane UI knows). The rules:

- **Placed, never shown or hidden.** Only its place, scale and layer are lent (`Core.Lend`); its parent stays
  its own, so its `OnShow` and `OnHide` run from its own code only. The game's panels are opened by the game:
  its keys, its micro menu buttons, or a secure button of ours that clicks the game's own micro menu button
  (`SecureActionButtonTemplate`, `type = "click"`). That button stands on UIParent, not in our window: a
  protected child makes our window protected, and it would be locked in a fight. It is made, placed, shown and
  hidden out of a fight only.
- **Followed:** hooks after its `SetPoint` and `SetScale` put it back in its room when the game places or
  scales it anew; a new size fits it anew; closed, it is given back exactly. `Core.Lent(frame)` says that it is
  lent, so another module leaves it alone meanwhile (Abilities does not place the spellbook then).
- **Going back** from the full screen gives it back to its place, open: our code does not close the game's
  window. Esc closes it with the full screen.
- **Where it stands today:** the game's window of talents and spellbook in Combat's panel in Retail, where ours are
  not (`src/Combat/GameWindow.lua`, with that secure button over the closed panel), the game's action bars in Combat's panels
  (`src/Combat/BarsWindow.lua`), Social's guild window, a talent planner, the game's vendor and mail windows (and
  a letter's) on Inventory's full screen and its trainer and Profession windows on Combat's (`Core.Seat.Part`: a board's part made of a game's
  window, there while it is open, its `OnShow` and `OnHide` followed; Saneroki, 2026-11-09).

### The board: a module's full screen of windows (`Board.lua`)

A full window that holds several of the module's windows (Social: the conversations, the friends list, the guild
window) lays them out on Core's board (`Core.Board.New(window, { store, key, label, windows, default, changed })`),
not by itself. The rules:

- **They share the screen, never overlap.** A layout is a tree of splits (side by side, `"x"`, or one over the
  other, `"y"`), each part a share of its room; `Board.Lay` gives each window its rect, whole pixels, `PAD`
  between neighbours and from the screen's edges. A window that cannot be held now (`present` false: the game's own
  guild window, closed) stays in the layout and is left out of the laying out; the others share its room until it
  is back. Its tick and its tab then do nothing to see, so a window of the module's own has no `present`: it stands
  and says why it is empty (the module Guild's, out of a guild); that it takes no room unasked is its first
  layout's to say (`want`), and a change there is told with `Board.Told`.
- **Arranged on the full screen itself, laid out once.** The gap between two neighbours is a strip that takes the
  mouse (the game's sizing cursor): held, only a line follows; let go, the two share their room anew, neither
  under its `least`. A window's head is dragged: held, it is see-through and a tinted shape shows where it would
  go (near a side of another: the two share that one's room; its middle: they swap; near a side of the screen: a
  strip along it); let go, the layout is kept and laid out once. Nothing runs at rest: one watcher, only while
  something is held. The X takes a window off; the dropdown *Windows* (left of *Classic windows*) ticks those in
  the layout, a tick adds one beside the largest.
- **Sized by its corners, as the mouse goes** (Saneroki, 2026-11-15: "make those corners of windows dragable to
  resize the windows in realtime"). The kit's two bronze brackets at a panel's right are its corners (the outer
  `Board.CORNER` of each, under the X, lit under the mouse): held on the full screen, the lines along its sides (the
  one at its right, the one over or under it) follow the mouse and the layout is laid out at every step, its
  windows told their sizes as they go; let go, it is kept. A corner without a line along it does nothing there. A
  bare panel draws its own window and has none.
- **A window of its own** (Saneroki, 2026-11-15: "a button that enables it to make it it's own window without the
  fullscreen. So you can for example open bags without the fullscreen if you hit its keybind"). Beside the X the
  game's own minimize (`MaximizeMinimizeButtonFrameTemplate`'s `RedButton-Condense`): the full screen goes back and
  the window stays where it stood, by itself on the screen (`MEDIUM`, a click brings it to the front, clamped, Esc
  closes it), moved by its head, sized by its corners as the game sizes a frame; from then on the module's key for
  it opens and closes it so (`Core.Board.Key(label, key)` first in the module's key: the bags' key the bags alone,
  Combat's keys their book, the guild key the guild window), and a key while the full screen stands with it sends
  the full screen back. The full screen keeps its layouts with that window in them; the full screen that comes takes
  every window of its own back onto it. On its own window the button is the game's maximize (`RedButton-Expand`):
  back onto the full screen, which comes with it, and its key opens that again. Kept in `store[key].alone[key] =
  { x, y, width, height, on }`. None for a window as large as what it holds or one that says so (`apart = false`:
  the game's own window seated there). In a fight a panel that holds protected frames is neither shown, hidden,
  moved nor sized; the module's window that goes (it stood down) takes its windows of their own with it.
- **Layouts behind tabs** after the title in the title bar (the game's `MinimalTabTemplate`): the first is the
  module's (`default(width, height)`, laid out for the screen as it is until it is changed, then kept as changed;
  *Reset* makes it the module's again), `+` makes an empty one, a right click renames, resets the first, deletes
  another (confirmed). Out of sight while the search box lies over the bar.
- **A window's own tab**, after the layouts' tabs and `+`, for a window whose spec has an `icon` (a texture or
  file ID with its `coords`, or `function(texture)` that draws it, like a portrait): the icon in place of words,
  lit (the tab selected, the icon in full colour) while the window is in the layout chosen, greyed while not; a
  click puts it in or takes it off, as its tick in *Windows* does; its tooltip says the window's title. The
  module picks the game's own icon for what the window stands for.
- **Kept** in `store[key]` (account-wide, as places are): `{ chosen, tabs = { { name, tree } }, alone }`, a tree only
  once changed (`false`: emptied); `alone` the windows of their own.
- **A window of another module** (Saneroki, 2026-10-20): a module depends on Core only, so a window it puts on another
  module's board is offered through Core (`Core.Board.Offer(label, spec)`, the board's label): the board lists it after its
  own, or in place of its own of the same key (the module Guild's guild window on Social's full screen, where Social
  otherwise holds the game's guild window); `Core.Board.Open(label, key)` fills that board's screen with it in the
  layout, and says false when that cannot come now (its window closed, Edit Mode, *Can expand to fullscreen* off): the
  module shows its window elsewhere; `Withdraw` takes it back when its module stands down. Either way a board that
  stands lays out anew, and the window that has the key now gets a panel of its own.
- **A talk's layout** (Saneroki, 2026-11-09): a module may give its board a layout for a talk (`occasions = { [name] =
  { title, default } }`: Inventory's vendor and bank, Combat's trainer and profession trainer). While the module says
  the talk is on (`board:Occasion(name)`, at the NPC's window or event), that layout stands instead of the tab chosen,
  behind a tab of its own first in the title bar; changed, it is kept as the talk's (`occasions[name]`), never in the
  player's tabs; a right click resets it; another tab chosen sets it aside until the talk ends. The module fills the
  screen for the talk and sends it back at the end only when it came for it; one open before stays, with the tab
  chosen. The game's window of the talk is never opened or closed by our code: only seated while it is open; where a
  second game window belongs to it (the Profession window), it is asked of the server, as the game's own code does it
  (`C_TradeSkillUI.OpenTradeSkill`, `CloseTradeSkill`), whose answer the game's code shows.
- **What is in a window is the module's**: a panel of Core's (the kit's heavy bronze, `Core.Look.Frame`; a head
  `Board.HEAD` high with its title and the X inside the band, the thin golden line, the body; what the module puts
  there keeps `Board.EDGE` from the panel's border) holds the module's part, built the first time it is shown (`build`), told
  when it is shown and hidden (`show`), its size once a change stands (`size`), the search (`search`). A window
  not ours stands in its panel by the module's seat (section *Seated*). A window may ask for no frame (`spec.dress = "bare"`:
  the module draws its own window, as the character's doll; a head, the game's gold title and the game's X it
  places on what it draws).

### Combat

- A window that holds the game's protected frames (secure buttons that cast a spell or use an item) is
  protected itself (`frame:IsProtected()` is true for the parent of a protected frame, *verified*:
  `SimpleScriptRegionAPIDocumentation.lua`, `IsProtected` returns `isProtected` and
  `isProtectedExplicitly`). In a fight addon code may not move, size, show or hide it.
- Core keeps to that by itself (`window:Locked()`): no drag, no sizing, no full screen, `Place` waits for
  `PLAYER_REGEN_ENABLED`, a motion on its way is finished at `PLAYER_REGEN_DISABLED` (the game says so before
  it locks), `Open` returns `"locked"`. The module does the same for its own calls on the window (`Show`,
  `Hide`, `SetPoint`), and builds secure buttons out of a fight.
- A window without protected frames (the chat, a vendor's lists) is free in a fight.

### Performance

- **Made when first needed, nothing at rest** (invariant 5). The title bar, its buttons, the search box,
  Edit Mode's box, the full screen background, the dropdown are each made the first time they are shown.
- **A motion is the game's animation** (`Motion.Clock`): one call per frame, only while it runs; out of sight
  it ends at once.
- **Per step of a motion** only what moves is touched (place, size, the plate's pieces, fitted once: a
  skin is held meanwhile, `skin:Hold`); what the window holds is laid out once at the end. A bar's rise
  moves only its fill and flare.
- **Search:** no tables per row (`Fuzzy.Rank` without spots), one pass through a text per look, lower-case
  once per text (kept while the row's text stays the same), spots only for rows on screen, long lists in
  parts (`Fuzzy.Filter`).
- **Events, not polling.** Edit Mode by its callbacks, the mouse at the screen edge by a strip's `OnEnter`.

### Resilience

- Every call into a module's hooks and every script of ours runs through `Core.Safe`; an error is kept in the
  log and the rest goes on. A part that fails stops for that window (`edge.off`) and the window stays usable
  in its place.
- **Never stuck:** without Blizzard's Edit Mode, `/sane arrange` gives the same mode; a kept place that
  cannot be read gives the first place; a window larger than the screen is cut to it.
- **Never in the way of the game's own:** if our window fails, the module shows the game's window
  (`module.Guarded`, then `native.show`).

### Look

- Built from Blizzard's parts, the kit's first (`Core.Look`, `Doc/guides/interface-style.md`, *The kit*, Saneroki,
  2026-11-15): a window's frame the character list's heavy bronze (`Look.Frame`; what it holds and its title bar
  inside the band), the board's layout tabs the character screen's top bar (`Look.Tab`) in the middle of a full
  window's title bar (`Window.FULL_BAR` high, nothing drawn behind it), the title bar's buttons the grey square ones (`Look.Square`), its search box the
  character list's (`Look.Search` on `SearchBoxTemplate`); the close button (`UIPanelCloseButtonNoScripts`),
  maximize and minimize (`MaximizeMinimizeButtonFrameTemplate`), the dropdown (`WowStyle1DropdownTemplate`), the
  tabs of a window's views (`TabSystemTemplate`, `TabSystemTopButtonTemplate`), Edit Mode's selection art (its
  nine-slice atlases, highlighted and selected) and its dialog's look (`DialogBorderTranslucentTemplate`), the
  title in `GameFontNormal`. A window may still ask for the round dark plate (`skin = "round"`, `Core.Skin`).
- The game's own sounds where Blizzard plays them, by `SOUNDKIT` (a window opening and closing: to come,
  section 8).

### Text

Every word a window shows is in one place per module (`ns.TEXT`), or the game's own string where it has one.

## 8. Not built yet, in order

Each with what is decided and what it needs; the plan has the decisions in full.

1. **The secure switch to the game's spellbook and map** (section 7, *The holder*, *To the game's*): a
   secure action button (`SecureActionButtonTemplate`, `type = "click"` on the game's own micro menu button)
   whose `PreClick` closes the held window unseen and gives it back, so that the game's own click opens it
   at once, as its own code. It makes our window protected (`window:Locked()` in a fight). Today
   `native.unseen` gives it back closed, and it opens at its key's next press. With the taint log: a vendor
   (held, opened by the NPC, given back mid-talk), then the spellbook (held, its key, the switch).
2. **Edit Mode's layouts, Save, Revert** (decided; the plan's *Edit Mode* has the design, section 9 the
   facts; *Reset To Default Position* is built, in Core's own dialog: `Selection.lua`). In short: a place per layout, keyed `preset:<number>`,
   `account:<name>`, `character:<character>:<name>`; one hook after `EditModeManagerFrame:UpdateLayoutInfo`
   (every way to a layout passes there: login, switching, *Revert Changes*, a new or imported layout),
   `EditMode.SavedLayouts` for *Save*, hooks after `RenameLayout` and `DeleteLayout` (a list of the layouts'
   keys by number, kept from the last `UpdateLayoutInfo`, says what was renamed or deleted). Our moves are
   Core's unsaved changes; Core enables Blizzard's *Save* and *Revert Changes* buttons itself
   (`SetEnabled`, again after each `SetHasActiveChanges`), never Blizzard's flag. Switching the layout or
   leaving Edit Mode with only our changes unsaved asks in Core's own dialog. The store then becomes
   `{ layouts = { [key] = { x, y, width, height, dock } }, full, native }`, today's shape read as the
   first layout's once.
3. **Edit Mode for windows that are hidden outside their use** (a talk window exists only at an NPC; a panel
   may be closed): in Edit Mode Core shows each registered window that is hidden as a preview at its kept
   place and size (its plate and title, nothing inside), so it can be moved and sized there too. Without it a
   talk window can never be sized (sizing is Edit Mode's). Previews hold no zone (invariant 7 counts shown
   windows only): two talk windows kept in the middle show there over each other.
4. **Full screen views: a board per module** (decided, Saneroki agreed to this design 2026-10-16): one full
   screen frame per module (background, the title bar, the dropdown, Esc), and a layout function that gives
   each of the module's windows its rectangle there. Going full screen, each window moves from its own place
   to its rectangle with the same motion (Edge's step, per window), the hidden ones (the friends list) come
   in; the search goes to every window's `search`; back, each returns to its place. What a window holds
   stays its own, so a window looks the same alone and on the board. Core: `Core.Board.New(module,
   { windows, layout })`; Edge's motion generalised from one window to a set.
   Built on 2026-10-20 within one full window (section 7, *The board*; Saneroki asked for layouts the player
   arranges, behind tabs): Social's windows stand on it; what is still to come is the windows' own motion
   from their places (today the board comes with the full window, its panels faded in).
5. **Opening and closing** with the game's sounds for a panel and a talk window, and the proposal of an
   opening motion (`window:Appear()`, Economy's plan; Blizzard's panels do not animate: open for Saneroki).

Built since the review: the kinds (`kind`, section 2) and one window to a zone (invariant 7), 2026-10-16.
On 2026-10-17: the holder (section 7), a first zone (`first.dock`) and standing clear of a zone another
holds, one Esc stand-in (`Core.Escape`), tabs (`Views.lua`), to the front (`toplevel`), `window.inside`,
`SetTitle`, the module's buttons, `insets`, `Window.All` and `ResetAll`, Edit Mode's selection and dialog
with *Reset To Default Position* and the grid's snap (`Selection.lua`), `Fuzzy.Filter`, `Core.Watch` and
`Core.Hover`, `Motion.Fade` and `Motion.Slide`, `Skin.TILES`, a fixed radius and `Shape.Round`, key bindings
(`Bindings.xml`).
On 2026-10-20: the seat (section 7, *Seated*) and a strip of a share of the screen's side (`strip`, Combat's half
of the bottom edge).

## 9. Facts checked in Blizzard's code

All in `Interface/AddOns/` of Blizzard's code (the in-game export of then; today the newest export, `dev/tools/blizzard
where`), checked 2026-10-16.

| Fact | Where | What it means for us |
| --- | --- | --- |
| Edit Mode announces itself: `EventRegistry:TriggerEvent("EditMode.Enter")` / `("EditMode.Exit")`; `EditModeManagerFrame:IsEditModeActive()` | `Blizzard_EditMode/Shared/EditModeManager.lua` 100-126, 151 | `EditMode.lua` listens; reads the manager once at login |
| Event registry callbacks run sealed off: `secureexecuterange` with `securecallfunction(closure, ...)` | `Blizzard_SharedXMLBase/CallbackRegistry.lua` 198-204 | our callbacks carry no taint into Edit Mode |
| Blizzard's selection box (`EditModeSystemSelectionBaseTemplate`) calls `EditModeManagerFrame:SelectSystem(self.parent)` on a mouse press | `Blizzard_EditMode/Shared/EditModeSystemTemplates.lua` 3374 | never use the template on our frames; Core copies its layout table (local there, 3222) and draws it with `NineSliceUtil.ApplyLayout` on its own frame |
| `NineSliceUtil.ApplyLayout(container, layout, kit)` makes its textures on the container | `Blizzard_SharedXML/NineSlice.lua` 160 | safe on our own frames |
| The close button `UIPanelCloseButtonNoScripts` (24 x 24, `RedButton-Exit`, frame level 510); `UIPanelCloseButton`'s click hides its parent through the panel system | `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml` 134-152 | Core takes the *NoScripts* one and gives the click itself: no `HideUIPanel` from our code |
| `MaximizeMinimizeButtonFrameTemplate`: `Maximize(isAutomaticAction, skipCallback)`, `Minimize(...)`, callbacks, looks; a CVar only if set | `.../SharedUIPanelTemplates.xml` 1070; `.../SharedUIPanelTemplates.lua` 659-727 | Core sets the look with `skipCallback` whenever the window changes by another way |
| `SearchBoxTemplate` (magnifier atlas `common-search-magnifyingglass`, clear button, instructions) | `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml` 206; `.lua` 180-198 | the title bar's search box; our handlers are hooks after the template's |
| `IsProtected()` returns `isProtected`, `isProtectedExplicitly` | `Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua` 540 | the first counts a frame made protected by its children: `window:Locked()` |
| Edit Mode hides its frames' boxes for a while without leaving (another window over it, its lock state): `OnShow`/`OnHide` call `ShowSystemSelections`/`HideSystemSelections` only, no `EditMode.Enter`/`Exit` | `Blizzard_EditMode/Shared/EditModeManager.lua` 96-153, `CheckHideAndLockEditMode` 155 | `EditMode.lua` hooks after both on the manager, so our boxes follow |
| `SetHasActiveChanges` writes `self.hasActiveChanges` ("Clear taint off of the value passed in" cleans the value, not the write) and enables *Save* and *Revert*; Blizzard reads the flag back on closing Edit Mode, switching layouts, the unsaved glow | `EditModeManager.lua` 276-284; read at 50, 1329, 1379, 1697 | never call it; enable the two buttons ourselves (section 8, item 2) |
| Every way to a layout passes `UpdateLayoutInfo`: the server's `EDIT_MODE_LAYOUTS_UPDATED`, `RevertAllChanges`, a new or imported layout | `EditModeManager.lua` 195-203, 995, 1655-1658 | one hook after it follows them all |
| *Save* is `SaveLayouts`, which fires `EventRegistry` `EditMode.SavedLayouts`; `RenameLayout` and `DeleteLayout` save at once | `EditModeManager.lua` 1640-1645, 1576-1601 | keep our places there; follow renames and deletes |
| The presets (*Modern*, *Classic*, *Gamepad*) have the game's localized names (`LAYOUT_STYLE_MODERN`, ...) and `layoutType` `Enum.EditModeLayoutType.Preset` | `EditModePresetLayoutsManager.lua` 8, 18, 28; `EditModeManager.lua` 1531 | key presets by number, the player's layouts by type and name |
| Edit Mode works in a fight (it clears its selection by a secure delegate only out of one) | `EditModeManager.lua` 766-772 | `window:Locked()` keeps protected windows still there |
| "We no longer allow addons to show or hide UI panels in combat": `ShowUIPanel`/`HideUIPanel` refuse when `InCombatLockdown() and not issecure()` | `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua` 849-861, 871-936 | no `Toggle…` or `ShowUIPanel` of ours in a fight |
| `ShowUIPanel` fires `EventRegistry` `UIParentPanelManager.ShowUIPanel` when the frame did show | `UIParentPanelManager.lua` 872-875 | follow the game's other ways of opening a window |
| The spellbook (`PlayerSpellsFrame`, load on demand) shows and hides all the action bars' grids in its `OnShow`/`OnHide`, and fires `PlayerSpellsFrame.OpenFrame`/`CloseFrame` | `Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.lua` 53-55, 85-89 | never show or hide it from our code |
| A vendor's, the auction house's (and trainer's, bank's) `OnHide` ends the talk: `CloseMerchant()`, `C_AuctionHouse.CloseAuctionHouse()` | `Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua` 163-164; `Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseFrame.lua` 448-458 | hiding the game's window loses the talk ours shows |
| `RegisterPlayerInteraction(type, { frame = <global name>, showFunc, hideFunc, loadFunc })`: without `showFunc` the game calls `ShowUIPanel(frame)`; the table it replaces is local | `Blizzard_UIPanels_Game/Shared/PlayerInteractionFrameManager.lua` 56-75, 114-163 | how a talk window of ours stands for the game's; back only by a `/reload` |
| The map's `OnShow` does `C_ChatInfo.PerformEmote("READ")` (an API with restrictions) | `Blizzard_WorldMap/Blizzard_WorldMap.lua` 386 | the map is never shown from our code |
| Camelot's keys: `TOGGLESPELLBOOK`, `TOGGLEPETBOOK`, `TOGGLETALENTS`, `TOGGLEWORLDMAP`, `TOGGLEQUESTLOG`, `TOGGLEGUILDTAB`, `TOGGLESOCIAL`, `TOGGLEFRIENDSTAB` | `Blizzard_FrameXML/Bindings_Camelot.xml` 1211-1256 | the bindings a window of ours takes over by override bindings |
| A mask is stretched whole (no slice margins); a texture takes at most three masks | Tooltips' and Social's experience (`src/Tooltips/Panel.lua`, Social's bubbles) | round corners are a masked piece per corner (`Shape.lua`, Social's bubbles on it too) |
| `EasingUtil` (`InQuadratic` ... `OutBack`), loaded in every flavour (2026-10-17) | `Blizzard_SharedXML/EasingUtil.lua`; `Blizzard_SharedXML.toc` 33 | `Motion.lua`'s curves, by name; a client without it moves straight |
| Camelot's experience bar: `UI-HUD-ExperienceBar-Background`, `-Fill-Experience`, `-Fill-Prediction` (rested, under the fill), `-Frame-Pip` (hidden within 1 % of an end), `ui-hud-experiencebar-divider`, the flare flipbook (7 x 4, 28 pictures, 32.5 x 10); `STATUS_BAR_NUM_SEGMENTS` 20 (2026-10-17) | `Blizzard_StatusTrackingBar/Mainline/ExpBar.xml`, `StatusTrackingBarTemplate.xml`, `ExpBarOverrides.lua`, `Shared/ExpBar.lua` 130-160, `Camelot/StatusTrackingBarConstants.lua`; `Blizzard_FrameXMLBase/GradualAnimatedStatusBar.xml` | `Bar.lua`'s art, sizes and dividers |
| Esc hides every shown frame whose global name is in `UISpecialFrames` (`_G[value]`) | `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua` 1106-1116 (2026-10-17) | one named stand-in of ours (`SaneUIEscape`) for all of Sane UI (`Escape.lua`) |
| The game's panels are `toplevel="true"`: a click raises them | `Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml` 403 (2026-10-17) | the panel and talk kinds' `toplevel` (`SetToplevel`) |
| `TabSystemTemplate` with `TabSystemTopButtonTemplate` tabs (the housing dashboard); the spellbook's tabs 100 to 150 wide, 22 from its left; the template's sound `IG_CHARACTER_INFO_TAB` | `Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.xml` 132-160; `Blizzard_PlayerSpells/Camelot/Blizzard_PlayerSpellsFrame.xml` 23-30; `Blizzard_HousingDashboard/Blizzard_HousingDashboardHouseInfoContent.xml` 81-85 (2026-10-17) | `Views.lua` |
| Edit Mode's dialog: `DialogBorderTranslucentTemplate`, strata `DIALOG` level 200; its button *Reset To Default Position* (`HUD_EDIT_MODE_RESET_POSITION`) | `Blizzard_EditMode/Shared/EditModeDialogs.xml` 254-273; `EditModeSystemTemplates.lua` 542 (2026-10-17) | `Selection.lua`'s dialog, in that look, our own frame |
| *Snap*: `EditModeManagerFrame:IsSnapEnabled()`; its grid's spacing (`SetGridSpacing`); the magnetism's range 8 | `EditModeManager.lua` 1076-1081, 1099; `EditModeUtil.lua` 119 (2026-10-17) | a free window of ours lines up with the grid, only read |
| A key binding: `<Binding name="..." category="BINDING_HEADER_...">` in an addon's `Bindings.xml`, its name `BINDING_NAME_...` | `Blizzard_FrameXML/Bindings_Camelot.xml` 4 (2026-10-17) | `src/Core/Bindings.xml`, `src/Social/Bindings.xml` |
