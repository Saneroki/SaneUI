# Sane UI: Inventory

**Status:** its window and full screen built; the character sheet built, its parts windows of their own (the paper doll; the stats with the game's sidebar: gear sets, titles, the pet; reputation, skills, PvP, currency, statistics); the bags built, with pins, the player's own groups and junk marks; the other characters' window built · **Since:** 2026-10-20 · **Addon:** `SaneUI_Inventory` · **Game:** WoW: Forever (interface 16001)

## TL;DR
The module for what you carry and wear. Push the mouse into the screen's bottom right corner and the screen
fills with the module's windows: your character sheet, your bags and your other characters' things, Sane UI's
own, arranged as you like. Push it there again, or press Esc, and they go. The game's own character sheet and
bags stay as they are, and their keys open them as before. The plan is in `Doc/ideas/Inventory.md`.

## How to use
- **Switch it on or off:** tick or untick *Inventory* under *Sane UI* in the game's addon list.
- **The full screen:** push the mouse all the way into the bottom right corner. Push it there again, or press
  Esc, to go back. Not in Edit Mode, and not with *Can expand to fullscreen* off (*Sane UI > Inventory >
  Expand window*). In Edit Mode the window can be docked in another corner; the push goes with it.
- **The game's own windows:** the full screen's dropdown *Classic windows* has *Character* (the full screen
  goes back and the game's key for its character sheet is said: our code never opens it) and *Bags* (the
  game's bags open). The game's character sheet and bags have the button *Sane UI* beside their close button:
  the game's closes and this full screen comes.
- **Arranging the windows:** as on every Sane UI full screen (Core's board): drag a window's head to move it,
  the gap between two to share their room anew, its X to take it off; the dropdown *Windows* adds one; layouts
  behind tabs in the title bar. Right of those tabs, a tab with an icon for each window (your portrait for the
  character, the game's icons for the others: the sheet's tabs', a bag, a group for your alts), lit while the
  window is on the screen: a click puts it there or takes it off.
- **The character sheet**, Sane UI's own, in windows of their own that you move and size on the full screen like
  every other (the dropdown *Windows* adds the ones that are not there; at first the character and the stats):
  - *Character*: your model in the middle (drag to turn it, the wheel or the buttons over it to zoom), your gear
    round it in the game's places, your level and class above; as large as its window lets it be, never larger
    than the game's. A click on a slot picks the item up or puts the one you hold there (a drag the same), Shift or
    Ctrl and a click links it or tries it on, the tooltip is the game's; an item let go over the model is put on.
    Using an equipped item with a right click stays on the game's own sheet and the action bars.
  - *Character Stats*: your stats as the game lists them, with its tooltips (in a fight they show what they were
    before it, and are brought up to date when it is over). On the stone at its top the game's sidebar tabs:
    Stats; Equipment Manager (your gear sets: a click chooses one, a double click or Equip puts it on, Save stores
    what you wear in it after a question, New Set asks a name, a right click renames or deletes; a new set's icon is
    changed on the game's own sheet); Titles (a click wears one); Pet (your pet's stats, while you have one).
  - *Reputation*: your factions as the game lists them: a click on a header folds or unfolds it, a click on a
    faction chooses it (its standing in numbers under the mouse); at the right the chosen faction, its standing,
    its description and the game's switches At War, Move to Inactive and Show as Experience Bar.
  - *Skills*: your skill lines with their ranks (the bonus in green); choose one to see its description, and for a
    weapon skill what it means against a foe of your level and against a raid boss.
  - *PvP*: the season, your rank and the game's rank ring, your points, the time left of the season, and at the
    right the season's progress and the next reward.
  - *Currency*: your currencies (choose one for its caps and description; Shift and a click links it, the game's
    watch key puts it on the backpack), with the game's switches Unused and Show on Backpack; the transfer between
    characters stays on the game's own sheet.
  - *Statistics*: the game's statistics by category, each category folding by a click.
- **Your bags** (the window *Bags*): everything you carry, in a flat,
  dark look: each item in a thin border of its quality's colour (a quest item's in gold), its item level at the top
  left, its count at the bottom right, a quest's mark on an item that starts one, red when you cannot use it.
  - **The bar** at the top: how many of your bags' slots are taken (every bag's in its tooltip); at the right *Sell
    All Junk Items* at a vendor, the junk marker, the bags' button (your bags stand in a strip under the bar, at
    first; a click hides it or shows it again: each bag with its free slots on it; point at one to light its items,
    drop a bag on a slot to put it on, click one to pick it up), the game's *Clean Up Bags* and the dropdown *View*.
  - **The sidebar** at the left: *All Items* (every item by category; the free slots are not shown), *One Bag*
    (every slot of your bags in their order, the empty ones too) and *Each Bag* (every bag by itself), then
    *Pinned Items* and *Recent Items*, then every category switched on, by name, with how many items it holds
    (empty ones too). A click shows it.
  - **Categories:** *Weapons / Trinkets*, *Armor* and *Item Set Gear* (gear of one of your equipment sets) are
    the group *The Armory*; *Consumables*, *Gear Enhancements* and *Camp Items* the group *Adventure Prep*; then
    *Trade Goods*, *Professions*, *Reagent Bag*, *Miscellaneous*, *Quest Items* (off at first: those items are in
    Miscellaneous then), *Special Bags* (what is in a quiver, a soul or herb bag) and *Junk* last. A group shows
    as one part in All Items, its members set in under it in the sidebar. *Pinned Items* and *Recent Items* (what
    came into your bags lately) are a second look: those items stay in their own categories too. Stacks of one
    item show as one with their count added up (gear never; not at a vendor, the bank, the mail, a trade or the
    auction house, where each stack is its own).
  - **Your own way:** a middle click on an item pins it (or unpins it; an item you put into a category is taken
    out of it again). Alt and a right click opens its menu: *Pinned Items*, *Junk*, *Put Into* another category
    or a new one, *Take Out of* the one you put it into. An item picked up (or dragged) and let go over a
    category's head or its row in the sidebar goes into that category (over Pinned: pinned). A right click on a
    category (its row or its head): *Rename*, *Move Up*, *Move Down*, *Create Group With* another, *Add to Group*,
    *Take Out of* its group, *Hide in All Items*, *Switch Off*; on a group: *Rename*, *Move Up*, *Move Down*,
    *Hide in All Items*, *Disband Group*; on one of your own also *Icon* and *Delete*. *Add Category* at the
    sidebar's foot makes one of your own. All of it is kept for the account.
  - **The list's columns:** the icon, the name, item level, required level, type, how it binds (BoP, BoE, BoU,
    Quest; SB once bound), the count and what the vendor pays for it. Click a column's head to sort by it (again
    for the other way), drag it sideways to move it, drag its right edge to size it; a right click on the head
    chooses the columns, moves one, makes the icons round or puts it all back. A click on a category's head folds
    it, Shift and a click folds or unfolds them all.
  - **"+" and the junk marker:** a *+* follows Pinned and every category that takes items: bring an item to it
    (picked up, or dragged) and it goes in; click it with nothing held, and the next item you click goes in (the
    rest of the window dims meanwhile; a right click or Esc stops). The coin on the bar is the junk marker: click
    it, then click items to mark them as junk or unmark them, and click it again to stop; an item brought to it
    is marked at once. Junk is sold one item at a time at a vendor, never what is in a special bag, in an
    equipment set or pinned, nor what the vendor would take back for its price; the chat says what it brought.
  - **The dropdown *View*:** *Grid* (each category under its head, its last line filled out), *List* (a line per
    item, in columns) or *Compact* (the categories side by side in bands, planned to take the fewest lines);
    *Sort By* (*Default*: gear by item level, then by kind, quality and name; or quality, name, item level);
    *Show Pinned Items*, *Show Recent Items*, *Merge Stacks*; *Open With* (the view the
    window opens with); *Switched Off* lists what you switched off, to switch it on again.
  - **Splitting a stack:** Shift and a click on a stack opens a little splitter (in All Items and the categories
    always, as those show no empty slots; in One Bag and Each Bag with *Stack Splitter Everywhere*): how many
    (typed, - and +, the wheel), *Split* puts that many into the first free slot (Enter), *Auto Split* splits the
    whole stack into stacks of that many (Alt and Enter).
  - Every item is the game's own button: click or drag it, right click to use it (in a fight too), to sell it at
    a vendor or to put it into the bank, Shift-click to link it; the tooltip is the game's. The search box finds
    items by name, category or item level: One Bag and Each Bag fade what is not found, the others show only what
    is. At the foot your currencies and your gold (every character's in its tooltip). The game's own bags and bank
    stay as they are.
- **Your bank** (the window *Bank*): there while you are at a banker, in the bags' look: a sidebar with *All
  Bank Tabs* (each tab under its head, every slot), *One Bank* (the bank's slots together) and each tab by its
  name with how many of its slots are taken; on the bar *Deposit All Reagents*, the game's *Clean Up Bank* and the
  dropdown *View* (*Grid* or *Compact*, *Group by Category* to see the bank's items by the bags' categories, *Sort
  By*). The items are the game's own: a right click puts one into your bags. Alt and a right click opens an item's
  menu, a middle click pins it, Shift and a click splits a stack (with *Stack Splitter Everywhere*). Your gold at
  the foot. Away from the banker the window is gone and the others share its room.
- **Your alts** (the window *Alts*): every character of the account down its left, you
  first, each in its class's colour with its gold, the gold of them all under them; the account's bank last
  where it holds something. A click shows that one's things as last seen: its bags, its bank (as it was when that
  character last had it open) and what it wears, on a paper doll slot by slot, with the game's tooltips; Shift or
  Ctrl and a click links an item or tries it on. The search box finds an item across them all, by its name or its
  number: each character says how many it has, and the window lists only what was found. A character's things are as Core last read
  them while it was logged in; its bank, while it had it open. In the bags' look: each item in its quality's
  border with its item level, each place under a head with how many items it holds. Beside the roster *Storage*:
  *All Places*, *Bags*, *Bank*, *Equipped*, then *All Categories* and each of the bags' categories with how many
  of that character's items it holds; a click shows only that place or category. The dropdown *View* on the head:
  *Grid*, *List* (in the bags' list columns) or *Compact*, and *Group by Category*.
- **Settings:** *Sane UI > Inventory*: the section *Expand window* (whether it fills the screen, its kind of
  motion, the background's opacity and texture), *Window corners*, and *Bags*: *Open With*, *Show Pinned Items*,
  *Pinned in One Bag and Each Bag*, *Show Recent Items*, *Recent in One Bag and Each Bag*, *Show Add Category*, *Merge Stacks*, *Junk Marker* (off: no Junk, grey items stay in their
  categories), *Stack Splitter Everywhere*, *Show Item Level*, *Quality Borders*, *Show BoE*, *Show Set Name*, *Coin
  on Junk*, *Grey Junk*. The dropdown *View* switches some of them too.

## Technical details
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked at `BOTTOMRIGHT` at first,
  `Window.WIDTH` x `Window.HEIGHT`, not sizable, see-through and empty while small (no mouse); in Edit Mode its
  box. Docked in a corner, Core gives it the corner's square (`Edge.lua`, `Edge.CORNER` screen pixels, the
  strata `DIALOG`): its push fills the screen. `docked` lays the board out once the full window stands,
  `filled` takes it away as soon as the window starts back; the search box goes to every part.
- **The board** (`Board.lua`): Core's (`Core.Board`), the module's windows in the order `Board.ORDER`
  (`character`, `stats`, `reputation`, `skills`, `pvp`, `currency`, `statistics`, `bags`, `bank`, `alts`). Each window is a part in files of its own, listed after `Board.lua` in the TOC,
  that registers itself: `Board.Part(key, title, least, part)`, `part.Build(panel)`, `part.Show(on)`,
  `part.Size(width, height)`, `part.Search(text)`; each step runs `ns.Safe`, so a part that fails is noted and
  the others go on. The first layout puts the parts of `Board.FIRST` (the character, the stats, the bags, the other
  characters) side by side, each as wide as its least width, the last taking the rest; the others come from the
  dropdown *Windows*; later the layout is the player's (kept in the module's store, `board`). Each window's icon
  (`Board.ICONS`: a texture, or a function that draws it: the portrait, the PvP icon of your faction) gives it a
  tab of its own in the title bar (Core's board, `spec.icon`).
- **The character sheet** (`Sheet/`): the game's Camelot character window rebuilt from Blizzard's code
  (`CharacterFrame.xml`, `PaperDollFrame.xml`, `PaperDollFrame.lua`, `ReputationFrame`, `SkillsFrame`, `PVPRankFrame`,
  `TokenFrame`, `StatisticsFrame`), its parts windows of their own on the board (Saneroki, 2026-10-20), each moved
  and sized there; what is in a window follows its size.
  - **The character** (`Sheet/Sheet.lua`, the part `character`): the game's left pane (`Sheet.WIDTH` 398 by
    `Sheet.HEIGHT` 464, on `UI-Character-Info-General-BG`), its top strip (the game's rock and edge) with the level
    line (`PaperDollFrame_SetLevel`: the effective level, the specialization where the game has one, the class in its
    colour), the model and the slots; scaled to fit its window's body and never larger than the game's
    (`Sheet.Size`), the board's least `Sheet.LEAST` of it. The panel's head is `UnitPVPName`. `Sheet.LEFT` is its width
    too (the other characters' paper doll reads it).
  - **Slots** (`Sheet/Slots.lua`): the game's `ItemButton` on its slot frame (`UI-Character-Info-GearSlot`), in
    its places (`Slots.TOP`, `LEFT`, `RIGHT`, `BOTTOM`, `SIZE`, `GAP`); the ranged slot only where
    `C_PaperDollInfo.IsRangedSlotShown`, the ammo slot (`…GearSlotSmall`) and the weapons moved left while
    `UnitUsesAmmo`. Drawn as `PaperDollItemSlotButton_Update` draws (the game's `SetItemButton…` functions:
    icon, count, quality, red while broken or unusable, grey while locked; empty, `GetInventorySlotInfo`'s picture).
    Clicks: `PickupInventoryItem` (left click, drag, drop), `HandleModifiedItemClick` (a modified click); a right
    click calls nothing (`UseInventoryItem` is the game's own). Tooltip: `GameTooltip:SetInventoryItem`.
  - **Model** (`Sheet/Model.lua`): a `ModelScene` of the game's `PanningModelSceneMixinTemplate` set up by
    `ModelSceneUtil.SetUpCharacterSheetScene` when shown and at `UNIT_MODEL_CHANGED`, the game's turn and zoom
    buttons (`ModelSceneControlFrameTemplate`), the race's background in four parts (`DressUpTexturePath`, greyed)
    under `UI-Character-Info-RaceBG-Overlay`; an item let go over it: `AutoEquipCursorItem`.
  - **The stats and the sidebar** (`Sheet/Sidebar.lua`, the part `stats`): the game's right pane as a window, at the
    game's width (`Sidebar.WIDTH`) and the window's height, in its middle: the game's stat background stretched, its
    stone at the top, and on it the game's sidebar tabs as our own buttons in its art (42 square,
    `UI-Character-Info-StatTab`, checked `…-StatTab-Selected`; the game's own tabs show its sheet's panes): Stats with
    the portrait, Equipment Manager and Titles (`PaperDollSidebarTabs`' icons and coordinates), Pet (`paw-icon`), shown
    only with `HasPetUI`, the three centred without it as `PaperDollFrame_UpdateSidebarTabLayout` does; a tab the
    game has nothing for greyed (half seen, desaturated) with its reason in the tooltip. The tab chosen shows its
    pane under the stone and names the window's head; only it listens to the game. `UNIT_PET` lays the tabs out
    anew (the pet's tab without a pet goes back to the stats).
  - **Gear sets** (`Sheet/Gear.lua`): `C_EquipmentSet`'s sets by name in the game's cards (`UI-Character-Info-OutfitCard`
    and its hover and selected art, the icon in `…-OutfitIcon-Frame`, `…-Icon-Tick` on the set worn, the name red with
    an item lost); the game's Equip and Save (`SharedButtonSmallTemplate`) and New Set (`PaperDollTertiaryButtonTemplate`
    with `UI-Character-Info-Icon-Add`). Equip as `EquipmentManager_EquipSet` (not with locked items or while casting:
    the game's error), Save after `Core.Confirm`, New Set's name by `Core.AskText` (the icon the game's question mark:
    the game's icon picker is a frame of its own we do not show), a right click's menu to rename or delete. Drawn anew
    after `EQUIPMENT_SETS_CHANGED`, `EQUIPMENT_SWAP_FINISHED`, `PLAYER_EQUIPMENT_CHANGED`.
  - **Titles** (`Sheet/Titles.lua`): None, then the titles you know by name, in the game's rows (the stripe, the tick
    and bar on the one worn, the blue light); a click `SetCurrentTitle`. Drawn anew after `KNOWN_TITLES_UPDATE` and the
    player's `UNIT_NAME_UPDATE`.
  - **Stats** (`Sheet/Stats.lua`): for the player and for the pet, the game's `CharacterStatsPaneScrollBoxTemplate`
    under the stone, its rows the
    game's element templates (a category's head, a stat, a stat with an icon) filled by the game's `Init`, which
    calls the game's function for that stat (`PAPERDOLL_STATINFO`). The list is put together by our code as
    `CharacterStatsPaneScrollBoxMixin:UpdateStats` does (the player's categories of `PAPERDOLL_STATCATEGORIES`,
    `primary`, `roles`, `showFunc`, the unit's categories, a stat left out at its `hideAt`, a scratch row of ours for
    the values; then the
    resistances, `Stats.RESISTANCES`, with `UnitResistance` and the game's tooltip and bonus formatting): the game's
    list builder borrows the game's own sheet's frame pool, which our code must not touch. Under a restriction
    (`Core.Restricted`) the stats are secret to addon code (`SecretWhenUnitStatsRestricted`; the player's health
    always is), so the list is not drawn then: it waits (`Stats.Owed`) and is drawn after `PLAYER_REGEN_ENABLED` or
    `ADDON_RESTRICTION_STATE_CHANGED`. Drawn when shown and a frame after the game's stat events (`Core.Later`).
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
    button; an entry with the game's `ColoredProgressBarTemplate`), the game's heights (`Rows.HEADER`, `SUBHEADER`,
    `ENTRY`), the game's light (`charactercreate-customize-dropdown-linemouseover-…`), an indent; every part made once,
    its scripts calling the tab's (`owner`), `ns.Safe`.
  - **Reputation** (`Sheet/Reputation.lua`): the factions of `C_Reputation` on those rows, its coloured bar
    (`ColoredProgressBarTemplate`: the standing's word and colour, `FACTION_BAR_COLORS`, friendships green, renown
    blue; the progress under the mouse), its light (`Reputation.LIT`, `WAR`: brighter chosen or under the mouse,
    red at war). The choice is the game's (`C_Reputation.SetSelectedFaction`), the first faction chosen when none
    is. The side: name, standing, description, bar, the account-wide line, and the switches
    (`ToggleFactionAtWar`, `SetFactionActive`, `SetWatchedFactionByIndex`, the game's tooltips and sounds). The
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
    frame after `SKILL_LINES_CHANGED`, while shown.
  - **PvP** (`Sheet/PvP.lua`): the season's rank as the game keeps it, the renown of its PvP rank faction
    (`C_MajorFactions`, `PvP.FACTION` 2800): the season (`GetCurrentArenaSeason`), the rank's number and title (the
    game's `PVP_RANK_<n>_<faction>` in the character's gender, `Enum.PvPRanks`), the game's ring (a paused
    `Cooldown` with its swipe, `CooldownFrame_SetDisplayAsPercentage`; glow, faction background, honour bar, the
    rank's badge `UI-Character-Info-Honor-Icon-<n>`, the rank on a reward ring at its foot), the points, the time
    left of the season (`C_SeasonInfo`, the game's seconds formatter) counted down by a ticker that runs only while
    the tab shows. The side: title and number, the season's description, progress, this week's raised cap, the next
    rank with a reward (`GetRenownRewardsForLevel`, icon rows `Side.Icon`) and the rewards' vendor.
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
    `UPDATE_INVENTORY_DURABILITY`, `UPDATE_INVENTORY_ALERTS`, `UNIT_INVENTORY_CHANGED` and `UNIT_MODEL_CHANGED`
    (the player's), `PLAYER_LEVEL_UP`, `UNIT_NAME_UPDATE`, `PLAYER_ENTERING_WORLD`. Every value read goes through
    `Core.Plain` or `Core.Ask`; every function of the game's is called only if this client has it.
- **The other characters** (`Alts/`, the part `alts`): what the account's characters have, read only from Core's
  data framework (`Core.Data.Characters`, `Character`, `Items`, `Worn`, `OnCharacters`; `Doc/guides/data.md`,
  *Characters*): nothing is gathered or kept here.
  - **What is shown** (`Alts/Snapshot.lua`, no frames): the roster (`Snapshot.Characters`: the one logged in
    first, the others by name, the account's bank last where it holds something), a character's places in the
    order `bags`, `bank`, `worn` with their items in the order Core keeps them (by item ID; Core keeps no bag's
    slots, so no empty ones), what is worn also slot by slot where Core keeps it (`Data.Worn`), the gold of them
    all. The search: a number typed is an item's ID; words are found in the item's name whole, as a piece or as
    first letters (`Core.Fuzzy.Rank` from `Fuzzy.INSIDE` up; letters spread through a name are too loose a fit). A name the game does not know yet is asked for once
    (`C_Item.RequestLoadItemDataByID`); its answer draws the window anew (`Snapshot.Learned`).
  - **The roster** (`Alts/Roster.lua`): the game's `WowScrollBoxList` and `MinimalScrollBar`, a line per character
    (`GetClassAtlas`, `RAID_CLASS_COLORS`, whole gold by `Core.Coins`), the chosen one lit and the line under the
    mouse as the game's options list lights its lines (`Options_List_Active`, `Options_List_Hover`); its tooltip
    the level and class, realm, the day last seen, the gold to the copper. While searching, how many each has of
    what is found (stacks counted whole), one without any dimmed (`Roster.DIM`).
  - **The items** (`Alts/Items.lua`): one scrolling list: a head per place in the bags' style (the bank's with the
    day it was last seen, or *Not seen yet*; the number of items), a bag or bank place as the display says: rows of
    the game's item buttons in the bags' flat look (`ItemButton`, drawn by the game's `SetItemButtonTexture`,
    `Count`, `Quality`, its border hidden for ours in the quality's colour, the item level of gear; as many to a
    row as fit, `Items.Fit`), with Group by Category a head per category (the bags' order and names); lines in the
    bags' list columns (`Columns.Place`, `Value`, `Sort`); or one compact piece (`Layout.Lay` *compact* over the
    categories). An item's record as the bags' (`Items.Record`: `C_Item.GetItemInfoInstant`, `GetItemInfo`,
    `GetDetailedItemLevelInfo`, `Categories.Classify`; kept once the game knows the item). What is worn as the
    paper doll (below), or as a list (icon, name in its quality's colour) for a character Core has not read slot
    by slot yet (it has not logged in since). Read only: the tooltip is `GameTooltip:SetItemByID`, a modified
    click `HandleModifiedItemClick`; nothing picks an item up. `Items.Counts`: each category's count for Storage.
  - **The paper doll** (`Alts/Items.lua`, one element of the list): the slots as the sheet has them
    (`Slots.COLUMNS`, `Slots.SIZE`, `GAP`, `AMMO`, `AMMO_GAP`, the game's slot frames
    `UI-Character-Info-GearSlot` and `...Small`; IDs and empty pictures from `GetInventorySlotInfo`), eight down
    each side as far apart as the grid is wide, at most as on the sheet (`Items.DOLL`), the weapons' row in the
    middle below them; the ranged slot where the game shows one (`C_PaperDollInfo.IsRangedSlotShown`) or something
    is in it, the ammo beside it where some is worn. An empty slot shows its own picture, its tooltip its name.
    The bags worn in their slots follow as a row of the grid, in their slots' order. While searching the doll is
    shown only if something in it is found, whole, what is not found dimmed (`SetMatchesSearch`, as the game's
    bags dim it); of the bags only what is found.
  - **The window** (`Alts/Alts.lua`): the roster at the left, Storage beside it (`ns.Sidebars.New`: places and
    categories, the choice held while the window lives), the chosen character's head (name, gold, the level line as
    the sheet writes it, the day last seen, the dropdown *View*) and items at the right. Kept in `store.alts`:
    `look`, `group`; the bags' store read for the categories and columns (`Bags.Store`). Shown at first: the first of the
    others; the choice holds until a `/reload`. While searching, if the chosen one has none of it, the first that
    has is shown until the search is cleared. Listens only while shown: `Core.Data.OnCharacters`,
    `GET_ITEM_INFO_RECEIVED`, `ITEM_DATA_LOAD_RESULT`, drawn a frame later (`Core.Later`); drawn anew when shown.
- **The bags** (`Bags/`, the parts `bags` and `bank`): the backpack, the bags, the reagent bag and the keyring
  (`Contents.Carried`: those with slots) in the window *Bags*; while the bank is open (`BANKFRAME_OPENED`, at the
  login `C_PlayerInteractionManager.IsInteractingWithNpcOfType`: `Bank.Start`, `Contents.bankOpen`) the tabs of
  each bank the game lets the player see (`Contents.Banks`: `C_Bank.FetchPurchasedBankTabIDs` of
  `Enum.BankType.Character`, then `.Account`) in the window *Bank*. The game's bag and bank windows are never
  opened, closed or touched.
  - **What they hold** (`Bags/Contents.lua`, no frames): a record per slot, made once and filled anew at each
    reading (`Contents.Read`: `C_Container.GetContainerItemInfo`, `GetContainerItemQuestInfo`,
    `C_NewItems.IsNewItem`, the class from `C_Item.GetItemInfoInstant`, the bind type, price, level needed and
    the class's and subclass's words from `C_Item.GetItemInfo`, the item level of gear from
    `GetDetailedItemLevelInfo`; an item the game does not know yet waits for `GET_ITEM_INFO_RECEIVED`,
    `Contents.waiting`). Whether the character can use it: a line of its tooltip in the game's red
    (`C_TooltipInfo.GetBagItem`; a recipe: `C_Item.IsUsableItem`), kept per link until `PLAYER_LEVEL_UP`. The
    equipment set a slot is in (`Contents.Sets`: `C_EquipmentSet.GetItemLocations`, the game's
    `EquipmentManager_GetLocationData`; the first set wins). The bag it is in: the reagent bag (`reagentBag`) or a
    bag for one kind of item (`special`: the game's bag family, the keyring). The free slots by kind of bag
    (`Contents.Scan`, `Kind`). Orders (`Contents.ORDERS`): *Default* (gear by item level, then the subclass's
    words, quality, name, item ID), quality, name, item level, at last bag and slot. The search
    (`Contents.Found`): `Core.Fuzzy.Match` over the name, the category's name and the item level. Junk to sell
    (`Contents.Junk`): in Junk with a price, not in a special bag, not in an equipment set, not pinned, not
    refundable (`GetContainerItemPurchaseInfo`).
  - **The categories** (`Bags/Categories.lua`, no frames): the built-in ones (`Categories.LIST`: their rules,
    icons from the game's own classic icons and atlases, `fixed`, `last`, `alone`, the first groups), the
    player's own (`own1`, `own2`, …), the order (`Categories.Order`: Pinned and Recent first, the movable ones in
    the player's order, a new built-in one before Miscellaneous, a late one at the end, Junk last while the junk
    marker is on), the groups (`GroupOf`, `Members`, `GroupWord`: its own name, its first name, else its members'
    "A & B"; a group of one is none), an item's category (`Categories.Classify`: the reagent bag's, a special
    bag's, the player's, Camp Items by the game's item IDs, Quest Items, Junk for grey, Item Set Gear, then by
    class in order, else Miscellaneous; a category switched off sends its items to Miscellaneous). Kept by item
    ID in `store.bags` (account-wide, the player's own settings, never shared): `assigned`, `before` (where a
    junk-marked item was), `pinned`, `own`, `order`, `words`, `member`, `groups`, `off`, `hidden`; checked when
    read (`Categories.Check`).
  - **What came in lately** (`Bags/Recent.lua`, no frames): from the login on, a frame after a burst of bag
    events, every item's count in the carried bags and on the character (`GetInventoryItemID`); one that went up
    goes to the front of `Recent.list` (at most `Recent.MOST`, until a `/reload`). Not counted while the bank is
    open; `Recent.SETTLE` seconds after it closes, counted anew without anything new.
  - **The views** (`Bags/Views.lua`, no frames: `Views.Build`): the sidebar's choice as blocks: *all* (Pinned,
    Recent, then a block per category in order, a group's members as one, hidden and empty ones left out but the
    player's own), *one* (Pinned, *Main Bags* with every slot of the ordinary bags, then each special bag and the
    reagent bag), *each* (every bag), `cat:<key>`, `group:<group>` (its members each a block). Stacks of an item
    that is no gear merge into one entry with their counts added (`Views.Merging`: not while talking to a vendor,
    a banker, the mailbox, a trade partner, nor while the auction house is open); a split item stays apart while the window is open
    (`Views.split`). What the search does not find is left out, or faded in *one* and *each*. `Views.Counts`: how
    many cells each category and group shows, for the sidebar.
  - **The displays** (`Bags/Layout.lua`, plain numbers: `Layout.Lay`): *grid* (a head per block, its cells
    `Layout.SIZE` 34 and `GAP` 4 apart, the "+", the last line filled with pads; the player's own empty category a
    line of pads to drop items on), *list* (a line `Layout.ROW` high per cell, a folded block its head only),
    *compact* (the blocks side by side in bands, a name over each: which blocks share a band and how many lines it
    takes planned by dynamic programming for the least height, `Plan`; a block that is not the last of its band at
    least three wide; on a tie the fuller band first). The display and the order are kept (`store.bags`: `look`,
    `order`).
  - **The splitter** (`Bags/Split.lua`): a dialog of ours in the flat look, opened by `Bags.Clicked` after the
    template's own Shift-click (the game's `StackSplitFrame` hidden when it opened); `C_Container.SplitContainerItem`
    then `PickupContainerItem` into the first free slot of the ordinary bags; *Auto Split* one split after the
    other, each once the source slot is unlocked again (looked at every `Split.WAIT` seconds, at most
    `Split.LONGEST`); the item split goes into `Views.split`.
  - **The settings** (`Inventory.lua`'s `OPTIONS`, the section *Bags*, Core's options): `first`, `showPinned`,
    `pinnedOne`, `showRecent`, `recentOne`, `addCategory`, `merge`, `marker`, `splitter`, `itemLevel`,
    `borders`, `bind`, `setName`, `coin`, `grey`; read by the views, the sidebar, the categories (`Categories.Marker`)
    and the cells; changed from the dropdown and menus by `Core.Set`; a change draws the bags anew
    (`Bags.Settled`). What the window keeps of itself (the display, the order, the columns, the strip, the folded
    blocks) and the categories' choices stay in `store.bags`.
  - **The list's columns** (`Bags/Columns.lua`): `Columns.LIST` (icon, name, level, required, kind, bind, count,
    sell), the ones shown in order (`columns`), widths (`widths`), the sort (`listSort`, `listDown`), round icons
    (`round`), all kept in `store.bags`. `Columns.Place` gives each its place in a line (the name the room left,
    the others narrower together where the name would keep less than `Columns.NAME_LEAST`), `Columns.Value` what
    it shows, `Columns.Sort` a block's entries by it. The head (`Columns.Build`, `Refresh`): a click sorts, a drag
    past `Columns.DRAG` moves the column where its neighbour's middle is crossed, a grip at its right edge sizes it
    (at least `Columns.LEAST`), a right click its menu (the game's). Folded blocks are kept in `folded`.
  - **The item buttons** (`Bags/Cells.lua`): a pool per window (`Cells.New(parent, owner)`; the bags' is `Cells.bags`,
    and Cells' own functions are its; the owner's `Hover` and `Clicked` answer its buttons; `Cells.Record` a button's
    record whatever its pool): the game's `ContainerFrameItemButtonTemplate`, taken in the
    order of the cells drawn (`Cells.Take`), each in a holder of ours that carries the bag's ID (`SetID`): the
    template's `GetBagID` asks its parent, so nothing of ours is written into the button and its click (use,
    drag, split, sell, deposit) is the template's own code, in a fight too. Made out of a fight only
    (`Cells.short`, `Core.AfterCombat`). The flat look set on the template's own parts once (the icon cut
    `Cells.ZOOM` round its edge and to the button's size, its mask, border, normal texture and new item's glow
    away, the highlight to the button's size, a warm glow pressed), ours beside them in a table of our own: a thin
    border of the screen's own pixels in the quality's colour (`Cells.QUEST`, twice as thick, on a quest item),
    above the cooldown's swipe the count, the item level, BoE, the set's name, the game's `QuestNormal` on an item
    that starts a quest, the junk coin; an empty slot a dark square; a pad (`Cells.Pad`) one that takes no mouse.
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
  - **The "+" cells** (`Views.lua`'s `block.plus`, `Layout.lua`'s `plus` places, `Bags.lua`'s `DrawPlus`): after
    Pinned (shown when empty too) and every category that takes items (`Categories.Takes`), in the grid; an item
    on the cursor clicked or dragged there `Menus.Drop`, else `Select.Start`.
  - **The sidebar** (`Bags/Sidebar.lua`): `ns.Sidebars.New(body, top, bottom, options)` a window's (rows of the
    game's look at Sane UI's size, `Sidebars.WIDTH` wide, the names always shown (one cut short whole in its
    tooltip), the view shown with a bar of `Core.GOLD` at its left; scrolled by the wheel; `Begin`, `Row`,
    `Divider`, `Done`; its `choose`, `drop`, `menu`, `add` answer the clicks); `ns.BagSidebar` the bags' (every
    category switched on, empty ones too; a click `Bags.Choose`, an item on the cursor let go there `Menus.Drop`, a
    right click `Menus.Row`).
  - **The drawing** (`Bags/Canvas.lua`): `ns.Canvas.New(child, owner)` a window's: the heads (a right click
    `Menus.Row`, an item let go `Menus.Drop`, in the list a click folds: `folded` in the owner's store), the compact
    display's labels, the "+" cells, the list's lines, the pads and the item buttons (the owner's pool), drawn as
    `Layout.Lay` places them (`canvas:Draw`). `Views.Build` takes a window's own store of blocks.
  - **The bank's window** (`Bags/Bank.lua`, the part `bank`, `Present` while `Contents.bankOpen`; the board leaves
    it out while away and the first layout too: `Board.lua`'s `spec.present`, `Window.Reboard` at the banker's
    events): its sections read as the bags' (`Contents.Scan` per bank), a sidebar (All Bank Tabs, One Bank, each tab
    by `Contents.BagWord`, its slots taken), the views (`Views.Build` *each*, *one*, a tab's own section; with
    `group` the bags' *all* without Pinned, Recent and "+"), a canvas and a pool of its own, the bar (the count, the
    reagents' deposit: `Foot.Deposits`, `C_Bank.AutoDepositItemsIntoBank`; the clean-up of the bank shown:
    `C_Container.SortBank`; the dropdown *View*), the gold at its foot. Kept in `store.bank`: `look`, `order`,
    `group`, `folded`. Listens while shown (bags, bank slots and tabs, locks, cooldowns, money).
  - **The window** (`Bags/Bags.lua`): the bar (`Bags.BAR`), the strip of the bags (kept: `strip`), the sidebar,
    the scroll area, the foot; the heads (a part's, a block's, a group member's) taking items and opening menus,
    the compact display's labels, the list's lines; the dropdown *View* (`WowStyle1DropdownTemplate`) with the
    displays, the orders and the switches (`showPinned`, `showRecent`, `merge`, `first`, the
    categories switched off). The view chosen holds while the window is open (`Bags.Choose`); it opens with
    `first`.
  - **The menus** (`Bags/Menus.lua`): the game's (`MenuUtil.CreateContextMenu`) for an item and for a category or
    group; names asked in the game's dialogs (`Core.AskText`, `Categories.LETTERS`), a category deleted after
    `Core.Confirm`. Each choice is kept at once and the window read and drawn anew (`Bags.Refresh`).
  - **The foot** (`Bags/Foot.lua`): the currencies watched (`GetBackpackCurrencyInfo`, `SetBackpackToken`), the
    gold (`Core.Coins`; its tooltip every character's from `Core.Data.Characters` and the total); the strip of
    the bags (the game's `ItemButton` with its bag icons in a border of the bag's quality, its free slots on it;
    the game's tooltip for a bag, *Equip Container* for an empty slot; `PickupBagFromSlot`, `PutItemInBag`,
    `PutItemInBackpack`, `PutKeyInKeyRing`, out of a fight); the bar's button for what can be done here (selling
    the junk after the game's `SELL_ALL_JUNK_ITEMS_POPUP` in `Core.Confirm`: the bags read anew, then
    `C_MerchantFrame.SellAllJunkItems` where the junk is just the game's, else `C_Container.UseContainerItem` on
    each, one every `Foot.STEP` seconds while the vendor is there, out of a fight and with the cursor empty, the
    item checked to be still in its slot; `Core.Print` says how many were sold for how much and how many could
    not be; `C_Bank.AutoDepositItemsIntoBank` where `DoesBankTypeSupportAutoDeposit`).
  - **Events, while shown only** (`Bags.Show`): `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`,
    `BAG_CONTAINER_UPDATE`, the quest events, the vendor's, mailbox's, trade's and auction house's opening and
    closing, `EQUIPMENT_SETS_CHANGED`, `BANKFRAME_OPENED`/`CLOSED` and the bank's slot and tab events: everything
    read and drawn a frame later (`Core.Later`); `ITEM_LOCK_CHANGED` greys one slot; `PLAYER_LEVEL_UP` asks
    anew who can use what; `BAG_UPDATE_COOLDOWN`, `PLAYER_MONEY`, `CURRENCY_DISPLAY_UPDATE` their own part.
- **Never the game's panels** (2026-10-20, from the error log): our code neither opens nor closes the game's
  character sheet or any other panel of its window manager (`UIParentPanelManager.lua`). Opened by our code,
  the manager ran tainted and the sheet's `OnShow` failed on the player frame's secret health
  (`ShowStatusBarText`, `TextStatusBar.lua`); the manager's slots, written by our call, made the game's own
  close button fail too until a `/reload` (`Doc/guides/addon-standards.md`, *Known traps*). Hence our own
  windows.
- **Standing down** (`ns.GiveBack`): the board's windows go and the window with them. A `/reload` starts the
  module afresh.
- Tests: `dev/tests/inventory.lua` (the window, the board, the paper doll, the stats, the other characters' window
  and an alt's paper doll), `dev/tests/sheet.lua` (the sheet's windows on the board, the sidebar with its gear sets and titles, the game's tabs as windows), `dev/tests/bags.lua` (the bags).

## Files

| File | What it holds |
|---|---|
| `SaneUI_Inventory.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Inventory.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings (Core's *Expand window* and *Window corners*), `GiveBack`, the start |
| `Window.lua` | Its window: docked in the bottom right corner, filling the screen from that corner |
| `Board.lua` | The full screen's windows on Core's board; the parts register theirs |
| `Sheet/Slots.lua` | The character sheet's equipment slots |
| `Sheet/Model.lua` | The character sheet's model, its background and buttons |
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
| `Sheet/Skills.lua` | The skills window |
| `Sheet/PvP.lua` | The PvP window: the season's rank |
| `Sheet/Currency.lua` | The currency window |
| `Sheet/Statistics.lua` | The statistics window |
| `Bags/Contents.lua` | The bags, without frames: the containers, a record per slot (bind type, price, who can use it, the set it is in), free slots, orders, the search, the junk to sell |
| `Bags/Categories.lua` | The bags' categories, without frames: the built-in ones and their rules, the player's own, their order, names and groups; pins, items put into a category, junk marks |
| `Bags/Recent.lua` | What came into the bags lately, without frames: counted from the login on |
| `Bags/Views.lua` | What each view of the sidebar shows, without frames: blocks of cells, stacks merged, the search |
| `Bags/Layout.lua` | The bags' displays (grid, list, compact): where each cell, pad, line, head and label goes, as plain numbers |
| `Bags/Cells.lua` | The bags' item buttons: the game's own, a pool, in the flat look, drawn the game's way |
| `Bags/Foot.lua` | The bags' foot: currencies, gold; the strip of the bags; selling junk or depositing reagents |
| `Bags/Menus.lua` | The bags' menus for an item, a category and a group, items let go over a category, new categories |
| `Bags/Split.lua` | The bags' stack splitter: split into the first free slot, or the whole stack by turns |
| `Bags/Columns.lua` | The bags' list columns: their values, sorting, widths, the head over the list and its menu |
| `Bags/Select.lua` | The bags' choosing by clicks: an item into a category after its "+", junk marked by the coin |
| `Bags/Sidebar.lua` | The bags' sidebar: the views, Pinned, Recent, the categories and groups with their counts |
| `Bags/Canvas.lua` | A window's drawing of its items: heads, labels, "+", the list's lines, pads, the item buttons |
| `Bags/Bags.lua` | The bags' window: the bar, the strip, the scroll area, heads, labels and lines, the dropdown *View*, the events; registers the part `bags` |
| `Bags/Bank.lua` | The bank's window while at a banker: its tabs, sidebar, views, bar and foot; registers the part `bank` |
| `Alts/Snapshot.lua` | The other characters' window, without frames: the roster, a character's places and items, the search |
| `Alts/Roster.lua` | The other characters' window: the account's characters down its left, their gold |
| `Alts/Items.lua` | The other characters' window: the chosen one's places and items: a grid, the paper doll, a list |
| `Alts/Alts.lua` | The other characters' window: whose things, the search, the events; registers the part `alts` |

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
