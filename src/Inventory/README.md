# Sane UI: Inventory

**Status:** its window and full screen built; the character sheet built, its parts windows of their own (the paper doll; the stats with the game's sidebar: gear sets, titles, the pet; reputation, skills, PvP, currency, statistics); the bags built; the other characters' window built · **Since:** 2026-10-20 · **Addon:** `SaneUI_Inventory` · **Game:** WoW: Forever (interface 16001)

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
- **Arranging the windows:** as on every Sane UI full screen (Core's board): drag a window's head to move it,
  the gap between two to share their room anew, its X to take it off; the dropdown *Windows* adds one; layouts
  behind tabs in the title bar.
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
- **Your bags** (the window *Bags*): everything you carry, and the bank too while you are at a banker. The
  dropdown *View* on its head chooses how they show: *All* (every slot in your bags' order, the empty ones too; a
  quiver, the reagent bag and the keyring each a part of its own), *Categories* (your items in the game's groups:
  new ones first, then weapons, armor, containers, consumables, trade goods, ammo, recipes, quest items and the
  rest, the junk last; then a cell for each kind of bag's free slots, with how many), *List* (the same as lines:
  name, item level, count) or *Compact* (smaller, without heads); and what sorts them inside a group (quality,
  name or item level). Every item is the game's own button: click or drag it, right click to use it (in a fight
  too), to sell it at a vendor or to put it into the bank, Shift-click to link it; the tooltip is the game's.
  The button left of *View* is the game's *Clean Up Bags*; at the bank each of its parts has its own. The search
  box finds items by name, category or item level: *All* dims what is not found, the other views show only what
  is. A new item stays under *New* while the window is open. At a vendor with junk the head also has *Sell All
  Junk Items*, at a banker *Deposit All Reagents*. At the foot: your bags (point at one to light its items; drop a
  bag on a slot to put it on, click one to pick it up), the free slots (every bag's in the tooltip), the
  currencies you watch and your gold (every character's in its tooltip). The game's own bags and bank stay as
  they are.
- **Your other characters** (the window *Characters*): every character of the account down its left, you
  first, each in its class's colour with its gold, the gold of them all under them; the account's bank last
  where it holds something. A click shows that one's things as last seen: its bags, its bank (as it was when that
  character last had it open) and what it wears, on a paper doll slot by slot, with the game's tooltips; Shift or
  Ctrl and a click links an item or tries it on. The search box finds an item across them all, by its name or its
  number: each character says how many it has, and the window lists only what was found. A character's things are as Core last read
  them while it was logged in; its bank, while it had it open.
- **Settings:** *Sane UI > Inventory*: the section *Expand window* (whether it fills the screen, its kind of
  motion, the background's opacity and texture) and *Window corners*.

## Technical details
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked at `BOTTOMRIGHT` at first,
  `Window.WIDTH` x `Window.HEIGHT`, not sizable, see-through and empty while small (no mouse); in Edit Mode its
  box. Docked in a corner, Core gives it the corner's square (`Edge.lua`, `Edge.CORNER` screen pixels, the
  strata `DIALOG`): its push fills the screen. `docked` lays the board out once the full window stands,
  `filled` takes it away as soon as the window starts back; the search box goes to every part.
- **The board** (`Board.lua`): Core's (`Core.Board`), the module's windows in the order `Board.ORDER`
  (`character`, `stats`, `reputation`, `skills`, `pvp`, `currency`, `statistics`, `bags`, `alts`). Each window is a part in files of its own, listed after `Board.lua` in the TOC,
  that registers itself: `Board.Part(key, title, least, part)`, `part.Build(panel)`, `part.Show(on)`,
  `part.Size(width, height)`, `part.Search(text)`; each step runs `ns.Safe`, so a part that fails is noted and
  the others go on. The first layout puts the parts of `Board.FIRST` (the character, the stats, the bags, the other
  characters) side by side, each as wide as its least width, the last taking the rest; the others come from the
  dropdown *Windows*; later the layout is the player's (kept in the module's store, `board`).
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
  - **The items** (`Alts/Items.lua`): one scrolling list: a head per place (the bank's with the day it was last
    seen, or *Not seen yet*), a bag or bank place as rows of the game's item buttons (`ItemButton`, drawn by the
    game's `SetItemButtonTexture`, `Count`, `Quality`; as many to a row as fit, `Items.Fit`), what is worn as the
    paper doll (below), or as a list (icon, name in its quality's colour) for a character Core has not read slot
    by slot yet (it has not logged in since). Read only: the tooltip is `GameTooltip:SetItemByID`, a modified
    click `HandleModifiedItemClick`; nothing picks an item up.
  - **The paper doll** (`Alts/Items.lua`, one element of the list): the slots as the sheet has them
    (`Slots.COLUMNS`, `Slots.SIZE`, `GAP`, `AMMO`, `AMMO_GAP`, the game's slot frames
    `UI-Character-Info-GearSlot` and `...Small`; IDs and empty pictures from `GetInventorySlotInfo`), eight down
    each side as far apart as the grid is wide, at most as on the sheet (`Items.DOLL`), the weapons' row in the
    middle below them; the ranged slot where the game shows one (`C_PaperDollInfo.IsRangedSlotShown`) or something
    is in it, the ammo beside it where some is worn. An empty slot shows its own picture, its tooltip its name.
    The bags worn in their slots follow as a row of the grid, in their slots' order. While searching the doll is
    shown only if something in it is found, whole, what is not found dimmed (`SetMatchesSearch`, as the game's
    bags dim it); of the bags only what is found.
  - **The window** (`Alts/Alts.lua`): the roster at the left, the chosen character's head (name, gold, the level
    line as the sheet writes it, the day last seen) and items at the right. Shown at first: the first of the
    others; the choice holds until a `/reload`. While searching, if the chosen one has none of it, the first that
    has is shown until the search is cleared. Listens only while shown: `Core.Data.OnCharacters`,
    `GET_ITEM_INFO_RECEIVED`, `ITEM_DATA_LOAD_RESULT`, drawn a frame later (`Core.Later`); drawn anew when shown.
- **The bags** (`Bags/`, the part `bags`): the backpack, the bags, the reagent bag and the keyring
  (`Contents.Carried`: those with slots), and while the bank is open (`BANKFRAME_OPENED`, at the start
  `C_PlayerInteractionManager.IsInteractingWithNpcOfType`) the tabs of each bank the game lets the player see
  (`Contents.Banks`: `C_Bank.FetchPurchasedBankTabIDs` of `Enum.BankType.Character`, then `.Account`), each
  under a head of its own after the bags. The game's bag and bank windows are never opened, closed or touched.
  - **What they hold** (`Bags/Contents.lua`, no frames): a record per slot, made once and filled anew at each
    reading (`Contents.Read`: `C_Container.GetContainerItemInfo`, `GetContainerItemQuestInfo`,
    `C_NewItems.IsNewItem`, the class from `C_Item.GetItemInfoInstant`, the item level of gear from
    `GetDetailedItemLevelInfo`; an item the game does not know yet waits for `GET_ITEM_INFO_RECEIVED`,
    `Contents.waiting`). Its group (`Contents.GROUPS`): new first, then the game's auction house categories in
    Camelot's order (`AUCTION_CATEGORY_*`, by item class: `Contents.CLASSES`), a quest's item by the game's quest
    info, junk (poor quality with a price) last. The free slots by kind of bag (`Contents.Scan`, `Kind`): the
    ordinary bags together; a reagent bag, the keyring and a bag for one kind of item (the game's bag family) each
    by itself; a bank's tabs by that bank. Orders (`Contents.ORDERS`): quality, name, item level, then bag and
    slot, so that an item keeps its place while only its count changes. The search (`Contents.Found`):
    `Core.Fuzzy.Match` over the name, the group's name and the item level.
  - **The views** (`Bags/Layout.lua`, plain numbers: `Layout.Lay`): *All* (`slots`: every slot in the bags'
    order at the game's size and spacing, `Layout.SIZE` 37 and `GAP` 5 as `ContainerFrame.lua`; a head per kind of
    bag where there are several; what the search does not find dimmed), *Categories* (`groups`: a head per group
    with how many, the items sorted; then *Empty*, a cell per kind of bag that has free slots: its first free
    slot's button, with how many), *List* (`list`: lines `Layout.ROW` high, the item button `Layout.ICON` at the
    left), *Compact* (`compact`: `Layout.SMALL` cells, no heads, the free cells last). Outside *All* what the search
    does not find is left out. The view and the order are kept (`store.bags`: `view`, `order`).
  - **The item buttons** (`Bags/Cells.lua`): the game's `ContainerFrameItemButtonTemplate`, one per slot, made
    when the slot is first shown (out of a fight: one first needed in a fight waits for its end,
    `Core.AfterCombat`), used again in every view (`SetScale`, `SetPoint`). They stand in a frame of ours per bag
    that carries the bag's ID (`SetID`): the template's `GetBagID` asks its parent, as the game's bag windows did,
    so nothing of ours is written into the button and its click (use, drag, split, sell, deposit) is the
    template's own code, in a fight too. Drawn as `ContainerFrameMixin:UpdateItems` draws (`ClearItemButtonOverlay`,
    `SetItemButtonTexture`, `Quality`, `Count`, `Desaturated`, the template's `UpdateQuestItem`, `UpdateNewItem`,
    `UpdateJunkItem`, `UpdateCooldown`, `SetMatchesSearch`, …); ours on it: the item level of gear at its top right
    in its quality's colour. In the list the button's hit rect reaches over its line (`SetHitRectInsets`), so
    the whole line is the item; a hook after its `OnEnter` lights the line. A bag of the foot's bar lights its
    items with the template's own mark (`BagIndicator`), as the game's combined bag does.
  - **The head** (`Bags/Bags.lua`): the game's clean-up button (`bags-button-autosort-up`, `UI_BAG_SORTING_01`,
    `C_Container.SortBags`; a bank part's head: `C_Container.SortBank` of that bank), not in a fight; the
    dropdown *View* (`WowStyle1DropdownTemplate`, its words fixed: views, then *Sort By*); left of the clean-up, one
    button for what can be done there (`C_MerchantFrame.SellAllJunkItems` after the game's
    `SELL_ALL_JUNK_ITEMS_POPUP` in `Core.Confirm`; `C_Bank.AutoDepositItemsIntoBank` where
    `DoesBankTypeSupportAutoDeposit`), made by the foot's file.
  - **The foot** (`Bags/Foot.lua`): the bag bar (the game's `ItemButton`, its bag icons, `ui-hud-actionbar-
    iconframe-bags`; the game's tooltip for a bag, *Equip Container* for an empty slot; `PickupBagFromSlot`,
    `PutItemInBag`, `PutItemInBackpack`, `PutKeyInKeyRing`, out of a fight), the ordinary bags' free slots (every
    bag's in the tooltip), the backpack's watched currencies (`GetBackpackCurrencyInfo`,
    `GameTooltip:SetBackpackToken`), the gold (`Core.Coins`; its tooltip every character's from
    `Core.Data.Characters` and the total).
  - **Events, while shown only** (`Bags.Show`): `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`,
    `BAG_CONTAINER_UPDATE`, the quest events, `MERCHANT_SHOW`/`CLOSED`, `BANKFRAME_OPENED`/`CLOSED` and the bank's
    slot and tab events: everything read and drawn a frame later (`Core.Later`); `ITEM_LOCK_CHANGED` greys one
    slot; `BAG_UPDATE_COOLDOWN`, `PLAYER_MONEY`, `CURRENCY_DISPLAY_UPDATE` their own part. New items stay in *New*
    while the window is open (`fresh`), whatever the game's mark says.
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
| `Bags/Contents.lua` | The bags, without frames: the containers, a record per slot, the groups, free slots, orders, the search |
| `Bags/Layout.lua` | The bags' views: where each cell, line and head goes, as plain numbers |
| `Bags/Cells.lua` | The bags' item buttons: the game's own, one per slot, drawn the game's way |
| `Bags/Foot.lua` | The bags' foot: the bag bar, free slots, selling junk or depositing reagents, currencies, gold |
| `Bags/Bags.lua` | The bags' window: the head, the scroll area, heads and lines, the events; registers the part `bags` |
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
  game's clean-up, the bag bar, junk and reagents, currencies and gold.
