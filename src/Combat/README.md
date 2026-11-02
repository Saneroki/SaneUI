# Sane UI: Combat

**Status:** its window and full screen built: docked at the bottom middle, the bottom edge's middle half (or your spellbook or talents key) fills the screen with our own spellbook and talents (built), as the game's, on Core's board; quest marks beside nameplates; our own frames for you, your target and your focus in a nameplate's look, with their power bars, the auras that matter most and your aura lists, and rows under them for your target's and focus's targets and your pet (built); the game's action bars clean (built); rings around the mouse for the global cooldown and your cast (built); the threat and damage meter (built); in Retail all of it, the game's own spellbook and talents window standing on the full screen in place of ours (they are Forever's) · **Since:** 2026-10-16 · **Addon:** `SaneUI_Combat` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
The module for everything about the fight: your own frame, your target's (and its target's), your
focus and your pet, the party and the raid, your buffs and debuffs, and what goes with them (cast bars,
totems, bosses). Each part, once built, gives the game's own frame back when it fails. The plan is in
`Doc/ideas/Combat.md`; the nameplates are a module of their own (`src/Nameplates/`).

Built so far: its window, docked in the screen's bottom middle. Push the mouse against the middle half of
the bottom edge, or press your spellbook or talents key, and it fills the screen with our own spellbook and
talents windows, which look and work as the game's, on Core's board that you arrange; push there again, press
the key again, or Esc, and it goes back. A talent planner Sane UI knows is a window of its own there.

Your frame, your target's and your focus's are ours, in the look of a nameplate and green: the level and raid
marker on the left, then the name (none on your own), the health and how much is left on the right. Under your
target's and focus's frames, as a cast bar under a nameplate, a row with the name of their target; under yours your
pet, with its health and its resource. Directly above each health bar its unit's cast while it casts. Your breath
lies over your health bar, in the game's bubbles, half see-through, the game's other timers on you stand above your
cast: none of the game's own bars is left. The game's action bars are clean: only the buttons that hold something, each its icon alone. Its experience and stance bars are gone, and its menu bar shows only while the mouse is on it. At rest your unit frames and the action bars are out of sight: they show with the mouse on them, while your health or your resource is not full, in a fight and in a group.

Your party and your raid are one frame of ours, in place of the game's two: unit frames edge to edge, up to forty, in the
nameplates' look, sized to fit the limits you set in Edit Mode. On every health bar of ours, these and the unit frames, you see
barriers, maximum health lost for a while, and what can be dispelled (Core's health marks, on the nameplates too).

Around the mouse, only while they run, two see-through rings: the global cooldown and your cast, a bright line with a soft glow leading
the cast's. They go around the whole picture of the cursor, so it stands in their middle, and start and end at its tip.

The threat and damage meter: your party or raid, you on top, each with their class, level, item level and name and
a thin bar each for threat, damage, healing and interrupts. No title bar and no background, and clicks go through
it; the mouse on it brings its buttons.

Click a buff or debuff, or right click a spell in the spellbook, and mark it: *Important* (the game's golden animated outline, first on the unit frames), *Unimportant* (faded,
never on the unit frames) or *Hidden* (out of the game's list until the mouse is on it); for the unit frames alone,
with no glow or fade, *Show on unit frames* or *Hide from unit frames*. Or choose *Create reminder*: its
icon then shows on an invisible reminder bar, placed in Edit Mode, while its settings want it; a bar is as wide as what
shows on it, and you make as many bars as you like.

## How to use
- **Switch it on or off:** tick or untick *Combat* under *Sane UI* in the game's addon list.
- **The full screen:** push the mouse against the bottom edge of the screen anywhere in its middle half
  (a quarter of the screen's width either side of the middle). Push there again, or press Esc, to go back.
  Not in Edit Mode, and not with *Can expand to fullscreen* off (*Sane UI > Combat > Expand window*).
- **Your keys:** the keys you gave the game's spellbook (P), pet spellbook and talents (N) open the full
  screen with that window on it (the pet's: the spellbook at the pet's tab; without a pet, as the game's, it does
  nothing), and close it again, as they do the game's windows. Your key bindings stay as they are; *Your spellbook and talents keys open ours* off,
  they open the game's own windows again. In the game's key bindings, under *Sane UI*, Combat's own keys for
  the same, to put on other keys.
- **The spellbook:** the game's book, at its size and in its art, scaled to fit its window: both pages where
  the window is wide enough, one page where not (the game's book minimized).
  - A tab per skill line at the top left (the class's, General, professions) and the pet's while your pet has
    spells; each tab's spells under its heading, laid out on the pages as the game's book lays them out; the
    page controls at the bottom right, or the mouse wheel.
  - Each spell as in the game's book: its icon in the game's frame (round for a passive), name and rank, a
    spell still to learn greyed with the level it comes at or *Trainable*, the cooldown, the glow of a spell on
    none of your action bars, a pet ability's autocast, the tooltip.
  - **Click** to cast it, **right click** for its menu, as a buff's (below, *Your buffs and debuffs*: a reminder and your marks of its aura; on a pet ability it switches its autocast), **drag** it onto an action
    bar, **Shift-click** to link it in chat (or to pick it up, as your game's modified clicks say).
  - **In a fight** the book shows, pages and drags as always, but a click does not cast (it says so): cast from
    your action bars then. After the fight, a click casts again.
  - At the top right the game's own settings for its book: *Hide passives*, and *Show all ranks* (not for
    rogues and warriors); they change the game's book too. The full screen's search box finds spells of every
    tab. Flyouts are shown as their spells, one by one (as the game's book with *Use flyouts* off).
- **The talents:** your three talent trees as the game's window shows them in this client, at its size and in
  its art, scaled to fit. Each tree's head shows the points spent in it, the box at the top right your unspent
  points. **Click** a talent to learn a rank, **right click** to take one back (**Shift**: with the talents that
  need it); a choice opens its options. Changes wait: **Apply Changes** applies them (a short cast, shown over
  the trees), the round button beside it undoes them, and with nothing waiting it is **Reset** (class,
  specialization or all). The tabs *Primary* and *Secondary* show either specialization; the inactive one is
  only to look at, with **Activate** to switch. Not in a fight. The full screen's search box marks the talents
  it finds. Before your first talent point it says from which level.
- **The talent planner:** with a talent planner Sane UI knows installed, the dropdown *Windows* has it: ticked,
  it gets a window of its own on the board, opens with it and closes when it goes. Opened any way of its own
  while its window is on the layout, it brings the full screen.
- **Arranging them:** as on every board of Sane UI's. Drag a window's head onto another to swap them or put it
  above, below or beside it; drag the gap between them to share the room anew; the X takes a window off, the
  dropdown *Windows* puts it back. Layouts are tabs after the title: *+* makes one, a right click renames it,
  resets the first or deletes another.
- **The game's own windows:** the full screen's dropdown *Classic windows* has *Spellbook* and *Talents*: the
  full screen goes back and what opens the game's is said: its key, or, while your keys open ours, its button
  in the micro menu (our code does not open the game's spellbook). The game's spellbook has the button *Sane UI*
  left of its sizing button: the game's closes and this full screen comes, with our spellbook or talents.
- **Quest marks beside nameplates:** a creature that belongs to a quest in your log shows a small mark left of
  its nameplate while an objective of it is still to do: a sword to kill it, a sack to loot it, with the count
  still open ("3/8"). It goes once the objective is done. As the game says it in the creature's tooltip; a
  creature the game says nothing about has none. *Quest marks on nameplates* switches it off.
- **Unit frames:** your own frame, your target's and your focus's, in place of the game's, in the look of a
  nameplate: a round green bar (the game's green for health, for everyone: no class colours), and under it the
  unit's power in a bar half as high, in the game's colour for it, with the power and how much is left on its
  right ("2.4k | 80%"). A druid's own frame has two: mana always, and under it energy or rage while in a form;
  so does yours in a specialization whose power is not mana but who has mana too. Inside the health bar, on the
  left the level (coloured by how hard the unit is to you, a skull
  where it is too high to tell) and the raid marker beside it; then the name, from the left, a player's first
  name and surname (none on your own frame); on the right the health and how much is left ("850 | 85%"), *Dead*
  or *Offline* where it is so. An elite has a gold line inside its border, a rare a silver one, a boss a thick
  gold one; the frame glows red while you have the unit's aggro (your own: while anything is after you) or while
  it is a player who may attack you. Every frame is the same width, whatever it shows: 240 at 100 % (*Unit frame
  size* scales all three alike); only the glow reaches beyond its edge.
  - **Auras:** the three that matter most of each kind, in one line above the frame: buffs on the left, from its
    edge (on a foe those the game shows on its own plates, on a friend or you any, big defensives first), crowd
    control in the middle, centred, debuffs on the right, from its edge (on a foe the ones you put on it, on a
    friend or you any, what you can dispel and a boss's first). **Click** an icon, out of a fight, for its menu: *Important* (in front of the
    rest, whoever cast it, with the game's golden animated outline), *Unimportant* (never here), *Hidden* (only the game's list, *Your buffs and debuffs*), *Show on unit frames* (in front of the rest, no glow), *Hide from unit frames* and *Aura lists...*, a window with the lists side by side: type a
    spell's number (or a name of one of your own spells) and choose a list, or take a spell off with its X;
    `/sane auras` opens it too. The game lets the lists act here on the buffs of you, your group and friendly units and
    on the debuffs of foes; on the rest it decides itself (and in a fight it keeps the icons from addons: their
    menu comes after it).
  - **The rows under them**, as a cast bar hangs under a nameplate: while your target has a target, a row under
    your target's frame with that one's health, in the light yellow the nameplates give a neutral creature, and its
    name alone in the middle; the same under your focus's frame for your focus's target, and under your own frame
    for your pet while you have one (green, its resource under it). The frame's outline goes
    round both, a thin dark line between them. Click a row to target its unit, right click for its menu.
  - **The health bar stays put:** it is every frame's anchor. Whatever comes or goes around it, it stays exactly
    where it is; only the frame's outline reaches further up or down.
  - **Casts:** part of each frame while its unit casts (yours, your target's, your focus's), in the same outline,
    directly above the health bar: the spell's icon and name, the seconds left at the right end, filling as it goes
    on and emptying for a channel, grey where it cannot be interrupted, red with who did it when it is interrupted;
    a moment after it ends it goes, so the frame does not jump between two casts. The auras above the frame move up
    while it shows. Your pet's row has none: its button cannot move in a fight, and your power bar stands right above it.
  - **Your breath and the game's other timers:** your breath lies over your health bar, in the game's bubbles and
    half see-through, so your health shows underneath, *Breath* and the seconds left in the middle. Fatigue in deep
    water and feign death stand above your cast, in the game's art for each: what it counts and the seconds left.
    None of the game's own bars shows: not its cast bar (over the vehicle bar and the game's talents window too),
    not its three timers at the top of the screen.
  - **Click** one to target the unit, **right click** for the game's menu of it, the mouse over it for its
    tooltip; in a fight too. Your target's and focus's frames come and go with them.
  - **Placing them:** in the game's Edit Mode, like the game's frames; at first you left of the screen's bottom
    middle, your target right of it, your focus above your target. A frame or row whose unit is not there shows
    a sample there (your own, named *Target*, *Focus*, *Target's target*, *Focus's target* or *Pet*); the rows
    move with their frames. Every frame shows a sample cast, yours a sample breath too. The game's
    own Edit Mode boxes *Cast Bar* and *Timer Bars* only show the game's bars there, which stay away in play.
  - With the game's target and focus frames go what hangs on them: their auras, their cast bars and their own
    target's frames (Forever's combo points show on your target's nameplate). The game's pet frame goes while your
    pet's row is on. Of the game's own frame only its picture, bars and texts go: its totems and a class's
    resource bar stay where it was, moved in Edit Mode by the game's box *Player Frame*.
- **Action bars:** the game's bars, placed and set up in its Edit Mode as always, without any border,
  decoration or background: no frame, end caps or dividers on the bars, no frame or slot on a button. The main
  bar's page number and its arrows stay, to see and change which bar shows. Only the buttons that hold something show, each its square icon alone; the mouse over one, a press and
  an active action are a soft wash over the icon. While you drag something onto the bars, and in Edit Mode,
  every button shows, an empty one as a dark square to drop on. The reservations of Abilities still show on
  their empty buttons.
- **Settings:** *Sane UI > Combat*: *Your spellbook and talents keys open ours*; the section *Unit frames* (*Your
  frame*, *Your cast bar*, *Your breath bar*, *Your pet*, *Your target's frame*, *Your target's target*, *Your
  focus's frame*, *Your focus's target*, each off for the game's own, *Unit frame size*, *Hide the unit frames at
  rest*, *Auras on the frames*); the section *Action bars* (*Clean action bars*, off for the game's look; *Hide the
  action bars at rest*; *Hide the game's experience and reputation
  bars*, *Hide the game's stance bar*, *Menu bar on mouseover*); *Quest marks on nameplates*; the section
  *Expand window* (whether it fills the screen, its kind of motion, the background's opacity and texture) and
  *Window corners*.
- **In Retail:** our spellbook and talents are made after WoW: Forever's, which Retail has not, so neither is
  there, and the full screen holds the game's own window of both, with its own tabs (Saneroki, 2026-11-02: Retail is
  only the testing platform until Forever's launch, nothing new is built for it alone). Your spellbook and talents
  keys and the micro menu open it as always, and the full screen comes with it; closed, the full screen goes back.
  The bottom edge brings the full screen, and a click on its panel, or the key, opens the window: a push is no
  click, and only a click or a key lets the game open its window as its own. Pushed back, the window stays open at
  its own place. There is no switch *keys* there. The rest works as in Forever (Retail's names have no surname: a
  player's name alone). Combat's own keys still stand in the game's key bindings (the game reads `Bindings.xml` in
  both games) and do nothing there.

- **Your party and raid:** one frame of ours for both, in place of the game's party and raid frames (*Party and raid
  frames*, off: the game's). It fills from its bottom left corner: you and your party going up, five to a column, then a
  column to the right for each group of a raid, up to forty, the units edge to edge. Nothing is drawn around it in play: only the
  unit frames show; in Edit Mode it has the box every window has. Each unit: the raid marker and the name on the left with as much room as
  there is; a tiny mark of a tank's or healer's role in the top left corner, a shield or a plus without a ring, centred on the raid marker's place, in front of the bar and
  behind the name and raid marker (by the role the game was told, or a main tank). Floating big over the left of the frame, so they are easy to see, with the name going on behind them: the type icon of a
  dispellable debuff (the game's, a green drop for poison and so on), the ready check while one runs and its result for a while after, the
  game's icon of a resurrection on its way, each moving aside for the one before it; how much health is left on the right ("85%";
  nothing on a frame narrower than 80, where the name gets it too; Dead and Offline always). A dead unit's bar is full and red, an offline
  one's full and grey, and who has an enemy's aggro has a solid red border instead of the black one, as far as the game tells it in a fight. A
  tank's or healer's mana as a line inside the bar, so the frame is no taller for it (with no roles set, a class that can heal or a main
  tank; a unit without mana its own power); an icon floating over the name, which goes on behind it, for each of your class's buffs it
  is missing (*Your missing buffs*: any priest's Fortitude counts, the
  group versions too; of a paladin's blessings only your own; a shout only in your own party; in a fight they stay as they were,
  as the game hides auras then). A unit out of your reach is fainter. A click targets, a right click opens the game's menu,
  hovering shows its tooltip with the whole name, and `@mouseover` macros work on it. Alone, your own frame is all there is.
  Hover and click are the game's unit button's: nothing of ours takes the mouse from it.
- **The group's tools:** your own slot among the frames is a frame like all the others, with its health, marks, buffs and everything else.
  Two things differ: its name is the word *Party* or *Raid*, and a cog always stands at its far right, where another frame has its health in
  words (your slot never shows those). The cog opens a small
  panel, in a fight too, in place of the game's raid manager at the screen's edge, which is gone: *Ready Check*, *Role Check*, *Countdown*,
  *Make Everyone Assistant*, the raid markers on your target and on the ground (click one to set or take it off, the last clears them
  all), *Group menu* (the game's menu of you: converting to a raid or party, difficulty, and more), *Leave Group*. Who may use what is the
  game's rule. Esc or its close button closes it. *Restrict pings* and the game's filters for its own raid frames are not in it.
- **Its sizes and preview:** in Edit Mode, click the frame. Core's dialog has its *Max width*, *Max height* and *Max unit width*,
  and a field *Preview units*: type a number and that many made-up units show, your own slot first, with random health, mana, raid
  markers, ready checks, aggro, the dead and offline, missing buffs, barriers, lost health and dispels; they stay the same while you
  slide the sizes. A slot is a fifth of the max height high, whoever is there, so five fill the window even with three in the party. It is as
  wide as the max unit width (at first as wide as your unit frames), and only where the columns in use would not fit into the max width do all
  share that width evenly. Sizes change out of a fight: in one, a member who joins shows at the size in use.
- **Barriers, lost health, dispels:** on your unit frames and your party and raid frames (*Barriers*, *Lost maximum health*,
  *Dispellable debuffs*, each its own switch; the same three on the page Nameplates for the plates). A barrier is the game's shield
  art on the bar: after the health while it fits, pushed against the bar's right end when it does not, always as long as it is.
  Lost maximum health: the health bar ends earlier, the rest is the game's hatching. What you or your group can take off a unit (on a
  foe, a buff you can remove): the game's icon of its type, big, floating over the left of the health bar (on a nameplate, above its right end).
- **Rings around the mouse** (*Global cooldown*, *Your cast*, each its own switch on the page Combat, both on at first): the inner, thinner ring,
  in white, fills while the global cooldown runs; the outer one, in your class's colour, fills while you cast and empties while you channel, a bright
  line with a soft glow at its head. See-through, there only while they run, gone at once when the cast is interrupted. They stand around the cursor
  you see, start and end on the line to its tip, and grow with the game's *Cursor Size* (Accessibility).
- **The threat and damage meter** (*Threat and damage meter* on the page Combat, the button on the full screen's bar or
  `/sane meter` switch it, on at first), in place of the game's own damage meter:
  - **When it shows:** the cog's section of that name, all three on at first. *Hide outside combat*, *Hide when not in
    group*: out of sight while that is so. *Show on mouseover*: while it is hidden, the mouse on its place brings it,
    buttons and all; off, it comes only with a fight or a group. On Combat's full screen, in Edit Mode and with a saved
    fight loaded it always shows.
  - **Where:** at first at the very top of the screen, right of the quest log's first place. On Combat's full screen in
    its top left corner, each with its own place and size, kept. In Edit Mode, or with the mouse on it: drag the first
    line to move it, as the quest log's title bar does, it docks at the edges too; its corner's grip sizes it.
  - **The list:** a line per character with the class's icon, level, item level (`-` until it could be read: the game
    gives it only near a player, out of a fight) and name, and under it the bars. You stand on top, always in sight;
    only as many as fit whole show, and the mouse wheel over the window takes the others one at a time under your line. In the screen's
    top half the list hangs from the window's top and grows down, in the bottom half it stands on its bottom and grows up.
  - **The bars:** left to right, in the colour of what they count, its word in the bar and on the right its numbers: per
    second and the fight's total (interrupts: how many). A bar's length is the total against the highest of the fight;
    threat's, while you have a mob as your target (or a boss is there), the share of that mob, up to the point of taking its aggro.
  - **Its buttons**, with the mouse on it, at the right end of the first line: the arrows and the page's number between
    them go through the fights the game holds (the last page is the live one; a new fight goes back to it); the note
    opens *Saved fights*; the cog the ticks: *My self on top*, *Show Threat*, *Show Damage*, *Show Healing*, *Show
    Interrupts*, *Reset on new combat*, and *Order by* (DPS, HPS, Threat, Interrupts, Total damage, Total healing).
  - **One character's own bars:** with the mouse on the window, right click a name: their own flyout, with *Show Threat*,
    *Show Damage*, *Show Healing* and *Show Interrupts* for them alone, whatever the cog's ticks say, kept for this account.
    The window set to threat alone can so show one member's damage too and another's healing, or leave a bar off one
    character. *As the window's ticks* takes their choices back. Your own line too, and in saved fights.
  - **Reset on new combat:** ticked, the live page is this fight alone and every number starts at nothing; unticked it
    is all fights added up. The fights' own pages stay either way.
  - **Saved fights:** *Save this fight...* keeps the fight shown under a name of your own, for this account, in a group
    or not. Asked in a fight, it is saved when the fight ends. Each saved fight has *Load* and *Delete*; a loaded one
    shows its people as they were, until an arrow, *Back to the fights* or a new fight.
  - **In a fight** the game hides these numbers from addons: they show, but the list goes by the places on the game's
    own list. On a boss it hides threat too: there you see the share alone, and threat is neither added up nor sorted.
- **Your buffs and debuffs** (the page's tick *Marks and menu on the game's list*): the game's own lists at the top of the
  screen stay, with your marks on them. **Click** one for its menu: *Create reminder*, and a tick each:
  - **Important:** the game's golden animated outline around it, as on a spell it wants you to see; on the unit frames it comes first, with the same outline.
  - **Unimportant:** faded to 25% of its strength; never on the unit frames.
  - **Hidden:** out of sight, and last in the list, so it leaves no hole; it shows while the mouse is on the list.
  - **Show on unit frames**, **Hide from unit frames:** the unit frames alone: first there without a glow, or never there,
    the list as it is. They go over the three above: *Important* + *Hide*: a glow in the list, not on the frames;
    *Unimportant* + *Show*: faded in the list, first on the frames, no glow. Hidden can have either.
  - A mark goes by the aura's name, so any rank of it. Click the tick again to take it off, or use `/sane auras`.
  - **A right click** cancels a buff, as in the game.
  - **In the spellbook** a right click on a spell opens the same menu, for the aura the spell gives: of a spell that hurts, a
    debuff on your target; else a buff on you. So it can be set up with the aura gone, in a fight too. A right click there
    casts nothing any more. The unit frames know a spell by its number: there it is the rank you marked.
  - **In a fight** the game hides what a button shows: an aura you had before the fight keeps its mark, and its menu opens,
    where the game tells its instance; what came during the fight the menu cannot name, and says so. Where the game does not
    tell the instance, the list shows plain from its first change until the fight ends.
- **Reminders** (the page's tick *Reminder bars*, `/sane reminders`):
  - **Making one:** click a buff or debuff of the game's at the top of the screen, or an icon above a unit frame (out of a
    fight), or right click a spell in the spellbook, and choose *Create reminder*; the window opens on it. An aura with a reminder says *Edit reminder*
    and *Delete reminder*.
  - **Its settings**, each at once: which bar; *Display when missing*; *Display when active*; *Offset time*, with
    missing: so many seconds before it runs out it shows already, with the seconds left on the icon; *Combat*: in and
    out, *Only show outside of combat* or *Only show inside of combat*; *Don't show in resting areas*. Never while you
    are dead. A reminder belongs to the character and watches the aura by name, so any rank of it, on you or on the
    unit it was made on (your target, your focus).
  - **The bars:** one at first, more by *New bar* in the window, each with its own reminders (the dropdown on top shows a
    bar's, *Bar* moves a reminder to another). *Delete bar* puts its reminders on the first bar left; the last bar stays.
    Invisible, only the icons of what shows now, side by side around the bar's middle, no glow. Placed in Edit Mode, where
    every bar stands with all it holds. Nothing on them takes the mouse.
  - **In a fight** the game hides most auras from addons. What was on stays known: when it goes the reminder shows at once
    and the offset counts on. What comes during a fight the game does not tell, except your own cast where it lets that
    through; else a reminder that shows stays until the fight ends.

## Technical details
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked at `BOTTOM` at first,
  `Window.WIDTH` x `Window.HEIGHT`, not sizable, see-through and empty while small (no mouse); in Edit Mode
  its box, to be docked elsewhere. Core's option `strip = Window.STRIP` (0.5): the strip that fills the
  screen is half the screen's side, in its middle, whatever the window's width (Core's `Edge.lua`; its
  length follows `DISPLAY_SIZE_CHANGED` and `UI_SCALE_CHANGED`). `docked`, once it stands full, lays the
  board out (`Board.Show`); `filled` on its way back, and `docked` at rest, take it away (`Board.Hide`).
  `Window.Open(key, tab)` fills the screen with that window on the layout (`Board.Add`, once it stands: Core's
  board adds one only then) and the book at that tab; `Window.Toggle` is that, or back to its size where that
  window is shown already (the keys). What is typed into the full screen's search box goes to the board's
  windows (its option `search`, `Board.Search`); a tab of the book chosen closes it (`Window.ClearSearch`,
  `window:EndSearch()`). Its option `classic` lists the game's spellbook and talents for Core's *Classic windows*
  (`Core.Classic`): `show` says what opens the game's (`Classic.Press`, the binding's name, or none while
  `Keys.Taken()`), `ours` is `Window.Open` of ours.
- **The board** (`Board.lua`): Core's (`Core.Board.New`, kept in `store.board`: layouts behind tabs, a panel
  per window with its head, X and body, the dropdown *Windows*), a registry of parts in files of their own
  (`Board.Part(key, title, least, part, wants)`; a part has `Build(panel)`, `Show(on)`, `Size(w, h)`,
  `Search(text)`, `Present()`, `Leave()`, as Inventory's). `Board.ORDER`: `talents`, `spellbook`, `planner`; the
  dropdown lists those `Present` now (`Board.Present`). The first layout: `Board.FIRST` side by side, the shares
  the game's sizes of their windows (`wants`: the talents' 1218 x 708, the book's 1612 x 702).
- **The spellbook** (`Book/`): our own frames, in the game's art and words, after Camelot's
  `Blizzard_PlayerSpells` (`SpellBook/` and `Camelot/SpellBook/`); the game's own `PlayerSpellsFrame` and its
  templates are not used (the game's entry casts from its own click, `C_SpellBook.CastSpellBookItem`, protected).
  - `Book.lua`, the part: a holder of the game's size (`Book.WIDE` 1612 or `Book.NARROW` 806 x `Book.HIGH` 702),
    scaled to fit its body (`min(1, ...)`), centred; both pages while they can be `Book.TWO` of one page's
    scale (`spellbook-Page-Left-C60`, `-Right-C60`; one page: the right page's art whole). Square icon tabs at
    `Book.TABS` (`spellbook-Tab-Frame-C60`, `-Glow-C60`, `-glow-gradient-C60`, the icon masked by `SquareMask`,
    44 x 32, the game's sound `IG_SPELLBOOK_OPEN`), the views at the game's places (`Book.VIEW_*`), the game's
    `PagingControlsHorizontalTemplate` at `Book.PAGER` (made in our code, it asks its frame's `OnPageChanged`),
    the mouse wheel, and the game's `UIPanelArrowDropdownButtonTemplate` at `Book.SETTINGS` with the CVars
    `spellBookHidePassives` and `ShowAllSpellRanks` (no menu tag: other code's lines for the game's book menu
    stay out). Events only while shown (`Core.On`/`Off`), each burst once a frame (`Core.Later`): the tabs and
    pages anew on `SPELLS_CHANGED`, `LEARNED_SPELL_IN_SKILL_LINE`, `PLAYER_SPECIALIZATION_CHANGED`, `UNIT_PET`; the
    page's entries on `SPELL_UPDATE_COOLDOWN`, `ACTIONBAR_SLOT_CHANGED`, `CURSOR_CHANGED`,
    `UPDATE_SHAPESHIFT_FORM`, `PET_BAR_UPDATE`; the secure buttons with `PLAYER_REGEN_DISABLED`/`_ENABLED`.
  - `Data.lua`: the tabs as the game's Camelot book makes them (`C_SpellBook.GetNumSpellBookSkillLines`,
    `GetSpellBookSkillLineInfo`, not `shouldHide`; General with `GetClassSkillLineInfo`'s icon; the pet's while
    `HasPetSpells` and `PetHasSpellbook`, `GetPetIcon`), each one group under its name; the game's filter
    (`SpellBookFrameMixin:ShouldDisplaySpellBookItem`) with flyouts loose; `Data.Search` over name and rank in
    every tab.
  - `Layout.lua`: the game's paging rules (`PagedContentFrameBaseMixin:ProcessElement`, the condensed vertical
    grid), with Camelot's numbers: views 680 x 590, three columns 15 apart, rows 10 apart, headings and entries
    60 high, groups 20 apart, column by column in `ceil(n / 3)` rows, never a heading alone at a view's foot.
  - `Item.lua`: an entry as `SpellBookItemTemplate` draws it (220 x 60, the button 40, the icon 36; the art sets
    `Item.ART`, Square and Circle, with the game's border anchors; `SPELLBOOK_FONT_COLOR`,
    `SPELLBOOK_UNLEARNED_TINT_COLOR`, `SPELLBOOK_AVAILABLE_AT`, `SPELLBOOK_TRAINABLE`, `SPELL_PASSIVE`), the rank
    from `Spell:ContinueWithCancelOnSpellLoad` where the game has none; the cooldown by
    `GetSpellBookItemCooldownDuration` into `SetCooldownFromDurationObject` (a secret value in a fight is taken
    as it is); the glow by `ActionButtonUtil.GetActionBarStatusForSpell`/`ForPetAction`
    (`MissingFromAllBars`, not auto attacks), its tooltip line `TALENT_BUTTON_TOOLTIP_NOT_ON_ACTION_BAR`;
    autocast by `GetSpellBookItemAutoCast`; `C_LevelLink.IsSpellLocked`; tooltip `SetSpellBookItem`; drag and
    `PICKUPACTION` by `PickupSpellBookItem`, `CHATLINK` by the item's (trade skill) link. Nothing of the game's
    action bars is written (no highlight marks).
  - `Casts.lua`: the cast. `SecureActionButtonTemplate` buttons on UIParent, each over the icon of a castable
    entry (`Item.Castable`: a learned spell, a pet ability), in UIParent's units, `Book.LEVEL` above the panel's
    body: `type` `spell` and `spell` the spell's ID (the rank it is); a pet ability `macro`, `/cast` its name and
    rank where it has one (`Bite(Rank 2)`), the right click `/petautocasttoggle` where it may autocast;
    `checkselfcast`, `useOnKeyDown = false`, no cast on Shift (`shift-type*` empty: `PostClick` links or picks it
    up). Made, set, placed, shown and hidden out of a fight only; all hidden at `PLAYER_REGEN_DISABLED` (the game
    locks them after it), set again after `PLAYER_REGEN_ENABLED`. Not in our window, so the full screen never
    becomes protected.
- **The talents** (`Talents/`): the game's shared talent frame (`TalentFrameBaseTemplate`,
  `Blizzard_SharedTalentUI`, loaded with `C_AddOns.LoadAddOn` in a `pcall` where it is not yet) inherited, as the
  game's class frame inherits it; the class layer the game's window adds lives in `Blizzard_PlayerSpells`, which
  is never loaded, so it is ported: the frame's keys, layers, gates, events and the game's talent search
  (`ClassTalentSearchMixin`, `Tree.lua`), the nodes' templates and the class glow, tooltip and sounds
  (`Nodes.lua`), the class's background, clouds, lights, frame and dividers (`Art.lua`), the trees' heads
  (x = 140 + 400 (i - 1), y = -100; `C_Traits.GetGroupCurrencyInfo`) and the unspent points (`Headers.lua`), the
  dual-spec tabs (the game's `TabSystemTemplate`, `GetCombatConfigIDForSpecGroup`, `SetActiveSpecGroup`;
  `Specs.lua`), Apply, Undo and Reset (`Foot.lua`; `C_ClassTalents.CommitConfig`, `C_Traits.RollbackConfig`,
  `ResetTreeByCurrency`, `PurchaseRank`, `RefundRank`, `SetSelection`; `Changes.lua`), the commit's cast on a cast
  bar of ours from the game's `CastingBarFrameTemplate` (`ApplyingTalents`, run with your casts only while a
  commit or switch is under way; the game's spinner after half a second without one; `Commit.lua`). The art
  (1212 x 701) scaled to fit the panel's body, centred (`Talents.lua`). Every method of ours on the frame and
  every script the game's templates gave our frames is behind the module's guard (`Talents.Wrap`); nothing of
  the game's window, casting bars or tables is written. Changes only on the active specialization and out of a
  fight; Apply as `C_ClassTalents.CanChangeTalents` says. Zoom and pan off; events only while shown. Left out
  as the Camelot window has them not: loadouts, starter builds, hero talents, inspecting; also the node sheen,
  the purchase effects and the action bars' marks (they write the game's bars).
- **The keys** (`Keys.lua`, `Bindings.xml`): Combat's keys `SANEUI_COMBAT_SPELLBOOK`, `_PETBOOK`, `_TALENTS`
  (Sane UI's section in the game's key bindings) run `Keys.Press` (`Window.Toggle`; the pet book's only while
  `BookData.HasPet()`, as the game's key opens its book only at the pet's tab). `SetOverrideBinding` on a
  frame of ours puts them on the keys of `TOGGLESPELLBOOK`, `TOGGLEPETBOOK`, `TOGGLETALENTS`
  (`GetBindingKey`): at the login, on `UPDATE_BINDINGS` when those actions' keys changed, cleared
  (`ClearOverrideBindings`) with the switch `keys` off and at standing down; out of a fight only (else after it,
  `Core.AfterCombat`).
- **The planner** (`Board.lua`; Core's `Neighbours.lua`, the one file that names the addons Sane UI knows): the
  part `planner`, present while `Core.Neighbours.Window("talents")` gives a handle. Its panel shown, the planner
  is opened by its own function and seated in the body (Core's `Seat.lua`: only its place, scale and layer lent),
  a frame later (`Core.Later`); the panel hidden, given back and closed. Its opening followed once, from the
  login or when its addon is first there: while its panel is on the layout, the full screen comes.
- **Mouse rings** (`MouseRings.lua`): a hidden holder at the `TOOLTIP` strata with two `Cooldown` widgets, their swipes Core's rings
  (`Shape.RING`, `RING_WIDE`) in `Rings.ALPHA`, both turned by `Rings.TURN` so they start and end on the line from their centre to the cursor's tip
  (the widget turns clockwise, a texture the other way). Above them a frame with the leading line and its glow, the game's cast bar spark twice, added
  to what lies under it, placed on the band's middle each frame from the cast's plain start and end, none where those are hidden. The holder comes
  out when a ring starts, follows
  `GetCursorPosition` on its `OnUpdate` and goes when neither ring is shown, so nothing runs at rest. Where it stands: the game's cursor hangs from its
  tip at the top left corner of a square picture, so the rings' centre is `Rings.MIDDLE` of a side right of and below the tip, and the inner ring's
  hole holds all 119 of the game's cursor pictures of that size whole (measured on the art, the widest is the sword). Everything is in that side, in
  real pixels turned into UI units (`768 / physical height / effective scale`): `cursorSizePreferred` 0 to 4 is 32, 48, 64, 96, 128; -1, *Default*, the
  largest of them `GetScreenDPIScale` reaches. Measured when the holder comes out, so nothing listens for a change. The global cooldown: on
  `SPELL_UPDATE_COOLDOWN` the game's answer for `Rings.SPELL` (61304, Retail's spell for it; Forever's tables lack that spell, so 29515, of no class
  and on that cooldown alone), `isActive` never hidden; its seconds, where they may be read, tell a school locked by an interrupt from it
  (`Rings.LONGEST`). It goes in as `C_Spell.GetSpellCooldownDuration`'s object, as the widget takes hidden numbers only from Blizzard's code. A cast:
  `ns.UnitCast.Read("player")` on `Cast.EVENTS`, read anew each time (a delay moves the ring, what you tried while casting leaves it); `SetCooldown`
  from its plain start and end, `SetReverse` so a cast fills and a channel empties; hidden, `UnitCastingDuration`/`UnitChannelDuration` through a
  `pcall`, no ring where the game refuses that. A failing ring is told once and leaves the module up (`ns.Safe`); a ring off hears nothing.
- **Quest marks** (`QuestMarks.lua`): on `NAME_PLATE_UNIT_ADDED` a frame of ours on the plate the game gives
  (`C_NamePlate.GetNamePlateForUnit`: none for a forbidden plate; none for players), left of its health bar
  where it has one (its fields read with `rawget`, never written), one per plate, kept while it shows.
  `QuestMarks.Read` is Core's `Core.UnitQuest` (`src/Core/Objectives.lua`): `C_QuestLog.UnitIsRelatedToActiveQuest`
  first, then the tooltip data's lines of the kind `QuestObjective` (`C_TooltipInfo.GetUnit`): the first not
  `completed` and not full ("8/8") is the mark, the sword (`Interface\CURSOR\Attack`) where its text names the
  creature, else the sack (`Interface\CURSOR\LootAll`), the count left of it. None while the module Nameplates runs
  (`SaneUI.Nameplates`, not stood down): it shows the same inside its bar. A secret value (a fight) leaves the mark as it was.
  Looked at again on `QUEST_LOG_UPDATE` and `UNIT_QUEST_LOG_CHANGED`, once a frame (`Core.Later`).
- **Forever and Retail** (`Combat.lua`, `ns.Serves(key)`): each of our windows is there only in a game that has
  what it is made after, asked for itself: the spellbook where the game's book holds its flyouts' spells loose
  (`C_SpellBook.IsSpellBookItemLooseFlyoutMember`; its art, `spellbook-*-C60`, is that game's too), the talents
  where each specialization group has its own config (`C_SpecializationInfo.GetCombatConfigIDForSpecGroup`). Both
  are Forever's only. A window that is not there is no part's `Present()` (`Talents.Present`, `Book.Part.Present`):
  not in the dropdown *Windows*, not in the first layout (`Board.FIRST`, those present), not in *Classic windows*
  (the entries' `window`), and its keys stay the game's (`Keys.Bind`, `Keys.Taken(action)`, `Keys.Press`). With
  neither (`ns.Serves()`), the switch *keys* is not described, and the board's window is the part `game`.
- **The game's own window on the full screen** (`GameWindow.lua`, the part `game`, present where `ns.Serves()` is
  false): `PlayerSpellsFrame` seated in the panel's body (`Core.Seat`), never shown or hidden by our code (its
  `OnShow` and `OnHide` set the action bars' grids, its book writes which spell each entry casts:
  `Doc/guides/windows.md`, *Taint*). The game's registry event `PlayerSpellsFrame.OpenFrame` says it opened, by any
  way: `Window.Open("game")` brings the full screen, or the panel if full. Closed while seated, the seat's `gone` is
  `Window.Back`. The closed panel says the key and holds a secure click (`SecureActionButtonTemplate`, `type = "click"`
  on `PlayerSpellsMicroButton`) on UIParent, placed in numbers over its body, not in our window: made, placed,
  shown and hidden out of a fight, gone at `PLAYER_REGEN_DISABLED`, back after. A secure snippet cannot do that
  on a push: the restricted frames have no `Click`, and `CallMethod` runs `forceinsecure()`.
- **The unit frames** (`Units/`): each of `Units.KINDS` (player, target, focus) is the game's
  `SecureUnitButtonTemplate` (`Units.WIDTH` x `Units.HEIGHT`, 240 x 26, scaled by `unitSize`; attributes `unit`,
  `*type1` `target`, `*type2` `togglemenu`; `RegisterUnitWatch`), its look a plain frame on it (`button.face`) that
  hears its unit's `Units.EVENTS` (`RegisterUnitEvent`), and a frameless `Core.Window` (`store`, `playerPlace`,
  `targetPlace`, `focusPlace`) placed in Edit Mode. `PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED`,
  `RAID_TARGET_UPDATE`, `PLAYER_LEVEL_UP` and `PLAYER_ENTERING_WORLD` fill them anew. In Edit Mode the unit watch is
  off and every frame and row shown, one whose unit is not there filled for `player` as a sample (`face.sample`,
  `face.rowSample`, `TEXT.samples`). Secure work (making, the unit watch, showing, the scale, the game's frames)
  runs out of a fight (`Core.AfterCombat("unit frames", ...)`); a setting changed in one waits for its end.
  - Each kind's `row` (`targettarget`, `focustarget`, `pet`; settings `unitTargetTarget`, `unitFocusTarget`,
    `unitPet`): a `SecureUnitButtonTemplate` child of the frame's button, right under it, `Units.ROW` (18) high,
    shown by its own unit watch; its look is the face's (`face.row`, `face.rowName`), laid out as its button shows
    or goes (its `OnShow`, `OnHide`, and the frame's `OnShow`: a row hidden while its frame was out of sight hears
    no `OnHide`; `Rowed`). While it shows its unit is read every `Units.POLL` (0.2 s) on the row bar's `OnUpdate`
    (the game sends no events of a target's target), and at once on `UNIT_TARGET` and `UNIT_PET`.
  - The casts and your frame's `bars` (settings `unitCast`, `unitBreath`; `Bars` in `Units.lua`): what stands in for
    the game's bars while they run, plain frames in `face.above`, the part of `Bar.Fit`'s stack above the health bar,
    nearest it first (each with its height, `tall`, and whether it shows, `on`), so they come and go in a fight without
    a secure button. `Cast.lua` (`ns.UnitCast`): one per frame (`bar.unit`), a
    frame in the stack holding the icon and, right of it, a `Bar.Strip` as fill; the strip's end masks go over both
    (`bar.ends`). It hears its unit's `UNIT_SPELLCAST_*` events itself (`Cast.EVENTS`) and reads `UnitCastingInfo` and
    `UnitChannelInfo` anew at each; hidden values go to the bar as they are, as a nameplate's (`Cast.lua` there). A
    cast fills in the game's art, a channel empties (its art behind, the dark filling from its end). Interrupted
    (`UNIT_SPELLCAST_INTERRUPTED` of the cast's own number, `UNIT_SPELLCAST_CHANNEL_STOP` with who did it,
    `UNIT_SPELLCAST_EMPOWER_STOP` not completed): the broken art and `SPELL_INTERRUPTED_BY`. An empowered cast (Retail's)
    fills on to `GetUnitEmpowerHoldAtMaxTime`, a line at each stage's end (`GetUnitEmpowerStageDuration`). It respects
    the game's rules (`Cast.RULES`), shows nobody else's crafting, and greys a cast that cannot be interrupted with a
    bar over the fill (`bar.lock`, under the same masks; a hidden answer by `SetAlphaFromBoolean`, as a nameplate's).
    A new target or focus reads it at once (`Cast.Anew`, from `Changed`). `Timers.lua` (`ns.UnitTimers`): your breath's strip over the health bar
    (`face.breath`, in `face.over`: `Bar.Fit` rounds it as the health bar and shows it by its `on`; no background, a
    level over the health and under the frame's words, the fill's alpha `Timers.SHEER`, the bar's own words over
    them), `Timers.MOST` strips at `Units.POWER` for the other timers in `face.above`, over the cast, each in the game's atlas (`Timers.ART`, as
    its `MirrorTimerAtlas`), filled by `MIRROR_TIMER_START`, `_STOP`, `_PAUSE` and `GetMirrorTimerInfo` (at the
    world's showing and whenever they are set up anew), following `GetMirrorTimerProgress` on its `OnUpdate`.
  - `Bar.lua` (`ns.UnitBar`): the nameplates' look rebuilt for a frame of one size: the fill and background
    masked by Core's caps (`Shape.CAP_LEFT`, `CAP_RIGHT`, a quarter of the height) or, while the row shows, by
    corner masks at the top alone (`Shape.CORNER`), the row's at its bottom; the border, rank line and the glow's
    six bands as halves round at their own corners, reaching down round the row while it shows, the row a pixel
    under the bar (the border's dark between). The frame keeps its width: the border lies on its edge, the rank's
    line a pixel inside it, and the bars inside both (`rank.width` pixels in: 1 plain, 2 an elite or a rare, 4 a
    boss); only the glow reaches outwards. The health bar is the anchor (Saneroki): its rectangle depends on the
    frame's rank alone, never on what shows, and the frames stand by their tops (`first`'s `relative`, or a moved
    frame's `TOPLEFT`), so the button's height moves nothing. The bars are one stack a pixel apart (`Bar.Fit`): the health
    (`face.healthHeight`, the face's own height), each power shown (`face.powersShown` of `face.slots`, each
    `Units.POWER` high, half the health's), the row under the power slots kept (where its button is) and your pet's
    power under it (`face.rowPower`, `Units.ROW_POWER` high, `Bar.RowPower`, read with the row, gone for a pet
    without one), and above the health what stands in `face.above` while it shows (the plates reach up by it;
    `face.roof` its top, moved in a fight too: the auras stand on it, never moved themselves); the first round at its top, the last at its bottom, the rest square (`End`'s modes). `Bar.Kinds` picks the powers: the
    unit's own (`UnitPowerType`), or on a frame with two slots (`face.alternate`) mana (`Bar.MANA`) and under it the
    unit's own while that is not mana; `Bar.Powers` fills them (`UnitPower`/`UnitPowerMax` by type, hidden or not;
    an empty bar where the unit has none) and lays them out anew when their number changes. Every health bar
    `Bar.GREEN` (the game's `COMPACT_UNIT_FRAME_FRIENDLY_HEALTH_COLOR`, plain green without it); each power in the
    game's `PowerBarColor`; ranks and glow as on a plate. Hidden values (health, a creature's most, your threat against it)
    go to the bars, the glow's `SetAlphaFromBoolean` and the texts as they are.
  - `Text.lua` (`ns.UnitText`): the game's plate font (`SystemFont_NamePlate_Outlined`) at `Text.SIZE` 12; level
    and raid marker (`SetSpriteSheetCell`) left, health right (`Text.Short`, `Text.Percent`; hidden: the game's
    `AbbreviateNumbers` in `Text.STEPS` and `UnitHealthPercent` by its curve), the name from the left side's end up
    to the health's room (`Text.Layout`; the health's room as wide as its most, measured on a ruler of ours,
    `Text.SAMPLE` while a creature's most is hidden), none on your own frame (`face.noName`); each power's words at
    its bar's right in `Text.SMALL` 9 (`Text.Powers`; hidden: `AbbreviateNumbers` and `UnitPowerPercent` by its
    curve); the row's name alone, centred (`Text.Row`). A row's bar is the colour of its kind's `row.colour`: the
    targets' rows `Bar.CALM` (the nameplates' light yellow for a creature that does not attack on sight), the pet's
    green.
  - The button's height is the health's and its power slots' (`Units.HEIGHT + slots * Units.POWER`), set out of a
    fight (`Kind`): your own frame keeps two slots (`Alternate`) as a druid, or while your power is not mana but you
    have mana (asked again on `PLAYER_SPECIALIZATION_CHANGED`); the face is the health bar's height, the rest hangs
    under it.
  - `Auras.lua` (`ns.UnitAuras`): per frame and kind (`Auras.KINDS`: buffs, control, debuffs) a container of the
    game's (`CustomAuraContainerTemplate`, as the nameplates'), each on the frame's `roof` at its `point`
    (`BOTTOMLEFT`, `BOTTOM`, `BOTTOMRIGHT`): the game sizes a container to what it holds, so the one in the middle
    stays centred. `Auras.LINE` (three icons) is its widest line (`SetFlowLayoutMaximumLineSize`): what your list
    adds goes up, not sideways into the next kind. Groups of `Auras.MOST` (3): `listed` (the filter
    `HARMFUL` or `HELPFUL` with `includeSpellIDs` = Important, off while that list is empty, its icons with a glow, so a
    fight needs no telling which is which), `shown` (Show on unit frames, no glow) and `auto` (the kind's
    filter for a foe or a friend, `SetAuraGroupFilterString` as the unit changes, its sort `UnitFrameDebuff` or
    `BigDefensive`, `excludeSpellIDs` = what those two hold and what never shows; control only what never shows: Unimportant and Hide, less Show). The game applies those candidate filters
    itself, in a fight too, where it lets addons tell spells apart (`AuraContainerUtil.CanApplyIdentityCandidateFilters`).
    Each icon (`initializeFrame`, `Dress`): the picture cropped in a dark edge, the swipe, the count, its name into a
    text of ours at alpha 0 (`SetSpellName`), and an `OnMouseUp` hook: a left click, while not `Core.Restricted()`,
    finds the spell by that name among the unit's auras (`C_UnitAuras.GetAuraDataByIndex`) and opens the game's
    context menu (`MenuUtil`). `Auras.Set` sets each container's unit (`none` while off), `UpdateAllAuras` at every fill.
  - `Lists.lua` (`ns.AuraLists`): the settings `auraWhite`, `auraBlack`, `auraHidden`, and `auraShow`, `auraHide` (`{ [spell number] = name }`), one list of
    each side per spell (`Lists.SIDE`; `Put`, `Take`, then `Auras.Refresh`, `BuffList.Style`); `Mark(name)` by name, for the ranks; `Entries` the menus' lines; the window a `Core.Window` panel (`auraListsPlace`, not
    sizable, no full screen): the box (`InputBoxTemplate`; a number by `C_Spell.GetSpellName`, a name by
    `C_Spell.GetSpellInfo`), a button per list, the lists in scroll areas, each line with
    icon, name, number and the game's close button, the rule under them. `/sane auras` (`Core.Command`).
  - The game's frames (`Away`, `Back`, `Core.Lend`): `TargetFrame` and `FocusFrame` get a hidden frame of ours as
    parent; of `PlayerFrame` its `PlayerFrameContainer` and `PlayerFrameContent` alpha 0 and its mouse off, so its
    children `TotemFrame` and the class bars stay the game's; `PetFrame` (which the game's layout re-parents) alpha 0
    and its mouse off while the pet's row is on. `PlayerCastingBarFrame`, `OverlayPlayerCastingBarFrame` and
    `MirrorTimerContainer` go deaf (`SetDeaf`: `Cast.GAME`, `Timers.EVENTS`) while ours stand in, each event noted with
    its unit and registered again as it was: they are not hidden or moved, because the cast bar is a managed frame
    (its `OnHide` would run the bottom layout in our taint, the game sets its alpha and parent anew itself). The overlay
    deaf, the game's own talents window shows its spinner where its cast would stand.
- **The game's other bars** (`GameBars.lua`, `ns.GameBars`, Saneroki 2026-10-31): `StatusTrackingBarManager` and
  `StanceBar` lent to a hidden frame (`Core.Lend`'s `SetParent`, each by its switch: `hideTracking`, `hideStance`).
  The game runs them on, unseen; its bottom bars stay where they stood, since its layout asks each bar's `IsShown`.
  Your stance keys run `StanceBar:Select`, which works hidden. The menu bar (`menuHover`) keeps its place: in
  WoW: Forever `MainActionBar` hangs on `MicroMenuContainer`. `MicroMenu`'s alpha is lent, a hook after each button's
  `OnEnter` fades it in (`Core.Motion.Fade`), a frame of ours looks each frame for `MicroMenu:IsMouseOver()` while
  it shows. In Edit Mode it shows, to be placed.
- **Out of sight at rest** (`Core.Rest`, Saneroki 2026-11-01; settings `unitRest`, `barsRest`, on at first): what
  shows when, and why your health is told from its changes, stands in `src/Core/Rest.lua`. Your frames are a set each
  (`Units.lua`, `kind.rest`): the mouse on a frame, its row or its aura containers shows that frame alone, and a cast
  or a timer on it does too (`Running`; `Bar.Fit` looks again as they come and go), since nothing else shows them and
  you need your breath under water. The action bars are one set (`ActionBars.lua`): `Bars.BARS`, each hot, each of
  their buttons a door, so the mouse on one shows them all; held in a vehicle (`HasVehicleActionBar`,
  `HasOverrideActionBar`: its actions stand on them), while something is dragged and in the game's Quick Keybind mode,
  which show every button too. Only alpha changes: out of sight they take the mouse as ever, and that is how the mouse
  is seen on them. Having a target does not show a frame: the plate shows it (Saneroki's list names no target).
- **The action bars** (`ActionBars.lua`): the bars of `Bars.BARS` (main, the extra bars, stance, pet, possess)
  keep their place, buttons and secure code; through `Core.Lend` their `Bars.ART` (`BorderArt`, `EndCaps`; the
  main bar's `ActionBarPageNumber` and its arrows stay) and each button's `Bars.BUTTON_ART` (`NormalTexture`, `SlotArt`,
  `SlotBackground`, `Border`) go to alpha 0, and its cooldowns cover the whole icon; the icon loses its
  `IconMask` and is cropped (`Bars.CROP`); its highlight, pushed and checked textures become flat colours
  (`Bars.LOOKS`, each texture's atlas or file and blend noted, written again where `UpdateButtonArt` set it anew).
  A button's alpha is 0 while it holds nothing (`C_ActionBar.HasAction`, else its icon) unless the game shows its
  grid (`ACTIONBAR_SHOWGRID`) or Edit Mode is open; then a dark square of ours (`Bars.SLOT`) lies under every
  icon. Hooks after the game's own (each button's `Update`, `UpdateButtonArt`; a bar's `Update`, `UpdateState`,
  `UpdateDividers`, the dividers of its pools at alpha 0, each kept to give back) keep it so. Cleaning waits for
  the end of a fight; giving back is at once (what may not change in one, after it).
- **Standing down** (`ns.GiveBack`): the keys are the game's again first, then each part gives back what it lent
  (the planner) and hides what is protected (the book's secure buttons, now or after the fight), the window hides,
  the quest marks hide and no plate gets one after it, our unit frames go (alpha 0 at once, hidden and their unit
  watch off after a fight) and the game's are back, and the action bars are as the game has them; each step by
  itself, so one that fails keeps none of the others from giving back.
- Tests: `dev/tests/combat.lua` (the window, the board, the keys, the planner, the quest marks, the unit frames,
  the action bars, a window of ours a game lacks; at its end the file runs again as Retail loads the module,
  `combat.lua retail`), with `dev/tests/combatclient.lua` (what the unit frames and action bars need of the
  stand-in client, for every test that loads the module),
  `dev/tests/book.lua` (the spellbook), `dev/tests/talents.lua` (the talents).

- **Party and raid (`Units/Group.lua`):** the window (`Core.Window`, key `groupPlace`) is `groupWidth` by `groupHeight`, anchored by its bottom left corner (`window:GrowFromBottom`). In it `live` (a secure frame, shown by
  the state driver `Group.SHOWN`) and `preview`. Eight `SecureGroupHeaderTemplate`s, `groupFilter` 1 to 8, `point` BOTTOM, chained
  BOTTOMLEFT to the last one's BOTTOMRIGHT with `minWidth` 0.1, so an empty group takes no room, in a fight too; they are told
  `template` `SecureUnitButtonTemplate` and make their buttons themselves (a `startingIndex` of -4, then 1: `header[1]`..`[5]`), built
  when you are first in a group, out of a fight. `Group.Size(columns, rows, width, height, unit)` is the sum for a unit's size,
  `Group.Filled()` what the group fills. `GROUP_ROSTER_UPDATE` lays out again after a fight. Preview: `Face.Make(preview, true)`
  plain frames, `Roll` once per count. The game's `PartyFrame` (which holds `CompactPartyFrame`), `CompactRaidFrameContainer` and
  `CompactRaidFrameManager` stand in a hidden frame (`Core.Lend`). A ready check's result stays `Face.READY_HOLD` seconds (the game's
  `CUF_READY_CHECK_DECAY_TIME`) after `READY_CHECK_FINISHED`; who has not answered is not ready, as the game has it.
- **What floats on the left (`Units/GroupFace.lua`):** `face.floating`, over the words: `marks.lead`, `ready`, `rez`, each anchored to the last's
  right, an empty one as wide as nothing. The dispel icon's container takes the size of what it holds (the game's `OnLayoutComplete`, its numbers
  hidden in a fight), so what follows it moves by itself where addons cannot tell whether it shows. They are the frame's height less
  `Face.BIG_OFF`. On the line under them `level`, `raid` and `name` hang on each other; `name` ends at the health's room.
- **The group's tools (`Units/GroupTools.lua`):** nearly all a raid manager does is `HasRestrictions`, off limits to addon code (markers,
  `DoReadyCheck`, `DoCountdown`, `SetEveryoneIsAssistant`, converting), so nothing of that is called: `SecureActionButtonTemplate`s of the types
  `raidtarget`, `worldmarker`, `togglemenu` (unit `player`) and `click`, whose `clickbutton` is the game's own button in
  `CompactRaidFrameManager.displayFrame` (`readyCheckButton`, `rolePollButton`, `countdownButton`, `everyoneIsAssistButton`). With secure buttons
  the panel is protected, so its opener and close button are `SecureHandlerClickTemplate`s, which work in a fight. The opener lies on the cog
  of the button whose face has your unit (`face.mine`), moved after the fight if the group changes in one. Threat may be hidden in a fight
  (`ShouldUnitThreatStateBeSecret`): addon code cannot turn a hidden number into a colour (a curve's `Evaluate` takes no secrets from addons), so the border stays black then.
- **One unit (`Units/GroupFace.lua`):** its parts are the unit frames' (`UnitBar.Plate`, `Around`, `Strip`, `End`, `Ends`, `Power`;
  `UnitText.MakeLine`, `Raid`, `Mark`, `Name`, `Health`, `Sample`), without the glow's plates: forty frames stay light. `Face.Unit` follows
  the button's `unit` attribute (`OnAttributeChanged`, in a fight too) and registers that unit's events. `face.compact` and `face.bare`
  are told to `UnitText.Health`; `MakeLine` takes its tighter inset and gap; `face.floating`, a frame over the words, holds the icons, and
  `face.roomed` places them and the dispel icon after each layout.
- **Your buffs (`Units/GroupBuffs.lua`):** `Buffs.CLASSES`, families of names (English clients), found as yours by `C_Spell.GetSpellInfo`
  of a name. `Buffs.Missing` reads `C_UnitAuras.GetAuraDataBySpellName`, out of a fight only (`Core.Restricted`): `nil` there, and
  everyone is read again at `PLAYER_REGEN_ENABLED`.

- **The threat and damage meter** (`Meter/`): the combat log is closed to addons (`C_CombatLog.IsCombatLogRestricted`), so
  the numbers are the game's own meter's (`C_DamageMeter`, the same in both games). `Read.Fight(where, types, people)` reads one
  list per kind, `where` `{ id = session }` or `{ type = "Current" / "Overall" }`, and matches the sources by GUID
  (`isLocalPlayer` for you). In a fight every number is a secret value: bars take them as they are (`SetValue`,
  `SetMinMaxValues`), words through `AbbreviateLargeNumbers` and `SetFormattedText` under `pcall`; never a comparison, a sum
  or a boolean test (`type(x) == "nil"` only; `dev/tests/meter.lua` errors on the rest). The game's list comes best first, so
  `read.rank` stands in for the numbers in `Sorted` while `read.hidden`. A source whose GUID is hidden after all: `Read.One`
  asks by the member's GUID, the total alone. A table the game keeps closed (`pcall`) leaves the fight empty until it ends;
  nothing is reported. `Hold` keeps `damageMeterEnabled` on, its old value in `store.meterGame`, and lends the game's window
  `DamageMeter` to a hidden frame (`Core.Lend`), but in Edit Mode. Threat (`Threat.lua`): `UnitDetailedThreatSituation(unit,
  mob)` for every member each look, `rawThreat / Threat.SCALE`, positive gains added per fight and overall; a mob is known
  only by a new target, as its GUID may be hidden. A fight's threat stays with the fight's session once the game lists
  it (`Fights.Settle`). Looks: `Core.Watch` every `Meter.EVERY` seconds in a fight or while an item level is still to ask
  for (`Core.Inspect`); at rest only `Core.Later` after the game's events. A fight is `Fights.Fighting()`, from the game's
  two events: as `PLAYER_REGEN_DISABLED` comes `InCombatLockdown()` still says no. A saved fight: `store.meterFights`, plain numbers.
  Hover: `Core.Hover` (motion only, so every click goes on); the wheel on the window while the list is longer than its room;
  the first line's `drag` frame shows only on hover, `window:DragBy` (Core).
  - **Which bars:** `Shows.Of(person)`: the ticks, but for `store.meterPeople[guid] = { [kind] = true or false }`, only what
    differs from the ticks; a saved fight keeps each GUID so its people have theirs. So rows differ in height: the list's extent is
    a calculator, `Fit` takes whole rows from `first` (the wheel moves it, a character a notch), and the scroll box is exactly as
    high as they are, scrolled by `ScrollToElementDataIndex`. A row's `line`, a button over its name that only shows on hover,
    takes the right click; on the first line `drag` lies over it and takes it. `Types` reads what anybody has (`Shows.Wanted`).
  - **In sight:** `Wanted()` (the full screen, Edit Mode, a saved fight, or both Hide ticks satisfied). With *Show on mouseover*
    the frame stays shown and only `block` goes, so `Core.Hover` still hears the mouse's coming; without, the frame hides. Hidden, nothing is read.
- **Reminders** (`Reminders/`): `Core.Character(ns.name).reminders`, a list. `Reminders.Update` runs on a ticker every
  `Reminders.EVERY` seconds, only while there are reminders and the setting is on: it looks at each aura
  (`C_UnitAuras.GetAuraDataBySpellName`, the name for the ranks) and hands each bar what shows. `Hidden` asks
  `C_Secrets.ShouldAurasBeSecret` and `ShouldSpellAuraBeSecret`, `Core.Restricted` where they are not there. Hidden, `Look`
  keeps the last plain look: `auraInstanceID` and the end; `GetAuraDuration` is not secret and fails on an instance gone
  (*RequiresValidUnitAuraInstance*), which `Core.Ask` turns to `nil`: the aura went. Past its end and still there it was
  renewed: on, time unknown. `UNIT_AURA`'s payload is secret there and is not used. The bars are plain frames, free to
  change in a fight. Bars: `char.reminderBars`, numbers that never change, so a bar's place (`reminderBar<number>`) stays
  with it; shown as the place in that list. Deleting one forgets its place. Without reminders the ticker is off.
- **The buff list** (`Units/BuffList.lua`): the game's `AuraButtonMixin:OnClick` cancels a buff on a right click, in secure
  code, and does nothing on a left one but tell `BuffButton.OnClick`, which nothing of the game's hears. Addons cannot cancel
  (`CancelAuraByInstanceID`, `CancelUnitBuff`), so the right click stays the game's, and the left is a `HookScript`: after the
  game's, so nothing of ours runs on its way to the cancel. Not that callback: it runs before the cancel, in the same click.
  Fields of the game's buttons are only read. The outline is a child of the button:
  `BuffList.Alert`, the game's `ActionButtonSpellAlertTemplate` made by us, 1.4 times the icon as the game's, only its loop;
  not by `ActionButtonSpellAlertManager`, which would write our frames into its `activeAlerts` and fields, and made when first
  needed. The template's own `OnShow` is never hooked up (and asks a field the manager never sets), so ours starts the loop. The fade on the button's regions (`REGIONS`), as `AuraButtonMixin:OnUpdate` sets the button's own alpha every
  frame for its warning flash. Hidden last: the game's list keeps a place for every button with `hasValidInfo`, written by
  it, so `Took` keeps each button's anchor after the game's layout (a hook on `AuraContainer:UpdateGridLayout`; the debuffs'
  list anchors valid buttons only, `doNotAnchorDisabledFrames`), `Arrange` deals those places out, seen first. The mouse:
  `HookScript` `OnEnter`, `OnLeave` on the buttons, `LINGER` for the gaps. In a fight `known[instance]` from the last plain look.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Combat.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Bindings.xml` | Combat's keys in the game's key bindings, under Sane UI (the game reads it by itself) |
| `Combat.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (the keys, the quest marks, Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Window.lua` | Its window: docked at the bottom middle, filling the screen from the bottom edge's middle half; full, Core's board; the game's windows in *Classic windows* |
| `Board.lua` | The full screen's windows on Core's board, each a part that registers itself; the talent planner's |
| `Book/Layout.lua` | Where each entry stands on the pages, by the game's rules |
| `Book/Data.lua` | What the book holds: the game's tabs, their spells as its book shows them, the search |
| `Book/Item.lua` | One entry, as the game's |
| `Book/Casts.lua` | The game's secure buttons over the icons, which cast out of a fight |
| `Book/Book.lua` | The spellbook: pages, tabs, the game's paging controls and settings |
| `Talents/Talents.lua` | The talents: the part on the board, the game's shared talent frame loaded and fitted into its panel, its words |
| `Talents/Nodes.lua` | The nodes: the game's shared node buttons with the class talents' glow, tooltip and sounds; the arrows |
| `Talents/Art.lua` | What the trees stand on: the class's picture, its clouds and lights, the frame and dividers, the commit's flash |
| `Talents/Headers.lua` | Each tree's head with the points spent in it, and the unspent points |
| `Talents/Specs.lua` | The primary and secondary specialization: the game's tabs, Active or Activate |
| `Talents/Foot.lua` | Apply Changes, Undo and the Reset menu |
| `Talents/Commit.lua` | The commit's and the switch's cast over the trees, on a cast bar of ours from the game's template |
| `Talents/Changes.lua` | Buying, refunding, applying, undoing and resetting, where the game allows it |
| `Talents/Tree.lua` | The frame: the game's shared talent frame with the class layer over it, its events while shown |
| `GameWindow.lua` | The game's own spellbook and talents window seated on the full screen, in a game where ours are not |
| `Keys.lua` | Your spellbook, pet book and talents keys opening ours |
| `QuestMarks.lua` | A mark beside a creature's nameplate while it belongs to an objective of your quests still to do |
| `MouseRings.lua` | Rings around the mouse for the global cooldown and your cast, only while they run, centred on the cursor's picture |
| `Units/Bar.lua` | A unit frame's bars in a nameplate's look: one round outline, its border, the rank's line, the glow; the green health bar, the power bars under it (a druid's mana and form), the row |
| `Units/Text.lua` | The line inside it: level and raid marker left, then the name, the health right; each power's words; the row's name |
| `Units/Auras.lua` | The auras that matter most around a frame, in the game's own aura containers; the click on an icon |
| `Units/Lists.lua` | Your marks: Important, Unimportant, Hidden; Show on and Hide from unit frames; the one menu of an aura or spell (`Lists.Menu`), and their window (`/sane auras`) |
| `Units/BuffList.lua` | The game's list of your buffs and debuffs: the game's outline, fade, hidden last, the left click |
| `Units/Cast.lua` | A unit's cast as part of its frame, directly above the health bar, in place of the game's cast bar |
| `Units/Timers.lua` | Your breath and the game's other timers on you as part of your frame, in place of its bars |
| `Units/Units.lua` | Your frame, your target's and your focus's, and the rows under them (their targets, your pet): the game's secure unit buttons, placed in Edit Mode; the game's own out of sight; each out of sight at rest |
| `Units/GroupBuffs.lua` | Which of your own buffs a member of your party or raid is missing |
| `Units/GroupFace.lua` | One member's frame: a nameplate's bar, marker, name, health, the mana line, the icons; live or made up |
| `Units/GroupTools.lua` | Your own slot's button and its panel of the group's tools, in place of the game's raid manager, by the game's secure means |
| `Units/Group.lua` | The one window for party and raid: the game's secure group headers, sizes, Edit Mode's settings and preview |
| `ActionBars.lua` | The game's action bars clean: only the buttons that hold something, each its icon alone; out of sight at rest, as one set |
| `GameBars.lua` | The game's experience and stance bars out of sight, its menu bar on mouseover |
| `Meter/Threat.lua` | The meter's threat: every member's share of the mob, its gains added up per fight |
| `Meter/Read.lua` | Who is in the group, and a fight's numbers from the game's meter, hidden or not; what the list can be sorted by |
| `Meter/Shows.lua` | Which bars a character has: the window's ticks, or their own |
| `Meter/Fights.lua` | Which fight is shown: the pages, the live page, the saved fights |
| `Meter/Row.lua` | One character: their line and a bar per thing shown |
| `Meter/Controls.lua` | The buttons at the end of the first line, and the flyouts |
| `Meter/Meter.lua` | The window: its two places, the list of whole rows, grown down or up, when it shows, the game's meter out of sight, the looks in a fight |
| `Reminders/Reminders.lua` | The reminders and bars: kept per character, what is known of an aura, in a fight too, whether one shows, the looks |
| `Reminders/Bars.lua` | The invisible bars: their places in Edit Mode, the icons side by side, as wide as what shows |
| `Reminders/Editor.lua` | The window: your bars, a bar's reminders and the settings of the one chosen |

## History
- **2026-11-02:** the aura's menu on a left click, in a fight where the game tells which aura it is, and on a right click in the spellbook (Saneroki).
- **2026-11-01:** Show on and Hide from unit frames, apart from how an aura looks (Saneroki).
- **2026-11-01:** Important, Unimportant, Hidden on the game's list of your buffs and on the unit frames (Saneroki); reminder bars made and deleted, one by default.
- **2026-11-01:** reminders of buffs and debuffs on invisible bars (Saneroki), from a right click on an aura.
- **2026-11-02:** the meter hides out of a fight and alone, shows on mouseover, and each character can have bars of their own (Saneroki).
- **2026-11-01:** the threat and damage meter (Saneroki), on the game's own meter and threat, with its pages and saved fights.
- **2026-10-16:** set up as a module of its own, for party, raid, buffs, unit frames, nameplates and pets.
- **2026-10-20:** its window, docked at the bottom middle (Saneroki); the bottom edge's middle half fills the
  screen with the talents and the spellbook as panels; a talent planner Sane UI knows as the Talents panel.
- **2026-10-20:** quest marks beside nameplates (Saneroki), from the game's own tooltip data.
- **2026-10-20:** the full screen on Core's board (Saneroki): layouts behind tabs, the windows arranged as on
  every board; an empty window of the game's opens with a click anywhere in it instead of an *Open* button.
- **2026-10-20:** our own spellbook (Saneroki: the spellbook and talents are Combat's own windows, as the game's;
  the book casts out of a fight only); your spellbook and talents keys open ours; the talent planner a window
  of its own; the game's window no longer seated.
- **2026-10-20:** our own talents (the game's shared talent frame with the Camelot class layer ported).
- **2026-10-25:** Retail (Saneroki: one interface for both games): our spellbook and talents stand down there and
  the game's own open with their keys; the quest marks run in both.
- **2026-10-29:** unit frames for you, your target and your focus (Saneroki: part of Combat, very like the
  nameplates; the health and its share right, the name in the middle, players by their full names, the level and
  raid marker left), in place of the game's; the game's action bars clean (Saneroki: no borders, decorations or
  backgrounds, only the filled slots).
- **2026-10-29:** rows under the frames (Saneroki: the target's target like the cast bar, appearing underneath while
  there is one, its name the only text): your target's target, your focus's target, your pet; every bar green, no
  class colours; names from the left; no name on your own frame.
- **2026-10-29:** every unit frame one width (Saneroki: a fixed width), the rank's line inside the border; the main
  action bar's page number and arrows visible again (Saneroki).
- **2026-10-29:** power bars half the health bar's height with "current | percent" (Saneroki: a druid's mana always,
  and the energy or rage of its form); the three most important buffs, debuffs and crowd control around each frame,
  as on the nameplates, with the lists Always show and Never show (Saneroki: by a right click on an icon, and a
  window to add them).
- **2026-10-29:** the target's and focus's target rows in the nameplates' light yellow of a neutral creature, the
  rows' names centred (Saneroki).
- **2026-10-30:** your cast and your breath as part of your frame, under it while active, the game's own bars hidden
  (Saneroki).
- **2026-10-30:** your breath over your health bar instead, 50 % transparent so the health shows underneath, in the
  bubble art of the game's own breath bar (Saneroki); the other timers in the game's art too.
- **2026-10-30:** the cast bars of all unit frames directly above the health bars, fatigue and feign death above the
  health bar too, so all three of the game's timer bars are gone; your pet's health and resource bar in place of a
  target's target on your frame, the game's pet frame hidden (Saneroki). The auras move up over what stands on a frame;
  your pet's row has no cast bar of its own: its secure button cannot move in a fight (board).
- **2026-10-30:** the health bar the rock solid anchor of every unit frame: whichever bars show or go, it stays at the
  same spot (Saneroki).
- **2026-10-30:** one frame for party and raid in place of the game's two (Saneroki): nameplates' look, up from the bottom left, a
  column a group, forty at most, units edge to edge with no gap and nothing around them; the mana of tanks and healers inside the
  bar; your missing buffs; max sizes and a preview of any number of made-up units in Edit Mode. Barriers, lost maximum health and
  dispels on every health bar (Core's `HealthMarks.lua`).
- **2026-10-31:** slots fill the window: five always fill the max height, and the width is shared only where the columns would not fit (Saneroki).
- **2026-10-30:** your own slot a frame like all the others, its name the word Party or Raid, a cog on it for the group's tools (Saneroki).
- **2026-10-30:** tiny role marks for tanks and healers in the top left corner, no golden circle; the ready check, dispel and incoming resurrection icons big, floating
  over the left of the frame, the raid marker and the name staying where they are behind them (Saneroki).
- **2026-10-30:** the game's raid manager gone, your own slot a button to the group's tools in its place; the dispel type's icon instead of a
  ring and the aura's icon, the raid marker moving aside for it; ready checks left of the raid marker; the dead red and the offline grey, their
  bars full; a solid red border on aggro; the box back in Edit Mode only (Saneroki).
- **2026-11-01:** rings around the mouse for the global cooldown and your cast (Saneroki): only while they run, around the whole cursor, not its tip.
- **2026-11-01:** unit frames and action bars out of sight at rest (Saneroki): in sight with the mouse on them, while your health or resource is not full, in a fight and in a group; the mouse on any action bar shows them all.
