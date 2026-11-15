# Sane UI: Combat

**Status:** its window and full screen built: docked at the bottom middle, the bottom edge's middle half (or your spellbook or talents key) fills the screen with our own spellbook and talents (built), as the game's, on Core's board; quest marks beside nameplates; our own frames for you, your target and your focus in a nameplate's look, with their power bars, the auras that matter most and your aura lists, and rows under them for your target's and focus's targets and your pet (built); the game's action bars clean (built); rings around the mouse for the global cooldown and your cast (built); the threat and damage meter (built); the aura history on the full screen (built); in Retail all of it, the game's own spellbook and talents window standing on the full screen in place of ours (they are Forever's) · **Since:** 2026-10-16 · **Addon:** `SaneUI_Combat` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
The module for everything about the fight: your own frame, your target's (and its target's), your
focus and your pet, the party and the raid, your buffs and debuffs, and what goes with them (cast bars,
totems, bosses). Each part, once built, gives the game's own frame back when it fails. The plan is in
`Doc/ideas/Combat.md`; the nameplates are a module of their own (`src/Nameplates/`).

Built so far: its window, docked in the screen's bottom middle. Push the mouse against the middle half of
the bottom edge, or press your spellbook or talents key, and it fills the screen with our own spellbook and
talents windows, which look and work as the game's, on Core's board that you arrange; push there again, press
the key again, or Esc, and it goes back. A talent planner Sane UI knows is a window of its own there.

Your frame, your target's and your focus's are ours, in the look of a nameplate and green (your target's and your
focus's red while you can attack it): the level and raid marker on the left, then the name (none on your own), the
health and how much is left on the right. Under your
target's and focus's frames, as a cast bar under a nameplate, a row with the name of their target; under yours your
pet, with its health and its resource. Directly above each health bar its unit's cast while it casts. Your breath
lies over your health bar, in the game's bubbles, half see-through, the game's other timers on you stand above your
cast: none of the game's own bars is left. The game's action bars are clean: only the buttons that hold something, each its icon alone. Its experience and stance bars are gone, and its menu bar shows only while the mouse is on it; its alert *You have unopened items in your collection*, once closed, stays closed until more come. At rest your unit frames and the action bars are out of sight: they show with the mouse on them, while your health or your resource is not full, in a fight and in a group.

Your party and your raid are one frame of ours, in place of the game's two: unit frames edge to edge, up to forty, in the
nameplates' look, each player's health in their class's colour, sized to fit the limits you set in Edit Mode; right of each
member of a party of five or less two small frames, half as wide and high: what they target, and their combat pet. On every health bar of ours, these and the unit frames, you see
barriers, maximum health lost for a while, and what can be dispelled (Core's health marks, on the nameplates too).

Around the mouse, only while they run, two see-through rings: the global cooldown and your cast, a bright line with a soft glow leading
the cast's. They go around the whole picture of the cursor, so it stands in their middle, and start and end at its tip.

The threat and damage meter: your party or raid, you on top, each with their class, level, item level and name and
a thin bar each for threat, damage, healing and interrupts. No title bar and no background, and clicks go through
it; the mouse on it brings its buttons.

The aura history, a window of the full screen: the buffs and debuffs seen on whoever you can attack, newest on top,
each a proper aura icon (its tooltip, a click its menu: the marks, *Add tracking*), with whom it was on, from whom, when
it came, its duration, whether it can be dispelled or stolen, and whether the cast that gave it could be interrupted.
In a fight the game keeps most auras from addons: those it shows come in as they come, the rest once the fight is over.

Click a buff or debuff, or right click a spell in the spellbook, and mark it: *Important* (the game's golden animated outline, first on the unit frames), *Unimportant* (faded,
never on the unit frames) or *Hidden* (out of the game's list until the mouse is on it); for the unit frames alone,
with no glow or fade, *Prioritize on unit frames* or *Hide from unit frames*. Or choose *Add tracking*: its
icon then shows on an invisible aura bar placed in Edit Mode (*Aura bar 1* at first), or on the health bars of your unit
frames, or of the party and raid frames, or right under each nameplate, while its settings want it, watched on whom you
choose (you, your target, your focus, everyone, a role, a member of your party or raid); a bar is as wide as what
shows on it, its icons clickable as the buffs are, and you make as many bars as you like. On the health bars and the
nameplates its icon then shows on each frame or plate whose unit lacks it (your Mark of the Wild, your Rejuvenation, your
Sunder Armor), as you choose, nothing fixed.

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
  - **Click** to cast it, **right click** for its menu, as a buff's (below, *Your buffs and debuffs*: *Add tracking* and your marks of its aura; on a pet ability it switches its autocast), **drag** it onto an action
    bar, **Shift-click** to link it in chat (or to pick it up, as your game's modified clicks say).
  - **In a fight** the book shows, pages and drags as always, but a click does not cast (it says so): cast from
    your action bars then. After the fight, a click casts again.
  - At the top right the game's own settings for its book: *Hide passives*, and *Show all ranks* (not for
    rogues and warriors); they change the game's book too. The full screen's search box finds spells of every
    tab. Flyouts are shown as their spells, one by one (as the game's book with *Use flyouts* off).
  - **With Abilities on** (Saneroki, 2026-11-06): the spells you have not learned yet, in grey, after each tab's own,
    what your trainer teaches you now first; in General *Passive spells to learn* and *Skills to learn* (the weapon
    skills a weapon master teaches), in the first class tab *Other spells to learn*. **Drag** a grey spell onto an
    action bar button to reserve it until you learn it (the clock on both), **right click** it for its menu,
    **Shift-click** to link it. The first tab is **Home** (the hearthstone): what your trainer teaches you now with
    the cost, and the spells that come from quests under their level; the book opens on it while Abilities' *Open the
    spellbook on its Home page* is on. The search finds grey spells too. Beside the page controls the checkbox *Show
    unlearned spells*; the settings menu has Abilities' lines under the game's two. All of it as Abilities' README
    tells it (*In Combat's spellbook*).
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
- **The red error text:** the switch *Hide the red error text* (on at first): the game's red line at the top of the screen and
  its sound are gone, always. Yellow lines stay.
- **The action bars on the full screen:** the window *Action bars* under Sane Macros (Saneroki, 2026-11-04; along the foot
  where Sane Macros is not there), and *Side bars* down the right while a tall bar shows. Your bars stand in them as they
  stand on your screen, stacked as you put them, so no other window lies over them; they work as ever, and every button
  shows, an empty one too. Drag a macro of Sane Macros onto one. A layout of your own takes them from the dropdown *Windows*.
  Every bar switched on in the game's options stands there, one Edit Mode shows only in a fight or never too, so you can
  fill it; each window is just as large as its bars, the window above it taking the rest of its column (Saneroki,
  2026-11-09). Every icon there shows at full brightness, and the bars stay in front of the full screen however often
  something is dragged onto them. Beside each of Bars 2 to 8 of a warrior, druid or rogue stands the checkbox *Page with
  your stance or form* (Abilities: [../Abilities/README.md](../Abilities/README.md)).
  Every bar switched on in the game's options stands there, one Edit Mode shows only in a fight or never too, so you can
  fill it; each window is just as large as its bars, the window above it taking the rest of its column (Saneroki,
  2026-11-09). Every icon there shows at full brightness, and the bars stay in front of the full screen however often
  something is dragged onto them. Beside each of Bars 2 to 8 of a warrior, druid or rogue stands the checkbox *Page with
  your stance or form* (Abilities: [../Abilities/README.md](../Abilities/README.md)).
- **Sane Macros:** macros and sequences with no limit of 30, on the full screen beside your bars: `/macro`, `/sane macros` or its key.
  See [Macros/README.md](Macros/README.md). Its switches: *Check macros*, *Dim what cannot be used*, *Show the key on the button*.
- **At a trainer** (Saneroki, 2026-11-09): the full screen comes by itself, the trainer's window on the left (the window
  *Trainer*: the game's own, as it always works, only placed there). Class, weapon and pet trainers: your spellbook on
  the right (in Retail the game's own window). Profession trainers: the game's *Professions* window on the right,
  opened for the profession that trainer teaches once you know it and it has something to craft, and closed again when
  you leave if it was opened for you. Each is a layout of its own behind a tab first in the title bar (*Trainer*,
  *Profession Trainer*), kept as you arrange it; a right click on its tab resets it. When the trainer closes, the full
  screen goes back, unless it was open already before. *Full Screen at Trainers* switches it off.
- **The game's own windows:** the full screen's dropdown *Classic windows* has *Spellbook* and *Talents*: the
  full screen goes back and what opens the game's is said: its key, or, while your keys open ours, its button
  in the micro menu (our code does not open the game's spellbook). The game's spellbook has the button *Sane UI*
  left of its sizing button: the game's closes and this full screen comes, with our spellbook or talents.
- **Quest marks beside nameplates:** a creature that belongs to a quest in your log shows a small mark left of
  its nameplate while an objective of it is still to do: a sword to kill it, a sack to loot it, with the count
  still open ("3/8"). It goes once the objective is done. As the game says it in the creature's tooltip; a
  creature the game says nothing about has none. *Quest marks on nameplates* switches it off.
- **Unit frames:** your own frame, your target's and your focus's, in place of the game's, in the look of a
  nameplate: a round green bar (the game's green for health, for everyone: no class colours; your target's and your
  focus's red, a nameplate's red for a foe, while you can attack it), and under it the
  unit's power in a bar half as high, in the game's colour for it, with the power and how much is left on its
  right ("2.4k | 80%"). Your own druid's mana always shows (Saneroki, 2026-11-13): in a form whose power is not mana
  your mana first, under the health bar, and the form's energy or rage under that; so does yours in a specialization
  whose power is not mana but who has mana too. The game tells a druid's mana in a form to that druid alone, so
  another druid's frame shows the one power it shows now (Saneroki, 2026-11-13: "revert back to how it was with only
  one class bar"). Your target's and focus's frames keep a slot for each power their unit shows (two while it is you),
  so the row under them moves down for the second; in a fight the bars show at once and the row's click area follows
  once it is over. Inside the health bar, on the
  left the level (coloured by how hard the unit is to you, a skull
  where it is too high to tell) and the raid marker beside it; then the name, from the left, a player's first
  name and surname (none on your own frame); on the right the health and how much is left ("850 | 85%"), *Dead*
  or *Offline* where it is so. An elite has a gold line inside its border, a rare a silver one, a boss a thick
  gold one; the frame glows red while you have the unit's aggro (your own: while anything is after you) or while
  it is a player who may attack you. Every frame is the same width, whatever it shows: 240 at 100 % (*Unit frame
  size* scales all three alike); only the glow reaches beyond its edge.
  - **Auras:** those that matter most, in one line above the frame: four buffs, two crowd control, four debuffs, each kind a block of icons that touch, no borders, the time gone darkening the icon as it passes, no numbers on them: buffs on the left, from its
    edge (on a foe those the game shows on its own plates, on a friend or you any, big defensives first), crowd
    control in the middle, centred, debuffs on the right, from its edge (on a foe the ones you put on it, on a
    friend or you any, what you can dispel and a boss's first). Out of a fight the mouse on an icon shows your own tooltip of the aura and brings the frame in sight at rest, and **a left or right click** opens its menu; in a fight the game's icons stand there, with its own tooltip and no click. The menu: *Important* (in front of the
    rest, whoever cast it, with the game's golden animated outline), *Unimportant* (never here), *Hidden* (only the game's list, *Your buffs and debuffs*), *Prioritize on unit frames* (in front of the rest, no glow), *Hide from unit frames*, then *Edit tracked...* and last, while it is not tracked, *Add tracking* (below, *Aura icons*; Saneroki, 2026-11-07: "put the add tracked down to the bottom and change the name from edit aura to edit tracked"). *Edit tracked...* opens *Edit tracked*, the one window
    for every aura's setup, its marks and where its icon shows (Saneroki: "one Edit Auras window where I can handle all the aura
    configuration"): one long list of every aura you set up, a line for each time it is tracked (one where it is not), in
    front of each its red X (off the list, every mark and its icon; on one of several lines of an aura that tracking
    alone) and a + (the game's own plus button: the aura tracked once more, a copy of the line's tracking on a line under
    it, chosen, its own place and conditions from now on; Saneroki, 2026-11-07: "Sometimes I want to show it on multiple
    places or have different conditions"), then its icon, name and number, a tick for each mark in the columns *Hidden*, *Unimportant*, *Important*,
    then a cog (the game's), whose tooltip says *Edit Tracked conditions*, and last *Tracked* (below, *Aura icons*). Click a
    line or its cog to choose it: under the list, titled *Edit Tracked conditions*, stand its icon's settings and its two marks for
    the unit frames, *Hide from unit frames* and *Prioritize on unit frames*, ticked there, tracked or not (Saneroki, 2026-11-09:
    the two columns made way for the cog). A spell stays on the list with no tick until its X. Over the list a search:
    type, and suggestions come under the box, forgivingly found (a piece of the name, its first letters, its letters in
    order), in groups, each class's auras in its colour, *Enemies* and *Food, potions, items and the world*, the best
    first; click one, or Enter for the first, and it is on the list, lit and chosen, to tick. A spell's number finds that spell.
    `/sane auras` and `/sane reminders` open it too, `/sane auras rejuv` with that searched, and the button *Edit tracked*
    in the page's section *Aura icons*. The game lets the lists act here on the buffs of you, your group and friendly units and
    on the debuffs of foes; on the rest it decides itself (in a fight, that is; out of one your marks act on all of them).
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
  - **Look out for**, in your focus's place while you have no focus (Saneroki, 2026-11-07; switch *Look out for*,
    under *Your focus's frame*): out of sight at rest, the mouse on that place shows the button *Look out for*. Click
    it and it grows into a field as wide as the frame: type a name and Enter, or pick by its **+** *Tank (@tank)*,
    *Healer (@healer)*, a *Party member* (@party1 to 4) or a *Raid member* (@raid1 to 40); its **X** stops it, Esc
    closes it. What you look out for is watched on the nameplates, among your group and as your target, in a fight
    too, and kept for the character. Once found, the place shows *Focus found: Add it now* in a gold edge, and a click
    on it, or its key (*Focus who you look out for*, under Sane UI in the game's key bindings), makes that one your
    focus. The game lets no addon set a focus by itself, so that click is yours; it focuses only while you have none.
    One not of your group, whom the game's `/focus` does not know by name (Saneroki, 2026-11-09: "It doesn't add units
    that are not in the group"), the click takes as your target first, makes your focus, and gives you back the target
    you had (or none, if you had none). In a fight the game hides creatures' names from addons: one found before stays found, one that comes in the
    fight cannot be told, and the place says *Looking out for Hogger: click to try* (the click still finds him by name
    if he is near). What you change in a fight is taken at its end. A right click opens the field again.
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
  rest* with *In a group too* under it, *Auras on the frames*); the section *Action bars* (*Clean action bars*, off
  for the game's look; *Hide the action bars at rest* with *In a group too* under it; *Hide the game's experience and
  reputation bars*, *Hide the game's stance bar*, *Menu bar on mouseover*); *Quest marks on nameplates*; the section
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
  unit frames show; in Edit Mode it has the box every window has. A player's health is in their class's colour (*Class
  colours*; off: green). In a party of five or less, right of each member's frame, two small ones, each half as wide and high (*Pets and
  targets beside a party*): what that member targets above, their combat pet under it, each with its name alone in the middle
  of its bar (beside you your target and your pet); a foe yellow or red by how it stands to you, a pet green. Each shows while
  it is there, a pet called or gone in a fight too; a click targets it. Not in a raid. Each unit: the raid marker and the name on the left with as much room as
  there is; a tiny mark of a tank's or healer's role in the top left corner, a shield or a plus without a ring, centred on the raid marker's place, in front of the bar and
  behind the name and raid marker (by the role the game was told, or a main tank). Floating big over the left of the frame, so they are easy to see, with the name going on behind them: the ready check while one runs and its result for a while after, the
  game's icon of a resurrection on its way, the type icon of a dispellable debuff (the game's, a green drop for poison and so on), each moving aside for the one before it; how much health is left on the right ("85%";
  nothing on a frame narrower than 80, where the name gets it too; Dead and Offline always). A dead unit's bar is full and red, an offline
  one's full and grey, and who has an enemy's aggro has a solid red border instead of the black one, in a fight too, where the game
  hides threat from addons (Saneroki, 2026-11-09: "Grooup windows should show always the class resource and aggro"). Every
  member's class resource as a line inside the bar, so the frame is no taller for it: a healer's mana, everyone else's the power
  they show now (a warrior's rage, a rogue's energy, a druid's in its form); on your own slot as a druid in a form whose
  power is not mana your mana along the bottom and the form's energy or rage in a line as thin along the top (Saneroki,
  2026-11-13); an icon floating over the name, which goes on behind it, for each aura you show
  on these frames whose settings want it, four at most (*Aura icons on the health bars*, below, *Aura icons*: a buff or HoT the member is
  missing, say). A unit out of your reach is fainter. A click targets, a right click opens the game's menu,
  hovering shows its tooltip with the whole name, and `@mouseover` macros work on it. Alone, your own frame is all there is.
  Hover and click are the game's unit button's: nothing of ours takes the mouse from it.
- **The group's tools:** your own slot among the frames is a frame like all the others, with its health, marks, buffs and everything else.
  It shows your own name and how much health you have left, as every slot does (Saneroki, 2026-11-13: "change the name of my own frame
  in a party to my actual name, Put the cogwheel infront of my name and add the % health"). One thing differs: a cog always stands at
  its far left, in front of your name; your raid marker, name and role's mark start after it. The cog keeps its place, so the button on it
  is always over it, in a fight too. The cog opens a small
  panel, in a fight too, in place of the game's raid manager at the screen's edge, which is gone: *Ready Check*, *Role Check*, *Countdown*,
  *Make Everyone Assistant*, the raid markers on your target and on the ground (click one to set or take it off, the last clears them
  all), *Group menu* (the game's menu of you: converting to a raid or party, difficulty, and more), *Leave Group*. Who may use what is the
  game's rule. Esc or its close button closes it. *Restrict pings* and the game's filters for its own raid frames are not in it.
- **Its sizes and preview:** in Edit Mode, click the frame. Core's dialog has its *Max width*, *Max height* and *Max unit width*,
  and a field *Preview units*: type a number and that many made-up units show, your own slot first, with random health, mana, raid
  markers, ready checks, aggro, the dead and offline, your auras' icons, a foe and a pet beside a party's members, barriers, lost health and dispels; they stay the same while you
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
- **The aura history** (Saneroki, 2026-11-11): a window of the full screen, *Aura history* in its dropdown *Windows*,
  or `/sane aurahistory` (the full screen with it on). The buffs and debuffs seen on whoever you can attack (your target,
  focus, the mouse's, the boss frames' and every nameplate's; a friend's never), newest on top, the last 400 kept for
  each character. Each line:
  - the aura's icon, as the buffs on your unit frames: the mouse on it its tooltip (the aura's own while it is still on,
    else the spell's), a left or right click its menu: *Important*, *Unimportant*, *Hidden*, the unit frames' two
    marks, *Edit tracked...* and *Add tracking*;
  - its name, *Buff* or *Debuff* and its stacks under it; *On*: whom it was on (a boss with the game's skull), from
    whom under it;
  - *Removable*: its dispel type in the game's colour of it (Magic, Curse, Poison, Disease), *Stealable*;
  - *Its cast*: *Interruptible*, *Not interruptible* or *Instant*, where that cast was seen (out of a fight);
  - *Came*: when it came, to the second; *Duration*: its duration (*No limit*), under it *On now* or how long it stayed
    where it went sooner.
  The dropdown over the list shows *All auras*, *Buffs*, *Debuffs*, those *On bosses* or those *From fights*, and holds
  *Clear history*; the full screen's search finds by the aura's name, whom it was on or whom from. **In a fight** the
  game keeps the auras on others from addons (secret values; asked of the game, Forever hides every real spell then:
  `/sane secrets`, `saneui showsecrets`). So what a fight hides comes in three ways:
  - once the fight is over, what is still on, with the time it came;
  - *Your cast in a fight*: your own casts the game does tell, each of a spell that puts an aura on (Core's data says
    which; a swing or a strike stays out), on whom, when; the aura found on your foe after the fight becomes that line;
  - after each fight, the spells the game's own damage meter holds of it (Saneroki, 2026-11-11: "Yess add them"):
    each member's *Damage in a fight* (Rend's ticks too), *Healing in a fight*, *Dispel in a fight*, *Interrupt in a
    fight*, and *Hit your group*: a foe's spell that hit you or a member, once, with how many more it hit. Whom from,
    whom on (the fight's foe where the game names none), the fight's name under the time, no duration. Swings and
    your own casts logged already stay out. The game's meter fills while Combat's meter is on (it keeps the game's
    switched on).
  - *Cast in a fight*: the casts the Sane UI of each member of your party or raid sends after the fight, of buffs
    and debuffs, with whom and when (Saneroki, 2026-11-11: "Can we use the guild and party sharing to get the spells
    and information from other party members combat?"); one that is an aura seen already marks that line. Only from
    members who run Sane UI, after the fight, never in it. *Share casts in a fight with your group* (page Combat,
    section *Aura history*, on at first): off, yours are not sent and theirs not taken.
  An aura that came and went inside a fight and did no damage or healing, nor was dispelled (Sunder Armor, a shout,
  a boss's enrage), is not seen; Edit tracked's search finds it to mark.
- **The threat and damage meter** (*Threat and damage meter* on the page Combat or `/sane meter` switch it, on at first),
  in place of the game's own damage meter. Never on or over Combat's full screen: out of sight while that is up.
  - **When it shows:** the cog's section of that name, all three on at first. *Hide outside combat*, *Hide when not in
    group*: out of sight while that is so. *Show on mouseover*: while it is hidden, the mouse on its place brings it,
    buttons and all; off, it comes only with a fight or a group. In Edit Mode and with a saved fight loaded it always
    shows.
  - **Where:** at first at the very top of the screen, right of the quest log's first place; its place and size are
    kept. In Edit Mode, or with the mouse on it: drag the first
    line to move it, as the quest log's title bar does, it docks at the edges too; its corner's grip sizes it.
  - **Lock window** (last in the cog's flyout, and on the page Combat under the meter, off at first): it stays where it
    is and at its size; the first line no longer moves it and its corner has no
    grip. Edit Mode still moves and sizes it, as it arranges the game's own meter.
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
  screen stay, with your marks on them. **Click** one for its menu: a tick each, then *Edit tracked...* (the window *Edit
  auras* on it) and last *Add tracking* while it is not tracked (below, *Aura icons*):
  - **Important:** the game's golden animated outline around it, as on a spell it wants you to see; on the unit frames it comes first, with the same outline.
  - **Unimportant:** faded to 25% of its strength; never on the unit frames.
  - **Hidden:** out of sight, and last in the list, so it leaves no hole; it shows while the mouse is on the list.
  - **Prioritize on unit frames**, **Hide from unit frames:** the unit frames alone: first there without a glow, or never there,
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
- **Aura icons** (Saneroki: *Show on healthbars*, once *Reminders*, then *Track*, then *Show on raid frames*; the page's tick
  *Aura icons and bars*; set in *Edit tracked*, `/sane auras`, `/sane reminders`):
  - **Showing one:** click a buff or debuff of the game's at the top of the screen, or an icon above a unit frame (out of
    a fight), or right click a spell in the spellbook, and choose *Add tracking* in its menu (Saneroki, 2026-11-07): it
    shows on *Aura bar 1* at once (Saneroki, 2026-11-07: "make the reminder bar 1 the default one"), and *Edit tracked*
    opens on it, its settings under the list (once it is tracked the menu's *Edit tracked...* does that). Or in *Edit tracked* search
    any spell (any class's, an enemy's, an item's, or its number): it comes onto the list, chosen, and under the list
    *Add tracking*; or tick the line's *Tracked*, or its +, the same. Unticking that, or the line's X, takes it off.
  - **More than once:** the line's + tracks the aura once more, a copy on a line of its own, set apart: on another bar,
    the unit frames, the group frames or the nameplates, or with other conditions (a Mark of the Wild missing on a bar
    in a fight, and on the group frames out of one). Each line is its own; the X on one of them deletes that one alone.
  - **Its settings** under the list, titled *Edit Tracked conditions*, for the line chosen, each at once: *Shows on*: a
    tick for each bar, *Unit frames*, *Group frames* and *Nameplates*, any number of them ticked, the dropdown naming them
    ("Aura bar 1, Nameplates"; Saneroki, 2026-11-07: "make the shows on also multiple choice"; 2026-11-09: "Add a Show on
    groupframes"); the last one ticked stays, as a tracking shows somewhere. On each place ticked it shows by the same
    settings, as that place shows it. *New bar* puts the aura on a new bar in place of the bars it was on (the frames and
    the nameplates stay as ticked); on a bar, *Delete bar*, on several bars a menu of them asks which; *Watch on*: a tick
    for you, your target and your focus, *Everyone*, the roles *Tank*, *Healer* and *DPS*, *Party 1* to *Party 4*, and in
    a menu of its own, *Group*, *Group 1* to *Group 40*, your raid's members (Saneroki, 2026-11-09: "all party members
    Like Party 1 and also on Role Tank, Healer, DPS", "Group 1, 2 to 40"); any number of them ticked, the dropdown naming
    those watched ("You, Tank"; Saneroki, 2026-11-07: "select multiple targets in its dropdown with checkboxes"); the last
    one ticked stays, as a reminder watches someone (one made in the window: a debuff on your target, a buff on you; one
    made on the frames: everyone). On a bar it shows while its settings want it on any unit watched, as one icon however
    many want it: its seconds those of the one whose aura runs out first, none while one of them lacks it; a member
    offline counts for none. On the unit frames and the group frames on each frame of one watched: *Tank*, on the tank's
    frame alone; *Everyone*, on all. On the nameplates alone *Watch on* is out of sight (each plate's unit watched), and
    on none of the bars *Delete bar*; *Display when missing*; *Display when active*;
    *Offset time*, with missing: so many seconds before it runs out it shows already, with the seconds left on the icon
    (on a bar and a nameplate); *Combat*: in and out, *Only show outside of combat* or *Only show inside of combat*; *Hide in
    rested areas* (cities, inns); *Only in groups*: only while you are in a party or a raid (Saneroki, 2026-11-09: "groups
    are raids and party"); *Ignore everywhere*: shown nowhere for now, its settings kept, to pause it (Saneroki,
    2026-11-09); *Only yours*: only your own cast of it counts (your HoTs, where another druid's Rejuvenation is no help);
    *When class in group*: *Not needed*, or one of the game's classes: shown only while you or one of your party or raid
    is of that class, in every place (Saneroki, 2026-11-07: "if a druid is in the party or raid it will then show that
    spell"; your own class counts too, "my own included", so a druid's *Druid* shows alone as well; the group's classes
    read again as it changes). Never
    while you are dead. What you show belongs to the character, watched by the aura's name, so any rank of it, on whom
    *Watch on* says. A group's version counts for the one: a Gift of the Wild for a Mark of
    the Wild, a Prayer of Fortitude for a Power Word: Fortitude, an Arcane Brilliance for an Arcane Intellect, any of
    your blessings for a blessing (which starts with *Only yours*).
  - **On the health bars** (the places *Unit frames* and *Group frames*, after the bars in the dropdown, each on its own;
    the switch *Aura icons on the health bars* on the page's group section): the aura is watched on your own frame, your
    target's and your focus's (*Unit frames*), or on every member the party and raid frames show, your own slot too
    (*Group frames*), on those *Watch on* takes in, and its icon floats over that frame's name, from the health leftwards,
    four at most in the order made. A tracking from before, on *Health bars*, is on both, watched on everyone where it
    is on no bar. A buff only on a unit you can help (none on a foe you target), a debuff on any. Not on
    the dead or the offline; a shout on your own party only. The class buffs no longer show by themselves: show each one
    you want there.
  - **On the nameplates** (the place *Nameplates*, last in the dropdown; Saneroki, 2026-11-07: "On those nameplates the
    trackers are shown directly underneath with no gaps"): the aura is watched on the unit of every plate the game shows,
    and its icon stands in a row right under that plate, from its left, the icons side by side, nothing between them nor
    between them and the plate, six at most in the order made, the seconds left on each. With *Nameplates* on, right under
    the plate's lowest row (its bar, your combo points, a cast's bar while one shows), as big as its debuffs above the bar,
    growing, shrinking and fading with the plate; without it, under the game's own health bar. A debuff only on a unit you
    can attack (your Sunder Armor missing on a foe), a buff only on one you can help; none on the dead; a shout on your own
    party only. Not on the plates the game keeps from addons (inside dungeons and raids every friendly plate) nor your own.
  - **The bars:** one at first, more by *New bar*, each with its own aura icons (*Shows on* ticks one on another, or on
    several). *Delete bar* deletes the chosen aura's bar (on several: the one picked) and puts what it held on the first
    bar left, its other places kept; the last bar stays.
    Invisible, only the icons of what shows now, side by side around the bar's middle, no glow. Placed in Edit Mode, where
    every bar stands with all it holds (but what is ignored everywhere). Out of a fight an icon on a bar works as a buff
    above a unit frame does (Saneroki, 2026-11-09: "The reminderbar icons should be clickable like the buffs in the aura
    view"): the mouse on it shows the aura's tooltip, a left or right click its menu, its marks and *Edit tracked...*, which
    opens the window on that tracking. In a fight and in Edit Mode nothing on them takes the mouse: your clicks go through.
  - **In a fight** the game hides most auras from addons, Forever's client all of them. What was on stays known until
    its time is up, and the offset counts on; then its icon shows. What comes during a fight the game does not tell, but
    your own casts: a cast of an aura watched counts as on for as long as that aura lasted when last seen out of a fight
    (else until the fight ends); on a bar on the units ticked that it was aimed at, by name (each of them on all where it
    reaches many or was aimed at none of them); on the party and raid frames on the member it was aimed at, so a Rejuvenation you cast
    on the tank takes its icon off the tank's frame until it runs out; on the nameplates on your target's plate (or a plate
    of the name it was aimed at). A plate that goes in a fight forgets what was known of its unit. A group's version (Gift of the Wild) or a shout
    counts on each member whose auras changed with it. An aura taken off early (dispelled, cancelled) is not told: its
    icon shows when its time would have been up.

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
    The offer's entries (`Core.Spellbook`) in a pool of the offer's frames (`Make(holder)`, `Set(frame, entry,
    width)`; a blank frame should it make none), placed as ours, no secure button over them (`Casts.Cover` takes our
    entries only); its Home on `homePane` (over the views, shown only while Home is chosen: hidden by us, whatever
    the offer can still do), `Surface(homePane, HomeHeader)` once and `Draw(surface, view1, view2 or nil)`, the page
    controls and the switch hidden there; Home chosen at each `Show(true)` while `Home.First()` (a key's tab is
    chosen after it, `Window.lua`); `Menu(root)` after the game's two lines; `Switch` a `UICheckButtonTemplate` left
    of the page controls (`Set`, then `On()` read back). `Core.Spellbook.Watch`: drawn anew while shown.
  - `Data.lua`: the tabs as the game's Camelot book makes them (`C_SpellBook.GetNumSpellBookSkillLines`,
    `GetSpellBookSkillLineInfo`, not `shouldHide`; General with `GetClassSkillLineInfo`'s icon; the pet's while
    `HasPetSpells` and `PetHasSpellbook`, `GetPetIcon`), each one group under its name; the game's filter
    (`SpellBookFrameMixin:ShouldDisplaySpellBookItem`) with flyouts loose; `Data.Search` over name and rank in
    every tab. With an offer (`Core.Spellbook.Offer()`: Abilities' `Book/Offer.lua`, Forever) its Home tab first
    (`{ key = "home", home = true }`, no bank), a skill line's tab with its `line`; `Data.Groups(tab, tabs)` adds the
    offer's `Spells(line, showRanks)` after the tab's own and each of `Sections(line, lines, hidePassives, showRanks)`
    as a group under its heading; `Data.Search` adds `Search(words, lines, showRanks)[line]` to each tab's finds. Such
    an element is `{ future = entry }`; the CVars `ShowAllSpellRanks`, `spellBookHidePassives` are passed on.
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
  (the widget turns as a texture does, counter-clockwise). Above them a frame with the leading line and its glow, the game's cast bar spark twice, added
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
- **The red error text** (`ErrorText.lua`). No CVar does this. `UIErrorsFrame` hears `UI_ERROR_MESSAGE`; the game's own `/uierrorsoff`
  stops that and mutes every sound effect (`Sound_EnableSFX`). Here the event alone, given back at standing down.
- **The action bars on the full screen** (`BarsWindow.lua`, the parts `bars` and `sidebars`): `Bars.SEATS` that show, each seated
  in its panel's body (`Core.Seat`), wide ones in one, tall ones in the other (present while there are any): in one they would
  shrink to nothing. The wide ones as they stand on the screen (`Arrange`: each bar's top left read while it is not seated, kept
  while it is; Saneroki, 2026-11-04: "directly stacked like they are in the not fullscreen view"), the whole in the panel's
  middle; the tall ones, and the wide ones where a bar's place is not plain, in lines from the left (`Flow`). Either at the
  largest scale, at most 1, at which all fit. `ActionBars.Seated`: every button shows and the bars
  stay in sight at rest. The game's stance and pet bars are left out. In a fight nothing moves; bars seated go back after it.
  Every icon at full brightness while seated (Saneroki, 2026-11-09): a hook after each button's `UpdateUsable` notes the
  game's colour and sets it white, given back when the bars leave (`Bright`); Sane Macros' faces are not dimmed then.
  The game sets each bar's strata at every grid change (`ActionBarMixin:UpdateFrameStrata`: MEDIUM, TOOLTIP while a spell
  is dragged), under the full screen's HIGH, so the bars went dark behind it after a drag until it opened again; the seat
  puts its layer back (`Core.Seat`, hooks after `SetFrameStrata` and `SetFrameLevel`). Each window is as large as its bars
  (`Part.Fit`, Core's board's `spec.fit`; `Content` at scale 1 with the room of what stands beside a bar out of its layout,
  `Beyond`: its shown `ignoreInLayout` children, Bar 1's page number and a paged bar's checkbox). Every bar switched on
  counts: `frame:IsShown()` is the game's `IsShownOverride`, switched on whatever Edit Mode's visibility; one that the
  visibility hides is shown by the game's own `ShowBase` while seated (`Reveal`, out of a fight) and hidden by its
  `HideBase` when the full screen goes, where the setting still hides it (`Conceal`, `SettingHides` as its
  `UpdateVisibility` reads it, after a fight).
  Every icon at full brightness while seated (Saneroki, 2026-11-09): a hook after each button's `UpdateUsable` notes the
  game's colour and sets it white, given back when the bars leave (`Bright`); Sane Macros' faces are not dimmed then.
  The game sets each bar's strata at every grid change (`ActionBarMixin:UpdateFrameStrata`: MEDIUM, TOOLTIP while a spell
  is dragged), under the full screen's HIGH, so the bars went dark behind it after a drag until it opened again; the seat
  puts its layer back (`Core.Seat`, hooks after `SetFrameStrata` and `SetFrameLevel`). Each window is as large as its bars
  (`Part.Fit`, Core's board's `spec.fit`; `Content` at scale 1 with the room of what stands beside a bar out of its layout,
  `Beyond`: its shown `ignoreInLayout` children, Bar 1's page number and a paged bar's checkbox). Every bar switched on
  counts: `frame:IsShown()` is the game's `IsShownOverride`, switched on whatever Edit Mode's visibility; one that the
  visibility hides is shown by the game's own `ShowBase` while seated (`Reveal`, out of a fight) and hidden by its
  `HideBase` when the full screen goes, where the setting still hides it (`Conceal`, `SettingHides` as its
  `UpdateVisibility` reads it, after a fight).
  The first layout (`Default`): Sane Macros (the part `macros`, [Macros/README.md](Macros/README.md)) its least width beside the
  others, the wide bars under it as high as they stand on the screen (at most what Sane Macros' least height leaves); without it, a
  strip along the foot of at most `MOST_SHARE` of the height.
- **The trainer** (`Trainer.lua`, Saneroki, 2026-11-09; Saneroki's picks: the spellbook beside a class, weapon or pet
  trainer, the Profession window beside a profession trainer): the parts `trainer` (`ClassTrainerFrame`, its addon
  `Blizzard_TrainerUI` loaded by the game on demand) and `profession` (`ProfessionsFrame`, `Blizzard_Professions`), each
  Core's `Core.Seat.Part`: seated in its panel while open, its `OnShow` and `OnHide` followed. The trainer's opening
  begins the talk: `IsTradeskillTrainer()` picks the occasion `profession`, else `trainer` (Board.lua's
  `Board.Occasion`, Core's board's occasions; the trainer as wide as its window, `Seated.Width()`, the other the rest,
  `spellbook` or, where ours is not, `game`). At a profession trainer `Trainer.Taught()` matches the services' skill
  line (`GetTrainerServiceSkillLine`) by name to the character's professions (`GetProfessions`, `GetProfessionInfo`:
  its skill line), one with a window to craft in (`C_TradeSkillUI.CanTradeSkillShowCraftingUI` of its first book
  spell); `C_TradeSkillUI.OpenTradeSkill` asks the server, and the game's own code shows its window
  (`TRADE_SKILL_SHOW`), never ours. Opened so, `C_TradeSkillUI.CloseTradeSkill` closes it when the trainer closes; one the
  player had open stays. The full screen came for the talk (`Window.Fill`): it goes back at its end (`Window.Back`).
  Off by the setting `trainers`. The trainer window's list and scroll bar, which the game pins on HIGH above the window,
  are lifted above the rest of it by Core's seat and given back after it (`Core.Seat`; Saneroki, 2026-11-11: "First time
  its empty but 2nd time it is working").
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
    `Bar.GREEN` (the game's `COMPACT_UNIT_FRAME_FRIENDLY_HEALTH_COLOR`, plain green without it), set in `Bar.Paint`:
    on a frame that tells foes (`face.foes`, the kind's `foes`: your target's and your focus's) `Bar.HOSTILE` (a nameplate's red)
    while `UnitCanAttack("player", unit)` says so, green where it says no or its answer is hidden; each power in the
    game's `PowerBarColor`; ranks and glow as on a plate. Hidden values (health, a creature's most, your threat against it)
    go to the bars, the glow's `SetAlphaFromBoolean` and the texts as they are.
  - `Text.lua` (`ns.UnitText`): the game's plate font (`SystemFont_NamePlate_Outlined`) at `Text.SIZE` 12; level
    and raid marker (`SetSpriteSheetCell`) left, health right (`Text.Short`, `Text.Percent`; hidden: the game's
    `AbbreviateNumbers` in `Text.STEPS` and `UnitHealthPercent` by its curve), the name from the left side's end up
    to the health's room (`Text.Layout`; the health's room as wide as its most, measured on a ruler of ours,
    `Text.SAMPLE` while a creature's most is hidden), none on your own frame (`face.noName`); each power's words at
    its bar's left in `Text.SMALL` 9 (`Text.Powers`; hidden: `AbbreviateNumbers` and `UnitPowerPercent` by its
    curve); the row's name alone, centred (`Text.Row`). A row's bar is the colour of its kind's `row.colour`: the
    targets' rows `Bar.CALM` (the nameplates' light yellow for a creature that does not attack on sight), the pet's
    green.
  - The button's height is the health's and its power slots' (`Units.HEIGHT + face.slots * Units.POWER`, `Slots`, out
    of a fight: in one it waits under the key `unit frame slots <unit>`): two on your own while you may have two powers
    (`Alternate`: a druid, or your power not mana while you have mana; asked again on `PLAYER_SPECIALIZATION_CHANGED`),
    else as many as the unit shows (`face.powersShown`); the face is the health bar's height, the rest hangs under it,
    the row under the slots or under the powers shown where there are more (`Bar.Fit`). The powers (`Bar.Kinds`): the
    unit's own; you as a druid in a form whose power is not mana (Core's `Core.FormPower`: for yourself alone) and
    your own `Alternate`, mana first and the unit's own second. Each power is read through `Bar.Read` (mana by Core's
    `Core.Mana`), the words too (`Text.Powers`).
  - `Auras.lua` (`ns.UnitAuras`): per frame and kind (`Auras.KINDS`: buffs, control, debuffs) a container of the
    game's (`CustomAuraContainerTemplate`, as the nameplates'), each on the frame's `roof` at its `point`
    (`BOTTOMLEFT`, `BOTTOM`, `BOTTOMRIGHT`): the game sizes a container to what it holds, so the one in the middle
    stays centred. `Auras.Line` (the kind's `most` icons and a pixel to spare, each icon's size given to the layout: the game's sizes
    come back rounded, and icons at exactly the line's width lost the last) is its widest line (`SetFlowLayoutMaximumLineSize`):
    what your list adds goes up, not sideways into the next kind. Groups of the kind's `most`, without spacing: `listed` (the filter
    `HARMFUL` or `HELPFUL` with `includeSpellIDs` = Important, off while that list is empty, its icons with a glow, so a
    fight needs no telling which is which), `shown` (Prioritize on unit frames, no glow) and `auto` (the kind's
    filter for a foe or a friend, `SetAuraGroupFilterString` as the unit changes, its sort `UnitFrameDebuff` or
    `BigDefensive`, `excludeSpellIDs` = what those two hold and what never shows; control only what never shows: Unimportant and Hide, less Show). The game applies those candidate filters
    itself, in a fight too, where it lets addons tell spells apart (`AuraContainerUtil.CanApplyIdentityCandidateFilters`).
    Each icon (`initializeFrame`, `Dress`): the picture cropped, no edge, the swipe (`SetReverse`: dark over the time gone, driven by the
    game in a fight too), its numbers off (`SetHideCountdownNumbers`), the count, its name into a
    the outline's loop started by hand. Those are the game's icons, in a fight. **Out of a fight our own row** (`AuraRow.lua`, `Auras.Set`
    picks by `Row.Open`): the game runs no script of an addon on its icons, and that goes for every child of one
    (`AuraButton`'s `UntrustedScriptExecution`, which propagates by hierarchy); their regions' secret aspects hide what they show
    at all times, the owned frames (`GetAuraGroupFrame`) come in the pool's order, and the tooltip they open is forbidden. So
    the row reads the same filters itself (`C_UnitAuras.GetUnitAuras`, `Auras.Sets` for your marks, by the spell's number), and
    each icon, a frame of ours on `face`, knows its aura: `OnEnter` asks `GameTooltip:SetUnitAuraByAuraInstanceID`, as the game's
    list does, for Tooltips to draw, and is a door of the frame's `Core.Rest` (`face.aurasArea` its area over the row, no
    mouse); `OnMouseUp` opens `Lists.Menu`, left or right. Places on `face.roof`, `Place`. `UNIT_AURA` of you, your target and
    focus fills it a frame later; `PLAYER_REGEN_*` and `ADDON_RESTRICTION_STATE_CHANGED` swap row and containers
    (`Auras.Set` at `face.auraAsked`). `Auras.Set` sets each container's unit (`none` while ours show), `UpdateAllAuras` at every fill.
  - `Lists.lua` (`ns.AuraLists`): the settings `auraWhite`, `auraBlack`, `auraHidden`, and `auraShow`, `auraHide` (`{ [spell number] = name }`), one list of
    each side per spell (`Lists.SIDE`; `Put`, `Take`, `Unmark(which, name)`, `Forget(name)`, then `Auras.Refresh`, `BuffList.Style`); `Mark(name)` by name, for the ranks; `Entries` the menus' lines; and `auraKept`, the window's own list: every spell put on a mark or picked
    in the search, with a mark or none, until its X (`Forget`: off every list, and its reminders `Reminders.Take`). The
    window *Edit tracked* a `Core.Window` panel (`auraListsPlace`, not sizable, no full screen): one scroll list of every
    name on any of them or a reminder's (`Rows`), each line the game's close button (its template stands at frame level 510:
    set to its line's), icon, name, number, a `UICheckButtonTemplate` per mark in `Lists.COLUMNS` (Hidden, Unimportant,
    Important), `line.cog` (a button of the game's cog atlas `Lists.COG`, its tooltip and its column's words
    `reminderTitle`, *Edit Tracked conditions*: the line chosen) and `line.remind` (Reminder: `Reminders.Make` of the
    line's spell, a debuff on your target by `C_Spell.IsSpellHarmful`, else a buff on you; `Reminders.Take`; the line
    kept), their words over the columns (`Middle`: from the right, Tracked last, the cog before it); `OnMouseUp` chooses
    the line (`chosen`, by name), and `ReminderEditor.Show(reminder, name, icon, id)` puts
    `Reminders.Named(chosen)` in the panel under the list (`Reminders/Editor.lua`, titled `reminderTitle`; none: the
    button *Add tracking* and `reminderNone` beside it, both anchored by their tops; *Delete bar* hidden on none of the
    bars, `Reminders.OnBar`, *Watch on* on the nameplates alone); under the settings, for the aura chosen, tracked or
    not, the marks `Editor.MARKED` (Hide from unit frames, Prioritize on unit frames: `Lists.Put`, `Lists.Unmark`,
    `Lists.Has(which, name)`). `line.mark`
    (chosen) and `line.lit` (just picked) stop where the ticks start: under them a tick looked greyed out.
    `Track(spell)`: *Add tracking*, the menu's (`Reminders.Entry`, its last line, a button `trackAdd`, none where a reminder
    of that name is: `Entries`' *Edit tracked...*, `auraLists`, opens it there) and the panel's (nil: the line chosen): kept, `Reminders.Make(spell)` (the first bar) where none is, `Open`
    on it. The search box `AuraSearch.Box` over all. `Open(text, name, reminder)` searches at once, chooses that name
    (that reminder's line: the menu's *Edit tracked...* of an aura bar's icon, `spell.reminder`). `/sane
    auras [words]` and `/sane reminders` (`Core.Command`).
  - `AuraSearch.lua` (`ns.AuraSearch`): what the search finds, read once at the first search from Core's sets: each class
    (`Classes`, 1 to `CLASSES`) its class lines' spells (`SkillLines` by `byClass`, kind `class`) that put an aura on
    (`Spells`' effects with an aura; one without effects counts), the enemies' (`CreatureSpells`) and the items' (`Auras`)
    by Data's jobs, a part per frame out of a fight; one entry per name in a group. `Find(text, done)`: `Core.Fuzzy.Filter`
    over the names, then the groups by their best rank, your own class first where two are as good; a spell's number
    first (`C_Spell.GetSpellName`); without the sets (Retail for now) a name finds a spell of your own (`C_Spell.GetSpellInfo`).
    While the sets are read `done` gets what the game found with `reading`, then again. `Lit(entry, text)` the name with what was typed in gold.
    `Box(parent, x, y, opts)` the search box (`InputBoxTemplate`, searched `WAIT` after the last key) and under it the
    suggestions, a frame of their own over what lies below (`FIND`: 16 lines at most, each group its title and its best,
    at least `per`); Enter takes the first, Escape empties it; Up and Down light a find as the mouse would (its tooltip),
    round at the ends, and Enter takes the lit one (`Core.Fuzzy.Keys`); `opts.pick(entry)`. `Icon(id)`, `Tip(owner, id, name)`.
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
  it shows. In Edit Mode it shows, to be placed. Its alert of unopened collection items (Saneroki, 2026-11-06: it came
  back at every login, under the minimap where his menu bar rests): the game shows it at each login while
  `C_MountJournal.GetNumMountsNeedingFanfare` or `C_PetJournal.GetNumPetsNeedingFanfare` is above its count of the
  session (0 at first). A hook after the tip's `HandleAcknowledge` (its close button) keeps both counts in
  `ns.store.unopened`, the account's; a hook after `MainMenuMicroButton_ShowAlert` finds the tip in `HelpTip.framePool`
  by its `info` (system `MicroButtons`, `CollectionsMicroButton`, the game's `COLLECTION_UNOPENED_*` words) and, while
  neither count is higher, takes its alpha and the mouse (its own and its close button's), given back by a hook after
  its `OnHide`. No function of the game's that writes its state is called: the alert system and the tip pool stay
  untainted, and to the game the alert still shows, so lower ones of the menu bar wait behind it, as before it is
  closed. Hooks after `ClearFanfare` (an item opened in the collections window) lower the counts kept to those
  waiting.
- **Look out for** (`Units/LookOut.lua`, `ns.LookOut`; setting `unitLookOut`, under `unitFocus`): `FocusUnit` is
  restricted (`HasRestrictions` in the newest export), so the place is the game's secure button `SaneUILookOut`
  (`SecureActionButtonTemplate`) anchored over the focus button's top, as high as its health bar, at its scale:
  `*type1` and `*type-Key` run `macrotext` `/focus [@focus,noexists] <name or unit>` (`LookOut.LINE`; the game's
  `/focus` hands the name to `FocusUnit`, which knows the names of your group alone), and for a name after it the
  target's way (`LookOut.Lines(target, named)`): `/stopmacro [@focus,exists]`, `/targetexact` the name, `/focus
  [@target,exists] target`, your target back: with one, `/cleartarget` first and `/targetlasttarget` last
  (`LookOut.KEPT`; a name not near focuses nobody), without, `/cleartarget` last (`LookOut.BARE`). Both stand on the
  button (`sane-kept`, `sane-bare`), and its snippet (`SecureHandlerBaseTemplate`'s `WrapScript` on `OnClick`,
  `LookOut.SNIPPET`) puts the one for `UnitExists("target")` into `macrotext` as it is pressed, in a fight too. Set out of a
  fight only (`Arm` through `Core.AfterCombat("look out")`; `wanted` the text for what is watched now, `armed` the one on
  the button: while they differ the words say *after the fight*). `RegisterForClicks("AnyUp", "AnyDown")` with `useOnKeyDown` from `ActionButtonUseKeyDown` (again
  at `CVAR_UPDATE`): a mouse click acts on its release, a key on the edge the setting says. The right button has
  no type: `PostClick` opens the field; the left opens it while nothing is found; a press (`down`) and the key's
  click (`Key`, `Bindings.xml`: `CLICK SaneUILookOut:Key`) never. A state driver shows it (`LookOut.DRIVER`,
  `[@focus,exists] hide; show`); in Edit Mode and while off it is unregistered and hidden. Its look is a frame of
  ours on it (`spot.look`: `UnitBar.Plate` outline and dark, `Around` rounded as the frames, the plates' font by
  `UnitText.Font`), `LookOut.WIDTH` wide as the button, `Units.WIDTH` while something is watched or the field is
  open (it grows in `LookOut.OPEN` seconds, an `OnUpdate` on a frame shown only while growing); the edge gold
  (`UnitBar.RANKS.elite`) while found; its alpha 1 while found, open or under the mouse. The field is an `EditBox`
  (`Core.Caret`) with the game's close button (X) and plus button (+, `AuraLists.PLUS_ART`; a menu of
  `MenuUtil.CreateContextMenu`, the raid in a grid of four). `LookOut.Parse`: `@tank` and `@healer` a role (the first
  of your group with it by `UnitGroupRolesAssigned`, not you, again at `GROUP_ROSTER_UPDATE` and
  `PLAYER_ROLES_ASSIGNED`), `@party1-4` and `@raid1-40` a unit, else a name without brackets or semicolons. A name is
  found (`Find`) on `nameplate1-40`, then your group, then `target`, by `UnitName` or `Core.FullName`, any case; a
  name the game answers hidden is neither (`Matches` gives nil), so one found stays found while its token stays
  (`NAME_PLATE_UNIT_REMOVED`, a new target, the roster drop it). Its events hear only while something is watched.
  Kept per character (`Core.Character(ns.name).lookOut`, the text). Standing down: alpha 0 at once, off after the
  fight (`LookOut.GiveBack`, from `Units.GiveBack`).
- **Out of sight at rest** (`Core.Rest`, Saneroki 2026-11-01; settings `unitRest`, `barsRest`, on at first; under
  them `unitRestGroup`, `barsRestGroup`, off at first: at rest in a group too, `rest:InGroup`, 2026-11-07): what
  shows when, and why your health is told from its changes, stands in `src/Core/Rest.lua`. Your frames are a set each
  (`Units.lua`, `kind.rest`): the mouse on a frame, its row or its aura icons shows that frame alone, and a cast
  or a timer on it does too (`Running`; `Bar.Fit` looks again as they come and go), since nothing else shows them and
  you need your breath under water. The action bars are one set (`ActionBars.lua`): `Bars.BARS`, each hot, each of
  their buttons a door, so the mouse on one shows them all; what stands beside a bar out of its layout (a child marked
  `ignoreInLayout`: the main bar's page number and arrows, a druid's Bar 6 pager of Abilities) holds the mouse as the bar
  does, asked each time (`Beside`); held in a vehicle (`HasVehicleActionBar`,
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
  `Group.Filled()` what the group fills, `Group.Columns()` with the half column beside a party (`groupBeside`, in a party
  only): `beside`, a `SecureFrameTemplate` shown by the state driver `Group.BESIDE_SHOWN`, two `SecureUnitButtonTemplate`s
  per slot (`beside.targets`, `beside.pets`) on fixed units, `Group.Beside(slot)` (`party1target`, `partypet1`; you `target`,
  `pet`), placed by `Layout` right of the header's slots (a party's header lists you, then party1 to party4, in that order),
  the target in the top half, the pet in the bottom one, each half a slot wide and high, shown by `RegisterUnitWatch`; their
  faces small (`Face.Make(button, nil, true)`: the name alone, `UnitText.SMALL`, centred), filled as they show and, a target's, every `Group.READ`
  seconds (no unit event names `party1target`). `GROUP_ROSTER_UPDATE` lays out again after a fight. Preview: `Face.Make(preview, true)`
  plain frames, `Roll` once per count. The game's `PartyFrame` (which holds `CompactPartyFrame`), `CompactRaidFrameContainer` and
  `CompactRaidFrameManager` stand in a hidden frame (`Core.Lend`). A ready check's result stays `Face.READY_HOLD` seconds (the game's
  `CUF_READY_CHECK_DECAY_TIME`) after `READY_CHECK_FINISHED`; who has not answered is not ready, as the game has it.
- **What floats on the left (`Units/GroupFace.lua`):** `face.floating`, over the words: `ready`, `rez`, the dispel icon, each anchored to the last's
  right, an empty one as wide as nothing. The dispel icon's container comes last because nothing of ours may be anchored to it: it sizes itself by
  what it holds, so once it has an aura group it has the forbidden aspect `UntrustedLayoutScriptExecution`, and the game refuses the anchor of whatever lacks that (`CustomAuraContainerSharedMixin`). It may hang on anything of ours (`marks:Place`). They are the frame's height less
  `Face.BIG_OFF`. On the line under them `level`, `raid` and `name` hang on each other; `name` ends at the health's room.
- **The group's tools (`Units/GroupTools.lua`):** nearly all a raid manager does is `HasRestrictions`, off limits to addon code (markers,
  `DoReadyCheck`, `DoCountdown`, `SetEveryoneIsAssistant`, converting), so nothing of that is called: `SecureActionButtonTemplate`s of the types
  `raidtarget`, `worldmarker`, `togglemenu` (unit `player`) and `click`, whose `clickbutton` is the game's own button in
  `CompactRaidFrameManager.displayFrame` (`readyCheckButton`, `rolePollButton`, `countdownButton`, `everyoneIsAssistButton`). With secure buttons
  the panel is protected, so its opener and close button are `SecureHandlerClickTemplate`s, which work in a fight. The opener lies on the cog
  of the button whose face has your unit (`face.mine`), at the slot's left (`Tools.Over`: the cog's middle `Face.INSET` +
  `Face.ICON` / 2 from it), moved after the fight if the group changes in one. On that face `Yours` starts the line
  `Face.MINE` farther in (the empty `level` that leads the raid marker and the name, the ready check's icon, the role's mark). Threat may be hidden in a fight
  (`ShouldUnitThreatStateBeSecret`): addon code cannot turn a hidden number into a colour (a curve's `Evaluate` takes no secrets from addons), so the border stays black then.
- **One unit (`Units/GroupFace.lua`):** its parts are the unit frames' (`UnitBar.Plate`, `Around`, `Strip`, `End`, `Ends`, `Power`;
  `UnitText.MakeLine`, `Raid`, `Mark`, `Name`, `Health`, `Sample`), without the glow's plates: forty frames stay light. `Face.Unit` follows
  the button's `unit` attribute (`OnAttributeChanged`, in a fight too) and registers that unit's events. `face.compact` and `face.bare`
  are told to `UnitText.Health`; `MakeLine` takes its tighter inset and gap; `face.floating`, a frame over the words, holds the icons, and
  `face.roomed` places your buffs' icons after each layout. `face.tint` (`Face.Tint`, at each fill): a player's class colour from the
  game's `RAID_CLASS_COLORS` (`groupClass`), a creature's by `UnitReaction` (4 `UnitBar.CALM`, under it `Face.HOSTILE`, the game's
  `FACTION_BAR_COLORS[2]`), else `UnitBar.GREEN`. The power line on every member (`Power`): `UnitPowerType`, a healer's mana
  where `UnitPowerMax` has one, `UnitBar.Power` (none where the most is 0); you as a druid in a form (`Core.FormPower`,
  for yourself alone) your mana there and the form's power in `face.form`, the same line along the bar's top; the
  samples' by class (`Group.POWERS`; `face.form` hidden). Aggro: a
  plain `UnitThreatSituation` paints the border (`Face.AGGRO`, 2, up: `Face.AGGRO_BORDER`); a hidden one (a fight) leaves it
  black and goes as it is into `face.threat` (`Face.Threat`: its `SetValue` gives both halves the value), two `StatusBar`s
  over the border (`edges` one level under them, the health over them), the face's upper and lower half, of
  `UnitBar.WHITE` in the red, each rounding its own two corners by masks of `Core.Shape.CORNER` as round as the border's
  (as `UnitBar.Plate`: the game refuses a texture a fourth mask since build 70862, `threat.corners` all four), bounds
  `Face.AGGRO - 1` to `Face.AGGRO`: full from aggro up, empty under it, never compared.
- **Reminders on the frames (`Reminders/Group.lua`):** a reminder with `Reminders.GROUP` (-3, *Group frames*) or
  `Reminders.FRAMES` (-2, *Unit frames*) among its `places` (`Reminders.At`; `IsFrames`), that watches the face's unit
  (`Reminders.Watching`: `Takes` of an entry, the same unit by `UnitIsUnit`, its role by `Reminders.Role`, everyone by
  `group`); `Wanted` asked with that place (no `foe` check: a member's debuff is on a friend). `GroupReminders.Show(face,
  unit, place)` puts its icons on a face (`GroupFace.Icons`, `Roomed`): a member's (GROUP), and a unit
  frame's (`Units.lua`: `face.floating` over the words, `Units.ICON`, at each fill and its unit's `UNIT_AURA`, in `Units.EVENTS`;
  `Units.Each`); a buff only where `UnitCanAssist`. `GroupFace`'s
  `Buffs` asks `GroupReminders.Missing(unit, list)` on a fill, on `UNIT_AURA` (out of a fight only one that may change what is seen:
  `Buffed`), and `GroupReminders.Refresh` asks every face (`Group.Each`) when a reminder changes, a fight begins, resting changes, and
  each `GroupReminders.EVERY` second while one has an offset. What is known is kept per reminder and member GUID
  (`Reminders.Known`, the bars' own look). In a fight (Forever's client hides every aura, its instance, `GetAuraDuration` and
  `GetUnitAuraInstanceIDs`' list from addons; your own casts are plain) a known state holds until `ends` by the clock (past it,
  renewed only where `GetAuraDuration` still answers for its instance); `GroupReminders.EVERY` a look each second from
  `PLAYER_REGEN_DISABLED` to `_ENABLED`. Your `UNIT_SPELLCAST_SUCCEEDED` of a name watched, its target's name from the
  `UNIT_SPELLCAST_SENT` of the same cast GUID (`UnitName` or `Core.FullName` of a face's unit): that member on, `ends` from
  `reminder.lasts[name]` (saved, learned at each plain read, `data.duration`: `Reminders.Ends`); no name of the frames, or
  `Reminders.Many` (a family's later names, a greater blessing, a shout): each member whose `UNIT_AURA` came within
  `GroupReminders.WINDOW` of it, before or after.
- **Reminders on the nameplates (`Reminders/Plates.lua`):** a reminder with `Reminders.PLATES` (-1) among its `places`,
  *Nameplates*.
  `NAME_PLATE_UNIT_ADDED`, `_REMOVED` follow each plate's unit (`C_NamePlate.GetNamePlateForUnit`; none for a forbidden plate
  or `player`), its GUID taken as it comes; `PlateReminders.Update`, last in `Reminders.Update` on its ticker (which runs while
  any reminder is off the frames: `Looked`), fills each plate's row: `Reminders.Known` per reminder and GUID, `Wanted` on the
  plate's unit (its `foe` check: a debuff only where `UnitCanAttack`), a buff only where `UnitCanAssist` is plainly true,
  `Reminders.Reaches`, `PlateReminders.MOST`. The row (`PlateReminders.SIZE` icons, `ReminderBars.Icon`, no gap) is made at a
  plate's first icon and kept per plate. Its place: `SaneUI.Nameplates.Plate.Foot(plate)` (asked by `Core.Ask`, nil while that
  module is off or does not dress the plate), a frame of the dress at its frame level + 6 kept under the lowest row by
  `Bar.Outline`; the row on it, by its `TOPLEFT`; else on the plate under the game's `UnitFrame.HealthBarsContainer`. Asked at
  each fill, so it moves on as soon as Nameplates dresses the plate or stops. Your cast (`Reminders.lua`'s `Cast`):
  `PlateReminders.Cast(name, target)` on the plate `UnitIsUnit(unit, "target")` (where the sent name is its) or the first of
  that name, `ends` by `Reminders.Ends`. A plate removed forgets its GUID's states.

- **The aura history** (`AuraHistory.lua`, the part `history` on the board, `Board.ORDER` after `macros`, not in the first
  layout): it shows what Core keeps (`Core.AuraLog`, `src/Core/AuraLog.lua`: every data set and its gathering are
  Core's), filled only while its panel shows (`Part.Show`; `AuraLog.Listen` asks a fill a frame later). A
  `WowScrollBoxList` of lines `History.ROW` high (`SetElementExtent`), newest first; `History.COLUMNS` from the right at
  fixed widths, the name taking the rest (`History.LEAST` 660 wide). The icon a frame of ours with `UnitAuras.Paint`:
  `OnEnter` asks `GameTooltip:SetUnitAuraByAuraInstanceID` while `AuraLog.Live(entry)` gives its unit and instance
  (the GUID still on that unit, the aura still there), else `SetSpellByID`; `OnMouseUp` opens `Lists.Menu` with the
  spell as `AuraRow` hands it (`unit = "target"`, so *Add tracking* watches your target). The kind shown is
  `store.auraHistoryShow` (`History.SHOWS`), the dropdown `WowStyle1DropdownTemplate` with its radios and *Clear
  history* (`Core.Confirm`, then `AuraLog.Clear`); `Part.Search` filters by name or `on`. `History.Open`:
  `Window.Open("history")`. The clock through `Core.ClockAt(stamp, true)`; durations `History.Span` (45s, 2m 10s, 1h 5m).
  Core's log: the units of `AuraLog.UNITS`, boss1-5 and each nameplate's (`NAME_PLATE_UNIT_ADDED`), each by its own
  `UNIT_AURA` (`Core.OnUnit`) a frame later, in a fight at most each `AuraLog.FIGHT` seconds; `C_UnitAuras.GetUnitAuras`
  per kind read under `pcall` (a table the game keeps closed errors when indexed), only auras whose `auraInstanceID`
  and `spellId` are plain, by `[GUID][instance]`: one new is an entry, one gone is closed (`gone`) only where the whole
  list was plain (`Open()`: no restriction, `C_Secrets.ShouldAurasBeSecret` no). `PLAYER_REGEN_ENABLED` and
  `ADDON_RESTRICTION_STATE_CHANGED` look at every unit again; an aura on for a while came at `expirationTime -
  duration`. Its cast: `UNIT_SPELLCAST_START`/`_CHANNEL_START` (`UnitCastingInfo` 8th answer, `UnitChannelInfo` 7th:
  `notInterruptible`), `_INTERRUPTIBLE`/`_NOT_INTERRUPTIBLE`, a `_SUCCEEDED` not begun before is instant; matched by the
  aura's source GUID and the same spell within `AuraLog.CAST` seconds. Kept in `Core.Character(Core.name).auraLog`, the
  last `AuraLog.MOST` (1000). Your casts: `UNIT_SPELLCAST_SENT` of `player` (its target's name by cast GUID) and
  `_SUCCEEDED`, while `Open()` is no, of a spell `AuraLog.Leaves` (Core's set *Spells*: an effect with an aura; or one of
  *Auras*): `kind = "cast"`; an aura of yours seen later on the one it was sent at within `AuraLog.MERGE` seconds of
  it fills that entry (`Yours`). A fight's spells (`Fought`, `AuraLog.AFTER` after `PLAYER_REGEN_ENABLED`, or when
  the restriction ends): the newest of `C_DamageMeter.GetAvailableCombatSessions` not read yet (`read`, the newest
  at the login), for each of `AuraLog.METER` its `combatSources` and each one's `GetCombatSessionSourceFromID`
  `combatSpells` under `pcall`: `kind = "fight"`, `what`, `from` (the member, its pet by `creatureName`), `on`
  (`combatSpellDetails.unitName`, else the session's name; for damage taken the two swapped), `fight`; one per what,
  spell, from and on (damage taken: per foe, `hits`), not `AuraLog.SWINGS`, not yours logged as casts in that fight.
  The view: `History.SHOWS` with `fights`; such lines' kind words `historyCast`, `historyWhat_<what>`, `+N` after
  `on`, `historyFight` under the time. Shared (`Send`, `Heard`): after a fight your casts of it (`fight.mine`, those
  folded into their aura too), at most `AuraLog.SENT`, as one block of `Core.Wire` of the kind `AuraLog.KIND` (F) to
  `RAID`, `PARTY` or `INSTANCE_CHAT`, a line each "spell, the server's time (`GetServerTime`, so neither the
  members' clocks nor the wire's waiting matter), whom at", once per fight; the wire sends nothing in a fight or
  under the game's chat lockdown. Taken in (`Wire.ListenBlock`; never a whisper): each line checked (digits, within
  `AuraLog.OLD` back, a name of 80 bytes at most), at this computer's time; an aura of that member's on that one
  within `AuraLog.HEARD` seconds is it (`shared`), one heard already left, else `kind = "cast"`, `shared`, `from` the
  sender's key. `AuraLog.Share(on)` from Combat's `auraShare` (`History.Apply`). `dev/tests/aurahistory.lua`.
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
  the first line's `drag` frame shows only on hover, `window:DragBy` (Core). *Lock window* (`meterLocked`) is the window's
  `usable` (`Free`): false while locked but in Edit Mode, so Core's `Draggable` and the hover grip say no (`Grip` hides it,
  `Meter.Apply` asks again by `handle:Hover`), while Edit Mode's box and grip still work.
  - **Which bars:** `Shows.Of(person)`: the ticks, but for `store.meterPeople[guid] = { [kind] = true or false }`, only what
    differs from the ticks; a saved fight keeps each GUID so its people have theirs. So rows differ in height: the list's extent is
    a calculator, `Fit` takes whole rows from `first` (the wheel moves it, a character a notch), and the scroll box is exactly as
    high as they are, scrolled by `ScrollToElementDataIndex`. A row's `line`, a button over its name that only shows on hover,
    takes the right click; on the first line `drag` lies over it and takes it. `Types` reads what anybody has (`Shows.Wanted`).
  - **In sight:** `Wanted()` (Edit Mode, a saved fight, or both Hide ticks satisfied). With *Show on mouseover*
    the frame stays shown and only `block` goes, so `Core.Hover` still hears the mouse's coming; without, the frame hides. Hidden, nothing is read.
    Combat's full screen hides the frame whole (`Meter.Cover`, from `Window.lua`'s `filled` as it begins to fill and its `docked`), so
    nothing of it, not even the mouse's coming, is on or over the full screen; its old second place `meterFullPlace` is no longer read.
- **Reminders** (`Reminders/`): `Core.Character(ns.name).reminders`, a list. Where one shows: its `places` (*Shows on*), a
  list of bar numbers (above 0), `Reminders.FRAMES` (-2), `Reminders.GROUP` (-3) and `Reminders.PLATES` (-1), one at
  least, in Editor's `Places` order (`Put`, the last one ticked staying); `Reminders.Places` reads an older one's single
  `bar` into it, and an older one's `Reminders.HEALTH` (0, *Health bars*) as `FRAMES` and `GROUP`, its `units` `{ "group" }`
  where it is on no bar (at `Start`, which drops a bar there is no more, and on any read), `Reminders.At` asks for one
  place, `IsBar` (above 0), `IsFrames` and `OnBar`. `Update` looks at a reminder on the bars once (`Shown`) and puts its
  icon on each bar ticked, `{ icon, left, reminder }` (`ReminderBars.Fill`: `EnableMouse` on each icon while
  `InCombatLockdown` and `Core.EditMode.active` are not, changed only when it differs; `OnMouseUp` `AuraLists.Menu` of
  the reminder's aura, `OnEnter` `AuraSearch.Tip`); `Wanted` takes the place it is asked for (`IsFrames`: no `foe`
  check), after `Reminders.Allowed`, the conditions of every place: `ignore` (*Ignore everywhere*, out of Edit Mode's
  bars too), `combat`, `noRest` (*Hide in rested areas*), `inGroup` (*Only in groups*, `IsInGroup`), `class`, you alive. `TakeBar` takes the bar out of each reminder's places, the first bar left in where it is
  not already. Editor: `Editor.Where` the dropdown's words (`OverrideText`), `Says` the words beside the name (the
  health bars' and the nameplates' in a row), `NewBar` the new bar in place of the reminder's bars, `TakeBar` a menu
  of its bars (`MenuUtil.CreateContextMenu`, titled *Delete bar*) where it is on several. An aura may have several (`Reminders.Copy`, a copy of every field right after the original; `Named` gives the first): the window's `Rows` gives a line `{ id, name, reminder }` for each, `Current` the one chosen (`chosen` the name, `pick` the reminder), `Drop` the X (that reminder alone where its name has more). `class` (a class token, *When class in group*): `Reminders.Wanted` asks `Reminders.InGroup`, the tokens of you and your party or raid (`UnitClass` of `player`, and of each `party`/`raid` unit that `UnitExists`), read at most once a second and anew at `GROUP_ROSTER_UPDATE` (then `Reminders.Apply` once a frame). `Reminders.Update` runs on a ticker every
  `Reminders.EVERY` seconds, only while there are reminders on bars or the nameplates and the setting is on: it looks at each aura
  (`Reminders.Aura`: `C_UnitAuras.GetAuraDataBySpellName`, the name for the ranks, each name of `Reminders.FAMILIES`, `PLAYER`
  with *Only yours*) on each unit of the reminder's `units` (*Watch on*, Editor's checkboxes in `Editor.UNITS`'s order:
  `player`, `target`, `focus`, `group`, `tank`, `healer`, `dps`, `party1` to `party4` and, in a submenu (`raidMenu`,
  four across), `raid1` to `raid40`; one at least; `Reminders.Units` reads an older reminder's single `unit` into the
  list, at `Reminders.Start` and on any read; `Find` takes a reminder that watches the spell's unit too), as
  `Reminders.Watched` makes them units, each once (a role: each of `Reminders.Members()`, `PARTY` with you or `RAID`,
  whose `Reminders.Role` it is, `UnitGroupRolesAssigned` or a main tank; `group`: all of them), and hands each bar what
  shows: one icon where `Wanted` says so for any of them (one offline, or one a party's family does not `Reaches`,
  counts for none), the fewest seconds left of those, none while one is missing (`Shown`). What was known is kept per
  reminder and unit (`seen`); a new target forgets your target's, a new focus your focus's, a group changed its members'. A cast in a fight
  (`Given`): on the units watched whose `UnitName` (or `Core.FullName`) is the name `UNIT_SPELLCAST_SENT` gave, on all
  of them where none is, or the name reaches many (`Reminders.Many`). Editor's dropdown words: `Editor.Watched`,
  set by `OverrideText`. `Hidden` asks
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
  `BuffList.Alert`, the game's `ActionButtonSpellAlertTemplate` made by us, 1.4 times the icon as the game's (its size through
  `Core.Plain`: a fight the icon showed in hides that, past its end, so `BuffList.ICON` stands in), only its loop;
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
| `Trainer.lua` | The full screen at a trainer: the game's trainer window seated on it beside the spellbook, or beside the game's Profession window; the parts `trainer` and `profession`, a layout of its own for each kind of talk |
| `Keys.lua` | Your spellbook, pet book and talents keys opening ours |
| `QuestMarks.lua` | A mark beside a creature's nameplate while it belongs to an objective of your quests still to do |
| `MouseRings.lua` | Rings around the mouse for the global cooldown and your cast, only while they run, centred on the cursor's picture |
| `Units/Bar.lua` | A unit frame's bars in a nameplate's look: one round outline, its border, the rank's line, the glow; the green health bar (your target's and focus's red on a foe), the power bars under it (your druid's mana and form), the row |
| `Units/Text.lua` | The line inside it: level and raid marker left, then the name, the health right; each power's words; the row's name |
| `Units/Auras.lua` | The auras that matter most around a frame: which, where, the game's own aura containers in a fight |
| `Units/AuraRow.lua` | Those auras out of a fight, on icons of ours: your tooltip, the menu, a frame at rest shown |
| `Units/AuraSearch.lua` | What Edit tracked's search finds: every class's auras, the enemies', the items', from Core's sets, in groups; its box and suggestions |
| `Units/Lists.lua` | Your marks: Important, Unimportant, Hidden; Prioritize on and Hide from unit frames; the one menu of an aura or spell (`Lists.Menu`), and the window Edit tracked (`/sane auras`, `/sane reminders`): one list with a tick per mark of the game's list, a cog (Edit Tracked conditions) and Tracked, the search, the chosen line's reminder under it |
| `Units/BuffList.lua` | The game's list of your buffs and debuffs: the game's outline, fade, hidden last, the left click |
| `Units/Cast.lua` | A unit's cast as part of its frame, directly above the health bar, in place of the game's cast bar |
| `Units/Timers.lua` | Your breath and the game's other timers on you as part of your frame, in place of its bars |
| `Units/Units.lua` | Your frame, your target's and your focus's, and the rows under them (their targets, your pet): the game's secure unit buttons, placed in Edit Mode; the game's own out of sight; each out of sight at rest |
| `Units/LookOut.lua` | Look out for, in your focus's place while you have none: the field, its + and X, the watch on nameplates, group and target, the game's secure button that focuses who it found on your click or key |
| `Units/GroupFace.lua` | One member's frame: a nameplate's bar, marker, name, health, the power line, aggro in a fight too, the icons; live or made up |
| `Units/GroupTools.lua` | Your own slot's button and its panel of the group's tools, in place of the game's raid manager, by the game's secure means |
| `Units/Group.lua` | The one window for party and raid: the game's secure group headers, beside a party each member's target and pet, sizes, Edit Mode's settings and preview |
| `BarsWindow.lua` | The action bars as windows of the full screen, seated, so that nothing lies over them |
| `ErrorText.lua` | The game's red error text off, by a switch |
| `Macros/` | Sane Macros: macros and sequences, keys and bar buttons, the + list, the checks ([its README](Macros/README.md)) |
| `ActionBars.lua` | The game's action bars clean: only the buttons that hold something, each its icon alone; out of sight at rest, as one set |
| `GameBars.lua` | The game's experience and stance bars out of sight, its menu bar on mouseover, its alert of unopened collection items closed for good |
| `Meter/Threat.lua` | The meter's threat: every member's share of the mob, its gains added up per fight |
| `Meter/Read.lua` | Who is in the group, and a fight's numbers from the game's meter, hidden or not; what the list can be sorted by |
| `Meter/Shows.lua` | Which bars a character has: the window's ticks, or their own |
| `Meter/Fights.lua` | Which fight is shown: the pages, the live page, the saved fights |
| `Meter/Row.lua` | One character: their line and a bar per thing shown |
| `Meter/Controls.lua` | The buttons at the end of the first line, and the flyouts |
| `Meter/Meter.lua` | The window: its place, out of sight under the full screen, the list of whole rows, grown down or up, when it shows, the game's meter out of sight, the looks in a fight |
| `Reminders/Reminders.lua` | The reminders and bars: kept per character, the families of names, what is known of an aura, in a fight too, whether one shows, the looks |
| `Reminders/Group.lua` | The reminders on the party and raid frames: on each member, in a fight your cast matched to the member who got it |
| `Reminders/Plates.lua` | The reminders on the nameplates: a row right under each plate, on Nameplates' dress where it dresses it, in a fight your cast on your target's plate |
| `Reminders/Bars.lua` | The invisible bars: their places in Edit Mode, the icons side by side, as wide as what shows, clickable out of a fight |
| `AuraHistory.lua` | The aura history on the full screen: the buffs and debuffs seen on whoever you can attack (Core's `Core.AuraLog`), each a proper aura icon with its tooltip and menu, on whom, from whom, when, its duration, dispel type and its cast; what to show, the search, clearing |
| `Reminders/Editor.lua` | Edit Tracked conditions, the chosen aura's reminder under Edit tracked's list: where it shows (ticks for the bars, the unit frames, the group frames, the nameplates; a new bar), on whom (you, your target and focus, everyone, a role, Party 1-4, Group 1-40), its conditions; the aura's two marks for the unit frames |

## History
- **2026-11-13:** another druid's mana: one power again (Saneroki: "It doesn't show on the party members [...] revert
  back to how it was with only one class bar"): the game tells a druid's mana in a form to that druid alone, and
  sending it between Sane UIs never came through, so another druid's frames show the power it shows now. Your own keep
  your mana beside the form's power.
- **2026-11-13:** another druid's mana (Saneroki: "When I as a warrior look at the druids nameplates or party plates it
  does not show me the manabar"; "Yes, let my druid send its mana to the party. On unit frame the bars should be like it
  was before. Put them below the mana bar on unit frames."): sent by a druid's Sane UI to its group (taken back the
  same day). On the unit frames the form's power under the mana again; your target's and focus's frames keep a slot
  for each.
- **2026-11-13:** your own slot among the group frames shows your name and your health's share; its cog stands at the far
  left, in front of your name (Saneroki), no longer at the far right in place of the health.
- **2026-11-13:** a druid's mana always in sight (Saneroki: "on all nameplates, unitplates and party plates the druids
  manabar is visible"): on your frame, your target's and your focus's the mana stays under the health bar and a form's
  rage or energy stands on top of it; on the party and raid frames the mana line along the bottom, the form's along the
  top. Your frame no longer keeps a second slot under the health bar.
- **2026-11-11:** the casts of your party's and raid's Sane UI in the aura history (Saneroki: "Can we use the guild
  and party sharing to get the spells and information from other party members combat?"): after each fight each
  member's Sane UI sends its player's casts of buffs and debuffs in it, with whom and when; *Share casts in a fight
  with your group* on Combat's page.
- **2026-11-11:** what a fight hides in the aura history (Saneroki: "Yess add them"): your own casts in a fight of a
  spell that puts an aura on, and after each fight the spells of the game's damage meter of it, each member's damage,
  healing, dispels and interrupts and the foes' spells that hit the group, all clickable as the rest; *From fights*.
- **2026-11-11:** the aura history, a window of the full screen (Saneroki: "a window for the fullscreen that shows
  history of buffs and debuffs that have happened"): every buff and debuff seen on whoever you can attack, newest on
  top, each a proper aura icon with its tooltip and menu ("click on it to add it to the tracker etc, just like the buffs
  normally"), whom it was on, from whom, when it came, its duration, whether it can be dispelled or stolen, and whether
  the cast that gave it could be interrupted. In a fight the game keeps the auras of others from addons: only the spells
  it shows come in then, the rest once the fight is over (still on, with the time they came).
- **2026-11-11:** at a trainer the trainer's list shows the first time too (Saneroki: "First time its empty but 2nd
  time it is working as expected"): its list and scroll bar, pinned by the game on a strata of their own, stood behind the
  full screen until the window was given back once; Core's seat lifts them now.
- **2026-11-09:** The action bars on the full screen (Saneroki): no longer dark after a spell or macro is dragged onto them ("only reopening the fullscreen resets it to visible"; the game set their strata under the full screen at every drag, the seat puts it back); every icon there at full brightness ("It should always show the icons in full brightness"); every bar switched on, one Edit Mode hides too; each window as large as its bars ("its height and width should always be the same height to just show the amount of content to fit"), the room beside it in its column empty.
- **2026-11-09:** The action bars on the full screen (Saneroki): no longer dark after a spell or macro is dragged onto them ("only reopening the fullscreen resets it to visible"; the game set their strata under the full screen at every drag, the seat puts it back); every icon there at full brightness ("It should always show the icons in full brightness"); every bar switched on, one Edit Mode hides too; each window as large as its bars ("its height and width should always be the same height to just show the amount of content to fit"), the room beside it in its column empty.
- **2026-11-09:** *Edit tracked* (Saneroki): *Watch on* takes *Everyone*, the roles *Tank*, *Healer* and *DPS*, *Party 1* to *Party 4* and, in a menu of its own, *Group 1* to *Group 40* ("can you add on the watched on all party members Like Party 1 and also on Role Tank, Healer, DPS", "add in the watch on Group 1, 2 to 40 members"), counted on the bars and on the frames' health bars, where the icon shows on each frame of one watched; *Shows on* has *Unit frames* (yours, your target's, your focus's) and *Group frames* apart, in place of *Health bars* ("Add a Show on groupframes that show the spell in the show on"; a tracking from before on both, on everyone where it is on no bar); the conditions *Only in groups* and *Ignore everywhere* (paused, kept), *Don't show in resting areas* now *Hide in rested areas* ("Add a only in Groups (groups are raids and party.", "Add a Hide in Rested Areas", "Add a ignore everywhere"); the columns *Hide from unit frames* and *Prioritize on unit frames* made way for a cog, its tooltip *Edit Tracked conditions*, the title of the settings under the list now, with those two ticks in it ("put there button That looks like a cogwheel"). The aura bars' icons clickable out of a fight as the buffs are ("The reminderbar icons should be clickable like the buffs in the aura view to add tracked etc."). *Look out for* focuses one not of your group by your target, your target back as it was ("The add focus is not entirely working. It doesn't add units that are not in the group."). The group frames: every member's class resource, and aggro in a fight too ("Grooup windows should show always the class resource and aggro.").
- **2026-11-07:** *Shows on* takes several places at once: its dropdown's lines are ticks (each aura bar, *Health bars*, *Nameplates*), its words name those ticked, the last one ticked stays; the aura shows on each by the same settings; *New bar* puts it on the new bar in place of its bars; *Delete bar* on several bars asks which (Saneroki: "We have the edit Tracked window we made the watch on multiple choice. Can we make the shows on also multiple choice").
- **2026-11-07:** *Look out for* in your focus's place while you have no focus: a name or @tank, @healer, @party1-4, @raid1-40 watched in a fight too; found, the place says *Focus found: Add it now* and a click or its key makes it your focus (Saneroki: "Is it possible to have a {add} button instead of the focus target if and only if there is no focus target selected", then "the button add is now called 'Look out for' instead" and "Focus found: Add it now").
- **2026-11-07:** *Watch on* takes several units at once: its dropdown's lines are ticks (you, your target, your focus), its words name those watched, the last one ticked stays; a reminder on a bar shows as one icon while any of them wants it, in a fight each unit known on its own (Saneroki: "Can we have watch on have several targets where we can select multiple targets in its dropdown with checkboxes to show what we watch it on."). The health bars and the nameplates as before.
- **2026-11-07:** your target's and your focus's health bars red while you can attack the unit, green otherwise (Saneroki: "The target unit frame. Can we make it red if it is an enemy, otherwise green like we have it now.", then of the focus: "Yes, focus too"); your own stays green.
- **2026-11-07:** *When class in group* counts your own class too (Saneroki: "I meant my own included").
- **2026-11-07:** an aura tracked more than once: a + beside each line's X copies its tracking onto a line of its own, with its own place and conditions; the X on one of several lines deletes that one alone (Saneroki: "Sometimes I want to show it on multiple places or have different conditions"). A condition *When class in group* (Saneroki: "It only shows that spell / buff on the bars when that class is in the party").
- **2026-11-07:** the window *Edit auras* is now *Edit tracked*: its title, its button on Combat's settings page, the tips and the commands' words (Saneroki).
- **2026-11-07:** the aura menu: the marks first, then *Edit tracked...* (was *Edit auras...*), last *Add tracking*, there only while the aura is not tracked (Saneroki: "put the add tracked down to the bottom and change the name from edit aura to edit tracked"); *Edit tracking* gone, *Edit tracked...* does the same.
- **2026-11-07:** a tracked aura goes on *Aura bar 1* at first, and a new place *Nameplates*: its icons right under each plate, without a gap (Saneroki: "make the reminder bar 1 the default one and add on Nameplates as well. On those nameplates the trackers are shown directly underneath with no gaps on the nameplates"); the list's column *Show on healthbars* is now *Tracked* (Saneroki kept it).
- **2026-11-07:** *In a group too* under *Hide the unit frames at rest* and *Hide the action bars at rest*: they rest out of sight in a party or raid as well (Saneroki: "I have no way to autohide then while i don't hover over them in party").
- **2026-11-07:** the aura menu's *Show on healthbars* tick is now *Add tracking* (*Edit tracking* once tracked): tracked on the health bars, put on *Edit auras*' list and the window opened on it; a spell searched there has *Add tracking* under the list; the chosen and new lines lit only behind their names, *Watch on* and *Delete bar* out of sight on the health bars (Saneroki: "I need a add Tracking that will add that spell to the edit auras window and open the edit auras window", "When I search for a spell in Edit auras I can't edit them. They are greyed out").
- **2026-11-07:** in a fight an aura on the health bars and the reminder bars counts from your cast for as long as it lasted when last seen, on the member it was aimed at, and runs out by the clock (Saneroki: "Inside combat i have the hots showing up but they never disappear"; Forever's client hides every aura's number in a fight, which the casts were matched to).
- **2026-11-06:** with Abilities on, the spellbook shows its spells still to learn in grey, the weapon skills, Home first, the reservations by drag, the checkbox *Show unlearned spells* and its menu lines, through Core (`Core.Spellbook`) (Saneroki: "it looks like it is not part of the combat fullscreen").
- **2026-11-06:** the meter is never on or over Combat's full screen, and its button on the full screen's bar is gone (Saneroki: "The meeter should not show in or over the full screen").
- **2026-11-06:** the meter's *Lock window*: neither moved nor sized out of Edit Mode (Saneroki: "lock it in its settings so it is fixed and doesn't let you drag to resize or move it").
- **2026-11-06:** *Show on healthbars* (first *Show on raid frames*): an aura's icon on your unit frames and the party and raid frames; beside each member of a party their target and their pet, small, their names alone (Saneroki).
- **2026-11-06:** in a party a column beside it with each member's pet, else their target; the party and raid frames' health in class colours (Saneroki).
- **2026-11-06:** *Reminder* is now *Show on raid frames* wherever you read it (first *Track*): the column, the menu's tick, *Aura bar*, *Aura icons* (Saneroki); one made shows on the party and raid frames.
- **2026-11-06:** one window, *Edit auras*, for every aura's marks and its reminder (Saneroki: "merge the Reminder and edit aura window"); any spell searched there can be a reminder.
- **2026-11-06:** the aura lists one long list, a tick per mark in Saneroki's order and the red X in front of the name, and a search over every class's auras, the enemies' and the items', in groups (Saneroki: "can I search for all spells across classes and maybe even enemies?"); *Show on unit frames* is *Prioritize on unit frames*.
- **2026-11-06:** reminders on the party and raid frames, in place of the fixed buffs of your class (Saneroki: "add those buffs or spells or hots to the party bar manually"); *Only yours*; a group's version counts for the one.
- **2026-11-06:** a Sane Macro on a bar button acts as the game's buttons do: a spell or item dropped or clicked onto it takes its place, and dragged with the pick-up key it goes to another button or off the bars (Saneroki: it could not be removed).
- **2026-11-06:** the menu bar's alert *You have unopened items in your collection*, once closed, stays closed until more come (Saneroki: it came back at every login).
- **2026-11-02:** the unit frames' auras out of a fight on icons of ours, as the game runs no addon's script on its own (Saneroki: tooltip and clicks).
- **2026-11-02:** the unit frames' auras four, two and four, in blocks of icons that touch, no borders (Saneroki).
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
- **2026-11-09:** the full screen at a trainer (Saneroki): the game's trainer window on the left, the spellbook on the right, or at a profession trainer the game's Profession window; a layout of its own for each, behind its tab.
