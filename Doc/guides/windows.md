# The window system

How Sane UI's windows are built: the one system every window uses, its parts, the states a window goes
through, what is kept, the rules that keep it fast, safe from taint and never stuck, and the recipe for a
module's window. Read this before building or changing any window.

- **What Saneroki decided, and what is still to come:** [Doc/ideas/Windows.md](../ideas/Windows.md) (the plan;
  where this guide and the plan differ, the plan's newest decision wins and this guide gets corrected).
- **Every call:** `src/Core/README.md`, section *Windows*, and the head of each file in `src/Core/`.
- **Look and behaviour:** [gui-development.md](gui-development.md); **code rules:**
  [addon-standards.md](addon-standards.md). This guide adds what is particular to windows.

`references/` is the ground truth; every fact below marked *verified* was checked there on 2026-10-16,
with the file it was read in.

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
the bank, the bags. What the Combat module shows (nameplates, unit frames, buffs, action bars) is no window
and does not use `Core.Window`. Pick the kind first: `kind = "screen" | "panel" | "talk"` gives the
window its kind's options (`Window.KINDS`); what the module gives itself wins.

| Kind | Examples | Title bar | Docked at first | Full screen by | Esc | Moved outside Edit Mode |
| --- | --- | --- | --- | --- | --- | --- |
| **screen** | the chat, the minimap | no (`titleBar` off): see-through or a look of its own | a screen edge zone | its screen edge (push, or click: section 8) | brings it back from full screen | no |
| **panel** | the spellbook, the talents, the guild, the bags | yes | a screen edge middle, or free | its maximize button (and its edge, if docked there) | closes it (`escape = "close"`) | by its title bar, not docked at an edge |
| **talk** | vendor, trainer, auction house, bank | yes | the middle (`CENTER`) | its maximize button | closes it, ends the talk | by its title bar |

| Option | screen | panel | talk |
| --- | --- | --- | --- |
| given by the kind | `dock`, `edge`, `sizable` | `titleBar`, `dock`, `skin`, `edge`, `sizable`, `escape = "close"` | as panel |
| the module's | `store`, `first`, `title`, `search`, `content`, `docked`, `classic`, `native`, `close`, `minWidth`, `minHeight` | the same | the same; `first` in the middle, `close` ends the talk |
| left out | `skin` (see-through), `titleBar` (only while full) | | |

## 3. The parts, and who does what

| Core file | It does |
| --- | --- |
| `Dock.lua` | The nine zones (corners, edge middles, `CENTER`); which zone a let-go window docks to; the tinted shape while dragging. Plain numbers, no frames but the shape. |
| `Window.lua` | The window: its place and size kept and restored, the title bar (title, search box, buttons), dragging by the title bar or Edit Mode's box, sizing by the grip, Esc, the combat lock, what it was left as (`Remember`, `Native`, `Open`), the button on the game's window (`Attach`). |
| `EditMode.lua` | Whether Blizzard's Edit Mode is open (its event registry); `/sane arrange` where there is none. |
| `Edge.lua` | Full screen: the trigger at the screen edge, the motion there and back, the background, the dropdown *Classic windows*, the section *Expand window*. |
| `Motion.lua` | The kinds of motion (Glide, Swing, Even, Instant), each a time and one of the game's easing curves (`EasingUtil`), and a clock that runs only while something moves. |
| `Shape.lua`, `Skin.lua` | The plate: round corners (square at the screen's edges, always square in full screen), the trim; the skin, a window's background and border. |
| `Expand.lua` | A window that opens larger once the mouse has rested on it, closes a moment after the mouse has gone, and can be kept open (`Stay`). |
| `Fuzzy.lua` | Fuzzy finding for the search. |
| `Bar.lua` | A progress bar in the art of the game's experience bar. |

**The module does:** what the window holds and its layout (laid out once in `docked`, not on every step of a
motion); what the search finds (`search`); what closing means (`close`); what its window stands for
(`native.frame`) and what changes besides when the player switches (`native.show`, `native.back`); its settings (the section *Expand window* through `Edge.Options`).
**Core does** (or will: section 8): keeping the game's window out of sight while ours is chosen and
following the game's own opening and closing of it (section 7, *The holder*).

## 4. States

A window's state is held in a few flags; Core keeps them, the module reads them.

| State | Flag | Begins | Ends | While in it |
| --- | --- | --- | --- | --- |
| shown | `frame:IsShown()` | the module, `Open` | the module, `close`, Esc | — |
| at rest | not `edge.away` | `Place` | a full screen motion | it may be moved, sized, dragged |
| away (to full screen and back) | `edge.away`, `edge.full` | `edge:Fill(true)` (edge, button, `Open`) | back in its place (`Place`) | not moved, not sized, not dragged; content faded out while moving |
| in hand | `window.moving`, `window.sizing` | a drag (title bar, Edit Mode's box), the grip | let go, Edit Mode closing | the dock shape shows |
| arranging | `Core.EditMode.active` | Edit Mode opens (or `/sane arrange`) | it closes | Edit Mode's box over every window, grips shown, buttons hidden, no full screen (full windows put back), title bars do not drag |
| locked | `window:Locked()` | a fight, for a window holding protected frames | the fight's end | nothing of ours moves, sizes, shows or hides it; `Place` waits; `Open` says `"locked"` |
| the game's own chosen | `store.place.native` | the toggle (`Native(true)`) | the toggle on the game's window (`Native(false)`) | `Open` shows the game's window |
| holding its zone | `Dock.Holder(zone)` is it | placed docked, shown | hidden, or docked elsewhere | no other window docks there (no shape on a drag; one opening with that zone kept stands free) |

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
   motion clock only during a motion, Expand's watch only from the mouse's coming until the window is closed. A module's own
   ticker (the chat's) is the module's to justify.
6. **A protected window is never touched in a fight** (section 7).
7. **One window to a zone at a time** (Saneroki, 2026-10-16): the first one shown there holds it; a zone's
   kept name is never dropped because it was taken (the window docks there again once it is free).

## 5. What is kept

- **Where:** `store[key]`, `store` the module's (`Core.Store(module)`: `SaneUIDB.modules.<Module>`, for the
  account, not in profiles), `key` the window's (`"place"` at first, another name for a second window).
- **What:** `{ x, y, width, height, dock, full, native }`: `x`, `y` the top left corner from the screen's lower
  left one; `width`, `height` only for a sizable window; `dock` a zone's name (a zone that no longer exists:
  the kept coordinates count); `full` it was left in full screen; `native` the game's own window was chosen.
- **Read with care:** a kept size larger than the screen is cut to it; a place that cannot be read gives the
  first place; `Reset` puts the first place and size back and keeps `full` and `native`.
- **To come:** one place per Edit Mode layout, following Save, Revert and switching layouts (section 8,
  item 2, has the keys and the new shape of the store).

## 6. Building a window: the recipe

1. **Make the frame when it is first needed** (`CreateFrame("Frame", nil, UIParent)`), not at login.
2. **`Core.Window.New(frame, options)`** with its `kind` (section 2) and what its kind does not give. A
   frame Esc may close needs nothing more: Core keeps its own stand-in in `UISpecialFrames`.
3. **Build what it holds as children of the frame,** below the title bar (`Core.Window.BAR`) when it has
   one; name the part that fades while the size moves (`content`).
4. **Lay out in `docked(zone)`,** which comes once the window stands (placed, or full screen reached), not in
   `OnSizeChanged` while `window.edge.away` (every step of a motion is a new size).
5. **Search:** `search = function(text)`: `local query = Core.Fuzzy.Query(text)` once, then
   `Core.Fuzzy.Match(query, row's texts...)` per row (nil: hide it; the number: its rank, if the list is
   sorted by it), `Core.Fuzzy.Rank(word, text, nil, spots)` and `Core.Fuzzy.Highlight` only for the rows on
   screen. A list of thousands is ranked a part per frame (a coroutine resumed from a short `OnUpdate` that
   stops when done), never all at once in one frame.
6. **The game's own window** (`native`): `frame` (a function if its addon loads on demand; call
   `window:Attach()` again once it has loaded), `anchor` (optional: where the button back to ours goes on
   the game's window, for one without a close button, such as the chat), `show` and `back` (what else changes when the player
   switches to the game's and back; until Core's holder is built, also hiding ours and showing the game's:
   out of a fight only).
7. **The game's triggers** need nothing of the module once Core's holder is built (section 7): the game
   opens its own window as always, unseen, and Core opens ours (`window:Open()`: `"ours"`, `"native"`, or
   `"locked"` in a fight when ours holds protected frames and is closed). Until then a module follows the
   game by a hook after its toggle and calls `window:Open()` itself.
8. **`close`:** what closing means (end the talk with the game's own call; hide). Without, Core hides it.
9. **`window:Place()`** once it is built.
10. **Settings:** `Core.Edge.Options(list, at, tab)` puts the section *Expand window* (with the corners) into
    the module's switches; a change of one calls `window.edge:Update()`.
11. **Test** with the stand-in client (`dev/tests/window.lua` shows how: frames that know their place, a
    clock that is run by hand, Edit Mode by `EventRegistry:TriggerEvent`), and mark the README *not yet
    tried in the game* until it is.

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
  they open in a fight; Esc by Core's stand-in in `UISpecialFrames`.
- **Load on demand:** the spellbook's addon (`Blizzard_PlayerSpells`) loads when the game first opens it.
  Our code never loads it; it waits (`EventUtil.ContinueOnAddOnLoaded`) to attach its button.
- **Try it in the game with the taint log:** `/console taintLog 1`, `/reload`, the test, then the game
  folder's `Logs/taint.log`: no line where Sane UI's code touched a Blizzard frame or value. The README
  says *not yet tried in the game* until it is clean.

### The holder: ours or the game's (to build in Core)

One way for every window, from Economy's plan (`Doc/ideas/Economy.md`, *Hidden, not closed*), made
Core's: a frame of ours that is never shown, and the game's windows held in it while ours is chosen.

- **Held while closed.** Set to Sane UI, the game's window gets the holder as its parent (`SetParent`; its
  parent, scale and alpha noted in our own table and put back exactly), only while it is not open: at
  login, once its addon has loaded (`EventUtil.ContinueOnAddOnLoaded`), and again each time it closes. The
  game then opens and closes it as always, by its own code: it counts as shown (`IsShown()`), but it never
  comes into sight, so its `OnShow` and `OnHide` do not run (no talk ended, no action bar touched, no bags).
- **Followed.** Hooks after the game's window's own `Show` and `Hide` (`hooksecurefunc(frame, "Show")`;
  every way passes there: its key, a micro menu button, a link, an NPC, Esc) open and close ours. Nothing of
  the game's is taken over or replaced.
- **To the game's** (our title bar's first button, the dropdown *Classic windows*): ours closes; the game's
  window goes back to its parent and comes into sight, so its `OnShow` runs from our code. Fine for most
  windows (the friends list, the guild, a vendor: as if it had just opened). Not for the spellbook (its
  `OnShow` sets the action bars' grids: their buttons are protected, and the fields it writes would be
  tainted) or the map (it does an emote, an API with restrictions): there the button is a secure action
  button (`SecureActionButtonTemplate`, `type = "click"` on the game's own micro menu button) whose
  `PreClick` first closes the held window unseen and gives it back, so that the game's own click opens it,
  as its own code. To prove in the game (a secure button makes our window protected: `window:Locked()` in a
  fight); until then the switch closes the held window unseen and the game's opens at its key's next press.
- **To ours** (the Sane UI button on the game's window, while it is in sight): the game's window is not
  hidden (its `OnHide` would end a talk, or touch the action bars) but made tiny and clear (`SetScale` very
  small, alpha 0: its buttons shrink to a point and take no clicks; the game's panel layout counts its
  scale) until the game closes it; then it is held again. Ours opens at once.
- **The empty place:** the game's panel layout still counts a held window as open (sight is not looked at),
  so another of the game's panels opened beside it stands where it would stand beside the game's. To see in
  the game whether that disturbs.
- **A failure gives the game's back:** if our window fails (`module.Guarded`), the game's window goes back
  to its parent at once (*Resilience*).

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
- **Per step of a motion** only what moves is touched (place, size, the plate's pieces); what the window
  holds is laid out once at the end.
- **Search:** no tables per row (`Fuzzy.Rank` without spots), one pass through a text per look, lower-case
  once per text, spots only for rows on screen, long lists in parts.
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

- Built from Blizzard's parts: the close button (`UIPanelCloseButtonNoScripts`), maximize and minimize
  (`MaximizeMinimizeButtonFrameTemplate`), the search box (`SearchBoxTemplate`), the dropdown
  (`WowStyle1DropdownTemplate`), Edit Mode's selection art (its nine-slice atlases), the title in
  `GameFontNormal`. Sane UI's own: the plate (round corners only on a small window; square in full screen),
  the bronze trim.
- The game's own sounds where Blizzard plays them, by `SOUNDKIT` (a window opening and closing: to come,
  section 8).

### Text

Every word a window shows is in one place per module (`ns.TEXT`), or the game's own string where it has one.

## 8. Not built yet, in order

Each with what is decided and what it needs; the plan has the decisions in full.

1. **The holder** (decided: ours or the game's, Core's job; section 7, *The holder*). Abilities' new spellbook
   window, Economy and Dialogue wait for it. Prove first in the game, with the taint log: a vendor (held,
   opened by the NPC, given back mid-talk), then the spellbook (held, its key, the secure switch).
2. **Click to expand** (decided: [Windows.md](../ideas/Windows.md), *Click to expand, not hover*): the edge
   strip takes the left button (`SetMouseClickEnabled`, `SetPassThroughButtons` for the others) when the
   setting *Click required to expand window* is ticked (Core's section *Hotcorners*, overridden per module).
   Today the mouse's coming alone fills the screen.
3. **Edit Mode's layouts, Save, Revert, Reset To Default Position** (decided; the plan's *Edit Mode* has the
   design, section 9 the facts). In short: a place per layout, keyed `preset:<number>`,
   `account:<name>`, `character:<character>:<name>`; one hook after `EditModeManagerFrame:UpdateLayoutInfo`
   (every way to a layout passes there: login, switching, *Revert Changes*, a new or imported layout),
   `EditMode.SavedLayouts` for *Save*, hooks after `RenameLayout` and `DeleteLayout` (a list of the layouts'
   keys by number, kept from the last `UpdateLayoutInfo`, says what was renamed or deleted). Our moves are
   Core's unsaved changes; Core enables Blizzard's *Save* and *Revert Changes* buttons itself
   (`SetEnabled`, again after each `SetHasActiveChanges`), never Blizzard's flag. Switching the layout or
   leaving Edit Mode with only our changes unsaved asks in Core's own dialog. The store then becomes
   `{ layouts = { [key] = { x, y, width, height, dock } }, full, native }`, today's shape read as the
   first layout's once.
4. **Edit Mode for windows that are hidden outside their use** (a talk window exists only at an NPC; a panel
   may be closed): in Edit Mode Core shows each registered window that is hidden as a preview at its kept
   place and size (its plate and title, nothing inside), so it can be moved and sized there too. Without it a
   talk window can never be sized (sizing is Edit Mode's). Previews hold no zone (invariant 7 counts shown
   windows only): two talk windows kept in the middle show there over each other.
5. **Full screen views: a board per module** (decided, Saneroki agreed to this design 2026-10-16): one full
   screen frame per module (background, the title bar, the dropdown, Esc), and a layout function that gives
   each of the module's windows its rectangle there. Going full screen, each window moves from its own place
   to its rectangle with the same motion (Edge's step, per window), the hidden ones (the friends list) come
   in; the search goes to every window's `search`; back, each returns to its place. What a window holds
   stays its own, so a window looks the same alone and on the board. Core: `Core.Board.New(module,
   { windows, layout })`; Edge's motion generalised from one window to a set.
6. **Opening and closing** with the game's sounds for a panel and a talk window, and the proposal of an
   opening motion (`window:Appear()`, Economy's plan; Blizzard's panels do not animate: open for Saneroki).

Built since the review: the kinds (`kind`, section 2) and one window to a zone (invariant 7), 2026-10-16.

## 9. Facts checked in the references

All in `references/BlizzardInterfaceCode/Interface/AddOns/`, checked 2026-10-16.

| Fact | Where | What it means for us |
| --- | --- | --- |
| Edit Mode announces itself: `EventRegistry:TriggerEvent("EditMode.Enter")` / `("EditMode.Exit")`; `EditModeManagerFrame:IsEditModeActive()` | `Blizzard_EditMode/Shared/EditModeManager.lua` 100-126, 151 | `EditMode.lua` listens; reads the manager once at login |
| Event registry callbacks run sealed off: `secureexecuterange` with `securecallfunction(closure, ...)` | `Blizzard_SharedXMLBase/CallbackRegistry.lua` 198-204 | our callbacks carry no taint into Edit Mode |
| Blizzard's selection box (`EditModeSystemSelectionBaseTemplate`) calls `EditModeManagerFrame:SelectSystem(self.parent)` on a mouse press | `Blizzard_EditMode/Shared/EditModeSystemTemplates.lua` 3291 | never use the template on our frames; Core copies its layout table (local there, 3222) and draws it with `NineSliceUtil.ApplyLayout` on its own frame |
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
| The map's `OnShow` does `C_ChatInfo.PerformEmote("READ")` (an API with restrictions) | `Blizzard_WorldMap/Blizzard_WorldMap.lua` 398 | the map is never shown from our code |
| Camelot's keys: `TOGGLESPELLBOOK`, `TOGGLEPETBOOK`, `TOGGLETALENTS`, `TOGGLEWORLDMAP`, `TOGGLEQUESTLOG`, `TOGGLEGUILDTAB`, `TOGGLESOCIAL`, `TOGGLEFRIENDSTAB` | `Blizzard_FrameXML/Bindings_Camelot.xml` 1211-1256 | the bindings a window of ours takes over by override bindings |
| A mask is stretched whole (no slice margins); a texture takes at most three masks | Tooltips' and Social's experience (`src/Tooltips/Panel.lua`, `src/Social/Plate.lua`) | round corners are a masked piece per corner (`Shape.lua`) |
| `EasingUtil` (`InQuadratic` ... `OutBack`), loaded in every flavour (2026-10-17) | `Blizzard_SharedXML/EasingUtil.lua`; `Blizzard_SharedXML.toc` 33 | `Motion.lua`'s curves, by name; a client without it moves straight |
| Camelot's experience bar: `UI-HUD-ExperienceBar-Background`, `-Fill-Experience`, `-Fill-Prediction` (rested, under the fill), `-Frame-Pip` (hidden within 1 % of an end), `ui-hud-experiencebar-divider`, the flare flipbook (7 x 4, 28 pictures, 32.5 x 10); `STATUS_BAR_NUM_SEGMENTS` 20 (2026-10-17) | `Blizzard_StatusTrackingBar/Mainline/ExpBar.xml`, `StatusTrackingBarTemplate.xml`, `ExpBarOverrides.lua`, `Shared/ExpBar.lua` 130-160, `Camelot/StatusTrackingBarConstants.lua`; `Blizzard_FrameXMLBase/GradualAnimatedStatusBar.xml` | `Bar.lua`'s art, sizes and dividers |
