# Sane UI: Inventory

**Status:** its window and full screen built; the character sheet built, its parts windows of their own (the paper doll; the stats; gear sets; titles; reputation, skills, PvP, currency, statistics); the bags built, with pins, the player's own groups and junk marks; the other characters' things in the bags' window · **Since:** 2026-10-20 · **Addon:** `SaneUI_Inventory` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105; in Retail the skills and PvP windows, resistances, pet stats, the ranged and ammo slots and the keyring stand down)

## TL;DR
The module for what you carry and wear. Left-click the screen's bottom right corner and the screen
fills with the module's windows: your character sheet, your bags (and in them your other characters' things), Sane UI's
own, arranged as you like. Click there again, or press Esc, and they go. Your bag keys open it too, with
your bags on it, and the game's bags stay closed. The game's own character sheet stays as it is, and its key
opens it as before. The plan is in `Doc/ideas/Inventory.md`.

## How to use
- **Switch it on or off:** tick or untick *Inventory* under *Sane UI* in the game's addon list.
- **The full screen:** left-click all the way in the bottom right corner. Click there again, or press
  Esc, to go back. Not in Edit Mode, and not with *Can expand to fullscreen* off (*Sane UI > Inventory >
  Expand window*); with *Hotcorner requires leftclick* off there, the mouse pushed into the corner is enough. In
  Edit Mode the window can be docked in another corner; the hot corner goes with it.
- **Your bag keys** (the backpack's, *Open All Bags*, each bag's, the reagent bag's, whatever keys you gave them)
  open the full screen with your bags on it; pressed again, it goes back. The game's bag bar is gone from the
  screen, Edit Mode included. The game's own bags stay closed meanwhile (at a vendor or the bank too); the dropdown *Classic windows*
  still opens them, until you close them. Sane UI's key *Open the bags on Inventory's full screen* is in the
  game's key bindings under Sane UI. *Sane UI > Inventory > Bags > Bag Keys Open Our Bags* switches it off; with
  *Can expand to fullscreen* off the full screen never comes, so your bag keys and bags are the game's then too, and
  so they are while Edit Mode is open.
- **A window of its own:** beside each window's X on the full screen, the game's minimize button makes that window
  its own: the full screen goes back, and the window stays where it stood, by itself. Move it by its title, size it
  by its bronze corners, close it with its X or Esc. From then on its key opens only that window: your bag keys
  open the bags alone. Its maximize button puts it back on the full screen, and its key opens the full screen
  again. On the full screen the corners size a window too, as the mouse goes.
- **The game's own windows:** the full screen's dropdown *Classic windows* has *Character* (the full screen
  goes back and the game's key for its character sheet is said: our code never opens it) and *Bags* (the
  game's bags open). The game's character sheet and bags have the button *Sane UI* beside their close button:
  the game's closes and this full screen comes (not with *Can expand to fullscreen* off).
- **Arranging the windows:** as on every Sane UI full screen (Core's board): drag a window's head to move it,
  the gap between two to share their room anew, its X to take it off; the dropdown *Windows* adds one; layouts
  behind tabs in the title bar. Right of those tabs, a tab with an icon for each window (your portrait for the
  character, the game's icons for the others: the sheet's tabs', a bag), lit while the
  window is on the screen: a click puts it there or takes it off.
- **The character sheet**, Sane UI's own, in windows of their own that you move and size on the full screen like
  every other (the dropdown *Windows* adds the ones that are not there; at first the character and the stats):
  - *Character*: Sane UI's own doll in the kit's look (`Doc/guides/interface-style.md`, *The kit*: the game's
    character window): your model in the middle, from under your level down to the ground if you are
    full-grown, every race at the same scale (a gnome stands as small as it is; drag it with the left button to
    turn it, the wheel zooms in on its head; left alone for ten seconds it goes back to how it stood), your name and level above it, your gear in the game's two columns of Forever's gear slots beside it
    (the head and the necklace at the top; the necklace, rings and trinkets together at the top right, the belt,
    legs and boots under them; the icons with their quality's border; an empty slot the game's own picture of
    it) with each piece's stats beside it (its DPS, its armor, Strength, Agility,
    Stamina, Intellect and Spirit, then the rest, such as spell power), the weapons and their strips below; as large as its window lets it be. A click on a slot picks the item up or puts the one you hold there (a drag the same), Shift or
    Ctrl and a click links it or tries it on, the tooltip is the game's; an item let go over the model is put on.
    Using an equipped item with a right click stays on the game's own sheet and the action bars.
  - *Character Stats*: your stats as the game's character window shows them, with the game's values and tooltips (in a fight they show
    what they were before it, and are brought up to date when it is over). Each of the game's categories (General,
    Primary Attributes, Weapons, Modifiers, Defense, Resistances; in Retail its Attributes and Enhancements) is a section under the character window's own head (its
    bronze plate with curled ends), a line for each stat, every other one on a band, its name at the left in gold
    and its value at the right in white (a bonus in green, a malus in red). The page follows the window: narrow, it is one list; wider, the sections stand
    in as many columns as fit, in the game's order, the columns about even in height and kept together in the
    middle; wide enough, your five attributes stand over the columns in thin golden boxes with their value written large.
    The wheel scrolls what does not fit. While you have a pet, its stats follow yours, each section named with it.
  - *Equipment Manager* (added from the dropdown *Windows*): your gear sets, each with its icon in the game's
    slot, the one you wear ticked, red with an item lost; Equip, Save and New Set the game's red buttons. A click chooses one, a double click or
    Equip puts it on, Save stores what you wear in it after a question (leaving out the slots the set leaves out),
    New Set asks a name and leaves out your shirt and tabard, a right click renames or deletes; a new set's icon is
    changed on the game's own sheet.
  - *Titles* (added from the dropdown *Windows*): None, then the titles you know; a click wears one, the one you
    wear ticked by hand.
  - *Reputation*: your factions as the game lists them: a click on a header folds or unfolds it, a click on a
    faction chooses it (its standing in numbers under the mouse); at the right the chosen faction, its standing,
    its description and the game's switches At War, Move to Inactive and Show as Experience Bar.
  - *Skills* (WoW: Forever): your skill lines with their ranks (the bonus in green); choose one to see its
    description, and for a weapon skill what it means against a foe of your level and against a raid boss.
  - *PvP* (WoW: Forever): the season, your rank and the game's rank ring, your points, the time left of the season,
    and at the right the season's progress and the next reward.
  - *Currency*: your currencies (choose one for its caps and description; Shift and a click links it, the game's
    watch key puts it on the backpack), with the game's switches Unused and Show on Backpack; the transfer between
    characters stays on the game's own sheet.
  - *Statistics*: the game's statistics by category, each category folding by a click.
- **Your bags** (the window *Bags*): everything you carry, in the kit's look (WoW: Forever's own parts: the heavy
  bronze frame, the game's Friz Quadrata, `Doc/guides/interface-style.md`): each item in the game's bag slot, its
  icon square with its quality's border, its item level at the top left in its quality's
  colour, its count at the bottom right, a quest's mark on an item that starts one, red when you cannot use it.
  - **The bar** on the window's title line, after *Bags*: how many of your bags' slots
    are taken (every bag's in its tooltip); at the line's end *Sell All Junk Items* at a vendor (the game's red button),
    then three small round buttons with a soft edge (the junk marker, the bags' button, the clean-up) and the
    dropdown *View*, a thin golden box. Your bags stand in a strip at the top of
    the page, at first; the bags' button hides it or shows it again: each bag's icon in the game's slot a little smaller
    than an item's, with its free slots on it; an empty slot shows what goes there, in a faded
    drawing (a pouch for a bag, the mortar for the reagent bag, a key for a keyring without keys); point at one to light its items,
    drop a bag on a slot to put it on, click one to pick it up. The clean-up
    in *One Bag* is our own sort: your items move into the order of your categories (pinned ones first, then each
    category in your order, inside one by *Sort By*, the larger stack first), partial stacks of one item joined
    first, the empty slots last; the reagent bag, the keyring and bags for one kind of item stay as they are. The
    button is greyed while it runs; it never starts in a fight and stops at one, or when you pick something up. In
    the other views it is the game's *Clean Up Bags*.
  - **The sidebar** at the left (its arrow at the top folds it to a narrow edge and the strip of your bags with
    it, which leaves the items the room in a narrow window; the arrow or the bags' button unfolds it, kept; every row with a game icon of its own: a
    backpack for All Items, a helmet for Head, a flask for Potions ...): *All Items* (every item by category, the categories side by side, as many to a
    line as fit; every category that takes items shown with its items and an empty slot after them, its drawing
    faded in it, also while
    it holds nothing; the free slots are not shown), *One Bag*
    (every slot of your bags in their order, the empty ones too) and *Each Bag* (every bag by itself), then
    *Pinned Items* and *Recent Items*, then every category switched on, by name, with how many items it holds
    (empty ones too). A click shows it.
  - **Categories:** your gear by its slot (*Head*, *Neck*, *Shoulder*, *Back*, *Chest*, *Wrist*, *Hands*,
    *Waist*, *Legs*, *Feet*, *Rings*, *Trinkets*, *Weapons*, *Off Hand*, *Ranged*, then *Shirts, Tabards & Other
    Gear*) and *Item Set Gear* (gear of one of your equipment sets) are the group *The Armory*; *Potions*, *Buffs*
    (elixirs, flasks, scrolls, gems and enchantments, and other consumables whose effect lasts 15 minutes or
    more), *Camp Items* and *Food* (the rest: food and drink, bandages) the group *Consumables*; then
    *Trade Goods*, *Professions*, *Containers* (bags and quivers lying in your bags, which are always empty there,
    and what a right click opens: a lockbox, a satchel, a clam), *Reagent Bag*, *Miscellaneous*, *Quest Items*
    (what the game calls a quest item, and what starts a quest; on at first), *Special Bags* (what is in a quiver, a soul or herb bag
    you wear) and *Junk* last. A group shows
    in All Items as its name over the whole width, its members that hold something side by side under it, then
    one empty slot for the whole group (an item let go there goes into the member the rules give it there, else
    the group's first member). In the sidebar its members are set in under it; the arrow on its row (the game's chevron,
    turned down or up) folds them into the row (*The Armory* and *Consumables* are folded at first), and its box (the game's checkbox), ticked, divides the group into its members in All Items; unticked, the group is
    one part with all its items and one empty slot. An item let go anywhere over the window where nothing else
    takes it (the paper, the title line, the foot) goes into your bags, into the category the rules give it
    (what you put it into taken off). The items scroll with the mouse wheel; no scroll bar. Items and empty slots
    are half again the game's size at first; the slider *Item Size* in the dropdown *View* makes them smaller or larger
    (55% to 135%), and a window too narrow for six of them in a line makes them smaller by itself, down to 28 units,
    so the window can be small (at its narrowest about 410 units wide; the words of the foot's checkboxes and the
    currencies go first, and the count on the bar). A free slot has the character window's gear slot round it (its
    bronze line at the slot's edge), so One Bag and Each Bag show every free slot; a category's empty slot shows its
    icon alone as a plain grey symbol, no slot or dark square behind it. Junk's first slot is a waste bin
    (the golden bin of the game's delete button alone, the same grey symbol, no slot around it; `Views`' `block.bin`, `Layout`'s `bin` place, `Canvas`'s `Sheet:Bin`,
    `Menus.Destroy`): an item let go there or clicked onto it is offered to be destroyed in the game's own dialog, as when you
    drop it into the world (a rare item or better is typed out). *Pinned Items* and *Recent Items* (what
    came into your bags lately): a pinned item stands only under Pinned (while Pinned is shown), a recent one in
    its own category too. Stacks of one
    item show as one with their count added up (gear never; not at a vendor, the bank, the mail, a trade or the
    auction house, where each stack is its own).
  - **Your own way:** a middle click on an item pins it (or unpins it; an item you put into a category is taken
    out of it again). Alt and a right click opens its menu: *Pinned Items*, *Junk*, *Put Into* another category
    or a new one, *Take Out of* the one you put it into. An item picked up (or dragged) and let go over a
    category's head, its row in the sidebar, one of its empty slots or one of its items (or clicked onto it) goes
    into that category (over Pinned: pinned; over Junk: marked as junk; over any other: the junk mark taken off);
    over an item it is lit and its tooltip names the category, and the two no longer swap places in your bags
    (over the same item, Recent Items, a special bag's, the reagent bag's or One Bag and Each Bag's slots they still
    do, as in the game's bags). Put anywhere but Pinned, a pinned item is unpinned, so it shows in the category it
    went to (your own too: an item kept in *Save it* stands there, no longer under Pinned); let go over the paper,
    it is unpinned and out of the category you put it into. An item from
    your bags stays in its slot; one from elsewhere (the bank, what you wear) goes into a free slot of your bags. A right click on a
    category (its row or its head): *Rename*, *Move Up*, *Move Down*, *Create Group With* another, *Add to Group*,
    *Take Out of* its group, *Hide in All Items*, *Switch Off* (both ticks: tick again to undo); on a group:
    *Rename*, *Move Up*, *Move Down*, *Hide in All Items*, *Disband Group*; on Pinned Items and Recent Items *Hide in
    All Items*; on one of your own also *Choose Icon* and *Delete*. A category hidden in All Items or switched off
    stays in the sidebar, greyed; its tooltip says what happened and how it comes back (a click on a switched-off one
    switches it on again). Pinned Items and Recent Items hidden leave All Items, their items in their own categories.
    *Add Category* at the sidebar's foot makes one of your own: name it, then pick its icon among all of the game's
    icons in Core's icon chooser (groups, a search); *Choose Icon* picks another. Drag a category's row in the sidebar to another place: let go at a
    row's top or foot it goes before or after that row (between a group's members it joins that group), at a
    row's middle it joins that row's group (or makes one with that category); drag a group's row to move the whole
    group. Pinned Items and Recent Items stay at the top, Junk at the end. All of it is kept in your profile, in the
    game's saved settings (its WTF folder), never shared.
  - **The list's columns:** the icon, the name, item level, required level, type, how it binds (BoP, BoE, BoU,
    Quest; SB once bound), the count and what the vendor pays for it. Click a column's head to sort by it (again
    for the other way), drag it sideways to move it, drag its right edge to size it; a right click on the head
    chooses the columns, moves one, makes the icons round or puts it all back. A click on a category's head folds
    it, Shift and a click folds or unfolds them all.
  - **"+" and the junk marker:** an empty slot (no sign in it, like any other) follows Pinned and every category that takes items: bring an item to it
    (picked up, or dragged) and it goes in; click it with nothing held, and the next item you click goes in (the
    rest of the window dims meanwhile; a right click or Esc stops). The coin on the bar is the junk marker: click
    it, then click items to mark them as junk or unmark them, and click it again to stop; an item brought to it
    is marked at once. Junk is sold one item at a time at a vendor, never what is in a special bag, in an
    equipment set or pinned, nor what the vendor would take back for its price; the chat says what it brought.
  - **The dropdown *View*:** *Grid* (each category under its head, its last line filled out), *List* (a line per
    item, in columns) or *Compact* (the categories side by side in bands, planned to take the fewest lines);
    *Sort By* (*Default*: gear by item level, then by kind, quality and name; or quality, name, item level);
    *Show Pinned Items*, *Show Recent Items*, *Merge Stacks*; *Open With* (the view the
    window opens with); *Switched Off* lists what you switched off, to switch it on again; the slider *Item Size* (the
    bank's items go with it).
  - **Splitting a stack:** Shift and a click on a stack opens a little splitter (in All Items and the categories
    always, as those show no empty slots; in One Bag and Each Bag with *Stack Splitter Everywhere*): how many
    (typed, - and +, the wheel), *Split* puts that many into the first free slot (Enter), *Auto Split* splits the
    whole stack into stacks of that many (Alt and Enter). A Shift-click while you write in the chat links the item
    instead; in a fight the game's own splitter opens.
  - Every item is the game's own button: click or drag it, right click to use it (in a fight too), to sell it at
    a vendor or to put it into the bank, Shift-click to link it; the tooltip is the game's. The search box on the
    bags' title line (and the full screen's) finds items by name, category or item level, each found item lit with
    the game's glow in gold: One Bag and Each Bag fade what is not found, the others show only what is. Under them,
    *Found elsewhere*: each other character that has any of it, and your bank as last seen while no banker is open,
    with how many; a click shows those things, found (while another character is shown, a line for you takes you back
    to your bags). Junk's waste bin asks first (*Delete*, *Cancel*, *Delete the
    item and don't ask me again*; *Waste Bin Asks First* brings the question back). At the foot your currencies and your gold (every character's in its tooltip). The game's own bank window
    stays as it is.
- **Your bank** (the window *Bank*): there while you are at a banker, in the bags' look: a sidebar with *All
  Bank Tabs* (each tab under its head, every slot), *One Bank* (the bank's slots together) and each tab by its
  name and icon with how many of its slots are taken (its tooltip says what it takes); on the bar *Deposit All
  Reagents*, the game's *Clean Up Bank* and the dropdown *View* (*Grid*, *List* or *Compact*, *Group by Category* to
  see the bank's items by the bags' categories, *Sort By*). The list has the bags' columns, with a head of its own
  (sorting, moving or sizing a column there does it for the bags too). A right click on a tab: *Rename* (at most 16
  letters, as the game's), *Assign To* (*Equipment*, *Consumables*, *Profession Goods*, *Reagents*, *Junk*: what the
  game puts into that tab) and *Ignore in Clean Up*, set by the game itself. Where the game sells another tab, *Buy
  Tab* follows that bank's tabs (its cost in the tooltip, red when you cannot pay it): a click on it is the game's
  own button for buying a tab, which asks first. The items are the game's own: a right click puts one into your
  bags. Alt and a right click opens an item's
  menu, a middle click pins it, Shift and a click splits a stack (with *Stack Splitter Everywhere*). Your gold at
  the foot. Away from the banker the window is gone and the others share its room.
- **At a vendor and a banker** (Saneroki, 2026-11-09): the full screen comes by itself. At a vendor the game's
  vendor window stands on the left (the window *Vendor*: the game's own, as it always works, only placed there) and
  your bags on the right; at a banker your bags on the left and your bank on the right. Each is a layout of its own
  behind a tab first in the title bar (*Vendor*, *Bank*), there while you talk to them: arrange it as you like and it
  is kept so; a right click on its tab resets it; another tab chosen shows that layout instead until the talk ends.
  When the vendor or the bank closes, the full screen goes back, unless it was open already before. Pushing the
  corner or Esc closes the full screen as always (Esc closes the vendor's window with it). At a mailbox likewise
  (the tab *Mail*): the game's mail window on the left, with Economy's tab *Banker* on it as always, a letter you open
  beside it, your bags on the right. *Sane UI > Inventory > Full Screen at Vendors, the Bank and Mail* switches it off.
- **Your alts**, in your bags' own window (Saneroki, 2026-11-15: the window as it was before the alts came into it,
  with the dropdown and the search added): the dropdown after *Bags* on its title line chooses whose things it shows
  (you: your bags as they are; anyone else: their things as last seen). It lists the account's characters (you first,
  each in its class's colour with its class's icon and its gold, the account's bank last where it holds something, the
  gold of them all under them; its tooltip the level, realm and when it was seen). Another character's things are drawn
  by the bags themselves: the same sidebar (*All Items*, then your categories and groups as you arranged them, with how
  many of that character's items each holds; a click shows one alone; a group's arrow, its box, a right click and a
  row dragged do what they always do), the same *View* (*Grid*, *List* or *Compact*, *Sort By*, *Item Size*), the same
  heads, item levels, coins and grey junk. Its bags, its bank as last seen and what it wears stand each under a head,
  the paper doll under them; the count on the title line says how many items are shown. What only your own bags can do
  stands aside meanwhile: the strip of the bags, the clean-up, the junk marker, selling, *One Bag* and *Each Bag*
  (Core keeps a bag's items, not the slots they lie in), *Pinned* and *Recent*, the "+" slots. At the foot that
  character's level, class and when it was seen, and its gold (every character's in its tooltip). Tooltips are the
  game's; Shift or Ctrl and a click links an item or tries it on; Alt and a right click opens its menu. Nothing moves an
  item. The search box finds an item across them all, by its name or its number: each character says how many it has
  in the dropdown, the window lists only what was found, *Found elsewhere* who else has it. The window opens with your
  bags. A character's things are as Core last read them while it was logged in; its bank, while it had it open.
- **Settings:** *Sane UI > Inventory*: the section *Expand window* (whether it fills the screen, its kind of
  motion, the background's opacity and texture), *Window corners*, and *Bags*: *Open With*, *Show Pinned Items*,
  *Pinned in One Bag and Each Bag*, *Show Recent Items*, *Recent in One Bag and Each Bag*, *Show Add Category*, *Merge Stacks*, *Junk Marker* (off: no Junk, grey items stay in their
  categories), *Stack Splitter Everywhere*, *Show Item Level*, *Show BoE*, *Show Set Name*, *Coin
  on Junk*, *Grey Junk*. The dropdown *View* switches some of them too.

### A new level

At a new level the top of the screen says it, right of its middle beside the guide's arrow, for a few seconds, in place
of the game's toast and its lines in the chat: the level, what it brought (your health and mana, your stats, a talent point) and how long you played on the
level before.

```
Level 22!
HP +18
Mana +20
Str +2
Stam +1
Talent +1
Leveled 7h 12m
```

Over the world, also while Lore fades the interface out for a talk; no setting. A level in the first seconds after a
login has no last line, until the game has said your time.

## Technical details
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked at `BOTTOMRIGHT` at first,
  `Window.WIDTH` x `Window.HEIGHT`, not sizable, see-through and empty while small (no mouse); in Edit Mode its
  box. Docked in a corner, Core gives it the corner's square (`Edge.lua`, `Edge.CORNER` screen pixels, the
  strata `DIALOG`): its push fills the screen. `docked` lays the board out once the full window stands,
  `filled` takes it away as soon as the window starts back; the search box goes to every part.
- **The bag keys** (`Keys.lua`, `Bindings.xml`): the keys of the game's actions `TOGGLEBACKPACK`, `OPENALLBAGS`,
  `TOGGLEBAG1` to `4` and `TOGGLEREAGENTBAG1` (`GetBindingKey`) bound to our `SANEUI_INVENTORY_BAGS` by the game's
  override bindings (`SetOverrideBinding` on a frame of ours; anew at `UPDATE_BINDINGS` when those keys changed;
  out of a fight, else after it), which runs `Window.Toggle("bags")`: the full screen filled with the bags put on
  the layout once it stands (`Board.Add`), or back while it stands with them (`Board.Has`); the bags made a window
  of their own (Core's board, `Core.Board.Key`) open or close by themselves instead. The game's `BagsBar`
  (the backpack, the bag slots, the keyring) lent to the same hidden frame as the bag windows while ours stand in
  for them (`Keys.lua`'s `Ours`: Edit Mode and Classic windows leave it there). The game's bag
  windows (`ContainerFrameCombinedBags`, `ContainerFrame1` to `NUM_CONTAINER_FRAMES`) lent to a hidden frame of
  ours (`Core.Lend`'s `SetParent`): the game opens and closes them as always, unseen; Classic windows' *Bags*
  (`Window.lua`) gives them back (`Keys.GameBags(true)`) until a hook after their `OnHide` finds none shown. The
  setting `bagKeys` and `expand` off (the full screen never comes: `Keys.Taken`, `Keys.Apply`; then no button *Sane
  UI* either, the Classic entries' `ready`), Edit Mode while open (`Core.EditMode.Watch`), standing down
  (`Keys.Leave`) give everything back; a key pressed while the full screen cannot come wishes for nothing later.
- **The board** (`Board.lua`): Core's (`Core.Board`), the module's windows in the order `Board.ORDER`
  (`character`, `stats`, `reputation`, `skills`, `pvp`, `currency`, `statistics`, `vendor`, `mail`, `letter`, `bags`, `bank`). Each window is a part in files of its own, listed after `Board.lua` in the TOC,
  that registers itself: `Board.Part(key, title, least, part)`, `part.Build(panel)`, `part.Show(on)`,
  `part.Size(width, height)`, `part.Search(text)`; each step runs `ns.Safe`, so a part that fails is noted and
  the others go on. The first layout puts the parts of `Board.FIRST` (the character, the stats, the bags, the other
  characters) side by side, each as wide as its least width, the last taking the rest; the others come from the
  dropdown *Windows*; later the layout is the player's (kept in the module's store, `board`). Each window's icon
  (`Board.ICONS`: a texture, or a function that draws it: the portrait, the PvP icon of your faction; the side tabs'
  icons are WoW: Forever's own art, so Retail gets icons of its own of the same meaning, `Core.ForGame`) gives it a
  tab of its own in the title bar (Core's board, `spec.icon`).
- **The talks** (`Talks.lua`, Saneroki, 2026-11-09): three layouts of Core's board's own for a talk (`Board.Occasion(name,
  title, default)`, its occasions; `Board.Talk(name)` sets the one on): `vendor` (the part `vendor` as wide as the game's
  window, `Shop.Width()`, the bags the rest), `bank` (the bags and the bank, halves) and `mail` (the parts `mail`,
  `MailFrame`, and `letter`, `OpenMailFrame`, each as wide as its window, the bags the rest; the letter always in it,
  left out while none is open, the shares made anew at each laying out so the mail keeps its width either way). A
  letter is the game's window of its own on UIParent, anchored beside the mail window: seated alone it would stand
  behind the full screen, so it is a part, and put back into the mail's layout when it opens should the player have
  taken it out (`Read`). Economy's tab Banker is the mail window's child and goes with it. The part `vendor` is Core's
  `Core.Seat.Part` on `MerchantFrame`: seated in its panel's body while it is open (`Present`), its `OnShow` and `OnHide`
  followed (hooks after the game's) to begin and end the talk; the bank by `BANKFRAME_OPENED` and `BANKFRAME_CLOSED`.
  `Talks.Began` fills the screen (`Window.Fill`) and notes that it came for that talk; `Talks.Ended` takes the
  layout off and sends the full screen back (`Window.Back`) only then. Switched off (`talks`), nothing comes; a vendor
  window put in a layout by hand still lays out with it.
- **The character sheet** (`Sheet/`): the game's Camelot character window rebuilt from Blizzard's code
  (`CharacterFrame.xml`, `PaperDollFrame.xml`, `PaperDollFrame.lua`, `ReputationFrame`, `SkillsFrame`, `PVPRankFrame`,
  `TokenFrame`, `StatisticsFrame`), its parts windows of their own on the board (Saneroki, 2026-10-20), each moved
  and sized there; what is in a window follows its size.
  - **The character** (`Sheet/Sheet.lua`, the part `character`, dressed `bare` on Core's board): the doll
    (`Sheet/Doll.lua`: the kit's heavy bronze round it, `Core.Look.Frame`, scaled with it; `Doll.WIDTH` by
    `Doll.HEIGHT`, its slots and boxes in the pixels of a 1080p layout, `Doll.TOP`, `LEFT`, `RIGHT`, `WEAPONS`,
    `AMMO`, `HERO`: the game's two straight columns, each slot in Forever's gear slot frame, `Doll.Frame`), at the
    window's top middle, scaled to fit and never larger than its 1:1 size (`Sheet.Size`), the board's least
    `Sheet.LEAST` of it. In the hero's place (on the plate itself) the panel's title (`UnitPVPName`, the
    game's gold), the level line under it
    (`PaperDollFrame_SetLevel`: the effective level, the specialization where the game has one (WoW: Forever: where
    `IsSpecSelectionEnabled` says the class chooses one; Retail, which lacks that call: always), the class in its colour)
    and the model; the panel's head (to drag it) is the doll's top, its X (the game's) in the top right corner.
    `Sheet.LEFT` (the game's 398) is still what the other characters' paper doll reads.
  - **Slots** (`Sheet/Slots.lua`): the game's `ItemButton` without its square, in Forever's gear slot frames
    (`Doll.Frame`, `Doll.INSET` from the slots' sides): the left from the head to the hands, the right the necklace, rings and trinkets
    together at the top, the belt, legs and boots under them (`Slots.COLUMNS`); the ranged slot (and its strip) only where
    `C_PaperDollInfo.IsRangedSlotShown`, the ammo slot while `UnitUsesAmmo` (Retail has neither slot: the game knows
    no `RangedSlot` or `AmmoSlot`, so no button is made there). Drawn as
    `PaperDollItemSlotButton_Update` draws (the game's `SetItemButton…` functions: icon, count, quality, red while
    broken or unusable, grey while locked; empty: the game's own picture of the slot, `GetInventorySlotInfo`'s, at
    `Slots.DRAWN`; where it gives none, the category's icon, `Slots.DRAWINGS`). Its stats beside it, on the plate (`Doll.Strip`):
    the item's stats, centred both ways, one to a line while they fit (`Slots.Stats`: `GetItemStats` by the game's
    words, `Slots.FIRST` first: DPS as `STAT_DPS_SHORT`, armor, the primary stats; the rest by their size);
    empty, nothing. The icon with the template's quality border, as large as the icon (the weapons' are larger than
    the game's 37 units).
    Clicks: `PickupInventoryItem` (left click, drag, drop), `HandleModifiedItemClick` (a modified click); a right
    click calls nothing (`UseInventoryItem` is the game's own). Tooltip: `GameTooltip:SetInventoryItem`.
  - **Model** (`Sheet/Model.lua`): a `ModelScene` of the game's `ModelSceneMixinTemplate` (its orbit camera: the
    left button's drag turns it, the wheel zooms; once the model has loaded, a target spline moves the camera into
    its head: all the way in, the top of the model at the top of its place; below the foot of the hero's column,
    `Doll.FOOT`, the bronze plate is drawn again over it, `Doll.Cover` on a frame above the model and under the
    items, a frame clipping a plate laid as the window's own so the grain runs on unbroken, so its legs go behind the
    weapons' row; no clipping frame, which hid the whole model) set up by `ModelSceneUtil.SetUpCharacterSheetScene` when shown and
    at `UNIT_MODEL_CHANGED`, `Model.SIZE` (272 x 872 doll pixels: a full-grown character fills its place, from
    under the level line to `Doll.GROUND`). Every race at one scale: each of the scene's actors gets requested scale
    1, no scaling toward a man's size and the floor (scene 595 sizes and lifts each race). Its feet on the place's
    foot: the scene says where it draws the bottom of the model (its bounding box once loaded, the floor before;
    `Transform3DPointTo2D`, its units from the camera's target in its middle), stood anew when the model has loaded
    (`SetOnModelLoadedCallback`); when that cannot be read, the field of view across its diagonal and
    `Model.LOWER`. It takes the mouse only over its place (`SetHitRectInsets`); our scripts are hooked on
    after the game's. Left alone `Model.REST` (10) seconds after the last drag or turn of the wheel (never while the
    button is held), the camera glides back to its first distance and its first side, the short way round. The name
    and level drawn over it; on the hero's dark place (no race background); an item
    let go over it (a drop, or the left button) where
    `C_PaperDollInfo.CanAutoEquipCursorItem` says it can be: `AutoEquipCursorItem`.
  - **Stats** (`Sheet/Stats.lua`, the part `stats`, in the kit's look: the character window's heads,
    `Core.Look.Head`, and bands, `Core.Look.Band`): each stat a line of ours (`Label`,
    `Value` with their fonts from the start, the tooltip's fields) filled by the game's own function for it
    (`PAPERDOLL_STATINFO[stat].updateFunc`), as the game fills its rows; which stats show as the game decides it
    (`PAPERDOLL_STATCATEGORIES`: `primary`, `roles`, `showFunc`, the unit's categories, a stat at its `hideAt` or one
    the game hides left out: as each game's sheet compares it: WoW: Forever the value the stat's function answers,
    Retail the `numericValue` it left on the line); a category named by its `categoryName` (WoW: Forever) or by the `titleText` of the frame
    it stands in on the game's sheet (Retail's `categoryFrame` on `CharacterStatsPane`); the label's colon taken off, the game's colour codes as they are (`Style.InkHex`); the
    tooltip the game's (`onEnterFunc`, else `PaperDollStatTooltip`). Then the resistances (`Stats.RESISTANCES`, the
    game's `PaperDollFrame_SetResistance`; only where the game has resistances, none in Retail), then the pet's
    categories while `HasPetUI` and the pet is there, named "<pet>: <category>" (`PET_STATS_UPDATE` listened to only
    where the game's list has a pet's categories: Retail has neither them nor the event). The sections are laid out for the page's width (`Layout`): `Stats.COLUMN` to
    `Stats.COLUMN_MOST` wide columns, the block of them centred, cut in the game's order so the tallest column is as
    low as it can be (`Cuts`); the primary attributes as five thin golden boxes over the block (`AsTile`) where they fit
    across it, else a section. A `ScrollFrame` and the wheel; laid out again on every size change. Under a
    restriction (`Core.Restricted`) the stats are secret to addon code, so the page is not drawn then: it waits
    (`Stats.Owed`) and is drawn after `PLAYER_REGEN_ENABLED` or `ADDON_RESTRICTION_STATE_CHANGED`. Drawn when shown,
    a frame after the game's stat events and the player's `UNIT_PET` (`Core.Later`).
  - **Gear sets** (`Sheet/Gear.lua`, the part `gear`): `C_EquipmentSet`'s sets by name in lines
    (the icon in the game's slot, the game's tick on the set worn, red with an item lost; a gold glow chosen and
    under the mouse); Equip, Save and New Set the game's red buttons (`Style.Red`), grey while they do nothing. Equip as `EquipmentManager_EquipSet`
    (not with locked items or while casting: the game's error), Save after `Core.Confirm` (the set's left-out slots
    set first: `GetIgnoredSlots`, `IgnoreSlotForSave`, `UnignoreSlotForSave`; a new set without the shirt and the
    tabard, `Gear.LEFT_OUT`; the game's note of them cleared after either, `ClearIgnoredSlotsForSave`), New Set's
    name by `Core.AskText` (the icon the game's question mark: the game's icon picker is a frame of its own we do not
    show), a right click's menu to rename or delete. Drawn anew after `EQUIPMENT_SETS_CHANGED`,
    `EQUIPMENT_SWAP_FINISHED`, `PLAYER_EQUIPMENT_CHANGED`.
  - **Titles** (`Sheet/Titles.lua`, the part `titles`): None, then the titles you know by name,
    in lines (a faint stripe, a tick and a gold glow on the one worn); a click
    `SetCurrentTitle`. Drawn anew after `KNOWN_TITLES_UPDATE` and the player's `UNIT_NAME_UPDATE`.
  - **The pages** (`Sheet/Page.lua`): the windows of the game's tabs are each a page: its panel's body cut into a
    left part that takes the room (`Page.New`) and, for those that tell of what is chosen, the game's right pane at
    its right (`Page.SIDE` wide, the window's height, its art and stone); `Page.Part` registers it with the board,
    `Page.Least` its least size (a list's `List.LEAST`, `LEAST_HEIGHT`, and the right pane).
  - **Lists and side pane** (`Sheet/List.lua`, `Sheet/Side.lua`): what the windows share. A list in the game's look
    (`WowScrollBoxList`, `MinimalScrollBar`, the long lines) whose rows (plain buttons) the tab draws, every call of
    the game's list into our code `ns.Safe`; the side pane over the right pane as the game's
    `CharacterFrameSidePaneTemplate` lays it out (title, subtitle, line, description, rows, foot, the empty word).
    The game's template itself registers into the game's sheet when made, so it is not used.
  - **Rows** (`Sheet/Rows.lua`): the reputation and skills rows in the game's three looks, the same in both (a header
    with `common-button-list-collapseExpand` and its fold sign; a sub-header with its `campaign_headericon` fold
    button; an entry with a coloured bar, `Rows.Bar`: the game's `ColoredProgressBarTemplate` where it has one, WoW:
    Forever; in Retail, which has none, ours with the same calls, `SetFillPercent` and `SetText`, its `Fill` the
    game's plain status bar texture on a dark track), the game's heights (`Rows.HEADER`, `SUBHEADER`,
    `ENTRY`), the game's light (`charactercreate-customize-dropdown-linemouseover-…`), an indent; every part made once,
    its scripts calling the tab's (`owner`), `ns.Safe`.
  - **Reputation** (`Sheet/Reputation.lua`): the factions of `C_Reputation` on those rows, its coloured bar
    (`Rows.Bar`: the standing's word and colour, `FACTION_BAR_COLORS`, friendships green, renown
    blue; the progress under the mouse), its light (`Reputation.LIT`, `WAR`: brighter chosen or under the mouse,
    red at war). The choice is the game's (`C_Reputation.SetSelectedFaction`), the first faction chosen when none
    is. The side: name, standing, description, bar, the account-wide line, and the switches
    (`ToggleFactionAtWar`, `SetFactionActive`, `SetWatchedFactionByIndex`, the game's tooltips and sounds; a faction
    made inactive, or active again, moves in the list and is chosen again by its ID, as the game's sheet does). The
    game's own rows are wired to its sheet (its frame, the event registry's selection, its side pane), so ours are
    our own. Drawn anew a frame after `UPDATE_FACTION` and the game's other reputation events, while shown.
  - **Skills** (`Sheet/Skills.lua`): the top-level skill lines of `C_SkillInfo` (`parentSkillLineID` 0) without the
    class's own (`Skills.HIDDEN`), as the game lists them: headers, sub-headers (`isChild`; a click folds them),
    skills set in under a sub-header (`Skills.INDENT_CHILD`, `INDENT`), the game's blue bar with the rank, the bonus in
    green and defense's bonus from `UnitDefenseSkill`. The choice is the game's (`C_SkillInfo.SetSelectedSkill`), the
    first skill when none is. The side: name, rank bar, description (`Skills.DESCRIPTION`, shorter for a weapon), and
    for a weapon skill (`Skills.WEAPONS`, the game's skill line IDs, ranged or not) the game's sums against a foe of
    your level and a raid boss (`Skills.BOSS_LEVEL`, `RANKS_PER_LEVEL`; glancing blows from the game's
    `GetGlancingBlowChance`, `GetGlancingBlowPenalty`) under the game's category bands (`Side.Category`). Drawn anew a
    frame after `SKILL_LINES_CHANGED`, while shown. WoW: Forever's: the part registers only where `C_SkillInfo` has
    its skill lines (`GetSkillLineInfo`), so Retail has no skills window.
  - **PvP** (`Sheet/PvP.lua`): the season's rank as the game keeps it, the renown of its PvP rank faction
    (`C_MajorFactions`, `PvP.FACTION` 2800): the season (`GetCurrentArenaSeason`), the rank's number and title (the
    game's `PVP_RANK_<n>_<faction>` in the character's gender, `Enum.PvPRanks`), the game's ring (a paused
    `Cooldown` with its swipe, `CooldownFrame_SetDisplayAsPercentage`; glow, faction background, honour bar, the
    rank's badge `UI-Character-Info-Honor-Icon-<n>`, the rank on a reward ring at its foot), the points, the time
    left of the season (`C_SeasonInfo`, the game's seconds formatter) counted down by a ticker that runs only while
    the tab shows. The side: title and number, the season's description, progress, this week's raised cap, the next
    rank with a reward (`GetRenownRewardsForLevel`, icon rows `Side.Icon`) and the rewards' vendor. WoW: Forever's:
    the part registers only where the game keeps that rank (`C_MajorFactions.GetMajorFactionProgressionInfo`), so
    Retail (its honor levels and seasons) has no PvP window.
  - **Currency** (`Sheet/Currency.lua`): `C_CurrencyInfo`'s list: headers (`ExpandCurrencyList`), sub-headers, and
    currencies as the game draws them (name, count, icon at the right, greyed at none, a tick while on the
    backpack), set in by depth; the choice is ours, kept by name as the game's sheet keeps it, forgotten when the tab
    hides. Shift and a click `HandleModifiedItemClick` its link, the watch key `SetCurrencyBackpack`. The side: name,
    icon and count, description, total and weekly caps, the transfer loss or *account-wide*, the switches Unused
    (`SetCurrencyUnused`) and Show on Backpack (`Side.Check`). The transfer button opens a panel of the game's
    window manager and is left out; the backpack's room is the game's to judge (its token bar is not asked).
  - **Statistics** (`Sheet/Statistics.lua`): `GetStatisticsCategoryList` as the game's tree (`GetCategoryInfo`'s
    parents, children after their parent), top-level categories as headers, deeper ones as sub-headers set in by
    `Statistics.INDENT` per depth, statistics (`GetStatistic`, `GetAchievementInfo`) with their value or `--`; our
    own fold state (until a `/reload`); a cut-short name in a tooltip. Drawn a frame after `CRITERIA_UPDATE`, while
    shown. The right pane shows only its art, as the game's.
  - **Events, while shown only** (`Sheet.Show`): `PLAYER_EQUIPMENT_CHANGED`, `ITEM_LOCK_CHANGED`,
    `UPDATE_INVENTORY_DURABILITY`, `UPDATE_INVENTORY_ALERTS`, `UNIT_INVENTORY_CHANGED`, `UNIT_MODEL_CHANGED` and
    `UNIT_NAME_UPDATE` (the player's), `PLAYER_LEVEL_UP`, `PLAYER_ENTERING_WORLD`. Every value read goes through
    `Core.Plain` or `Core.Ask`; every function of the game's is called only if this client has it.
- **The other characters** (`Alts/`; in the bags' own window since 2026-11-15, no part of their own: `Bags.Face(key,
  stored)` chooses whose things it shows, `Alts.Choose` from the roster and the lines of *Found elsewhere* go there):
  what the account's characters have, read only from Core's data framework (`Core.Data.Characters`, `Character`,
  `Items`, `Worn`, `OnCharacters`; `Doc/guides/data.md`, *Characters*): nothing is gathered or kept here.
  - **What is shown** (`Alts/Snapshot.lua`, no frames): the roster (`Snapshot.Characters`: the one logged in
    first, the others by name, the account's bank last where it holds something), a character's places in the
    order `bags`, `bank`, `worn` with their items in the order Core keeps them (by item ID; Core keeps no bag's
    slots, so no empty ones), what is worn also slot by slot where Core keeps it (`Data.Worn`), the gold of them
    all. The search: a number typed is an item's ID; words are found in the item's name whole, as a piece or as
    first letters (`Core.Fuzzy.Rank` from `Fuzzy.INSIDE` up; letters spread through a name are too loose a fit). A name the game does not know yet is asked for once
    (`C_Item.RequestLoadItemDataByID`); its answer draws the window anew (`Snapshot.Learned`).
  - **The dropdown of the characters** (`Alts/Roster.lua`): `ns.Style.Dropdown` on the title line, `Roster.WIDTH` wide,
    `Roster.LEAST` on a narrow one, its word the chosen one's name in its class's colour (`Style.InkHex`). Its menu a radio
    per character (`GetClassAtlas` by `CreateAtlasMarkup`, `RAID_CLASS_COLORS`), whole gold by `Core.Coins` at the line's
    right (a font string attached by an initializer, which returns the line's size), its tooltip `Alts.About`, a title with
    the gold of them all. While searching, how many each has of what is found (stacks counted whole), one without any
    greyed, no total.
  - **The items** (`Alts/Items.lua`): no frames of their own but the doll's. `Items.Record` an item as a record of the
    bags' kind (`C_Item.GetItemInfoInstant`, `GetItemInfo`, `GetDetailedItemLevelInfo`, `Categories.Classify`; what the
    game told kept once it knows the item, the category worked out anew each time, as the player may have moved the item).
    `Items.Sections` makes the character's places into sections for `Views.Build`: `place = "alts"`, so Views gives them
    no Pinned, Recent or empty slots; `slots` a record per item, a place's count on it (`Held`: the item's record by
    `__index`, the count its own), `word` the head with what is said beside it in faint grey (the day the bank was
    seen, *Not seen yet*, *Empty*), `doll` and `total` for a place the doll stands under. `Items.Button` is a read-only
    item button: the tooltip `GameTooltip:SetItemByID`, a modified click `HandleModifiedItemClick`; nothing picks an item
    up. `Items.Counts`: each place's, category's and group's count for the bags' sidebar.
  - **The paper doll** (`Items.MakeDoll`, `Items.DrawDoll`; a frame in the scroll area's child, under what the canvas
    drew): the slots as the sheet has them (`Slots.COLUMNS`, `Slots.SIZE`, `GAP`, `AMMO`, `AMMO_GAP`; IDs from
    `GetInventorySlotInfo`), eight down each side as far apart as the room is wide, at most as on the sheet (`Items.DOLL`),
    the weapons' row in the middle below them; the ranged slot where the game shows one
    (`C_PaperDollInfo.IsRangedSlotShown`) or something is in it, the ammo beside it where some is worn. The icons as the
    sheet's: square, the game's slot behind. An empty slot is the game's slot alone, its tooltip its name. The bags
    worn in their slots stand as items under Equipped's head, in their slots' order. While searching the doll is shown
    only if something in it is found, whole, what is not found dimmed (`SetMatchesSearch`, as the game's bags dim it).
    A character Core has not read slot by slot yet (it has not logged in since) has what it wears by category.
  - **In the bags' window** (`Alts/Alts.lua`, built by `Bags.Build`): a canvas of its own in the bags' scroll area's
    child (`Canvas.New` with the bags' store, `store.bags`: their display, order and folded blocks) and a pool of
    read-only buttons (`Cells.New(child, Alts, Items.Button)`), the doll in the same child, a foot over the bags' own
    (`Foot.frame`, hidden meanwhile), the word in the items' place (*Loading...*, *No items found*). `Bags.lua`'s `Draw`
    draws by whose things are shown (`face`): the bags' canvas, or `Alts.Draw(key, view, query, room, how, size)`, the
    other canvas emptied (`Alts.Clear`; the bags' drawn with no blocks). `Alts.Draw`: `Views.Build` with the view the
    bags' sidebar chose (One Bag, Each Bag, Pinned and Recent give way to All Items: `Bags.lua`'s `LIVE`), `Alts.PLAIN`
    and, while searching, `Contents.FOUND` (what `Snapshot` found stands; the bags' search also finds by category and
    item level, the dropdown's counts would not fit it); `Tidy` takes out what the views left that is not shown here (a
    category without items; a place's head with nothing under it while only some is shown) and gives a place's head
    its count. It returns the height, how many items are shown (the title line's count) and `Items.Counts` for the bags'
    sidebar (`BagSidebar.Refresh(counts, view, options, true)`: *All Items* with the total, the categories and groups
    taking no item, no One Bag, Each Bag, Pinned, Recent or Add Category). `Bags.Face` sets the bags' own buttons
    (clean-up, strip, junk marker, `Foot.act`), the strip and the foot aside for another and back for you, ends the junk
    marker's mode, and draws; `Bags.Show(true)` opens with the bags as they are. *Found elsewhere* lists every character
    not shown that has any of what is searched (you: your bags as they are while another is shown; your bank as last
    seen while yours are). Listens only while another is shown (`Alts.Show`): `GET_ITEM_INFO_RECEIVED`,
    `ITEM_DATA_LOAD_RESULT`, `Core.Data.OnCharacters`, drawn a frame later (`Core.Later`; the names the game tells
    together, `Alts.NAMES` later). A character's class, level and realm of a wrong kind (Core checks only its name and
    places) are left out. Before (2026-11-15, the same day) a body of its own with a sidebar *Storage*, a foot and a
    *View* stood in the bags' place: it replaced the bags' own parts, and went.
- **The bags** (`Bags/`, the parts `bags` and `bank`): the backpack, the bags, the reagent bag and the keyring
  (`Contents.Carried`: those with slots) in the window *Bags*; while the bank is open (`BANKFRAME_OPENED`, at the
  login `C_PlayerInteractionManager.IsInteractingWithNpcOfType` for each of `Bank.BANKERS`: `Bank.Start`,
  `Contents.bankOpen`) the tabs of
  each bank the game lets the player see (`Contents.Banks`: `C_Bank.FetchPurchasedBankTabIDs` of
  `Enum.BankType.Character`, then `.Account`) in the window *Bank*. The game's bag and bank windows are never
  opened, closed or touched.
  - **What they hold** (`Bags/Contents.lua`, no frames): a record per slot, made once and filled anew at each
    reading (`Contents.Read`: `C_Container.GetContainerItemInfo`, `GetContainerItemQuestInfo`,
    `C_NewItems.IsNewItem`, the class from `C_Item.GetItemInfoInstant`, the bind type, price, level needed and
    the class's and subclass's words from `C_Item.GetItemInfo`, the item level of gear from
    `GetDetailedItemLevelInfo`; an item the game does not know yet waits for `GET_ITEM_INFO_RECEIVED`,
    `Contents.waiting`, the bags' and the bank's, left once a reading knows it; meanwhile its record holds none of
    the words of the item there before). Whether the character can use it: a line of its tooltip in the game's red
    (`C_TooltipInfo.GetBagItem`; a recipe: `C_Item.IsUsableItem`), not asked while the game does not know the item,
    kept per link while the character's level stays (`Contents.Scan` sees a new one, the bags shown or not). The
    equipment set a slot is in (`Contents.Sets`: `C_EquipmentSet.GetItemLocations`, the game's
    `EquipmentManager_GetLocationData`; the first set wins). The bag it is in: the reagent bag (`reagentBag`) or a
    bag for one kind of item (`special`: the game's bag family, the keyring). The free slots by kind of bag
    (`Contents.Scan`, `Kind`). Orders (`Contents.ORDERS`): *Default* (gear by item level, then the subclass's
    words, quality, name, item ID), quality, name, item level, at last bag and slot. The search
    (`Contents.Found`): `Core.Fuzzy.Match` over the name, the category's name and the item level. Junk to sell
    (`Contents.Junk`): in Junk with a price, not in a special bag, not in an equipment set, not pinned, not
    refundable (`GetContainerItemPurchaseInfo`).
  - **The categories** (`Bags/Categories.lua`, no frames): the built-in ones (`Categories.LIST`: their rules,
    `fixed`, `last`, `alone`, the first groups), the
    player's own (`own1`, `own2`, …), the order (`Categories.Order`: Pinned and Recent first, the movable ones in
    the player's order, a new built-in one before Miscellaneous, a late one at the end, Junk last while the junk
    marker is on), the icons (`Categories.Icon`, `GroupIcon`: the game's own icons, `Categories.ART` by the key and
    `Categories.Art(key)`, for every built-in category, view and group, Add Category and a category of the player's
    own without an icon chosen (Saneroki, 2026-11-15: Blizzard's art in place of our pencil drawings); one the player
    chose for one of their own stays; every one cut a little round its edge), the groups (`GroupOf`, `Members`, `GroupWord`: its own name, its first name, else its members'
    "A & B"; a group of one is none), an item's category (`Categories.Classify`: the reagent bag's, a special
    bag's, the player's, Camp Items by the game's item IDs, Quest Items, Junk for grey, Item Set Gear, then by
    class in order, else Miscellaneous; a category switched off sends its items to Miscellaneous). An item let go
    over a category or chosen for it: `Categories.File` (Pinned pins it, its category kept for when it is
    unpinned; a group's key `Into`; Junk `MarkJunk`; any other `Assign`; anywhere but Pinned it is unpinned too,
    since a pinned item stands only under Pinned). Kept by item
    ID in `options.bags` (account-wide, the player's own settings, never shared): `assigned`, `before` (where a
    junk-marked item was), `pinned`, `own`, `order`, `words`, `member`, `groups`, `off`, `hidden`; checked when
    read (`Categories.Check`). Moved by the menus (`Move`: one place, past a whole group; a group's member among its
    members; `MoveGroup`: a group as one; what is switched off stepped over) and by the sidebar's drag (`Place`: before or
    after another, then in a group or none; `PlaceGroup`: a group's members together; `Movable`: not Pinned,
    Recent, Junk; a target that does not move: the end, before Junk).
  - **What came in lately** (`Bags/Recent.lua`, no frames): from the login on, a frame after a burst of bag
    events, every item's count in the carried bags and on the character (`GetInventoryItemID`); one that went up
    goes to the front of `Recent.list` (at most `Recent.MOST`, until a `/reload`). Not counted while the bank is
    open; `Recent.SETTLE` seconds after it closes, counted anew without anything new.
  - **The views** (`Bags/Views.lua`, no frames: `Views.Build`): the sidebar's choice as blocks: *all* (Pinned,
    Recent, then a block per category in order, a group as its title (`block.title`) and its members that hold
    something as blocks of their own (level 3) and the group's one empty slot (`block.bare`, `block.drop`
    "group:<group>"), or, with `Categories.Divided` off (`options.bags.whole`), one block of all its members' items,
    hidden ones left out, empty ones shown
    but not while searching nor in the bank), *one* (Pinned, *Main Bags* with every slot of the ordinary bags, then each special bag and the
    reagent bag), *each* (every bag), `cat:<key>`, `group:<group>` (its members each a block). Stacks of an item
    that is no gear merge into one entry with their counts added (`Views.Merging`: not while talking to a vendor,
    a banker of any kind the client has, the mailbox, a trade partner, nor while the auction house is open); a split item stays apart while the window is open
    (`Views.split`). What the search does not find is left out, or faded in *one* and *each*. `Views.Counts`: how
    many cells each category and group shows (Pinned and Recent too, stacks merged as they are shown), for the sidebar.
  - **The displays** (`Bags/Layout.lua`, plain numbers: `Layout.Lay`): *grid* (the blocks side by side in bands,
    `BAND_GAP` apart, as many as fit across, the next on a new band; each under its head (no rule under it): its
    cells `Layout.SIZE` 51 (half again the game's; the size a window draws at: `Layout.Fit`, the slider's percent `scale`
    kept with the window, smaller while fewer than `Layout.FIT` stand in a line, never under `Layout.SMALLEST`; the gap
    with it, `Layout.Gap`) and `GAP` 5 apart, then where it takes items (`block.plus`) one empty slot; a block
    takes the room of its cells or of its head's words (the canvas measures them), whichever is wider, at most the
    room, more cells in more lines; a block with nothing to show left out. A group's title over the whole width (no line
    under it; a part's head with the thin golden line), its members' blocks side by side under it, a line of their own. An
    empty slot: an item let go or clicked on it goes into the block's category, `Menus.Drop` with `stow`), *list*
    (a line `Layout.ROW` high per cell, a folded block its head only, a folded group's title its members too),
    *compact* (the blocks side by side in bands, a name over each: which blocks share a band and how many lines it
    takes planned by dynamic programming for the least height, `Plan`; a block that is not the last of its band at
    least three wide; on a tie the fuller band first; the empty slots after the cells as in the grid). The display and the window's Sort By are kept (`options.bags`:
    `look`, `sort`; `order` is the categories').
  - **The splitter** (`Bags/Split.lua`): a dialog of ours in the flat look, opened by `Bags.Clicked` after the
    template's own Shift-click, only where that opened the game's `StackSplitFrame` for that button (then hidden:
    `Split.Replace`; a Shift-click that linked the item into the chat opened none; in a fight the game's stays);
    `C_Container.SplitContainerItem` then `PickupContainerItem` into the first free slot of the ordinary bags; *Auto
    Split* one split after the other, each once the source slot is unlocked again (looked at every `Split.WAIT`
    seconds, at most `Split.LONGEST`), stopped when another stack is chosen and, with the dialog, when the bags or the
    bank hide (`Split.Stop`); the item split goes into `Views.split`.
  - **Our sort** (`Bags/Sort.lua`, the clean-up in *One Bag*: `Sort.Start` with the window's order): the slots of
    the ordinary bags (`Sort.Ordinary`: a record's `kind` "bags"), planned without frames (`Sort.Plan`): first the
    partial stacks of an item (`record.stack`, the game's full stack) joined, the smallest onto the largest, the next
    onto the next; then each slot given the item the order wants there (pinned first, then `Categories.rank`, then
    `Contents.Before` with the order, then the link, the larger stack first; empty slots last), from a slot that is
    not right itself where there is one. In passes: each slot at most once in a pass, a move two
    `C_Container.PickupContainerItem` (the game swaps or joins); then it waits for `BAG_UPDATE_DELAYED` and every
    slot unlocked (`Sort.WAIT`; at most `Sort.LONGEST` without word from the game) and reads the bags anew
    (`Bags.Carried`). It stops when nothing is left to move, when a pass changed nothing (what the slots held, as
    words), after `Sort.PASSES`, at `PLAYER_REGEN_DISABLED`, with something on the cursor (a move that left one
    there: `ClearCursor`) and when the window hides (`Bags.Show`). The clean-up button is locked and greyed meanwhile
    (`Bags.Sorting`).
  - **The settings** (`Inventory.lua`'s `OPTIONS`, the section *Bags*, Core's options): `first`, `showPinned`,
    `pinnedOne`, `showRecent`, `recentOne`, `addCategory`, `merge`, `marker`, `splitter`, `itemLevel`,
    `bind`, `setName`, `coin`, `grey`; read by the views, the sidebar, the categories (`Categories.Marker`)
    and the cells; changed from the dropdown and menus by `Core.Set`; a change draws the bags anew
    (`Bags.Settled`). What the window keeps of itself (the display, the order, the columns, the strip, the sidebar
    folded: `side`, the folded blocks) and the categories' choices stay in `options.bags`.
  - **The list's columns** (`Bags/Columns.lua`): `Columns.LIST` (icon, name, level, required, kind, bind, count,
    sell), the ones shown in order (`columns`), widths (`widths`), the sort (`listSort`, `listDown`), round icons
    (`round`), all kept in `options.bags`. `Columns.Place` gives each its place in a line (the name the room left,
    the others narrower together where the name would keep less than `Columns.NAME_LEAST`), `Columns.Value` what
    it shows, `Columns.Sort` a block's entries by it. A head per window (`Columns.Build(parent, redraw)`: the bags'
    is `Columns.head`, the bank has one), all arranging the bags' columns; a change refreshes every head and draws
    every window anew; round icons `Columns.Rounded`. The head (`head:Refresh`): a click sorts, a drag
    past `Columns.DRAG` moves the column where its neighbour's middle is crossed, a grip at its right edge sizes it
    (at least `Columns.LEAST`), a right click its menu (the game's). Folded blocks are kept in `folded`.
  - **The item buttons** (`Bags/Cells.lua`): a pool per window (`Cells.New(parent, owner)`; the bags' is `Cells.bags`,
    and Cells' own functions are its; the owner's `Hover` and `Clicked` answer its buttons; `Cells.Record` a button's
    record whatever its pool): the game's `ContainerFrameItemButtonTemplate`, taken in the
    order of the cells drawn (`Cells.Take`), each in a holder of ours that carries the bag's ID (`SetID`): the
    template's `GetBagID` asks its parent, so nothing of ours is written into the button and its click (use,
    drag, split, sell, deposit) is the template's own code, in a fight too. Made out of a fight only
    (`Cells.short`, `Core.AfterCombat`). The kit's look set on the template's own parts once: the game's bag slot at the
    button's edge (`Style.Slot`: `bags-item-slot-blank`), the icon inset by `Style.SLOT_ICON` of the cell and cut
    `Cells.ZOOM` round its edge, its quality's border round it (the template's `IconBorder`, as the game draws it),
    its mask, normal texture and new item's glow away, the highlight to the icon's size, a warm glow pressed; the
    icon square, as the game's (a circle, `Cells.CIRCLE` by `Cells.Mask`, for the list's round icons,
    `Cells.Round`); ours beside them in a table
    of our own: above the cooldown's swipe the count, the item level, BoE, the set's name, the game's `QuestNormal` on an item
    that starts a quest, the junk coin, the game's green arrow (`bags-greenarrow`) at the top right on gear that would
    make the character better (`Core.Upgrade`; always, bank too, drawn anew as what you wear changes); an empty slot the game's slot alone, a little dim (`Cells.EMPTY_SLOT`; so too the end of a block's "+" slot and an empty bag slot in the strip).
    Drawn by the template's own functions (`SetItemButtonTexture`, `Quality`, `Count`, `Desaturated`,
    `UpdateCooldown`, …). In the list the button's hit rect reaches over its line. Hooks after its `OnEnter`,
    `OnClick` and `OnMouseUp` light a list's line, open the item's menu (Alt and the right button, which the
    template does nothing with) and pin it (the middle button: `Bags.Clicked`).
  - **Choosing by clicks** (`Bags/Select.lua`): `Select.Start("put", key)` (a "+" clicked with nothing on the
    cursor) or `"junk"` (the bar's coin): a catcher over the scroll area takes the mouse (the item under it lit:
    a border of `Core.GOLD`, a pale veil; found by `IsMouseOver` when the cursor moved), the bar, strip, sidebar
    and foot dimmed (a click there ends it); a click puts the item in (then the mode ends) or marks or unmarks it
    as junk (the mode stays); a right click, Esc (`SetPropagateKeyboardInput` for every other key) or
    `PLAYER_REGEN_DISABLED` ends it. The game's item buttons never see those clicks.
  - **The empty slots** (`Views.lua`'s `block.plus`, `Layout.lua`'s `plus` places, `Canvas.lua`'s `Sheet:Plus`):
    after Pinned (shown when empty too) and every category that takes items (`Categories.Takes`; not Recent, the
    reagent bag's or a group, which take none), in the grid and the compact display; an item
    on the cursor clicked or dragged there `Menus.Drop`, else `Select.Start`. In its middle its category's icon
    (a group's, `Categories.GroupIcon`; grey, cut round its edge), `Canvas.SLOT_ICON`
    (0.75) of the slot's side at `Canvas.SLOT_FADE` (0.3): a subtle grey.
  - **Letting an item go over an item** (`Views.lua`'s `block.into`, `Canvas.lua`'s `Sheet:Catch`): the bags'
    Pinned, every category of theirs that takes items and a group shown as one give their cells `into` (`Into`:
    the bags' section, `Categories.Takes`; the bank's, the alts', Recent's and the slots of One Bag and Each Bag
    none). The game's button would put the item held into its slot, swapping the two, and keep nothing. So while
    an item is held over such a cell (the bags' `Hover`, after the game's `OnEnter`) and it is not the cell's own
    item (its stacks join as the game joins them), one catcher per canvas lies over the button (`SetAllPoints`,
    the button's hit rect, as in the list the whole line; ten frame levels above it), lit, its tooltip the
    category and `bagsDropTip`; let go or clicked there `Menus.Drop` with `into`; it goes when the mouse leaves, at
    each drawing and once nothing is held (its `OnUpdate`, only while shown). The game's button is left as it is,
    its scripts and clicks its own.
  - **The sidebar** (`Bags/Sidebar.lua`): `ns.Sidebars.New(body, top, bottom, options)` a window's (rows in the
    kit's look, `Sidebars.WIDTH` wide (a window that answers `fold` gets an arrow in the head: `Rail:Fold`, the
    narrow edge `Sidebars.FOLDED` with the arrow alone; the arrow the game's chevron (`Style.PIECES.arrow`,
    `uitools-icon-chevron-down`) pointing down, `Sidebars.TOGGLE` square in its button's middle at `Sidebars.MARK`, whole under the
    mouse, turned left (folds) or right (unfolds); a group's row has the same arrow turned down while folded, up
    while listed, and beside it a box as large, the game's minimal checkbox (`checkbox-minimal`) with its tick
    (`checkmark-minimal`), as dim), the names in Friz Quadrata always shown (one cut short whole in its tooltip), the
    view shown in a gold glow with a bar at its left; scrolled by the wheel; `Begin`, `Row`,
    `Divider`, `Done`; its `choose`, `drop`, `menu`, `add` answer the clicks); `ns.BagSidebar` the bags' (every
    category switched on, empty ones too; a click `Bags.Choose`, an item on the cursor let go there `Menus.Drop`, a
    right click `Menus.Row`). A row the window marks (`row.drag`: the bags' movable categories and groups) is
    dragged (`OnDragStart`, not with an item on the cursor; `Rail:Lift`, `Land`, `Cancel`): a ghost of it on the
    cursor (`Sidebar.GHOST`, the strata `TOOLTIP`, its `OnUpdate` only while shown, given up when the button is
    no longer down), the row faded (`Sidebar.LIFTED`), the row under the cursor and how far down it (`Rail:Under`)
    asked of the window's `aim` (`Bag.Aim`: the top and foot quarter `Sidebar.EDGE` before or after, the middle
    into; a line of `Core.GOLD`, set in where it lands in a group, or the row lit, `Sidebar.INTO`); let go, the
    window's `place` (`Bag.Place`: `Categories.Place`, `PlaceGroup`, `Join`, `GroupWith`; drawn anew). Pinned and
    Recent take nothing, Junk only before it, a group goes before or after a group as a whole.
  - **The drawing** (`Bags/Canvas.lua`): `ns.Canvas.New(child, owner)` a window's: the heads (a right click
    `Menus.Row`, an item let go `Menus.Drop`, in the list a click folds: `folded` in the owner's store), the compact
    display's labels, a block's empty slots (no sign in them, lit while an item is held over it), the list's lines
    and the item buttons (the owner's pool), drawn as
    `Layout.Lay` places them (`canvas:Draw`). `Views.Build` takes a window's own store of blocks.
  - **The bank's window** (`Bags/Bank.lua`, the part `bank`, `Present` while `Contents.bankOpen`; the board leaves
    it out while away and the first layout too: `Board.lua`'s `spec.present`, `Window.Reboard` at the banker's
    events): its sections read as the bags' (`Contents.Scan` per bank), a sidebar (All Bank Tabs, One Bank, each tab
    by `Contents.BagWord`, its slots taken), the views (`Views.Build` *each*, *one*, a tab's own section; with
    `group` the bags' *all* without Pinned, Recent and "+"), a canvas and a pool of its own, the bar (the count, the
    reagents' deposit: `Foot.Deposits`, `C_Bank.AutoDepositItemsIntoBank`; the clean-up of the bank shown:
    `C_Container.SortBank`; the dropdown *View*: grid, list, compact), the gold at its foot. Kept in `store.bank`:
    `look`, `order`, `group`, `folded` (the list's columns are the bags'). Listens while shown (bags, bank slots and
    tabs, a tab's settings, locks, cooldowns, money: the gold only; an item's data only for one it waits for).
    - **The list** (`Place`): a column head of its own (`Columns.Build`) over the scroll area while the display is
      the list; the canvas draws the bags' columns.
    - **A tab's settings** (the sidebar's `menu` and `tip`): a tab's row by its icon (`C_Bank.FetchPurchasedBankTabData`,
      `Bank.TabData`), its tooltip what it takes (`Bank.TAKES`: the game's flags `Enum.BagSlotFlags` and words
      `BAG_FILTER_*`, `Bank.Takes`). Its right click, where the client has `C_Bank.UpdateBankTabSettings`, the game's
      menu: *Rename* (`Core.AskText`, `Bank.LETTERS` 16 as the game's box), *Assign To* the five kinds and *Ignore in
      Clean Up* (`DisableAutoSort`), each a flag set or cleared in plain numbers (`Bank.Has`, `With`), the name, the
      icon and the other flags as the tab has them; drawn anew at `BANK_TAB_SETTINGS_UPDATED`.
    - **Buying a tab**: where `C_Bank.CanPurchaseBankTab` (and not `HasMaxBankTabs`) a row *Buy Tab* after that
      bank's tabs (the character's even without a tab yet); its tooltip the cost
      (`C_Bank.FetchNextPurchasableBankTabData`). Over it, unseen, lies the game's own button made for addons
      (`BankPanelPurchaseButtonScriptTemplate`, one per bank, made once, `overrideBankType` set to the bank), so its
      click is the game's: the game's question `CONFIRM_BUY_BANK_TAB`, then its purchase. Our code never buys and
      never touches that button's click; only its `OnEnter`/`OnLeave` light our row. Without that template there is
      no row.
  - **The window** (`Bags/Bags.lua`): the bar (`Bags.BAR`) on the panel's title line (anchored to `panel.title`,
    above the head that drags the window; its round buttons `Bags.Round`: the icon in a circle, `Bags.SOFT` the
    ink's alpha one, two, three pixels out, the highlight and checked light cut to the circle), the strip of the
    bags at the body's top (kept: `strip`; hidden while the sidebar is folded, `Bags.Fold`, kept: `side`), the panel itself
    and its head taking an item let go where nothing above them does (`Menus.Home`; the items' scroll child takes
    no mouse, so the item buttons keep theirs), the scroll area a plain `ScrollFrame` without a bar (`Bags.STEP`
    the wheel's step, `Bags.RIGHT` its room at the right), the sidebar,
    the scroll area, the foot; the heads (a part's, a block's, a group member's) taking items and opening menus,
    the compact display's labels, the list's lines; the dropdown *View* (`Style.Dropdown`: the game's `DropdownButton` in a thin golden box, the game's chevron) with the
    displays, the orders and the switches (`showPinned`, `showRecent`, `merge`, `first`, the
    categories switched off). The view chosen holds while the window is open (`Bags.Choose`); it opens with
    `first`.
  - **The menus** (`Bags/Menus.lua`): the game's (`MenuUtil.CreateContextMenu`) for an item and for a category or
    group; names asked in the game's dialogs (`Core.AskText`, `Categories.LETTERS`), a category deleted after
    `Core.Confirm`. Each choice is kept at once and the window read and drawn anew (`Bags.Refresh`).
  - **The foot** (`Bags/Foot.lua`): the currencies watched (`GetBackpackCurrencyInfo`, `SetBackpackToken`), the
    gold (`Core.Coins`; its tooltip every character's from `Core.Data.Characters` and the total); the strip of
    the bags (the game's `ItemButton` in the game's slot, its bag icon square and
    no border, an empty slot no icon, its free slots on it;
    the game's tooltip for a bag, *Equip Container* for an empty slot; `PickupBagFromSlot`, `PutItemInBag`,
    `PutItemInBackpack`, `PutKeyInKeyRing`, out of a fight); the bar's button for what can be done here (selling
    the junk after the game's `SELL_ALL_JUNK_ITEMS_POPUP` in `Core.Confirm`: the bags read anew, then
    `C_MerchantFrame.SellAllJunkItems` where the junk is just the game's, else `C_Container.UseContainerItem` on
    each, one every `Foot.STEP` seconds while the vendor is there, out of a fight and with the cursor empty, the
    item checked to be still in its slot; `Core.Print` says how many were sold for how much and how many could
    not be; `C_Bank.AutoDepositItemsIntoBank` where `DoesBankTypeSupportAutoDeposit`).
  - **Speed Leveling** (`Bags/Vendor.lua`, Saneroki, 2026-10-30): a checkbox beside Auto Sell and Auto Repair that is the
    profile (`profile` in `Vendor.BOXES`): ticked, this character uses *Speedleveling*; unticked, the one it used before,
    *Accountwide* if it had no other (`Core.Profiles.SetLeveling`), its tick following through `Core.OnSwitches`. No box
    while that module is off.
  - **Make Room** (`Bags/Vendor.lua`, `Bags/Room.lua`, Saneroki, 2026-10-30): a checkbox for Loot's switch *Make room for
    loot* (`module` in `Vendor.BOXES`: read with `Core.Settings`, set with `Core.Set`). One slot stays free: when the last
    one fills, the junk worth the least (`Contents.Junk`, all of its stack) goes, and the chat says so. The game destroys an
    item only on a press of the player's (`DeleteCursorItem`, `HasRestrictions`), so it goes at the next key press out of a
    fight: a frame hears the keyboard (`SetPropagateKeyboardInput`) only while something waits, and hands every key on. The
    game refuses now and then: the item goes back into the bags and it is tried again `Room.AGAIN` seconds later. No junk:
    a warning in `UIErrorsFrame`, once a minute (`Room.WARN`).
  - **Auto Sell and Auto Repair** (`Bags/Vendor.lua`, Saneroki, 2026-10-30): two checkboxes in the foot, left of the
    gold (the settings `autoSell` and `autoRepair`, on at first, also on the page Inventory): the game's
    minimal checkbox and its tick, the word beside it. A frame after
    `MERCHANT_SHOW`, heard from the login on, so the bags need never have been opened (`Vendor.Start`; the two events
    a vendor may send make one run, `Core.Later`), the junk goes first, so its money goes to the repair: `Foot.Sell`,
    what the bar's button sells, unasked, `after` run when it is done (`Foot.SOLD` seconds after the game's sell-all,
    which brings the money a moment later). Then `RepairAllItems` with the character's own money, if the vendor
    repairs (`CanMerchantRepair`), `GetRepairAllCost` says so and the money is there. The chat says what was sold and
    what the repair cost. Shift held as the window opens leaves both to the player.
  - **Events, while shown only** (`Bags.Show`): `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`,
    `BAG_CONTAINER_UPDATE`, the quest events, the vendor's, mailbox's, trade's and auction house's opening and
    closing, `EQUIPMENT_SETS_CHANGED`, `BANKFRAME_OPENED`/`CLOSED` and the bank's slot and tab events: everything
    read and drawn a frame later (`Core.Later`); `ITEM_LOCK_CHANGED` greys one slot; `PLAYER_LEVEL_UP` asks
    anew who can use what; `BAG_UPDATE_COOLDOWN`, `PLAYER_MONEY`, `CURRENCY_DISPLAY_UPDATE` their own part.
- **WoW: Forever and Retail** (2026-10-25; `Doc/guides/addon-standards.md`, *Forever and Retail*): one code for both,
  each part asking the game for what it needs. What only WoW: Forever has stands down in Retail without a word:
  the skills and PvP windows (not registered: not in the dropdown *Windows* nor among the title bar's tabs), the
  resistances and the pet's stats in the stats' window, the ranged and ammo slots on the doll, the keyring in the
  bags (the game gives it no slots). The rest is the same in both: the doll, the stats (Retail's own categories,
  attributes and enhancements), gear sets, titles, reputation (renown as the game's bar has it), currency,
  statistics, the bags with the reagent bag, the bank with its tabs and the account's (Retail's warband bank), the
  other characters. In Retail the coloured bars are `Rows.Bar`'s own and the side tabs' icons Retail's
  (`Board.ICONS`).
- **Never the game's panels** (2026-10-20, from the error log): our code neither opens nor closes the game's
  character sheet or any other panel of its window manager (`UIParentPanelManager.lua`). Opened by our code,
  the manager ran tainted and the sheet's `OnShow` failed on the player frame's secret health
  (`ShowStatusBarText`, `TextStatusBar.lua`); the manager's slots, written by our call, made the game's own
  close button fail too until a `/reload` (`Doc/guides/addon-standards.md`, *Known traps*). Hence our own
  windows.
- **Standing down** (`ns.GiveBack`): the bag keys and the game's bag windows are the game's again first, then the
  board's windows go and the window with them, each step by itself (`ns.Safe`). A `/reload` starts the module afresh.
- Tests: `dev/tests/inventory.lua` (the window, the board, the paper doll, the stats, the other characters in the bags' window
  and an alt's paper doll), `dev/tests/sheet.lua` (the sheet's windows on the board, the sidebar with its gear sets and titles, the game's tabs as windows), `dev/tests/bags.lua` (the bags); each also as Retail (`W.Play("retail")`: the level line, the stats, the windows that stand down, the icons, our bar, the bags without a keyring).

`LevelUp.lua` (Saneroki, 2026-10-30) tells a new level in the middle of the screen. What it brought comes with
`PLAYER_LEVEL_UP`, a line only for what grew, in Core's short words (`Core.StatWord`; Retail's event has no Spirit); the
game's second number is told as mana, as its chat did; the time from `TIME_PLAYED_MSG`,
asked once five seconds after the login with the chat windows deaf to that one answer (`Core.Lend`, `SetDeaf`), so
`/played` stays as it was; `GetTime()` counts on from there and the level's start is the level-up itself.
The chat windows write their level-up lines at `PLAYER_LEVEL_UP` themselves (no `CHAT_MSG_`, no filter), Retail's at
`PLAYER_LEVEL_CHANGED`, and Social's window takes what they write (`AddMessage`). So they are lent deaf to those two, at
the world's entry and each `PLAYER_XP_UPDATE`: the game adds the events again when the player changes what a window
shows. The game's toast is `EventToastManagerFrame`, a toast of `Enum.EventToastEventType.LevelUp` in it; it must run on,
since its animations end it and bring the next toast, and they stop on a hidden frame, and its alpha would be its fade's
during those. So at `DisplayToast` (hooked) it is lent under a frame of ours at alpha 0, and back at the next toast or
at the end of them: every other toast shows as ever. `ns.GiveBack` gives both back. Its height is `Core.TOAST_TOP`, as
the travel overlay's, `LevelUp.RIGHT` (340) right of the middle (Saneroki, 2026-11-04: Speed Leveling's arrow, 240
wide, stands in the middle there and stays in sight; the shade's fading left edge ends beside it), so it takes no
place at the top (`Core.TellsAtTop`). Its look:
`Doc/guides/interface-style.md`, *A new level over the world*.

## Stat weights
`Asks.lua` (Saneroki, 2026-10-30): *Equip and delete without asking*, on in every profile: the game's questions before gear
binds or ends a refund answered as their own Yes would. Destroying waits for a press of the player's (`DeleteCursorItem`,
`HasRestrictions`; the game blocked it every time inside the question's own frame, which comes with the drop: Forever 70790
to 70888): the question comes up with the word typed in, and the item goes at the next key, as Make Room's does (a frame
that hears the keyboard, `SetPropagateKeyboardInput`, shown only while a question waits; out of a fight; Escape is the
game's No and keeps it); a click on Yes does it at once. Where the game refuses that too, the question stands, and the next
item is tried again.

`Weights.lua` (Saneroki, 2026-10-30) says what each stat is worth to a character, so that an upgrade is one for the class
and specialization played. Core's `Core.Upgrade` asks for them (`Core.WeighWith`), so the arrow in the bags, Loot,
Speed Leveling's rewards, Equip upgrades and its group rolls all judge the same way; with Inventory off, item levels
decide. One line per specialization, the numbers a leveling character goes by, the stat it builds on at 1 so that two
classes' gains can be held against each other; `early` for a character without a specialization yet.
- **Forever** (`Weights.FOREVER`): pairs of a stat and its worth, by the game's rules where they say (a warrior's Strength is
  2 Attack Power, 14 Attack Power 1 damage per second, so `str 1 ap .5 dps 7`; a feral druid's the same, its forms
  swinging the equipped weapon in WoW: Forever, unlike Classic's).
- **Retail** (`Weights.RETAIL`): the main stat, then the secondaries best first down `Weights.LADDER`; Stamina and a
  physical fighter's weapon damage the same for all.
- `dps` is a melee weapon's or staff's damage per second, `ranged` a bow's, gun's, thrown weapon's or wand's.
- **A shield build** (Saneroki, 2026-11-04): a warrior whose talents work only with a shield gets its weights with
  `shield`, and `Core.Upgrade` then takes no two-hander (one held counts as nothing in either hand), judges a one-hander
  against the main hand alone and lets only a shield into the off hand (its armour, block value and stats). A shield
  build is the game's primary talent tree being Protection (`Weights.SHIELD`, `C_SpecializationInfo.GetSpecialization`),
  or a talent with a rank whose spell's tooltip asks for a shield (the game's `SPELL_EQUIPPED_ITEM` with its name for
  shields; in WoW: Forever Shield Slam, Bastion and Defiance). Asked anew when the talents change. No setting: before the
  first talent point (level 10) nothing of the warrior's needs a shield and a two-hander's damage leads; from it on the
  talents say. Druids and the other classes are not touched.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Inventory.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Art/banner.blp`, `Art/icon.blp` | The module's logo (a chest): one of Sane UI's family of logos (`dev/tools/logo-art`), its banner at the top of its options page, its icon in the addon list (the TOC's `IconTexture`). Original art of Sane UI (see the project's `LICENSE`), made by `dev/tools/art` from `assets/Logos/inventory-banner.png` and `inventory-icon.png` |
| `Inventory.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Keys.lua` | The bag keys open the full screen with the bags; the game's bag windows and bag bar kept unseen |
| `Bindings.xml` | Inventory's key in the game's key bindings |
| `Window.lua` | Its window: docked in the bottom right corner, filling the screen from that corner |
| `Board.lua` | The full screen's windows on Core's board; the parts register theirs; which draw their own frame (`Board.DRESS`), which fill their body to its edges (`Board.FILLED`), their bodies' sizes |
| `Style.lua` | What the windows draw with, in the kit's look (`Core.Look`): the game's Friz Quadrata in its own colours (white words, gold heads, grey; every word `Style.WORDS` times its first size, the heights laid out for words grown by `Style.Fit`), the thin golden line and box, the game's slot, chevron, checkbox and tick, the dropdown in a thin golden box, the red button's art |
| `Sheet/Doll.lua` | The character's doll: its bronze frame, its slots in Forever's gear slot frames, the hero's place, the items' stat lines |
| `Sheet/Slots.lua` | The character sheet's equipment slots, in the doll's slots, and their strips |
| `Sheet/Model.lua` | The character sheet's model, still, in the doll's hero's place |
| `Sheet/Stats.lua` | The stats, the player's and the pet's: the game's list and rows, put together by our code |
| `Sheet/List.lua` | A window's scrolling list in the game's look |
| `Sheet/Side.lua` | The side pane at a window's right, as the game lays it out |
| `Sheet/Rows.lua` | The rows the reputation, skills, currency and statistics windows list, in the game's three looks |
| `Sheet/Page.lua` | What a window of the game's tabs stands on: the left part and the game's right pane; registers it |
| `Sheet/Sheet.lua` | The character: the paper doll, the level line, scaled to its window; registers the part `character` |
| `Sheet/Gear.lua` | The sidebar's equipment manager: the gear sets, Equip, Save, New Set |
| `Sheet/Titles.lua` | The sidebar's titles |
| `Sheet/Sidebar.lua` | The stats' window: the right pane, the game's sidebar tabs, their panes; registers the part `stats` |
| `Sheet/Reputation.lua` | The reputation window |
| `Sheet/Skills.lua` | The skills window (WoW: Forever's skill lines; none in Retail) |
| `Sheet/PvP.lua` | The PvP window: the season's rank (WoW: Forever's; none in Retail) |
| `Sheet/Currency.lua` | The currency window |
| `Sheet/Statistics.lua` | The statistics window |
| `Bags/Contents.lua` | The bags, without frames: the containers, a record per slot (bind type, price, who can use it, the set it is in), free slots, orders, the search, the junk to sell |
| `Bags/Categories.lua` | The bags' categories, without frames: the built-in ones and their rules, the player's own, their order, names and groups; pins, items put into a category, junk marks |
| `Bags/Recent.lua` | What came into the bags lately, without frames: counted from the login on |
| `Bags/Views.lua` | What each view of the sidebar shows, without frames: blocks of cells, stacks merged, the search |
| `Bags/Layout.lua` | The bags' displays (grid, list, compact): where each cell, empty slot, line, head and label goes, as plain numbers |
| `Bags/Cells.lua` | The bags' item buttons: the game's own, a pool, in the flat look, drawn the game's way |
| `Bags/Foot.lua` | The bags' foot: currencies, gold; the strip of the bags; selling junk or depositing reagents |
| `Bags/Menus.lua` | The bags' menus for an item, a category and a group, items let go over a category, new categories and their icon (Core's icon chooser) |
| `Bags/Bin.lua` | Junk's waste bin's question: Delete, Cancel, Delete the item and don't ask me again; the game's own question where it refuses |
| `Bags/Split.lua` | The bags' stack splitter: split into the first free slot, or the whole stack by turns |
| `Bags/Sort.lua` | Our sort of the bags in One Bag: partial stacks joined, the items moved into the categories' order, in passes |
| `Bags/Columns.lua` | The bags' list columns: their values, sorting, widths, the head over the list and its menu |
| `Bags/Select.lua` | The bags' choosing by clicks: an item into a category after its "+", junk marked by the coin |
| `Bags/Sidebar.lua` | The bags' sidebar: the views, Pinned, Recent, the categories and groups with their counts |
| `Bags/Canvas.lua` | A window's drawing of its items: heads, labels, the empty slots, the list's lines, the item buttons, the catcher of an item let go over an item |
| `Bags/Bags.lua` | The bags' window: the bar (the characters' dropdown, the search box), the strip, the scroll area, heads, labels and lines, the dropdown *View*, *Found elsewhere*, the events; whose things it shows (`Bags.Face`: another character's drawn by `Alts.lua`); registers the part `bags` |
| `Bags/Bank.lua` | The bank's window while at a banker: its tabs, sidebar, views, bar and foot; registers the part `bank` |
| `Talks.lua` | The full screen at a vendor, a banker and a mailbox: a layout of its own for each talk; the game's vendor, mail and letter windows seated on it, the parts `vendor`, `mail`, `letter` |
| `Alts/Snapshot.lua` | The other characters' things, without frames: the roster, a character's places and items, the search |
| `Alts/Roster.lua` | The dropdown of the account's characters on the bags' title line, their gold |
| `Alts/Items.lua` | The other characters' things: the chosen one's things as the bags' records and sections, read-only buttons, the paper doll |
| `Alts/Alts.lua` | Another character's things in the bags' own window: their canvas and read-only buttons, drawn by the bags' views, the doll, their foot, the events |

## History
- **2026-10-20:** set up as a module of its own. First the bottom right corner opened the game's own bags and
  character sheet; the sheet failed in the game (tainted by our call, on the player frame's secret health), so
  the corner opened the bags only. Then (Saneroki) our own windows instead: the module's window docked in the
  bottom right corner, its corner filling the screen with the character sheet, the bags and the other
  characters' snapshots on Core's board (`Doc/ideas/Inventory.md`). The character sheet's paper doll: its slots,
  the model, the level line; its stats; its side tabs and the six tabs of the game's sheet. Then (Saneroki) each part
  a window of its own on the board, the side tabs gone, and the game's sidebar in the stats' window: gear sets,
  titles, the pet's stats.
  The window of the other characters: the roster, each one's bags, bank and what it wears as last seen, the
  search across them all; Core's `Data.Items` for it. Then an alt's gear on a paper doll, slot by slot, from Core's
  new `Data.Worn`.
  Our own bags: every slot and the bank while it is open, the game's item buttons, four views, the search, the
  game's clean-up, the bag bar, junk and reagents, currencies and gold. Then pinned items, the player's own groups
  (the game's renamed, moved, hidden or joined; items let go over a group's head) and items marked as junk.
- **2026-10-25:** in Retail too (Saneroki: one interface for both games): the coloured bars our own where the game
  has none (the reputation, currency and statistics windows had none of their rows), the stats by Retail's
  categories without resistances (which stopped the whole page) or the pet's, the specialization on the level line,
  Retail's own icons for the side tabs; the skills and PvP windows, the ranged and ammo slots and the keyring stand
  down there.
- **2026-11-07:** (Saneroki) an item let go over an item of a category goes into that category, no longer swapped
  in the bags; put anywhere but Pinned, a pinned item is unpinned, so it shows in the player's own category.
- **2026-11-09:** (Saneroki) the full screen at a vendor (the game's vendor window on the left, the bags on the right)
  and at a banker (the bags on the left, the bank on the right), each a layout of its own behind its tab; then at a
  mailbox (the mail window on the left, a letter beside it, the bags on the right).
- **2026-11-15:** the kit's look (Saneroki: "rebuild the inventory fullscreen and all its windows again with the new
  styling. Replace our custom generated art with blizzards art"): the journal's paper, leather, pencil and Kalam
  give way to WoW: Forever's own parts (`Core.Look`, `Doc/guides/interface-style.md`, *The kit*). Every window but
  the character's on the heavy bronze plate (`Board.DRESS` keeps only the doll's own frame; `Board.FILLED`),
  `Paper.lua` replaced by `Style.lua` (the game's Friz Quadrata in its colours, the thin golden line and box, the
  game's slot, chevron, checkbox and tick), the doll rebuilt as the game's character window (two straight columns
  in Forever's gear slot frames, the hero framed, the items' stats in grey boxes), the stats with the character
  window's heads and bands, the bags' cells square with their quality's border on the game's bag slot, the action
  buttons the game's red ones, the category icons the game's own icons (our pencil drawings, `Art/Categories`,
  taken out).
- **2026-11-15:** (Saneroki, seen in the game) the doll plainer: no frame round the model, no grey boxes round the
  items' stats; the quality's border as large as a weapon's icon; the bronze plate laid once per window (Core's).
- **2026-11-15:** (Saneroki) the alts merged into the bags' window, first as a body of their own in its place (a
  sidebar *Storage*, a foot and a *View* of their own), which stood in for the bags' own parts. Then (Saneroki: "restore
  the bags window we had before moving the alts features into it and then keep our bags window but add the search and
  dropdown menu to select other characters to the proper bags window") the bags' window as it was, with the
  characters' dropdown and the search box on its title line; another character drawn by the bags' own sidebar, views
  and *View* (`Alts.Draw`).
