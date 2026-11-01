# Sane UI: developer changelog

Every change, newest first. The short version for users is [changelog.txt](changelog.txt).

## 0.3.0 (2026-10-14)
Tests: lint, 399 checks (Core, with its options and profiles), 609 (Abilities), 496 (Tooltips), 626 (Social), 110 (Sync), 440 (windows), 269 (data in the game), 792 (Navigation), 150 (Inventory), 128 (sheet), 349 (bags), 124 and 10 in Retail (Combat), 43 (spellbook), 66 (talents), 247 (Nameplates), 190 (Loot), 180 and 162 (Speed Leveling, its guide), 83 (Lore), 111 (Guild), 159 (walking data), 24 (map data), 235 (data tools), 95 (Blizzard's code).
A game restart takes it in (new addons, Navigation, Atlas, Inventory, Nameplates, Guild, Speed Leveling, Loot and Lore; new files in Navigation's, Core's, Social's, Combat's, Inventory's, Nameplates', Speed Leveling's, Tooltips' and Abilities' TOCs, key bindings; Core's data sets, now Core's own files; the `SaneUI_Data_*` folders leave the game).

### Combat: rings around the mouse for the global cooldown and your cast (Saneroki, 2026-11-01)
Saneroki: the global cooldown and the cast bar around the mouse while they run, shifted "so it goes around the visible mouse cursor instead of the tip", no circle always there.
- **`src/Combat/MouseRings.lua`** (new): two `Cooldown` widgets on a holder that follows the mouse and is hidden at rest. The inner ring, silver, the global cooldown; the outer one the cast, gold, a channel in green and emptying. Centred `Rings.MIDDLE` of a side right of and below the tip of the cursor's square picture, every size in that side in real pixels, by the game's Cursor Size, on Default by the display's scale; the inner ring's hole holds all 119 of the game's cursor pictures of 32 pixels whole. Forever's tables have no global cooldown spell of their own (61304 is Retail's): 29515 there.
- **`src/Combat/Combat.lua`:** the section *Rings around the mouse* on the page Combat, *Global cooldown* and *Your cast*, both on at first; standing down hides them. **`src/Combat/Units/Cast.lua`:** `Cast.Read` for the rings.
- **`dev/tools/shape-art`, `src/Core/Shape.lua`:** `ring.blp`, `Shape.RING`, a thin white ring drawn by code. **`dev/tests/combat.lua`:** the rings' place, size, life and settings, hidden numbers.
- `src/Combat/README.md`, `src/Core/README.md`, `Doc/ideas/Combat.md`, `Doc/agent/README.md`, `Doc/guides/images.md`, `Doc/changelog.txt`.

### /patchday: a new game build taken the whole way (Saneroki, 2026-11-01)
Saneroki: "Can you make me a skill called /patchday": each new build of Forever and Retail taken in by one command, from its export to patch notes in Blizzard's layout, stored by build.
- **`dev/tools/patchday`** (new, `saneui patchday`): `check` which game has a new build and what its patch still lacks; `bump` the build into `builds.toml` and the data tools; `tables`, `world`, `draft`, `rerender`, `paint`, `page`, `store`; the page `/patchnotes/` on the tools' server. `Doc/guides/blizzard-updates.md`: *Patch day*.
- **`dev/blizzard/world.py`** (new): two builds' terrain as the game reads it: ground (with the base added, inside a chunk, from a yard: a chunk's base and outer ring baked anew are no move), holes, areas, water, minimap, placements (without their numbers), models, and the Map, AreaTable and UiMap tables; which walking data to make anew, which of the Atlas' squares and zones to paint again.
- **`dev/blizzard/clienttables.py`** (new): every client table against the build before, by topic, so what the master does not hold is seen too.
- **`dev/blizzard/patchnotes.py`** (new): the notes' form in Blizzard's layout, each point saying where it stands (Blizzard and client, client only, Blizzard only), as text, as a folding page in both themes and as the database's rows.
- **`assets/data/PatchNotes`** (new set, key the build); **`dev/data/schema.py`, `compile.py`:** a schema's `ship = false`: the master keeps the set, the game gets no file of it.
- **`dev/tests/patchday.py`** (new). `dev/saneui`, `dev/tools/web-pages`, `dev/tests/run`, `Doc/guides/data.md`, `Doc/agent/development.md`.

### Abilities: one character's Action Bar 7 follows its form (Saneroki, 2026-11-01)
Saneroki: "the Shift modifier (second) bar should change with forms", for the druid and not the warrior, as a setting per character.
- **`src/Abilities/FormBar.lua`** (new): a switch of the character (`ns.char.formBar`, the spellbook's menu, `/sane ab formbar on`), not of the profile the two share. As Bar 1 keeps its page, a state driver gives each of Bar 7's twelve buttons its own `actionpage`: the form's row in a form (`[bonusbar:1]` to `[bonusbar:4]`, pages 7 to 10), none out of one. Buttons and keys stay the game's, and it works in a fight. A druid has two rows, as Saneroki asked ("I only want a cat and a bear and a human / moonkin bar"): Cat Form's, which Prowl keeps (`FormBar.DRUID`), and Bear Form's; as a human or in Moonkin Form the bar is itself.
- **`Bar1.lua`:** `Bar1.Header` makes the driver's frame for either bar; `Bar1.Unseen` no longer counts a form's row as unseen while Bar 7 shows it, so the game's new spells stay there. `SlotLabel` names such a row as Bar 7's, and `LearnPageName` learns its name.
- **Tests:** `dev/tests/abilities.lua` (a wrong row caught when made).

### Quest log rechecked: a quest's item by a click and its tooltip; Shift and a click tracks again (Saneroki, 2026-11-01)
Saneroki asked to recheck the quest log, above all that a click on a quest's item uses it and that its tooltip shows as the tooltip settings say. The click was right: run through the game's own click code of both games (`SecureActionButton_OnClick`, `SecureCmdItemParse`), every mouse button with every modifier, in and out of a fight, the game's key-down option on and off, each used the item once. The settings were kept too, as the tooltip is filled like any other (`Show tooltips`, at first while Shift is held). What was found around it is below. A `/reload` takes it in.
- **`src/Navigation/QuestLog.lua`, the tooltip:** `GameTooltip:SetQuestLogSpecialItem`, as the game's tracker, by the quest's index in the log now, in place of `SetItemByID`, which showed the item as such: a quest's item bound to you stood as a red *BoP* in the tooltip's panel, without its charges and cooldown. `SetItemByID` stays for a quest gone from the log while a fight holds its button. The mouse on an item counts as the mouse on the log (`Hover`), and a tooltip open on a button that takes another row's item follows (`Seat`).
- **The click:** on the release (`AnyUp`, `useOnKeyDown` false), as the tracker, whatever the game's option says. With the chat's box open the link's modifier links the item and uses nothing (`Linking`, `PreClick`, `PostClick`): a Shift click used a quest's item up there. With the box closed Shift and a click uses it, so holding Shift for the tooltip costs nothing. In a fight the game locks what the button does: it links and uses.
- **The bags:** the game has no event for a quest's item that comes, goes or loses a charge (its tracker keeps looking). `BAG_UPDATE_DELAYED` compares `Special` with the rows and draws the list anew only then; before, the button and its count stayed until the log changed.
- **A quest's row:** Shift and a click tracks again: the link's modifier, Shift too, returned even where nothing took the link (`Clicked`).
- **Tests:** `dev/tests/navigation.lua` (each change caught when undone), `dev/tests/wowstub.lua` (`IsOwned`). **Lab:** the scene `questlog` has two quests with an item.

### Sync: every profile keeps Graphics, Audio and All other game settings (Saneroki, 2026-11-01)
Saneroki asked whether a `/reload` really saves everything to the profile in use. It did not: Speedleveling held neither
Graphics, Audio nor All other game settings. These three parts find their CVars in a job of Core's scheduler, which was
started only when a part had something to write. A profile that held nothing of them never started it before the logout,
and the logout's reading only started it, too late, every time.
- Each writing now gets such a part ready, whatever the profile holds (`Prepare`, `Sync.Give`); the job stays once a session.
- `dev/tests/sync.lua` holds it: without the fix the new check fails.

### Social: a tick for each of the game's channels; a refused leave not asked at every click (Saneroki, 2026-11-01)
Saneroki: a click on any channel's *Never in it*, *Always in it* or *The game decides* said "Unable to leave chat
channel Newcomer Chat"; each channel should have a plain tick instead of its flyout, ticked joined, unticked left.
- **The bug:** a click runs `Join.Settle`, which goes through every wish. Retail's standard profiles wish Newcomer Chat
  away, the game refuses that leave (`CHAT_MSG_CHANNEL_LEAVE_PREVENTED`) and writes its line at each try. `Join.lua`
  notes a refused channel (`kept`) and does not ask again until the next login or a click on its own tick; the wish stays.
- **The ticks:** the third column of `Menu.lua`'s list, now *Joined on every character*, has a check box per channel
  (`Join.In`, `Join.Flip`); the three choices and `TEXT.wishes` are gone. A wish counts at once, never ticked the tick
  is what the game says, a refused one stays on. `Menu.Refresh` shows an open list's ticks anew when the game answers.
  Tests: `dev/tests/social.lua`.

### Speed Leveling: the list is the whole guide, your step marked in its middle; a red cross (Saneroki, 2026-11-01)
Saneroki: highlight the current active steps clearly and scroll continuously from the first step to the last; on the first
scroll the list centered on the current step; about 10 steps at a time; left alone it goes back to the steps after 10 seconds,
and a red x in the top right corner takes it away by hand. A `/reload` takes it in.
- **`src/SpeedLeveling/Guide.lua`:** `Guide.Listed()` is every step the list shows and where you stand among them, `Guide.Line`
  one of them; the wheel goes a line at a time over that, where it stuck on the steps not listed before. `Guide.Picture` has
  no list of its own any more (`ahead`, `shift`, `Guide.AHEAD` gone).
- **`src/SpeedLeveling/Steps.lua`:** the list opens with your step in its middle; steps at hand on a gold band with a gold
  line at the left (`Steps.BAND`, `Steps.MARK`). The cross (`Steps.closer`, the game's ready-check cross) stands at the view's top
  right, how far you are moves left of it. `Steps.LINGER` is 10 seconds without the mouse on the view, a turn of the wheel or
  an open menu of a line.
- **Interface lab:** the scene `guide` has a guide of a hundred steps, you at the 35th.
- **Tests:** `dev/tests/speedguide.lua`, `speedleveling.lua`.
- **Docs:** `src/SpeedLeveling/README.md`, `Doc/guides/interface-style.md`, `Doc/ideas/Leveling.md`.

### Party and raid slots fill the window (Saneroki, 2026-10-31)
Saneroki: five slots fill the window's height whoever is there; a slot as wide as the max unit width, at first the unit frames' width; all slots share
the width evenly only where the columns would not fit. A `/reload` takes it in.
- **`src/Combat/Units/Group.lua`:** `Group.Size(columns, width, height, unit)`, no cap on the height, no rows by the group's size; `Group.HEIGHT` gone.
- **`src/Combat/Units/GroupFace.lua`:** the big icons and the mana line stop growing on tall slots (`Face.BIG_MOST`, `Face.LINE_MOST`).
- **`src/Combat/Combat.lua`:** `groupUnitWidth` 240 at first. **Tests:** `dev/tests/combat.lua`.

### Speed Leveling: the list on the wheel, in the place of the steps (Saneroki, 2026-10-31)
Saneroki: no scrollable list under the steps, to focus on them; the wheel over the steps makes them go and the list come up.
A `/reload` takes it in.
- **`src/SpeedLeveling/Steps.lua`:** only the steps at hand show. The first turn of the wheel anywhere over the view
  (`TakesWheel`) puts the list in their place, from the step you are at, on the steps' shade and as high as they stood, filled
  with as many steps as fit (`Steps.ROW`); further turns scroll it. The steps come back `Steps.LINGER` seconds after the mouse
  left the view, not while a line's menu is open, and at once on going to a step. Those at hand white, the rest 0.85. The
  fade by line, `LIST_SHADE` and `lastAt` are gone. A double click on a line now works: it took right clicks alone.
- **`src/SpeedLeveling/SpeedLeveling.lua`:** the setting *Steps in the list*, 10 at first, 1 to 20; words of the view's tip.
- **Interface lab:** `LabWheel(-1)` in the scene `guide`.
- **Tests:** `dev/tests/speedguide.lua`.
- **Docs:** `src/SpeedLeveling/README.md`, `Doc/guides/interface-style.md`, `Doc/guides/ui-lab.md`, `Doc/ideas/Leveling.md`.

### Unit frames' auras in three groups above them; the game's own bars out of the way (Saneroki, 2026-10-31)
Saneroki: on every unit frame buffs on the left, crowd control in the middle, debuffs on the right; the game's experience, leave vehicle, cast and stance bars, its breath and fatigue bars, its bag bar, unit frames, party and raid frames and quest log gone, its menu bar on mouseover. Stance buttons of our own are not built: the bar goes as asked, and a card is on the board. A game restart takes it in (a new file in Combat's TOC).
- **`src/Combat/Units/Auras.lua`:** the kinds in the order buffs, control, debuffs, each with its `point` on the frame's roof; crowd control no longer beside the frame but by its bottom middle (the game sizes a container to what it holds, so it stays centred). `Auras.LINE`, three icons, is each container's widest line, `lineSpacing` its gap: what the list *Always show* adds goes up, not into the next kind.
- **`src/Combat/GameBars.lua` (new):** `StatusTrackingBarManager` and `StanceBar` lent to a hidden frame, by the switches *Hide the game's experience and reputation bars* (`hideTracking`) and *Hide the game's stance bar* (`hideStance`), on, in the section Action bars. The menu bar (*Menu bar on mouseover*, `menuHover`, on) keeps its place, since Forever's main action bar hangs on it: `MicroMenu`'s alpha lent, a hook after each button's `OnEnter` fades it in, a frame of ours sees the mouse off it. In Edit Mode it shows. Stands down with the module (`ns.GiveBack`, `ns.GIVEN_BACK`).
- **`src/Combat/Units/Units.lua`:** `PetCastingBarFrame` deaf with the other cast bars (it shows while you possess a pet). `Unmouse`: what lies under your own frame's hidden parts and the pet frame takes the mouse no more; the game's health and power bars, at alpha 0, took no click but held the mouse off the world over their spot.
- **`src/Core/Kit.lua`:** `Core.Lend`'s `SetMotion`, the mouse moving over a frame alone: `SetMouse` gives back clicks a frame never took.
- **`src/Inventory/Keys.lua`:** the game's `BagsBar` lent to the hidden frame of the bag windows while ours stand in for them (`Ours`; Edit Mode and Classic windows leave it there; *Bag Keys Open Our Bags* or *Can expand to fullscreen* off bring it back). The hooks on its buttons are gone with it, nothing can click them now.
- **`src/Navigation/QuestLog.lua`:** `QuestLog.Tracker`: the game's quest tracker stays out of sight with our log switched off too; only *Show the game's map* brings it back, and then it goes while ours shows, as before. It is a frame the game manages: whenever a layout of Edit Mode is applied (the login, Edit Mode closing, a layout changed) `ApplySystemAnchor` and `AddManagedFrame` reparent it, whatever parent it has, so a hook after its `SetParent` (`Reclaim`) puts it back at once.
- **Checked, already so:** the game's target, focus and their targets' frames, party and raid frames (`CompactPartyFrame` is a child of `PartyFrame` in this build), your cast bar, your breath, fatigue and feign death timers, the leave vehicle button (Navigation's trip view, while it is on) and the keys and buttons to the game's quest log.
- **Tests:** `dev/tests/combat.lua`, `combatclient.lua`, `book.lua`, `inventory.lua`, `navigation.lua`.
- **Docs:** `src/Combat/README.md`, `src/Inventory/README.md`, `src/Navigation/README.md`, `Doc/ideas/Combat.md`.

### Speed Leveling: the guide read at a glance (Saneroki, 2026-10-31)
Saneroki: the guide window optimized to read the steps at a glance: less grey text, no count twice (*0/12 ... 0/12*), *Step x*
out of the way at the top right, a more solid background and no grey bar, the list under the steps more readable, a little
more white, still fading into the background. A `/reload` takes it in.
- **`src/SpeedLeveling/Steps.lua`:** a thing to do says its count once, before its words, or a tick when done (`Uncounted`
  takes the game's own count out at either end, a colour around it or not; `Count`). The count's column and bars are gone, so
  is the rule under the head. *Step 12* or a chain's name at the card's top right, the first words beside it, a long name on
  a line of its own. Shade 0.3 to 0.65; the list on a lighter shade of its own (0.4), words 0.9, fading to 0.7 at most, a tick
  in place of a done step's number; `DONE` 0.5 to 0.7; soft words 0.8 to 0.9; notes and things to do a little larger.
- **Interface lab:** the scene `guide`; `LabGround(0.9)` reads it on snow.
- **Tests:** `dev/tests/speedguide.lua`.
- **Docs:** `Doc/guides/interface-style.md`, `Doc/guides/ui-lab.md`, `Doc/ideas/Leveling.md`.

### Speed Leveling: the guide read at a glance (Saneroki, 2026-10-31)
Saneroki: the guide window optimized to read the steps at a glance: less grey text, no count twice (*0/12 ... 0/12*), *Step x*
out of the way at the top right, a more solid background and no grey bar, the list under the steps more readable, a little
more white, still fading into the background. A `/reload` takes it in.
- **`src/SpeedLeveling/Steps.lua`:** a thing to do says its count once, before its words, or a tick when done (`Uncounted`
  takes the game's own count out at either end, a colour around it or not; `Count`). The count's column and bars are gone, so
  is the rule under the head. *Step 12* or a chain's name at the card's top right, the first words beside it, a long name on
  a line of its own. Shade 0.3 to 0.65; the list on a lighter shade of its own (0.4), words 0.9, fading to 0.7 at most, a tick
  in place of a done step's number; `DONE` 0.5 to 0.7; soft words 0.8 to 0.9; notes and things to do a little larger.
- **Interface lab:** the scene `guide`; `LabGround(0.9)` reads it on snow.
- **Tests:** `dev/tests/speedguide.lua`.
- **Docs:** `Doc/guides/interface-style.md`, `Doc/guides/ui-lab.md`, `Doc/ideas/Leveling.md`.

### Abilities: the buttons of every action bar touch (Saneroki, 2026-10-31)
Saneroki: "The padding between the spells on all actionbars should also be 0 so all spells / icons are directly touching each other without pading or margings on their sides, between them and under or above them." The bars stacked, from the bottom up: Bar 1 on Alt, Bar 8 on Ctrl, Bar 7 on Shift, Bar 6 on the plain keys.
- **`src/Abilities/Spacing.lua` (new):** Edit Mode's Icon Padding stops at 2 and the game's `minButtonPadding` is not ours to write. So the grid stays the game's and each button leaves the `CENTER` of its small frame (`button.container`) towards the middle of its line, by its place times the padding: all eleven bars, every orientation and number of rows, any icon size (the offsets stand in the button's own scale). The bar keeps its place and box. A hook after `UpdateGridLayout` follows Edit Mode; a button moves out of a fight. The switch *Action bar buttons touch* (`tightBars`, on, both games; also in the spellbook's menu); off and standing down put every button back.
- **`src/Abilities/Abilities.lua`:** `ns.SlotLabel` asks whether a bar is off with `IsVisible`: a button's parent is its small frame, not the bar, so `IsShown` said on for every bar.
- **`dev/tests/abilities.lua`:** a bar as the game makes it, its grid worked out as the game's: touching on a row, with any padding, vertical, growing left, two rows, without spacers; the row in its bar's middle; a new layout, in a fight too; the switch; standing down.

### Abilities: Action Bar 1 keeps its page; bars 6 to 8 are the fixed bars (Saneroki, 2026-10-31)
Saneroki: "I want you to implement it so that the actionbar 1 does not automatically on its own change the pages. Those pages are for me manually to change." And three bars beside it, his main bar on 1 to = and the others with Shift and Ctrl, the game's bar with its pages on Alt: "So that all pages and bars are truely unique." "The most important thing about the new actionbars is that they have all features and exactly same behaviours of the official native actionbars".
- **`src/Abilities/Bar1.lua` (new):** a header with a state driver (`Bar1.STATES`) writes the page to the twelve buttons' own `actionpage`, which comes before the bar's that the game writes a form's row to: no form changes what they show or what their keys cast, in a fight too, and the arrows and page keys still turn the page. `game` under the game's own bars (`[vehicleui][overridebar][possessbar][shapeshift][bonusbar:5][petbattle]`): the buttons read the bar's page again and the keys of Bar 6 press `ACTIONBUTTONn`, by the header's override bindings. Switch off and standing down let go at once, out of a fight.
- **The three bars are the game's own bars 6 to 8, no bars of ours:** slots 145 to 180 (pages 13 to 15) on none of Bar 1's six pages, their own `actionpage`, Edit Mode, key bindings and options in Forever as in Retail, so they behave as the game's because they are; the clean look (`Bars.BARS`) and the reservations (`ns.BARS`) already took them. Bars 2 to 5 off, pages 3 to 6 are Bar 1's alone (`VIEWABLE_ACTION_BAR_PAGES`).
- **`src/Abilities/Abilities.lua`:** the switch *Action Bar 1 keeps the page you chose* (`holdPage`, on, both games; in the spellbook's menu too, `Book/Menu.lua`); `ns.ManagedSlots` takes Bar 1's page 2 (`ns.SECOND_PAGE`), so layouts keep it; `ns.BARS[n].page`; `ns.SlotLabel`: *Bar 1 (page 2), button 1*, and a bar that is off by its page of Bar 1. `ns.GiveBack` lets the bar go.
- **`src/Abilities/Engine.lua`:** `UndoPushes`: a spell the game drops on a form's row, which never shows now (`Bar1.Unseen`), comes to the first free button.
- **`dev/tests/abilities.lua`:** the game's page writing, a button's lookup and the state driver stood in for as its code has them, the snippet run for real: stances and forms, pages in a form and in a fight, the game's own bars and the keys, the switch, the fight's wait, page 2 in labels and layouts, ghosts on page 2 and Bar 6, a spell dropped on a form's row, standing down.

### Abilities: buttons move up to a new rank (Saneroki, 2026-10-31)
Saneroki: "I will put spells that i learned on the actionbar. I will then learn a rankup but at native the old rank spell will stay on the actionbar. I want the ability module to lookout for when I learn spell rankups and replace the old rank spells with the new rank spells automatically on the actionbar"
- **`src/Abilities/Sources.lua`:** `ScanBook` compares the rank to cast with the last read (`NoteNewRanks`); a rank that went up notes the old one in `S.outranked`. Forever only, upward only by the rank line's number, no rank line: any change counts.
- **`src/Abilities/Engine.lua`:** `RaiseRanks`, first step of `Reconcile`, so not in a fight and not with something on the cursor: the newest rank goes on every button holding the old one, on all bars, Bar 1's second page and the form rows, not on slots 121 to 144, which none of your bars shows. Older ranks on a button stay (a low rank kept on purpose), macros too; no chat line, the game says it already. A refused pick-up is tried at the next update. `UndoPushes` takes off the game's own copy of a rank a button moved up to.
- **`src/Abilities/Abilities.lua`, `Book/Menu.lua`:** the switch *Move buttons up to a new rank* (`ranks`, on, Forever only), on the options page and in the spellbook's menu.
- **`dev/tests/abilities.lua`:** 29 checks: the buttons that move and those that stay, a rank named with a numeral, cursor, fight, two ranks at once, a refused pick-up, the game's own copy, a rank given back, the switch, Retail, the menu. `src/Abilities/README.md`, `Doc/agent/abilities.md`.

### Drop chances; quest areas from play; the interface on 70707 (Saneroki, 2026-10-31)
Saneroki: "Ye its fine include the drop chances where you can get them. Run everything you still need but be aware of the caps so try to devide it out or split things up so you don't hit those caps or have workarounds ready."
- **`assets/data/Drops` (batches 21, 22; a game restart takes it in):** counted chances of play in Forever with their drops and loots, where 10 loots and 3 drops stand behind them: 638 of creatures, 45 of skinning, 30 of nodes, so gems and other rare finds have real rates; node IDs by name to the set's one entry; bosses' rolled items by their kills; then 8,747 chances of the 1.12 records where both agree exactly on an item the set lists, in place of the whole-percent ones.
- **`assets/data/QuestAreas`, `Spawns` (batch 21):** 284 areas of objectives from where counts went up in play, shown as the game's are; 2 herb and ore points.
- **The newest export is 70707 (`dev/tools/blizzard adopt`):** 0 broken, 5 changed, none of them asks for a change: the settings' colour picker, the combined bags and the bags' cells take what is new; the game's spellbook is narrower, `src/Abilities/Book/Window.lua` follows by its insets, Combat's own book keeps its size. `CVarLabels`, the sync pages, `dev/tests/games.lua` made anew.

### The database on Forever's release client, 70707; quests' rewards, vendors' prices (Saneroki, 2026-10-31)
Saneroki: "New information or data might have become publick. Do an extensice research download addins that you might suspect contais more up to date wow forever data and try to update all databases with your new finds."
- **`assets/data/` (a game restart takes it in), the game first:** build 70707 and its hotfixes in `builds.toml` and the master: 67 new and 458 changed items, 16 new and 106 changed spells, 97 talent nodes, 86 recipes, 28 Legacy nodes, 2 flights, 7 auras. The set `Walking` made anew: 35 of the world's tiles have other ground than 70245, 33 other water.
- **Batches 17 to 20 (`sources.toml`, all unverified):** 17, a newer reading of batch 5: new 6 quests, 47 creatures, 43 objects, 119 entries of places, 44 of drops; filled or corrected 227 quests, 227 creatures, 703 entries of places, 28 of drops, 9 vendors; what the older reading said and the newer took back goes. 18: every good a vendor sells has its cost: the client's price (vendors' windows show the same for 776 of 798), a currency's where it asks for one; 530 goods and 9 vendors new. Rare goods no window showed stay without a price. 19: the experience of 680 quests as captured in play, 11 quests, what bosses were seen to drop. 20: what the servers said of 2,917 quests (levels, chains, objectives with their counts and texts, money, items, spells, reputation) and of 4,294 creatures (titles, ranks, kinds, families), their levels, health and the spells they cast; 219 lines of `CreatureSpells`, until now empty; 1,724 weapons' damage; flights' times; what creatures, nodes and chests give, in more than one window; no chances.
- **`assets/data/Quests/schema.toml`:** `rewardFactions`' `amount` a number: a reputation that spills over can be a fraction.
- **`dev/data/importer.py`, `master.py`:** live coming to say what another game version's line says: the line keeps what it still changes, or goes (`_catch_up`, 620 lines of the beta's to 13); a game version with nothing left in a set has no file there. `dev/tests/data/tools.py`: a check of it.
- **`dev/data/schema.py`, `compile.py`, `assets/data/Walking/schema.toml`:** a schema's `history = false`: the set files carry the newest versions alone, the master keeps all; the set `Walking` so, else its file would have grown from 25 to 46 MB. A check in `dev/tests/data/tools.py`.
- **`dev/tools/map-data`, `travel-data`, `walk-data`, `walk-gates`:** `BUILD` 70707. `Doc/guides/blizzard-updates.md`: *the game's facts*, the steps after a patch; `Doc/guides/data.md`: `_catch_up`.

### No dungeons in the normal guide (Saneroki, 2026-10-31)
Saneroki: "is the normal guide does it have dungeons in its steps? It shouldn't i don't want to have dungeon quests in the normal guide. For that there is the dungeon guide."
- **`src/SpeedLeveling/Format.lua`:** the guides' dungeon marks were read and ignored, so a normal guide sent you to its dungeons. Now a step marked for a dungeon stands only in a guide of a dungeon group, one marked for skipping it only in the others (`Format.DungeonStep`): 982 steps out of the 119 Forever guides. `dev/tests/speedguide.lua`.

### Professions along the way: nodes where the guide passes them, detours, cloth; Forever's amber (Saneroki, 2026-10-31)
Saneroki: "make sure that the guide recommend me to level minig to x when the guide naturally leads me there so I dont need to go back before I leave the zone [...] and does a extra check shows step if I am not yet the right level when I move on zone. This should work in the gude, no matter what race or crafting skill I have"; "Or if a herb [...] is nearby [...] inject a step to put a mapmarker there"; "If a node disapears the step is autofinished and the guide puts me back on track"; "Mybe i have tailoring and need to fight humanoids anyway then you can fx recommend me to grind a little more until I skip the step our outlevel the enemies"; "Wow forever might have other reworked nodes. So make sure you have accurate up todate data where possible."
- **`assets/data/` (batches 15 and 16 in `sources.toml`; a game restart takes it in):** Teldrassil's ore, Forever's own: *Chunk of Amber* (656332) in and around the Shadowthread Cave, *Large Chunk of Amber* (656333) at Ban'ethil Barrow Den, Fel Rock and more, in *Objects*, *Spawns* and *Drops*; the Large one's 25 to 100 is what the game's servers sent, the small one's thresholds are left out. Where Poor Copper Vein, Wilted Peacebloom and Stunted Silverleaf stand in Mulgore and on Zephras Isle, which the master held too few of (Poor Copper in Mulgore 6 points, now 68). *NPCs*: `kind` for 4626 creatures that had none, only where every record agrees, unverified until seen in play.
- **`src/SpeedLeveling/Gathering.lua`:** Mining and Herbalism no longer wait at the zone's door: the step with the most nodes around it in each zone gets a step after it, to what the next harder zone asks, as far as those nodes teach; a check before that zone, only where the next zone would not teach it; a zone without that kind asks nothing; passed by once you left. The guides after the one run are read for where the way goes (`Guide.After`). `Gathering.Chance`, `Gathering.Goal`, `Gathering.Stop`. The crafts keep their step before a harder zone.
- **`src/SpeedLeveling/Detours.lua` (new, in its TOC):** a node the minimap shows close to your way, a step over the guide's at `Detours.STEP`, with the arrow, map pin and key on it, ending by itself when the node is gone.
- **`src/SpeedLeveling/Grind.lua` (new, in its TOC):** after the guide's humanoids, a step to kill on for their cloth while your skill works with it and they are worth the experience.
- **`src/Core/Sight.lua` (new, in its TOC):** `Core.Sight`, what is in sight, between Navigation's `Found.lua` and the guide. `src/Navigation/Nodes.lua`: `Nodes.Find`'s record holds `yellowAt` and `greyAt`.
- **`Run.lua`:** the detour first in `Run.Hand` and `Run.Target`, `Run.Skip`, `Run.Use`; `Run.Yards`. **`Guide.lua`:** `Guide.After`. The switch is now *Professions along the way*.
- **Tests:** `dev/tests/speedleveling.lua`: the spots, the check and when it stays out, a zone with nothing, guides read on; detours (nothing in sight, too far, gone, left alone, stale, teaches nothing, a fight, the skill reached, beside it, too long, a click); cloth (a boss, a beast, outlevelled, carried, skipped).

### Class quests in the guide, every Forever class (Saneroki, 2026-10-31)
Saneroki: "The druid and warrior have class quests at different levels like 10 and 20 and i believe 16 and other levels. Can you research those as much as you can [...] and at those quest chains to the guide when I reach the right leves so I know where to go. The guide should automatically understand on wich character class the guide currently plays and if the character is the right level when it shows the steps." Then: "It should work on all forever classes, not only warrir and druid but all".
- **`assets/data/ClassQuests/` (new set, hand-picked, a game restart takes it in):** 118 chains of 404 quests for all nine classes and ten races: for whom, from which level, the quests in order, and `also` for a first quest other NPCs give. Levels 3 to 50; from 54 on (dungeon sets, raids) left out, and the paladins' chain that starts from a dropped item. **`assets/data/Quests/fixes.jsonl`:** quest 94818's giver and taker.
- **`src/SpeedLeveling/ClassQuests.lua` (new, in its TOC):** the chains of the character by class, race and side; how far each is, as the game says; the one step that is due, made as it comes up from Core's *Quests* and *Spawns* (to its giver, what it asks, to whoever takes it, the next quest with it where the same NPC gives it); what the guide does itself left to it; a click leaves a chain, a quest of it taken brings it back, a right click on the zone brings back all. The switch *Class quests*, on in Speedleveling (`src/Core/Presets.lua`, `VERSION` 3, so a profile already saved gets it).
- **`src/SpeedLeveling/Run.lua`:** the step at `ClassQuests.STEP`, outside the guide's numbers: first in `Run.Hand` and `Run.Target`; `Run.Skip` leaves its chain; `Run.Check` and `Run.Use` keep it up. **`Lines.lua`:** `Lines.Brief`, what a quest in your log asks in the game's words (the line word `brief`, `Format.WORDS`). **`Guide.lua`:** the picture's `chain`; `Guide.Things` takes a step's `things`. **`Steps.lua`:** the chain's name and how far in place of a step's number; the menu line that brings chains back.
- **Tests:** `dev/tests/classquests.lua` (the module), `dev/tests/classquests.py` (the set against the master: every quest there, every giver and taker placed, every Forever race and class with chains). **Docs:** `src/SpeedLeveling/README.md`, *Class quests*; `Doc/ideas/Leveling.md`; `Doc/guides/data.md`.

### The guide's arrow goes by the route; it stands at the toast's place (Saneroki, 2026-10-31)
Saneroki: the arrow should not point in a straight line to the guide's goal but guide along the routing to the next goal, also when the map pin points elsewhere; and it should stand where the level up and the travel widget stand, hidden while those show.
- **`src/Navigation/Planner.lua`:** its state in two ways, `pin` (drawn) and `guide` (not drawn, the place asked for, whatever the pin says and with the route off too); `Settle` lets the pin's way serve where the pin stands on that place, so no search runs twice. `Planner.Aim`, `Planner.Ahead`: the line `Planner.LEAD` yards on, the yards to the next ride or the end, that ride, where it brings one, whether it starts here.
- **`src/Core/Ways.lua` (new, a game restart takes it in):** `Core.Ways`, so Speed Leveling and Navigation need not know each other. **`src/Core/Kit.lua`:** `Core.TellsAtTop`, `Core.TopTaken`, `Core.OnTopTaken`.
- **`src/SpeedLeveling/Arrow.lua`:** turned along the way, yards along it, the ride next in its words and picture, at a ride only those; straight only without a way. At first at `Core.TOAST_TOP`, out of sight while the toast of a new level (`src/Inventory/LevelUp.lua`) or the travel overlay (`src/Navigation/TripView.lua`) shows.
- **Tests:** `dev/tests/navigation.lua`, `speedguide.lua` (the arrow's first tests), `inventory.lua`.

### New characters start on Accountwide (Saneroki, 2026-10-31)
Saneroki: "So the default of SaneUI will be the account wide profile".
- **`src/Core/Profiles.lua`:** `ForNew()` gives a character not seen yet *Accountwide*, no longer *Speedleveling*; the line *New Characters* on the page Profiles says so at first. `SaneUIDB.newProfile` still overrides it. Characters already seen keep their profile.
- **`src/Core/Settings/Profiles.lua`, `src/Core/README.md`:** the words about where new characters start.
- **`dev/tests/core.lua`:** the check of a new character's profile.

### Faction and neutral auction house weighed against each other (Saneroki, 2026-10-30)
Saneroki: "Maybe we should also implement the same save history and add advice if I should buy sell on faction / neutral auctionhouse. Maybe sometimes the adivce is buy on faction ah and sell on neutral ah." Each house always kept its own prices, forecast and sales; what was new is reading two at once. A `/reload` takes it in.
- **`src/Core/Data/Prices.lua`:** `Prices.Other()`, the house of the other kind; `Prices.Within(house, fn, ...)` reads everything as that house; `Part(key)` split from `Prices.House`; `OnSale` is both houses' together.
- **`src/Core/Data/Fees.lua`:** `Prices:Route`, `RouteUsual`, `Trip`, `AWAY`, `TRIP`: what a sale in the other house brings by its own cut and deposit; a quarter on top of the cost, 10% over the best way here, nothing older than three days as ground for a trip.
- **`src/Tooltips/Kinds/Gold.lua`:** the advice *there*, *Sell at the neutral AH for ...*; *Buy if under* by a sale there where that is more; *Buy at the neutral AH for ...*; with Alt what the other house asks.
- **`src/Economy/Deals.lua`, `Tab.lua`:** a line to buy here and sell there, the better of the two ways; a line to take a thing there, with no button.
- **`dev/tests/data.lua`, `tooltips.lua`, `economy.lua`:** 13, 8 and 6 checks more; **`dev/uilab/scenes/deals.lua`:** a neutral house.
- **Docs:** `Doc/guides/data.md` (*Fees*), `src/Tooltips/README.md`, `src/Economy/README.md`, `Doc/ideas/Economy.md`, `Doc/agent/`.

### The tab Deals, Forever's real fees, money as 1g1s1c (Saneroki, 2026-10-30)
Saneroki: "The auctionhouse window has already tabs. Can we add a extra tab that helps me find great sniper options ... and also a sell tab that shows items that I have on any of my characters ... Actually, can we have both those in the same tab maybe in 2 colums and how in the auctionhouse window how much gold worth of Items I am currently selling for? ... And the tab with the quick buy/sell is the default open tab". And: "Prices should always be shown as 1g1s1c where the letters are the ingame icons for gold silver and copper." A game restart takes it in (a new addon, new files in Core's TOC).
- **`src/Economy/` (new module):** the tab *Deals* on the game's window, open first (option *Open on Deals*). `Deals.lua`: what is cheap and likely to bring a profit, what of any character's is worth selling now, in steps. `Live.lua`: the server asked about the lines in sight one at a time; an item with no answer in time no longer holds up the rest. `Trade.lua`: a purchase and a post, each from a click: a thing sold whole on one click, a thing sold by the unit on two, the server's sum on the line, called off when it is over the limit. `Tab.lua`: the page over the game's, nothing written into its frames (the tab template joins its parent's list, so its parent is ours), the title by the game's own calls, the gold on sale over the window's border.
- **`src/Core/Data/Fees.lua` (new):** the cut and the deposit by house, from the client's own table: 5% and 5%, at a neutral house 15% and 25%, for 2, 8 and 24 hours (1, 4, 12 times), not a 48-hour auction; at least 1s an auction; whole silver for what does not stack, copper only for what stacks (`Prices:Step`). `Limit`, `Later`, `PostAt` moved here from the tooltips, so tab and tooltip say the same.
- **`src/Core/Data/Scan.lua`, `Prices.lua`:** `onSale`, the buyouts of the player's characters in each scan; `Prices:Scanned`, `Usual`, `OnSale`, `Read`, an item may be its key; `Prices.Mine` knows this account's characters without the links.
- **`src/Core/Core.lua`:** `Core.Coins` writes 1g1s1c from the game's coin icons; every view goes through it. `src/Lore/Look.lua` too.
- **`src/Tooltips/Kinds/Gold.lua`:** Core's fees; the row of fees says *post*.
- **`dev/tests/economy.lua` (new):** 58 checks; **`dev/tests/core.lua`, `data.lua`, `tooltips.lua`:** the coins, the fees; **`dev/uilab/scenes/deals.lua`** (new).
- **Docs:** `src/Economy/README.md`, `Doc/guides/data.md` (*Fees*), `Doc/ideas/Economy.md`, `Doc/agent/`, `src/Tooltips/README.md`, `src/Core/README.md`, `Doc/guides/ui-lab.md`.

### When to buy and sell an item, from the auction history (Saneroki, 2026-10-30)
Saneroki: "Can it now (when the ah history is scanned and building up) try to do their best to tell me when to sell or buy this item to
make a profit. The 1s minimum post price and the ah cut should be calculated in ... looking at the history and its natural trends, swings
between time of day, weekday etc." A game restart takes it in (a new file in Core's TOC).
- **`src/Core/Data/Rhythm.lua` (new):** one short line per item in a house's `rhythm`: the usual price over a day and a half and a week
  (geometric), the swing of each three-hour stretch and weekday, what sold fading over a week. `Rhythm.Read` gives the usual price, the
  trend, the highest and lowest price within a week and when, how many sell a day. A swing counts only clear of the item's own noise, less
  what it may be off by; an item watched too briefly names no time. Checked on made-up months: noise names no time, an evening or a
  Saturday is found at about its price, a rise is not taken for a swing, one wild first listing does not make the usual price.
- **`src/Core/Data/Scan.lua`:** a sample per stretch at its first scan (`Scan.RHYTHM`, Forever's). `Scan.Bought`: what went between two scans
  at most 30 minutes apart, matched by count and buyout, as many of each; not an auction of short time left, of a seller with a new auction
  of the item, or over the market price. `Prices.Offers` hands the scan's offers on.
- **`src/Core/Data/Prices.lua`:** `Prices:Outlook(item)`, held per item for the hour and until a scan is kept, the line of the account
  with the most samples; `Prices:Under(item, price)`, also from the game's lists of an item's offers; `Prices.UNITS`.
- **`src/Tooltips/Kinds/Gold.lua`, `Texts.lua`:** `Post`: 60% of the vendor price, at least 1s an auction, shared by the size others post in,
  counted in full in every weighing of the auction house (the game's mail gives a sold auction's deposit back; an expired one keeps it).
  *Buy if under* is what a sale at the best time brings after the cut and the post, less 10%; under it when to sell and what one brings, how
  many cost less, or when to buy. The new advice *Sell Fri 18:00-21:00 for 20s*. Alt: the usual price and trend, dearest and cheapest time,
  what sells. An item seen not selling gets no advice to buy it to sell on.
- **`dev/tests/data.lua`, `dev/tests/tooltips.lua`:** 27 and 44 checks more; **`dev/uilab/scenes/pricegraph.lua`:** three weeks of scans behind the
  item, `LabBuying`, `LabSold`, `LabScans`.
- **Docs:** `Doc/guides/data.md` (*The forecast*), `Doc/ideas/Economy.md`, `src/Tooltips/README.md`, `src/Core/README.md`, `Doc/agent/`, `Doc/guides/ui-lab.md`.

### Drop rates on the map's pins (Saneroki, 2026-10-30)
Saneroki: "When you hover over rare enemies or other map pins that contain this information can we have in the map pins tooltips
information of its drop rates?" A game restart takes it in, with the gathering work before it.
- **`src/Navigation/PinView.lua`:** `PinView.Drops(key, limit, inset)` and `PinView.Often(entry)`: on a rare's, a chest's, a herb's and a
  vein's tooltip what it gives, the likeliest first, at most `PinView.DROPS` lines, read from `Data.Drops()` when hovered; inset under
  each name in a gathered marker. `pin.rare` keeps a rare that offers a quest in. An item not loaded yet draws the tooltip again.
- **`src/Navigation/Found.lua`, `Dungeons.lua`:** the same on a found herb or ore and on an enemy's dot; a boss's loot has how often at each
  item's right, the boss found by its name among those that gave the item, as the set Encounters names no creature.
- **`src/Core/Data/Drops.lua`:** entries say `listed` (the chance is the set's) and `doubt` (the set's word, not yet confirmed).
- **Tests:** `dev/tests/navigation.lua` 801 checks, `dev/tests/data.lua`.

### Gathering counted, rare drops, discoveries, and both shared (Saneroki, 2026-10-30)
Saneroki: implement the drop rates and gathering counts, "esp focusing on how often rare drops from skinning, mining and herb gathering was
found with nodes", and the new discoveries. A game restart takes it in (new files and a new saved variable in Core's TOC).
- **`src/Core/Data/Drops.lua` (new):** `Data.Drops()`, the one door for how often things come: the set Drops, this account's counts and
  the members', with `Of`, `Rare`, `Chance`, `From`, `Knows`, `/sane data gathered`. A chance from three drops on, until then how many of how
  many; rare is at most 10 % of a way.
- **`Tally.lua`, `Loot.lua`:** a node's visits (`v` records); `Tally.Read`, strict; `Counts`, `Keys` (an index of who gives what), `Bundle`.
  A slot with no source in a window of one source is that source's; a window with none counts after a gather cast aimed at a herb or
  ore of that name in Objects; a gather cast the set Spells lacks is told by the game's name for it.
- **`src/Core/Data/Found.lua` (new):** `Data.Discovered`, `Data.Found`, the switches *Chat message for new data changes* and *... for new
  auction house data* (off), one line in 15 minutes, never in a fight, `[Details]`, `/sane data found`. `Check.lua`, `Watchers.lua`,
  `Teleports.lua`, `Confirm.lua`, `Loot.lua`, `Scan.lua` and `Relay.lua` tell it.
- **`src/Core/Data/Bundle.lua` (new), 1f.3:** every 15 minutes a member that counted something tells its totals and the rows it learned, in
  blocks of kind `B`; kept apart in `SaneUIData_Shared`, per block id; a fact needs three senders, or one of the player's other accounts
  (`Prices.Mine`, each account's auction file names its characters). Strikes as for scans. *Forget shared prices* is *Forget shared
  data* (`Data.ForgetShared`).
- **Tooltips:** rare drops on a herb or a vein, and where a rare item came from (`Gathering.lua`).
- **The harvest:** the ledger keeps visits; `dev/tests/data.lua` 514 checks, with hostile members; `dev/tests/tooltips.lua` 535.

### Role icons and incoming resurrections on the group frames (Saneroki, 2026-10-30)
Saneroki: roles for tanks and heals as a + or a shield in the top left corner, no golden circle; ready check, dispel and incoming resurrection icons as an
overlay like the buffs, anchored left and big so they are easy to see. A `/reload` takes it in.
- **`src/Combat/Units/GroupFace.lua`:** `face.role`, the game's plain role marks (`roleicon-tiny-*`) in the top left corner, in front of the bar and behind the words (the assigned role, or
  a raid's main tank); `face.rez`, `RaidFrame-Icon-Rez`, by `INCOMING_RESURRECT_CHANGED`; `face.floating` holds the dispel icon, the ready check
  and the resurrection, each after the last, as high as the frame less `Face.BIG_OFF`; your own slot a frame like all the others, its name the word Party or Raid, no health in words, `face.cog` at its far right with the tools' button on just that. Also in the preview.
- **`src/Combat/Units/Text.lua`, `Bar.lua`, `src/Core/HealthMarks.lua`, `src/Nameplates/Bar.lua`:** the raid marker no longer follows the dispel icon;
  `marks:Resize`; the dispel icon 22 on unit frames, 20 on plates. **Tests:** `dev/tests/combat.lua`.

### The group's tools on your own slot; dispel type icons; ready checks, aggro, the dead and offline (Saneroki, 2026-10-30)
Saneroki: the edge raid manager gone, your slot a settings button holding its stuff; a border in Edit Mode, just not in play; offline grey and
dead red, health bar full; the dispel type's icon instead of ring, border and aura icon, in front of the raid icon, which moves aside; ready
checks left of the raid markers with their result before they go; a solid red border on aggro. A game restart takes it in (a new file in Combat's TOC).
- **`src/Combat/Units/GroupTools.lua` (new):** the button on your slot and its panel, all by the game's secure means, as its marks, ready check
  and countdown are `HasRestrictions`: secure action buttons `raidtarget`, `worldmarker`, `togglemenu`, `click` on the game's own manager's buttons;
  opened by a secure handler, so in a fight too. `CompactRaidFrameManager` joins `Group.GAME`.
- **`src/Core/HealthMarks.lua`:** the ring and the aura's icon gone; the container's one frame shows a dispel type texture in the game's Icon style.
  `marks.lead`: the container takes the size of what it holds, so what is anchored to it moves aside by itself in a fight.
- **`src/Combat/Units/Text.lua`:** the line's left side a line of anchors (dispel icon, level, ready check, raid marker, name). **`GroupFace.lua`:**
  `Health` (dead and offline), `Aggro`, `ReadyIcon`, `Mine`. **`src/Core/Window.lua`:** `plainBox` gone again.
- **Tests:** `dev/tests/combat.lua`, `combatclient.lua`.

### One party and raid frame; barriers, lost health and dispels on every bar (Saneroki, 2026-10-30)
Saneroki: no party frame at all, the same window for party and raid with more slots, in the nameplates' look, a tank's and healer's mana
inside the bar, missing buffs floating over the name, max sizes and a preview in Edit Mode; no borders around the whole, 0px gaps, little
space inside, the health's share alone and none on narrow frames; and barriers, reduced max health and dispels on all bars. A game restart
takes it in (new files in Core's and Combat's TOCs).
- **`src/Core/HealthMarks.lua` (new):** what every health bar shows besides the health: a barrier from the game's heal prediction
  calculator (two status bars, hidden numbers never computed), the lost part from `GetUnitTotalModifiedMaxHealthPercent`, one aura
  container for the ring and icon of what can be dispelled, `RAID_PLAYER_DISPELLABLE`. On Combat's `Units/Bar.lua`, Nameplates' `Bar.lua`
  and `Plate.lua`, and the group frames; three switches on each module's page.
- **`src/Combat/Units/Group.lua`, `GroupFace.lua`, `GroupBuffs.lua` (new):** the one window, eight secure group headers, the game's party
  frame and raid container lent away, `Group.Size`; a member's face, live or made up; your buffs by family. `Bar.lua` and `Text.lua`
  give their parts out (`Plate`, `Around`, `End`, `Power`, `MakeLine`, `Mark`, `Sample`, `face.compact`, `face.bare`, `face.roomed`);
  `Units.Clicks` is the unit button's answers.
- **`src/Core/Selection.lua`, `Window.lua`:** a window's settings as rows in Edit Mode's dialog (`options.settings`, `get`, `set`: the game's
  slider, or a field); `options.plainBox`, nothing drawn in Edit Mode; `window:GrowFromBottom`.
- **Tests:** `dev/tests/combat.lua`, `combatclient.lua`, `nameplates.lua`. **The lab:** the scene `groupframes`, `Texture:SetSpriteSheetCell`.

### Shared auction prices: strict reading, kept apart, strikes, Forget shared prices (Saneroki, 2026-10-30)
Saneroki: the plan's safety layer for shared prices now, the safety review and hardening later. A game restart takes it in.
- **`src/Core/Data/Prices.lua`:** a block is read whole by its strict shape or not at all; what members sent stands over this account's
  own points but apart (`book.shared`, `book.under`, saved `heard[sender]`), never in `index`, `days` or the whole scans; a far-off price
  needs a second sender, one of the guild's. `Prices.Forget(sender)`, `Prices.Shared`.
- **`src/Core/Data/Relay.lua`:** strikes for a block off its shape, a scan from the future, two scans sooner than the server allows, a
  scan full of far-off prices; three and the sender is not heard for a week, and what it sent is taken out. Saved in `strikes`.
- **Forget shared prices:** a button on the page General, `/sane data forget`.
- **Tests:** `dev/tests/data.lua`, with hostile members.

### Auction scans shared with the guild and the group, by themselves (Saneroki, 2026-10-30)
Saneroki: new prices on the other running accounts at once, then: the automatic sync between party and guild members was planned,
and should be a given. Step 1f.2 of the plan; a game restart takes it in (a new file in Core's TOC).
- **`src/Core/Data/Relay.lua` (new):** a scan kept is offered in one message (`have`); a member with nothing as new answers (`want`) and
  only then gets what moved, in blocks, on that channel; a minute after the login a member asks who has a newer scan, and gets it
  whole. One transfer per house in 15 minutes. Another running account is a member like any other.
- **`src/Core/Data/Prices.lua`:** `Prices.Heard`: only from the guild and group, only over what is older; five times off needs a second
  sender. Into `index` only, never `days` or the whole scans. `Kept`, `Lines`.
- **The switch *Share data with my guild and group* (page General, on):** `Core.general.shareData`, `Data.Sharing()`; it also holds
  `Confirm.lua`'s sharing, sending and taking.
- **Tests:** `dev/tests/data.lua`, `dev/tests/core.lua`.

### Auction data across accounts by links, no program running; every scan whole in a file of its own (Saneroki, 2026-10-30)
Saneroki: three accounts, the third scanning in the background; the data detected and all of it on all three; a file link in
place of a system runner. A game restart takes it in (new addons), and `saneui auctiondatabase link` after a new account.
- **`dev/tools/auction-database`:** rewritten: `link` makes the addon `SaneUI_AuctionDatabase` of links to each account's
  `SaneUI_AuctionData.lua`, `status` shows the accounts' files. The merging and the user service are gone.
- **Why links there and not in `WTF`:** the game writes a new file at every save in place of what stood there (its inode changes), so
  a link in `WTF` is lost, and one shared file would lose scans, as each running game writes only what it read.
- **`src/Core/Data/Prices.lua`:** `Prices.Account()` takes what a link left, in place of `Prices.Database`. `Prices.Key`.
- **`src/AuctionScans/` (new addon `SaneUI_AuctionScans`, *Data: Auction Scans*, Forever's):** every scan whole, `SaneUIData_Scans`,
  loaded when the auction house opens, so a login reads none of it. `SaneUI_AuctionData` keeps prices and the daily history,
  and reads after the links (`## OptionalDeps`). Scans kept whole by an earlier build stay where they are in that file.
- **Tests:** `dev/tests/auctions.py`, `dev/tests/data.lua`.

### Tooltips: how an item's price went, in the Gold section; `Prices:Range` (Saneroki, 2026-10-30)
Saneroki: with Alt held, a graph of the price's development at the auction house, inside the Gold section of our tooltips, with
buttons for 24h, 1w, 2w, 1m and all; it respects and reads the actual auction data, the database or the WTF folder, whichever is
more current. `src/Tooltips/PriceGraph.lua` (new): a row of kind `graph` at the section's end, drawn after the rows have their
places (columns too), the lowest price in gold and the market's in grey at their true places on the time line, the range's highest
and lowest price, where it begins. A tooltip goes when the mouse leaves what it stands for, so no button on it can be reached: a tap
of Ctrl goes to the next range (`MODIFIER_STATE_CHANGED`, so it needs no restricted call, works in a fight and takes no key from a
binding), and only a tooltip that takes the mouse, the chat link's, has real buttons. The range is the option *Price graph's range*.
`Prices:Range(item, from, to)` and `Prices:Stamp()` in `Core/Data/Prices.lua`: what is most current for each stretch of time, a day's
scans, this account's and the database's, then the database's day, then this account's own, last the item's newest point, which
what the game lists right now moves on. `Point` also gives the key, so a link's kind of gear has its own history. A day's string
can hold several accounts' lines joined, so an item's lines are all read: the lowest price, the last market price. `recent[at]`
beside `whole` in `Core/Data/Scan.lua` (`Scan.RECENT`, Forever's): each scan of today and yesterday as `key=low,market;`, as a day's
string has one point a day and a whole scan is too much to open for a tooltip. `dev/tools/auction-database` carries it, so a
graph of a day works on an account that did not scan. `Pools.Stroke`, a pool of `Line`s. Tests: Tooltips, data, auctions. A scene
for the lab (`pricegraph`). The game needs a restart (a new file in Tooltips' TOC).

### Combat: the health bar is every unit frame's anchor (Saneroki, 2026-10-30)
Saneroki: no matter which bars are visible the health bar is the rock solid anchor and does not move, on all unit frames.
`Bar.Fit`: the health bar's rectangle no longer depends on what shows. Before, on a frame whose rank's line is wider than
a pixel (elite, rare, boss) its top rose by 1 to 3 screen pixels while something stood above it; now what stands above
rests on it, a pixel over it, and the outline rises that much less. The frames' first places by their tops
(`first.relative`, new in `Core.Window`): a frame never moved hung by its bottom, so a change of its power slots moved its
health bar. The check runs on every frame and rank with every bar on and off. A `/reload` takes it in.

### Combat: cast bars on every frame, directly above the health bar; your timers above it; your pet's resource (Saneroki, 2026-10-30)
Saneroki: fatigue and feign death part of the player frame too, above the health bar, so all three of the game's bars
are gone; the cast bars of all unit frames directly above the health bars; the pet's health and resource bar in place of
a target's target on the player frame, the game's pet frame hidden. `Bar.Fit` builds the stack up from the health bar
(`frame.above`, nearest first; the plates reach up by it), `frame.roof` its top: moved in a fight, the aura containers
stand on it and are never moved themselves. `Cast.lua` by unit (`bar.unit`, `Cast.RULES`, `Cast.Anew` for a new target or
focus), the grey of a cast that cannot be interrupted as on a nameplate (`bar.lock`), nobody else's crafting; the setting
*Cast bars* for all three. `frame.rowPower` under your pet's row (`Units.ROW_POWER`, `Bar.RowPower`, its button over both).
Your focus's first place higher, for your target's cast and auras. Your pet's own cast is left out: its row's secure
button cannot move in a fight and your power bar stands right above it (board); the game's own pet cast bar shows only
while it is possessed. The lab's scene shows it all. A `/reload` takes it in.

### Combat: your breath over your health bar, in the game's bubbles (Saneroki, 2026-10-30)
Saneroki: the breath bar over the health bar, 50 % transparent so the health shows underneath, in the bubble texture of
the game's own breath bar, the game's bar hidden. `Timers.lua`: your breath's strip lies on the health bar (`face.breath`,
new `frame.over` in `Bar.Fit`: the health bar's ends, shown by its `on`), `Timers.SHEER` 0.5, *Breath* and the seconds in
its middle (your own frame has no name there). Every timer in the game's atlas for it (`Timers.ART`, as the game's
`MirrorTimerAtlas`), no colours of our own; fatigue and feign death stay under the frame. The game's bars stay deaf as
before: its timers start only by `MIRROR_TIMER_START` and at the world's showing. A `/reload` takes it in.

### One server for every tool page: one port, running by default (Saneroki, 2026-10-30)
Saneroki: all local websites for development on the same framework, server and runner, on the same port, always running.
- **`dev/tools/web-pages` is the server:** 127.0.0.1 port 8768, the pages under their names (`/board/`, `/lab/`, `/art/`,
  `/pieces/`, `/maps/`, `/world/`, `/instances/`, `/concepts/`), a list of them at the root. A user service
  (`saneui-web-pages`, written by `saneui start webpages`) that starts with the computer and comes back when it stops;
  `saneui stop webpages` stops it until it is started again. The seven ports and five servers are gone.
- **A page is one line in `PAGES`:** folders (the first with the file answers), or a tool with `web(request)`, read again
  when its file changed, so a tool's new code needs no restart; an error stays in its page. The server puts the ☰ menu
  into every HTML page; the tools' pages lost their own tag and use relative links.
- **Only this computer's pages may ask:** now the server is always there, a request by another host name or from another
  site's page is refused (it could reach the board and the lab through the browser).
- **The tools:** the board's and the lab's own servers became `web()`; `saneui show...` opens the page in the browser. The
  world map and the maps compared serve their page from its own folder, the build only makes the data; the maps'
  pictures are made by `saneui makemapcompare` (showing them no longer builds). The lab's game stops after 15 minutes
  without a page, its saved settings kept, and starts again at the next call. `dev/tools/web-pages run --port N` (or
  `ui-lab serve --port N`) is a session's own copy, for a lab of its own.

### Speed Leveling off hides the guide, the satchel's switch mirrors the bags' box; Retail's Newcomer Chat left (Saneroki, 2026-10-30)
Saneroki: turning Speed Leveling off in the bags or the minimap's popup closes the guide, not only pauses it, and both
buttons do the same; Retail's Newcomer Chat off and left on both profiles. A game restart takes it in, with the build's
other work; `Presets.VERSION` 2 brings the wish to accounts that have settings.
- **`src/SpeedLeveling/Guide.lua`:** `Guide.State()`: *Your guide*, and off outside the profile Speedleveling. The view, what
  the guide wants and `Idle` go by it. `Moved` in `SpeedLeveling.lua`: a change of profile is followed also where the
  setting is the same on both.
- **`src/SpeedLeveling/SpeedLeveling.lua`:** the switch is the profile (`Profiles.SetLeveling`), as `Vendor.BOXES`' box: state on or
  off, offered while the module rests, the same words as the box; its pause and its right-click menu are gone. Paused
  stays on the options page.
- **`src/Navigation/Satchel.lua`, `src/Core/Switches.lua`:** a switch's state *paused* gone.
- **`src/Core/Presets.lua`, `src/Social/Social.lua`, `src/Social/Join.lua`:** in Retail both standard profiles hold the wish
  never in it for *Newcomer Chat* (the game's name), so it is left on every character, also those saved before, and again
  when the game puts one back. Default `mute` has `CHANNEL:NewcomerChat`. Forever has the channel switched off.
- **Tests:** `dev/tests/speedguide.lua`, `core.lua`, `social.lua`, `navigation.lua`.
- **Docs:** `src/SpeedLeveling/README.md`, `src/Navigation/README.md`, `src/Social/README.md`, `Doc/ideas/Leveling.md`.

### Speed Leveling: simple group rolls, professions as steps of the guide; junk tried again (Saneroki, 2026-10-30)
Saneroki: roll Need on an upgrade, else Greed, nobody Passes, off Speedleveling nothing automatic, no talk between the
accounts; gathering for the next zone as a normal step of the guide at the right time, one per profession, crafts too;
deleting junk tried again a little later, not given up for the session. A `/reload` takes it in.
- **`src/SpeedLeveling/Rolls.lua`:** no more Core's `Wire`, nothing said or heard: `Core.Upgrade` and `canNeed` say Need, else
  Greed, then Transmog, Disenchant, Need; a roll that offers nothing is left alone. No waiting for a fight's end; only for
  the game's description of the item, to `Rolls.LAST`. Gone: `KIND`, `WAIT`, `KEEP`, `Heard`, `Say`, `Beaten`.
- **`src/SpeedLeveling/Gathering.lua`:** `Gathering.Weave(guide)` puts a step per profession (`Gathering.PROFESSIONS`, 12)
  before the first step into a zone asking more than the guide's zones so far, where the guide spends `Gathering.STAY` steps
  (10, from the guides themselves: it leaves about two places a guide, and no errands). Labels follow. `Need` gives `any`,
  the higher of herbs and ore, for the professions that use neither. The view keeps the guide's own numbers (`step.shown`,
  `guide.total`). Gone: `Short`, the line under the head (`Steps.lua`), `Run.ZonesAhead`, `gatherShort`, `gatherSkill`.
- **`src/SpeedLeveling/Run.lua`:** `Run.MapId`; a skill's line gives its count and bar; `NotYours(step)` (not learnt, or the
  switch off): passed by, not listed, not gone back to; a step of a profession proves nothing and does not hold back who is
  known to have come past it. Setting renamed *Professions before the next zone*, its key stays `gather`.
- **`src/Inventory/Bags/Room.lua`:** refused, or something in your hand: tried again `Room.AGAIN` (5) seconds later, no warning;
  the warning is for no junk alone.
- **`src/Inventory/Asks.lua`:** `deleteRefused` gone: a refused item no longer stops all later ones.
- **Tests:** `dev/tests/speedleveling.lua`, `bags.lua`.
- **Docs:** `src/SpeedLeveling/README.md`, `src/Inventory/README.md`, `Doc/ideas/Leveling.md`.

### Auction data across accounts: the daily points of every account in an addon they share (Saneroki, 2026-10-30)
Saneroki: a full scan on one account visible and updated on account 2 as well; WTF keeps all, the database filtered to daily. A
restart of the game takes in the new addon once; after that a `/reload`.
- **`dev/tools/auction-database` (new, `saneui auctiondatabase`, `saneui start auctiondatabase`):** reads every account's
  `SaneUI_AuctionData.lua`, passing over the whole scans, and writes the addon `SaneUI_AuctionDatabase` into the game's `AddOns`
  folder of Forever and Retail: each item's newest point and the daily points. Only reads `WTF`. Made here, never in a build.
- **`src/Core/Data/Prices.lua`:** `Prices.Database(game, houses)`: read over the account's own points where newer.
- **`dev/build`:** leaves an addon made on this computer alone (`## X-SaneUI-Made`).
- **Why not the game's own:** `## SavedVariablesMachine` is closed to addons; `Doc/guides/data.md`, *Across accounts*.
- **Tests:** `dev/tests/auctions.py` (new), `dev/tests/data.lua`.

### Auction data: every scan kept whole in a file of its own; one door to prices, live, for every view (Saneroki, 2026-10-30)
Saneroki: Forever keeps a full history of all scans, every datapoint, filtered when it goes into the database; all tooltips,
their disenchanting and what-to-do calculations use the AH's realtime data and the database, not their own; the AH data is a
file for itself, not part of the settings. A game restart takes it in (a new addon, new files in Core's and Tooltips' TOCs).
- **`src/AuctionData/` (new addon `SaneUI_AuctionData`, *Data: Auction House*):** no code, only `SaneUIData_Market`, so the game
  keeps it in `SavedVariables/SaneUI_AuctionData.lua`. `Data.APART` hands its part over once it has loaded. Scans made with the
  build before stay behind in Core's file.
- **`src/Core/Data/Scan.lua`:** Forever keeps every row of every scan: `whole[at]`, packed a block of 1,024 rows at a time, zlib
  and Base64. Whole numbers past 2^31 written with `%.0f`.
- **`src/Core/Data/Prices.lua` (new):** `Data.Series("Prices")`: `Low`, `Last`, `OnChange`. What the game lists right now
  (browsing, an item's offers), else the last scan, per house. Each item's newest point stands in `index`.
- **Tooltips:** `Auction.lua` and the module's saved prices are gone. `Kinds/Gold.lua` reads Core's prices, by the item's link
  where a scan saw that kind; the shown panels are read anew when prices change. The advice weighs disenchanting for a character
  with the spell (*Disenchant it for 1s 40c*), also what it is worth paying. With Alt: on offer, when seen, the market.
- **Speed Leveling:** `Rewards.lua` reads Core's prices, not Tooltips' store.
- **Tests:** `dev/tests/data.lua`, `tooltips.lua`, `speedleveling.lua`.
- **Docs:** `Doc/guides/data.md` (*The full auction scan*, *Prices*), `Doc/ideas/Economy.md`, `Doc/ideas/Data.md`, `Doc/ideas/Data-build.md`, the READMEs.

### Core: the full auction scan, every 16 minutes while the house is open, with its bar (Saneroki, 2026-10-30)
Saneroki: every time the auction house opens a full scan, all items recorded in the history database, at least in the WTF,
from day one; a progress bar on the window for started, in progress, finished and the next scan; every 16 minutes while it
is open; with the game in the background; the bar, pressed, starts a scan by hand. A game restart takes it in (new files
in Core's TOC, a new saved variable).
- **`src/Core/Data/Scan.lua` (new):** `Data.Scan`, `State`, `OnChange`. Asks by itself (no click), a moment after the window
  opens and then every 16 minutes from the server's answer; 90 seconds with no answer is a refusal, asked again after 3
  minutes. Any full scan is read, whoever asked for it. The rows in a priority job of the scheduler; gear and pets wait up
  to 30 seconds for the game to know them; nothing is kept of a list taken away halfway.
- **`SaneUIData_Market` (new saved variable):** per house (region, realm, side) one string per server day:
  `key=low,market,units,auctions,sellers;`, the game's item key, prices per unit, the day's lowest, the median of the last
  scan. Forever keeps every day, Retail a week until its data's plan is made.
- **`src/Core/Data/ScanBar.lua` (new):** the bar under the game's window, beside its tabs: started, rows read, finished with
  the time and the count, the time to the next scan; refused and cut short. Pressed, it starts a scan (`Scan.Start`); inside the
  server's 15 minutes that comes back refused and the wait goes on. `/sane data` names each house.
- **Idle logout:** not prevented; `Doc/ideas/Economy.md`, *How it runs*, says why.
- **Interface lab:** the scene `auctionscan`; a flipbook's grid is taken (`dev/uilab/lab/anim.lua`).
- **Tests:** `dev/tests/data.lua`, the scan start to end, the day's merge, refusals, gear and pets, a house of a wrong shape.
- **Docs:** `Doc/guides/data.md` (*The full auction scan*), `Doc/ideas/Economy.md`, `Doc/ideas/Data.md`, `Doc/ideas/Data-build.md`.

### Navigation: the quest log's one switch, its title closer, objectives with their count and picture first (Saneroki, 2026-10-30)
Saneroki: no X to close the window: the full screen pins the quest log and closes it on the normal screen, so no close and no
pin button; the extra empty line between the title and the first quests gone; the icons for kill (sword) and loot (bag) and
the number in front of the objectives, like `- 4/7 <bag icon>: Nightstalker`. A `/reload` takes it in.
- **One switch:** `store.questLog`, the button *Quest Log* on the full map's bar, for both looks: `QuestLog.Lay` shows the log
  as it says, over the full map and on the screen alone. `QuestLog.Pinned`, `store.questLogPinned`, `Pin`, `PinLook`, `Close`,
  `QuestLog.PIN`, `PIN_OFF` and the fade on the map's way (`QuestLog.Fade`, `Window.lua`'s `Moving`) are gone: it stays as it
  is until the map stands. The game's quest tracker is lent away while the log shows, in either look.
- **Core's windows:** the option `barHeight` (`src/Core/Window.lua`); the log's `QuestLog.BAR`, 22, its list right under it.
- **Objectives:** `Objective` reads the count and the name out of the game's words and `Asked` writes them,
  `4/7 |T...|t: Nightstalker`, `QuestLog.ASKS` the game's mouse cursors by the game's `type` and Core's `kind`, as the tooltips
  and the nameplates have them. Words without a count stay as they are. A preview's objectives the same (`Listed`).
- **Interface lab:** the objectives in the scene `questlog` as the game writes them, with their `type`. The lab's reader leaves
  a paletted BLP with alpha empty, so the cursors stay blank there (board).
- **Tests:** `dev/tests/navigation.lua`, no buttons, the bar's height, the one switch, each kind of objective.
- **Docs:** `src/Navigation/README.md`, `Doc/agent/navigation.md`, `Doc/ideas/Navigation.md`.

### Navigation: ghosts in their normal colours, a + on the level of a group quest (Saneroki, 2026-10-30)
Saneroki: the red X and the red exclamation mark are enough to mark a quest not in the log, its title and the rest normal;
group and epic quests show a + on the level number, to say they are meant for a group. A `/reload` takes it in.
- **`src/Navigation/QuestLog.lua`:** `QuestLog.GHOST` gone: a preview's title in its level's colour, nothing see through; its
  mark stays the exclamation mark in `Pins.RED`. `Colour` asks the game's colour only of a row with a level.
- **The + (`ForGroup`, `Title`):** `[60+]`, as Forever's own quest log writes it: `C_QuestLog.IsEliteQuest` (Forever alone), a
  suggested group of two or more, the game's tag of one (`QuestLog.GROUP_TAGS`: Group, which is Forever's Elite, Raid, Dungeon,
  Heroic, Raid10, Raid25) or `isElite`. A preview: by the same calls, and Core's `groupSize`, which the data does not hold yet
  but for quests taken (board).
- **Interface lab:** a group quest and a group ghost in the scene `questlog`.
- **Tests:** `dev/tests/navigation.lua`, what makes a + and what does not, a ghost's colour.
- **Docs:** `src/Navigation/README.md`, `Doc/agent/navigation.md`, `Doc/ideas/Navigation.md`.

### Navigation: a quest's story first; ghosts from the map's exclamation marks (Saneroki, 2026-10-30)
Saneroki: the description above the objectives, as the first part of a quest; a click on an exclamation mark on the map adds
its quests to the log as see-through ghosts, the exclamation mark and the title red, so he knows they are not in his log;
quick to take out again. A `/reload` takes it in.
- **`src/Navigation/QuestLog.lua`:** `Story`: description, objectives, rewards. A preview's row: `QuestLog.GHOST` (0.7) of its
  mark and title, both `Pins.RED`; `Mark` always the game's exclamation mark, whatever its giver's pin shows, so `row.standing`
  and `MARKS` are gone (why it is not for you yet stays in its text).
- **Taken out:** the red X, now the right button too (no menu on a ghost's row; its text keeps the menu), and a red X on
  *Not in your log* for all of them (`row.ghosts`, `QuestLog.Unpreview()` with no quest, `Gone`). `Read`: a ghost taken from its
  giver meanwhile goes by itself, no quest twice.
- **Interface lab:** two ghosts in the scene `questlog`.
- **Tests:** `dev/tests/navigation.lua`, the order, the ghost's look, the right button, the X over them, one taken meanwhile.
- **Docs:** `src/Navigation/README.md`, `Doc/agent/navigation.md`, `Doc/ideas/Navigation.md`, `Doc/guides/ui-lab.md`.

### Navigation: an open quest's text under headings, its rewards as big icons, its gold (Saneroki, 2026-10-30)
Saneroki: the quest text and rewards formatted nicely, the reward icons big, to mouse over them for their tooltip. A `/reload`
takes it in.
- **`src/Navigation/QuestLog.lua`:** an open quest is rows of the list, each marked `part`, in place of one row of words:
  `section` (a heading in gold), `text` (words, the game's font object one size up, wrapped), `reward` (cells side by side)
  on a dark panel (`element.back`, 0.35 over the full map, 0.75 on the screen alone) with a thin gold line down the side the
  words start at (`element.rule`). `Words`, `Section`, `Given`, `Listed`, `Things`, `Others`, `Story` and `Preview` make parts,
  `AddText` and `Put` rows of them. `Tidy`: no blank lines round the game's words, no more than one inside them.
- **The rewards (`Rewards`, `RewardCell`, `RewardShown`):** the icon 40 high, the rim in its quality's colour, its name on the
  game's plate, how many on the icon, the icon red where this character cannot use it, as the game has them; two to a row
  where two of `REWARD_WIDTH` fit. Plain buttons in the row (nothing is used, so no secure tray). The mouse on the icon or its
  name: the game's tooltip by the quest's ID (`SetQuestLogItem`), compared with what is worn; `SetSpellByID`,
  `SetCurrencyByID`, `SetItemByID` for a preview's. A modified click links it, a plain one does nothing. Currencies and spells not
  known yet are read too (`C_QuestInfoSystem`). Previews the same, from Core's data.
- **Fixed:** a quest's gold never showed: `GetCoinTextureString` is no global in either game; `Core.Coins`.
- **An item not known yet** comes in once the game has it (`missing`, `ITEM_DATA_LOAD_RESULT`), the list not drawn anew for
  others. `Reveal` brings the first and the last row into sight.
- **Interface lab:** the scene `questlog`, with the three looks.
- **Tests:** `dev/tests/navigation.lua`, the parts, the cells, the tooltips, the links, an item coming late, one to a row.
- **Docs:** `src/Navigation/README.md`, `Doc/agent/navigation.md`, `Doc/ideas/Navigation.md`, `Doc/guides/ui-lab.md`.

### Interface style: a new direction, the game's own art numbered to pick from (Saneroki, 2026-10-30)
Saneroki: windows more like WoW: Forever's own style, its images instead of the leather and the paper, the game's default
fonts, the pencil icons kept, no red buttons but natural ones with golden or silver beaten-up metal borders; find a lot of
the game's elements and show them numbered. Nothing in the addon changes yet: the look is built from the picks.
- **`dev/tools/game-art` (new, `saneui makegameart`, `saneui showgameart`, 127.0.0.1 port 8776):** 1447 numbered pieces cut
  out of the newest export by the client's atlas tables, the states of a piece side by side, whole windows put together from
  Blizzard's nine-slice layouts, with a mark for each card and a PDF of the same numbers. A number stays with its piece.
- **`Doc/guides/interface-style.md`, *The new direction*:** the decisions, the references and what Retail has of Forever's art.

### Core: meters and 24 hours, the setting Units; the toast's time in minutes, no switch; the overlay level with it (Saneroki, 2026-10-30)
Saneroki: the travel widget at the same height as the level-up screen; the time with minutes as well; the off switch
removed, "just default and not clutter the ui"; the entire addon everywhere in Metric, meters and hh:mm in 24 hours like
23:59, recalculated correctly, on by default in Core, all yards and times metric or imperial by the setting; BVal,
SDmg, Res, ASpd, APen, and Bonus Arm (not BArm, which reads too close to Block and BVal). A game restart takes it in (a new file in Core's TOC).
- **`src/Core/Units.lua` (new):** `Core.Metric`, `Distance`, `DistanceNumber`, `DistanceText`, `Clock`, `ClockAt`, `GameClock`. The
  setting *Units* (page General, `Core.general.units`): Metric at first, or Imperial. 0.9144 m to the yard, whole meters.
  All of Sane UI keeps yards; only what a player reads comes through here. An option `distance = true` is a slider of
  yards shown so (`Panel.Said`).
- **Distances:** a spell's range and the yards in a spell's, buff's or item's text in the tooltips, the guide's arrow, the far
  herbs' and ore's rings (the number alone, in their unit), *Switch finders every*, `/sane range`, the options' tips of
  Speed Leveling, Nameplates and Navigation. NPCs' words and quest texts stay as the game wrote them.
- **The time:** the chat's and the conversations' times, the local and the realm's time in the satchel (no longer the game's
  `GameTime_` functions), the game's own clock (`timeMgrUseMilitaryTime`). Durations (*1:25*) are no clock.
- **The toast:** *Leveled 7h 12m* (`LevelUp.Took`). Its switch gone: `LevelUp.Apply` and the option too; an old saved value is
  taken out by itself. `LevelUp.Ask` public for the tests.
- **The travel overlay:** `Core.TOAST_TOP` (`Kit.lua`, 190 below the screen's top, where the game's toast stands) holds both it
  and the toast: the words over its line level with the toast's top (`TripView.ABOVE`). `TripView.UP` and its placing anew
  by the screen's height are gone: anchored to the screen's top it needs neither.
- **Stats' words:** BVal (Block Value), SDmg (Spell Damage), ASpd (Attack Speed), APen (Armor Penetration),
  each school's *Res*, All Res.
- Tests: `dev/tests/core.lua` the units both ways; `navigation.lua`, `tooltips.lua`, `inventory.lua` by the new words.

### Inventory: a new level in the middle of the screen; Core: the stats written short everywhere (Saneroki, 2026-10-30)
Saneroki: hide the level-up lines in the chat; the toast in the middle of the screen with the stat changes and how long
you played on that level (*Level 22! / Str +2 / Stam +1 / Leveled 7h*), then health, mana and talent points in it too, as
the chat told them (*HP +18*, *Mana +20*, *Talent +1*, a line only for what grew); in the entire game all stats
shortened. A game restart takes it in (new files in Core's and Inventory's TOCs, Core's new font).
- **`src/Core/Stats.lua` (new):** `Core.StatWord`, `Core.StatLine`, the one place of the short words: Str, Agi, Stam, Int, Spi,
  HP, Arm, Def, Block val, Crit, Crit dmg, Hit, AP, RAP, Haste, Exp, ArP, SP, Spell dmg, Heal, SPen, MP5, HP5, Mast, Vers,
  Resil, Avoid, Move, DPS, iLvl, and for each school its res, dmg and pen. Sentences stay as they are.
- **Everywhere Sane UI names a stat:** the tooltips' item lines and comparisons (`Kinds/Item.lua`: every line goes through
  `Core.StatLine`, which also does the comparisons' DPS, so `PATTERN.DPS_WORDS` is gone), the stats' window and the slots'
  strips (`Sheet/Stats.lua`, `Sheet/Slots.lua`), a quest reward's changes (`Lore/Rewards.lua`), a boss's loot with Alt
  (`Navigation/Dungeons.lua`). The game's own windows keep its words: its strings are not ours to write.
- **`src/Inventory/LevelUp.lua` (new):** the toast, by the event's stats and the time from `TIME_PLAYED_MSG`, asked once after
  the login with the chat windows deaf to that one answer. The chat windows lent deaf to `PLAYER_LEVEL_UP` and
  `PLAYER_LEVEL_CHANGED`, so Social's window gets nothing from them either; checked at each XP gain, as the game adds the
  events again. The game's toast of a level lent under a frame at alpha 0 while it runs its course; every other toast of the
  game's shows. *Level-up Toast* on the page Inventory; `ns.GiveBack` gives all of it back.
- **Core's font:** Expressway beside Kalam (`assets/optimized/Core/Fonts/`).
- **The interface lab:** scene `levelup`.
- Tests: `dev/tests/inventory.lua` the words, the lines, the time, the chat, the game's toast, the switch and standing down.

### Nameplates: what did no harm in words by default; a hidden school's colour in the text (Saneroki, 2026-10-30)
Saneroki: a setting for whether a parry, dodge, immune, block and so on is an icon or text, by default text in both
Accountwide and Speedleveling; at least in Retail auto attacks and spell attacks both white, spells should be red.
- **Words by default:** `combatPictures` (*Drawings for what did no harm*) is off by default, and only `true` shows a
  drawing (`CombatText.Nothing` read "on unless false"). Neither shared profile sets it, so both have the word, as
  Character specific has. Its tip and *Over nameplates*' tip say so.
- **Why all white:** nothing but physical damage was to be white, yet `School` and `Took` made every value the game
  hides white, and the only other way to white is a school of 0 or 1. The newest export marks no value of `UNIT_COMBAT`
  as hidden, in either game, and its documentation is the same in both, so which of them Retail hides is inferred: a
  spell school has no other way to white, while on 2026-10-23 Forever's numbers had each school's own colour.
- **A hidden school's colour:** an addon may not compare a hidden value or look it up, and curves and number formatters
  refuse it from addons; `format` and `..` are open. So `CombatText.Hued` writes the school as an exponent
  (`CombatText.SHADE`): 255 for physical, 25 or less for a spell school, in hex the green and blue of white or of a red,
  the colour then inside the text (with its minus or its blocked form). Where the game refuses, white as before. The
  same for both games, no branch by game.
- **A hidden kind:** by its school over a foe, where it is damage; white over a friend or your character, where it may be
  a heal.
- Tests: `dev/tests/nameplates.lua` 291 checks (the word by default, a hidden school in every mask, a critical hit, a
  partly blocked blow and a blow on you with one, a hidden kind over a foe, a friend and you).

### Inventory: the alts made like the bags, an item size, narrow windows, the bags' strip (Saneroki, 2026-10-30)
Saneroki: the list of alts a dropdown to save a column; the collapsing of categories and the bag/category column like the
bags'; the alts window given the bags' functions and settings where it makes sense; a slider in both windows that scales
the items, which also adjust to the window, so the windows can be narrower; the bags' icons on the equipped bag slots,
empty slots that say what they are, a little smaller; The Armory and Consumables collapsed at first.
- **`Alts/`, rebuilt on the bags' parts:** no list or grid of its own any more. `Items.Sections` makes a character's
  places into sections for `Views.Build` (`place = "alts"`: no Pinned, Recent or empty slots; a place's count on a record
  of its own that reads the item's by `__index`), and `Layout`, `Canvas`, `Sidebars`, `Columns` and a pool of `Cells`
  draw them: categories side by side, groups that fold and divide, the sidebar folding by its arrow, Sort By, the
  displays, *Show Item Level*, *Coin on Junk*, *Grey Junk*, Alt and a right click, a row's menu and drag. *Group by
  Category* went: the items always stand by category. `Roster.lua` is the dropdown on the title line (`Roster.Show`); the
  head over the items went: the level line and the gold are in a foot as the bags' (the gold's tooltip every character's).
  The doll is a frame under the canvas (`Items.MakeDoll`, `DrawDoll`), its icons as the sheet's. `Bags.TitleBar` and
  `Bags.Wheel` are shared; `Contents.FOUND` is a query that takes what the window's own search found.
- **`Layout`, the item size:** `Layout.Lay` and `Canvas:Draw` take a size; `Layout.Fit(percent, room)` is the slider's size,
  smaller while fewer than `Layout.FIT` (6) stand in a line, never under `Layout.SMALLEST` (28); the gap goes with it
  (`Layout.Gap`). `Cells`: a button's face, words and marks follow its size (`Sized`; the list's icons no longer a fixed
  inset of the large button's). `Bags.SizeRow`: the game's slider in the dropdown *View*, kept per window (`scale`); the
  bank goes with the bags (`Bags.ItemSize`).
- **Narrow windows:** `Bags.LEAST` 340 by 240 (was 560 by 320), `Alts.LEAST` 372 by 240; `Part.Width` keeps the first
  layout's bags as wide as before. On a narrow title line the count goes (`CountFit`, `BarFit`), `Bags.TITLE_MENU` 56, the
  characters' dropdown down to `Roster.LEAST`; `Foot.Room` leaves out the currencies, then the boxes' words
  (`Vendor.Width`, `Vendor.Words`).
- **`Foot.lua`, the strip:** its slots buttons of ours with a texture of ours in place of the game's item button, so
  nothing of the game's touches the icon; `Icon` reads the slot, else the item worn there (`C_Item.GetItemIconByID`),
  else `Foot.BAG_ICON` while the bag has slots. `Foot.BAG` 40 (was 51). An empty slot shows `Foot.EMPTY`'s drawing: a
  pouch, the mortar, and a new `key` (`assets/interface/categories/key.png`, drawn by code, its row in the set for when
  one is rendered), the keyring's while it holds no key.
- **`Categories`:** `Categories.FOLDED`: The Armory and Consumables folded in the sidebar at first; `folded` keeps false too,
  so a group unfolded stays so.
- **Tests:** `dev/tests/inventory.lua`'s alts rewritten for the window; `bags.lua`: the sizes, the foot, the strip. The
  lab's world has a bag worn and an empty keyring.

### Social: a quiet start, in no public channel (Saneroki, 2026-10-30)
Saneroki: the game's chat off and short names off; at first in none of the public channels, to be activated when needed;
loot, money, experience, General, Trade, Local Defense and Services turned off; on both profiles.
- **`Social.lua`:** `showNative` and `shortNames` at first off. `mute` no longer empty at first: `REWARDS` and the channels
  `General`, `Trade`, `TradeLocal` (Forever's Trade (Local), named beside Trade), `LocalDefense`, `Services`. All module
  defaults, so both standard profiles and Character specific have them.
- **`Channels.lua`, `Log.lua`, `Feed.lua`:** a channel's group is `CHANNEL:<word>` now, not `CHANNEL:<number>`: `Channels.Own`,
  the game's shortcut (`C_ChatInfo.GetChannelShortcut`; Retail's and Forever's Trade (Services) is `Services`), else its
  name. A number moves as channels are left and joined, so a tick by number went to whichever channel had it next. Saved
  ticks and chat views of the old shape count for nothing (no players yet).
- **`Join.lua`:** a character's public channels are left once: `Join.Notes` makes the notes `char.public` only when no row
  is saved for the character yet, so a second character on a shared profile has its own and a `/reload` keeps them; `LeaveOnce`
  (from the first look on, in `Settle`) leaves each channel of the game's kind (*Zone*) the first time it is seen active,
  notes it, and spares one with a wish; one the game lists as switched off waits. A wish was no way to do it: *never in
  it* would throw out what the player joins. `JoinPermanentChannel` and two more are hooked (Core's guard, it must hold after
  the window stood down): nothing of the game's interface calls them by itself, its own joins come from the server, so
  what is asked for is the player's and is never left, also a channel never seen yet (Looking For Group: the game's table
  has it joined by nobody). The game's table was read for both games: by kind this covers Forever's Trade (Local) and
  HardcoreDeaths, Newcomer Chat, Chromie Time and the rest with no list of names.
- **`Core/Sync/Chat.lua`:** a kept window's channels are matched only for those the kept windows name and the character is in,
  or joins in that writing (`Arranged`, `Among`): `AddChatWindowChannel` is not called for a channel it left, and a new
  character's General, left a moment later, is no change to offer a `/reload` for. `ownChannels` needs no change: it goes
  by the same kind. Nor do the windows' kinds of chat: the game's windows keep them and write the lines Social reads,
  `mute` decides what shows.
- **Tests:** `social.lua` (the defaults, every case above, a new character, a late or zone channel, a join by hand, a
  `/reload`, a second character, a character saved before), `sync.lua` (nothing brought back, no reload offered).

### Speed Leveling: the guide works out by itself what is done (Saneroki, 2026-10-30)
Saneroki: the guide should understand which steps are done already, even after a click back to a specific step, and
complete them by itself.
- **`Run.lua`, what the game knows:** `Known(index)` says of a step: finished, still to do, or the game cannot tell. A
  quest's lines, a level, a spell and a skill it can judge at any time; the rest (a hearth, a flight, a vendor's or
  trainer's window, a place, a thing to tick by hand, an item carried for no quest) it tells only as it happens. About
  one step in four of the guides read is of that kind, and the guide stood at each of them. Now such a step is passed
  once a step after it is known done by a quest line the guide had not asked before (`Proof`, `line.first`,
  `FirstAsked`): you came that way. A step with something judged still to do is never passed by itself. No proof: a
  level or a spell (they can be had ahead of the guide), a line asked a second time, a step that only goes along.
- **`Run.lua`, going back:** a step before your place is shown and held and your place stays kept (`place`, `Run.Place`,
  saved in the character's notes in place of the step looked at, so a `/reload` comes back to it). Once what was left
  of it is done, or a click goes on, you are back at your place and on past what got done meanwhile. A held step now
  stays until that, where it used to let go at the first check. A step after your place becomes your place. A click on
  a step the game knows is done marks no skip.
- **`Run.Ticked`, `Guide.lua`, `Steps.lua`:** a tick says what the game knows, not where you are: ahead of your place
  once every thing to do is done, behind it unless the game says it is open. A tick by the number of a done step at
  hand; how far you are in the head stays your place while you look back; Gathering looks ahead from your place.
- **The cost:** a check reads the step you are at, and only while the game cannot judge it the way ahead to the first
  step it can, `Run.PROOF` (40) at most; the list reads only what it shows. The whole guide is read when it is picked.
- **Checked offline** on 296 guides for a Horde character: played in order, no step still to do was passed (10,917
  stops; 48 before `line.first`, guides ask some quests twice); a guide picked partway reached the real place in 83% of
  825 cases (19% before), 1.3 steps short on average (29.4 before).
- **Tests:** `dev/tests/speedguide.lua`, made-up steps: a guide picked partway, ticks, what stays, what proves nothing,
  going back and redoing, your place through a `/reload`, the cost on a guide of 400 steps.

### Lore: the words wait for you, a left click cycles them, a right click answers (Saneroki, 2026-10-30)
Saneroki: reading speed 0, so the quest text never moves on by itself where Speed Leveling's auto accept and turn in
are not doing the quest; a left click cycles through the text; a right click accepts, or closes the window on the
goodbye screen.
- **`Lore.lua`:** *Reading speed* at first 0, its slider from 0 (was 230, from 100); *Words go on by themselves* stays on,
  so raising the speed alone brings them back as they were. Tips anew.
- **`Talk.lua`:** `Onward` sets no timer at 0. `Talk.Cycle` (left click): the next paragraph, after the last the first;
  it never answers (before, a click on the last paragraph accepted). `Talk.Reply` (right click, was back a paragraph,
  `Talk.Back` gone): `Default`'s answer on any paragraph; nothing with several answers, a reward to choose or a quest
  that costs money. `Talk.SETTLE` 0.4 s after a talk shows and after each answer, so a double click on the NPC or on
  the answer before gives nothing unread. `Talk.Click` tells them apart; Space and Esc as they were.
- **`Quest.lua`, `Box.lua`:** the quest under the words is a button too, its clicks the talk's (before, they fell through
  to the world), and its rewards' lines take the right button. On a reward to choose at the hand-in the right button
  does nothing, even with another chosen; `OnDoubleClick` looks at the button, as the game fires it for the right one
  too. An answer's line keeps the left button alone.
- **Speed Leveling** unchanged: its `Quests.lua` calls the game at `QUEST_DETAIL`, `QUEST_PROGRESS` and `QUEST_COMPLETE`,
  through no frame of the game's or ours, so nothing here holds it up.
- Tests: `dev/tests/lore.lua` 125 checks (the clicks on every screen, speed 0 and a raised speed, `src/SpeedLeveling/Quests.lua`
  itself beside the talk, its switches on and off).

### Navigation: Atlas the first view, one view no buttons; Follow me a tick, the minimap back the moment you walk (Saneroki, 2026-10-30)
Saneroki: "The default map view should be atlas if available otherwise scrying and in retail, since there is only one
mode it is the default one and no "mode button" is showin on the fullscreen." "Follow again should not be a number. If
on the fullscreen the follow character is ticked on (which is the default) the map should automatically snap to having
the player center on the minimap as soon as I walk (wasd) if it is off the minimap will not center. The Fullscreen can
have the 10s delay if the follow character is ticked on."
- **`Navigation.lua`:** `ns.FIRST` "atlas", the option's first default; `ns.FirstView` (Atlas where offered, else the
  fallback), which `Offer` makes the default, so a reset, a profile read after login and a saved view not offered come
  to one that can be drawn. `ns.Several`: more than one view offered; with one the setting *Map view* is hidden.
  `followAgain` and its words are gone, `followMap` on at first, its tip for both views.
- **`TopBar.lua`:** `Arrange` shows no view buttons where only one view is offered, the map selector then right of the
  quest log's button.
- **`Canvas.lua`:** `Again(now, u, walked)`, never with a button held: with *Follow me* ticked the small view as soon as
  the player walks, the mouse on it or not; the full map as the player walks, `Canvas.AGAIN` (10) seconds after
  `lastInput`. Not ticked, a view moved away stays. Where the game tells no place (an instance) the small view comes
  back at once, ticked or not: the game's minimap is the map there. `Canvas.Show` and `Canvas.Fit` set `lastInput`, so a
  map chosen on the bar or by the game has the same wait.
- `src/Navigation/README.md`, `Doc/ideas/Navigation.md`, `Doc/agent/navigation.md` updated.
- Tests: `dev/tests/navigation.lua` 754 checks and 27 in Retail; the overlay's countdown check allows a second, as the
  trip's check before it does.

### Loot: bare Link and Close, no line under a name, coins and quest items at once, nothing lost in the feed (Saneroki, 2026-10-30)
Saneroki: "I don't think the Link and close button should have borders or backgrounds. Just have the off white text
and there should be no line under the name in the lootwindows." "Take all Coins, currencies, questitems, junk, Should
be on even on accountwide." "But I do want to know what I loot."
- **`Window.lua`:** `Button`: no `Row.Bar` any more, the word alone, off white (238, 229, 208), gold under the mouse.
- **`Loot.lua`:** `notes` off at first (the switch stays). `takeCoins`, `takeCurrency`, `takeQuest`, `takeJunk` on at
  first: Loot's own defaults, so in every profile, each its own switch; `takeAll`, which Speed Leveling lends, stays off.
  The tips say so.
- **`Row.lua`:** a locked thing's words under its name only with the switch; its tooltip says so always (`Window.lua`).
- **`Feed.lua`:** what the game says of all you receive rises, taken at once or not, and that held already. Closed: a
  pile over eight lines pushed its first out at once, now the rest waits (`waiting`) until a line goes; a currency the
  game does not describe still rises, by the name in its line.
- **`Chat.lua`:** every line through `Core.Plain`: the text of these events may be a secret value in both games.
- `dev/uilab/scenes/loot.lua` keeps every line on show. `Doc/guides/interface-style.md`, *The loot window*, updated.
- The roll cards are paper with no line under the name and no Link or Close: unchanged.
- Tests: `dev/tests/loot.lua` 219 checks.

### Combat: your cast and your breath as part of your frame (Saneroki, 2026-10-30)
Saneroki: the game's cast bar hidden, the cast and breath under the player frame like the class resource bars, part of
the frame while active.
- **`Units/Cast.lua`** (new): your cast in your frame's stack, inside its outline, under your powers and your pet's
  row: icon, name, seconds left at the right end; fills, a channel empties, in the game's art; interrupted red with
  who did it (only for the cast's own number: the game also tells of what you tried meanwhile); stays `Cast.HOLD` so
  the outline does not jump between casts. An empowered cast (Retail's) fills on to its hold, with a line at each stage.
- **`Units/Timers.lua`** (new): breath, fatigue and feign death, three strips at a power bar's height under the cast;
  breath blue, the rest orange.
- **`Units/Bar.lua`:** `frame.under`, bars that hang in the stack while on (`bar.on`, `bar.tall`), `Bar.Strip`; the
  outline's depth now comes from the stack. **`Units/Text.lua`:** `Text.Line`, `Text.Over` open.
- **`Core.Lend`:** `SetDeaf(events)`, each event noted with its units and registered again as it was.
  `PlayerCastingBarFrame`, `OverlayPlayerCastingBarFrame` and `MirrorTimerContainer` go deaf while ours stand in: never
  hidden by us (the cast bar's OnHide lays out the bottom of the screen, which would run tainted) nor moved (the game
  sets its alpha and parent anew). The overlay's cast no longer shows over the vehicle bar; the game's talents window
  shows its spinner instead.
- **Settings:** *Your cast bar*, *Your breath bar*; each off gives the game's own back, *Your frame* off both. Edit Mode
  shows a sample of each on your frame.
- Lab scene `unitframes`. Tests: `dev/tests/combat.lua`, `dev/tests/core.lua` (`SetDeaf`); `wowstub.lua`'s
  `IsEventRegistered` gives its units.

### Navigation: the travel overlay higher, the way out in it (Saneroki, 2026-10-30)
Saneroki: the travel widget a little higher, with the exit vehicle icon, the game's own hidden.
- **`TripView.lua`:** `TripView.UP` 0.72 (was 2/3): the labels end just under the game's error messages. The way out
  (`DrawExit`) shows on any flight and wherever the game's button asks (`Leaving`, `CanExitVehicle` of the game's button:
  a vehicle's own action bar keeps its own leave button); in a vehicle, or a flight whose route is not known, the
  button alone (`DrawAlone`). Its click and tooltip as the game's: Request Stop on a flight, `VehicleExit` and Leave
  Vehicle else. Heard at once by a hook after the game's button's `Update`.
- **The game's button** (`Stand`): lent (`Core.Lend`: alpha 0, no mouse), so it stays shown to the game. Never hidden by
  us: its OnHide has Edit Mode's manager lay out the action bars, which would run tainted. Back in Edit Mode, with
  the setting *Your trip on screen* off, when the module stands down; it stays as it is if the game's button changed
  (`Game`).
- **`Data.Trips`:** `Land` on any flight, as the game's button; a stop is noted only where one can be made
  (`trip.canLand`), so pressing it past the last stop keeps the flight's pace.
- Tests: `dev/tests/navigation.lua` 737 checks; `wowstub.lua` has `Enable` and `Disable`.

### Speed Leveling is the profile; Make Room; one of two characters always rolls (Saneroki, 2026-10-30)
Saneroki: the box Solo is the word Speed Leveling and changes the profile, everything of Speed Leveling off elsewhere, E only
in Speedleveling, equip and delete without asking in Inventory, every group roll rolled by one of his two characters,
Make Room a box in the bags with one slot kept free, tooltips on Shift.
- **`Profiles.SetLeveling`, `Profiles.Leveling`** (`Profiles.lua`): the box's two sides. `Assign` keeps what a character
  left (`line.before`, Speedleveling never); a rename follows it, a deleted one falls back on Accountwide. A move tells
  the switches (`Core.SwitchChanged`).
- **Speed Leveling:** the switch Solo is gone. Every switch defaults to off and `follow` to `off`; `Presets.lua` turns all
  of them on in Speedleveling. `Idle()`: with none on the module rests, as Solo did, and wakes for one ticked.
  `FirstKey` gives E on Speedleveling alone; the module's `moved` asks for it after a move.
- **`Sync.Moved`:** a part with a `Default` that the profile come to holds nothing of gets the game's own (`arrived`), so
  Accountwide does not keep Speedleveling's E; not at a login, where the game's keys stay.
- **`Rolls.lua`:** the first in line (most gain, then the lower GUID) takes what the game lets it (`Any`: Greed, Transmog,
  Disenchant, Need last); a character that can roll nothing says a gain under 0. Rolls read `canDisenchant`, `canTransmog`.
- **`Inventory/Asks.lua`** (new): Equip and delete without asking, from `Errands.lua`, option `noAsk` on in every profile;
  Errands keeps only the question on what binds when picked up.
- **`Inventory/Bags/Room.lua`** (new): one slot kept free, Loot's switch `full`, a box in `Vendor.BOXES`.
  `DeleteCursorItem` wants a press of the player's, so it runs from `OnKeyDown` on a frame shown only while something
  waits.
- **`Bags.Reload`:** read a local defined further down, so a profile move with the bags built stood Inventory down.
- **Tooltips:** `show` defaults to `shift`; the old step that turned `shift` into `always` is gone.
- Tests: `dev/tests/core.lua`, `sync.lua`, `speedleveling.lua`, `bags.lua`, `tooltips.lua`.

### Core: the recommended CVars in Accountwide and Speedleveling (Saneroki, 2026-10-30)
Saneroki: the world's distance, grass, weather, shadows, water and 115 frames a second set by the profiles, nothing to
type on a new install, and what loads quicker.
- **`Presets.lua`** (new, in Core's TOC before `Profiles.lua`): `Core.Presets.profiles[name]`, `VERSION`. Both hold
  farclip, horizonClip, horizonStart, groundEffectDensity, groundEffectDist, groundEffectFade, weatherDensity, shadowMode,
  shadowTextureSize, SSAO, waterDetail, maxFPS, maxFPSBk, targetFPS and their switches, worldPreloadNonCritical,
  worldPreloadHighResTextures, cameraDistanceMaxZoomFactor and screenshotQuality. Speedleveling adds ffxDeath 0,
  showTutorials 0, instantQuestText 1, Sound_EnableErrorSpeech 0 and autoDismountFlying 1; Accountwide names the game's
  values for those five, as the computer keeps several of them, not the character.
- **`Profiles.lua`:** `Profiles.PRESET` is `Core.Presets.profiles`; `Standard` gives a profile its preset once per
  version (`SaneUIDB.presets`), only what it lacks (`Give`), and sets Sync's `from` to this game when none is kept, or
  a fresh Retail profile would write nothing. Speedleveling comes first: it copies Accountwide as that was before its
  own preset.
- **`Sync.lua`:** turning to Character specific also puts the CVars kept by name back at the game's defaults
  (`leftNamed`): no part reads a CVar of the computer's.
- The game's combat text stays with Nameplates, which switches it off while its own shows and gives it back; a CVar
  of the profiles would fight that. Tests: `dev/tests/core.lua` 410 checks, `dev/tests/sync.lua` 129.

### Navigation: by zone the quests stand under their zone (Saneroki, 2026-10-30)
Saneroki: sorted by zone it showed the zones but not the quests. The list followed the game's own log's folded headers
(`isCollapsed`), and on the screen alone a window without fold marks could not open them again. `Entries` no longer
looks at that state, and `CollapseQuestHeader` and `ExpandQuestHeader` are no longer called: the game's own log keeps its
headers as it likes. The + over the full map folds a zone in ours (`store.questLogFolds`, by its name); on the screen
alone none is folded. Tests: `dev/tests/navigation.lua` 727 checks.

### Navigation: a double click on a quest puts the pin, whatever the list does (Saneroki, 2026-10-30)
Saneroki: a double click only opened the quest and put no marker, and a second one closed it.
- **`Pressed`** (`QuestLog.lua`): a plain click on a quest waits `Canvas.DOUBLE` for a second one, told by its own clock as
  a click on the map is; the row's `OnDoubleClick` is gone. The first click no longer draws the list anew, and with it
  the buttons under the mouse, before the second comes. One click: `Unfold`. Two: `Pin`, the arrow, the map and the map
  pin, the text as it was. A click on a quest's text folds it at once.
- **`Where`:** after the player's map the one `GetQuestUiMapID` names for the quest (and `GetNextWaypointForMap` there),
  before going through the zones.
- Nothing of the quest log asks anything of Speed Leveling; only the guide's own pin is its.
- Tests: `dev/tests/navigation.lua` 724 checks.

### Navigation: a quest's text under the quest (Saneroki, 2026-10-30)
Saneroki: a click expands the quest, with its full text, the lore and the rewards in gold and items, and collapses it
again to its headline and open objectives.
- **A row of the list** (`QuestLog.lua`, kind `text`) under the quest's objectives, in place of the panel below the list:
  `AddText` (`Story`, or `Preview` for a quest not in the log), its height from `measure`, a hidden font string wrapped
  at the list's width; drawn again once the list is sized. One quest's at a time (`chosen`, `open`). A click on the text
  folds it too. `Reveal` brings it into sight: whole where it fits, else from its start. Right aligned on the right half.
- **Gone:** the panel with its scroll frame, X and buttons (`Words`, `NoWords`, `QuestLog.Details`, `Button`,
  `QuestLog.DETAILS`); *Track*, *Share* and *Abandon* stand in the right button's menu, as before.
- Tests: `dev/tests/navigation.lua` 721 checks.

### Navigation: the quest log's click and minimize (Saneroki, 2026-10-30)
Saneroki, on the click of the same day: a double click for the marker is fine after all; a click could toggle the quest's
information with its rewards and objective; a click on the title row but not on its words minimizes the log.
- **Clicks** (`QuestLog.lua`): `Look` toggles the quest's text (`QuestLog.Text`), arrow and map as before; the row's
  `OnDoubleClick` is back and puts the map pin (`DoubleClicked`, `Pin`). Previews the same.
- **Its text:** titled objectives, then `Rewards` (experience, coin, things, what to choose from), then the story. The
  game's calls take the quest's ID, so no quest is chosen in the game's own log for them, and they run only while the
  text shows. A thing the game does not know yet is left out until the log is read again.
- **Folded:** `QuestLog.Fold`, kept in `store.questLogFolded`, for both looks; `Body` takes the panel and background
  away and the mouse off the frame. No ticker, no items meanwhile. A quest's text asked for (a pin on the map, its
  giver's preview) opens it again. The title's tip says so.
- **Core's window:** the option `barClick`, a click on the title bar beside the title; a press that was a drag is none.
- Tests: `dev/tests/navigation.lua` 714 checks, `dev/tests/window.lua` 440.

### Speed Leveling: the map pin on the guide's place (Saneroki, 2026-10-30)
Saneroki: yes, the guide should put the map pin on a task as it becomes active, so that the route leads there.
- **`Pin.lua`** (new): the game's own map pin (`C_Map.SetUserWaypoint`) on the place the arrow points to, once for each
  place, looked at every `Pin.ASK` seconds (`Run.Target` moves on past a place by being asked, the arrow may be off). It
  is the game's pin, so no module leans on another: Navigation's route follows it as any pin. What you do to the pin
  stays until the next place; when the guide stops or has no place the pin goes if it stands where the guide put it.
- **`Run.Point(place)`:** a place on a map of the game's, 0 to 1; one written in the world by `GetMapPosFromWorldPos`,
  on the map its line names if it lies on that, else on the one the game has there. `Run.SamePlace` (was `Arrow.lua`'s).
- **The switch** *Map pin on the guide's place* (on). A new file in the TOC.
- Tests: `dev/tests/speedguide.lua` 119 checks.

### Navigation: the quest log leaner, its items, a click for the map pin (Saneroki, 2026-10-30)
Saneroki: no question marks, not the word Quest Log, everything closer to the screen's edge, no ticks; the quests' items
anchored to the log's right side, and on the screen's right half the text right aligned with the items at the left; a
click on a quest puts the map pin there, so the route in Forever leads there.
- **Rows** (`QuestLog.lua`): a quest has no mark and no tick (a preview keeps its giver's mark, it says whether it can
  be taken); the title `%d/%d <sorting>`. An objective stands `QuestLog.INDENT` in. Pinned, the list and title stand
  `QuestLog.EDGE_SMALL` from the side the log stands at (`Margin`), the scroll bar then at the other side.
- **A click:** `Look` puts the game's map pin too (`PinView.Drop`, the error words where the game takes none); the
  row's `OnDoubleClick` is gone, a second click is a click.
- **Items:** `GetQuestLogSpecialItemInfo`, by the game's rule for its tracker (`Special`); a row with one is
  `QuestLog.ITEM` high. Secure buttons (`SecureActionButtonTemplate`, type `item`) on a tray of their own on `UIParent`
  and placed by the screen (`Seat`): the game protects a secure button's parent, and the log has to come and go with
  the map in a fight. Set out of a fight only (`Core.AfterCombat`). Over the full map the tray is hidden in a fight by
  the game's state driver, as the map may go then. `Fade` takes it along.
- **Mirrored:** `Sided`, from Core's `docked` wherever the log was put: `Draw` lays each row out from its near end,
  `Reach` and the items follow.
- **Core's window:** `window:TitleAt(side, inset)` (the title at the bar's right, left of its buttons; its inset), the
  option `lifted` (a drag begins), `usable` keeps the log still in a fight.
- Tests: `dev/tests/navigation.lua` 707 checks, `dev/tests/window.lua` 430.

### Social: the list of chats in columns, open until you close it (Saneroki, 2026-10-30)
Saneroki, on the collapsed chat: the list behind the chat button has where you write, what the window shows and the
game's channels in separate columns, and it no longer closes when the mouse leaves the window or at a tick, a join or
a leave; only a click outside it or on its button closes it.
- **Columns:** the game's menu in its grid (`SetGridMode`, three columns, two without any of the game's channels). The
  grid runs down each column and on at the top of the next, all equally long: `Menu.lua`'s `Column` fills the shorter
  ones up with spacers.
- **Open:** the chat button hides with the mouse away, and the game closes a menu whose owner is gone, so the menu's
  owner is the window now (`Menu.Toggle(window, line)`, was `Menu.Open(owner, line)`). Radio lines close a menu by
  default: `MenuResponse.Refresh` on the chats to write in and on the three choices per channel.
- **Closed by its button:** a press outside a menu closes it, so a click on its button would close and open it again.
  `Menu.Button` gives the chat button and the chat's name `HandlesGlobalMouseEvent`, as the game's dropdown buttons,
  and `Menu.Toggle` and `Input.Toggle` close it. A channel joined or left shows or goes in the first two columns the
  next time the list opens. Tests: `dev/tests/social.lua` 626 checks, the columns, what closes the list and what does not.

### Social: the chat lies on the full screen's panels (Saneroki, 2026-10-30)
Saneroki: on the full screen the chat lay behind the see-through background and was much darker than it had to be
(board #2). Core's board draws a panel `Board.LEVEL` above what the window holds, and the chat's frame stood below that,
under the panel's plate. `Window.lua` puts the chat's frame as high as the panels; the line to write in, its plate and
the smiley over the messages (`Layout.INPUT_LEVEL`, 13 above the window). Tests: `dev/tests/social.lua`.

### Inventory: the doll's jewellery together at the top right (Saneroki, 2026-10-30)
Saneroki: the rings, trinkets and the necklace together on the right at the top, so the boots, pants, belt and gloves
go toward the bottom. `Slots.COLUMNS`: the right side the necklace, rings and trinkets, then the belt, legs and boots;
the left from the head to the wrists, the gloves at its foot, so each side keeps its eight painted slots. The necklace
stands in the right top slot, which has no strip; the gloves gain one. The alts' doll reads the same list. Tests:
`dev/tests/sheet.lua` 128 checks, `dev/tests/inventory.lua` the alts' doll in the new order.

### Inventory: the doll's slots empty of painted drawings, our own drawings in empty slots (Saneroki, 2026-10-30)
Saneroki: the sketches painted into the doll's gear slots go, the shield too, and our own rendered simplified gear
icons stand in the empty slots.
- **The picture:** `dev/tools/journal-art` (`blank_slots`) lays paper of each slot's own tone over the inside of its
  pencil box, the box's lines kept: the rows' insides found from their lines (the arc leaves them a little crooked),
  the weapons' and the ammo's measured, the shield's point mended where it lay over its box's line. `doll.blp` anew.
- **The slots:** a texture on each button, `Slots.DRAWINGS`, the bags' pencil drawings (`Art/Categories`) over the
  whole item square at half strength (`Slots.DRAWN`); hidden while something is worn there. The shirt is `armor`, the
  ammo a quiver (`special`), the off hand the shield (`offhand`); the tabard a new drawing, made by code in the set's
  line, as the card was held by the game (`assets/interface/categories/tabard.png`).
- The lab's scene `inventory` gives the doll its slots (`C_PaperDollInfo.GetInventorySlotInfo`). Tests: `dev/tests/sheet.lua`
  124 checks (a drawing for every slot, shown empty, gone with an item, back without it).

### Speed Leveling: Shift makes a whole talk yours (Saneroki, 2026-10-30)
Saneroki: holding Shift while talking to an NPC should stop the automatic accepting, going on and choosing a reward.
Shift was only asked at each step, so letting go to read took the quest just opened. Now Shift seen at any step of a talk
holds the rest of it, by the NPC's GUID (`held` in `Quests.lua`), until `Quests.OVER` seconds after a window closed with
no NPC left: the game closes the gossip window for a quest's, which is the same talk. The tip of *Quest givers* says so.
- Tests: `dev/tests/speedleveling.lua` 133 checks (let go in a talk, the gossip window gone for a quest's, a goodbye screen
  left open, Shift first seen at a later step, the next talk and another NPC done for you again).

### Bags: Auto Sell and Auto Repair, two checkboxes in the foot (Saneroki, 2026-10-30)
Saneroki: both belong to the bags, not to Speed Leveling, as a checkbox in the bag at first. New file `Bags/Vendor.lua`,
new settings `autoSell` and `autoRepair`, on at first, also on the page Inventory.
- **The boxes:** left of the gold in the foot, which always shows: `Journal.Box` as a 15 unit square, a tick of two
  pencil strokes, the word in the bags' count font, a tooltip. A change on the settings page moves the ticks; the bags
  are not drawn anew for it.
- **At a vendor:** a frame after `MERCHANT_SHOW`, heard from the login on, so the bags need never have been opened. The
  junk first, what the bar's button sells (`Foot.Sell`, now with an `after`), then `RepairAllItems` with the
  character's own money if `CanMerchantRepair`, `GetRepairAllCost` and the money allow. Shift held leaves both to the
  player.
- **The chat:** the game's sell-all now says what was sold as selling item by item did; *Junk sold: 3 for 12s.* in
  place of *Sold 3 junk items*, which read badly for one; *Repaired for 1g 20s.*
- Tests: `dev/tests/bags.lua` 349 checks (the boxes and their ticks, the vendor before the bags' window was built, the
  order of junk and repair, the event twice, Shift, each switch off, too little money, nothing to repair, a vendor who
  does not repair or left, standing down); `CreateLine` in `dev/tests/wowstub.lua`.

### Speed Leveling: its key gets E (Saneroki, 2026-10-30)
Saneroki: E as the key by default, for a fresh install. `Key.FIRST`: where the key has none, `Key.SETTLE` seconds after the login
(the profile's key bindings come first) or on waking from a rest, it gets E, once for a profile (`keyGiven`), over the game's
Strafe Right, saved in the game's binding set, said in chat. Taken off again, the old hint at every login.

### Core: key bindings, Edit Mode layouts, all CVars, window places and the bags' layout in the profile (Saneroki, 2026-10-30)
Saneroki: key bindings part of Accountwide and saved and loaded; key bindings, Edit Mode layouts, CVars, all game settings and
all addon settings automatically saved in the profile the character has active.
- **`Sync/Keys.lua`** (new): every key of the game's list by command; a command not listed now keeps its keys. `part.Default`: the
  game's own keys for a character turning to Character specific (`ToDefaults` waits for the end of a fight).
- **`Sync/Layout.lua`:** the layout in use is kept with the game's text of it too; one a character lacks is added through
  `C_EditMode` alone (`Add`), not the manager.
- **`Sync/Game.lua`:** the part *All other game settings* (`perCharacter`) takes CVars the game stores for an account too.
- **Window places** go with the profile: `Core.general.places`, `Held` in `Window.lua`, `Core.StoreName`; `Window.PlaceAll` after a
  profile's settings came into use; a module's old store starts each profile off. Tests read them there.
- **The bags' layout** moved from `store.bags` to `options.bags` (`Bags.Reload`).

### Core: three standard profiles; Speed Leveling: Skip cinematics, the guide and the arrow unlocked by a right click (Saneroki, 2026-10-30)
Saneroki: Speedleveling, Accountwide and Character specific by default. Accountwide our recommended settings, all changes
synced; Character specific 100% the game's defaults, each character its own, as a fresh install; Speedleveling all the
automation on, for now the default of new characters. No profile made for a character by itself; the user can make new ones.
A setting in Speed Leveling that skips all cinematics. A right click on the arrow and the guide to lock or unlock them, to drag them.
- **The switch Accountwide is gone** (`SetOn`, `db.accountwide`, `ownSince`): *Character specific* is a choice per character
  (`Profiles.OWN`, `line.profile`); `Profiles.On()` now says whether this character uses a shared profile.
- **Speedleveling** (`Profiles.PRESET`, `Standard`): made once, a copy of Accountwide's so that an account loses nothing, Speed
  Leveling's `solo` on; `solo` itself is off at first now, so the other profiles leave all that automation off. `db.newProfile`
  nil means Speedleveling. *Defaults* sets the preset again.
- **Own settings** start at the defaults, no copy of a profile's. Turning to Character specific the CVars the last capture
  read go back to the game's defaults (`ToDefaults`, `C_CVar.GetCVarDefault`); they stay in the profile left.
- **Sync: `Addons.lua`**, a new part: which addons are on, kept in the profile, a /reload offered; never Sane UI itself.
- **Skip cinematics** (`cinematics`): on `CINEMATIC_START` and `PLAY_MOVIE`, a frame later, `StopCinematic`, `CancelScene` where
  `CanCancelScene`, `MovieFrame:FinishMovie`; not the game's own `CinematicFrame_CancelCinematic`, which would leave a vehicle.
- **`window:Unlock(on)`** (`Window.lua`): the box of Edit Mode outside it, `options.unlockedMenu` on its right click. The zone's
  menu and a right click on the arrow (its frame takes the mouse now) lock and unlock them (`Steps.LockItem`, `Steps.LockMenu`).

### Inventory: stat weights decide upgrades; Speed Leveling: Solo, group rolls agreed between your characters (Saneroki, 2026-10-30)
Saneroki: Always show upgrades off after all, Speed Leveling puts upgrades on. Stat weights for all classes, part of the
Inventory module, so that an upgrade is one for the class played. A third box in the bag foot, Solo, that switches Speed
Leveling on or off for playing with others. Group rolls handled, on both of his characters, so that the right one gets it.
- **Take all loot** sets *Always show upgrades* off again; `Lend` now goes switch by switch, so a switch set before stays set.
- **`src/Inventory/Weights.lua`** (new): a line per class and specialization of each game (`Weights.FOREVER`, `Weights.RETAIL`),
  the stat a character builds on at 1, so two classes' gains compare; `early` for a character without a specialization.
  `Weights.Start` gives `Weights.Now` to `Core.WeighWith`.
- **`Core.Upgrade`**: worth is an item's stats by those weights (`GetItemStats`; the rings' weaker by it too, a two-handed weapon
  against both hands, a ranged weapon's dps by `ranged`), its item level where there are none or neither item has any.
- **Solo** (`solo`, on at first; a box in the foot, `Vendor.BOXES`, with `module`: another module's switch, no box without it):
  off, the module rests with `ns.off` set, the key's bindings and driver gone, the guide hidden, Loot's switches back; on again
  `Key.Wake` and the rest return. The run keeps its place, the guide catches up.
- **Roll on group loot** (`Rolls.lua`, `rolls`, on at first): each Sane UI says what the thing brings over `Core.Wire` (kind `SLR`,
  by item ID), the one it brings the most Needs, the others Greed, a tie by GUID; no word from anybody: Need on an upgrade.
  `CONFIRM_LOOT_ROLL` answered for rolls made here.

### Speed Leveling: Equip upgrades (Saneroki, 2026-10-30)
Saneroki: a checkbox, on by default, that puts upgrades on as they are looted. `Errands.lua`: on `BAG_UPDATE_DELAYED` and
`PLAYER_REGEN_ENABLED`, out of a fight, the first item the game flags as new (`C_NewItems.IsNewItem`) that `Core.Upgrade` calls
an upgrade goes on by `C_Item.EquipItemByName` in the place it names (`Core.Upgrade` now gives it as a third answer: of two, the
empty or the weaker one), one at a time so that the next is measured against it. What you took off yourself is not new and
stays off; an item tried is not tried again (`tried`), the game may refuse it. The chat says what went on.

### Speed Leveling: quest rewards chosen, two guide quests at one NPC; Bags: the green arrow on upgrades (Saneroki, 2026-10-30)
Saneroki: Always show upgrades stays on with Take all loot, he wants to see an upgrade; the green arrow always on the icon
in the bag view; an NPC with two of the guide's quests gives both, quests not in the guide are ignored; and the reward
chosen on turning in, the best upgrade, else the highest vendor or auction house value, on by default.
- **Take all loot** sets only Loot's *Everything* (`LENT`); *Always show upgrades* stays as it is, an upgrade waits in the
  window, the rest is taken.
- **`Core.Upgrade(link, id)`** (`src/Core/Upgrade.lua`, moved from Loot so that the modules share it): the kind, and now the
  item levels it brings. `Slots.Line` asks it.
- **Bags:** the game's `bags-greenarrow` at a cell's top right on gear that is an upgrade, bank too, always (`Cells.ARROW`);
  drawn anew on `PLAYER_EQUIPMENT_CHANGED`.
- **Two quests at one NPC:** `Gossip` and `Greeting` count the guide's quests on the list (`more`); while there are more the
  key is not through with the NPC, so the talk that opens again or the next press takes the next. After a hand-in the key may
  talk once more while the guide wants a quest to take or a finished one handed in (`Owed`), the next of a chain may be
  there. Only the guide's quests are taken: a quest it does not know is ignored, and right after a quest done there the talk
  closes over it, one time; a talk opened after that stays open for it. `Offered` does the same for a quest offered alone.
  `Quests.Left` also asks the switch *Close the talk when it is done*.
- **Choose quest rewards** (`Rewards.lua`, on at first): the biggest upgrade, else the guide's named reward, else the highest
  value: a vendor's, or the auction house's after its cut where the thing does not bind when picked up and a price was seen
  (Tooltips' store). Looked at again for a moment while the game does not know a reward yet (`Quests.WAIT`, `Quests.TRIES`).

### Speed Leveling: all loot taken, equip and delete unasked, the key walks to corpses, a talk that is done closes (Saneroki, 2026-10-30)
Saneroki: by default Speed Leveling sets Loot to take everything, and equipping or deleting never asks. The key walks to
a corpse around you, not only one in front and close. After a quest is taken and handed in the key no longer talks
again and stays on the goodbye screen. New file `Errands.lua`, new switches *Walk to corpses*, *Close the talk when it
is done*, *Take all loot*, *Equip and delete without asking*, each on at first.
- **Take all loot:** sets Loot's *Everything* on, once (`lootLent`): what is changed on Loot's page afterwards stays, the
  switch off puts it back. `LOOT_BIND` is answered.
- **Loot:** *Everything* now takes what binds when picked up too (the game asks first); the kinds still leave it.
- **Equip and delete without asking:** a hook on `StaticPopup_Show` answers `EQUIP_BIND`, `EQUIP_BIND_TRADEABLE`,
  `EQUIP_BIND_REFUNDABLE` and the four `DELETE_*` questions by the dialog's own `OnAccept`. `DeleteCursorItem` is
  restricted: where the game refuses, the item stays on the cursor, `deleteRefused` is kept and from then on the question
  stands with `DELETE_ITEM_CONFIRM_STRING` typed in.
- **Walk to corpses:** after a fight the interact key looks all around, 30 yards (`Key.REACH`), for `Key.LOOK` seconds, on
  while it finds corpses, `Key.LOOKS` at most, out as a fight begins; meanwhile its NPCs and things take no press.
  Click-to-Move is lent while its pick is a corpse or your target's corpse has loot (`CanLootUnit`, the state `corpse`).
- **A talk that is done:** `Quests.Left` tells the key to leave an NPC alone (attribute `left`) after a quest done there
  or a talk with nothing for the guide, until the pick moves on, the quest log changes or `Quests.LEFT` is over. A talk
  with nothing is closed a frame later: the goodbye screen always, any other within `Quests.AFTER` of a quest done there.
  Quests the guide does not know keep it open. `/sane key` has a line for corpses and the NPC left alone.

### Navigation: the quest log sorted by proximity, level, zone or type; pinned, its own place and look, the game's tracker hidden (Saneroki, 2026-10-29)
Saneroki: ordered by proximity, no "complete" text at the right; left of the title quests/max quests and the sorting,
a click there cycles Proximity, Level, Zone, Type. The pin and close not shown and the background clicked through when
not in full screen. The same place in the full screen, an independent one with the map collapsed (the top left corner
at first). Completed objectives hidden with the map collapsed, all shown in the full screen; the + buttons always
hidden collapsed; a completed quest's "Report back to ..." is an objective still to do, never hidden. The game's quest
tracker hidden while the quest log is pinned.
- **Sorting (`QuestLog.Sort`, `store.questLogSort`):** Proximity first (`C_QuestLog.GetDistanceSqToQuest`; another
  continent or no measure last; a ticker every `QuestLog.RESORT` seconds while shown draws anew once the order
  changed), Level, Zone (the game's own, its headers and folding), Type (under `GetQuestTagInfo`'s tag, the rest
  Normal); equal ones by level, then name. The title bar: `12/25 Proximity · Quest Log`; a click on the title the
  next sorting, its tip says the sorting and the next.
- **A done quest:** no *Complete* at its right; its turn in as its last objective, in the game's tracker's words
  (`GetQuestLogCompletionText`, else `GetNextWaypointText`, else `QUEST_WATCH_QUEST_READY`), in both looks.
- **Two looks (`Dress`):** over the full map as before (background, the mouse taken, pin and close, every objective,
  the done ones grey, fold marks); on the screen alone no buttons, the frame without the mouse and each row taking it
  only over its words (`Reach`, hit rect insets), the mouse wheel the game's while the list fits, the objectives done
  left out, no fold marks and no folding. Each look at its own place and size: `store.questLogPlace` and
  `store.questLogSmallPlace` (first: the screen's top left corner).
- **The game's quest tracker:** `ObjectiveTrackerFrame` lent to a hidden frame (`Core.Lend`) while the quest log is
  pinned; given back once it is not, or the module stands down.
- **Core's window:** options `titleClick` (a click on the title of a window without search), `titleTip` (its tip),
  `bare` (no title bar buttons right now); `window:Use(key, first)`, a second kept place.
- **Tests:** `dev/tests/navigation.lua` 690 checks, `dev/tests/window.lua` 426.
- A `/reload` takes it in.

### Loot: short tags under a name: BoP red, BoE orange, Uncollected light blue (Saneroki, 2026-10-29)
Saneroki: things like uncollected, BoE, BoP as abbreviations, not whole words; BoP red, BoE orange, Uncollected in the
uncollected colour (none of Sane UI's yet: the game's own, `LIGHTBLUE_FONT_COLOR`, as its "You haven't collected this
appearance").
- **`Slots.Note`:** BoP (`RED_FONT_COLOR`), BoE, BoU and WuE (`ORANGE_FONT_COLOR`), BoA; *Uncollected*
  (`LIGHTBLUE_FONT_COLOR`) after it; a quest's item *Quest*, one that starts a quest *Starts a quest*. The colours from
  the game's colour table, ours (its values) where a client has none.
- **`Slots.Uncollected`:** the item's appearance source (`C_TransmogCollection.GetItemInfo`), one the character can
  collect (`PlayerCanCollectSource`) whose look is not collected (`GetAppearanceInfoBySource`): nothing where the game
  collects no looks or the class cannot.
- **Tests:** `dev/tests/loot.lua` 184 checks.
- A `/reload` takes it in.

### Loot: the picture rounded as its bar, at the bar's left end; the green arrow in front of the name (Saneroki, 2026-10-29)
Saneroki: the item icons cornered with the same radius as the row so they fit together; the green arrow in front of
the name instead of on the icon.
- **The picture (`Row.lua`):** at the bar's left end, a screen pixel inside its border and as tall as its fill, round
  at its ends by the same caps as the fill (a quarter of its height): its left corners follow the bar's round. The
  words start after it; at the mouse the window puts this picture under the cursor (`Window.lua`).
- **The green arrow:** the game's `bags-greenarrow` in front of an upgrade's name, the name moved over for it.
- **Tests:** `dev/tests/loot.lua` 180 checks (the picture as tall as the fill, its two caps, the arrow before the name).
- A `/reload` takes it in.

### Combat: the target's-target rows light yellow, the rows' names centred (Saneroki, 2026-10-29)
Saneroki: the target of target's health bar the yellowish of the nameplates' neutral foes; its name centred in it.
- **Colour (`Units/Bar.lua`, `Units/Units.lua`):** a row's bar takes its kind's `row.colour`: your target's and your
  focus's target `Bar.CALM` (1, 0.93, 0.55, as a nameplate's creature that does not attack on sight); your pet's row
  stays green as the frames.
- **Name (`Units/Text.lua`):** the row's name centred in its bar (still its only text), the pet's too.

### Retail: no item range asked about a friend in a fight either; a blocked action's log entry names its place (Saneroki, 2026-10-29)
Saneroki: errors in the addon. The error log of both Retail accounts kept "SaneUI: the game blocked UNKNOWN()" thousands
of times after 261ba6b8 was installed (5,184 on the second account in one evening). Retail's taint log of 2026-10-26
had put every block on Nameplates asking the game an item's range (`C_Item.IsItemInRange`) in a fight; the fix spared
foes only, so a friend's plate (a player of your group, a friendly NPC) was still asked at every look.
- **Range (`src/Nameplates/Range.lua`):** no item is asked about any unit, foe or friend, while the game restricts
  addons (`Core.Restricted`: a fight, the moment before one, an encounter, a keystone, a PvP match, a map); the
  spells answer alone there, and a distance they cannot tell keeps the last one. Its own `Fighting` (the lockdown or
  the combat restriction alone, foes alone) is gone.
- **Core (`Core.lua`, `Blocked`):** the game tells a blocked action while the blocked call still runs, so its log
  entry now has the trace under its line: `saneui showerrors` names the file and line that made it, not only
  UNKNOWN() and the first addon on the stack (Core, whose guards every module's code runs through).
- **Tests:** `dev/tests/nameplates.lua` (a friend in a fight, a foe and a friend in an encounter: no item asked; after
  both, the items again), `dev/tests/core.lua` (the trace in a blocked action's entry, its kind the first line alone).
- A `/reload` takes it in.

### Combat: power bars half the health bar's height; the most important auras around the unit frames; aura lists (Saneroki, 2026-10-29)
Saneroki: the class resource bar the same 50% height of the health bar; with several, as a druid's, always the mana
bar and also the energy or rage bar in that form; "<current> | <percentage>%" on the right in the bars. CC, debuffs and
buffs on the unit frames as on the nameplates, at least the three most important; black or white list them by a right
click, with an option to open a window to add them.
- **Power bars (`Units/Bar.lua`, `Units/Text.lua`, `Units/Units.lua`):** the thin power line inside the health bar is
  gone; under the health bar, inside the same outline, a power bar half its height (13 at 100 %) with the power and its
  share at its right in a smaller size (hidden values by the game's `AbbreviateNumbers` and `UnitPowerPercent`). The bars
  are one stack a pixel apart, round only at its top and bottom; the row (target's target, pet) under the power slots.
  Your own frame keeps two slots as a druid (mana always, the form's energy or rage under it) or while your power is not
  mana but you have mana; the button's height (health and slots) is set out of a fight only, the second bar comes and
  goes with the form. The face is the health bar's height, the rest hangs under it.
- **Auras (`Units/Auras.lua`):** per frame three containers of the game's (`CustomAuraContainerTemplate`, as the
  nameplates'): debuffs above from the left (a foe: yours; a friend or you: any; the game's unit frame order), buffs
  above from the right (a foe: as on its plates; a friend or you: any, big defensives first), crowd control right of
  the frame; three each. A group for Always show in front (`includeSpellIDs`), the rest without both lists
  (`excludeSpellIDs`): the game applies them, in a fight too, where it lets addons tell spells apart (buffs of you,
  your group and friends; debuffs of foes). A right click on an icon out of a fight finds the spell by its name (the
  game writes it into a text of ours, unseen) among the unit's auras and opens a menu: Always show, Never show, Aura
  lists. The setting *Auras on the frames*.
- **The lists (`Units/Lists.lua`):** `auraWhite` and `auraBlack`, spell number and name, a spell on one list at most;
  a window of its own (`/sane auras`, and the menu): a box for a spell's number or one of your spells' names, the
  buttons Always show and Never show, both lists side by side with icon, name, number and an X, what the game lets the
  lists do under them.
- **Tests:** `dev/tests/combat.lua` checks the bars (a druid's two), the containers, the menu, the lists and the window;
  `dev/tests/combatclient.lua` gives the stand-in client the game's aura containers, aura data and powers by type.

### Loot: each line a bar as the nameplates draw theirs, in the thing's colour; the picture bare (Saneroki, 2026-10-29)
Saneroki: no border round the item's picture, the line's own is enough; the border like the nameplates' (their font,
colour, border radius, shading), the colours by the item.
- **`Row.Bar`:** made as Nameplates' bar: the game's shaded health fill (`Raid-Bar-Hp-Fill`) in the quality's colour
  (a quest's thing gold), a screen pixel inside a border nearly black (grey under the mouse, as a nameplate's on your
  target), both round by a quarter of the height (Core's corner masks on the border's two halves, Core's caps on the
  fill). The words white, in the face and outline of the game's nameplate font.
- **The picture** has no plate or border of its own; the A, Link and Close are dark bars of the same make. The round
  plates of Core's `Shape` the lines had are gone (its `trim` width setting stays in Core).
- **Tests:** `dev/tests/loot.lua` 179 checks (the bar's colour and fill, its two halves, lit under the mouse, the bare
  picture, the buttons' dark bars, a quest's gold bar).
- A `/reload` takes it in.

### Combat: every unit frame one width; the main bar's page number and arrows stay (Saneroki, 2026-10-29)
Saneroki: a fixed width for the unit frames; the arrows and the number of the action bar shown still visible on the
main bar.
- **One width (`Units/Bar.lua`):** a frame's button was 240 wide already (scaled by *Unit frame size*), but an elite's,
  a rare's or a boss's rank line reached outside its border, so those frames looked 2 to 6 pixels wider. The border now
  lies on the frame's edge, the rank's line a pixel inside it, the bars inside both (1, 2 or 4 pixels in); the row
  under the frame the same. Only the aggro glow reaches beyond the edge.
- **Page number (`ActionBars.lua`):** the main bar's `ActionBarPageNumber` and its arrows are no longer lent away
  (alpha, mouse): seen and clicked as the game has them; the bar's frame, end caps and dividers stay out of sight.

### Loot: smooth round corners; the green arrow on an upgrade, and Always show upgrades (Saneroki, 2026-10-29)
Saneroki: smooth corners, as the nameplates are drawn, "our current loot window is very ugly"; a green arrow on a thing
that would improve the character (nothing worn in its place, or better than what is worn), and a switch "Always show
upgrades": those never auto looted, even with everything set to be.
- **Round plates (`Row.lua`):** each line, its picture, the A and the buttons Link and Close stand on a plate of Core's
  `Shape` (`Row.Plate`), as the chat's bubbles: round corners (6 UI units; the picture's and the A's 4), a black fill
  at half (darker under the mouse), a thin trim (1.25) in the quality's colour (a quest's gold; the buttons grey). The
  square four-line outlines and the shades are gone.
- **Core (`Shape.lua`):** a shape's settings may give its trim's width (`trim`; `Shape.TRIM` at first).
- **Upgrades (`Upgrade.lua`, new):** gear the character can wear now (`C_PlayerInfo.CanUseItem`, its level) where
  nothing is worn, or with a higher item level than what is worn there (the weaker of two rings or trinkets); never
  armour lighter than the one worn, nor an off hand beside a two-handed weapon. The game's `bags-greenarrow` on its
  picture, its tooltip saying which.
- **Always show upgrades** (tab *Taken at once*, on): `Slots.Rule` takes no upgrade at once, over Everything, the
  kinds and the player's word.
- **Tests:** `dev/tests/loot.lua` 178 checks (the plates' trims, fill and width; an empty place, a better and a worse
  item level, lighter armour, unusable, too low a level, no gear; the upgrade waiting under Everything and the word,
  its arrow; the switch off).
- A game restart takes it in (a new file in Loot's TOC).

### Combat: your target's and focus's targets and your pet as rows under the frames; green bars, names from the left (Saneroki, 2026-10-29)
Saneroki: the target's target like the casting bar: it appears underneath while there is one, and the only text in its
health bar is the name; the unit frames green, not in class colours; the names anchored to the left instead of the
middle; no name in the player frame. (The pet with it, as asked for with the target's target.)
- **The rows (`Units/Units.lua`):** under your target's frame its target, under your focus's its target, under your own
  your pet: each a secure unit button of the game's (a click targets, a right click opens its menu), a child of the
  frame's button right under it, 18 high, shown by its own unit watch. Its health and name are read while it shows,
  every 0.2 seconds (the game sends no events of a target's target) and at once on `UNIT_TARGET` and `UNIT_PET`. The
  frame looks at its row again as it shows: a row hidden while its frame was out of sight heard no `OnHide`. In Edit
  Mode the rows show as samples (*Target's target*, *Focus's target*, *Pet*). The game's pet frame goes by its alpha
  and clicks (its layout re-parents it).
- **The look (`Units/Bar.lua`, `Units/Text.lua`):** the row inside the frame's outline, as a nameplate's cast bar: the
  border, rank line and glow reach round both, the frame's bar square at its bottom then, the row round at its own, a
  pixel's dark between; the row's name alone, from the left. Every bar the game's health green
  (`COMPACT_UNIT_FRAME_FRIENDLY_HEALTH_COLOR`), no class or reaction colours. The name from the left side's end (level
  and raid marker) up to the health's room; your own frame has none.
- **Settings:** *Your pet*, *Your target's target*, *Your focus's target* under their frames' switches, all on at
  first. Your focus's first place a little higher, to leave room for your target's row.

### Loot: the game's Auto Loot stays off on every account; a lend Sync leaves alone (Saneroki, 2026-10-29)
Saneroki: on his first account Loot works; on the second everything is looted at once.
- **Why:** Loot lent the game's Auto Loot off at the login, and Core's Sync, which keeps the game's settings in the
  profile, wrote the profile's own a moment later (the second account's profile had Auto Loot on; the first's had it
  off), so the game took everything again.
- **Sync (`Core/Sync/Game.lua`):** a CVar a module lends (`Sync.Lend(name, value, own)`, `Sync.Return(name)`): while
  lent Sync writes it no more (what it would write becomes the player's own value) and reads the player's own value
  (`Sync.Value`), so the profile keeps the player's, not the lent one; given back, the player's own again.
- **Loot (`Game.lua`):** the Auto Loot lend goes through it, at every login even while the game has it off already.
- **The line under a name (`Row.lua`):** where a thing sells for nothing (a quest's item, coins) it reaches the line's
  end instead of leaning on the empty worth (the interface lab drew no "Quest Item", no "Coins").
- **The interface lab:** a scene `loot` (`dev/uilab/scenes/loot.lua`): the window over the world with a thing of
  every quality, a quest's item and coins, the A lit on one.
- **Tests:** `dev/tests/sync.lua` 110 checks (lent, written over by the profile: kept; read: the player's own;
  given back; changed meanwhile: left), `dev/tests/loot.lua` 166.
- A `/reload` takes it in.

### Combat: unit frames for you, your target and your focus in the nameplates' look; the action bars clean (Saneroki, 2026-10-29)
Saneroki: unit frames for the player, the target and the focus, part of Combat, looking very like the nameplates: the
current health and its percent on the right, the name in the middle, the level and the raid marker on the left; players
always by their full names (first name and surname). The action bars completely clean: no borders, decorations,
backgrounds or anything on them, just the filled slots.
- **The frames (`Units/Units.lua`):** three secure unit buttons of the game's (`SecureUnitButtonTemplate`, 240 x 26):
  a click targets, a right click opens the game's menu (`togglemenu`), the mouse over one its tooltip; the game's unit
  watch shows each while its unit is there, in a fight too. Each a frameless Core window placed in Edit Mode (at first
  you left of the bottom middle, your target right of it, your focus above it); in Edit Mode a frame whose unit is not
  there shows a sample, your own named *Target* or *Focus*. The game's `TargetFrame` and `FocusFrame` stand in a hidden
  frame of ours (`Core.Lend`); of `PlayerFrame` only its picture, bars and texts go (their alpha) and its clicks, so its
  pet frame, totems, cast bar and class bars stay the game's. Secure work waits for the end of a fight.
- **The look (`Units/Bar.lua`, `Units/Text.lua`):** the nameplates' bar rebuilt for a frame of one size: round by
  Core's caps and corner masks, a one-pixel border, the gold or silver rank line, the red glow (your aggro; your own
  frame: anything's; a player who may attack you), the power along the bottom; the plates' font. The level (by
  difficulty, a skull) and the raid marker left, the name centred in the room the wider side leaves, the health right
  ("850 | 85%"; *Dead*, *Offline*); hidden values shown as they are.
- **The action bars (`ActionBars.lua`):** the main bar's frame, end caps, page number (its arrows take no clicks) and
  dividers, and each button's frame, slot, background and equipped border at alpha 0; the icon unmasked and cropped,
  its cooldowns over all of it; the mouse over it, a press and an active action a flat wash. A button that holds
  nothing is out of sight (its alpha), shown on a dark square while something is dragged and in Edit Mode. Hooks after
  the game's own keep it so; off, all is the game's again.
- **Settings:** *Unit frames* (*Your frame*, *Your target's frame*, *Your focus's frame*, *Unit frame size*) and
  *Action bars* (*Clean action bars*), all on at first. Standing down gives the game's frames and bars back. In Retail
  the same (names there have no surname).
- **Tests:** `dev/tests/combat.lua` checks both, in Forever and Retail; `dev/tests/combatclient.lua` gives the stand-in
  client what they need, for `combat.lua`, `book.lua` and `talents.lua`.

### Loot: each thing outlined on a dark shade with its worth and an A; Link and Close; your own switches for what is taken at once (Saneroki, 2026-10-29)
Saneroki: Link and Close as buttons at the window's foot (Close spelled out) on a dark 50% background; each thing with
an outline and a background, its vendor value and an "A" to add it to the auto-loot list; a list in the settings of
what is auto looted and what is not; nothing auto looted at first, switches for quest items, currency, trade goods,
gear, junk or everything; what is to be looted taken as quickly as possible.
- **The lines (`Row.lua`):** each on a black shade at half (darker under the mouse), outlined in the quality's colour
  (a quest's in gold); the picture bordered so too; the name; under it the kind and how it binds, at the right what a
  vendor pays for the stack (`Core.Coins`); an A at the top right, gold while the item is on your list. *A line under
  each name* is on again.
- **The foot (`Window.lua`):** *Link* and *Close* as buttons on the same shade with a grey outline, side by side;
  Close alone when there is nothing to link. The A (and Alt-click) puts the thing on your list and takes it now; again,
  takes it off.
- **Taken at once (`Slots.lua`):** every switch off at first: *Everything*, *Coins*, *Currencies*, *Quest items*,
  *Trade goods*, *Gear*, *Consumables*, *Junk*, by the game's own item classes (`Enum.ItemClass`); `Slots.Rule` says
  which takes a line. Over them your word on an item (`kept[id]`: true taken, false never). Gone: *Coins and
  currencies* on, *Your loot list*, *Everything up to* a quality.
- **As fast as the game lets it:** the rules' slots are taken on `LOOT_READY`, before the window opens, four at once
  and four a frame after (a hidden frame's `OnUpdate`), each slot asked once a loot. A slot that changes (a roll ended)
  is taken if the rules want it now.
- **The game's Auto Loot (`Game.lua`):** `autoLootDefault` lent off while our window is on, what it was kept and set
  back when the window is switched off or the module stands down (unless changed meanwhile), so your switches decide.
  Shift while looting still takes everything; then we ask for nothing.
- **Your items (`Items.lua`, new):** a tab of the Loot options: the items met in loot of late (`seen`, the newest
  first, 60 at most, IDs only) and those with your word, under *Taken at once* (ticked, why at the right) and *Left
  for a click*; a tick sets your word, or drops it where the switches say the same; *Forget the rest*. The options are
  in tabs now: *Loot window*, *Taken at once*, *Rolls and feed*, *Your items*.
- **Core:** `Core.Options` takes a hook `tabs` (`{ name, build = function(child) return height end }`): tabs a module
  fills itself after its switches' (`Tabbed.lua`); `Core.Tabbed` counts them.
- **Tests:** `dev/tests/loot.lua` 163 checks (the kinds, Everything, your word over them, never by a switch what binds
  when picked up; the outline, the shade, the worth, the A; Link and Close; ready before opened, a few a frame, each
  slot once; Shift's Auto Loot; the list's ticks and words; the Auto Loot setting lent and given back).
- A game restart takes it in (a new file in Loot's TOC).

### Nameplates: sizes follow a moving unit every frame (Saneroki, 2026-10-29)
Saneroki: with the quick easing the resizing happened only now and then; it should update much more often.
- **Why:** the game tells addons only between which range checks a unit stands (`Range.lua`'s ladder: 5, 8, 10, 15
  yards and so on), so the distance, and with it the size, changed only as a unit passed one: a step every few
  yards, looked at every 0.2 s.
- **Between the rungs (`Range.Follow`, `Range.Drift`):** where a unit went on to the next two rungs, its distance is
  at the rung it passed, with a pace: the last two rungs passed over the time between (not older than
  `Range.STALE`, 3 s), else a run's (`Range.RUN`, 7 yards a second) that way; none beyond `Range.FASTEST` (40) or
  where the rungs are no neighbours of the last (a jump, or the ladder changed). Every frame, from Scale.lua's
  driver, the distance moves on at that pace, never past the two rungs it stands between (there it waits, its pace
  spent), and the plate's size is aimed at it (`Scale.Step` eases after it). A unit that stops between two rungs
  shows at most one rung's step off, as before.
- **Looked at twice as often (`Range.EVERY` 0.1 s), more cheaply (`Still`):** each look asks the two rungs the unit
  stood between first (`dress.rung`, the index `Range.Check` gives back): two questions while it stays there, the
  ladder from the shortest only once it left.
- **Tests:** `dev/tests/nameplates.lua` 277 checks (on from a rung at a run's pace, every frame, waiting at the next;
  the pace from the two rungs passed last; the size aimed every frame; two questions while a unit stays; a jump past
  several rungs without a pace).
- A `/reload` takes it in.

### Nameplates: sizes change quickly and eased; the raid marker after the level (Saneroki, 2026-10-29)
Saneroki: resizing much snappier, smoother and quicker; the raid icon next to the level, as on the unit frames.
- **Eased (`Scale.Step`):** each moment a plate closes the same share of what is left to its size,
  `exp(-elapsed / Scale.EASE)`: quick at first, slower as it arrives, never past it, there within `Scale.SNAP`
  (0.002). `Scale.EASE` 0.08 s by distance (about a quarter of a second for a step of the range ladder), `Scale.QUICK`
  0.05 s selected or let go; was an even 0.2 shares a second (several seconds a step) and 2.
- **The raid marker in the line (`Text.lua`, `Marks.lua`):** right after the level, as on Sane UI's unit frames,
  `Text.BESIDE` (2) either side of it (`Gap`); no longer outside the bar left of the quest's icon, which is now the
  only piece outside (the foe's buffs stand left of it alone).
- **Tests:** `dev/tests/nameplates.lua` 271 checks (a plate eased to its size, never past it, within half a second;
  the marker after the level, the item level after the marker).
- A `/reload` takes it in.

### Nameplates: players' borders by how you know them (Saneroki, 2026-10-29)
Saneroki: the border of player plates green for guild members, blue for party, purple for raid, pink for friends,
in that order of priority: guild, party, raid, friend.
- **How you know a player (`Plate.Kin`):** `"guild"`, `"party"` (your group; in a raid your own subgroup, by
  `UnitInRaid`'s index and `GetRaidRosterInfo`'s subgroup), `"raid"` (another subgroup), `"friend"` (friends list,
  a friend of your account); found anew at each `Wear` (the plate added, a roster, guild or friends list change, a
  unit's flags), kept as `dress.kin`, the border lit anew where it changed. `Plate.Wanted` asks it too: one answer
  for which players show and how their border looks.
- **The colours (`Bar.KIN`):** green (as the game's guild chat), blue, purple (as the game's epic items), pink;
  your target's grey and your focus's orange over them, the red of a foe out of reach over all (`Bar.Border`, `Lit`).
- **Tests:** `dev/tests/nameplates.lua` 271 checks (party blue; guild over party green; raid over friend purple;
  your own subgroup of a raid blue; a friend alone pink; your target grey over green, green again after).
- A `/reload` takes it in.

### Nameplates: the line tight, no room wasted; players' plates dressed alike (Saneroki, 2026-10-29)
Saneroki: no wasted space between the level and the name, nor after the health; player plates styled exactly like
the enemies', shown for enemies who can attack you, your party, raid, guild, friends and your target, else hidden.
- **The level right before the name (`Text.NEAR`, 0):** the letters' own spacing between them; the other pieces stay
  `Text.GAP` (4) apart.
- **No slack nor spare but the name's:** only the name is ever cut short, so only it keeps `Text.SLACK` and
  `Text.SPARE`; every other text is as wide as it is (`SetWidth(0)`, never cut) and its room its width rounded up
  (`Text.Width`, `Measure`); `Text.Spare` takes the share (0 for those, a unit of leeway).
- **The health at the bar's right end:** anchored by its right at the end of its room (justified right), so the bar
  ends close after it; what it shows less than its room (the most health it can show, a guess while the game hides
  it: `888 | 100%` for a level 3 creature showing `101`) stands between the name and it.
- **Friendly players not by name only (`Scale.ALWAYS`):** the game's *Show only names for friendly players*
  (`nameplateShowOnlyNameForFriendlyPlayerUnits`) hid their health bar, auras and cast bar and took the plate's
  clicks, so Sane UI left those plates to the game. Now 0 whenever the module is on (with *Size by distance* or
  without), kept and given back like `Scale.CVARS` (`Ours`, `Restore` take the list; the logout, standing down and
  `CVAR_UPDATE` cover both), so friendly players get the same dress as any other.
- **Who shows (`Plate.Wanted`):** a player who may attack you, or whom you may attack (`UnitCanAttack` both ways),
  your group, guild, friends and target; any other player's plate out of sight. *Only players you know* says so.
- **Tests:** `dev/tests/nameplates.lua` 264 checks (the level against the name, the health right, the texts unbounded
  but the name, the name's spare; a player who may attack you though you may not attack it shown, glowing; the
  name-only setting 0 while on, with *Size by distance* off too, back at the logout).
- A `/reload` takes it in.

### Nameplates: names not cut short as plates grow and shrink; room to spare (Saneroki, 2026-10-29)
Saneroki: as a plate and its text scale together, names are often cut short with "..."; let the text follow the
plate, so the text always has room, with a little to spare before the plate widens.
- **Why it was cut:** the game draws small letters a little wider or narrower than large ones, so a text measured
  at one size (a plate appearing was measured at the full size, then shown at the size of its distance) could be
  wider than its room at another.
- **Measured again (`Text.Refit`, from `Scale.Step`):** after the plate took its new size, once it moved on by
  `Scale.TEXT` (4%) and when it settles, the count, level, item level and name are measured again at that size; the
  line is laid out anew only where a text outgrew its room or left too much of it. A text that answers its width
  hidden, and a dress out of sight, are left as they are.
- **Room to spare (`Text.Spare`):** every text's room `Text.SPARE` (6%) wider than it, and kept while the text fits in
  it with no more than twice that left over, so small changes leave the bar's width alone.
- **Not done:** drawing the text a little behind the plate's size: as a plate shrinks, the text would be larger than
  its bar for a moment, and the room would still be measured at another size than the one drawn. The room follows
  the text's size instead, measured right after the plate took it.
- **Tests:** `dev/tests/nameplates.lua` 260 checks (the spare and when a room is kept; a name drawn 5% wider as the
  plate shrinks: the bar as it was; 15% wider: wider for it, never cut; back: the bar's width again).
- A `/reload` takes it in.

### Nameplates: appearing softly, at their size; the out-of-reach red half transparent (Saneroki, 2026-10-29)
Saneroki: plates appeared with a springy overshoot; they should appear as subtly as possible, fading in linearly from
nothing to full between 60 and 55 yards, and the red range border should be half transparent, less saturated.
- **The overshoot (`Scale.lua`):** a plate appearing did not know its distance yet, so it grew from nothing to full
  size in 0.2 s, and only at the next look (up to 0.2 s later) shrank, evenly but slowly, to the size of its
  distance (some 3 s from 50 yards). Now `Scale.Born` asks its unit at once (`Range.One`, the one plate's part of
  `Range.Look`) and shows it at that size (your target's full), never larger; `Scale.GROW` is gone.
- **The fade:** its alpha from 0 to 1 in a straight line within `Scale.SHOW` (5/7 s, was 0.12): as long as running at
  7 yards a second takes from 60 yards, where the game first shows plates, to 55. Timed, since nothing an addon may
  ask tells 55 yards from 60: no item in Forever's tables reaches a foe that far (the farthest 45, grenades; those of
  60 act on yourself), nor do your spells. A plate going out at 60 yards is taken by the game at once, as before.
- **Red** (`Bar.lua`): `Bar.FAR` at alpha 0.5 (was 1).
- **Tests:** `dev/tests/nameplates.lua` 255 checks (a plate appearing 50 yards off at its size at once and never
  larger, its fade in a straight line, the red at half).
- A `/reload` takes it in.

### Loot: the loot window as little as it can be (Saneroki, 2026-10-29)
Saneroki: the loot window minimalistic to the extreme: a transparent background, Link and a close button; a thing
looted, the list closes up so the next one is under the mouse again; quest items in a golden border, the others in a
border of their quality.
- **No window round it (`Window.lua`):** no paper, frame or title; the lines straight on the world, over them at the
  right *Link* and the X (Kalam outlined, light, gold under the mouse). As wide as its widest words (140 to 300). Take
  all and the looted thing's title are gone; *A line under each name* is off at first. In Edit Mode (At the mouse off)
  two lines as they will look are placed.
- **The lines (`Row.lua`):** the picture in a thin border of its quality's colour with a dark hair round it, a
  quest's thing (a quest wants it, it begins one, it binds as a quest's: `Slots.Quest`, new) in the game's gold; the
  name in the game's quality colour, outlined; under the mouse a soft dark shade fading out to the right.
- **The next under the mouse:** a thing the player took cleared, the lines close up; at the mouse the window moves so
  the line now in the taken one's place stands where it stood (the last taken: the window comes down a line), the
  scroll counted in. A thing cleared by anything else moves nothing. The tooltip follows the thing now under the mouse.
- **Link:** the links of the loot's items and currencies, as many as the game's chat box holds, into the chat box
  being written in, else one opened with them; the player sends them (the game restricts `SendChatMessage`).
- The bags-full page stands at the right of the lines, under the strip.
- **Tests:** `dev/tests/loot.lua` 122 checks (borders, a quest's gold, the width, Link into a new and an open chat
  box, money alone without Link, the X, the lines closing up under the mouse, the Edit Mode sample).
- A `/reload` takes it in.

### Speed Leveling: gathering for the next zone; your bought Forever guides in the guide pack (Saneroki, 2026-10-29)
Saneroki: Speed Leveling in WoW: Forever should have his bought guides installed, and hint at Herbalism and Mining
high enough before the guide goes on to a harder zone.
- **Gathering for the next zone (`Gathering.lua`, new; the setting of that name, on):** the next zone the steps ahead go
  to (`Run.ZonesAhead`, a town or cave counted as its zone) where herbs or ore grow; what it asks worked out from the
  game's own facts in Core's sets *Objects* (each herb's and ore's skill) and *Spawns* (where they grow): the lowest
  skill that gathers at least half of that zone's spawns of that kind (`Gathering.SHARE`). Where a skill you have is
  lower, a line under the guide's head in the warning colour (*Wetlands next: Herbalism 92 of 100. Gather here a
  while first.*). Nothing without Core's data (Retail).
- **Your bought guides:** the import string is opened on this computer for your account and its guides put into
  *Guides: Forever* first, marked bought (191 guides, the same as on 2026-10-25), so Forever has them without a paste;
  the pack now holds 296 (all read with no unread line, 46,377 steps for a Horde and an Alliance character).
- **Tests:** `dev/tests/speedleveling.lua` 94 checks (a zone's asks; the next zone ahead short of Herbalism, Mining
  not learnt; the view's line; enough, the switch off, there already: nothing).
- A game restart takes it in (a new file in Speed Leveling's TOC; the guide pack anew).

### The blocked actions in a fight (Nameplates); Speed Leveling's key says when it has no key (Saneroki, 2026-10-29)
Saneroki: E did nothing again, and the error log held thousands of "the game blocked UNKNOWN()".
- **The blocked actions (`Nameplates/Range.lua`):** Retail's taint log (`Logs/taint.log`) named them all, 768 of 768:
  the range ladder asked `C_Item.IsItemInRange` about foes in a fight, which the game forbids to addons then; one
  block per question, every 0.2 s per plate. Now no item is asked about a foe in a fight (`Fighting`: the lockdown or
  the game's addon restriction for combat); your spells answer alone there. Not the key.
- **E did nothing on the second account:** the game keeps key bindings per account; there E was still bound to the
  button of the questing addon used before (switched off), so a press did nothing, and Sane UI's key had none. The
  hint that the key has no key was said once per account ever; now at every login while it has none, in words that
  name the per-account bindings (`Key.lua`, the setting `told` gone). `/sane key` says "none" for its keys.
- **Tests:** `dev/tests/nameplates.lua` 250 checks (a foe in a fight: no item asked, the spells still answer; a
  friend's items still; after the fight again), `dev/tests/speedleveling.lua` 88.
- A `/reload` takes it in.

### Lore: a module of its own, with talks as a scene (Saneroki, 2026-10-28)
Saneroki asked for the NPC dialogues the way he likes them, more transparent, as a Lore module: the interface hidden
while talking with its tooltips in sight to compare rewards, and each reward saying its gear kind, whether it can be
used, its sell value and its improvement without its tooltip (board #107).
- **New addon `SaneUI_Lore`** (`src/Lore/`, `src/Lore/README.md`): the first part of the Lore plan; Dialogue moves
  into it from Social (`Doc/ideas/Dialogue.md`, `Doc/ideas/Lore.md`).
- **The game's windows held** (`Native.lua`): `GossipFrame` and `QuestFrame` parented to a hidden frame of ours while
  closed (`Core.Lend`, layer noted), so the game opens them unseen and their `OnHide` never ends a talk; given back in
  a fight, with the switch off, on standing down, and at once for a talk ours does not show (`Native.Check`).
- **The talk** (`Talk.lua`, `Box.lua`, `Answers.lua`, `Quest.lua`, `Look.lua`): gossip, a greeting, a quest offered,
  in progress and handed in, low in the middle, see-through (soft shades fading out at the sides, Expressway
  outlined): the NPC's 3D face, name, a paragraph at a time (*2/4*), actions in `<...>` in the emote colour; the
  answers in a column beside (to hand in, offered, options, not done, Goodbye); the quest under the words, lifting
  the box. Space (`Keys.lua`, an override binding only while it shows) or a click goes on, a right click back; on
  the last paragraph the answer that needs no choosing. Words go on by themselves at a reading speed (230 a
  minute). Esc, Goodbye, a vendor's window or a fight end it; a talk begun in a fight is the game's.
- **Rewards read for you** (`Rewards.lua`): what it is (`Leather · Chest`; a ring by its slot; a weapon's kind), Can't
  use (the game's `isUsable`), the vendor's price for all, its item level against the one worn and the stats that
  change (`C_Item.GetItemStatDelta`), an empty slot; a click chooses, a double click hands in; a quest that costs
  money only by its answer, which says the price.
- **The interface out of sight** (`Quiet.lua`): `UIParent`'s alpha lent and faded to 0 while talking (at once back in
  a fight); `StaticPopup1`–`4` and `UIErrorsFrame` kept in sight, `GameTooltip` and its comparisons only while a
  reward shows one (`SetIgnoreParentAlpha`, each noted and put back).
- **Tooltips:** a panel follows its tooltip's `IsIgnoringParentAlpha` (`Host.Seat`), so Sane UI's tooltip panels stay
  in sight over the faded interface with it.
- **Tests:** `dev/tests/lore.lua` (83 checks, Retail too), in `dev/tests/run`.

### Loot: a module of its own, with its loot window, rules, roll cards and feed (Saneroki, 2026-10-28)
Saneroki asked for a loot module with a loot window of its own and what a full loot addon does (board #34, #109).
- **New addon `SaneUI_Loot`** (`src/Loot/`, `src/Loot/README.md`): stands in for the game's loot window and roll
  frames. The game's `LootFrame` no longer hears `LOOT_OPENED`; its `GroupLootContainer` is lent to a hidden frame
  (`Core.Lend`): both given back when switched off or standing down (`Game.lua`).
- **The loot window** (`Window.lua`, `Row.lua`, `Slots.lua`): a journal page (`Core.Journal.Dress`) at the mouse (or
  placed in Edit Mode, `windowPlace`), titled by what is looted; a line a thing (picture in a pencil slot, name in its
  quality's ink, a note: binds, kind, quest), Take all a pencil box. Click takes, Shift/Ctrl the game's modified
  clicks, Alt the loot list (`kept`, `/sane loot list`). Taken at once by the rules: coins and currencies, quest
  items, the loot list, everything up to a quality (`takeUpTo`), never what binds on pickup; no window when all is
  taken; with the game's Auto Loot only what is left 0.4 s later; a thing refused for full bags shows again.
- **Master looter** (`Master.lua`): a thing at the group's threshold opens the game's menu with the candidates (by
  class in a raid, class colours), the game's yes or no, `GiveMasterLoot`; *Request Roll*.
- **Bags full** (`Full.lua`, board #34's note): a paper page hanging out of the window's right edge: the thing's
  vendor worth, the cheapest thing in the bags (`Full.Rank`: not unsellable, a quest's or epic), arrows through the
  rest; a click picks it up to be dropped on the world (the game asks; `DeleteCursorItem` has restrictions).
- **Roll cards** (`Rolls.lua`): paper cards placed in Edit Mode (`rollsPlace`): Need, Greed or Transmog, Disenchant
  where offered, Pass as pencil boxes, refused ones faint with the game's reason; the time left a shrinking pencil
  line; who chose what counted from the game's chat lines (`Chat.lua`), named in the tooltip.
- **Loot feed** (`Feed.lua`): what you receive (and coins, currencies, the group's from a quality) rising over the
  world in outlined Kalam, merged per thing, 5 s then a fade; placed in Edit Mode (`feedPlace`). `/sane loot try`
  shows a card and the feed.
- **Docs:** the module's README; `Doc/agent/README.md`'s table, Speed Leveling's README and `Doc/ideas/Leveling.md`
  point to it.
- **Tests:** `dev/tests/loot.lua`, 109 checks (Retail's path too), in `dev/tests/run`; `wowstub.lua`'s menu lines take
  initializers.
- A game restart takes it in (a new addon).

### Navigation: the finders switch every 15 yards, a slider sets how far (Saneroki, 2026-10-28)
Saneroki: 15 yards at first, and a slider in the settings for how far you move before the finder switches.
- **The setting (`Navigation.lua`):** `nodeYards` 15 at first (was 7), still a slider of 0 to 50 yards on
  Navigation's options page, under *Herbs and ore*, now named *Switch finders every* (was *Finders in turn*), its tip
  saying what it measures. No upgrade: the settings had not yet been loaded with the 7 in the game.
- **Tests:** `dev/tests/navigation.lua` 673 checks (14 yards moved: no turn yet; 15: the turn).
- A `/reload` takes it in.

### Navigation: the finders take turns every 7 yards, Find Fish among them, and come back after death (Saneroki, 2026-10-28)
Saneroki: Find Herbs, Find Minerals and Find Fish are lost at death; Sane UI should cast them again every 7 yards,
in turn among those the character has (only the one, where it has one), and put it back on after reviving.
- **Turns by yards (`Nodes.lua`):** the setting *Finders in turn* (`nodeYards`, 7 at first, 0 never) counts the
  yards you move (your speed at each look, `GetUnitSpeed`) in place of seconds (`nodeTurns`, let go by the options'
  shape 4); the next finder in `Nodes.ORDER` (herbs, ore, fish) that the pin filter wants and the game lists for the
  character, as soon as the global cooldown lets it (`Free` asks that finder's own spell).
- **Find Fish (43308):** a finder of its own, switched by the pin filter's new kind *Found fishing pools* (on at
  first; a switch only, no pin or size: the game's minimap dots show the pools); left out of the satchel's tracking
  as the other finders are (`Nodes.KIND`, which also knows Retail's other Find Herbs and Find Minerals spells).
  Found.lua sweeps for herbs and ore only (`Nodes.DRAWN`), none while Find Fish is on.
- **Back after death:** `PLAYER_ALIVE` and `PLAYER_UNGHOST` try the first finder wanted every half second for 10
  seconds until it can be cast (`Revived`), none where a finder is on already; a ghost's tries run out, the corpse
  or the spirit healer tries again. Retail keeps its tracking through death: nothing there.
- **Tests:** `dev/tests/navigation.lua` 672 checks (the turns by yards, Find Fish in turn, the global cooldown,
  *Found fishing pools* off, a ghost, alive again, one finder alone; the satchel without Find Fish), 26 in Retail.
- A `/reload` takes it in.

### Speed Leveling's key talks to the NPCs Retail's spells cannot help, and walks to neutral ones; `/sane key` (Saneroki, 2026-10-26)
Saneroki: the key talked to no NPC and walked to none; a press said "I can't do that".
- **Why (`Key.lua`):** the key's states for "an NPC in front of you" and "your target is a friend" used the macro
  condition `help`, which holds only for a unit your spells could help, and many quest givers are not one; Click-to-
  Move was lent only for the game's friends (`UnitIsFriend`), so not for neutral quest givers. Then a press ran Find,
  which let your target go, or used a quest item (the "I can't do that").
- **Now:** a target is a friend when it is alive and no foe (`noharm`); the NPC in front of you is told to the header
  out of a fight when it is a creature, alive and no foe (the attribute `npc`, from `PLAYER_SOFT_INTERACT_CHANGED`);
  Click-to-Move is lent for a wanted NPC that cannot be attacked. `Wanted.Unit` also takes an NPC the game says
  belongs to a quest of yours (to hand it in to, or to speak to), on any client, without Core's data.
- **`/sane key` (`Key.Check`):** what the key sees in chat, kept as `keyCheck` in Speed Leveling's store for after a
  `/reload`.
- **Blocked actions:** the 224 blocks (`UNKNOWN()`) of 08:08 to 08:11 did not come back in a test of the key with the
  game's taint log on; left open until the log names one.
- **Tests:** `dev/tests/speedleveling.lua` 88 checks (an NPC in front that `help` misses, a foe, a thing, Talk to NPCs
  off; a neutral wanted NPC walked to; an NPC the game relates to a quest wanted, a foe so related not; `/sane key`).
- A `/reload` takes it in.

### Speed Leveling: the guides that come for each game, chosen by a right click; your guide on, paused or off; the satchel's switches (Saneroki, 2026-10-26)
Saneroki: the guide was empty and no guide could be opened or loaded; the guides that come for each game should be
there to choose by a right click on the guide, beside those imported; the minimap's satchel should show its AddOns
section only with buttons in it, the latency home and world on one line, and switch the guide on, off or pause it.
- **Guide packs (`Guide.lua`):** the guides that come for each game are in a pack of their own per game (*Guides:
  Forever*, `SaneUI_GuidesForever`, 105 guides; *Guides: Retail*, `SaneUI_GuidesRetail`, 147 to choose and 116 parts
  of longer ways), made apart from Sane UI's code and put into each game; no guide's text is in this repository. A
  pack's TOC says `X-SaneUI-Guides`, its game and `LoadOnDemand`; Speed Leveling loads its game's pack at the start
  (`Guide.LoadPacks`) and the pack hands over each guide's head and its zlib-packed text
  (`SaneUI.SpeedLeveling.TakeGuides`); they are not kept. A guide added under the same key goes first; a new
  character takes the first default guide of those added, then of the pack in its order. `dev/build` leaves a guide
  pack in the game (not stale).
- **The right-click menu (`Steps.lua`):** a click on a guide there chose it by its name, not its key, so no guide
  could be chosen there. Now by key; the guides for this character by group, each group a menu of its own (its
  subgroups as titles, a long one scrolls), then *All guides, or add one...*.
- **Guides of one name for different characters (`Guide.lua`):** a guide's key is its group, its name and, where its
  head keeps it for some only, for whom (`<< Horde`): 19 of the bought Forever guides came twice under one name (one
  for a choice the guide offers), and the second replaced the first, so they were missing. The guide named next is
  the one for this character (`Find`).
- **Parts and dividers (`Format.Head`):** a guide that is a part of a longer way (reached only as another's next) is
  not listed; a list's divider is no guide (the format's marks, `Core.Neighbours`: `part`, `divider`).
- **The guides window (`Guides.lua`):** the guides under their groups' headings, by title where the head gives one,
  the subgroup after it; a pack's guide has no cross to forget it.
- **Your guide on, paused or off (`SpeedLeveling.lua`, the setting *Your guide*):** paused, the guide holds where it
  is, its view shows its head and a line saying so (a click goes on), and the key and the quest givers leave it;
  what was done meanwhile counts once it goes on. Off: no view, no guide followed. `Guide.Following`.
- **Quick switches (`Core/Switches.lua`, new):** `Core.Offer`, `Core.Switches`, `Core.SwitchChanged`,
  `Core.OnSwitches`: a module offers a switch, a view lists them; Speed Leveling offers *Leveling guide* (a click
  pauses or goes on, a right click chooses on, paused or off).
- **The satchel (`Navigation/Satchel.lua`):** a section *Sane UI* with the modules' switches (on ticked, paused said
  under its name, off faint); the *AddOns* section only while it has a button; the latency *N ms home, N world* on
  one line.
- **Tests:** `dev/tests/navigation.lua` 661 checks (the switches section, its click, paused and off; no AddOns
  section while empty), `dev/tests/speedguide.lua` 104 (paused and off, by the switch and by the view; a pack loaded
  for its game only, its guide listed and chosen in the menu by key and read from it, its part followed next, not
  listed; the window's rows; guides of one name for different characters apart).
- A game restart takes it in (a new file in Core's TOC, the guide packs new addons).

### Speed Leveling's guide: shown with no guide yet, large guides pasted fast, the Retail guides read (Saneroki, 2026-10-26)
Saneroki, after a restart in Retail: the guide was shown nowhere. No guide was kept (the view no longer shows the
other addon's loaded guide, so a guide has to be added once), and the view hid itself without a word.
- **The view's empty state (`Steps.lua`, `Guide.Empty`):** while no guide is followed the view stays, its head and one
  line saying why (none kept, none chosen, or none kept is for this character or this game, as the bought Forever
  guides are in Retail); a click on the line opens *Guides*.
- **Large guides (`Guides.lua`):** the fast paste line (gathered as it comes, a multi-line box so line breaks come
  along) now takes a guide's text as well as an import string; a text whose line breaks did not come through is sent
  to the box below. The free Retail starting-zones file alone is about 1 MB.
- **`.cast unit,spell` (`Format.lua`):** a word before the spell (`vehicle`) is passed over. All 398 free Retail guides
  now read with no unread line (198 for a night elf hunter); the bought Forever guides still read with none.
- **An event Retail lacks** (`LEARNED_SPELL_IN_TAB`) is no longer listened to (`Guide.lua`).
- **Tests:** `dev/tests/speedguide.lua` 85 checks (the empty view, its click, the guides' window built).

### Speed Leveling: the key walks you to the NPC found and uses the step's item on your target (Saneroki, 2026-10-25)
Saneroki asked for the follow-up (board #163): walk to the NPC the key found, and use a step's item on the creature
found.
- **Walking (`Key.lua`, the switch *Walk to the NPC found*, on):** the game's Click-to-Move (`autointeract`) is lent
  only while your target is a living friendly NPC the key wants, so *Interact With Target* runs you to it before it
  talks; it is given back as soon as that is over and as a fight begins, and left alone where the player has it on
  already. The game gives addons no way to walk to a map place, only to a target.
- **An item on the target (`Items.OnTarget`, `Key.lua`, the switch *Use items on what is found*, on):** the step's
  `.use` lines now keep their words (`Format.lua`, `step.uses`; `Run.UseOn`, `Guide.UseOn`, `Guide.Bare`), which
  say what each item is for: on a corpse ("on their corpses"; the corpse of a creature the steps want), or on the
  creature or NPC they name. Out of a fight the key's new button *Use* (`/use item:<ID>`) comes before talking and
  fighting while your target is that one; a friendly target only once it is within the item's reach (the game's
  `IsItemInRange`, looked at three times a second while it waits; out of reach the key walks you there). Never on a
  foe whose words say it must be weakened first, and a cast the game refuses (`UNIT_SPELLCAST_FAILED`, not one
  merely too far) keeps the item off that target. A new driver state, a dead target (`corpse`), carries it.
- **Checked on the real guides:** of 381 `.use` lines with words, 24 speak of corpses and 62 name their target; all
  43 Horde guides ran through the key with targets of every kind, no error.
- **Tests:** `dev/tests/speedleveling.lua` 79 checks (both tests now fail if the module stood down along the way).
- **Docs:** `src/SpeedLeveling/README.md`.

### Speed Leveling: independent of any other addon; it imports the paid guides itself (Saneroki, 2026-10-25)
Saneroki (with the guide authors' leave) asked for the whole function built into Speed Leveling so it needs no other
addon: our own display and engine, able to import, open and run the paid guides, which are locked to the account. He
also reported the module was buggy — active targets showed looted items and gear, some steps would not skip, the
priority order was off — and asked for a logical order: loot around you, then quest givers, then things on the ground,
then enemies.
- **Independent (`src/Core/Neighbours.lua`):** the leveling guide Sane UI knows is no longer used at runtime. Of it,
  Sane UI reads only the words of its text format (`Neighbours.Format`: commands, marks, modes, colours, game tags)
  and the recipe its bought guides are locked by (`Neighbours.Lock`), both as copies. The runtime integration (its
  loaded guide, window, arrow, boxes, targets, items — `Book`/`Targets`/`Uses`/`GoTo`/`Complete`/`Pointing`/`Arrow`/
  `Boxes`/`Menu`/`Frame`) is gone.
- **Opening bought guides (`Unlock.lua`):** a bought guide comes as an import string locked to the buyer's account.
  Sane UI makes the key from the BattleTag of the account played (`BNGetInfo`), in memory and never kept, and opens
  each piece (base64 and zlib are the game's own, `C_EncodingUtil`) over frames (`Core.Steps`); a string bought for
  another account stays shut. Checked offline against the real paid guide: 191 guides open and parse, 15,129 steps
  for a Horde character, no error. No guide's text ships with Sane UI.
- **Our own engine (`Format.lua`, `Lines.lua`, `Run.lua`, `Guide.lua`):** the reader now covers the full command and
  mark set the guides use (61 commands, all the step marks), with game tags and per-character/level conditions;
  `Lines.lua` asks the game what each line's thing is (quests, items, spells, skills, auras, the level, where you
  are); the engine runs steps at hand, tests, places and the next guide. The guides are kept packed for the account,
  read on demand, so the list needs no parse.
- **The key's order (`Key.lua`, `Wanted.lua`, `Quests.lua`):** loot → fight-in-combat → talk → pick up → fight → find,
  the order the game's own gamepad interact button keeps. What is found is ordered NPCs first, then creatures nearest
  first by the zone you are in (the set *Spawns*); a quest Core lacks is found by the game's own objective words.
  Find's macro is chained across hidden buttons for the 255-character limit the game runs. At a quest giver, the
  guide's quests are taken and handed in (`Quests.lua`, the game's gossip and quest-frame functions; Shift held does
  it yourself).
- **The icons (`Icons.lua`):** only an item that can be used is shown (a bag item with a use, the game's quest items),
  never the gear or the loot a step merely mentions — which is why gear and looted items showed before.
- **Tests:** `dev/tests/speedleveling.lua` 60 checks, `dev/tests/speedguide.lua` 80; `dev/tests/encoding.lua` a
  pure-Lua stand-in for the game's bit library and `C_EncodingUtil`.
- **Docs:** `src/SpeedLeveling/README.md`, `src/Core/README.md`, `Doc/ideas/Leveling.md`.

### Speed Leveling's guide: any step at hand ticked off, the list through the whole guide, no blocked actions (Saneroki, 2026-10-25)
Saneroki, in Retail: steps 2 and 14 of the Shadowglen guide could not be skipped; he wants to scroll through every
step, done ones too, and go to one with a right click; and chat said the game blocked an action (the error log:
"the game blocked UNKNOWN()", 2,680 times in three minutes, blamed on Sane UI).
- **Skipping (`Guide.lua`, `src/Core/Neighbours.lua`):** the known guide keeps steps in view before its current step
  (one with a line to tick by hand that goes along up to a named step; one that goes along with the step before it).
  A click now ticks the step off whole, each line by the known guide's own function as the box beside a line does
  (`Neighbours.Complete`, its `SetElementComplete`), whichever step at hand it is; going on past it from its step
  only where it has no such function.
- **The list (`Steps.lua`, `Guide.Picture(count, shift)`, `Neighbours.Book(key, ahead, shift)`):** the wheel scrolls
  it through the whole guide, back to the first step and to the last; done steps (before the step it is at) with the
  game's tick, the steps at hand lighter; it starts after the steps at hand again when the guide moves on. A right
  click on a listed step opens its menu: *Go to step N*, then the known guide's own menu (else the guides kept).
- **No more blocked actions (`Icons.lua`):** the known guide's boxes of targets and items were put into a hidden frame
  of ours; they hold its secure buttons, and in a fight the game blocked their layout under a parent set by Sane UI's
  code. They are left as they are now; Sane UI's own icons stand beside them (they can be switched off in the known
  guide's own settings).
- **Tests:** `dev/tests/speedguide.lua` 148 checks.
- **Docs:** `src/SpeedLeveling/README.md`.

### Installs into Forever and Retail at once (Saneroki, 2026-10-25)
Saneroki, a hard rule: `saneui installdev` and every session's build, commit and install put the build into both
games at the same time.
- **`dev/build`:** `--install` goes into Forever's game folder (`WOW_FOREVER`, default `_forever_`) and Retail's
  (`WOW_RETAIL`, default `_retail_` beside it), both or neither: each must have its `Interface/AddOns` and a
  `.flavor.info` of its own game, or nothing is copied into either and the build says which folder is missing (before,
  whichever game folders were there, and `WOW_FOREVER` named one alone).
- **`dev/saneui`:** `saneui installed` names the build in Forever's and Retail's game, and a game without Sane UI.
- **Docs:** `dev/installdev`, `dev/installrelease`, `Scripts/update`, `README.md`, `Doc/agent/development.md`.

### Nameplates: critters without a plate or a name, a setting shows them (Saneroki, 2026-10-25)
Saneroki asked for critters to have no name or nameplate by default, with a setting to show them.
- **`src/Nameplates/Plate.lua`:** `Plate.Wanted(unit, dress)`: a unit that is no player whose creature type
  (`UnitCreatureType`'s ID) is in `Plate.CRITTERS` (8 Critter, 12 Non-combat Pet, 14 Wild Pet; the client's
  CreatureType table, the same in Forever and Retail) is out of sight as a stranger's plate (the game's unit frame at
  alpha 0, its name with it), unless it is your target or has a quest piece on its dress; a hidden type shows. The quest
  log's events look at every plate anew. A dress that comes back in sight is filled anew (`dress.away`), so a stranger
  or critter you target measures its line while it shows.
- **`src/Nameplates/Nameplates.lua`:** the setting *Plates on critters* (`critters`, off).
- **Tests:** `dev/tests/nameplates.lua` 247 checks.
- **Docs:** `src/Nameplates/README.md`, `Doc/agent/README.md`.

### Speed Leveling: one press talks to the NPC in front of you; a click skips any step at hand (Saneroki, 2026-10-25)
Saneroki, in Retail: the key said "You can't do that" in front of a quest giver, and a click on a step did not skip it.
- **`src/SpeedLeveling/Key.lua`:** a new state after a fight's: `[@softinteract,exists,help,nodead] near`, a living
  friendly NPC the game's interact key would pick; with *Talk to NPCs* on, the key is Interact With Target at once
  (before, an NPC no list named sent the press to Find, whose macro then tried a quest item).
- **`src/SpeedLeveling/Items.lua`:** Find's quest item leaves out one the game says is out of range of what it is for
  (`IsQuestLogSpecialItemInRange` 0); `Items.QuestItems(near)`.
- **`src/SpeedLeveling/Guide.lua`:** the known guide's step at hand may be one that only goes along with the next, both
  shown: a click on either goes past the step clicked (`GoTo(number + 1)`), before only on the step it was at.
- **Tests:** `dev/tests/speedleveling.lua` 96 checks, `dev/tests/speedguide.lua` 139.
- **Docs:** `src/SpeedLeveling/README.md`.

### Speed Leveling's guide: the arrow a part of its own, pictures and words; icons over the guide (Saneroki, 2026-10-25)
Saneroki asked for the arrow and the guide placed apart in Edit Mode, a picture of what to do in the arrow (a speech
bubble to talk, a sword to kill, a bag to loot, a hand to use), words under it read at a glance, and the targets and
items to use as clean icons only, above the guide's top.
- **`src/SpeedLeveling/Arrow.lua`** (new): the arrow as its own part (`Core.Window`, key `arrowPlace`, at first over
  the middle of the screen; the switch *Show the arrow*). In its hole the game's cursor pictures (the largest of each
  sheet, cut past the corner its tip is drawn in): `Guide.Doing` picks talk, kill, loot, use, take, hand in, buy,
  train, inn, hearth, fly or go. Under it the step's first words and *177 yd · 0:25*: the time from the pace you close
  in (measured every 0.5 s, smoothed, none slower than 0.8 yd/s or past a leap of 50 yd/s). The known guide's arrow is
  put away here now.
- **`src/SpeedLeveling/Icons.lua`** (new): a row of Sane UI's own secure buttons over the guide's top, placed by the
  screen: the steps' items in your bags and the game's quest items (type item), then the NPCs and creatures (a macro
  that targets, with the skull); round leather rings (`Art/mark-round`), cooldowns, counts, portraits once seen,
  tooltips; set out of a fight only. The known guide's boxes are put away (`Core.Lend`, a hidden parent) in place of
  being gathered (the switch *Targets and items over the guide* replaces *Gather its targets and items*).
- **`Steps.lua`:** the arrow and the boxes out; `Steps.Frame`. **`Guide.lua`:** `Guide.Doing`; `Guide.Target` gives the
  step there. **`Run.lua`:** `Run.ObjectiveKind`. **`Items.lua`:** `Items.QuestItems` shared.
- **Art:** `assets/optimized/SpeedLeveling/Art/mark-round.blp` (`dev/tools/art` ships both rings to Speed Leveling).
- **Tests:** `dev/tests/speedguide.lua` 137 checks.
- **Docs:** `src/SpeedLeveling/README.md` (*The arrow*, *The icons*), `Doc/guides/interface-style.md`,
  `Doc/ideas/Leveling.md`, the public changelog.

### Speed Leveling's guide: the leather arrow, Expressway, the guide's own menu and boxes (Saneroki, 2026-10-25)
Saneroki asked for the arrow in Sane UI's leather ring with its point, the view's words in Expressway, the next steps
greyed out, the known guide's own menu on a right click, and its boxes of targets and items gathered with the view so
they need no placing.
- **`src/SpeedLeveling/Steps.lua`:** the arrow at the view's top: the far herbs' pointed ring (`Art/mark-pointed`),
  turned every 0.05 s the way to the place (`Run.Way` less the player's facing), its target asked every 0.5 s
  (`Guide.Target`), what waits there in its hole (the game's quest signs, else a map), its yards under it, out of sight
  within the place's reach. All words in Expressway (`Fonts/Expressway.ttf`), outlined, the game's font where it cannot
  be set; ticks are the game's ready-check tick (the font has no root sign). The next steps grey, their colours taken
  out. A right click on the zone or the next steps opens the known guide's own menu while its guide is shown. While
  ours points to its place, the known guide's arrow is put into a hidden frame (`Core.Lend`); its boxes are placed in
  a row under the view by the screen, out of a fight only (the switch *Gather its targets and items*). At first at the
  screen's right, anchored by its top.
- **`src/SpeedLeveling/Run.lua`:** `Run.Way` (yards and the bearing, for both kinds of place), `Run.Target` (the first
  place of the steps at hand not yet passed; points on the way passed within their reach). **`Guide.lua`:**
  `Guide.Target`, `Guide.Menu`; a line's command in our word in the picture.
- **`src/Core/Neighbours.lua`:** `Neighbours.Pointing`, `Arrow`, `Boxes`, `Menu`; `book.place`; a line's `what`.
- **Art and font:** `assets/optimized/SpeedLeveling/Art/mark-pointed.blp` (the pointed ring, `dev/tools/art` ships it
  to Speed Leveling too), `assets/fonts/Expressway/` and `assets/optimized/SpeedLeveling/Fonts/Expressway.ttf`.
- **Tests:** `dev/tests/speedguide.lua` 122 checks (18 new).
- **Docs:** `src/SpeedLeveling/README.md`, `src/Core/README.md`, `Doc/guides/interface-style.md` (*The leveling
  guide over the world*), `Doc/ideas/Leveling.md`, the public changelog.

### Speed Leveling: your leveling guide over the world (Saneroki, 2026-10-25)
Saneroki asked for his leveling guide in Speed Leveling, over the world without a window, in Sane UI's own style:
the guide the leveling guide Sane UI knows has loaded, while it is loaded, else guides pasted as text in its format
(its import strings are locked to the buyer's account and are never read).
- **`src/SpeedLeveling/Format.lua`** (new): a guide written as text read into our own shape for one character: its
  head, steps, lines kept or left out for side, race and class (`Format.For`), each command into a line to do, words,
  a place, a test that passes a step by, or names and items for the key; long brackets of a Lua file split into
  guides (`Format.Parts`). The format's own words are Core's (`Core.Neighbours.Format`).
- **`src/SpeedLeveling/Run.lua`** (new): a pasted guide run per character (`Core.Character`): the step you are at,
  the steps at hand (those that stay, those that go along with the next or up to a named one), each line done as the
  game tells it (quests, objectives, items, level, spells, zone and subzone, places by distance, home, hearth, flight
  path, flight, vendor, trainer, spirit healer, a cast), tests that pass a step by, skip, back and go (held there),
  the next guide when through.
- **`src/SpeedLeveling/Guide.lua`** (new): the guide shown: the known guide's loaded guide while it is loaded (its
  switch), else the pasted one; one picture for the view, names in the game's font colours, the guides kept as text
  (`Core.Store`), the events that move a pasted guide on, a look at the known guide every half second while it is
  loaded (told only when it changed). The key's names and items come from it (`Wanted.lua`, `Key.lua`).
- **`src/SpeedLeveling/Steps.lua`** (new): the guide over the world, in Kalam with a dark outline: zone, levels and
  how far, the steps at hand on faint shades (what to do large, counts with thin bars, ticks, notes), the next steps
  fading; click skips, right click goes back, the wheel scrolls, a double click goes to a step, a right click on the
  zone opens the guides' menu; placed in Edit Mode (`Core.Window`). The known guide's own window lent see-through
  and small (`Core.Lend`) while its guide is shown here.
- **`src/SpeedLeveling/Guides.lua`** (new): the window of the guides kept as text (`/sane guides`): the list, a box to
  paste into, *Read*.
- **`src/Core/Neighbours.lua`:** `Neighbours.Book`, `GoTo`, `Frame` and `Format`: the known guide's loaded guide as
  plain copies, its step function, its window, its text format's words by ours.
- **Switches:** *Show the guide*, *Your leveling guide's own guide*, *Hide its own window*, *Steps listed ahead*, the
  button *Guides*; *Your leveling guide's targets* now means the guide shown.
- **Tests:** `dev/tests/speedguide.lua` (new), 104 checks; `dev/tests/speedleveling.lua` 94. The shipped guides of
  the known guide read with no problem for either side (checked outside the project).
- **Docs:** `src/SpeedLeveling/README.md`, `src/Core/README.md`, `Doc/ideas/Leveling.md`, `Doc/agent/README.md`, the
  public changelog.

### Navigation: the satchel's zone and clock (Saneroki, 2026-10-25)
Saneroki asked for the minimap's other parts in the satchel too: the calendar, the zone's name, the local and the
server's time, the frame rate, the local and world latency, the time of day, and the game's timer, stopwatch and alarm.
- **`src/Navigation/Satchel.lua`:** a first section: its title the zone and subzone in the game's minimap colours
  (`Satchel.ZONE`), its lines (`Lines`: local and realm time, frame rate, latency home and world, the time of day in
  Forever, new mail with its senders, the calendar's invitations), looked at every `Satchel.EVERY` second while open;
  its cells (`Tools`): *Calendar* (a secure button of ours on `UIParent` clicks the game's `GameTimeFrame`, `Cover`,
  out of a fight only), *Clock* (`TimeManager_Toggle`; while the alarm sounds, `TimeManager_TurnOffAlarm`),
  *Stopwatch* (`Stopwatch_Toggle`), each ticked while open.
- **Tests:** `dev/tests/navigation.lua` 654 checks (the zone and its colour, the lines, the three cells, the
  calendar's secure button, the stopwatch, the alarm stopped, the clock's window); the lab's scene `satchel` with
  stand-ins for the game's clock and calendar.

### Navigation: the satchel's addons round (Saneroki, 2026-10-25)
Saneroki asked for the addons' pictures without the golden ring round them, always round.
- **`src/Navigation/Strays.lua`:** a held button lies unseen (alpha 0, kept and given back; a hook after its
  `SetAlpha` keeps it so) over the picture the satchel draws of it; `Strays.Picture` finds that picture (its largest
  `ARTWORK` texture, else its normal texture).
- **`src/Navigation/Satchel.lua`:** an addon's picture cut round (`Satchel.ROUND`), cut inside its frame where it
  shows its whole file (`Satchel.TRIM`); the compartment's addons too.
- **Tests:** `dev/tests/navigation.lua` 647 checks (the round picture, the button unseen and seen again when given
  back).

### Navigation: the satchel's addons twice as large (Saneroki, 2026-10-25)
- **`src/Navigation/Satchel.lua`:** the section AddOns has pictures of 56 (twice the pins' and tracking's 28) in rows
  84 high (`Satchel.ADDON`); each section its own picture size and row height. Test updated.

### Navigation: the satchel compact (Saneroki, 2026-10-25)
Saneroki asked for a more compact satchel without the pencil slots behind its pictures.
- **`src/Navigation/Satchel.lua`:** six columns of cells 72 by 58 (were five of 88 by 78), pictures of 28 on the paper
  as they are (`Journal.Slot` gone), smaller words and titles, less room between the sections and none under the last.

### Navigation: the satchel and the middle click (Saneroki, 2026-10-25)
Saneroki asked for a middle click that centres the map on the player at a zoom where the minimap's icons show, and
for one button on the minimap that gathers the addon buttons usually placed round it and the pins to choose, in a
big, easily selectable way.
- **`src/Navigation/Canvas.lua`, `Hybrid.lua`:** the middle button (`Canvas.Home`): following again, on the player;
  the small view at the game's step `Hybrid.HOME` (2), the full map where that step's square takes `Hybrid.ROOM` of
  it (`Hybrid.Home`), `Canvas.HOME` yards across where the game's minimap is not ours. `Hybrid.Release` gives a frame
  of the cluster its clicks back; `Hybrid.Update` tells `Strays.Update` after it takes or gives the minimap.
- **`src/Navigation/Strays.lua`** (new): other addons' buttons on the minimap, its backdrop and cluster, told apart
  from the game's own by `issecurevariable` on their global name, held while our window is the minimap (parent,
  points, scale, strata, level kept; a hook after `SetPoint` keeps them in their cell), given back with the minimap
  or at a stand-down; the game's addon compartment's addons, called behind `pcall`.
- **`src/Navigation/Satchel.lua`** (new): the button on the small map (the leather ring, a satchel's icon) and its
  page in Core's journal: AddOns, Pins (`ns.SwitchPin`, now shared with the pin filter, `TopBar.lua`), Tracking (the
  game's tracking menu's entries, not Find Herbs and Find Minerals). `Window.lua` shows it only small and as the
  minimap; `Canvas.LEVELS.satchel`.
- **Tests:** `dev/tests/navigation.lua` 645 checks (20 new), Retail 26; the lab's scene `satchel`
  (`dev/uilab/scenes/satchel.lua`, `Doc/guides/ui-lab.md`).
- **Docs:** `src/Navigation/README.md`, `Doc/ideas/Navigation.md` (decision *The satchel and the middle click*),
  `Doc/agent/navigation.md`, the public changelog.

### Navigation in Retail: the Cosmic map's highlight (Saneroki, 2026-10-25)
The world under the mouse on Retail's Cosmic map lit up as a corner of its picture, blown up. Its highlight is a
piece of an atlas (`worldmap-highlight-cosmic-azeroth` and the other worlds; also Argus' three maps and the Broken
Isles; Forever has none), and a `SetTexCoord` after `SetAtlas` cuts within the piece, not within the file: the
piece's own coordinates set again took its top left part.
- **`src/Navigation/Art.lua`** (`Art.Light`): the texture placed first, the atlas set last with its coordinates
  reset (`SetAtlas(atlas, false, "TRILINEAR", true)`), as Blizzard's highlight pin sets it.
- **Tests:** `dev/tests/navigation.lua` (Retail, 26 checks): the Cosmic map's highlight is its atlas piece whole, at
  the atlas' size.

### Navigation in Retail: the game's own maps, one at a time (Saneroki, 2026-10-25)
Saneroki: Forever keeps our own map (our tiles, Scrying, the Atlas, one world to roam); Retail's map shows the game's
own map tree as its own map does, in our window with our pins (option 1 of two; `Doc/ideas/Navigation.md`, *Forever's
own world, Retail's own maps*).
- **`src/Navigation/Camera.Retail.lua`** (read in Retail alone): the camera shows one map (`camera.shown`), whole at
  first; the wheel within it up to its art's largest scale (or `Camera.DEEP` units to a pixel of its art); a click
  into the map the game says is under the mouse (`camera:Under`), a right click up to the map over it (zone,
  continent, Azeroth, the Cosmic map); following, the map the player is on (`Camera.Wanted`); the art's layer by the
  zoom (`camera.layer`). Retail's two answers of the map tree: a map in another world than its continent's is a plane
  of its own (`Coords.PlaneOf`), the Cosmic map a sheet (`Coords.Box`, `Coords.SHEET`).
- **Shared, the same in Forever:** cameras have their own nearest zoom (`camera:Nearest`, Hybrid asks it); `Art.Of`
  takes a layer, `Art.Layers`; the canvas, the art, the pins, the quest areas and the map selector follow the map
  shown where the camera has one (`view.shown`, `view.box`, `view.layer`); `Coords.COSMIC`, `Coords.WORLD`.
- **Tests:** `dev/tests/navigation.lua` runs again as a Retail client from the start (`retail`, 25 checks: the tree's
  answers, following, right clicks up to the Cosmic map, clicks back in, the zoom's limits and layers, the pins of
  the map shown, the full map's first look).

### Sane UI works in Retail: every module gone through (Saneroki, 2026-10-25)
Sane UI's first run in Retail failed in places, and stood down where it should not: Combat's own talents (Forever's
two talent groups, `TabSystemButtonMixin:UpdateTabText`) took the whole module down, Abilities' scan asked for
Forever's spell ranks, and Sync wrote the game settings kept in Forever into Retail. Every module was gone through
against Retail's export (the Forever-Retail lookup, `uses.md`); what both games share works in both, what needs
Forever's systems or data stands down in Retail without a word, and Forever is unchanged.
- **Core:** Sync's kept game settings belong to the game they were read in (`Sync.options.from`, those kept before
  Forever's): another game's are neither written nor handed out (`Sync.Taken`), and replaced at the next reading.
  The data framework notes no missing set where the game version has no set at all (Retail, until Data: Retail).
  `Core.Inspect.Talents` gives Retail's specialization without points. The bar's dividers: a thin line of ours where
  the client lacks their atlas (Retail).
- **Abilities:** the scan asks for low ranks only where the game has them; Forever's trainer data, weapon skills
  and skill lines load in Forever only (`[ExcludeLoadGameType standard]`); in Retail the spellbook's pages, Home,
  the window, the trainer's reading, their switches, menu lines and commands are not there; the reservations, their
  icons and the saved layouts work in both.
- **Combat:** its own spellbook and talents are Forever's (`ns.Serves`, by the functions they need): in Retail
  neither is there, the game's keys and windows stay the game's, no full screen at the bottom edge, and the module
  keeps the quest marks on nameplates (its one setting there).
- **Inventory:** the rows' coloured bar is ours where the game has no `ColoredProgressBarTemplate` (`Rows.Bar`:
  reputation, currency, statistics); the stats page takes Retail's categories and its hide values, without
  resistances and the pet's stats; Skills and PvP register only where their systems are; Retail's icons for the
  side tabs; the level line shows the specialization in Retail.
- **Social and Guild:** the Group finder tab and its switch stand down where Retail's finder (`PVEFrame`) is, and
  its entry in *Classic windows* opens Retail's; Battle.net blocking through `BNSetBlocked` in Retail; the friends
  list also as the game's newer social window; *Extend Raid Lock* where the game has it; the guild's paper doll
  without a ranged slot where the game shows none.
- **Navigation:** Scrying and Blended only where Core's terrain is: in Retail the map is Parchment, the game's own
  map art, and the small view keeps the game's minimap ground; pins, switches and views that need Core's data or
  Forever's minimap answers stand down; the game's minimap gets its round mask back where no code of the game sets
  one; Retail's tracking holds both finders at once; the continents beside Retail's world map are in the map
  selector. Forever's outlines and coasts load in Forever only.
- **Tooltips, Nameplates, Speed Leveling:** the class line shows Retail's specialization; no kill-experience row in
  Retail (its rule is Forever's); combo points on the target's plate only in Retail (up to seven); Speed Leveling
  finds without quest data what the game marks.
- **Tests in Retail (#137):** `W.Play("retail")` makes the tests' stand-in a Retail client: Core told, and everything
  Retail lacks of Forever's taken away (`dev/tests/games.lua`, made by `dev/tools/blizzard games` with the lookup:
  globals, `C_X.Function`, `Enum` and `Constants` entries, events; a global Forever defines in Lua that Retail's code
  calls is the client's own there); `W.Play("forever")` gives it back. Every module's test checks its Retail path.
- **Docs:** `Doc/guides/addon-standards.md` (*Tested in both*, *Kept settings of one game*),
  `Doc/guides/blizzard-updates.md` (the stand-in's list; a file for one game: `standard` only), the modules'
  READMEs (*Forever and Retail*).

### Sane UI in Forever and Retail; our own patch notes after every patch (Saneroki, 2026-10-25)
- **One code for both games** (Saneroki: development aimed at Forever, Retail compatible, its data later). Core knows
  the game: `Core.GAME` (`forever`, `retail`), `Core.FOREVER`, `Core.RETAIL`, `Core.ForGame({ forever = a, retail = b })`,
  `Core.TellGame()` (told as Core is read; again by the tests). `Data.Game()` answers `retail`, `retail-beta` and
  `retail-ptr` too; `assets/data/builds.toml` has `[retail]` (no data yet), so Core refuses Forever's sets in Retail
  and a Retail copy of Core carries none. Wire signs for Retail's game versions.
- **A module for one game:** `## X-SaneUI-Games: forever` in its TOC (`Core.ServesGame`): in the other game it is off
  from the start (`module.elsewhere`), without a word and without an options page. The Atlas is Forever's
  (its painted world); Navigation does not offer its view in Retail (`Painted.Find`).
- **Every TOC:** `## Interface: 16001, 120105`. A file line for one game: `[AllowLoadGameType standard]` (Retail's)
  or `[ExcludeLoadGameType standard]` (Forever's), the only two `dev/tests/lint` allows; the tests' stub
  (`W.Allowed`) and the lab read them as the game does. `dev/tools/blizzard check` checks each game's number.
- **`dev/build` installs into Retail's folder too** (product `wow` is the game version `retail` in
  `dev/data/compile.py`): Core without sets there, a module of the other game left out and taken out. The beta's
  `_classic_beta_` is gone from the words of `dev/build` and `dev/tools/errors`.
- **After a patch:** `saneui readpatch` (`dev/tools/blizzard patch [forever|retail] [--again] [--no-card]`): a game
  whose installed build is newer than its newest export is exported (the settings' `extract`), and its new export
  against the one before written as our own patch notes (`notes.md`: Blizzard's addons, the API by namespace,
  events, widgets, enums, structures, CVars, templates, Lua, code files and art), the tables of every change, Sane
  UI's todo list (`todo.md`) and the brief of the session that fixes it (`session.md`), with a card on the board;
  the Forever-Retail lookup made anew. `saneui fixpatch` starts Claude Code on the newest brief (`--print`: the
  prompt). New `dev/blizzard/patch.py`; `games.py` names its two sides. Settings in `~/.config/saneui/blizzard.json`:
  `install`, `extract`, `reports`. `Doc/guides/blizzard-updates.md`, *After a patch*.
- **The rules:** `Doc/guides/addon-standards.md`, *13. Forever and Retail* (look a name up first, one way for both,
  what one game lacks stands down, overrides, files and modules of one game, data per game), with a checklist line.
- Tests: Core 394 checks, data in the game 269, Navigation 601, blizzard 91, saneui 257.

### dev: Blizzard's code of Forever and Retail side by side (Saneroki, 2026-10-25)
- Sane UI is to work in Forever and Retail (Saneroki). `dev/blizzard/export.py` knows both games (`GAMES`, `CLIENTS`):
  `newest()` and `required()` are Forever's newest export unless asked for Retail's (`newest("code", "retail")`),
  so Retail's higher version numbers (12.x) never take Forever's place in the lab, `adopt` and the art tools. An
  export is read as its own client loads it (Forever: `camelot` and `mainline`, `[Game]` Camelot; Retail: `standard`
  and `mainline`, `[Game]` Standard); TOC names are matched without regard to capitals.
- `dev/tools/blizzard games [--out FOLDER]` (new `dev/blizzard/games.py`): lookup tables of where the two games
  differ: `symbols.tsv`, `files.tsv`, `addons.tsv`, `art.tsv`, `art-folders.tsv`, a `README.md` of counts, and
  `uses.md`, what of Sane UI's own uses Retail lacks or calls differently. `check` and `show` take `--retail`
  (`show C_ActionBar.FindSpellActionButtons --retail`); `where` names both games' newest exports.
  `Doc/guides/blizzard-updates.md`, *Forever and Retail*. `dev/tests/blizzard.py`: 82 checks.

### dev: long documents read by their sections (Saneroki, 2026-10-25)
- `dev/tools/doc-sections` (`saneui showsections FILE`): a Markdown file's headings with their lines and size in tokens
  (about); `saneui showsections FILE words` prints the sections whose heading holds those words, with their
  subsections. A chat reads a guide of 20k tokens by the part it needs.
- `Doc/agent/README.md`, *Read as little as needed*, names it.

### Speed Leveling: NPCs found before creatures (Saneroki, 2026-10-25)
- `Wanted.Names()`: the guide's NPCs and the NPCs your finished quests go to come before every creature (the guide's,
  the quests', those the game marks on nameplates), so Find targets a quest giver or taker around you first.
  `dev/tests/speedleveling.lua` follows (91 checks).

### Speed Leveling: loot only opened; quest objects, the hearth and quest items (Saneroki, 2026-10-25)
- **Loot opened, not taken** (Saneroki asked): the key's loot step is the game's Interact With Target alone, as a right
  click on the corpse; the game's auto loot (`autoLootDefault`) is no longer switched on. How and what is looted is
  the loot module's to come.
- **Quest objects** (new switch, on): `Wanted.Object(guid)`, the things of the world your quests want by object ID
  (open objectives of kind `object`, the `object:` sources of an item to loot in *Drops*, the `finishObjects` of a
  finished quest of your side), on any client. `Key.lua` keeps the interact key's thing from
  `PLAYER_SOFT_INTERACT_CHANGED` and sets the header's attribute `object`; the snippet then puts `INTERACTTARGET` on
  the keys, after loot and a fight's foe, before a wanted foe and an NPC. The interact key stays on while this or Loot
  first is on.
- **Hearth and items** (new `Items.lua`, switches *Hearthstone* and *Quest items*, on): Find's macro (`Key.Find`) is
  `/use item:6948` alone when the guide's step lists the Hearthstone (a shaman's Astral Recall, 556, while it cools
  down); else its targeting lines end with `/stopmacro [exists]` and `/use item:<ID>`, the first ready item (in your
  bags, `C_Item.IsUsableItem`, off its `C_Container.GetItemCooldown`) of the guide's step's items and of the quest
  log's own (`GetQuestLogSpecialItemInfo`, quests not yet done). As a fight begins (`PLAYER_REGEN_DISABLED`) the
  macro is written without either.
- Core: `Neighbours.Uses(key)`, a known guide's steps' items and spells to use, by ID (`KNOWN.guide.items`, `spells`).
- Tests: `dev/tests/speedleveling.lua` 91 checks (objects and the soft target, the hearth, the items, the switches).

### Speed Leveling: one key for questing (Saneroki, 2026-10-25)
- **New module** `SaneUI_SpeedLeveling` (Saneroki asked for it): one key (the game's key bindings, under Sane UI),
  pressed again and again: it loots the corpse beside you, finds what your quests and your leveling guide want around
  you, marks it with a skull, and attacks it or talks to it. Looting without a press is not possible: the game lets an
  addon interact with a corpse, target and attack only by its secure ways on the player's key press.
- `Key.lua`: a secure state driver reads the macro conditions (`[@softinteract,exists,dead]` loot, a living foe in a
  fight, a living foe, a living friend, else find); the header (`SecureHandlerAttributeTemplate`) puts that mode's
  action on the key's keys as override bindings above the others: the game's `INTERACTTARGET` to loot or talk, the
  button Fight (`/tm [harm,nodead] !8`, `/startattack`), or the button Find. A foe or friend counts only when the
  module says it is wanted (the attribute `wanted`, set out of a fight); in a fight every living foe is fought. Find's
  macro (`/cleartarget`, `/targetexact [noexists][dead] <name>` per name, up to 1023 characters, `/tm [exists] !8`,
  `/startattack`) is written out of a fight, before each press (`PreClick`) and when the quests change. *Loot first*
  switches on the game's interact key and auto loot (`softTargetInteract`, `autoLootDefault`), kept and put back.
- `Wanted.lua`: the names, in order: the guide's step (creatures, then NPCs), the quests' open objectives from Core's
  sets Quests, NPCs and Drops (to kill, then the three likeliest droppers of an item to loot), creatures the game marks
  for a quest on nameplates (`Core.UnitQuest`), the NPCs your finished quests go to (of your side). Core's English
  names on an English client only.
- Core: `Neighbours.Targets(key)`, what the step at hand of a known leveling guide wants (`"guide"`, Saneroki,
  2026-10-25), two lists of names.
- Tests: `dev/tests/speedleveling.lua` 60 checks (the header's snippets run as the game runs them).

### Navigation: the found herbs' and ore's pictures without square edges in the ring (Saneroki, 2026-10-25)
- `Found.lua`: an item's picture is cut 12 % in at each side (`Found.TRIM`, was 7 %: the icon's frame is 4 of 64
  texels, a darker band follows), and `Found.Ring` makes it `Found.FILL` (1.16) times as wide as the ring's hole, so the
  round mask's edge lies under the leather; the ring is sized from the hole (`side` is the hole's width now), as large
  as before. `Glints.lua` (`Glints.ICON` 32, the hole's width) and the lab scene follow.

### Navigation: the far herbs' and ore's yards as a bare number under the ring (Saneroki, 2026-10-25)
- `Glints.lua`: the distance is the number alone (`%d`, no longer the game's `IN_GAME_NAVIGATION_RANGE` with *yds*),
  `GameFontHighlight` at `Glints.TEXT` with an outline, under the ring, and under its point while that points down
  (`Glints.TIP`, the tip's distance from the middle in the picture's side). Centred in the ring over the picture came
  first, the same day. The setting's tip said "a gold ring": a ring of stitched leather now.
- Tests: `dev/tests/navigation.lua` 600 checks (the marks found by their numbers; the yards under a downward point).

### Navigation: the found herbs and ore in a leather ring, pointed in the world and round on the minimap (Saneroki, 2026-10-25)
- **The pick:** of eight rings rendered (`dev/imagegen/sets/far-marks/rings.txt`: five gold, leather, pencil, parchment;
  Qwen 2.1 turbo from words, transparent) Saneroki took the leather one, kept as
  `assets/interface/far-marks/leather-ring.png`, and asked for a perfectly round version too.
- **`dev/tools/mark-art`** (new, `saneui makemarkart`): finds the middle of the ring's hole (a circle fitted to its
  edge) and lays the picked ring round it on a canvas of 1040 (`assets/FarMarks/ring-pointed.png`); unrolls the ring
  round that middle, takes the rows within `POINT` degrees of the top from the opposite side (blended over `BLEND`),
  stretches every row so its edges lie on the two circles of the ring's bottom and rolls it up again
  (`assets/FarMarks/ring-round.png`). Prints the hole's and the ring's radius for the code.
- **`dev/tools/art`:** the kind `mark` (drawn 70 x 70, 256 x 256), kept whole instead of cropped (a kind's fourth
  value), so the hole's middle stays the texture's; `assets/optimized/Navigation/Art/mark-pointed.blp`,
  `mark-round.blp` (Git LFS, with their sources).
- **The marks** (`Glints.lua`): the picture (`Glints.ICON`) in the pointed ring, the ring turned by `SetRotation(-way)`
  about the hole's middle; the yards on the side away from the point. The two slices of the minimap's gold ring are
  gone.
- **The minimap's found ones** (`Found.lua`): the round leather ring in place of the game's tracking ring
  (`Found.RING`, `Found.HOLE`, `Found.OUTER`; `Found.Ring` lays it so the hole holds the picture, its edge under the
  leather); `Found.Round` takes off the item picture's own dark frame (`Found.TRIM`) and makes it round, for both.
- The interface lab's scene `far-sparkles` has a minimap's stand-in with the three found ones on it.
- Tests: `dev/tests/navigation.lua` 599 checks (the ring's turn ahead, ahead-right, behind-left).

### Navigation: far herbs and ore as their pictures, the ring running out into a point (Saneroki, 2026-10-25)
- **The look** (`Glints.lua`): no column and no sparkles; each mark is the item's picture, round
  (`TempPortraitAlphaMask`), in the minimap pictures' gold ring (`Found.Ring`, new, shared with `Found.lua`'s
  pictures; `Found.RING`), `Glints.ICON` wide (down to `Glints.SMALL` far off), the ring running out into a point the
  way to the node from the facing (`Point`; `way` = `atan2(across, ahead)`: up ahead, down behind): two slices across
  the ring's band in its own art (`SLICE`, `Glints.BAND` measured from the art), each laid by `Lay` from where a line
  from the tip (`Glints.TIP`) touches the band's middle to the tip, turned with `SetRotation`. The yards under the
  ring. Edge marks the same, without the game's arrow. The setting is called *Far herbs and ore on the screen*
  (`nodeGlints`). A flat V of gold lines came first, the same day.
- **One cohesive ring, rendered:** `dev/imagegen/sets/far-marks/rings.txt` (Qwen 2.1 turbo from words; with the first
  build as image 1 the edit model copied its two bars), five in gold, one each in leather, pencil and parchment, under
  `assets/generated/far-marks/`; Saneroki's pick is to replace the ring and its slices.
- **The interface lab:** the scene `far-sparkles` (`dev/uilab/scenes/far-sparkles.lua`): Core from its TOC, the rest of
  Navigation standing in, `Found.lua` and `Glints.lua` as they are, a Peacebloom, an Earthroot and a Copper Vein
  found, over a local screenshot of the world (`assets/generated/ui-lab/backdrops/`). The lab reads the game's plural
  code `|4one:many` without its closing `;` too, as the game's `IN_GAME_NAVIGATION_RANGE` has it
  (`dev/uilab/lab/text.lua`), and turns a region drawn with mirrored texture coordinates as the game does: the mirror
  inside the turn (`dev/uilab/web/lab.js`).
- Tests: `dev/tests/navigation.lua` 599 checks (the point ahead, ahead-right, behind-left).

### Navigation: far sparkles, the found herbs and ore marked on the screen however far (Saneroki, 2026-10-25)
- **What** (`Glints.lua`, new; the setting *Sparkles on far herbs and ore*, `nodeGlints`, on at first): each herb and
  ore the minimap found (`Found.Each`, new) beyond `Glints.NEAR` yards marked in its direction: a column of gold (two
  gradients, added light) with `Glints.SPARKS` of the game's `star4` drifting up it, the item's picture (grey while
  the skill is too low, `Nodes.TooHard`) and its yards (the game's `IN_GAME_NAVIGATION_RANGE`) under it; the nearest
  `Glints.MOST`. One outside the view at the left or right edge, the side one would turn to, stacked from the middle
  down, the game's `Navigation-Tracked-Arrow` turned to point out.
- **Roughly placed, never the map pin** (Saneroki): a camera of our own (`Project`): behind the player at
  `GetCameraZoom`, looking the way of `GetPlayerFacing`, `Glints.PITCH` down about `Glints.PIVOT` yards over the
  feet, its height's angle from `cameraFov` taken across a 16:9 screen (`Scale`); a place at the player's height.
  The marks wait (`Behind`) while the left button, held `Glints.HOLD` seconds with the mouse on the world, turns the
  camera, until the right button is down or the player has moved `Glints.SETTLE` seconds.
- A frame on `UIParent` at the `BACKGROUND` strata, its `OnUpdate` only while the setting is on; hidden when the
  module stands down (`Glints.Hide`).
- Tests: `dev/tests/navigation.lua` 599 checks (one ahead in the middle, one right of it, one behind at the left edge
  with the arrow, a near one left to the close sparkles, the left button's turn ended by moving or by the right
  button, a short click, the setting).

### Data: the database made better by play: checked field by field, counted, harvested (Saneroki, 2026-10-24)
- **Checked in play** (`Data/Check.lua`, `Data.Check(set, key, told)`): what the game shows of an entry compared with
  the set field by field. What agrees is confirmed as a part (a field `name`, a member `startNPCs=69`, a map's key
  `health=12`) and shared like any confirmation; the whole entry once every field of its schema's new `play` list was
  told. What differs, or an entry the set lacks (a quest or creature only Forever has), is learned with the parts the
  game told (`Confirmations.Told`), never taking a member away. Texts only on an English client.
- **The quest watchers** (`Data/Quests.lua`): offered (title, giver, thing or starting item, rewards: items, choices,
  money, experience, a spell), taken (level, group, daily, the log's objectives), worked on (the creature an
  objective asks for from the dead target its text names, the item from the loot, where the count went up),
  handed in (the taker, experience and money; the quest offered at once after it by the same NPC its `next`).
  Requirements narrowed by an offer to the player's own character (a lower level, a race, class or side, a quest not
  done first), never by a quest a player shared. Experience and money only where they are whole. The old whole-quest
  confirmation at `QUEST_ACCEPTED` is gone (it marked givers, rewards and requirements verified unseen).
- **Counted in play** (`Data/Tally.lua`, `Data.Tally`): per build a block with a random id in `SaneUIData_Learned`
  (`tally`, and `maps` with their sizes in yards): loots and what they gave, places seen from up close merged by
  `Tally.MERGE` yards (one visit per `Tally.VISIT`), cells of the map. Bounded (`Tally.BUILDS`, `KEYS`, `RECORDS`).
- **Every loot window** (`Data/Loot.lua`) by the game's own source of each slot (`GetLootSourceInfo`; without it
  nothing, `Loot.blind`, said by `/sane data`): each corpse once, skinning and gathering from a corpse after its cast,
  Pick Pocket, nodes and chests for each cast, fishing for the zone, a quest's item for those on the quest; the
  corpse's cell, the node's point.
- **Creatures, services, vendors, spells, tooltips** (`Data/Facts.lua`): creatures out of a fight (name, levels
  widened, rank, kind, health at a level; never a pet or totem), the services of the NPC talked to, vendors' goods
  (not prices), the spellbook's and tooltips' spells (name, rank, icon), the tooltips' items.
- **Spawns point by point** (`Watchers.lua`): the point stood near confirmed (`p` and `Watchers.Code`), the whole
  once all were; a creature or thing talked to is a sighting of its place.
- **The master:** `play` lists for Quests, NPCs, Spells and Vendors (`dev/data/schema.py`: whole, `x.part`, `x[]`,
  `x{}`, `?`), written into the set files' headers; **an entry is verified only when each of its fields was last
  written or confirmed by the game** (`compile.trusted`; no entry's mark changed today).
- **The harvest** (`dev/data/harvest.py`, `dev/data/play.py`): learned rows staged with only what the game told;
  confirmations whole over all saved files; `--from` for WTF folders and saved files players send; the ledger
  (outside the project where `~/.config/saneui/private.json` points) adds every block up once and stages Drops
  (every way looted 50 times, chances from 3 drops, the change between builds, our rare items kept, common ones
  gone, again once the loots grew by half), Spawns (points narrowed, new ones, once every point of ours was seen) and
  areas (Spawns, CreatureSpawns, QuestAreas, where our data has none).
- Confirmations of an entry a release verified are dropped at the login. `/sane data` says what play counted.
- Tests: `dev/tests/data.lua` 267 checks (quests offered, taken, worked on, handed in, narrowed, shared; a quest only
  Forever has; loot of every way; places merged; spawns point by point; creatures, vendors, spells),
  `dev/tests/data/tools.py` 235 (the play list, the per-field mark, the harvest's told fields, the ledger taking a
  block once and its growth, Drops, Spawns, areas).

### dev: one menu on every tool page; the pages dark (Saneroki, 2026-10-24)
- **The menu:** a ☰ button on every tool page (interface pieces, concept history, maps compared, instance maps, world
  map, interface lab, task board) opens the list of them all, each with its port and a dot for whether it is up,
  the page you are on marked; Alt+M opens and closes it, Esc closes it. One script, `dev/tools/web-nav.js` (in a
  shadow root, so no page's styles reach it), stands before the page's title in its header bar, or in the top left
  corner where a page has none. Every tool's server sends it as `/web-nav.js` with the list filled in from
  `dev/tools/web-pages` (`web-pages nav`; `pages.json` gets an optional `path`, the concept history's
  `/concept-history/`).
- **Folders:** `web-pages folder PORT DIR` serves a folder as it is and puts the menu into each HTML page it sends,
  so the interface pieces and the concept history get it without their generators changing; `web-pages run` and
  `.claude/launch.json` use it in place of `python -m http.server`.
- **Dark:** the menu sets the browser's dark controls and scrollbars on every page; the task board opens dark (its
  ◐ button still switches to light, kept per browser).

### dev: the task board, every todo a card from Backlog to Finalized (Saneroki, 2026-10-23)
- **`dev/tools/board`** (`saneui board`, `saneui showboard`): one board in the private folder (`board.json`, set by
  `~/.config/saneui/private.json`), columns Backlog, Next up, In progress, Review (built, to try in the game) and
  Finalized; a card has a title, notes, priority (high, medium, low), area, who changed it last and a log of its
  steps. Every change, from the page or the command line, goes through one locked write and writes `Backlog.md`
  beside it as text. `import` reads a ranked Markdown list (`##` priority, `###` area, `- [ ]` items).
- **The page** (`dev/tools/board-page/index.html`, 127.0.0.1 port 8775, in `saneui webpages` and
  `.claude/launch.json`): cards dragged by pointer (mouse and touch, a line where it lands, the lists and board
  scrolled at their edges), quick add at a column's top (Enter adds, the priority beside it), a card's editor
  (title, notes, priority, column, area, its log, delete), search, filters by priority and area, sorting a column
  by priority, light and dark; it asks the server every 1.5 seconds, so a session's changes show by themselves,
  briefly lit.
- Tests: `dev/tests/board.py` 19 checks.

### Art: ComfyUI's window shows every job, templates and apps of ours; test pictures out of the repository (Saneroki, 2026-10-23)
- **Every job a workflow in ComfyUI:** `Server.queue` (`dev/tools/imagegen`, used by the Atlas and the map layers too)
  sends each job's graph in the canvas' form beside the API form (`ui_workflow`: slots before widgets, a seed's
  `fixed`, an upload's widget, dynamic options and numbered slots, an input that takes only a link fed by a primitive
  node, laid out left to right), named after its picture. ComfyUI's queue opens it; its pictures carry it. All 27
  workflows tried in ComfyUI's canvas: it turns each back into exactly the graph sent.
- **Reference pictures** go into ComfyUI's input folder itself: its Load Image offers only those.
- **`dev/tools/comfy-library`** (`saneui makecomfyapps`), new: every workflow and recipe as a template (Templates >
  Extensions > saneui, the pack `custom_nodes/saneui`), every recipe as an app in ComfyUI's App mode (Workflows >
  Sane UI); an app changed in ComfyUI is kept. `dev/tools/imagegen` runs it when a workflow or recipe changed.
- **Where pictures go:** `assets/generated/` is a link into the private work folder; the example set's pictures and
  eight unpicked alternatives of the UI style (four edges, band, buckle, chat bubble, class fan) moved to
  `assets/generated/picks/`, out of the repository. Guide: `Doc/guides/image-generation.md`, *In ComfyUI's window*,
  *Where pictures go*.
- **The common folder:** `dev/tools/private-folder` (`saneui linkprivate`, new) makes `assets/generated` the link into
  the private folder named in `~/.config/saneui/private.json`, moving a real folder's contents there first; `dev/build`
  runs it. Every tool, list and web page keeps the one path.
- Tests: `dev/tests/imagegen.py` 142 checks.

### Nameplates: combo points on the plate that holds them, none while empty (Saneroki, 2026-10-23)
- **Resource.Update**: every shown plate of a unit you can attack asks `GetComboPoints("player", unit)`; its row shows
  while the count is above 0, on your target's plate or another's, and hides at 0. A hidden count (the game restricts
  units' power) shows on your target's plate only. No more `holder`.
- Setting *Combo points under the bar*. Tests: 229 checks.

### Nameplates: the combo points' row thinner (Saneroki, 2026-10-23)
- `Resource.SHARE` a third of the bar's height (was half), as the power line.

### Nameplates: combo points in a row of their own, the cast bar under them (Saneroki, 2026-10-23)
- **Resource.lua**: the combo points no longer sit on the power line inside the health bar but in a row of their own
  under your target's bar (`Resource.SHARE`, half its height), over the bar's dark, its segments masked by the row's
  own pair of corner masks (`Resource.Shape`): round at the bottom while it is the lowest row, square above a cast.
- **Bar.Outline**: lays out the rows under the bar (health, combo points, cast), puts the cast under the combo points
  and anchors the outline, the rank's line and the glow down to the lowest; run as either row shows or hides.
- Setting *Combo points under your target's bar* (was *in*). Tests: 225 checks.

### Nameplates: the threat red in a fight while you have aggro (Saneroki, 2026-10-23)
- **Text.Aggro** (`Text.lua`): in a fight the game hides your threat's status from addons, and the number stayed grey
  while the bar glowed. Now the hidden `isTanking` is turned into a colour by the game (`C_CurveUtil.
  EvaluateColorFromBoolean`, red or grey) and the text takes it as it is; orange (about to take aggro) only where the
  status may be read.
- Tests: 222 checks.

### Nameplates: your target's outline a quiet grey (Saneroki, 2026-10-23)
- `Bar.TARGET` 50% grey (was the game's white): a hint of which plate is your target, not a shout.

### Nameplates: the white and red outline as thin as the black (Saneroki, 2026-10-23)
- **Bar.BACKGROUND** solid (alpha 1, was 0.85): the outline plate lies behind the whole bar, and a white or red one
  showed through the bar's dark and through the fill's soft top and bottom rows, so it looked two or three pixels
  thick where the black looked one. The cast bar's dark too.
- Tests: 220 checks.

### Inventory: the group Adventure Prep now Consumables, the category Consumables now Food (Saneroki, 2026-10-23)
- **Names only** (`Inventory.lua`: `bagsPrep` the game's `AUCTION_CATEGORY_CONSUMABLES`, `bagsFood` new): the keys
  (`prep`, `consumables`) stay, so what the player chose is kept; a name the player gave stays theirs.

### Nameplates: every round fits; Core's corner masks (Saneroki, 2026-10-23)
- **Core** (`Shape.CORNER`, `Art/corner-tl.blp`, `-tr`, `-bl`, `-br`, new from `dev/tools/shape-art`): one corner of a
  rectangle cut round, laid over that corner as large as the radius: that corner alone round, at any radius and height.
- **Outline** (`Bar.lua`): the border, the rank's line and each band of the glow are two halves (`Halves`), each round
  at its own corners by corner masks, so the outline is as round around the bar and its cast bar as around the bar
  alone (the cap masks had made it twice as round with a cast); the plates beyond the border that much rounder by
  their reach, concentric (`Bar.Radius`: a quarter of the bar's height).
- **Inside:** the bar's ends by `Bar.End` (`Bar.Ends`): round at both corners alone (the caps), only at the top while
  the cast bar is under it (corner masks), a pixel less round than the outline. The cast bar round only at its bottom:
  the icon's bottom left (a corner mask on the icon), the fill's bottom right; square where icon, fill and bar meet.
  The seam behind their corners is gone.
- Tests: 219 checks.

### Nameplates: no line between the bar and the cast bar (Saneroki, 2026-10-23)
- **Bar.Outline** (`Bar.lua`): while a cast shows, the bar reaches down to the cast bar (no pixel of the outline under
  it), and a seam in the bar's dark (`dress.seam`) lies behind where their round corners meet; the white border of a
  target no longer shows between them. The bar's inset and caps are set there now, not in `Bar.Fit`.
- Tests: 216 checks.

### Nameplates: the cast bar in the game's art, inside one outline with the bar (Saneroki, 2026-10-23)
- **Art** (`Cast.lua`): the fill in the game's own cast bar atlases (`Cast.ART`: golden standard, channel,
  uninterruptible, interrupted), given through `SetStatusBarTexture` as the game's cast bar does; the flat colours gone.
- **One outline** (`Bar.lua`, `Bar.Outline`): the border, the rank's line and the glow reach down to the cast bar's
  bottom while it shows (run from its `OnShow` and `OnHide`), their caps sized for both; around the bar alone
  otherwise. The cast bar has no border of its own any more: a pixel of the outline between it and the bar.
- Tests: 214 checks.

### Inventory: an item let go over the bags' window no longer tries a quiver (Saneroki, 2026-10-23)
- An item from elsewhere (worn, the bank) let go over the window went into the first free slot of the carried bags,
  a quiver's or another bag of one family's too, and the game answered that only arrows fit there. Now
  (`Menus.lua`, `Stow`) only the slots of ordinary bags (`record.kind == "bags"`) take it.

### Nameplates: our cast bar also for casts the game hides from addons (Saneroki, 2026-10-23)
- **Why the game's showed:** in this client a nameplate unit's cast times come hidden from addons (secret values), and
  ours stood back for such casts. Now (`Cast.lua`) the fill runs from the cast's start to its end as the game gives
  them (`SetMinMaxValues`, hidden or not) and is given the time now each frame, so the game draws the progress; a
  channel fills from its end in the dark over its colour (`SetReverseFill`). Not interruptible: a grey bar over the
  fill seen by the game's answer (`SetAlphaFromBoolean` where it is hidden). The seconds: from the end where it may be
  read, else reckoned from the spell's cast time (none for a channel); a reckoned end passed by a second without the
  game's word counts as done. The game's own cast bar shows only with the setting off.
- Tests: 212 checks (hidden times and lock).

### Nameplates: the power line a third of the bar (Saneroki, 2026-10-23)
- `Bar.LINE` 1/3 (was 1/5): the unit's mana, rage or energy a third of the bar's height; your combo points as high,
  on top of it.

### Inventory: the stats' page more compact (Saneroki, 2026-10-23)
- Less room round and between the sections (`Sheet/Stats.lua`, at the words' first size): the page's margin 5 (was
  12), between columns 12 (26), between sections 6 (14), a head 21 (26), a line 18 (20); the attributes' boxes 70 by
  48 (78 by 60), 6 apart (10); columns 170 to 320 wide (200 to 300), so more of them fit and less is left at the sides.

### Nameplates: the cast bar's colour from the cast alone; half a second after it ends (Saneroki, 2026-10-23)
- **Colour** (`Cast.lua`): your own interrupts no longer count (`Cast.KICKS`, `Cast.Ready`, `Cast.Learn` and the green
  gone): gold or blue where the cast can be interrupted, grey where it cannot, red when it was, with who did it.
- **Stays:** done (its time ran out, or the game says it stopped) a cast stays half a second, full (a channel
  empty); interrupted, half a second in red (`Cast.HOLD` 0.5); failed, it goes at once.
- Tests: 209 checks.

### Nameplates: the cast bar shows when you can interrupt it, and who interrupted it (Saneroki, 2026-10-23)
- **Colour** (`Cast.lua`): green (`Cast.READY`) while one of your interrupts is ready and reaches the unit, gold or
  blue while it can be interrupted but not by you now, grey where it cannot; looked at every 0.1 s while the bar shows.
  Your interrupts: `Cast.KICKS` (Kick, Pummel, Shield Bash, Counterspell, Earth Shock, Rebuke, every rank, from the
  game's tables) you know (`IsPlayerSpell`, `Cast.Learn` at `SPELLS_CHANGED`); ready by `C_Spell.GetSpellCooldown`
  (the global cooldown counts as ready), in reach by `C_Spell.IsSpellInRange`.
- **Interrupted:** full and red for a second (`Cast.HOLD` 1, was 0.4), the text the game's *Interrupted* and who did it
  (the event's `interruptedBy`, Plate.lua now hands the event's payload on).
- Tests: 207 checks.

### Inventory: the stats window shows its stats; only the stats (Saneroki, 2026-10-23)
- **Fixed:** the page stayed empty in the game: a stat's line had no font until the layout, but the game's function
  writes into it first, and the game refuses words without a font ("Font not set"). `Row` gives `Label` and `Value`
  their font objects when made. Test: `dev/tests/inventory.lua` checks the fonts are there before the layout.
- **Only the stats:** `Sheet/Sidebar.lua` is gone (TOC); `Stats.lua` is the part `stats` itself, one page. The pet's
  categories follow the player's and the resistances while there is a pet (`HasPetUI` and the pet there), named
  "<pet>: <category>". The gear sets and the titles are windows of their own on the board (`gear`, `titles`: the
  journal's dress, the game's sidebar icons on their tabs, not in the first layout; `Board.ORDER` after `stats`).
- Tests: `dev/tests/inventory.lua` 144 checks, `dev/tests/sheet.lua` 92 (no tabs; the titles and the gear sets in
  their own windows; a pet's stats on the page and gone with it).

### Nameplates: our own cast bar (Saneroki, 2026-10-23)
- **Cast bar** (`Cast.lua`, new in the TOC): under the plate's bar, no gap, as wide and as high as it, round like it;
  the spell's icon at its left end with the seconds left inside it; the spell's name and its target's on one line
  cut where the bar ends. Filling for a cast, emptying for a channel, grey when it cannot be interrupted, red for a
  moment when interrupted. Read from `UnitCastingInfo`, `UnitChannelInfo` and `UnitSpellTargetName` at the unit's
  `UNIT_SPELLCAST_*` events (registered in Plate.lua), its fill and seconds from start and end on its own `OnUpdate`.
  The game's `CastBarsContainer` out of sight while ours shows (`Plate.HIDDEN`); where the game hides a cast's times,
  or the new setting *Cast bar* is off, the game's shows. `Text.Font` exposed for it.
- Tests: 202 checks.

### Nameplates: words in place of the drawings; the combat text's CVars back when off and at logout (Saneroki, 2026-10-23)
- New setting *Drawings for what did no harm* (`combatPictures`, on): off, a miss, dodge, parry, block, evade or
  immunity is the game's word, as a resist is.
- `CombatText.lua`: the game's combat text CVars are ours only while ours shows: what they had before is kept in the
  setting `combatFoundCVars` and goes back once (`Restore`, per group) when ours is switched off, the module stands
  down, or at `PLAYER_LOGOUT` (`CombatText.Logout`, from `ns.OnLogout`, before Core's profiles take the game's
  settings); a module off or not loaded leaves the game's and the profiles' values alone (was: the game's defaults
  set when off). The setting and the logout's call in `Nameplates.lua` came in with 81133cb.
- Tests: `dev/tests/nameplates.lua` 186 checks (the word with the drawings off; the values found go back at the
  logout and are left alone after).

### Nameplates: the game's nameplate CVars ours only while on; theirs back at a logout (Saneroki, 2026-10-23)
- **Off leaves them alone** (`Scale.lua`): switched off, the CVars had the game's defaults written, and with the guard
  of the last change again at every change, over the player's own and a profile's values. Now what each had before
  ours goes back once (`Restore`) and they are left alone.
- **A module gone leaves them alone:** the values found before ours are kept with the module's settings
  (`foundCVars`, a new kept key) and put back at the logout (`ns.OnLogout`, `Scale.Logout`; the game writes its
  settings after it, at a `/reload` too), so a module not loaded leaves the game's own; loaded, ours come back at the
  login.
- Tests: 183 checks (off leaves yours, on keeps yours, the logout puts it back and sets nothing again).

### Nameplates: the game's scaling and fading kept off (Saneroki, 2026-10-23)
- **Scale.lua:** its CVars (the game's nameplate scaling and fading) were set once at the login; the game's stored
  settings and Core's Sync (a profile's game settings) come after it and could bring them back. Now they go through
  `Sync.SetCVar` where Sync is there, and are set again `Scale.AGAIN` (3) seconds after `PLAYER_ENTERING_WORLD` and
  `VARIABLES_LOADED` and after any `CVAR_UPDATE` of one of them, as the combat text does.
- Tests: 178 checks.

### Nameplates: one heal number, not two (Saneroki, 2026-10-23)
- `CombatText.lua`: the game's own heal numbers over units showed beside ours: the game's stored settings and Core's
  Sync (a profile's game settings) come after the login and turned `floatingCombatTextCombatHealing_v2` back on. The
  game's combat text CVars are set again `CombatText.AGAIN` (3) seconds after `PLAYER_ENTERING_WORLD` and
  `VARIABLES_LOADED`, and after a `CVAR_UPDATE` of one of them; through `Core.Sync.SetCVar` where Sync is there.
- Tests: `dev/tests/nameplates.lua` 176 checks (turned back on by something else: off again a little later).

### Inventory: the character's stats a page of our own that follows its window (Saneroki, 2026-10-23)
- **The stats' window on the journal's page** (`Board.DRESS.stats = "journal"`), no longer the game's right pane
  (its stone, background and scrolling list of its rows). `Sheet/Stats.lua` anew: each stat a line of ours
  (`Label`, `Value`, the tooltip's fields) filled by the game's own `PAPERDOLL_STATINFO[stat].updateFunc`, as the
  game fills its rows; its colon taken off, the game's colour codes in a value darkened for the paper
  (`Paper.InkHex`); its tooltip the game's (`onEnterFunc`, else `PaperDollStatTooltip`); the resistances by the
  game's `PaperDollFrame_SetResistance`. A stat the game hides, or at its `hideAt`, is left out.
- **Layout that follows the width:** the categories are sections (head in Kalam Bold with a pencil rule, lines with a
  faint stripe on every other one) in as many columns as fit (`Stats.COLUMN` to `Stats.COLUMN_MOST` wide, the block
  of them centred), cut in the game's order so the tallest column is as low as it can be (`Cuts`, every cut tried);
  one column in a narrow window. The primary attributes (a section of only `Stats.PRIMARY`) stand over the columns
  as five pencil boxes with the value large (`AsTile`) when they fit across the block, else a section like the
  others. A `ScrollFrame` with the wheel; laid out again on every size change.
- **The tabs** (`Sheet/Sidebar.lua`): drawn tabs in pencil (a pencil box, the word in Kalam; the chosen one strong
  and shaded, one the game has nothing for faded) in a row with a rule under it, as wide as their words, squeezed to
  share a narrow row. The window's least width is one column's.
- **Gear sets and titles on the paper:** lines with the pencil's shading, the hand-drawn tick (Kalam's root sign), a
  set's icon in a pencil slot, red ink for a set with an item lost; Equip, Save and New Set are pencil boxes
  (`Gear.lua`, `Titles.lua`). `List.New` takes `paper = true` (without the game's long lines).
- **The lab:** the inventory scene shows the stats, filled by the game's own character sheet files
  (`Lab.BlizzardFiles`, new: some files of one of Blizzard's addons, from the newest export); the lab's client got
  what those ask (`BreakUpLargeNumbers`, `GetUnitSpeed`, `LE_UNIT_STAT_*`, the ratings and enemy chances as zero, the
  defense skill, `C_PaperDollInfo`'s armor share and shield) and `format`'s `%F`.
- Tests: `dev/tests/inventory.lua` 143 checks (the sections, a resistance, the game's function and tooltip, one
  column narrow and three wide, the restriction), `dev/tests/sheet.lua` 95 (the drawn tabs, red ink).

### Nameplates: the outline one screen pixel at every size (Saneroki, 2026-10-23)
- **Fixed** (`Scale.lua`, `Plate.lua`): the border's pixel (and the bar's inset, the caps) was worked out at a plate's
  first size, so as plates grew in from nothing or shrank with distance it came out several pixels wide. A plate is
  now laid out anew (`Plate.Refit`) when its size settles or has moved on by a tenth since the last time.

### Nameplates: the combat text's drawings in sharp lines (Saneroki, 2026-10-23)
- `dev/tools/combat-art`: sharp pencil lines in place of thick ones: a traced drawing's lines thickened by 7 (was 17),
  the dark edge 0.013 (was 0.022); parry's and block's heavier lines first made thinner (`SHRINK`, 5) and not
  thickened, so they match the others; the immunity's bubble as it was (`THICKS`, `EDGES`). The miss stays the
  drawing in code (Saneroki's pick), in thin, even strokes without a second pass (`SHARP`); `Sheet` takes its edge
  and its strokes per drawing.

### Inventory: Containers a category of its own; Special Bags as before (Saneroki, 2026-10-23)
- 6fa115e had made Special Bags into Containers (bags and quivers besides what lies in a worn special bag). Saneroki
  explained the game: a bag or quiver lying in the bags is an item like any other and always empty
  (`ERR_BAG_IN_BAG`), only worn bags hold items. So:
  - **Containers** (`containers`, new, after Professions; the game's `AUCTION_CATEGORY_CONTAINERS`): the classes
    Container and Quiver, and what a right click opens: `Contents.Read` keeps the game's `hasLoot` as `record.loot`,
    `Categories.Classify` sends it there after Quest Items and Junk (`take = "loot"`); it takes what is put into it.
    Its drawing a lockbox (`dev/imagegen/sets/bags/categories.txt`, containers-1; `category-art containers`).
  - **Special Bags** (`special`, `ns.TEXT.bagsSpecial` back): only what lies in a worn bag for one kind of item, as
    before 6fa115e (`unassignable`, late, alone; the quiver's drawing).
  - The alts' items: `Contents.OPENS` remembers the items seen in the bags as opened by a right click
    (`Alts/Items.lua` sets `record.loot` from it), as their records have no such word of the game's.
- Tests: `dev/tests/bags.lua` 322 checks (the order, bags and quivers and what opens in Containers, Special Bags
  as before, the blocks and their empty slots).

### Nameplates: the combat text's drawings from the image model (Saneroki, 2026-10-23)
- Saneroki's picks, kept in `assets/interface/combat-text/` (new) and traced by `dev/tools/combat-art`: dodge (round
  2's `house/dodge-2`, its arrow turned to fly left to right), evade (round 2's `picks/evade-2`, its arrow turned to
  fly up past the head, as Saneroki's sketch), parry (round 1's `parry-1`), block (round 1's `block-4`), immune
  (round 2's `house/immune-2`). The arrows were turned in the pictures themselves (a crop flipped or rotated).
- `dev/tools/combat-art`: lines thickened per drawing (`THICKS`: parry and block 9, thinner; the bubble 27, thicker);
  the traced bubble's "i" larger (`LETTER_TRACED`).
- Render list `dev/imagegen/sets/combat-text/miss.txt` (round 3: a target with an arrow flying past beside it); the
  miss stays the drawing in code until one is picked.

### Nameplates: the combat text in three colours (Saneroki, 2026-10-23)
- `CombatText.lua`: physical damage (auto attacks, physical abilities; school mask 1 or none told) white, damage of
  any spell school red (`CombatText.SPELL`, the game's combat text red), heals green; over your character the same,
  with a minus. `CombatText.SCHOOLS` (a colour per school) is gone: it confused.
- Tests: `dev/tests/nameplates.lua` 172 checks (a spell red, a blow on you white, physical and a spell school at once
  red).

### Inventory: the doll's model back; Special Bags become Containers (Saneroki, 2026-10-23)
- **The model was gone:** 25bd74d put the model scene into a frame that clipped its children, anchored to the scene
  inside it; the game then drew no model at all. The scene stands on its place again (`Model.Build`, no `view`), and
  the legs below the hero's column are hidden by the doll's own picture drawn again over the model: `Doll.Cover`
  (the picture from `Doll.FOOT` down, as wide as `Model.SIZE`, its texture coordinates the doll's) on a frame of
  `Sheet.Build` at the holder's level + 6, above the model and under the items (+10).
- **Containers:** the category `special` (key kept) is named by the game's `AUCTION_CATEGORY_CONTAINERS` and takes
  the classes Container and Quiver besides what lies in a special bag; no longer `unassignable`, so an item can be
  put into it and it has its empty slot. `ns.TEXT.bagsSpecial` gone.
- Tests: `dev/tests/inventory.lua` (no clipping frame; the cover's coordinates, place and level), `dev/tests/bags.lua`
  321 checks (bags and quivers in Containers, its name, it takes items; nine empty slots in the grid).

### Nameplates: smaller drawings, your combat text at your feet, the "i" in Kalam (Saneroki, 2026-10-23)
- `CombatText.lua`: the drawings 30 units (`CombatText.PICTURE`, was 48); your own combat text rises from about your
  character's feet, 130 under the screen's middle (`CombatText.SELF`, was 60 over it).
- `dev/tools/combat-art`: the immunity's "i" is Kalam Bold, written in by code (`letter`); a drawing picked from the
  image model's, kept as `assets/interface/combat-text/<name>.png`, is traced in place of the one in code (`trace`:
  its dark lines thickened, white with the dark edge).
- Render lists `dev/imagegen/sets/combat-text/`: `drawings.txt` (round 1, prompts alone), `house.txt` (round 2, from
  words with the bags' decided pencil icons as the style), `picks.txt` (round 2, Saneroki's picks of round 1 redrawn in
  that style).

### Inventory: larger words in the bags' view; the slots' drawings bigger and darker (Saneroki, 2026-10-23)
- `Paper.WORDS` (1.2): `Paper.Font` and `Paper.Outlined` make every font object that much larger than the size
  given, the dropdown's word and arrow too; the cells' numbers (`Cells.Fonts`: count, item level, bind, set) and
  the bank bar's button word likewise. `Paper.Fit(n)` grows a height laid out for words with them:
  `Layout.ROW`, `HEAD`, `MEMBER`, `LABEL` and `Columns.HEAD`. The sidebar 180 wide (was 160) with rows of 28 (26);
  a group's box tick keeps its size (`Core.Journal.FontObject`, not grown: as large as its box).
- `Canvas.SLOT_ICON` 0.75 (was 0.6), `Canvas.SLOT_FADE` 0.3 (was 0.18).
- Seen in the interface lab (scene inventory, 1920 x 1080): the words fit their heads and rows, the drawings in the
  slots. Tests: `dev/tests/bags.lua` 320 checks (the fonts' sizes, a head's height, the tick's).

### Inventory: the category drawings large, and faded in each category's empty slot (Saneroki, 2026-10-23)
- `dev/tools/category-art`: 256 x 256 (was 64), from a 1024 square; every mipmap made from the whole drawing by
  itself, its lines thickened by a square `THICK` (30) wide for 64 and smaller, half as much for each doubling above
  (the 64 level as before, so the sidebar's rows look the same); the thickening by running maxima (0.7 s an icon).
  37 icons, 3.2 MB.
- `Bags/Canvas.lua`: an empty slot (`Sheet:Plus`) draws its category's drawing in its middle (`plus.icon`;
  `Categories.GroupIcon` for a group's one slot, `Categories.Icon` else), `Canvas.SLOT_ICON` (0.6) of its side at
  `Canvas.SLOT_FADE` (0.18); a game icon a player chose for a category of their own grey and cut by `Cells.ZOOM`.
- Tests: `dev/tests/bags.lua` 319 checks (a category's and Pinned's slot drawing, whole and faded; a group's; the
  player's own icon grey).

### Inventory: pencil drawings of our own for the sidebars' rows; a group's members darker (Saneroki, 2026-10-23)
- **The drawings:** `dev/imagegen/sets/bags/categories.txt` (Qwen turbo, one prompt a row, four seeds; a pilot of
  six settled the words: a few thick confident outlines, a simple silhouette, little shading), one chosen a row and
  noted in the list, kept as `assets/interface/categories/<key>.png`. The new `dev/tools/category-art`
  (`saneui makecategoryart`) makes each the game's texture: graphite from its darkness and alpha, cropped, laid
  into a 512 square with `ROOM` round it, thickened by a 15 px max filter, 64 x 64 BLP2 with mipmaps
  (`assets/optimized/Inventory/Art/Categories/<key>.blp`, into `SaneUI_Inventory/Art/`).
- **The code:** `Categories.ART` and the key is every built-in category's icon (the game's icons and atlases gone
  from `Categories.LIST`), `Categories.GroupIcon` a group's (a built-in group its own drawing, else its first
  member's), `Categories.Icon` a category of the player's own its chosen game icon or the drawing `own`;
  `Categories.Drawn` tells ours from the game's. `Views.FIXED` the three views' drawings; Add Category `add`. The
  sidebar's `Icon` draws ours whole (the game's still cut by `Cells.ZOOM`). The alts' Storage sidebar shows the
  categories' drawings too.
- **Darker members:** `Canvas.MEMBER_COLOR` is `Paper.SOFT` (was `FAINT`): a group's members' names as dark as a
  category's head, smaller and not bold.
- Tests: `dev/tests/bags.lua` 316 checks (the rows' drawings by key and drawn whole, a group's own, the player's own
  category with and without a chosen icon).

### Nameplates: the evade a figure leaning out of an arrow's way (Saneroki, 2026-10-23)
- `dev/tools/combat-art`: the evade is a figure facing you, leaning hard to its side, the arrow that flew at its face
  flying on through where the head was, two marks for the head's swing (in place of the see-through figure; the
  `faint` strokes stay in the tool). Texture made anew (`combat-evade.blp`).

### Nameplates: new drawings for dodge and evade (Saneroki, 2026-10-23)
- `dev/tools/combat-art`: the dodge a figure bending far back under an arrow (Saneroki's pick of the tries); the
  evade an arrow flying through a see-through figure: strokes of their own (`faint`), white at `FAINT` with a lighter
  dark edge round them (`FAINT_EDGE`), laid under the lines and their edge. `--try` keeps one other idea (the evade
  with a sword's swing). Textures made anew (`combat-dodge.blp`, `combat-evade.blp`).

### Nameplates: the immunity a red bubble with an "i"; other ideas for dodge and evade (Saneroki, 2026-10-23)
- `dev/tools/combat-art`: the immunity's bubble larger, an "i" in its middle, no sparkle; `CombatText.TINTS` draws it
  bright red (`SetVertexColor`, the texture stays white). `--try` draws other ideas into `assets/generated/CombatText/`
  (not shipped): dodge leaning back under an arrow or stepping aside from it, evade back to a flag, back home, or
  running to a flag.
- Tests: `dev/tests/nameplates.lua` 170 checks (the immunity red, the block white).

### Inventory: the doll's zoom moves the camera into the head; the model cut off at the column's foot (Saneroki, 2026-10-23)
- `Sheet/Model.lua`: zoomed in, the head went to the scene's middle and the legs, drawn larger, covered the weapons'
  slots. Now the camera's target spline (`Aim`) puts the top of the model (its bounding box) at the top of its place
  at the nearest distance (`GetMinZoomDistance`): the target there is the top plus (target - floor) x (1 - place's
  height / `below`) x nearest / at rest, from the scene's own measure at rest. A tall character's head stays about
  where it is and grows, a small one's comes up; `Model.HEAD` gone.
- The scene sits in a frame that clips its children (`SetClipsChildren`, as the game's shop holds its scene), as wide
  as the scene, from its top down to the foot of the hero's column (`Doll.FOOT`, 703, its paper's edge): below it
  the model is cut off.
- Tests: `dev/tests/inventory.lua` 139 checks (the model's top at the place's top all the way in, the clipping frame).

### Nameplates: the combat text in Kalam, drawings for what did no harm, over your character (Saneroki, 2026-10-23)
- `Numbers.lua` is `CombatText.lua` (`ns.CombatText`); the settings' section *Combat text*: *Over nameplates*
  (`combatText`), *Over your character* (`combatSelf`), *Heals* (`combatHeals`), *Instead of the game's*
  (`combatGame`).
- The numbers in Kalam Bold, outlined (`Core.Journal.FONT_BOLD`; the game's combat text font where it cannot be set).
- A miss, dodge, parry (and deflect), block, evade or immunity is a white pencil drawing, 48 square, in place of the
  word: new `dev/tools/combat-art` (`saneui makecombatart`) draws them into `assets/CombatText/`; `dev/tools/art`
  makes `assets/optimized/Nameplates/Art/combat-<name>.blp` (128, kind `combat`). The word stays where there is no
  drawing (resist, absorb, reflect, interrupt) or its file is missing.
- Over your character: your own `UNIT_COMBAT` (`Core.OnUnit`) rises from a point of ours `CombatText.SELF` over the
  screen's middle (no plate of your own in this client: the resource display is a panel of Edit Mode); damage red
  with a minus. *Instead of the game's* then also turns `enableFloatingCombatText` off.
- `Doc/guides/interface-style.md`, *Combat text*: Saneroki's look for it.
- Tests: `dev/tests/nameplates.lua` 169 checks (the font, the drawings and the word without one, your character's
  text, each switch, no CVar set in a fight).

### Inventory: a pencil arrow of its own for the sidebars, centred and as large as a box (Saneroki, 2026-10-23)
- **The picture:** `dev/imagegen/sets/bags/arrow.txt` (Qwen turbo, three prompts by four seeds), stroke-3 chosen
  (`assets/interface/bags-arrow.png`): one thick pencil stroke bent into a chevron pointing down, heaviest at the
  point. `dev/tools/journal-art arrow` makes Core's `Art/Journal/arrow.blp` from it (`arrow()`: graphite with its
  grain, the left half mirrored onto the right, thickened by a 13 px max filter at 512, centred in a square with
  `ARROW_ROOM` round it; 64 x 64), listed in `Journal.PIECES`.
- `Bags/Sidebar.lua`: `Arrow` is that texture, `Sidebar.TOGGLE` (14) square in its button's middle, at
  `Sidebar.MARK`, turned by `SetRotation` (down as drawn, up, left, right) in place of Kalam's "<": the head's
  points left to fold and right to unfold; a group's row's arrow button is as large as its box (both
  `Sidebar.TOGGLE`).
- Tests: `dev/tests/bags.lua` 312 checks (the piece, its size and place, its turns in a group's row and the head).

### Inventory: the doll's zoom toward the head (Saneroki, 2026-10-23)
- `Sheet/Model.lua`: the scene's camera looked at the hips (its target 1.02 high) at every zoom. Once the model
  has loaded, the camera gets a target spline (`SetTargetSpline`, the game's `CreateCatmullRomSpline`): no shift
  zoomed out, the model's head zoomed all the way in (`Model.HEAD`, 0.85 of its bounding box's height up from its
  feet), so the wheel zooms in on the face. Set anew with each setup of the scene (which clears it); the way back
  after ten seconds zooms out, so the target comes down with it.
- Tests: `dev/tests/inventory.lua` 137 checks (the spline's points).

### Nameplates: combat numbers over the plates (Saneroki, 2026-10-23)
- New `Numbers.lua` (in the TOC): what a plate's unit takes rises over its bar and fades: damage (physical white, a
  spell in the game's colour for its school), critical hits and heals half again as large with a short swell,
  glancing blows and words (miss, dodge, parry, block, ...) smaller, heals green with a "+". From each dress's own
  `UNIT_COMBAT` (added to `Plate.EVENTS`; the combat log is closed to addons in this client), so in a group it is
  everybody's damage on the unit. Pooled frames on the dress, one animation group each (rise, fade, swell; no
  `OnUpdate`), lanes side by side, at most `Numbers.MOST` a plate; let go with the plate (`Plate.lua`, `Off`).
  Hidden kinds and amounts (secret values) are written as they are, white, nothing compared.
- The game's own numbers over units (`floatingCombatTextCombatDamage_v2`, `...CombatHealing_v2`) off while ours show,
  at their defaults otherwise and when standing down; never set in a fight.
- Settings, section *Combat numbers*: *Numbers over nameplates*, *Heals*, *Instead of the game's numbers*.
- The purple XP over a kill is drawn by the game itself, with no CVar of its own in this build: it stays.
- Tests: `dev/tests/nameplates.lua` 159 checks (a critical hit, a miss, a heal, a hidden hit, the pool, the most a
  plate holds, the switches, the CVars off and back).

### Navigation: no blocked action at login; Follow me follows as soon as you walk (Saneroki, 2026-10-23)
- `Hybrid.lua`: the game's minimap over our map takes no clicks (`SetMouseClickEnabled(false)`, given back as it
  was) in place of `SetPassThroughButtons`, which the game now blocks for addons (a blocked action at every login
  and `/reload`).
- `Canvas.lua` (`Again`): the full map with *Follow me* ticked follows again as soon as the player walks on, no mouse
  button held; it no longer waits for *Follow again after*, which is the small view's alone now.
- Tests: `dev/tests/navigation.lua` 587 checks (the minimap's clicks off and back; walking on right after a drag).

### Inventory: the doll's model between the lines, every race at one scale (Saneroki, 2026-10-23)
- Saneroki's two lines on the doll: a full-grown character fills its place from under the level line
  (`Doll.MODEL_TOP`, 84) down to the ground (`Doll.GROUND`, 681, was the strap at 713); a smaller race stands on
  the same ground at the same scale, not filling the height.
- **One size** (`Sheet/Model.lua`): the scene `Model.SIZE` (272 x 872 doll pixels, the shape it had) in place of
  `Model.LARGER` times its place: the night elf in the game was 664 pixels tall at 1.5625, now about 589.
- **One scale for every race:** after `SetUpCharacterSheetScene` every actor of the scene gets requested scale 1,
  no scaling toward a man's size (`SetNormalizedScaleAggressiveness(0)`) and the floor (`SetPosition(0, 0, 0)`):
  scene 595 gives each race its own size, scaling and lift.
- **Feet measured:** the scene says where it draws the bottom of the model (its bounding box, once loaded; the
  floor before) under the camera's target (`Transform3DPointTo2D`; the units from the target, drawn in the middle:
  points or pixels, or shares of its size). The actors' `SetOnModelLoadedCallback` stands it anew once loaded. When
  the answer cannot be read: the rule (field of view across the diagonal) and `Model.LOWER` (0.064 of the
  scene's height) lower, as the game drew it (the feet were 63 doll pixels under the rule's 713). `Model.FEET` gone.
- Tests: `dev/tests/inventory.lua` 136 checks (the one size, the actors evened, the feet before and after loading,
  in pixels and in shares, the rule when the answer cannot be read).

### Inventory: the sidebar's group rows with the pencil arrow, turned, and a pencil box (Saneroki, 2026-10-23)
- `Bags/Sidebar.lua`: the head's arrow made by one helper (`Arrow`: Kalam Bold's "<" in graphite at
  `Sidebar.MARK`, 0.6); a group's row has it too in place of the game's arrows, turned (`FontString:SetRotation`)
  down while its members are folded, up while they are listed. Its box: the square pencil piece (`pencil-slot`,
  `Sidebar.BOX` 0.8) in place of the stretched pencil box drawn strong, the tick Kalam's root sign
  (`Sidebar.TICK`, 25) at `Sidebar.MARK` in place of the game's check mark at 0.9. Under the mouse the arrow or the
  tick is drawn whole; the tooltip as before.
- Tests: `dev/tests/bags.lua` 310 checks (the arrow's glyph, its turn either way, the tick's glyph and lightness).

### Core: Hotcorner requires leftclick per window (Saneroki, 2026-10-23)
- The switch moved from General into each module's section *Expand window* (`expandClick`, off, under *Can expand
  to fullscreen*; `Edge.DEFAULTS`, `Edge.KEYS`): the bags may want a click while the map does not. The general
  switch `edgeClick` is gone; a change is taken in by `edge:Update()` like the section's other switches.

### Core: Hotcorner requires leftclick (Saneroki, 2026-10-23)
- New general switch *Hotcorner requires leftclick* (`edgeClick`, off; page General, under Windows): ticked, the
  mouse at a docked window's screen edge or corner does nothing; a left click in that edge's strip or the corner's
  square fills the screen, another there brings the window back (`Edge:Clicked`). The strips take left clicks only
  while it is on (`SetMouseClickEnabled`); Edge follows Core's own `changed` for it.

### Inventory: no rule under a group's title (Saneroki, 2026-10-23)
- A group's title (The Armory, Adventure Prep) has no pencil rule (the double line) under it any more; it stands
  right over its members' heads, as a category's name does. Only a part's head keeps its rule (`Sheet:Head`).

### Inventory: no "+" in the empty slots (Saneroki, 2026-10-23)
- A block's empty slot after its items (Pinned's, a category's) shows no "+" any more, like the empty slots of the
  other views: `plus.sign` and the font `SaneUIBagsPlus` are gone; the slot still takes an item into its category.
  The test finds these slots by their key.

### Inventory: empty slots at half strength (Saneroki, 2026-10-23)
- An empty slot's pencil lines are drawn at `Cells.EMPTY_SLOT` 0.5, less distracting: empty cells (back to full
  when an item comes), a block's "+" slot (`Canvas`) and an empty bag slot in the strip (`Foot`).

### Inventory: the waste bin strong and dark (Saneroki, 2026-10-23)
- The bin's drawing was faint on the paper (its darkest lines some 40 % graphite). `dev/tools/journal-art` now makes
  its darkest lines full graphite, lifts the lighter ones and thickens every line a little (`trash.blp` rebuilt,
  the same size); the bags draw it at full strength (no more 0.7) and `Canvas.BIN` 1.2 times the slot, centred on it.

### Inventory: the waste bin without a slot (Saneroki, 2026-10-23)
- Junk's waste bin is the bin's drawing alone, as large as a slot (`Sheet:Bin`): no pencil slot around it, no inset
  (`Canvas.BIN` is gone). The shade behind it still lights when an item is held over it.

### Nameplates: no endless bars after a /reload (Saneroki, 2026-10-23)
- **Fixed** (`Text.lua`, `Plate.lua`): plates on the screen at a `/reload` are dressed at the login, before the game's
  fonts and scales are set up, and its widths then (none, endless, absurd) made the bars endlessly wide. Such a width
  now counts as none (`Text.WIDEST`); the ruler then guesses (`Text.GUESS` of the font's height a letter);
  `Plate.Place` keeps a bar to `Plate.PLAIN` where its width is beyond `Plate.WIDEST`; and half a second after
  `PLAYER_ENTERING_WORLD` every plate is filled and measured anew.
- Tests: 144 checks.

### Nameplates: your target full size; smooth glides between range rungs; far foes red (Saneroki, 2026-10-23)
- **Target** (`Scale.lua`): your target's plate always at the full size, whatever its distance; selected or let go a
  plate moves at `Scale.QUICK` (2 a second).
- **Smooth:** the distance was the middle of the two rungs around a unit, flipping as it crossed one, and plates
  jumped to it quickly. Now `Range.Settle` keeps it where it was while within the rungs and puts it at the rung the
  unit just passed (the one distance known for sure); plates follow at `Scale.SPEED` 0.2 a second, about as fast as a
  running unit changes its size, evenly, never past it.
- **Far foes red** (`Range.lua`): where none of your spells can say, a foe the ladder puts beyond the farthest of your
  attacks (`Range.longest`) is out of reach too. `Range.Check` gives the two rungs; `/sane range` prints them.
- Tests: 142 checks.

### Nameplates: the glow under the outline; even size changes; half the size; close foes not red (Saneroki, 2026-10-23)
- **Layers** (`Bar.lua`): the glow, the outline (rank line and border) and the bar each on a frame of its own one level
  above the last; the glow's frame had been asked one level under the dress, which can come out above the outline.
- **Even** (`Scale.lua`): no spring; a plate moves to its size at `Scale.SPEED` (1.5 shares a second) in a straight
  line, grows in from nothing within `Scale.GROW` (0.2 s).
- **Half the size:** *Nameplate size* under a new key (`plateSize`, 125%, 50 to 300), so the old 250% saved goes.
- **Red border** (`Range.lua`): a spell with a least range (Charge, Auto Shot) said no to a foe standing too close, so
  close foes turned red; its no counts for nothing now. A plate's red goes with its unit. `/sane range` prints the
  game's answers for your target.
- Tests: 138 checks.

### Nameplates: distance from your character, size by it alone, no fading (Saneroki, 2026-10-23)
- **Why:** the game's nameplate scaling, read back as the distance, measures from the camera: near plates read far
  (faded, small) and the selected one huge. Now nothing of the game's sizes or fades a plate.
- **Distance** (`Range.lua`, rewritten): each plate's unit asked against a ladder of range checks from your
  character, the shortest first: items whose use reaches a foe (`Range.ENEMY`, 5 to 40 yards) or a friend
  (`Range.FRIEND`, 5 to 50), picked from the game's own tables, and your spells with a range (harmful for foes,
  helpful for friends); the unit stands between the last rung that did not reach and the first that did
  (`Range.Check`), every 0.2 s for every plate (`Range.Look`).
- **Size** (`Scale.lua`, rewritten): *Nameplate size* (new setting, 250%) within 10 yards, half at 40, a quarter at 60,
  by distance alone; the game's scaling and fading off (`nameplateMinScale`, `MaxScale`, `SelectedScale`,
  `LargerScale` and the alphas 1) and any scale it still gives a plate undone. Each plate moves on a spring
  (`Scale.Step`), springs in from nothing when it appears (`Scale.Born`). No fading of ours.
- **Red border** on any foe none of your harmful spells reaches (`dress.out`, `Plate.Light`, `Bar.Border`'s `out`),
  from the same look; the event-driven target check is gone.
- Tests: 135 checks (the ladder and the distances it gives, size by distance alone, the target the same, a game scale
  undone, the spring, red and black by reach, the size setting, off in a fight).

### Nameplates: your target's border red while out of reach of all your attacks (Saneroki, 2026-10-23)
- **Range** (`Range.lua`, new in the TOC): your attacks are your spellbook's harmful spells with a range (melee
  strikes, Charge, Shoot with a bow, bolts), made anew when your spells change; the game tells when each goes in or
  out of reach (`C_Spell.EnableSpellRangeCheck`, `SPELL_RANGE_CHECK_UPDATE`). Out of reach when one says no and
  none yes; where none can tell, beyond 40 yards by the distance read from the game's scaling (`Scale.Yards`).
- **Border** (`Bar.Border` `"far"`, `Bar.FAR`): red on your target then, white otherwise; only targets you can attack.
- **Setting:** *Out of reach: red border*.
- Tests: 137 checks (which spells are watched, red and white by them, the 40-yard fallback, the setting).

### Nameplates: the quest's icon and the raid marker outside the bar; long names longer bars (Saneroki, 2026-10-23)
- **Outside** (`Text.lua`, `Marks.lua`): the quest's sword or sack and the raid marker stand left of the bar, outside
  it (`Text.OUTSIDE` 4 from it and each other, the marker outermost); the quest's count stays first in the line. A
  foe's buffs stand left of them (`dress.outside`, `Auras.Place`).
- **Long names** (`Text.MOST` 400, was 180): the bar grows for them instead of cutting them short.
- Tests: 127 checks (the icons' places, the buffs past them, a long name).

### Nameplates: one control over size and transparency; plates spring in (Saneroki, 2026-10-23)
- **One hand** (`Scale.lua`): the game's scaling, its larger target and elites and its fading pulled at the plates'
  size apart from ours. Now the game's scaling is only a gauge: its CVars make it one straight line from 1 at your
  feet to `Scale.LINE` 0.25 at the farthest reach, nothing larger, none of its fading (`nameplateSelectedScale`,
  `nameplateLargerScale`, `nameplateMinAlpha`, `MaxAlpha`, `SelectedAlpha`, `NotSelectedAlpha` 1), and each plate's
  scale is read back to its distance. Our dress gets `Scale.FULL` (3, the size a target had) times `Scale.CURVE`
  (full to 10 yards, half at 40, a quarter at 60) over the game's scale; the game's unit frame the curve alone.
  `Plate.SIZE` is gone.
- **Transparency:** a plate not targeted fades out over the last `Scale.FADE` 5 yards of the reach.
- **Spring** (`Scale.Born`, `Scale.Spring`): a plate appearing grows from 0.6 of its size, swings past it and settles
  within 0.45 s, its alpha up within 0.15 s; the driver looks every frame while one springs.
- **Setting:** *Size by distance* (was *Smaller far away*), the same key.
- Tests: 126 checks (the curve, the distance, the fade, the spring, a plate the game scales up, off in a fight).

### Nameplates: twice the size; no empty room after the health (Saneroki, 2026-10-23)
- **Twice the size** (`Plate.lua`): our dress at `Plate.SIZE` (2) times the plate's scale (`SetScale`), the bar, its
  line and auras alike, whatever the game's scaling does.
- **The health's room** (`Text.lua`): the game hides a plate's unit's health from addons always, so its text could
  not be measured and the room fell back to "888.8k | 100%", empty after a short health. Now the room is the most
  health's short form when the game says it, else `Text.Guess` from the unit's level and rank ("888", "8.8k",
  "8.88m"); the health text is as wide as it is (never cut short).
- **Measuring:** the ruler stands on a frame of its own, always shown (it was on the first plate's, which hides);
  a new plate is shown before it is filled, so its texts are measured while they show.
- Tests: 118 checks (the guesses, the size, the health's width).

### Nameplates: a compact bar; larger plates (Saneroki, 2026-10-23)
- **Compact** (`Text.lua`, `Plate.lua`): the bar as high as its line (`Text.Height`: the font's height, `Text.PAD` 2
  over and under, a pixel of border each), no longer the game's row's height; `Text.INSET` 3 (was 5); the health's
  room measured on its own text in its widest form (the ruler only where it answers hidden).
- **Larger** (`Scale.lua`): `Scale.NEAR` 1.5 at your feet, the same straight line down to a quarter of it at 60
  yards (`nameplateMaxScale` 1.5, `nameplateMinScale` 0.375).
- Tests: 113 checks.

### Nameplates: half the size; the game's own scaling only (Saneroki, 2026-10-23)
- **Half the size** (`Scale.lua`): their own size at your feet, half at 40 yards, a quarter at 60. That is one
  straight line, so the game's CVars do it all (`nameplateMinScale` 0.25 at the farthest, both scale distances 0,
  no larger target or elites); the per-plate rescaling (the driver frame's `OnUpdate`, `SetScale` on our dress and
  the game's unit frames, `Plate.shown`) is gone.
- Tests: 113 checks.

### Nameplates: one border; the rank's line and the glow behind it (Saneroki, 2026-10-23)
- **One border** (`Bar.lua`): the ring outside the border is gone; the border itself (one pixel) is black, white on
  your target, orange on your focus (`Bar.Border`).
- **Behind it** from the same edge: the rank's line (`dress.rankLine`, `Bar.RANKS` widths from the bar's edge: boss
  4, elite and rare 2), and the glow beyond that line. The bar no longer moves inward for a thicker rank.
- Tests: 117 checks (the border's colours, the line's and the glow's reach).

### Nameplates: the line smaller, nothing cut short, no room left over (Saneroki, 2026-10-23)
- **Smaller** (`Text.lua`): the line's font is the game's nameplate font's face and outline at `Text.SMALLER` (0.72)
  of its height, set on every text of ours (`SetFont`); icons `Text.ICON` 1.2 times that height.
- **Measured right:** texts ("0/7", the name) were cut short and others had room left over, because rooms came from a
  hidden ruler. Now a plain text is measured on itself, whole (`GetUnboundedStringWidth`), rounded up and a pixel
  more (`Text.SLACK`); the ruler (alpha 0, shown) only for texts that answer hidden, the health's most and "100%".
- Tests: 116 checks (the font, the rooms with their slack).

### Nameplates: one line inside the bar, each piece only while it shows; the bar as wide as the line (Saneroki, 2026-10-23)
- **The line** (`Text.lua`): left to right the quest objective (the game's sword or sack and "0/7", from
  `Core.UnitQuest`), the raid marker (`Marks.lua`, no longer right of the bar), the level, a player's item level
  ("i32", from `Core.Inspect`), the threat, the name, the health; each piece has its room only while it shows
  (`dress.room`), `Text.Layout` places them one after another, and the bar is as wide as the line and its insets
  (`Plate.Place`, centred on the game's row; `Plate.WIDE` is gone). Widths from a ruler font string that never gets
  a hidden value; hidden health takes the room of its most, a hidden name the last plain one's, threat that of
  "100%", so the bar keeps its width as values change in a fight.
- **Item levels** asked for when a player's plate comes and again while one is missing, Core pacing the questions.
- **Settings:** *Quest progress*, *Item level*.
- **Core** (`Objectives.lua`, `Inspect.lua`, new in its TOC): `Core.UnitQuest(unit)`, moved from Combat's quest
  marks, and `Core.Inspect` (`Level`, `Talents`, `Watch`), moved from Tooltips (which now reads Core's); game data
  is Core's. Combat's quest mark beside a plate steps aside while Nameplates runs.
- Tests: 115 checks in `dev/tests/nameplates.lua` (the line's order and rooms, the width, quests, item levels);
  the tooltips test loads Core's `Inspect.lua`.

### Nameplates: the glow fades for real, narrower; the bar half as wide again (Saneroki, 2026-10-23)
- **Fixed glow** (`Bar.lua`): turning the glow on set each plate's own alpha to 1, which in the game replaces a
  texture's vertex alpha, so every plate was solid and the glow a thick red block. The plates now stand on a frame
  of their own a level under the dress (`dress.glow`), and only that frame's alpha switches the glow (also a hidden
  aggro answer, `SetAlphaFromBoolean`); the plates keep their strengths. Narrower: `Bar.HALO` 6, 1 to 6 screen
  pixels beyond the border.
- **Wider** (`Plate.lua`): our bar `Plate.WIDE` (1.5) times as wide as the game's health bar row, centred on it, as
  high (`Place`, at every fit).
- Tests: 106 checks (the glow's frame and untouched plates, the width).

### Nameplates: the red glow a blurred edge, solid at the border (Saneroki, 2026-10-23)
- **Glow** (`Bar.lua`): `Bar.HALO` 8 round plates a pixel apart (2 to 9 screen pixels beyond the border), drawn
  as paint again (no `ADD`): each plate's strength (`Bar.Strength`) worked out from the plates beyond it so that
  together they are solid red at the border and fade to almost nothing outwards (`Bar.Fade`, squared falloff).
- Tests: the glow's bands added up: solid at the border, each fainter outwards, as `Bar.Fade` says.

### Nameplates: the size by distance on a curve of two steps (Saneroki, 2026-10-23)
- **The curve** (`Scale.lua`, `Scale.CURVE`): twice the size at your feet, slowly down to its own size at 40 yards,
  then faster to half at 60, the game's limit for plates of units not targeted (its `nameplateMaxDistance` reads
  more but is held to 60); the target's plate, shown farther, stays at half.
- **How:** the game scales only in a straight line, so its CVars now make that line run from 1 at no distance to
  `Scale.LINE` (0.25) at the farthest, with the larger target and larger elites off (`nameplateSelectedScale`,
  `nameplateLargerScale` 1). A driver frame's guarded `OnUpdate` (every 0.05 s, only while plates show) reads each
  plate's scale back to its distance and scales our dress and the game's unit frame on it by our size over the
  game's; scale 1 again when the plate goes, the setting is off or the module stands down (`Scale.Leave`,
  `Plate.GiveBack`). `Plate.shown` is read by it.
- Tests: 103 checks in `dev/tests/nameplates.lua` (the curve, the distance read back, a plate scaled, off in a fight).

### Nameplates: up to twice the size close by; resource lines without a background; a soft glow (Saneroki, 2026-10-23)
- **Twice the size** (`Scale.lua`): `nameplateMaxScale` 2 (was 1), so a plate within ten yards is twice its size;
  far away still 0.55.
- **No background** (`Bar.lua`, `Resource.lua`): the power line's dark background is gone, so spent power shows
  nothing; the combo points are one `StatusBar` per point (segment *i* from *i* - 1 to *i*, each given the count
  as the game gives it: the bar clamps it, so hidden counts still work), a pixel apart, without the darkened
  background and the dark lines between and over them: points not built show nothing.
- **A glow, not an outline** (`Bar.HALO`): seven round layers a pixel apart, each fainter outwards (0.22 to
  0.025), in blend mode `ADD`: thin and fading out, where the three solid layers looked like an outline.
- Tests: 99 checks in `dev/tests/nameplates.lua` (the segments, no backgrounds, the glow's layers).

### Nameplates: health as "1.2k" and "1.32m"; the glow no longer stops the module in a fight (Saneroki, 2026-10-23)
- **Health short** (`Text.Short`): under a thousand as it is, thousands to one place ("1.2k"), millions to two
  ("1.32m"), cut, not rounded, without zeros at the end ("1k", "1.3m"); the game's abbreviation of hidden health
  in the same steps (`Text.STEPS`: thousands' `significandDivisor` 100, `fractionDivisor` 10). The "1m325k" form
  is gone.
- **Fixed** (the game's error log): `Bar.Glow` compared the game's hidden answer about aggro with `true`, an error
  in a fight that stood the module down; a hidden answer now goes to `SetAlphaFromBoolean` with the game's own
  alphas, untouched, and only a plain one is tested.

### Nameplates: everything inside the bar, the power line, borders by rank, a glow on aggro, auras around the bar, strangers hidden, smaller far away (Saneroki, 2026-10-23)
- **Inside the bar** (`Text.lua`, new in the TOC): on one line, at the left the unit's level (the game's
  `GetRelativeDifficultyColor`, its skull where too high) and your threat on it (`UnitDetailedThreatSituation`: grey,
  orange about to take aggro, red having it), the name in the middle (cut short past `Text.NAME` of the width), at
  the right its health short (`Text.Short`: "850", "12k", "1m325k") and `| 100%`; hidden values in a fight go to
  the texts as they are (`AbbreviateNumbers` with our steps, `UnitHealthPercent` by the game's curve). The name
  above the bar and the game's level box (`LevelFrame`, `PlayerLevelDiffFrame`) are gone.
- **The bar** (`Bar.lua`): health red for creatures that attack on sight, light yellow for those that do not
  (`UnitReaction` 4), grey when tapped, the class colour for every player; the unit's power as a line a fifth of
  the bar's height along its bottom, inside it (`Bar.Power`, the game's `PowerBarColor`); the border by rank
  (`Bar.RANKS`: boss gold and 3 pixels, elite gold, rare and rare elite silver, else black) in place of the rare's
  mark; target and focus as a ring a pixel outside the border; a red glow of three round plates around it all while
  you have the unit's aggro (a hidden answer by `SetAlphaFromBoolean`) or it is a player who may attack you.
- **Combo points** (`Resource.lua`) as high as the power line, right on top of it.
- **Auras** (`Auras.lua`): your debuffs right on the bar's top (`HARMFUL|PLAYER|!CROWD_CONTROL`, the whole width);
  a foe's three buffs left of the bar; a third container for crowd control (`HARMFUL|CROWD_CONTROL`, two) right of
  it, after the raid marker (`Marks.lua`: the rare's mark gone).
- **Strangers' plates** (`Plate.Wanted`): a player you cannot attack shows only while in your group or guild, a
  friend or your target; the game's unit frame at alpha 0 otherwise. Setting *Only players you know*.
- **Smaller far away** (`Scale.lua`, new in the TOC): the game's `nameplateMinScale`, `MaxScale`, `MinScaleDistance`
  and `MaxScaleDistance` CVars set to ours (0.55 far away, full within ten yards), their defaults back when the
  setting is off or the module stands down; never in a fight.
- **Settings:** *Crowd control*, *Power line*, *Only players you know*, *Smaller far away* added.
- Tests: `dev/tests/nameplates.lua`, 96 checks (the texts and their short forms, threat's colours and the glow,
  the ranks, the ring, the power line, the auras' places, strangers' plates, the CVars in and out of a fight).

### Inventory: the doll's model on the strap, a quarter larger again, turned and zoomed, back after ten seconds (Saneroki, 2026-10-23)
- **On the strap** (`Sheet/Model.lua`, `Sheet.lua`, `Doll.lua`): the model's place reaches from under the level line
  down to `Doll.GROUND` (713, the top of the strap drawn under the hero's column), and the scene stands with its
  floor there: where the floor is drawn worked out from its camera (the target's height over its distance, the
  field of view across the scene's diagonal), `Model.FEET` (0.08 of its height) when the camera cannot tell.
- **Larger:** `Model.LARGER` 1.5625 (a quarter larger, and a quarter again) times its place.
- **Turned and zoomed:** the game's `ModelSceneMixinTemplate` in place of the one that takes no mouse: its orbit
  camera turns the model by the left button's drag and zooms by the wheel; mouse and wheel enabled, only over the
  hero's place (`SetHitRectInsets`), our scripts hooked on after the game's (`HookScript`; the item let go over it
  is still put on).
- **Back after ten seconds:** `Model.REST` (10) seconds after the last drag or turn of the wheel (a `C_Timer`
  timer, started anew by each, never running while the button is held) the camera glides back to its first
  distance and its first side the short way round (`home`, read after `SetUpCharacterSheetScene`).
- Tests: the inventory test's stand-in scene has the game's camera and scripts; 132 checks (the size, the place,
  the feet, the mouse's area, the game's scripts kept, the wait, its new start by the wheel, the way back).

### Navigation: the group's pings no longer heard, so the game blocks nothing at login (Saneroki, 2026-10-23)
- The game still blocked an action of Navigation's at every login ("UNKNOWN()"; 3x at 14:29) after `SetPassThroughButtons`
  had gone (71bd2aa): the blocks began with the callback for `MINIMAP_PING` (`RegisterEventCallback`, ece73bf), one of
  the game's callback events with restrictions. `Ping.lua` no longer listens: it only sends. Gone with it: the marks
  of received pings (`Marks.Pings`, the ping art), `Ping.List`, `Ping.TIME`, `Hybrid.Covers`, the message LIVE
  "ping". The game's minimap draws the group's pings where it lies over our map.
- Tests: `dev/tests/navigation.lua` (585 checks: nothing listens to `MINIMAP_PING`, neither a callback nor a frame).

### Navigation: a ping sent in the click itself (Saneroki, 2026-10-23)
- The game blocked our pings ("the game blocked UNKNOWN()", three times): `Minimap:PingLocation` is taken only in the
  click's own handler, and the ping was sent from a timer (`Ping.Soon`, held back a double click's time). Now sent at
  once, in the click (`Canvas.lua`'s `Clicked`, `Found.lua`'s picture), so a double click pings with its first click
  and puts the map pin with its second; `Ping.Soon`, `Ping.Cancel` and `Ping.DOUBLE` are gone (`Canvas.DOUBLE`, 0.3).
- Tests: `dev/tests/navigation.lua` (586 checks: the ping in the click, one ping in a double click; the test clock
  kept as before).

### Navigation: the group's pings heard (Saneroki, 2026-10-23)
- `Ping.lua`: `MINIMAP_PING` is one of the game's callback events, which no frame can register (Forever's client
  refused it: "this client has no such event"); it is now taken through the game's `RegisterEventCallback`, as
  Blizzard's minimap takes it, guarded (`Listen`; its first value the callback's owner, none), a frame's event only on
  a client without callback events.
- Tests: `dev/tests/navigation.lua` (586 checks: the ping heard as a callback event, by no frame).

### Navigation: the player's arrow always shown, on the small map and the full one (Saneroki, 2026-10-23)
- `Canvas.lua`, `Marks.lua`: our arrow (`Marks.Player`, Blizzard's world map arrow) is no longer left to the game's
  minimap where that lies over our map: on the full map, where the game's minimap stands only as a square around the
  player for its dots, it showed no arrow in play. Ours is drawn in both views wherever the game tells the player's
  place, over the game's minimap (its own arrow, where it draws one, under ours; the game has no call to hide it).
- Tests: `dev/tests/navigation.lua` (585 checks: our arrow on the player over the game's minimap, small and full).

### Navigation: pings as on the game's minimap, a double click for the map pin, the quest log moves the map, Follow me (Saneroki, 2026-10-23)
- **Pings** (`Ping.lua`, new in the TOC, no frames): a plain click on the map where it opens nothing pings there to the
  party and raid through the game's own ping (`Minimap:PingLocation`; Forever's client loads no ping wheel): the
  place's yards from the player in the game's minimap's units (`Hybrid.PingAt`: its width over twice its view's
  radius; where the view it has does not reach so far, at the nearest step measured that does for the moment, its
  zoom set back at once; none past the widest), sent `Ping.DOUBLE` (0.3) seconds later unless a second click came
  (`Ping.Soon`, `Ping.Cancel`). `MINIMAP_PING` (shares of the minimap's width from its middle) is kept as a place on
  the player's plane for `Ping.TIME` (5) seconds and drawn by `Marks.Pings` in the game's minimap ping art (its ring
  turning, its wave growing; who pinged under it in their class colour, not the player), faded out at the end,
  hidden where the game's minimap covers it (`Hybrid.Covers`); turned with the game's own minimap where it turns.
  The small view's old ping on the game's minimap (`Hybrid.Ping`) stays only in an instance.
- **A double click puts the game's map pin** (`Canvas.lua`): two plain left clicks on the same (a pin, or the map)
  within `Ping.DOUBLE` and `Canvas.NEAR` (8) units, at the first click's place (`Where`, taken before a zone it
  opened). Ctrl and a click still puts it at once (on a pin: where the pin stands). A click on a pin is its own
  first (`PinView.Act`, now public and false where a pin has none: gathered markers zoom in, quests and givers on
  the full map show in the quest log, Shift opens a linked map), else the map's; `Canvas.Release(button, pin)` takes
  the whole click. A found herb's or ore's picture (`Found.lua`): a click pings it, `OnDoubleClick` the map pin.
- **The quest log** (`QuestLog.lua`): a click on a quest (or a preview) leads the arrow to it and moves the map to
  its objective at the zoom it has (`Canvas.LookAt`: no longer following, as after a drag; a dungeon's map over the
  full map goes); the row's `OnDoubleClick` puts the map pin there (a header's, or a modified second click, as a
  click).
- **Follow me** (the setting `followMap`, off; its box on the full map's bar left of the pin filter, `TopBar.lua`;
  `Canvas.Following`, `Canvas.Center`): ticked, the full map is on the player and follows; the window filling the
  screen puts it on the player again (`Window.lua`: not at a map the game was asked for, `aimed`); the tracker's
  `Again` follows again on the full map once the player moved since the last look, no button is held and the mouse
  left the map alone for *Follow again after*. Unticked, the full map as before.
- **The bar:** the view buttons `TopBar.VIEW_WIDTH` (90) and the pin filter `TopBar.PINS_WIDTH` (110) wide, so the
  bar with the box still fits a screen 1366 units wide.
- Tests: `dev/tests/navigation.lua` (584 checks: a ping where clicked once no second came, at a wider step past the
  view, none past the widest; a double click's map pin and no ping; the party's ping on the full map and the
  player's under the game's minimap, gone after its time; pins clicked and double clicked; the quest log's click
  and double click; Follow me ticked, dragged, standing, walking on, opening on the player, unticked; a found herb).

### Tooltips: rules, a table's captions and its lines in the grey of the section names (Saneroki, 2026-10-23)
- `Model.lua`: `COLOR.NOTE` (the grey of a section's name, `Tone(GREY, WHITE, 0.3)`) in place of the dark
  see-through `COLOR.GROOVE`. `Panel.lua`: a section's rules, a table's captions (a spell's *Mana*, *Range*, *Dmg*,
  *DPS*, ...), the lines between its cells and between two columns in it, as Saneroki asked; the values keep their
  colours. `Pools.lua`: `Pools.GROOVE`, `GROOVE_LIGHT` and the groove's light edge gone; every text its font's shadow.
- README.md; `dev/tests/tooltips.lua` (the captions, rules and lines grey).

### A red ! before each thing not yet confirmed; quests confirmed when taken or handed in (Saneroki, 2026-10-23)
- Core, `Kit.lua`: `Core.UNCONFIRMED_MARK` (the red ! and a space), for the name of each thing a tooltip lists that is
  not yet confirmed, so *! Unconfirmed Data !* says which, as Saneroki asked.
- Navigation: a boss's abilities and items (`Listed`: `SpellLine`, `ItemLine` take the mark, between the icon and the
  name), an enemy (`FoeTip`: by its instance's entry in the set Dungeons; *Unconfirmed Data* only then), a pin's own
  thing (`pin.doubt`, its heading; each of a gathered pin's, `Iconed`, with *Unconfirmed Data* under them) and a
  pin's quests (`QuestLines`: the set Quests; the pin's tooltip ends with *Unconfirmed Data* then, `pin.unverified`).
- `Data/Watchers.lua`: a quest taken or handed in (`QUEST_ACCEPTED`, `QUEST_TURNED_IN`) confirms the set Quests' quest.
- READMEs (Navigation, Tooltips, Core), `Doc/guides/data.md`; tests: `navigation.lua` (the marks, gone once
  confirmed), `data.lua` 232 (a quest taken and handed in).

### Core: what the game confirms in play, kept, shared and harvested; items' stats learned (Saneroki, 2026-10-23)
- The master: a version's `verified` mark (`{"day","times"}`, after `src`; `master.py`, `schema.py`), `Master.confirmed`
  (a source of the kind game or hand, or the mark). The compiler lists each set's entries not yet verified in its file
  (`S.unverified`, `compile.py`).
- `Data.lua`: `Handle:Unverified(key, part)`; `Data.LearnRow` (a row from somebody else's Sane UI, taken where
  `accept` says so), `Data.Learned`, `Data.NoteBuild` (`builds[build] = patch` in the learned part).
- `Data/Confirm.lua` (new, in Core's TOC): `Data.Confirm`, `Confirmed`, `ConfirmedParts`, `OnConfirm`, `Share`; kept in
  `SaneUIData_Learned[game].confirmed`; shared with the guild and the raid or party (the wire's kinds V and L) from an
  outbox kept in the saved file, `Confirm.GAP` seconds apart, never in a fight, under a restriction or in an instance,
  as Saneroki asked; taken from the guild, party and raid only: a confirmation of what this client has unverified, a
  learned row where it changes nothing but an item's stats, armour, damage and speed (`Confirm.SHARED`).
- `Data/Watchers.lua` (new, in Core's TOC): creatures seen near their spawn or talked to, things used, mailboxes
  opened, crossings, a boss's loot (within `Watchers.LOOT` seconds of its kill, in its instance: an item the set
  names, or any of the boss's own corpse, as Saneroki allowed: no place is told inside an instance), its casts and
  buffs; every item the character has compared with *Items* (`GetItemStats`, its tooltip's damage and speed),
  learned and shared where it differs (the master has no item's stats yet).
- Views: the map's pins (`Pins.Unverified`) and a boss's tooltip (per item and ability; items and abilities confirmed
  that the set lacks join it; an item the game keeps hidden as Core's data has it, its stats with Alt: `Recorded`)
  say *Unconfirmed Data* only while it holds; redrawn on `Data.OnConfirm`.
- The harvest (`dev/data/harvest.py`, `dev/tools/data harvest`; `saneui data harvest`): the game folders' saved files
  read as data, learned rows and whole confirmations staged, new builds into `builds.toml`; the import's case
  *verified* (`confirmed`: the mark, once an import, beta's of live's on live's line).
- `Doc/guides/data.md` (*Verified*, the line, staging, the set file, saved variables, messages, tools),
  `Doc/ideas/Data.md`, `Data-build.md` (1c.3 ticked), READMEs (Core, Navigation); tests: `data.lua` 231 (marks,
  watchers, sharing, taking, items), `navigation.lua` 568, `data/tools.py` 215 (the mark, the list, the import, the
  harvest, every row read back).

### Navigation: a plus for pins of different icons gathered; their icons in its tooltip (Saneroki, 2026-10-23)
- `PinView.lua`: a gathered marker shows its pins' icon where all have the same one (`Alike`: atlas, tint, grey),
  else the game's round plus (`PinView.PLUS`), as Saneroki asked; its tooltip puts each pin's own icon before its
  name (`Iconed`, `PinView.TIP_ICON`, a tinted or grey one in its colour).
- README.md; `dev/tests/navigation.lua` 561 (two herbs: the herb's icon; an innkeeper and a herb: the plus, icons in
  the tooltip).

### Navigation: a pin's tooltip says nothing twice, a gathered one no sentence about the click (Saneroki, 2026-10-23)
- `PinView.lua`: a gathered marker's tooltip is headed by its first pin's name (or role), the others under it, each
  once; `Pins.TEXT.gathered` (*%d here: a click zooms in*) gone, as Saneroki asked. Every line of a pin's tooltip
  goes through `Say`, which leaves out words said already (the heading too).
- README.md; `dev/tests/navigation.lua` (two herbs of a kind: one name).

### Tooltips: section names grey; Unconfirmed Data and Hold ALT for more as quiet notes (Saneroki, 2026-10-23)
- `Panel.lua`: a section's name grey (`NOTE`, `COLOR.ASIDE`), no longer the groove's black (it read badly), as
  Saneroki asked; its rules stay in the groove's shade. A caption row that is `bare` (`Model.lua`) has no rules.
- `Read.lua`: *Unconfirmed Data* (Core's line) as written, no capitals, and *Hold ALT for more*: small grey notes in
  the middle at the panel's very bottom, without rules (`Note`); the unconfirmed one after Alt's details and other
  addons' lines, its red *!* at each side (`FONTS.mark` as small as the note).
- READMEs (Tooltips, Navigation), `Core/Kit.lua`'s comment; `dev/tests/tooltips.lua` (the grey name, the bare notes).

### Tooltips and Navigation: columns, Unconfirmed Data, pins by role, bosses as creatures (Saneroki, 2026-10-23)
- Tooltips, `Panel.lua`: a panel taller than the screen (`Tallest`: `UIParent`'s height in the panel's units, less
  `SCREEN_MARGIN` and the soft edge) is laid again in columns (`Columns`, `ox`): each ends before the row that would
  run past it, a caption goes on with its rows; the panel as wide as the columns, a groove between two; the icon at
  the first column's corner (anchored `TOPLEFT` now). `Pools.Rewind` gives back a laying's lines and icons; a unit's
  buffs and bars follow their column (`aurasLeft`, `block.left`).
- Core, `Kit.lua`: `Core.UNCONFIRMED` (*! Unconfirmed Data !*, the marks in the game's red) and `Core.Unconfirmed`;
  `Core.TipLook`, `Core.TipSection`, `Core.LookOf`: a creature that is no unit of the game's, its look kept until
  the tooltip is cleared.
- Tooltips: that line a caption with a red *!* at each side (`mark`, `FONTS.mark`; `Read.Rest`); a tooltip with a
  look read as a creature's (`ns.Figure`, `Kinds/Unit.lua`): its title and kind under the name, its `display` model
  in the portrait's place, the dragon, the badge, its sections by their heading lines, a row's icon at its start, a
  detail set in; *Hold ALT for more* on it too.
- Navigation: an NPC's pin is named by its role (`pin.role`: its title, else its service, else *Quest giver*; a rare
  keeps its name), as Saneroki asked; `Pins.TEXT.unverified` and `Dungeons.TEXT.unverified` are Core's line. A
  boss's tooltip (`BossTip`) as a creature's: its name in `Dungeons.FOE`, the dungeon, *Boss*, `Core.TipLook` with
  its `display`, the boss's dragon and *??*; *Abilities* and *Loot* headed by `Core.TipSection`; an ability's
  description set in; an item's details with Alt: *Uncollected* first, its effects (`Effect`), then its stats.
- READMEs (Tooltips, Navigation, Core); tests: `dev/tests/tooltips.lua` 489 (columns, the divider, a boss as a
  creature), `dev/tests/navigation.lua` 560 (a pin by its role, the boss's lines and look, the items' order).

### Navigation: a boss's items with Alt show their stats and effects only (Saneroki, 2026-10-23)
- `Dungeons.lua`: of an item's own tooltip lines only its damage, speed, damage per second, armour, block, stats
  (`Dungeons.KEEP`) and effects (`Dungeons.EFFECTS`: Equip, Use, Chance on hit), as Saneroki asked; no price, slot,
  binding, requirements, durability, set or lore. *Uncollected* under it while the player lacks its appearance
  (`C_TransmogCollection`, else the game's line).
- README.md (*Dungeons*), `dev/tests/navigation.lua` (an item's lines kept and dropped).

### Navigation: the bosses as their models alone; Alt for their abilities' and items' details (Saneroki, 2026-10-23)
- `Dungeons.lua`: a boss's mark (`Dungeons.BOSS`) shows, and takes the mouse, only where no model stands on it (no
  look, or the model at the view's edge), as Saneroki asked. Its tooltip with Alt held: under each ability its
  description (`C_Spell.GetSpellDescription`, `SPELL_DATA_LOAD_RESULT`), under each item its own tooltip's lines
  (a hidden tooltip, `SaneUINavigationReader`); drawn again as Alt is pressed or let go (`MODIFIER_STATE_CHANGED`).
- README.md (*Dungeons*), `dev/tests/navigation.lua` (the mark under a model, Alt held and let go).

### Navigation: the route's ships light blue, its flights white (Saneroki, 2026-10-23)
- `Route.lua`: `Route.COLOURS`: a boat's, a zeppelin's and the tram's way light blue (0.4, 0.75, 1; red before), a
  flight's white (pale gold before), as Saneroki asked. The line's art (the game's dependency bar: its edge, fill and
  glint) is grey, so each kind shows its colour as it is. The hearthstone's and the teleports' stay pale blue.
- README.md (*Routes*, *Route*, the files), `Doc/ideas/Navigation.md` (the line's colours).

### Inventory: a pinned item only under Pinned (2026-10-23)
- `Views`: while the bags' Pinned is shown (`apart`), `ByCategory` leaves pinned records out of their categories
  and groups; `Views.Counts` counts them only for Pinned. Pinned hidden: in their categories as before.
- `dev/tests/bags.lua`: a pinned item only under Pinned; Pinned off: in its category.

### Inventory: the waste bin is Junk's first slot (2026-10-23)
- The bin leaves the sidebar (`MakeTrash`, `Bags.Bin`, `Bags.TRASH`, `TRASH_FOLDED`, the rail's `narrow`,
  `BagSidebar.Room` gone): Junk's block has `block.bin` (`Views`), the layout a `bin` place before its cells
  (`Layout`), the canvas a pencil slot with the drawing (`Sheet:Bin`, `Canvas.BIN`); its drop and click
  `Menus.Destroy` (moved from `Bags.lua`), the game's own question to destroy the item.

### Inventory: the waste bin shows with the sidebar folded (2026-10-23)
- Folded, the bags' sidebar is `Bags.TRASH_FOLDED` (52) wide (the rail's `narrow`), the bin's drawing 44 in it.

### Inventory: the bags' cells a quarter smaller (2026-10-23)
- `Layout.SIZE` 51 (was 68), `GAP` 5; the cells' words (count and item level 13, BoE 12, the set 10), the quest
  mark 22 and the coin 16, the "+" 27, `Bags.STEP` 56; the bags' strip with them.

### Inventory: the bags' cells twice as large; the bag strip like them; a waste bin (2026-10-23)
- `Layout.SIZE` 68 (was 34), `GAP` 6; the cells' words (`Cells.Fonts`: count and item level 16, BoE 14, the set 12),
  the quest mark 28 and the coin 20, the "+" 34; `Bags.STEP` 74. The bags' strip takes the same size and gap
  (`Foot.BAG`, `Foot.BAG_GAP` from `Layout`), already in the cells' look (pencil slot, rounded icon, no border).
- The waste bin (`Bags.lua`: `MakeTrash`, `Trash`, `Bags.Bin`; `Bags.TRASH` its room, `BagSidebar.Room` keeps it
  free under the rows): an item let go there or clicked onto it opens the game's own dialog as the game's
  `DELETE_ITEM_CONFIRM` would (`DELETE_GOOD_ITEM` for rare and better but heirlooms, the quest variants for quest
  items), whose Yes is the game's `DeleteCursorItem`.
- Its picture: Core's `Art/Journal/trash` (`dev/tools/journal-art`: `trash()`, the chosen drawing
  `assets/interface/bags-trash.png` turned into graphite on clear, its white fill gone; `Journal.PIECES`), made by
  `dev/imagegen/sets/bags/trash.txt` (a quick try of eight; bucket-1 taken).
- `dev/tests/bags.lua`: the bin, nothing asked without an item, the game's question with one.

### Inventory: the bags' strip of bag slots twice as large (2026-10-23)
- `Foot.BAG` 68 (was 34), the strip's height with it (`Foot.STRIP`).

### Inventory: the bags' items take the mouse again; drops anywhere on the window; no scroll bar (2026-10-23)
- The items' scroll child took the mouse for drops on the paper and the item buttons lost their tooltips, drags
  and clicks: it takes none now. An item let go where nothing else takes it goes to the panel itself and its head
  (`Bags.lua`: `Back`, `Home`, `Menus.Home`): into the bags, where the rules put it.
- The scroll area is a plain `ScrollFrame` (no `ScrollFrameTemplate`, no bar), the wheel scrolls it a line
  (`Bags.STEP`), `Bags.RIGHT` its room at the right; the bank keeps its bar (`Bags.SCROLL`).
- `dev/tests/bags.lua`: the scroll child takes no mouse, the window takes the drop, no scroll bar.

### Inventory: drops on the paper; one slot a group; groups fold and divide; a small title line (2026-10-23)
- An item let go over the bags' paper (the scroll child, `Canvas`: `PaperDrop`, `Menus.Home`): into the bags
  (`Stow`), its assignment taken off, so it lands where the rules put it.
- A group divided has one empty slot for the whole group (`Views`: a `bare` block with `drop` "group:<group>";
  `Layout`: no head, level with the members' cells, none above it when alone), its members none. An item let go
  there, on a group's head or its sidebar row (`Menus.Takes`/`Drop`, `Select`): `Categories.Into`, the member
  `Categories.Rule` gives it there (the rules by `Contents.Instant`), else the group's first member.
- A group whole (`Categories.Divided` off, `store.bags.whole`): one block of all its members' items, one slot.
- The sidebar's group rows (`Rail:Toggles`): an arrow (the game's small arrows in graphite) folds the members
  into the row (`Categories.Folded`, `store.bags.folded`), a pencil box with a check divides or joins the group in
  All Items.
- The title line: `Bags.BAR` 18, round buttons `Bags.TITLE_BUTTON` 15, *View* `Bags.TITLE_MENU` 74 wide; the bank's
  bar keeps its height (`Bags.PAGE_BAR`) and buttons (`BAR_BUTTON`). `Paper.Dropdown` is a pencil box with graphite
  words (the bank's and the alts' too); *Sell All Junk Items* on the title line a pencil box (`Foot.ACT_LIT` gone).
- `dev/tests/bags.lua`: the paper drop, the group's slot, folding and dividing from the sidebar, a group whole.

### Inventory: the Armory by slot, Adventure Prep by kind; one empty slot; the doll still, on plain paper (2026-10-23)
- Categories (`Bags/Categories.lua`): The Armory is the gear by its slot (`head` ... `ranged` by `def.equip`, the
  game's `INVTYPE_` words), `armor` now *Shirts, Tabards & Other Gear*, then `sets`; Adventure Prep is `potions`
  (Consumable subclass Potion), `enhance` now *Buffs* (elixirs, flasks, scrolls, enchantments by subclass, gems and
  item enhancements whole, and a consumable whose use aura lasts `Categories.LASTING`, 15 minutes, by Core's Items
  and Auras), `camp`, `consumables` (the rest). The rules that ask more than the class (a slot, a kind) are tried
  first (`First`, `Rules`).
- All Items (`Bags/Views.lua`): a group is its title (`block.title`, its members' count) and its members that hold
  something as level-3 blocks, each with its empty slot; an empty group is left out.
- The grid (`Bags/Layout.lua`): one empty slot a block, never more (a wide name widens the block's room, not its
  slots); a group's title over the whole width, its members a line of their own; in the list a folded title folds
  its members. No rule under a block's or member's head, only under a part's head and a group's title
  (`Bags/Canvas.lua`).
- Rounder icons: Core's own mask `Art/Journal/icon-mask` (`dev/tools/journal-art`: a square with corners of
  `ROUND` 0.2 of its side), `Cells.ROUNDED`.
- The doll (`Sheet/`): the turn and zoom buttons gone and the scene the game's `NonInteractableModelSceneMixinTemplate`,
  `Model.LARGER` 1.25 times its place, its foot kept, the name and level over it; the head and hands slots as large
  as the others (`Doll.TOP`, `INSET.top`); the slot icons without `IconBorder`, rounded by `Cells.ROUNDED`; the
  strips the item's stats, centred (`Slots.Stats`, `Slots.FIRST`; `Doll.Strip`'s `Fill(stats)`).
- The doll's art (`dev/tools/journal-art`, `doll.blp`): the two large top boxes covered with the page's paper and
  redrawn at a row's size with their sketch (`small_tops`, `LARGE`, `TOP`), and the hero's column with its frame,
  wedges and stony ground covered with the page's paper (`paper_over`, `MIDDLE`).
- Tests: `dev/tests/bags.lua` (the new categories and their order, groups' titles and members, one slot),
  `dev/tests/inventory.lua` (the still model, no buttons, the strips' stats); `wowstub.lua` keeps a frame's
  template (`_template`).

### Inventory: the bags' bar on the title line; borderless rounded icons; the sidebar folds (2026-10-23)
- Items (`Bags/Cells.lua`, `Alts/Items.lua`): no border any more (`Cells.QUEST`, `NEUTRAL`, `EMPTY_EDGE` and the
  setting `borders`, *Quality Borders*, gone); the icon, the empty slot's graphite, the highlight and the press share
  the game's rounded icon mask (`Cells.ROUNDED`, `Interface\Common\common-iconmask`) through `Cells.Mask`;
  `Cells.Round` swaps that mask for a circle (`Cells.CIRCLE`) in the list.
- The bar (`Bags/Bags.lua`) on the journal's title line, anchored to `panel.title` above the head that drags the
  window: the count after *Bags*, at the line's end (`Bags.BAR_END`) the junk marker, the bags' button and the
  clean-up as round buttons (`Bags.Round`: the icon in a circle, a soft edge of the ink at `Bags.SOFT` one, two,
  three pixels out; the clean-up a broom, the bank's too), then *View*. The strip of the bags at the body's top.
- The sidebar folds (`Bags/Sidebar.lua`: `options.fold`, `Rail:Fold`, the arrow in its head, `Sidebars.FOLDED`):
  folded, the strip of the bags is hidden too (`Bags.Fold`, kept as `store.bags.side`); the bags' button unfolds it.
- The strip (`Bags/Foot.lua`): no border; a bag's icon rounded as the items', an empty bag slot no icon (the pencil
  slot alone, not the game's empty bag picture).
- `dev/tests/bags.lua`: the round clean-up, folding and unfolding, an empty bag slot without a picture.

### Inventory: the bags' categories share lines; one kind of empty slot (2026-10-23)
- The grid (`Bags/Layout.lua`): the blocks flow side by side in bands, `BAND_GAP` apart, as many as fit across;
  each under its own head as wide as it is: its cells, then (where it takes items, `block.plus`) its empty slots,
  the first right after the cells and more only to make its last line whole. A block is as wide as its cells and
  that slot, or as its head's words (`Layout.Lay`'s new `measure`, the canvas's hidden font string), at most the
  room. A block with nothing to show (an empty group) is left out.
- Every empty slot is the "+" slot (`Canvas.lua`'s `Sheet:Plus`, now lit while an item is held over it): let go
  or clicked on, the item goes into the category (`Menus.Drop` with `stow`). The pads are gone (`Cells.Pad`,
  `Pads`, `PAD_ALPHA`, `EMPTY_PAD_ALPHA`, `PAD_EDGE`). The compact display has its empty slots too.
- `dev/tests/bags.lua`: the grid's bands, the head's width, a narrow room, the empty slots' drops.

### dev: the tools' web pages, each on its own port (2026-10-23)
- `dev/tools/web-pages` (`saneui webpages`; `saneui start|stop|status webpages`): every page a tool serves, each on
  a port of its own so all can be open at once: interface pieces 8768, maps compared 8771, instance maps 8772, world
  map 8773, interface lab 8774, and folders of this computer named in `~/.config/saneui/pages.json`. `start` runs
  the ones that are down in the background (a passing user unit); a port already served is left to its server.
- `dev/tools/world-map serve --only instances` (`saneui showinstancemaps`, port 8772): the instance maps alone;
  `--only world` the continents alone. `serve` copies the page in as it is now, not as the last build left it.

### dev: the finished maps compared (2026-10-23)
- `dev/tools/map-compare` (`saneui showmaps`, 127.0.0.1 port 8771): every zone and instance with a painted level
  in one page, its levels (close, middle per floor, far) and the game's terrain and maps laid by their boxes over
  each other: a slider each, or two side by side under a divider. A list of the maps with their finished levels,
  a filter, the arrow keys. The pictures as JPEGs in `assets/generated/map-layers/compare`, made again when their
  source is newer; it takes over the hand-made page of four maps that was there.

### dev: the GPU runner's map jobs finish again (2026-10-23)
- `dev/tools/map-layers tiles`: a square over the open sea took the sea's words, which have no light, and every
  run stopped there; the sea's own light is now in its words.
- `dev/tools/map-layers status` counts only the `--levels` and `--kind` asked, and the job `instancemaps` asks
  for its own share (the instances' far renders) with a `done` pattern: before, the runner could never see it
  finished and dropped it after three tries.

### Inventory: every category shown, its empty slots take items (Saneroki, 2026-10-23)
- Saneroki asked that every category's line of slots stays visible when it is empty, and that the empty slots work
  like real ones: an item let go there goes into the bags and into that category; on Junk it is marked as junk,
  on any other category the junk mark comes off.
- `Views.lua`: All Items keeps an empty category or group (not while searching, not in the bank). `Layout.lua`: in
  the grid every block gets its line of pads, and a pad knows its block. `Cells.lua` (`Pool:Pad`): a pad of a
  category that takes items takes an item let go or clicked on it (`Menus.Drop`), lit while one is brought over it,
  the category's tooltip; drawn stronger than the inert pads.
- `Menus.Drop(key, stow)`: in the bags' window (its heads, "+", pads and sidebar rows) the item is stowed: one taken
  out of a bag (its slot locked) goes back to its slot, one from elsewhere (the bank, what is worn) into the first
  free slot of the ordinary bags (`C_Container.PickupContainerItem`), with none free back where it came from. The
  bank's window keeps the item where it was. Assigning to another category takes a junk mark off (as before).
- `dev/tests/bags.lua`: the empty categories in All Items, the grid's pads, drops on Junk's and Trade Goods' empty
  slots, an item from outside the bags stowed (278 checks).

### Core: the journal's window no longer freezes the game (2026-10-23)
- Opening the inventory froze the game until the client stopped the script ("script ran too long" in
  `Journal.lua`): the edges' and the bottom's tiles were laid by stepping a remainder, which in floating point can
  come out a hair under a whole tile, so the step stopped moving the position and the loop never ended (each round
  making another texture). `Strip` now counts whole tiles from the first to the last, at most `Journal.MOST_TILES`.
- `dev/tests/core.lua`: a dressed frame laid out at some 200 sizes, those at the floating-point edge among them, and
  at one beyond reason (388 checks; the old loop does not finish them).

### Navigation: no ride straight back (2026-10-22)
- `Planner.lua` (`Journey`): no ride brings one back to where the rides since the last walk began (`boarded`: for a
  node reached by a ride, that place; `origin` while a node is looked at; neither a ride nor a landing reaches it). A
  lift's end reached on foot lets no walk go on and the same end reached by the lift does, so 5 of 200 routes between
  NPCs rode a lift up and straight down again (the Undercity's, the small one by Gnomeregan) for a walk after a walk.
- `Lifts.lua` (`Lifts.Heights`, new): the heights of a lift end's own level (within `Walk.RISE` yards of its
  landing's, at most half way to the other end's); `Search.Price` takes them (`level`, passed to `Goals`): such a walk
  ends only on a floor at those heights within `Search.NEAR` yards, none else. A walk to the Undercity's upper landings
  ended in the city under them (one region with the ruins, by the sewers), as though it had come down the lift.
- `Planner.lua` (`Find`): of the journeys whose walks were all priced, the quickest as priced is drawn (`kept`: the
  journey's seconds with each walk's price in place of its guess and of `Planner.APART`). One chosen again by its
  guesses could be dearer than one priced before it: a walk up to `Planner.WORSE` times its guess stays, and after
  `Planner.TRIES` tries the last stayed whatever it cost (Ironforge to Apothecary Zinge by Dalaran's portals, then an
  Undercity lift up and straight down: about 910 seconds where 650 were known).
- Checked on the real data (outside the game, the walking data of 2026-10-22, the code before and after): of 200
  routes between NPCs none rides back (5 before; with the player indoors 4, in turn 5); those go by one walk or
  another real way, and three others take the quicker journey priced before them; walks drawn straight 1, off the
  data 1, none and not from the player 0, as before; the 29 fixed journeys the same legs; the teleports' 16 from the
  player to the pin; 128 ms a route (127).
- Tests: `dev/tests/navigation.lua` (555 checks: a walk straight there a long way round, never up a lift and
  straight down again to walk on; each end of a lift its level's heights, and a walk to the upper end from the hall
  under it none; of the journeys priced whole the quickest drawn).

### Inventory, Core: the character, the bags and the alts in Sane UI's own look (Saneroki, 2026-10-22)
- Saneroki asked for the inventory's windows in the new art and style (`Doc/guides/interface-style.md`), resizable
  on the board as before. Three windows changed; the stats and the sheet's other windows keep the dark plate.
- **Core.Journal** (`src/Core/Journal.lua`, new; from the interface lab's draft, which it replaces): the window of
  paper bound in stitched leather from the art's pieces (the top in three, its middle stretched; the edges and the
  bottom repeated; the bottom corners mitred under their caps; the clasp; the paper cut, never stretched), laid out
  anew at every size; pencil rules, pencil boxes (nine pieces), an item's pencil slot; the leather patch as a button
  (`Journal.Patch`, `Journal.Button`); Kalam font objects; letters pressed into leather in the leather's light tan
  with a dark edge, as `title-text.png` shows them; `Journal.Ink` for a game colour that reads on the paper. The
  leather is drawn at 0.8 of its 4K size (`Journal.SCALE`), so a full screen of windows keeps room.
- **Core's board** (`Board.lua`): a window's spec may ask for `dress = "journal"` (the journal round its panel, its
  title on the top's label, the X on the corner patch, the strap and label its head) or `"bare"` (no plate: the
  module draws its own window; a head, a Kalam title and a pressed X it places itself).
- **Art** (`dev/tools/journal-art`, `saneui makejournalart`, new): the pieces as BLP2 textures for Core
  (`assets/optimized/Core/Art/Journal/`, 23 files): each piece at its texture's top left, a repeated piece repeated
  into the rest so tiles join without a seam; a square pencil slot made from the box's corners; Kalam into Core's
  `Fonts/`. The character window for the game: the doll with the hero taken out (repainted as paper by the image
  model with the stony ground kept, its paper toned and grained to the column's in code;
  `assets/interface/doll-empty.png`), its slot columns bent into their arcs (`compose.py`'s `doll_bent`, now shared)
  and its strips' painted writing covered. `dev/tools/art` runs its pictures only when called as a script.
- **The character** (`Sheet/Doll.lua`, new; `Sheet.lua`, `Slots.lua`, `Model.lua`): the doll picture, scaled to fit
  its window at the top; the game's item buttons in its painted slots (empty: the doll's sketch shows), each strip
  with the item's name in its quality's colour (outlined), the slot and item level, its two largest stats; the name,
  title and level line (the class's colour as ink) in the hero's place, the live model under them standing on the
  doll's ground, no race backdrop; the X on the right strap. Its least is 0.6 of the doll.
- **The bags and the bank** (`Paper.lua`, new; `Bags.lua`, `Bank.lua`, `Canvas.lua`, `Cells.lua`, `Foot.lua`,
  `Sidebar.lua`, `Columns.lua`): on the journal's page; the bar and foot a pencil rule, no dark band; every cell a
  pencil slot with its icon covering the slot's inner line, an empty slot the paper in its box; heads in Kalam over a
  pencil rule; the sidebar in graphite, the chosen row shaded; the View dropdown, Sell Junk and Deposit leather
  patches; a list's coloured names outlined. Bodies sized through `Board.Body`/`Board.Least`.
- **The alts** (`Alts.lua`, `Roster.lua`, `Items.lua`): the same page and pencil, the roster's names in their class
  colour outlined, the head's level line as ink, worn gear in pencil slots.
- Interface lab: the scene `inventory` (Core and Inventory, the module as `LabInventory` in the console);
  `Lab.Blizzard(name)` loads one more of Blizzard's addons; a scroll frame tells its scroll only when it changes, as
  the game does (Blizzard's scroll bar and frame set each other). The draft `Journal.lua` and its scene now use Core.
- Tests: the sheet's, the bags' and the inventory's checks follow the doll and the paper; the test stub has
  `CreateFont`.

### dev: Blizzard's code and art from the newest export, never references/ (Saneroki, 2026-10-22)
- A hard rule (Saneroki, 2026-10-22): Sane UI's tools read Blizzard's interface code and art from the newest
  export, the build with the highest version number in the exports' folder this computer's settings name
  (`~/.config/saneui/blizzard.json`, `{"exports": "<folder>"}`, or `$BLIZZARD_EXPORTS`; one
  `<product>-<version>/interface/` folder a build, with `BlizzardInterfaceCode/` and `BlizzardInterfaceArt/` in the
  game's export layout). Read straight from the install, without starting the game: Forever 1.60.1.70532, 4,482
  code files (all but 27 byte for byte the export in `references/`, which 70532 changed or dropped) and 135,442
  pictures (the settings panel's frames among the 1,633 new ones). `references/` stays only to compare with.
- `dev/blizzard/export.py`: `exports_folder()`, `all_exports()`, `newest()`, `required()`. `dev/tools/blizzard`:
  `where` (the newest export's folders and build); `check` and `show` compare the newest with the export before it
  (or `--old`); `uses` reads the newest; `adopt` remakes the files made from it (CVarLabels, Pages) and copies
  nothing into `references/` any more.
- On the newest export now: `dev/tools/cvar-labels`, `dev/tools/sync-pages` (both up to date with it),
  `dev/tools/game-data` (the API documentation), the interface lab (`dev/tools/ui-lab` and its host: Blizzard's code,
  documentation and art; it passes the code's folder to the host), the views' game icons
  (`dev/imagegen/sets/interface/compose.py`), `dev/tests/uilab.py`. `dev/tests/blizzard.py`: the exports' folder (78
  checks).
- Docs: `Doc/guides/blizzard-updates.md` (the base, the pipeline), the guides that sent to `references/`
  (gui-development, windows, addon-standards, blizzard-design-principles, images, image-generation,
  voice-generation, ui-lab, data), `Doc/agent/development.md`, the source *game*'s words in
  `assets/data/sources.toml`.

### Navigation: long walks found fast and priced near-exactly, by a coarse layer over the walking data (Saneroki, 2026-10-22)
- Far pins took seconds to plan: on the real data outside the game 505 ms a route, 3.4 s at worst, 95 % of it the
  searches; 13 of 383 searches stopped at `Search.MOST` (200,000 rectangles), every one a walk 5 to 11 times its
  straight line (a Horde character deep in the Alliance's lands) that the journey had guessed at 1.3 times it. A
  search looked at every rectangle as near as its walk was long.
- **The coarse layer** (`dev/tools/walk-gates`, new, `saneui makewalkgates`; Core's set *Walking*, the new field
  `gates`, 2.0 MB: the set 26.1 MB): per terrain tile its gates (where a part of the tile, the rectangles one walks
  between without leaving it, meets a part of the next tile across their border, cut into pieces of at most 64
  samples) and what the walk between each two gates of a part costs inside the tile (Dijkstra over its rectangles, the
  line pulled through the openings: yards on land, swum, climbed, gone down, packed in one number; chosen on foot, a
  yard swum at 1.5, and where it swims again for a rider, at 3). Its check is the CRC of the blocks it was made from.
  Made from the master in some 40 seconds; taken in with `--take` (a new field at the same build). 21,898 gates,
  311,570 ways.
- `Gates.lua` (new, in the TOC after `Walk.lua`): reads it (`Gates.Tile`, the `Gates.KEEP` 400 asked for last kept,
  some 16 KB each; `Gates.Cost` at the walker's price, the cheaper of the way on foot and the rider's; `Gates.Parts`,
  `Gates.Edges` of a walking tile; `Gates.Id`, `Gates.Ends`); a tile's layer made from another block (another number
  of rectangles) is passed over there.
- `Search.lua`: in two steps. `Search.Price`: rectangle by rectangle only on the start's tiles and the end's, across
  every other by its gates; where the two lie apart guided out of the start's tiles by the costs found back from the
  end over the gates first (`Back`, `Search.SLACK`); a start priced again in one plan goes out of its tiles as the
  first time (`Out`, the planner's memo). `Search.Walk(..., found)`: the line along that coarse way, rectangle by
  rectangle on its tiles only, each step aimed at its next gate, what is left estimated along it `Search.AIM` (1.2)
  times; on every tile where that finds none. One search function with options (`Run`), the line (`Line`), the way
  (`Way`).
- `Planner.lua`: `Find` prices the chosen journey's walks first (`Search.Price`) and chooses again by the prices; once
  the journey stays, each walk is searched along its coarse way for its line. `Planner.BUDGET` counts nodes. The
  coarse layer let go with the walking tiles (`Gates.Forget`).
- `Walk.lua`: a tile unpacked without its openings, worked out the first time a search or the floor's following needs
  them (`Walk.Links`): looking up the floors at a place needs none (an unpacking 0.1 ms and 310 KB then, with its
  openings some 5 ms and 1.5 MB); each rectangle's surface kept (`tile.surface`, for the parts); `Walk.Unpack` shared.
- Measured on the real data (200 routes between NPCs, both sides): 119 ms a route (505), the slowest 0.7 s (3.4),
  indoors 118 ms; 0 none, 1 walk drawn straight (9: the capped walks are found), 1 off the data, 0 not from the player;
  none stopped at `Search.MOST`; with the game's 48 tiles kept unpacked 213 ms, the slowest 1.0 s (the code before did
  not finish so). Of 40 walks of 300 to 8,000 yards the price within 3 % of the old search's cost, the line's cost
  0.2 % over on the median (2.8 % at the 90th), 70 ms a walk (700). The 29 fixed journeys keep their legs; the 16
  teleport journeys all from the player to the pin.
- Tests: `dev/tests/navigation.lua` (551: a tile's gates, their costs both ways, at a price and a rider's, the parts
  and edges, the openings once needed; a walk across a walled tile priced by the gates and drawn through its door,
  priced again from its way out, over a stale layer; the planner's line through the door); `dev/tests/walk.py` (159:
  the tool's parts, gates, ways through a door and round a pond, its numbers and field; the master's layer made from
  its blocks as they are).

### Navigation: walks timed at the character's own speeds, water priced by them (Saneroki, 2026-10-22)
- Routes swam where land was there: from Westfall to Stormwind harbor's boat a walk swam 942 yards along the coast
  at Longshore, the dry way through the Valley of Heroes and the city 73 % longer; with a yard swum at twice a yard
  walked (`Search.WATER` 2) that was the cheapest. One swims at about 60 % of one's speed on foot (Saneroki) and far
  slower than one rides (60 % mount: 2.4 times, epic: 3), so for a rider the land is quicker.
- `Planner.lua`: `Speeds`: the character's speed on land and in water as the game tells it (`GetUnitSpeed`, with a
  mount, form or aspect), on land at least the fastest it was seen riding (`Ridden`, at each look at the floor:
  mounted, not on a flight's mount; kept per character as `ride`), else `Planner.RUN` and `Planner.SWIM` (new, 4.2:
  60 % of 7). Each plan (`Find`) times its walks at that land speed (the guess and the walk found; before
  `Planner.RUN`) and has each search price a yard swum at land over water speed.
- `Search.lua`: `Search.Walk(..., water)`: a yard swum costs `water` yards (else `Search.WATER`, now 1 / 0.6). Each step
  goes from where a rectangle was entered to where the straight line on to the end crosses the next opening
  (`Through`; before the nearest point of it), so open ground costs its straight way: a dry walk's cost over its
  drawn yards 1.044 to 1.033 (median of 100 journeys). The openings passed kept in three tables (`viaSide`,
  `viaFirst`, `viaLast`): no table made per step; squares by multiplication, the rectangle's own cost and height read
  once.
- `Walk.lua`: `Walk.Portal` reads the rectangle's numbers itself.
- On the real data (the offline checks): of the walks of 100 journeys 4.5 % of the yards were swum, now on foot 5.5,
  on a 60 % mount 3.9, on an epic one 2.9; the 200-journey scan unchanged (0 none, 9 drawn straight, 1 off, 0 not from
  the player) at 505 ms a route (532 before), indoors 493; the 29 fixed journeys the same legs (one in the Undercity
  by the lift beside), their walks 0.2 % shorter; the 16 teleport journeys from the player to the pin.
- Tests: `dev/tests/navigation.lua` (537: from hall to hall at row 170 the channel on foot, the door for a rider; the
  planner by the character's speeds, riding kept, not a flight's).

### Navigation: the golden line's corners curved (Saneroki, 2026-10-22)
- `Route.lua`: a corner of a leg that turns more than `Route.BEND` (10) degrees is drawn as a quadratic curve from a
  point before it to one after it, the corner its middle point (Saneroki asked for a curve over three points: a way
  round many corners showed as short straight lines). It reaches along both parts as far as cuts the corner
  `Route.STRAY` (6) units deep (half its reach times the sine of half the turn), at most to a part's middle, so short
  parts one after the other make one smooth line; drawn in an even number of pieces turning about 10 degrees each,
  none shorter than `Route.PIECE` (2) units; all three scaled with the route's pin size. A leg's points form runs
  on the view's plane (`Lay`, `Run`, `Bend`, `Half`, `Curve`, `Piece`); each piece is tested against the view's
  rectangle in the holder's units (`Near` gone).
- Each piece stands for a share of the way's part (`t0`, `t1`): the cut (`Against`, `Share`) finds the piece the
  player is on (`on`) and draws it from there; the head ends on that piece, so it meets the curve.
- The art runs on along the leg (`along`: the texture coordinates continue from piece to piece, the head's into the
  line), and each glint starts at the pulse's moment (`Play(false, GetTime() % Route.PULSE)`; `Route.PULSE` is
  `Route.xml`'s 1.2 seconds), so the pieces pulse as one line wherever they came into view.
- Tests: `dev/tests/navigation.lua` (535: a right angle a curve of pieces end to end, each turning little, 6 units
  deep and no deeper; its art running on, the glints in step, Route.xml's duration; a turn under 10 degrees a corner
  still; the player on the curve, the head meeting it). The stub's `Play` keeps its offset.

### Core, dev: the beta's copy of Sane UI with its own data sets (2026-10-22)
- In the game, every route was one straight line to its pin: the beta's client (`_classic_beta_`, game version
  `forever-beta`) had a copy of live's folder, whose sets (all made for `forever`) it refuses, so Navigation planned
  without the walking data and Travel (the error log: "Walking is not used: made for forever, this client is
  forever-beta").
- `dev/build --install` (`saneui installdev`, `installrelease`): into each game folder of Forever's there is (by its
  product, `.flavor.info`: live's `_forever_`, the beta's `_classic_beta_`; not retail's), each with its own game
  version's sets: a beta's or PTR's copy of Core keeps its `Sets/` while the rest is copied, and has them made anew
  from the master after it, so it never holds live's. `WOW_FOREVER` names one folder alone, as before.
- `saneui showerrors` (`dev/tools/errors`) reads the game folder played last (whose `SaneUI.lua` was written last);
  `saneui installed` names the build in each game folder.
- `Data.Add`: set files of another game version are refused as before, but said once for them all (`data: game`:
  "Sane UI's data is not used: made for forever, this client is forever-beta"), not in a chat line for each of the
  37 sets.
- README.md (*How to use*, *Building*), `Doc/guides/data.md` (*Loading*). Tests: `dev/tests/data.lua` (209: the sets
  of another game version said once).

### dev: the interface lab reads frame XML and loads Core from its TOC (2026-10-22)
- Frame XML (`dev/uilab/lab/xmlui.lua`), read as the game reads it: `<Script>` and `<Include>`, fonts, frames,
  regions and animations; a virtual one a template for `CreateFrame`, `inherits` and `CreateTexture`, an intrinsic
  one a kind of its own (`CreateFrame("EventFrame")`, `"DropdownButton"`). Attributes and parts: names with
  `$parent`, `parentKey` and `parentArray` (a template's too), `mixin`, `Size`, `Anchors` with `relativeKey` (set
  once the object's parts are all there), `Layers`, `Frames`, `Scripts` (`method`, `function`, inline code with the
  game's argument names, `inherit`, `intrinsicOrder`), `KeyValues` (dotted globals), the buttons' textures and
  fonts, `ThumbTexture`, `BarTexture`, `ScrollChild`, `Animations`; OnLoads children first. `C_XMLUtil` tells a
  template. An addon's TOC-listed XML is read (`Lab.TOC`), and a scene's own (`Lab.Addon`).
- Blizzard's interface loaded from its TOCs as this client loads it (`camelot`, `mainline`, `[Family]`,
  `[Game]`), Lua and XML with their dependencies: the shared XML and its templates (`UIPanelButtonTemplate`,
  `TabSystemTemplate`, the check boxes, input boxes, dropdowns, scroll boxes), its fonts, the panel manager and the
  settings panel, so `Settings` is the game's own. Its `print` writes to the lab's log; `import` for its modules.
- What the game documents but the lab does not do: namespaces and global functions are there too, and told when
  called (as methods were); `Enum`'s `Meta`; the extensions of `string`, `table` and `math`; a script's name in any
  case; scripts of textures and font strings; events heard by functions (`RegisterEventCallback`); the events
  Blizzard's code registers known. The client's state Core needs, as documented: `C_EditMode` (layouts, sent at
  the login), the chat windows' settings, `C_SettingsUtil`, `C_CVar.GetCVarInfo`, `C_Texture.GetAtlasInfo`, the
  bag slots' constants.
- Set right: `IsMouseOver`'s offsets move each edge outward as in the game; a font string's size 0 is its text's;
  uncompressed BLP files are read.
- Core's caught errors (its error log) show in the lab's log as errors. Scenes `core` (Core from its TOC, its
  window to try windows with, `/sane options` opens its options) and `xml-templates` (a window from the scene's own
  XML on Blizzard's templates); `dev/tests/uilab.py` checks the XML reader (`dev/tests/uilab/`), Blizzard's
  templates and Core; `saneui checkuilab` is clean for every scene. Guide: `Doc/guides/ui-lab.md`.

### Navigation: the routing finalized (2026-10-22)
- Read through with its docs (the planner, the search, the walking data's reader, the lifts, Core's teleports, the
  line, the trip view); set right:
  - `Planner.lua`: a portal a few yards across (the Wizard's Sanctum's two, Dalaran's Violet Citadel's: 6 to 42
    yards, a hundred and more up or down) left the floor followed as it was before it, as only a leap of
    `Planner.LEAP` yards took it anew. A hop now (`Planner.HOP`, 20 yards a second between two looks, `seen`) from a
    portal's trigger, at its height, to its other end is that portal: its end's floor is followed
    (`Arrival(map, u, v, fu, fv, fz)`). After a leap the nearest end or landing, not the first found (Teleport:
    Stormwind lands 12 yards from the Sanctum's top room's portal end).
  - A teleport's landing floor is a guess (`landings`): Teleport: Stormwind's is the Sanctum's cellar, closed in since
    the walking data of 2026-10-22, so no walk left it and routes never took it.
  - `Find`: a walk between places that share no region that ends only as near as one walks (`{ near = points }`)
    stays none for the journey (`Measured`), and where it stays the way it is drawn as near as one walks, then
    straight (it was drawn straight from its start, and the player on the roads beside it was off the line, planned
    again every `Planner.AGAIN` seconds).
  - `Walk.Forget` (no caller): when the route is switched off, and on the walking data's stamp; the stamps' listeners
    behind `ns.Guard`. `Plane(nil)` is none (it raised: a flight begun where the game told no place); `Trips`: a
    flight kept over a `/reload` without its world map is not kept.
  - Gone: `Route.Way`, `Coords.WORLD`, `Data.ShipsReader`, the steps' `teleport`, `tram` and `portal`, and the
    built-in clean-up of the characters' old `flights` (a one-time clean-up is a step of development, not the
    addon's).
  - Comments and docs as the code is: `Planner.lua` (its header: the retries, the floor, the re-plans; `Find`'s
    description above it), `Route.lua`, `Walk.lua`, `Lifts.lua`, `Steps.lua`, `Ships.lua`; `src/Navigation/README.md`,
    `Doc/ideas/Navigation.md` (the planner's first design, the packs that went, its data, failures and pin
    catalogue, open question 1), `Doc/agent/navigation.md`, `Doc/guides/data.md`, Travel's `schema.toml`.
- Checked on the real data (outside the game, the walking data of 2026-10-22): the 29 fixed journeys keep their legs;
  of the 16 with and without a teleport only Teleport: Stormwind's changed (taken now: the teleport, then 644 yards on
  foot to the Cathedral); of 200 journeys between NPCs' places (outdoors; indoors in turn) none without a way, 9 (8)
  walks drawn straight (10, 9 before), 1 drawn as near as one walks (Archmage Xylem's tower), none from elsewhere than
  the player; 571 ms a route (627), the slowest 3.9 s (4.4).
- Tests: `dev/tests/navigation.lua` (530 checks: through a portal a few yards across, up onto a roof, its floor
  followed; a pin on a mesa no lift reaches, as near as one walks, then straight; the old list's clean-up gone; the
  test portal 14 on tile 6179).

### Navigation: a world tile's words its zone's kind, colours and light only (2026-10-22)
- `dev/tools/map-layers tiles`: a square takes `tile_words`: the far level's pictures and look, its main zone's
  kind of place, colours and light, the last sentence; never the zone's land, plants, buildings, roads or places,
  nor the zones beside it (Elwynn Forest's lakes were painted into a square of its forest, its outlines 0.10; with
  these words 0.46, the layout of the zone's render kept). Tests: `dev/tests/map_layers.py` (63 checks).

### Navigation: the world map of high resolution tiles; the world map offline; the instance maps (Saneroki, 2026-10-22)
- **The world's tiles** (`dev/tools/map-layers tiles`; Saneroki: the far renders so precise that the world map is
  made of them, tiny tiles for extreme zoom, the final tiles of the game's map): every land square of the Atlas'
  plan (1456, a terrain tile at 2048 pixels) painted with the far harness, coarse to fine: its colour and light from
  the zones' far renders over it (`Coarse`, as `stitch` lays them), its shapes from the game's terrain, its heights
  and water lines the controls, its main zone's words and the zones beside it; checked for writing, outlines and
  water; into `assets/generated/world-tiles/` in the Atlas' run layout. The water dark blue, dark blue-green in the
  shallows, and the far words ask for dark water lit like the land (Saneroki: the bright blue stood out).
- **The world map offline** (`dev/tools/world-map`, new; `saneui makeworldmap`, `showworldmap`; the page in
  `dev/tools/world-map-page/`): every layer laid where the game lays it and stacked, a slider each, zoomed from a
  continent to the finest blocks (the level chosen as the game's `Painted.Level`): the game's terrain (its minimap
  tiles as blocks) and zone maps, our zone renders and maps (cut by the zones' outlines), our tiles packed by the
  Atlas' own pack, the Atlas' pack read by `src/Atlas/Atlas.lua` itself under Lua 5.1 (`dev/tools/world-map-index.lua`);
  a selector for the world or any instance, each a view of its own.
- `dev/tools/atlas`: `pack` writes through a given writer (`block`: the viewer's pictures of the game's blocks); its
  joins between squares and between rows in two bands too (`two_bands`, shared with `join_two`).
- **The instances**: all 30 dungeons and raids, their terrain extracted from the install (the maps of a building
  alone placed by their WDT: `buildings_of` reads it, from the world's middle); `paint --kind`.
- `jobs.toml`: `worldtiles` (priority 10: the zones' far renders, then the squares) and `instancemaps` (priority 2:
  each instance's far render) in place of `atlas`, `zonemaps`, `mapcompare` and the finished `interface`.
- Docs: `Navigation.md`, `map-style.md`, `image-generation.md`, `levels.toml`, `Doc/agent/development.md`.

### Core, Navigation: the map window stands at login again; the tools in Forever's own game folder (2026-10-22)
- `Window.lua` (`Square`): a title bar button's sign in words is `art.sign` (the full screen's question mark). Since
  24a647c a module's own button (`options.buttons`) took its tip's words (`text`) for such a sign: the quest log's pin
  was words, not a picture, its look failed (`QuestLog.lua`, `PinLook`: `SetAtlas` on a font string), and at every
  login Navigation gave the map and the minimap back to the game, so no map, pins or routes of ours; the demo's
  button showed its tip's words.
- The tools' game folder (`dev/build`, `dev/tools/errors`, `dev/tools/blizzard`, `dev/saneui`; `WOW_FOREVER` still
  overrides): Forever's own `_forever_` (product `wowf`), where the game is played since 2026-10-21, in place of the
  beta's `_classic_beta_`. Core's sets go in there as Forever live's: the copy of the beta's install standing there
  had sets made for the beta, which Core left unused (walking, travel and every other). `README.md`: installed into
  `_forever_`.
- Tests: `dev/tests/wowstub.lua`: a font string has no picture's calls (`SetAtlas`, `SetTexture`, `SetColorTexture`,
  `SetTexCoord`), a texture none of words' (`SetText`, `SetFont`, `SetFontObject`), as in the game;
  `dev/tests/window.lua` (412 checks: a module's own button shows its picture, its tip's words in its tip); the quest
  log's pin in `dev/tests/navigation.lua` now fails on the old code as the game did.

### Navigation: no walk after a walk at a flight point (2026-10-22)
- `Planner.lua` (`Journey`): taking off is part of the first flight (from a known flight point on the ground, its
  flights each at `Planner.BOARD` more; the way `"up"` is gone), so the air over a flight point is reached by a flight
  only and one comes down there (`"down"`) only after a flight. Before, a route that walked to a flight point went up
  and straight down again (8 seconds) and walked on, from every floor at it (the lowest first): from the Undercity's
  lift to Sylvanas 78 yards to the bat handler on the ring and 588 on from the floor under it, where one walk from the
  lift is 748; and round regions the search had found no walk between (the Horde from Teldrassil: straight to
  Nighthaven's flight point, on to Moonglade's other one). A flight that lands still walks on; walk, take off and fly
  cost as before.
- Checked on the real data (outside the game, the walking data of 2026-10-22): of 29 fixed journeys only Orgrimmar to
  Sylvanas changed (the zeppelin, down a lift, one walk of 748 yards), so too from Brill, the zeppelin tower and the
  ruins to her; of 200 journeys between NPCs' places (outdoors; indoors in turn) the 7 (8) that walked twice in a row
  no longer do, walks drawn straight 14 to 10, none, off the data and not from the player 0 as before, 619 ms a route
  (643), the slowest 4.3 s (5.8).
- Tests: `dev/tests/navigation.lua` (528 checks: a known flight point on a mesa's edge by its lift, between the two
  levels the lift joins: from the field to the mesa the lift, not a walk to the flight point and on from it).

### Navigation: the maps' middle tries keep their zone's colours; the stitched middle level over a sea of its own (2026-10-22)
- `dev/tools/map-layers`: the middle level's three tries all skip one step (`STRENGTH` 0.95 each, a try another
  seed; the third from noise lost the zone's colours: Duskwood came out pale); `stitch` lays the middle level's
  zones each only within its outline over a faded grey-blue wash on the parchment (`SEA_WASH`; the zones' whole
  paintings under them showed their frames' edges), the far level's over the zones' whole photographs as before.
- Westfall, Elwynn Forest and Duskwood stitched at both levels: the far level meets seamlessly along the outlines.

### Navigation: the Atlas' middle and far levels of every zone queued (Saneroki, 2026-10-22)
- `jobs.toml`: `zonemaps` (priority 10, beside `atlas`): every zone's and city's middle and far levels, 49 zones
  (Saneroki: render everything at all three levels so the Atlas works in the game; the close level is the job
  `atlas`, held). Their inputs are made (`map-layers inputs`, 44 zones more).
- `dev/tools/map-layers`: `paint --kind zone|instance`; a far painting passes without the vision model's "not a map"
  (it called every photograph straight down a map, so every zone took three tries); none passing, a painting
  without writing is kept before one with it (Ashenvale's middle level); an instance without map art takes
  Uldaman's manner.
- Compared (a local page, not kept): Duskwood, Ashenvale, the Deadmines and the Hall of Thanes, the game's terrain
  and maps under our three levels. The instances' full run waits for the new game build's tables (1.60.1.70532).
- Docs: `Navigation.md`, `map-style.md`, `image-generation.md`. Tests: `dev/tests/map_layers.py` (62 checks).

### Navigation: the walking data's openings both ways, on both rectangles; the portals' rooms (Saneroki, 2026-10-22)
- `dev/tools/walk-data`: `openings` and `across` link every floor beside a rectangle's edge one way with its own (they
  took the first: the way back of a floor beside two went to the other and was lost, 129,510 samples apart from their
  region's main part, 4,016 openings into the next tile one way only), only between rectangles that meet along that
  side (`meets`). `cuts` ends a surface's rectangles where one of its floors is one way with another surface's floor
  beside it while the surface goes on there, so every opening lies on both rectangles' sides (113,241 did not:
  `Walk.lua` set their way back elsewhere, and lines pulled through them ran over no floor); `shared` asks that the
  two meet (`block` wrote such pairs whole, and `Walk.lua`'s `Side` took the west).
- `through`: two floors of different surfaces are no way where the higher goes on into the lower one's sample over it
  (a deck and the ground under its next sample, 2 to 2.6 yards apart). `bridges` keeps one such way between two parts
  of a tile no other opening joins (a hall whose door is a wall in the data, Lordaeron's inner ruins), and `plan` cuts
  the rectangles again for it: every join the data had stays (Saneroki).
- `ends` (was `lifts`): the lifts' and the portals' ends; the regions they land on are kept however small (the Wizard's
  Sanctum's cellar and top, the Skyborne portal's room, the Violet Citadel's top).
- Core's set *Walking* rebuilt: 412 regions, 3.03 million rectangles (2.83), 24.1 MB (23.7); the two tiles of Zephras
  Isle the tool no longer writes marked gone. Checked outside the game: no islands, no opening without its way back or
  off its rectangles, all 14 lifts and 8 portals land; 200 journeys between NPCs: none failing, 14 drawn straight (14),
  none off the data (7), about 5 % slower; spawn points on a floor at their height 85.07 % (84.95 %).
- Tests: `dev/tests/walk.py` (147 checks: two floors beside a floor, both ways on a tile and into the next; a deck over
  the ground, its rectangles cut where it begins; a hall walled round, kept by one way under its floor; the portals'
  ends and rooms; runs of an opening joined).

### Atlas, Navigation: the close squares joined in two bands, no harsh line between them (Saneroki, 2026-10-22)
- `dev/tools/atlas`'s `join_two` (the Atlas' squares and the maps' close levels alike): where two squares overlap
  (SQ - STEP, 256 pixels), their fine detail still meets along the line where they differ least (`seam`:
  interlocking, never both trees), but their colour and light (blurred by `SOFT`, 24 pixels) fade from one to the
  other across the whole overlap, so a square a little lighter than its neighbour leaves no step at the line.
- Tests: `dev/tests/atlas.py` (two plain squares of different light meet without a step; the overlap's ends are the
  squares' own).

### Navigation: the maps' three levels all from straight above, each zone on its own, joined (Saneroki, 2026-10-22)
- Saneroki: all three levels seen straight from above in the same world coordinates, so every road, major place and
  pin is in the same spot in each; each zone painted on its own and the zones joined along their outlines; the far
  level's view from a plane at an angle given up (`Navigation.md`, *All three from straight above*).
- `dev/tools/map-layers`:
  - **Far, straight down:** image 1 the zone's terrain in its frame, its water a sea's blue, lightly blurred
    (`FAR_BLUR` 5: its roads and towns faint); the controls its heights (`height_map`) and the walking data's water
    lines (`far_inputs`); an instance's its plan blurred with its clearest edges; outlines measured against the
    terrain plan. Gone: the relief seen from a plane, the plane view, the far box, the continent views.
  - **Middle, each zone in its own colour:** the parchment the game maps' yellow-orange turned towards the zone's
    land (`land_tone`: the median of its terrain inside its outline, stronger by `LAND_COLOUR`: Westfall golden,
    Elwynn Forest and Duskwood green); an instance's in its game map's colour (`tone_of`); the words keep image 1's
    tints, the water a faded grey-blue wash (`levels.toml`).
  - **`stitch`:** the painted zones' middle and far levels laid on their continent, each cut by its outline
    (Navigation's zone masks, `Art/Zones/`), the zones' whole paintings under them.
  - **`paint --whole-close`:** a subject's close level over its whole frame; a far level of a zone without a close
    level takes another zone's on its map.
- `jobs.toml`: `mapcompare` (priority 2): Duskwood's and Ashenvale's close levels whole, 35 and 126 squares, for
  comparing all three levels with the game's maps.
- Docs: `map-style.md`, `image-generation.md`, `levels.toml`, `Navigation.md`.
- Tests: `dev/tests/map_layers.py` (61 checks: the height map, the walking picture framed, the land tone, the
  words straight down).

### Navigation: the whole Undercity below its lifts' upper level (Saneroki, 2026-10-22)
- `Lifts.lua`: within one region (the Undercity under the ruins) a place stands below a lift's upper level on a map
  the lift's ends lie on (`Round`: in that map's box, in the lift's plane), or within `Lifts.SPREAD` yards of the
  lift (one on no map). Before, only within `SPREAD` (250 yards), and the Royal Quarter lies 265 to 330 yards from
  the city's three lifts, the Magic Quarter's far end 256: they counted as on the ruins. So from where Teleport:
  Undercity lands (or a hearthstone bound there) to Sylvanas the route went up a lift, over the surface and down by
  the sewers (1,577 yards where one walk is 881); from her to the flight master, the inn or the bank the walk ended
  on the canal under a lift's top and the line rode down from there; from Brill, the zeppelin tower or the ruins the
  walk ended on the hill over her.
- Checked on the real data (outside the game): the city's floors under the surface reach 344 yards from the nearest
  lift, 9 % beyond `SPREAD`, all in the Undercity map's box. Now the teleport and the hearthstone are one walk of
  881 yards (52 to the Magic Quarter's mage trainers), walks within the city stay in it, and from the surface the
  route takes a lift down to her floor. 200 journeys between NPCs' places, outdoors and indoors: the same, route for
  route (0 none, 14 straight, 7 off the data); of the fixed journeys only Orgrimmar to Sylvanas changed (the
  zeppelin, then down a lift). Thunder Bluff, Freewind Post, Gnomeregan and the Great Lift as they were.
- Tests: `dev/tests/navigation.lua` (527 checks: a lift within one region on its city's map, the city's hall
  reaching beyond `SPREAD`: from the lift's foot to its far end on foot, from there out by the lift).

### Navigation: the maps' far level tuned, a copy never kept (Saneroki, 2026-10-22)
- `dev/tools/map-layers`: a zone's water in the far image 1 shaded as a sea seen from a plane (`sea_of`: `SEA` deep,
  `SHALLOWS` where the game's water is lighter; beyond the terrain the deep sea), its colours toned down further
  (`FAR_COLOUR` 0.65); an instance's guide its clearest edges only (`EDGES` 0.96); a far painting whose outlines
  agree past `COPY` (0.97) is its image 1 come back as it is, never kept (the Hall of Thanes' plan on grey).
- The controls light and early (stronger and longer they kept the game's look): a zone's depth 0.35 to 30 % of the
  steps and its water 0.5 to 35 % (`qwen21-edit-2ref-i2i-cn2`), an instance's edges 0.35 to 30 %
  (`qwen21-edit-2ref-i2i-cn`); a zone's words ask for a real camera (`levels.toml`'s `look_relief`).
- Samples painted at all three levels: Westfall, Tanaris, the Deadmines, Zul'Farrak, the Hall of Thanes.
- Tests: `dev/tests/map_layers.py` (61 checks: the sea's shades).

### Navigation: the maps' far level a view of the terrain standing up, its layout held by controls (Saneroki, 2026-10-22)
- `dev/tools/map-layers`, the far level painted anew (Saneroki: rough places for lakes, rivers, landmarks, mountains
  and the ground nobody crosses, some leeway, a perspective view from a plane):
  - **A zone:** `relief` draws the terrain around the frame from a plane, its heights standing up (the terrain files'
    heights, `Ground.heights`, under the minimap textures, as the voxel spaces of old drew land; `far_box` widens the
    plan so no corner of the view lies beyond it; the open sea where there is no terrain); its water a sea's blue,
    blurred and toned down (`far_colours`) as image 1; two controls of the Fun ControlNet Union (new workflow
    `qwen21-edit-2ref-i2i-cn2`): its depth and the lines where Core's set *Walking*'s water meets land (`Walking`,
    `guide_of`); its words name the zones around it by direction (`around_of`, `levels.toml`'s `around`).
  - **An instance:** its plan warped into the view (`plane_view`; its halls lie under rock), blurred, its clear
    edges the control (`edges_of`, new workflow `qwen21-edit-2ref-i2i-cn`).
  - Painted from noise (`STRENGTH` far 1.0), a try another seed; a zone's water checked against the walking data's
    (`water_check`: `atlas`'s `check` takes the game's water, what it does not know and how far a shore may stray).
  - Learned on Westfall: ComfyUI's strength is in steps (25 steps: 0.927 to 0.961 skip one, above it none; the
    earlier "0.97 loses the frame" was that); the sharp view as image 1 came back as the game's own terrain; the
    walking data's barriers as lines came back as lakes.
- Docs: `map-style.md`, `image-generation.md` (*Far*, *Strength is in steps*), `levels.toml`, `Navigation.md`.
- Tests: `dev/tests/map_layers.py` (60 checks: the walking blocks read, the relief's view, depth and far box, the
  water guide and check, the lands around a zone, the words).

### Navigation, Core: the teleports a character has in the routes; what Core learns in play; Frequent Flier (Saneroki, 2026-10-21)
- **The teleports** (Core's set *Travel*, kind `teleport`, key 3000000 + the spell's ID; new fields `spell`, `items`,
  `reagent`; `dev/tools/travel-data --teleports <places> <batch>`, `teleports`, `race_side`, `teleport_places`): from
  Forever's client every class's spell whose effect moves one to a place the server holds (the mage's to Stormwind,
  Ironforge, Darnassus, the Undercity, Thunder Bluff, Orgrimmar and Dalaran, each its side by its race mask and its
  reagent, the Rune of Teleportation; the druid's to Moonglade) and the items' of `ITEM_TELEPORTS` (the engineers'
  transporters to Everlook, Gadgetzan and Mount Hyjal, Forever's four and Classic's two; the Crumbling Hearthstone):
  twelve. Not the SAF-T Teleport (Tinker: Teleport, a few yards).
- **Batch 14** (`sources.toml`, unverified): where seven of them bring one, the original game's place where every
  record of it agrees, on a continent, with a floor of Forever's own world there (Stormwind, Ironforge, the Undercity,
  Thunder Bluff, Orgrimmar, Moonglade, Everlook); Darnassus' left out (two places 13 yards apart).
- **What Core learns in play** (the data plan's 1c.1 built ahead; `Doc/guides/data.md`, *Learned*): `Data.Learn(set,
  key, record)` keeps a whole row of the set (`Codec.Encoder`, new: the decoder turned round) of the client's build
  and the server's day in the new saved variable `SaneUIData_Learned` (Core's TOC, `Data.SAVED`); read over the set's
  own at once (its stamp moves) and at the login, dropped once the set has a version of that entry as new or newer.
- **Where a teleport brings one, learnt** (`src/Core/Data/Teleports.lua`, new in Core's TOC): after the player cast a
  teleport's spell, a leap of `LEAP` (50) yards between two looks a quarter second apart, or onto another map after a
  loading screen, is the teleport; where it ends (no height: the game tells none) is learnt into *Travel*; within
  `SAME` (2) yards of the set's place nothing.
- **The planner** (`Planner.lua`: `Teleports`, `Usable`, `Spell`, `Item`, `Held`, `landings`): from the player to where
  each brings one, the teleports the character has now (a spell known, `C_SpellBook.IsSpellKnown`, with its reagent
  in the bags; an item in the bags that the game lets it use, `C_Item.IsUsableItem`; of its side or of both), their
  cooldown and `Planner.HEARTH`; on its floor where its height is known (`Walk.Landing`), after the leap the floor
  followed there (`Arrival`); drawn pale blue (`Route.COLOURS.teleport`). The hearthstone's way by Astral Recall
  too (`Planner.RECALL`, the sooner of the two). The Legacy perk Frequent Flier (`Planner.FLIER`, `Planner.Pace`):
  flights `Planner.FASTER` (1.2) times as fast where the game tells the character has it (its spell, or its aura).
- **On the real data** (the routes harness): the mage from Goldshire to the Cathedral, from Kharanos to Ironforge,
  from the Crossroads to Thunder Bluff, from Orgrimmar into the Undercity; the druid from Stormwind to Nighthaven; the
  engineer from Orgrimmar to Everlook; without runes none. The 29 fixed journeys and 200 random ones give the same
  legs as before for a character with nothing of it.
- Tests: Navigation 524 (a mage's teleport only with its reagent, the other side's never, a druid's, a transporter
  held, cooling down or unusable; one learnt in play; Astral Recall and its cooldown; Frequent Flier's flight), data
  209 (the encoder; what was learnt, laid over a set at the login, dropped once the set is as new, learnt anew; the
  teleports' watcher: a leap, a loading screen, running on, a landing the set has), walking data (the teleports from
  made-up client tables).

### Navigation: the maps' far level a view from a plane, the close squares joined along seams (Saneroki, 2026-10-21)
- **The far level** (Saneroki: the photographic look is right, but its roads, places and landmarks must fit the middle
  and close levels roughly, lakes, rivers, mountains and the ground nobody can cross with some leeway, seen from a
  plane at an angle): image 1 is the terrain plan of the frame and around it warped into that view
  (`map-layers`' `plane_view`), image 2 a piece of the close level; painted from image 1 a little under full
  strength (`qwen21-edit-2ref-i2i`, new); its outlines must share 0.3 with the plane view. Not the middle drawing as
  a picture (its symbols were stamped on the land), not from nothing (a closer view than the frame).
- **The middle level** paints from the game's map itself (`qwen21-edit-3ref-i2i` at 0.94, 0.96, 0.98), its frame,
  title banner and ornaments made parchment first; the pictures are read for the words at 1024 pixels (three at 2048
  took ComfyUI past the computer's memory).
- **The close level's squares** are joined as the Atlas joins them, each overlap cut where they differ least
  (`map-layers join`).
- `Doc/guides/map-style.md`, `Doc/guides/image-generation.md`, `dev/imagegen/maps/levels.toml` say so. Tests: 38.

### Navigation: the maps' three levels strict, one pipeline for zones and instances (Saneroki, 2026-10-21)
- **Saneroki:** the first far paintings were far too free; all three levels are to be strict maps of the layout. Close
  the terrain, pixel-exact (the world's cleanup pipeline); middle a top-down map in the manner of the game's own maps,
  in pencil on parchment, exactly over the terrain; far a photorealistic render with a very strict harness, its major
  places, borders and walls where they are. `Doc/guides/map-style.md` and `Doc/ideas/Navigation.md` (*Strict maps,
  all three*) say so.
- **`dev/tools/map-layers`** (new; `saneui makemaplayers`), for zones and instances alike, every subject in one frame
  (its box in the world) that its three levels share: `inputs` (the terrain plan from the game's minimap textures, an
  instance's from its own map's tiles with the indoor maps of the buildings they place laid over them; the game's map
  art in the same frame, its frame, title banner and ornaments made parchment); close by the Atlas' own code (squares,
  words, water and lava check, colour pass); middle and far with the new workflow `qwen21-edit-3ref-i2i` (three
  pictures, starting from image 1 itself, its strength rising a try): the middle level from the game's map, the
  terrain plan and the parchment, the far level from the terrain plan, the middle drawing and the close painting;
  each middle and far painting checked for its outlines against the terrain and by the vision model, painted again
  when it fails. `contact` lays a sheet of a subject's inputs and levels.
- **The words** (`dev/imagegen/maps/levels.toml`): edits of image 1 ("make image 1 look like ..., never where or what
  anything is"), which keep the layout; the middle level takes no brief (a first try drew the cove's ship on the mine's
  floor). `dungeons.toml` keeps the briefs only.
- **`dev/tools/dungeon-paint`** (its far paintings, its test and its job) is gone: `map-layers` replaces it.
- Tests: `dev/tests/map_layers.py` (33 checks, new, in `dev/tests/run`).

### Navigation, data: Forever's own ways of travel; Dalaran's airship the Alliance's (Saneroki, 2026-10-21)
- **Which ways Forever has** (its client and what its beta servers sent, against Classic Era's): Classic's five boats,
  three Horde zeppelins, the Deeprun Tram (a second set of cars, the same run) and its lifts (the Undercity's cars
  under new IDs); new: three boats (Menethil by Southshore to Auberdine; Auberdine to Stormwind's harbour, the
  *Mistbound*; Tanaris to the Riverglades), two airships to Zephras Isle (the Skycutters, from Dalaran and from
  Mulgore), portal objects (Stormwind to Dalaran and back, Dalaran's Violet Citadel, Zephras Isle's), a mage's
  Teleport: Dalaran, four flight masters (Mount Hyjal, the Riverglades). `Doc/ideas/Navigation.md`, *Forever's own
  ways*.
- **Batch 13** (`sources.toml`; picked from what Forever's beta servers sent, unverified): the portal objects where a
  pair stands at both places and each one's target lies beside the other (Stormwind's Skyborne Portal to Dalaran and
  Dalaran's back; Dalaran's Violet Citadel up and down), set *Travel*, kind `portal`, keys 2000000 + the object's
  entry; and `side` where the NPCs at a way's ends are hostile to one side only (Forever's faction table): Dalaran's
  Skycutter the Alliance's (the flight-master rule had none near), Stormwind's Wizard's Sanctum portals and the new
  portals too; the Horde's zeppelins and Mulgore's Skycutter agree.
- **The planner** (`Portals`, `Journey`): a portal of the other side is no way (its `side`); Stormwind's Skyborne room
  is not in the walking data yet, so that pair is no way until it is (`Ends`).
- Checked on the real data: both sides to Zephras Isle by their own airship (the Horde no longer by Dalaran); the
  city journeys as before.
- Tests: Navigation 508 checks (the portal the other side's: a Horde character's line goes without it).

### Navigation: the dungeons' paintings researched and held to their words and pictures (Saneroki, 2026-10-21)
- **The briefs** (`dev/imagegen/maps/dungeons.toml`): all 30 instances researched from the game's own lore texts and
  pictures of each place and from what is known of them in play, in the zone briefs' fields: `biome` (what kind of
  place: a cave, a castle, a mine, a temple, a city, a volcano), `buildings`, `places`, `mood`, `colours`,
  `atmosphere` (its light first). Forever runs the classic versions of all 26; its four new dungeons' pictures are
  sketches in one tone (`sketch = true`: their colours are the words').
- **The harness** (`dev/tools/dungeon-paint`, workflow `qwen21-edit-2ref`): image 1 the floors where they lie in the
  world, seen at an angle, a floor over another lifted, parts far apart moved together, the paper around the rooms
  left out (no more side-by-side panels); image 2 the game's own picture of the place (the dungeon journal's
  painting, else the loading screen, cut free of frame and logo; `--pictures`): its architecture, materials, colours,
  light and mood. "This place is <biome>." in the words.
- **The check** (`dev/imagegen/workflows/qwen3vl-look.json`, new): the vision model the image model reads its words
  with looks at each painting (writing, a map or a drawing, panels, seen from above as a whole rather than image 2's view
  copied, the brief's kind of place) and a failed one is painted again with the next seed: three that pass, six
  tries at most. A pilot of four (the Deadmines, Wailing Caverns, Blackrock Spire, the Hall of Thanes) passed three;
  the cave painted from inside, under an arch, was caught. Image 2 is given at 640 pixels (`resolution` 0: each
  picture at its own size), and the shared far look (`levels.toml`) says that all of the place lies below, cut
  open, nothing framing the view: two more caves came out from above and passed. `dungeon-paint check` looks at paintings
  made without it; `contact` marks the failed ones.
- **The queue:** the far level follows the layout and takes the middle and close levels as inspiration (Saneroki),
  so the job `dungeons` is held until they are made; its run is ready (30 layouts, 30 pictures). Written in
  `Doc/guides/map-style.md` (*Strict to its words and pictures*), `Doc/guides/image-generation.md`,
  `Doc/ideas/Navigation.md`, `Doc/agent/development.md`. Tests: `dev/tests/dungeon_paint.py` (383 checks).

### Navigation: boats, zeppelins and the tram of one side only for that side (Saneroki, 2026-10-21)
- **Their side** (Core's set *Travel*, `side` of a boat, a zeppelin and the tram; `dev/tools/travel-data`, `side`):
  `alliance` or `horde` where the way's docks lie within `DOCKSIDE` (600) yards of that side's flight masters alone
  (the client's flight points and their sides: its towns; a town's guards are the server's), none where they are of
  both sides or none (a goblins' port). Horde: Grom'gol's, Orgrimmar's and the Undercity's zeppelins, Mulgore's to
  Zephras Isle; Alliance: Menethil's, Theramore's, Auberdine's, Rut'theran's, Feathermoon's boats, the one from
  Stormwind's harbour, the tram; both: Booty Bay to Ratchet, Steamwheedle Port to the Riverglades, Dalaran's zeppelin.
- **The planner** (`Journey`): a ship or the tram of the other side is no way (its harbours and towers are guarded);
  routes for one side went through the other's (an Alliance character from Tirisfal by the Undercity's zeppelin).
- Tests: Navigation 507 checks (the boat the other side's: no way across the sea, no line), walking data 125 (a way's
  side by the flight masters near its docks, a dock too far from one, a transport's among its fields).

### Navigation: Teldrassil's portal in the routes; a walk not found is none, the journey chosen again (Saneroki, 2026-10-21)
- **The portals** (Core's set *Travel*, kind `portal`; batch 12 of `sources.toml`, unverified; `dev/tools/travel-data
  --portals <places> <batch>`, `portals`, `portal_places`): the game's trigger (its `AreaTrigger`: the client's place)
  and where it brings one (a batch file of our picking); its key 1200000 + the trigger's ID, `path` its two ends with
  their heights, `length`, `from` and `to` (the map's pins: `Data.Map` makes them, the game's portal icon). Four:
  Darnassus and Rut'theran Village, Stormwind's Wizard's Sanctum up and down. The two zeppelins to Zephras Isle now
  name the area of their dock there (Valanaar, 16638, read from the isle's terrain).
- **In the journey** (`Planner.lua`: `Portals`, `Ends`, `Arrival`): a portal's trigger and where it brings one are
  places on their floors (`Walk.Landing` within `Planner.ARRIVE`, 20 yards, at their height; with walking data only a
  portal with a floor at both ends, not yet the Sanctum's, whose rooms the walking data leaves out as small); the way
  through `Planner.PORTAL` (3) seconds, drawn violet; after a leap to where a portal brings one, the floor followed is
  its floor there. `Planner.Floor()`: the floor followed.
- **A walk not found** (`Find`, `Measured`, `Cut`): the journey is chosen again (up to `Planner.TRIES`, 8, while its
  searches have looked at fewer than `Planner.BUDGET`, 400,000 rectangles) with the walk as none, and where its places
  share no region every walk between those regions too; between such places a walk that ends only as near as one walks
  (more than `Search.NEAR` yards off the walking data) is none as well; one with no walking data at an end stays a
  guess, drawn straight. Before, a walk between regions was taken on its guess and drawn straight where none was found
  (Teldrassil's top to Moonglade, Rut'theran up to Dolanaar).
- **No walk after a walk** (`Journey`, `FOOT`, `Place`): a place reached on foot is a node of its own, from which no
  walk goes on (the walk straight on is a way of its own). Walks through places on the way were joined and searched
  as one, their parts never measured, so the choice went round (a 12,000-yard swim over the sea in place of the boat).
- **The search** (`Search.lua`): `Search.Walk` tells the yards from the walking data to the end (its third result) and
  `"off"` where no floor lies near the start or the end; `Search.looked` counts the rectangles of every search; the
  other floors under a start only for a guess (`from.guess`: a floor known is the walk's own; a floor over it,
  Orgrimmar's rim, made an impossible walk look found).
- **Checked on the real data** (outside the game): the city journeys as before, Teldrassil's through the portal; of
  200 journeys between NPCs' places, walks drawn straight 21 before these two changes, 10 after: most for one side deep
  in the other's lands with no ship or flight of its own (a Horde character on Teldrassil), where the budget ends the
  choosing; Archmage Xylem's tower top, nobody walks onto. A plan's searches 563 ms on average outside the game (312
  before), the longest 4.2 s (2.2).
- Tests: Navigation 506 checks (a pin past a portal; the floor after it; a slow portal: the walk between regions not
  found, the portal taken; the floor known: no other), walking data 121 (a portal's record, its ends, left out).

### Navigation: the world's middle level at an angle, the instances' from above (Saneroki, 2026-10-21)
- The world's middle level (the zones' pencil drawings) keeps its perspective angle; an instance's floors are drawn
  straight from above, in the floor's own frame, the ground their close level lies over. `levels.toml`'s shared
  middle look leaves the view to each plan; `dungeons.toml` has the instances' (`view`). Written in
  `Doc/guides/map-style.md`, `Doc/ideas/Navigation.md` and `Doc/guides/image-generation.md`.
- `dev/tools/dungeon-paint`: a run's plan counts as changed only when what its paintings are made with changes (the
  far level's words, the briefs, the workflow), read from the run's own copy, not when the middle level's words do.
  Tests: 272 checks.

### Navigation: the maps' three looks, the instance maps made as the world's (Saneroki, 2026-10-21)
- **The map style guide** (`Doc/guides/map-style.md`, new; in CLAUDE.md's guides): the Atlas and the instance maps in
  three levels, alike: close the terrain pixel-exact (the Atlas' words), middle a beautiful pencil drawing on paper
  in the interface's paper and pencil, traced exactly along the terrain's walls and walkable ground and lying under
  the close level wherever the terrain has nothing to show, far a free realistic reimagination; text, pins and the
  bosses' 3D models are overlays drawn by code, never painted.
- **`Doc/ideas/Navigation.md`:** *The three levels' looks* (the middle zoom no longer a free painting, the instances'
  no longer drawn by code); *Instance maps as the world map, apart from it* (their own view, data and jobs, the
  world's pipeline, words, tools and cleanups).
- **The shared words** (`dev/imagegen/maps/levels.toml`, new): the middle and far levels' look and last sentence,
  for the world and the instances. `dungeons.toml`: the briefs take the zone briefs' fields (mood, places, colours,
  atmosphere), each atmosphere's first sentence a light the Atlas keeps whole for the close level.
- **`dev/tools/dungeon-paint`:** the far level with the shared words; a run keeps its own copy of the plan, as the
  Atlas does. The close and middle levels wait for the instances' terrain. Tests: `dev/tests/dungeon_paint.py`
  (268 checks).

### Navigation: routes from the floor the player is on, not aboard in a dock town (Saneroki, 2026-10-21)
- **Checked on the real data:** the planner, its search and Core's timetables run outside the game over every walking
  tile, the game's flight points and Core's set *Travel*: the journeys through the cities (indoors and out, the tram,
  the lifts, boats and zeppelins over the sea, few flight points known) and 200 between NPCs' places on both
  continents and Zephras Isle, both sides. Every line ran from the player to the pin; these faults were found.
- **Aboard** (`Planner.lua`, `Aboard`): within `Planner.DECK` (40) yards of the plan's boat's or zeppelin's way, where
  it lies more than `Planner.DOCK` yards along it from where it was boarded (`Along`). Standing in the town at its dock,
  within `Planner.ABOARD` yards of the way it comes in or leaves by, took the player aboard, and a new pin was planned
  from where the ship lands (Grom'gol, the Riverglades' port).
- **The player's floor** (`Footing`): one chosen among others under the player (outdoors the highest: the rock
  overhangs over Orgrimmar's streets, a rock's top, a roof) is a guess (`guess`), so are those followed from it, until
  the player stands where one floor alone lies under them; for a guess the journey counts the regions of every floor
  around the player as theirs (no false gap between regions). Chosen anew after a leap of `Planner.LEAP` (50) yards
  between two looks (a portal: the height from before chose the floor at the far end); none on a flight, a boat or a
  zeppelin (`Trips:Now`, `UnitOnTaxi`), chosen anew where the player comes down. The plan's job gets a copy of it.
- **The search** (`Search.lua`): from a floor known at the start, the other floors there too, `Search.ASIDE` (500)
  yards more and not counted in the walk's cost, so a walk is found where none leaves that floor (a wrong guess, a
  floor the walking data closes in); a start with no floor within `Search.REACH` yards takes the nearest within
  `Search.FAR` (a gap in the walking data), straight onto it.
- Tests: Navigation 502 checks (in the dock town, not aboard: planned from the player; from a floor no way leaves:
  from the floor under it, at its own cost; the player outdoors over it: the line from the floor under it; after a
  leap: the floor chosen anew), each failing on the code before.

### Navigation: the dungeons' and raids' paintings planned and queued (Saneroki, 2026-10-21)
- **The plan** (`dev/imagegen/maps/dungeons.toml`, new): the far zoom of the instance maps, one free realistic painting
  of each instance as a whole: the fixed words (edit, levels, last) and a brief for each of 30 instances (the 26 of
  Core's set *Dungeons* and Forever's four new dungeons: setting, layout, colours, atmosphere, no names). The close
  zoom is described there and waits for its inputs (the instances' own indoor maps and terrain).
- **The tool** (`dev/tools/dungeon-paint`, new; `saneui makedungeonmaps`): `paint` makes each instance's image 1
  (its floors side by side in the game's order, from the game's map art of the set's tiles, `--mapart`, cut free of
  frame and title banner, or from given pictures, `--layouts`; contrast stretched, blurred to shapes) and paints
  three seeds an instance with the full Qwen edit model at 2048 x 1360, the first seed of all before the second of
  any, skipping what is made; `status` (`<made> of <all> paintings made`), `contact` (a sheet to choose from),
  `rebuild`, `--dry`.
- **The queue** (`dev/imagegen/jobs.toml`): the job `dungeons`, priority 2; the redesigns of interface parts go
  above it when they are queued. `Doc/guides/image-generation.md` (*Maps*, *The GPU runner*),
  `Doc/ideas/Navigation.md`, `Doc/agent/development.md` and `navigation.md` say so.

### Doc: a travel pin's ways on the map, to come (Saneroki, 2026-10-21)
- `Doc/ideas/Navigation.md` (*Map pins*, what is not there yet) and `Doc/agent/navigation.md` (*What is not there
  yet*): the mouse over a flight point, a boat's or zeppelin's dock or the tram's entrance is to draw the ways the
  character can take from there; flights from or to a flight point not found yet a little differently.

### Doc: what gets redesigned in our own style (Saneroki, 2026-10-21)
- `Doc/guides/interface-style.md`, *To redesign* (new): our own map pin icons (coloured renders, being developed
  soon), the route line as leather stitches in place of the golden line, the raid markers in our own style.
- Noted where they stand: `Doc/ideas/Navigation.md` (*Map pins*, *Our own data*, *Waypoint and route*, *The golden
  line*), `Doc/agent/navigation.md` (*What is not there yet*), the Nameplates and Social READMEs (*Not there yet*).

### Navigation: the ground as the game draws it; water in buildings; indoors on a building's floor (Saneroki, 2026-10-21)
- **The ground's triangles** (`dev/tools/walk-data`: `steepness`, from `ground`): a sample's ground is too steep where
  the game's triangle under it is steeper than `SLOPE` (each cell four triangles meeting at its inner height; a
  sample's middle lies where two meet, it takes the one terrain-art's ground draws its height from), no longer by its
  heights smoothed over three samples, whose slopes walked up Ironforge's mountain and into the ground under
  Stormwind. Held against the gentlest way over the triangles themselves where regions part: the ground under
  Stormwind (55.6 degrees at its gentlest) and the plateau east of Ironforge (53.6) are no walk; Feralas' hills
  (47.9), Searing Gorge (48.3) and Silithus' hives (16), cut off before, are joined.
- **Stairs** (`roomy`, `STAIR` a yard): the next piece of a stair or a ramp passing up through a sample within a yard
  over a floor is no ceiling (inns' upper storeys, narrow stairwells). **`CORE`** 0.3 of a sample (a half): Thunder
  Bluff's Spirit Rise and Hunter Rise join the mesa by their bridge heads.
- **The buildings' water** (`pools`, `liquid`): their parts' liquids (MLIQ), the liquid type as the game takes it (the
  table's where the building says so, MOHD 0x4; else the old numbers, of the first twenty every fourth water, ocean,
  magma, slime), joined to the ground's: Stormwind's canals swum, the Undercity's slime and Ironforge's lava closing
  what lies under them. Water drowns a floor only where nothing solid stands between them (`overs`: a tunnel under a
  river, the ground under a city's pool stay dry).
- **A building's floor** (`BUILT`, kind 3 in the block; the format the same): a floor on a building or a doodad. Each
  floor's sky (`SKY`, `COVERED`, `BURIED`: the ground `DEPTH`, 10 yards, and more under a building); `regions` leaves
  out a region with the sky over none of its floors (a cellar the data closes) or most of them buried (the ground
  under Stormwind's streets, open only between its districts). `tile` gives the rectangles with the sky over a floor
  and the buried counts.
- **Navigation:** `Walk.Floor` indoors (the game's `IsIndoors`: a building's or a cave's) takes the lowest of a
  building's floors near the player before the ground or water under it (`Walk.BUILT`; from inside Stormwind's
  buildings walks started on the ground forty yards under the streets); `Walk.Under` and `Walk.Nearest` take a
  building's floor as on foot (the docks' piers); `Walk.Landing` counts a yard up or down `Walk.LEVEL` (3) times, as
  the tool's `LEVEL`; `Search.CLIMB` 0.25 (2): the game runs as fast up a hill as on the flat, so the shorter way over
  a hill or a pass is taken; the planner's walk guess at least the way the steepest floor needs to climb between its
  ends (`Planner.SLOPE`).
- **The set made again** with the doodads (the same day's tool) and these rules: 2.83 million rectangles, 23.0 MB of
  blocks, the master 23.7 MB (1.65 million, 12.1 and 12.6 before the day's changes), Core's sets 33 MB in all; about
  six minutes to make. Regions: 160 on the Eastern Kingdoms, 240 on Kalimdor, 8 on the isle. Checked offline on the
  whole data: of 53,000 creatures' spawn points 71 % stand on a floor at their height (66 %), a start indoors
  without a height lands within 3 yards of its floor for 82 % of those under a ceiling (80 %), all 14 lifts land and
  their routes ride them, walks across hilly zones are as long at `CLIMB` 2 as at 0 within 2 % on the mean, Thousand
  Needles is walked to from Tanaris, Feralas and the Barrens. Apart: the plateau east of Ironforge, and Blackfathom's
  lower ruins, reached only under water.
- Tests: walking data 117 checks (the ground's triangles, a stair's pieces, a narrower `CORE`, a building's floor, the
  sky and the buried ground, water kept off a floor by a roof, slime, a building's water and its liquid types, regions
  without sky or mostly buried); Navigation 498 (indoors a building's floor before the ground under a city, on foot a
  building's floor too, a lift's end landing beside its shaft, not on the roof over it).

### Navigation: the doodads in the walking data's tool (Saneroki, 2026-10-21)
- **`dev/tools/walk-data`** reads the doodads' collision (the game's models, M2: the collision triangles their header
  names) the object files place (MDDF) and the placed buildings show (each root file's doodad sets: the first, global
  one and the placement's own; MWDR/MWDS where one shows several, Zephras Isle's), into the same columns as the
  buildings': fences, rocks, trunks and the game's invisible walls stand as walls; piers, decks and the tops of rocks
  are floors. `model`, `measure`, `quaternion`, `doodads`, `building(folder, file, sets)`; `placements` gives each
  placement its kind (`BUILDING`, `DOODAD`). Its game files' folder gains `m2/` (5,662 models from the game's install).
- **Placed as the game places them** (`placed`): tilted as well as turned. Buildings were turned only, though 902
  stand tilted (a capsized ship, ruins on hillsides, cave tunnels). Checked against the game's own files: every
  building's box as its object file keeps it (to 0.001 yards), the doodads each map chunk lists (99.9 % of 54,000).
- **Rules:** `SMALL` (2 yards: a doodad no wider either way is left out, about 82,000 torches, barrels, crates and
  posts; one walks round them); `sunken` (an outdoor doodad's triangles wholly under the ground: a tree's roots);
  `built` only where something comes near the ground (a canopy leaves the ground's `TAKEN` to its columns); a lift's
  landing with the rise counted `LEVEL` (3) times, as `Walk.Landing` must too (the Undercity's roofs over the shafts
  were taken for its landings).
- **Measured on the whole data** (the doodads alone): 2,413,319 rectangles, 17.9 MB of blocks (1,645,740 and 12.1),
  five to seven minutes to make. Thunder Bluff's rises are not split by doodads but by their bridge heads' stairs and
  posts (the buildings' own); the set is made again together with the same day's stair rule, which joins them and
  the inner ruins of Lordaeron that the game's invisible wall on their rampart now closes off the old way.
- Tests: walking data 87 checks (a model's collision, a building's doodad sets, the object files' placements, a tilted
  building of the game in the box its object file keeps, a fence and a deck rasterized, what lies under the ground, a
  canopy and `built`, a lift's landing beside the shaft, not on the roof).

### Navigation: only the flight points the character has found (Saneroki, 2026-10-21)
- At Saneroki's ask: a character may not have found every flight point, and the game tells which ones it has once a
  flight master is opened. The routes now fly only those, and the map's flight points it has not found are red.
- **The bug** (`Planner.lua`, `Learn`): at a flight master every flight point its map listed was kept as found, also
  those the game's flight map leaves out as not found (`Unreachable`), so a route could fly from and to flight points
  the character never had. Now its flight map's states count (`Current` and `Reachable` found, `Unreachable` not; on
  the older window `NONE` not), and every plane's points as the game's maps mark them (`isUndiscovered`, which the game
  knows once a flight master was opened this session); learnt again at `TAXI_NODE_STATUS_CHANGED` once one was, and a
  pin set before is planned again when they changed. Kept per character as `flightPoints`: the older `flights` held the
  wrong ones and goes, so until the first flight master the routes fly none. `Planner.Knows(node)` tells the others.
- **The map** (`Pins.lua`): a flight point not found has its colour taken out and `Pins.RED` over it (as a quest for
  later), its tooltip *Not discovered yet*. It followed the game's own `isUndiscovered` before, which the game does not
  know before a flight master is opened.
- Tests: Navigation 495 checks (a flight point not found red before any flight master; at one, the found one and the
  one its map leaves out, the old list gone, the route then on foot; the map's pins found and not). A `/reload` takes it
  in.

### Data: bosses' abilities and loot in a set of their own, unconfirmed until the game says so (Saneroki, 2026-10-21)
- **Saneroki:** boss abilities, drop tables and item stats are used at once but marked unconfirmed until the client or
  the server sends them and our own local data confirms them.
- **The fix:** batch 11's abilities and loot had been taken (`--take`) into the game's own versions of *Encounters*,
  which name the game among their sources and so would read as verified. They move to the new set *Bosses* (keyed by
  encounter, `abilities`, `loot`; every version batch 11's alone: unverified); *Encounters* is again what the game
  said, line for line. `Dungeons.lua` reads *Bosses*; its tooltips say "Not yet confirmed by the game".
- **The rule** in `Doc/ideas/Data.md` (*Verified and unverified*: an import never joins the game's version) and
  `CLAUDE.md` (*Unverified is marked*).
- Tests: Navigation 491 checks, data tools 198 (the set Bosses in the plan). A game restart takes it in (a new set
  file in Core's TOC).

### Navigation: the walking data joins what players walk between (Saneroki, 2026-10-21)
- **Found on the real data** (while adding the lifts): the Undercity's ring, lower parts, quarters and sewers were
  regions apart; its lifts' upper landings, Freewind Post's mesa and Gnomeregan's lift's landings were left out as
  small regions; Thunder Bluff's rises lay apart.
- **`dev/tools/walk-data`:**
  - A building's slope is judged in yards (`YARDS`): in the samples' space (2.08 yards across, a yard up) `SLOPE`'s
    50° was 30°, so the Undercity's ramps (27° to 39°, the building's collision-only triangles) were walls.
  - **Thin walls:** a wall takes a sample's floor only where it comes into the middle of its square (`CORE`, half
    its side); off the middle it is kept on each side whose way it crosses (`walls[(row, column, side)]`, from the
    sample's middle to that side's) and closes the way to the next sample where it rises more than `STEP` (0.5
    yards) over the higher floor under its `ROOM`, or more than `LEDGE` (1.5) between the two (`stands`, `walled`:
    in the flood of the surfaces, the openings and across the tiles' edges). Doors and bridges narrower than two
    samples stay open (the lifts' upper landings open into the throne room through arches 3.9 yards wide); a wall
    standing in water closes it (the water's floors ignored walls).
  - **The lifts' landings kept:** the region a lift of the master's set *Travel* lands on (`lifts`, `landings`: as
    `Walk.Landing`, the floor within `LANDING` yards of its end and `RISE` of its height, the nearest by both) is
    kept however small (`regions(tiles, keep)`).
- **The set *Walking* made again and taken in** (`dev/tools/data import ... --apply --take`: 1,506 tiles corrected,
  244 agreeing): 1,750 tiles, 1,645,740 rectangles (1,452,740 before), 12.1 MB of blocks (10.5), 12.6 MB in the
  master (10.9); regions: 108 on the Eastern Kingdoms (131), 219 on Kalimdor (221), 5 on the isle (6); three minutes
  to make. Joined: the Undercity's levels and landings, Gnomeregan's lift's ends, Thunder Bluff's Elder Rise to the
  main mesa by its bridge, Orgrimmar's flight tower, the Crossroads' tower, the zeppelin towers to Zephras Isle,
  the Caverns of Time, Jintha'Alor, Timbermaw Hold and more. Not joined: Thunder Bluff's Spirit Rise and Hunter Rise
  (their bridges end on decks whose stairs are doodads, which the tool does not read).
- **The Undercity's sewers** lead out to a cave on the hillside west of the ruins (world x 1658, y 729), so the city
  and the ruins are one region. **`Lifts.lua`:** two levels within one region where they are stacked round a lift
  (`level.alone`), told apart by height (`split` halfway between the landings, `low` the lower landing's, within
  `Walk.RISE`), a place below them only within `Lifts.SPREAD` yards, joining no two regions (`Joined`); a lift within
  one region side by side joins none; each landing's height kept (`fz`). **`Planner.lua`:** a place below a level
  and one on it stay apart also where they share a region (`Over`).
- Checked on the real data (outside the game): from the ruins to the Undercity's flight master, bank, quarters and
  back, from the canyon to Freewind Post's flight master and back, down Gnomeregan's lift: walk, lift, walk each; from
  the lift into the Magic Quarter on foot all the way; Thunder Bluff's flight master to the Elder Rise on foot.
- Tests: `dev/tests/walk.py` 71 checks (a ramp of 35° walkable, one of 55° not; a wall off a sample's middle keeps
  its floor and closes the way; a door narrower than two samples open; walls, railings, sills, ledges and a stair's
  steps; a wall on a tile's edge; a lift's landing kept, the lifts read from the master); Navigation 491 (a lift
  within one region: its levels, a pin under the courtyard by the lift, one beyond it on foot, out of the hall). A
  `/reload` takes it in.

### Navigation, data: bosses' abilities and loot in their tooltips, more bosses, enemies (Saneroki, 2026-10-21)
- **Batch 11** (`sources.toml`, "the dungeons' and raids' bosses and enemies as our tool picked them"): taken in with
  `--take` after a dry run showed only fills (new fields, longer lists with every boss of the set unchanged).
  - *Encounters*: `abilities` (the game's spell IDs Forever's client has: 234 bosses, 809 spells) and `loot` (item IDs
    the set *Items* has, no chances: 211 bosses, 886 items).
  - *Dungeons*: 100 more bosses in 23 dungeons and raids (the rebuilt dungeons too, where the records agree on the
    floors' maps), each with its look where both Forever clients have it; `enemies` (creature, floor, x, y): 961 in
    Ragefire Chasm, Wailing Caverns, the Deadmines, Shadowfang Keep, the Stockade and Blackfathom Deeps. A boss the
    game lists under several encounters (its dungeon's other modes) is the one its own dungeon has.
- **The dungeon view** (`Dungeons.lua`): a boss's tooltip lists its abilities and loot, each with its icon and name
  as the game has them (an item in its quality's colour, asked for while not loaded and drawn again once it is; at
  most `Dungeons.LINES` of each, then how many more); the enemies stand as small red dots (`Dungeons.ENEMY`) under
  the bosses, their names in their tooltips; the tooltips say "Not yet confirmed by the game".
- Tests: Navigation 487 checks (the tooltip's abilities and loot with their icons, a spell the game does not know left
  out, an item loaded later drawn again; an enemy where it stands, under the boss, with its name). A `/reload` takes
  it in.

### Core: every data set part of Core, the data packs gone (Saneroki, 2026-10-21)
- **The data packs are gone** (Saneroki: they filled the addon list and hid the modules one chooses; a second of
  loading screen and a few hundred megabytes of memory are acceptable): `dev/tools/data compile <dir>` writes every
  set with entries as `Sets/<Set>.lua` into Core's addon (`BUILD/SaneUI/Sets`, 36 sets, 22 MB) and lists them at the
  end of its TOC below a line of its own; unchanged files keep their time, files of sets no longer made go. Measured
  first with Lua 5.1 on all 13 packs: about 85 ms to compile and run, 25 MB of memory, nothing on the graphics card.
- `assets/data/packs.toml` and every schema's `pack` are gone (the check refuses `pack` now); `stats` totals all sets.
- **Core's `Data.lua`:** no finding of packs in the addon list, no loader, no states `idle` and `off`. A set file's
  `Data.Add` makes the set ready at once (listeners told on the next frame); a set refused (format, game version, a
  client that cannot be told) is said once; one Core does not hold is `missing` once Core's `ADDON_LOADED` came
  (`loading` before). `Prepare` only says a set that is not there; `Data.Find` is `Data.Retell`. `/sane data` lists
  the sets with hash and build and the saved parts with their size.
- **The data's saved variables are Core's** (`## SavedVariables: SaneUIDB, SaneUIData_Characters, SaneUIData_Guild`;
  `Data.SAVED`): `Data.Saved` hands a part once Core's saved variables are read, so the characters are read at the
  login. The warning of a lost pack file is gone: everything is in Core's one saved file now, whose budget of values
  is the whole file's.
- `dev/build`: the sets into `BUILD/SaneUI` (rsync keeps `Sets/`); a beta's or PTR's game folder gets its game
  version's sets compiled into the game's copy of Core; `SaneUI_Data_*` folders leave `BUILD/` and the game.
- `dev/tests/lint` checks the set files of every game version in a copy of Core's TOC, and that Core's TOC declares
  every saved variable `Data.SAVED` names. `dev/tests/data/packs.py` is `sets.py`; the stand-in client's `W.AddPack`
  is `W.AddSets` (set files run at the end of Core's files, or at once after them).
- Tests: `dev/tests/data.lua` 192 (sets arriving and refused, the client's game version by set files, the saved
  parts), data tools 198 (compiling into `Sets/` and Core's TOC); Tooltips, Navigation, Inventory, Guild and windows
  with the data there from the login.
- Docs: the guide `Doc/guides/data.md` (*Core's TOC*, *Loading*, *Saved variables*), the plan `Doc/ideas/Data.md`
  (*Sets by concern*: decisions 1 and 2 overturned), `Doc/ideas/Data-build.md`, Core's README, the project map.

### Navigation, Tooltips: indoor maps off the streets, instance maps without players, a rare's model, 3D portraits (Saneroki, 2026-10-21)
- **Indoor maps only inside buildings and caves** (Saneroki's answer to open question 18): `dev/tools/indoor-art` marks a
  part `open` where the game lights it as outdoors (its flag `EXTERIOR_LIT`) and its area counts as outdoors
  (`WMOAreaTable`, flag 4): Stormwind's 64 and Orgrimmar's 12 streets and squares, one part of two other buildings.
  Core's set *Indoors* gains the field (schema; the four entries taken in again as corrections of build 70245, their
  pictures unchanged). `Indoors.lua` never draws an open part and passes over a building where the part you stand in
  (the smallest holding your place and height, `Standing`) is open.
- **Instance maps keep rules of their own** (Saneroki: Forever tells no player's place inside an instance): `Dungeons.lua`
  has no arrow and no group any more, `Dungeons.Here` gives the instance's lowest floor, the drag's step runs only
  while dragging. Decided too: the enemies' and bosses' fixed places are shown, the bosses in full 3D (built).
- **A rare's 3D model with Alt** (`PinView.lua`): over a rare's pin with Alt held, a `PlayerModel` of its creature
  (`SetCreature`) beside the tooltip (left, or right without room), unseen until loaded; Alt let go or the mouse off
  the pin: gone.
- **Tooltips: 3D portraits always** (`Panel.lua`): a unit's model the game refuses at first is asked for again, unseen,
  every `Panel.RETRY` (0.1) seconds, `Panel.RETRIES` (10) times, and stands in the portrait's place once taken; until
  now it waited for the next draw, which only Alt caused. The flat portrait stays only where the game still refuses.
- Plans: `Doc/ideas/Navigation.md` (instance rules, indoor maps, a rare's model; open question 18 answered),
  `Doc/ideas/Tooltips/Build.md`; handoffs `Doc/agent/navigation.md`, `Doc/agent/tooltips.md`.
- Tests: Navigation 485 checks (a street of the building: no plan; back inside: the floor, the street not drawn; no
  arrow inside an instance; the drag's step only while dragging; the rare's model with Alt), Tooltips 485 (refused
  at first, taken at a later try without a new draw; still refused: the picture). A `/reload` takes it in.

### Navigation: lifts in the routes (Saneroki, 2026-10-21)
- **Saneroki's ask:** a route into the Undercity or up Thunder Bluff's mesas walks to the lift, rides it and walks
  on, instead of ending as near as one walks and running straight to the pin.
- **The data** (Core's set *Travel*, kind `lift`; batch 10 of `sources.toml`, unverified): `dev/tools/travel-data
  --lifts <places> <batch>` reads each lift car's motion from the client's `TransportAnimation` (straight up and
  down, standing once a round at each end and nowhere between, rising 10 yards or more: `lift`), and writes one
  record per car: its two ends in the world's yards with their heights (`path`, the lower first; the path's tuple has
  a new part `z`), its slower ride (`time`), the time between two departures from an end (`wait`), its rise
  (`length`), its ends on the zone maps (`from`, `to`, by map-data's Placer); its key our own number from 1100001,
  the master's kept for a car at the same place (`lift_keys`). Where the cars stand is a batch file of our picking.
  Fourteen cars: Thunder Bluff's four, the Undercity's three, the Great Lift's two, Freewind Post's two,
  Gnomeregan's and two small ones.
- **`Lifts.lua`** (new in the TOC, no frames): each end of a car on its landing (`Walk.Landing`, new: the floor
  within `Lifts.LANDING` yards of a point nearest its height), the levels the lifts join (`Lifts.Levels`: two
  landings' regions, stacked where on a ring `Lifts.RING` yards round the shafts a third of the lower level's points
  lie under the upper: the Undercity under the ruins of Lordaeron; side by side at Thunder Bluff), `Lifts.Joined`,
  `Lifts.Stand` (a place over a stacked lift's lower level stands below its upper one: the player by its floor, any
  place by the lower level's floors under it, the pin on the lift's own map also by any floor below there or the
  nearest within `Lifts.RING` yards; by a lift side by side, under its overhanging landing, on the upper),
  `Lifts.Near`.
- **`Planner.lua`:** the lifts' ends are places of the journey, at their landings, only where both ends have one;
  the ride costs half the time between two departures and its ride; no walk between two levels a lift joins, or
  between a level and a place below it; a walk's guess between places of known heights counts the climb; every walk
  starts on the floor known at its start (the player's, a landing's: `step.floor`); a lift's leg is drawn straight
  from landing to landing (gold); after a ride on the line's lift the floor followed is its far landing (`Rode`);
  the pin keeps the map it was put on (`target.at`); `Planner.APART` is left for gaps of the walking data.
- `Pins.lua`: a way without a name of its own (a lift) is named by its kind.
- Checked outside the game on the real walking data: Mulgore to Thunder Bluff's flight master by either lift and
  back; the ruins of Lordaeron to the Undercity's flight master, bank, Magic, Royal and War Quarter and out again,
  each walk, lift, walk.
- Not yet: the walking data joins the Undercity's levels nowhere (its ramps and stairs), so a walk from the lift to
  its lower parts ends as near as one walks; the small landings (the Undercity's upper ones, Freewind Post's mesa,
  Gnomeregan's) are left out of it.
- Tests: `dev/tests/navigation.lua` 478 (a field with a mesa beside it and a courtyard over a hall: the landings,
  the levels, walk, lift, walk up and down, out again, the floor after a ride and not without one, a pin by its map,
  the lifts on the map), `dev/tests/walk.py` 50 (a lift's motion, its ends, keys and what is left out).

### GPU runner: the queue started, listed and switched (Saneroki, 2026-10-21)
- At Saneroki's ask, the runner's commands say what they do: `saneui start|stop|pause|resume|status gpurunner`
  (was `gpujobs`), `saneui gpuqueue` (`gpu-runner queue`, also `status`): the runner's state and the queue in the
  order it runs, with each job's priority, progress, which runs now and which next, the held, finished and
  failed ones.
- `saneui switch <job>` (`gpu-runner switch`): that job now, let go if held, finished or failed; the job at
  work is stopped with its progress kept; the runner started if it is not running, its hold skipped. The job
  stays first (`first.json` in the runner's state) until it is finished or another is switched to;
  `switch --back` gives the priorities back at once. `saneui rebuildstart <job>`: `rebuild`, then `switch`.
- The runner now lets a more important job take over at once (one added to `jobs.toml`, a switch): the job at
  work is stopped as for the game and comes back when its turn comes.
- A standing rule (guide, *The GPU runner*; `jobs.toml`'s head; the instructions): a session that adds or
  changes a render plan adds or updates its job in `dev/imagegen/jobs.toml` with a priority. The UI look sets
  (`ui-explore`, `ui-style`, `ui-compare`) are rendered, so they have no job.
- The Konsole greeting shows `gpurunner`, `gpuqueue`, `switch` and `rebuildstart`; `rebuild` is in `saneui`'s
  list only. Tests: 12 more of the GPU runner (the order with a switch, a runner on made-up jobs: the switch,
  the switch back, a new job taking over, one switched to and finished).

### Docs: this session's asks in the plans and handoffs (Saneroki, 2026-10-21)
- `Doc/ideas/Navigation.md`: Saneroki's asks under *Decisions* (the quest marks, tooltips without the click, the pin
  filter in sections, every pin clicked for the map pin the minimap's too, dungeon maps now with their bosses and
  3D models, the quest log without a scroll bar, its icons, its click and its menu); *Design* (gathered markers,
  the filter, the quest log's actions, no quest details window of the game's), the status, *Where it stands*
  (step 8 begun), the gathering and dungeon references as built; open question 18 (indoor maps on city streets).
- `Doc/agent/navigation.md`: *Built (2026-10-20, 21)*, the *Not yet* list and the test counts.
- `Doc/ideas/Windows.md` and `Doc/ideas/Onboarding.md`: the options' cog and the ? on every full screen (the ?
  there now, its `help` the seam for Onboarding's tour).
- `Doc/ideas/Data.md`: the sets *Indoors* and *Dungeons* in World; *Dungeons* in the sets table.
- `Doc/agent/core.md`, `Doc/agent/README.md`, `Doc/guides/windows.md`, Core's and Settings' READMEs: the title bar's
  two buttons, `window:Escapes` (the review moved it from Edge), `Core.Reset(name, only)`.

### GPU runner and Atlas: rebuild, holds, a run's own plan (Saneroki, 2026-10-21)
- At Saneroki's ask: the Atlas waits for new notes and rules; then a rebuild starts it anew with the plans of
  that moment, and without one it goes on with the plan it began with.
- `dev/tools/atlas`: a run keeps its plan, a copy of `dev/imagegen/maps/atlas.toml`, `zones.toml` and the
  workflow in its `plan/`, made at its first paint (with the day and the commit in `state.json`); every later
  paint of the run takes them from there, `status` says when the plans have changed since. `rebuild` puts the
  run so far aside, whole, in `assets/generated/atlas-runs/<day and time>/` and starts a new one with only the
  game's paths. The run of 14 squares got its plan as it was painted with (unchanged since 2026-10-20), then
  was put aside by the first rebuild. The new run is held (`saneui hold atlas`) while Saneroki writes the new
  notes; it takes the plans of the moment it is let go (`saneui unhold atlas`).
- `dev/tools/gpu-runner`: `rebuild NAME` (the job's `rebuild` command, run while the job is held and stopped,
  then its finished mark forgotten), `hold NAME [--why]` / `unhold NAME` (kept across restarts, the other jobs
  go on); the hand pause is kept in `~/.local/state/saneui/gpu-runner/` too, so it lasts over a reboot; the
  runner reads its state at each look, so `reset` and `rebuild` from outside are not overwritten. `saneui
  rebuild`, `hold`, `unhold`.

### Releases: saneui snapshot; every script in saneui (Saneroki, 2026-10-21)
- `dev/snapshot X.Y.Z [--dry]` (`saneui snapshot`): a release from main's newest commit. The version in every
  module's TOC is committed on main ("Version X.Y.Z", in an index of its own, main moved only if nobody
  committed meanwhile), the tests run on git's copy of that commit first, then the tag `vX.Y.Z`, the release
  branch `release/X.Y` (made, or moved forward) and the tag `current` are set. Changes not committed stay out
  (listed); in the working tree a TOC gets only its version line. Refused: a version made already or not newer,
  a release branch with commits main lacks. Nothing is pushed.
- Every executable in `dev/`, `dev/tools/` and `Scripts/` must have its `saneui` command:
  `dev/tests/saneui.py` fails on one without (CLAUDE.md, AGENTS.md and README.md say so for new scripts; new
  GPU work goes to the GPU runner's job list).

### Scripts: one command, saneui; dev and release builds (Saneroki, 2026-10-21)
- At Saneroki's ask: the scripts run from the terminal by names that say what they do, listed in the Konsole
  greeting, and a build kind for the game: the dev build day to day, a release from time to time.
- `dev/saneui` (`saneui`, linked to `~/bin/saneui` by `saneui --link`): every script by an expressive name
  (`installdev`, `installrelease`, `build`, `installed`, `test`, `showerrors`, `atlas`, `makeimages`, `data`,
  `makevoices`, ...); `saneui start|pause|resume|stop|status gpujobs` (the GPU runner) and `comfyui`; `saneui`
  alone lists them by group, `saneui help <command>` gives the script's own help. `--card` gives the main ones
  for the Konsole greeting (a Sane UI block under the Toolbox), `--names` the names for fish's completion.
- `dev/build` now only tests and builds (`--install` copies into the game too; `--no-install` is still
  taken). `dev/installdev` is the old `dev/build`: the working tree, tested, built, into the game.
  `--release [TAG]` (default `current`) builds a release from git's copy of its tag, LFS art included, into
  `BUILD/release/<tag>`, with the tag's own tests; `dev/installrelease [TAG]` puts it into the game and takes
  out our modules it lacks. Each built TOC says which build it is (`## X-SaneUI-Build: dev <commit>[ +changes]`
  or `release <tag> <commit>`); `saneui installed` reads the game's. No release is tagged yet.
- `Scripts/update` ends with `dev/build --install`. README.md, *Building*; tests: `dev/tests/saneui.py`.

### Image generation: the GPU runner (Saneroki, 2026-10-21)
- At Saneroki's ask: the long ComfyUI work (the Atlas, the rerenders of its middle and far zooms, dungeon maps)
  should use the graphics card only while it is idle, since the game uses it too.
- `dev/tools/gpu-runner`: runs the most important unfinished job of `dev/imagegen/jobs.toml` (a tool's command,
  a priority, optionally a status command and the pattern that says it is done), and stops it as soon as the
  card is wanted elsewhere: the game (`Wow*.exe`), another program holding more than 1.5 GB of the card or using
  more than 40 % at three looks in a row (not the desktop's), ComfyUI pictures of another session or tool, a
  claim (`gpu-runner claim NAME [--wait] [-- COMMAND]`, or a file in `$XDG_RUNTIME_DIR/saneui-gpu/claims/`), a
  pause by hand. Its pictures then leave ComfyUI's queue and the card is freed (ComfyUI stopped if the runner
  started it and nobody else used it, else `/free`); it goes on after the card has been free for `hold` (three
  minutes). `start` (a systemd user unit), `stop`, `pause`, `resume`, `status`, `reset`; its log in
  `~/.local/state/saneui/gpu-runner/`. The job list ships with no job: long runs start on Saneroki's word.
- `dev/tools/imagegen`: `Server.free` (the Atlas' pause used it inline) and `Server.interrupt`, which stops only
  its own picture (the Atlas' quit interrupted whatever ComfyUI was making, another session's picture too); its
  client id can be set by `IMAGEGEN_CLIENT`, so the runner tells its jobs' pictures from others'.
- At Saneroki's ask, the same day: the Atlas' close squares are its first job, and `gpu-runner install` makes it
  a user service (`~/.config/systemd/user/saneui-gpu-runner.service`), started at every login; it stands by
  for the hold after its own start too, so one started in a gap of another session's work waits first.
- Guide: `Doc/guides/image-generation.md`, *The GPU runner*. Tests: `dev/tests/gpu_runner.py` (33 checks).

### Navigation: zones and continents reimagined in the painted view (Saneroki, 2026-10-21)
- Plan only (`Doc/ideas/Navigation.md`, *Zones and continents reimagined*, *Dungeon maps reimagined*): the close
  zooms stay the accurate terrain repainted; the zone and continent zooms become free, realistic fantasy
  paintings of each zone's mood, layout and major places, perspective allowed, borders fitting together; the
  dungeon, instance and raid maps get three zooms too: the accurate terrain close up, a clean Blizzard-style
  plan of rooms and corridors in between, a free realistic reimagination zoomed out fully. Indoor maps, painted
  or not, are clear around (never black) and as accurate as the terrain, to lie seamlessly over it. The map
  selector picks the dungeon maps, opening in their three zooms. Far out: no pins and no names in the paintings
  (names, level ranges and gathering skills are an overlay with switches), soft zone borders, and the lore's
  view (Teldrassil's world tree, Ironforge's mountain) where the game's zone is cut open. The middle zoom shows
  each zone's major places clearly, the far zoom a realistic render with only a loose idea of them. The
  dungeons' room plans are drawn by code; the close terrain blends only a zone's outermost edge; a review queue
  takes or sends back each painting. Only borders the player cannot reach are blended (coasts, piers and passes
  stay exact); a size budget comes before the big runs; a game update repaints only what it changed. Scrying
  and Parchment stay the game's own files, pixel for pixel, cut not to overlap. The Atlas has three levels only
  (terrain, zone, world with both continents), no single continent; continent and zone maps and controls are
  Scrying's and Parchment's. The Atlas is one smooth world, its style blending with the wheel; no right-click
  steps out a level (open question 8 answered; the canvas' right-click is to be taken out). The Atlas' README
  and Navigation's project map (`Doc/agent/navigation.md`) say what is planned.

### Navigation: routes from the player, on their floor, over every plane (Saneroki, 2026-10-21)
- At Saneroki's ask: a route into a building or a cave and out again did not work, routes across the continents by
  tram, flight and ship not well, and the line should always run from the player to the pin.
- **The floor** (`Walk.lua`, `Search.lua`): the walking data holds floors one over the other, and the game tells no
  height (`UnitPosition`'s third answer is always 0). Every lookup took the first floor under a point (the hill over
  a cave, Ironforge's mountain over its city), so a walk could start on the wrong floor and a place's region come
  from it; the planner then ruled the walk out and drew no line at all. Now
  `Walk.Follow` follows the player's floor through the openings nearest the way they went (a cave's mouth, not the
  path up the hill over it), and `Walk.Floor` chooses one where that cannot be done (near the height they had, within
  `Walk.RISE`; else outdoors the highest under them, indoors the lowest within `Walk.ROOF`). New beside them:
  `Walk.Around`, `Walk.Regions`, `Walk.Inside`, `Walk.Gap` and `Walk.Opening` (the openings one by one: a search
  makes no function for each rectangle). The search starts on the player's floor (else on every floor under the
  start and within `Walk.ROOF`, each over the lowest at the cost of the climb up to it) and ends on any floor of its
  regions under the end or within `Search.NEAR` (50 yards), else the nearest within `Search.FAR`; what lies off the
  data is drawn straight at `Search.STRAIGHT` times its yards, so the line reaches the player and the pin
  themselves; each yard up costs `Search.CLIMB` (2) yards more, so a walk keeps to the valleys and the roads (the
  data holds steep slopes as floors: a walk into Ironforge went over its mountain). Its heap keeps each node's f as
  it was put in. `Search.Start` went: the planner's job searches. On the real data (the set read outside the game):
  Ironforge's flight master to the tram's entrance 327 yards through the city (1,551 over the mountain before; the
  entrance's own floor lies a yard off its point, under the mountain's), and back alike; of 150 walks between
  points at random around Stormwind and around Ironforge, 139 found in each (113 and 120 before), every one from its
  start to its end itself (82 and 65 before).
- **The line from the player** (`Planner.lua`, `Route.lua`): the plan's cut, where along the line the player is (of
  the next `Planner.AHEAD` parts the first within `Planner.SLACK` yards of the nearest, never back; a part from one
  plane onto another at its end on the player's), found at every step of the canvas' tracker; `Route.Cut` hides
  what lies behind, draws the part the player is on from there, and a line from the player's arrow to it. Leaving
  the line (`Planner.OFF`) is measured from the cut.
- **Every plane** (`Planner.lua`): the journey's graph holds every plane's known flight points, docks, the tram and
  the hearthstone (it held the player's and the pin's planes only), so the hearthstone home and then a ship, or
  Zephras Isle by way of a continent, are found. A flight point is a place on the ground and one in the air: a
  flight over many takes off and lands once (`Planner.BOARD`), and its flights are one step and one leg. Places that
  share no region (of the floors under them and within `Planner.REGION` yards) are a walk `Planner.APART` seconds
  dearer instead of none (Thunder Bluff's flight point, the zeppelins' towers to Zephras Isle stand on regions of
  their own). Aboard a ship the plan does not have (Core's `Data.Trips`, `Riding`), a new pin is planned from the pier
  of its next dock; a ship's landing plans anew. The tram's wait is the time to its next train where a ride taught
  its times (`Trips:TramNext`). Piers within `Planner.PIER` 60 yards (at 40, three docks had none).
- **One job** (`Planner.lua`): the journey and its walks are one job of Core's scheduler, which a new pin stops; the
  line of the pin before goes at once. A place's regions are looked up only for a walk that may still be part of a
  quicker journey (unpacking no tiles of places nobody walks to), kept since. `Walk.Tile` keeps the `Walk.KEEP` tiles
  asked for last (it let the oldest unpacked go, the ones the next plan needed among them), and in a job an
  unpacking may end the job's frame.
- Tests: Navigation 468 checks (floors one over the other chosen, followed by the cave's mouth and by the hill's
  path, a floor near the height one had; a walk from the player's floor, from the shortest of its floors; a pin on a
  mesa, one beside the data, a start beside it; the planner from a cave; the cut and the line from the player's
  arrow; a leg from one plane onto another; a pin nobody can walk to; three planes by the hearthstone and by the
  zeppelin; two flights one leg; a pin set aboard a ship). A `/reload` takes it in.

### A review of the whole addon: bugs, hardening, speed (Saneroki, 2026-10-21)
Every module and Core read through for bugs, the error doors, secret values, taint, fights, saved shapes and work done
for nothing; what held up was fixed, each with checks that fail on the old code. No new files: a `/reload` takes it in.
- **Core:**
  - *Start* (`Core.lua`): a module that stood down, in whichever step or at whichever door, gets no further step (its
    OnLogin no longer takes back what its GiveBack gave back).
  - *Esc* (`Escape.lua`): the stand-in hidden with its parent (the game hides its whole interface for a movie) is no
    Esc; a protected window whose close waits for the fight's end takes its Esc entry out meanwhile (`Window.lua`), so
    the game's Esc and its menu work in that fight.
  - *People* (`People.lua`): *Remove Alias* and *Remove Note* (the game's text dialog takes no empty text, so neither
    could be taken away); kept in `SaneUIDB.modules.Core.people`, as the docs now say.
  - *Profiles* (`Profiles.lua`): *Forget* also forgets the character's bags, bank, gear and gold (`Data.Forget`); an
    imported profile keeps only the single CVars the game's options have (Sync's `named`); `Serial.Read` refuses NaN,
    endless numbers and table keys; `Profiles.Copies` and `Exists` went (unused); one shared refresh of the options after
    a profile action (`Config.RefreshSoon`). `Fuzzy.Plain` drops named colour codes (`|cnIQ5:`); its second `Ranked` is
    `RowRank`.
  - *Windows* (`Window.lua`, `Board.lua`, `Edge.lua`, `Classic.lua`): the secure *Sane UI* button clicks the game's close
    button also with *Action button use key down* on (`useOnKeyDown` false); in a fight it follows the game's window by
    its alpha and does nothing while unseen; `Board.Open` fills only a shown window and says false when no full screen
    comes; a panel whose key another spec takes is built anew for it (`Offer` tells a standing board too); kept layouts
    are checked (parts, shares, tabs); a window hidden mid-drag or mid-size is let go; shown windows are placed anew when
    the screen size or UI scale changes (a full one gets `docked`); `window:Escapes(on)`, which the options screen uses;
    a cancelled held line only redraws its strip. Seat has checks of its own now.
  - *Options* (`Settings/`): the feedback window keeps the draft of the kind shown when another opens; the *New* button's
    tooltip is its own (two keys were one); *New*, *Rename* and a forgotten character's dropdown say and do what happened;
    dropdowns make their functions once and only update while their choices stay the same; the compartment, the colour
    picker, the CVar list's callbacks and the XML scripts run behind Core's guards; `Sync.Settable` holds the checks
    `Sync.SetCVar` and the CVars tab share; `Config.Getter`/`Setter`/`Enabled` shared by both kinds of page.
  - *Sync* (`Sync/`): a channel's chat colour is kept with the channel's name and written to this character's channel of
    that name (never by its number alone); a layout waiting while Edit Mode is open gives way to the player's pick.
  - *Data* (`Data/`): gold and the bank's day move the characters' stamp; a bank is read whole in one step, and the place
    a read was cut off in is read again at logout; `Data.Forget(key)`; listeners told once, on a later frame; ships learn
    a round from the longest span and take a realm's new run (a restart) as a new epoch (`span`, `doubt`); ships' and
    trips' looks start only once *Travel* is there or a module asks (`Data.Trips()`); a job stopped from inside ends at
    its next `Check`; the map reads its sets once when several arrive together, its spawns swapped in whole; every saved
    shape of ships, trips and characters is checked; int map keys only from digits (no NaN keys).
  - *Wire and guild records* (`Data/Wire.lua`, `Data/Guild.lua`): a block's part numbers are digits only (a whisper with
    `nan` or `2.5` raised in the inbox); a block is queued only when all its parts fit, and a kind switched off drops what
    still waits of it (`Wire.Drop`); professions from `C_SkillInfo` (the old globals are not on this client: the cards had
    none), re-carded a minute after a skill-up; a roster that shrank by more than a tenth is believed once a read a minute
    later agrees; a leaving member's records go; no join day at a guild's first read; the roster read by the scheduler,
    never in a fight, its events added in one go; asked for while a view shows it (`Data.Guild.Watch`); fresh hellos
    answered by whisper, asks once a minute per member and kind; Sync sends a fresh hello, once a minute; the guild data's
    format under `guildFormat`.
- **Abilities:** the fallback gives every book entry the game's size, also those back in the game's pool; the book's size
  is given back when it is hidden too (refit at its next showing); the headings are this client's 60 high (rows under
  them line up across pages); the trainer's listeners do nothing once stood down, and its filter is put back; GiveBack's
  steps each on their own (ghosts, drag, the trainer's filter, the book); a stand-down mid-drag hides the gold frame too;
  the menu's tooltip and enabled functions behind guards, made once; no closures per button read.
- **Combat:** GiveBack gives the keys back first, each step on its own; quest marks do nothing once stood down, and read
  nothing with the setting off; the full screen's search box is wired (spells, talents); a tab chosen ends a search; the
  pet key closes the screen again from the pet's tab, and does nothing without a pet; a dragged spell's glow comes back
  when the cursor changes; a pet ability with a rank casts that rank; a refused fill forgets what was wanted; the
  fallback cooldown reads plain values only.
- **Nameplates:** a stand-down gives every plate its parts back first (also plates the game hands out again), then the
  auras and combo points, each on its own; a plate taken back has its bar as made.
- **Guild:** lists keep their scroll position; your own model shows again after another member; another member is dressed
  on your own figure (said so); the guild key and `/sane guild` work only in a guild (outside, the game's guild finder);
  the window of its own hooks its scripts (Core's Esc and drag stay); the head alone redraws for peers; item levels kept
  per member and stamp; no closure per row; GiveBack's steps each on their own.
- **Inventory:**
  - *Bags:* the Sort By choice under a key of its own, `sort` (it and the categories' order wiped each other, and a
    category switched off after a Sort By stood the module down); the bank's sidebar with several tabs (its tally was a
    map and a list in one); Move Up/Down moves whole groups and steps over switched-off categories; a Shift-click links an
    item again (our splitter only where the game's opened); the red "cannot use" follows level-ups and unknown items; the
    bank redraws only for its own item data, the gold alone for money; a reused slot keeps nothing of the item before;
    Auto Split stops when another stack opens, the splitter closes with the bags; column sizing redraws only on a change
    and stops when the button is up; the sidebar's counts as the views show them; menus, the junk marker and the middle
    click redraw the bank too; the take highlight by its colour's alpha; every banker kind; pooled bank rows forget their
    last use.
  - *Sheet, alts, keys:* with *Can expand to fullscreen* off, or in Edit Mode, the bag keys, the bag buttons and the
    *Sane UI* button leave the game's bags to the game; GiveBack's steps each on their own, the keys first; equipment sets
    keep their ignored slots (shirt and tabard); a faction moved to Inactive stays chosen; stats rows are left alone in a
    fight; a tab clicked again does nothing, the pet tab falls back to stats without a pet; the player's unit events only;
    the alts' items follow their category, their menu steps fail alone, their saved facts are type-checked; a drop on the
    model equips only with the left button and when the game allows it; names that arrive redraw after a pause.
- **Navigation:**
  - *The game's map and minimap:* a caught map is hidden by its own `Hide`, never by the game's panel function from our
    code (that left the panel manager tainted, and the character sheet then broke on C until a `/reload`); choosing the
    game's map in *Classic windows* only sets the switch, its key or button opens it next; inside an instance the small
    window shows the game's minimap with its ground (our map has no place for you there), ours again once there is one;
    no *Sane UI* button on the game's minimap inside ours; GiveBack's steps each on their own, the map and keys first; a
    fight's deferred minimap update runs guarded.
  - *The map:* a map in another instance than its continent's plane is not placed on it (a battleground's coordinates
    read as the continent's); the zone in the middle asked at most every `Canvas.LOOK`; a zone change re-places only the
    pins; nothing laid out while the window moves between small and full; the dungeon list kept once read; boss models
    stay under the top bar; a right click on a dungeon shows the map under it; indoors looked at again only when you
    moved, and only in your own instance; closures made once.
  - *Pins:* every point of a thing is its own pin (one herb per view showed before), its thing's key kept apart; Core's
    pins kept per map in parts (NPCs, objects, places), so a quest or waypoint change rebuilds only its part; the finder
    asked once, again on the game's tracking news; folded quest log headers list nothing; the pin filter's pooled slider
    no longer resizes another kind; low-level quests by the game's own grey range; found herbs left far behind are
    forgotten; object mailboxes count as services; pin levels by kind (`PinView.TIERS`); Abandon through `Core.Confirm`.
  - *Cheaper pins:* possible herbs and ore give one pin per cell of the gather's grid and kind (the others ride with it:
    its tooltip still names every place); Gather's cells are numbers and its tables reused; a kept button is redrawn
    only when it changed. A full-map layout in the densest zones went from about 7–11 ms to about 2 ms (measured
    offline, on Core's data).
  - *Planner* (committed before, see below): regions and walks kept, a plan kept while the pin stays.
- **Social:**
  - *Chat:* a link click opens no panel of the game's (a Ctrl-click's dressing room, a calendar or channel link ran the
    game's panel manager from our code, which then broke the character sheet), and fails alone; a conversation begun by
    your first message is chosen whole; the search waits for the keys and keeps each message's plain text; copying skips
    named colour codes; at most 1,000 conversation messages saved per character, without what follows from the rest;
    creatures' names are no player links; the raid roster rebuilt once per burst; one colour table per view; the reply
    target read plainly; the menus and list callbacks behind guards; a chat view's unseen count lasts the session only
    (it was saved); in a fight a click on a link the game shows in its link tooltip does nothing (the game refuses that
    window to our code then; the tooltip under the mouse shows it); no emotes offered in chat lockdown; one shared
    `ns.ChatLocked()`.
  - *Contacts:* *Ignore* and *Add Friend* on a target use the whole Forever name (the surname was taken for a realm);
    the group finder pauses in chat lockdown and leaves out hidden listings; a search the tab was away for is read when
    it comes back; the raid tab's right click opens a menu of our own (the game's offers Set Focus, which our code cannot
    call); Away before Busy; *Block Invites* only where the game offers it; the guild window left open in a fight closes
    after it; row scripts set once; the filter ticks and Decline fail alone.
- **Tooltips:** the 3D portrait stays when the same thing is shown again; comparisons are placed after their main tooltip
  (the probable cause of the auction house's flicker), the queue settled without holes; *Buy if under* on the auction
  house's list links; saved prices are numbers only; the caches capped; GiveBack hides the driver; dead bar code and an
  unused text went.
- **The lint** (`dev/tests/lint`) also checks the callbacks the game calls later that it could not see: dropdown menus
  (`SetupMenu`), list callbacks (`SetElementInitializer`, `Factory`, `ExtentCalculator`), menu tooltips, selection
  translators, default callbacks, settings predicates and getters/setters, chat filters, tooltip post-calls, and the
  function fields (`callback`, `swatchFunc`, `OnRefresh`, `SlashCmdList`, ...); a callback that answers a value passes
  as a one-step guard with a fallback of its kind (`return ns.Safe(...) or 1`), a guard it cannot follow by its
  `-- guarded: <how>` mark. The 20 places it then found are guarded (addon-standards.md §10 says which forms pass).
- **Docs:** the module READMEs, `Doc/agent/*` and the guides (`addon-standards.md`, `windows.md`, `data.md`) follow
  the fixes; check counts went from the READMEs (each change makes them stale).
- **Tests:** checks added in every suite (Core, windows, Sync, data, Guild, Abilities, Combat, spellbook, Nameplates,
  Inventory, sheet, bags, Navigation, Social, Tooltips); stubs for the game's `C_SkillInfo`, `ScrollBoxConstants`, the
  stack splitter and more.

### Art: every picture in assets, none in src (Saneroki, 2026-10-21)
- The modules' textures moved from `src/<Module>/Art/` to `assets/optimized/<Module>/Art/` (Core, Navigation,
  Social, Tooltips), so `src/` holds code only; all of `assets/` (concept art, examples, the sources and the
  textures made from them) is committed in Git LFS, but for the image models' candidates and the Atlas' test
  pack. Navigation's indoor maps (`Art/Indoors/`) are committed now too.
- `dev/build` puts each module together from `src/<folder>` and `assets/optimized/<folder>` when there is one (the
  Atlas' way, now every module's); the addons and their `Art\` paths in the game are unchanged.
- `dev/tools/art`, `shape-art`, `tooltip-art`, `terrain-art`, `indoor-art` write there; `dev/tests/lint` finds a
  file a TOC lists in either place, and fails on a picture or sound in `src/`.
- `Doc/guides/images.md`: the place of a module's picture.

### Navigation: the planner keeps what it found while the pin stays (Saneroki, 2026-10-21)
- From the review of the whole addon (`Planner.lua`): the walking data's region of each flight point and dock is
  kept from plan to plan (`regions`, emptied when Walking or Travel change), a walk a plan searched already is taken
  again when the plan is chosen anew (`start.walked`, by from:to), and the game's news of its map pin plans again
  only when the pin moved (`Waypoint`, `Pinned`). The hearthstone's kept place is used only when its map and point
  are numbers, a kept `flights` that is no table is replaced, and `UNIT_SPELLCAST_SUCCEEDED`'s spell is read
  plainly (`Core.Plain`). A `/reload` takes it in.

### Tests: a part the image lists include is checked in them (Saneroki, 2026-10-21)
- `dev/tests/imagegen.py`: a list other lists include that names no workflow (the house style, the leather look's
  shared views) is checked as part of the lists that include it, no longer as a set of its own; the suite stopped
  there since the leather look's views came in.

### Navigation: the quest log without a scroll bar, a click pins the objective; found herbs clicked (Saneroki, 2026-10-21)
- **The quest log** (`QuestLog.lua`, at Saneroki's ask): no scroll bar at rest, the wheel scrolls the list; while
  the mouse is on the window and the list is longer than its room, the game's thin scroll bar shows at the side the
  window stands at (its dock zone, else the screen's half its middle is in), in the room of its edge, and goes with
  the mouse. Each quest has its mark at its row's left as its pin on the map has it (the yellow question mark; a
  preview its giver's: the yellow !, grey for too low, the red ? for later); the watched tick moved right of its
  words. A click puts the game's map pin on the quest's objective (the game's quest on a map, `GetQuestsOnMap`; a
  preview's at its giver) and the arrow leads to it; the map no longer moves. The right button's menu: *Quest
  Details* (its text below the list, with its buttons, closed by its new X), *Show Map*, then *Track*, *Share* and
  *Abandon* (a preview: its way out of the log); *Lead the arrow here* went, the click does it. A click on a quest's
  pin on the map shows its text without moving the map.
- **Found herbs and ore** (`Found.lua`): each picture on the minimap is a button: its tooltip names it (grey while
  your skill is too low), a click puts the game's map pin where it is, on its zone's map.
- `PinView.Drop` is shared (the quest log, the found herbs).
- Tests: Navigation 413 checks (the marks, a click's map pin and the map left as it is, the menu, the text and its
  X, the scroll bar at rest, with the mouse, at either side; a found herb's tooltip and map pin). A `/reload` takes
  it in.

### Core: Sane UI's options on every full screen (Saneroki, 2026-10-21)
- **The title bar of a full window** (`Window.lua`): two buttons more, left of the others, only while it fills the
  screen: the game's cog (`questlog-icon-setting`, Sane UI's options over the full screen) and a question mark in
  the game's gold words (`Square` takes `art.text`), the full screen's tour: the window's option `help`, without
  which it does nothing yet.
- **The options view** (new `Settings/Screen.lua`, `Config.Screen`): over what the window holds, in the layer
  `DIALOG` (over the map's quest log), dark, taking the mouse and its wheel. At the left Sane UI's pages as the
  game's options list them (*General*, *Appearance*, a page per module that is on and has switches) in the look of
  the game's own list of pages; at the right the chosen one, drawn as a page in tabs is (`Config.BuildTabbed`),
  built when first chosen; the window's module chosen first (found by the settings its edge reads), the last chosen
  kept for the session. *All options* at the list's foot opens the game's options at Sane UI (Profiles is only
  there), the full screen going back first. The cog again, Esc, the window going back or closing take it away;
  while it is there Esc is its own (`edge:Escapes`, new in `Edge.lua`).
- **`Config.BuildTabbed(page, name, onPage, title)`**: only the switches of one page (Core's *General* and
  *Appearance*), its title; *Defaults* sets only those back (`Core.Reset(name, only)`).
- Tests: Core 355 checks (the view, its pages, the window's module first, another chosen, Esc, the window closed),
  windows 376 (the two buttons only on the full screen, the dropdown left of them), Social 565. A game restart takes
  it in (a new file in Core's TOC).

### Navigation: the bosses' 3D models on the dungeon maps (Saneroki, 2026-10-21)
- **Core's set *Dungeons***: each boss's tuple gains `display` (its look: the first creature of its entry in
  Blizzard's retail boss journal, `JournalEncounterCreature`, read from the local retail install), only where
  Forever's live and beta clients both have that creature display (129 of 138; the other 9 got new looks in retail:
  War Master Voone, Mother Smolderweb, Lethtendris, Sapphiron and five of Stratholme's). Forever's client draws its
  own model for the display. The batch taken in again (the set is new, nothing else changed).
- **The dungeons' view** (`Dungeons.lua`): a boss with a look gets a `PlayerModel` of it standing on its mark
  (`SetDisplayInfo`, as the game's guild news shows a boss), `Dungeons.MODEL_WIDTH` x `MODEL_HEIGHT` at every zoom,
  turned `Dungeons.FACING`; one lower on the screen in front; hidden while it would reach past the view's edge (the
  engine does not cut models there), its mark stays; its tooltip the boss's; let go (`ClearModel`) when the view
  closes.
- Tests: Navigation 399 checks (the model in its look on its mark, its tooltip, hidden past the edge and back, a
  boss without a look, let go). A game restart takes it in (the World pack's set changed).

### Navigation: the travel overlay lower and golden, smooth, and while waiting at a dock (Saneroki, 2026-10-21)
- **The overlay** (`TripView.lua`, at Saneroki's ask): centred two thirds up the screen (placed again when the
  screen's height changes), a fine golden line in the map route's art (Route.lua's edge, fill and glint, its pulse
  from Route.xml) in place of Core's bar, the start's and the end's names above its ends, the vehicle's icon riding
  at its tip, a flight point's mark at each stop; under it the time to the end (large), the next stop and its time,
  the zone. The line moves smoothly: every frame while shown (OnUpdate) it eases towards where the trip is between
  Core's looks (`TripView.EASE`), the time to the end counting down with it.
- **Waiting at a dock or the tram's station:** the same overlay shows the next to come there, the line filling from
  when it last left there to when it arrives, then *Board now* and when it leaves; how often it comes while its
  times are not known; the other ways there in a line each below. `DockWatch.lua` only finds the rows now (with
  `kind`, `arrive`, `leave`, `last`, `every`; the tram's at its stations, within `DockWatch.STATION` yards); its own
  frame is gone, the overlay draws them. The settings' tips say so.
- **Core's trips** (`Data/Trips.lua`): each trip's `pace` and `t` (to move it on between looks); the tram's times
  learnt on a ride (three looks that agree within two seconds on when its train left its station, kept per realm
  in Core's saved data, trusted as the ships' times), `Trips:NearTram(yards)` and `Trips:TramNext(key, at)`: a train
  leaves each station every `wait` seconds and stands there `wait` less its run.
- Tests: `dev/tests/navigation.lua` (386 checks: the overlay two thirds up, the wait's line from the last
  departure, a tram ride learnt, waiting at the tram's station).

### Navigation: dungeon maps of Core's data, with their bosses (Saneroki, 2026-10-21)
- **Core's new set *Dungeons*** (pack World; `assets/data/Dungeons/`, source batch 9, unverified): Forever's client
  has no maps of its dungeons (its map table holds 60 maps, none of the kind Dungeon), but its files hold the game's
  dungeon map art. For the 26 classic dungeons and raids Forever has: each floor's art size and tiles (816 files,
  every one byte for byte the same in Forever's live and beta clients as in Blizzard's newest retail client), the
  part of the world the floor shows (one box per floor, its assignments agreeing within half a yard), and where each
  boss stands (138 bosses, only those Forever's clients list under the same encounter in the same instance; their
  names are the set *Encounters*). The bosses of the dungeons Blizzard reworked later (the Deadmines, Shadowfang
  Keep, Gnomeregan and others) are left out: their encounters differ.
- **The dungeons' view** (`Dungeons.lua`): the list takes the set's dungeons too (walked once it is there, `Each`;
  the game's own map wins by name), each floor keyed `"<instance>:<floor>"`; their art from the set's tiles; each
  boss in the game's boss mark (`Dungeons.BOSS`, `vignettekillboss`), the same size at every zoom, its name and "not
  yet confirmed" in its tooltip; the player's arrow by `UnitPosition` in the floor's box; inside, the full map opens
  on the floor whose box holds the player (the instance from `GetInstanceInfo`). While the game has told of no
  dungeon map, it is asked again (as before), the set's dungeons kept beside.
- **Entrances** (`Pins.lua`, Core's `Data/Map.lua`): a place hands on its `instance`; a dungeon's entrance whose map
  the set has opens it with Shift and a click (`Dungeons.Key`).
- Tests: Navigation 390 checks (a dungeon of the set: its floors, tiles, boss marks and names, the arrow, the floor
  you are on). A game restart takes it in (the World pack's new set).

### Inventory: the bank as a list, a tab's settings, buying a tab (Saneroki, 2026-10-21)
- **The list** (`Bags/Bank.lua`, `Bags/Columns.lua`): the bank's dropdown *View* has *List*; a column head of its own
  over the bank's list (`Columns.Build(parent, redraw)` makes one per window, `Columns.head` the bags'; the column
  choices stay the bags', and a change refreshes every head and draws each window anew; `Columns.Rounded` for the
  canvas's round icons).
- **A tab's settings**: a tab's row by its own icon, its tooltip what it takes; a right click, where the client has
  `C_Bank.UpdateBankTabSettings`, the game's menu: *Rename* (16 letters, as the game's box), *Assign To* the five kinds
  of the game's tab settings (`Bank.TAKES`, `Enum.BagSlotFlags`, the game's `BAG_FILTER_*` words) and *Ignore in Clean
  Up*; each change the game's call with the tab's name, icon and other flags as they are; drawn anew at
  `BANK_TAB_SETTINGS_UPDATED`. The sidebar takes a `tip` for a row's own tooltip.
- **Buying a tab**: *Buy Tab* after a bank's tabs where `C_Bank.CanPurchaseBankTab` says so (its cost in the
  tooltip); over it, unseen, the game's `BankPanelPurchaseButtonScriptTemplate` (one per bank, `overrideBankType`),
  so the click, the question and the purchase are the game's; our code never calls `PurchaseBankTab`.
- Tests: `dev/tests/bags.lua` (237 checks): the bank's list under its own head sorting the bags' columns, back to the
  grid; a tab's icon, tooltip, menu, a kind assigned and taken back, left out of the clean-up, renamed (cut to 16);
  Buy Tab with the game's button over it, its cost, its click the game's. A `/reload` takes it in.

### Inventory: categories dragged in the bags' sidebar (Saneroki, 2026-10-21)
- **The drag** (`Bags/Sidebar.lua`): a row a window marks (`row.drag`) is dragged with the left button (not while an
  item is on the cursor): a ghost of it follows the cursor (`Rail:Lift`; strata `TOOLTIP`, `Sidebar.GHOST`, the row
  itself faded to `Sidebar.LIFTED`), a line of `Core.GOLD` shows where it would go (set in where it lands inside a
  group) or the row it would go into is lit (`Sidebar.INTO`); the row under the cursor and how far down it
  (`Rail:Under`) are asked of the window's `aim`; let go (`Rail:Land`), the window's `place` puts it there. The ghost's
  `OnUpdate` runs only while it is shown and gives up when the mouse button is no longer down (`Rail:Cancel`; also
  when the bags hide).
- **The bags' rules** (`Bag.Aim`, `Bag.Place`): the movable categories and the groups are dragged (Pinned, Recent and
  Junk never); the top and foot quarter of a row (`Sidebar.EDGE`) put it before or after (between a group's members:
  into that group; under a group's row: its first member), the middle joins that row's group or makes a group of the
  two (`Categories.Join`, `GroupWith`); a group goes before or after another group as a whole; Pinned and Recent take
  nothing, Junk only before it.
- **Categories** (`Bags/Categories.lua`): `Categories.Movable`, `Place` (a category before or after another, then in a
  group or none; one that is never grouped stays in none; a target that does not move: the end, before Junk) and
  `PlaceGroup` (a group's members together), kept in `kept.order` and `kept.member`.
- Tests: `dev/tests/bags.lua` (220 checks): placed before another, into a group between its members, to the end, a
  group as a whole, Pinned, Recent and Junk never moving; in the window the ghost and the line, a drop before a row,
  into a row's middle (a new group), out of a group, a group dragged, before Junk, nothing over Pinned, the drag given
  up. A `/reload` takes it in.

### Inventory: our own sort of the bags in One Bag (Saneroki, 2026-10-21)
- **The sort** (`Bags/Sort.lua`, new in the TOC): the bar's clean-up button in One Bag moves the items of the ordinary
  bags (never the reagent bag, a bag for one kind of item or the keyring) into the categories' order: pinned items
  first, then by category (`Categories.order`, the player's), inside one by the window's Sort By (`Contents.ORDERS`),
  then by link, the larger stack first; the empty slots last. In passes, each slot touched once per pass
  (`C_Container.PickupContainerItem` twice: the game swaps two items or joins two stacks): first the partial stacks of
  an item joined (the smallest onto the largest, inwards), then each slot given the item the order wants there.
  After a pass it waits for `BAG_UPDATE_DELAYED` and the slots unlocked (`Sort.WAIT`, at most `Sort.LONGEST`), then
  plans anew from the bags. It stops when nothing is left, a pass changed nothing, after `Sort.PASSES`, at a fight
  (never starts in one), with something on the cursor, or when the window hides; a move that left an item on the
  cursor puts it back. The button is locked (greyed) while it runs (`Bags.Sorting`). The other views keep the game's
  `C_Container.SortBags`. The planner (`Sort.Plan`) has no frames.
- **Contents**: `record.stack` (a full stack, the game's item info), `Contents.Before` (an order's tests without the
  slot, also used by the views' orders).
- Tests: `dev/tests/bags.lua` (199 checks): partial stacks joined in the first pass, the final order, the special
  bags untouched, nothing moved when sorted, no sort with the cursor full or in a fight, a fight stopping it, the
  other views' game clean-up. A game restart takes it in (a new file in the TOC).

### Navigation: a map pin the game refuses no longer stops the map (Saneroki, 2026-10-20)
- `Live.SetWaypoint`: a place off the map's edge (or no number) puts no map pin, and the game's
  `C_Map.SetUserWaypoint` is asked in a protected call: where it refuses the point, the bar says that no map pin can
  go there, instead of an error that made the module stand down (the error log, 2026-10-20 23:28).
- Tests: Navigation 382 checks. A `/reload` takes it in.

### Navigation: quest marks as the game's, the pin filter in sections (Saneroki, 2026-10-20)
- **Quest marks** (`Pins.lua`, `PinView.lua`): quests in your log the game's yellow question mark (`Pins.ICONS.log`;
  the target mark for one in progress is gone), quests to take the yellow exclamation mark at full opacity
  (`PinView.OFFERED` gone), too low the grey one, for later the question mark in red (`Pins.ICONS.later`,
  `pin.tint = Pins.RED` over the game's yellow; the kind *Quests for later* takes its own pins, `low` and `later` no
  longer share the grey mark).
- **Tooltips**: no line saying a click puts the map pin there (`Pins.TEXT.drop` gone); the quest lines say only what a
  click does on the full map.
- **The pin filter** (`TopBar.lua`, `Navigation.lua`): its kinds in sections under the game's menu titles, a line
  between them (`ns.PIN_SECTIONS`, each kind's `section`; a kind of no known section last): around you, quests,
  travel, towns and services, rares and treasures, gathering. Icons of 24 (`TopBar.ICON`; `ns.KindLabel(kind, size)`,
  a tint in the atlas markup), rows 30 high, those without a slider too; it scrolls on a screen lower than it.
- Tests: Navigation 380 checks (the four quest marks, the red row in the filter, the sections). A `/reload` takes it
  in.

### Navigation: the tram in the routes (Saneroki, 2026-10-20)
- **The planner takes the Deeprun Tram** (`Planner.lua`, `Tram`): its two entrances (Core's set *Travel*, the
  tram's `docks`: the cities' entrances to its stations, points of the city maps) are docks of the journey on the
  Eastern Kingdoms' plane, boarded and left right there; the way between them costs the walks down and up and the
  loading screens (`Planner.STATION`, 30 seconds, a guess), half the time between two trains from a station and its
  run (`time`, 58.633 seconds). Its leg is drawn red, straight from entrance to entrance (the tunnel's map has no
  plane; in it the line stays as it is). The ships' ways are as they were; `Ships:Next` is asked only for a ship's
  stop.
- **The tram's `wait`** (set *Travel*, `dev/tools/travel-data`): 71.666 seconds between two trains leaving one
  station, its cars' motion once round (143.333 seconds, the same for all six, the game's TransportAnimation) over
  its two trains (three cars each, setting out from the two stations together, as their motions show). Taken into
  the master as a correction of the tram's line alone (`import --take`); the schema's note on `wait` says what it is
  for the tram.
- Tests: `dev/tests/navigation.lua` (377 checks: the test pack's tram with its entrances and a wait; a pin far in
  the north reached on foot, by the tram, on foot, the tram's leg straight between its entrances; the trip view
  names the tram's stations).

### Navigation: quest areas in place, nearer zoom, dungeon maps, the quest log a window that pins (Saneroki, 2026-10-20)
- **Quest areas** (`Areas.lua`): stood where the zoom before had put them. The engine shades the area into the
  quest area frame's rectangle as it stands when asked, and a frame just placed or sized has its new one only after
  the game's layout at the frame's end; now each frame is placed at once and its area drawn on the next frame, as
  Blizzard's map waits after a change of scale.
- **Zoom**: `Camera.NEAR` 2 → 8 units a yard, four times the game's nearest minimap step in the small window (the
  view Atlas three times that). The wheel goes on in past the game's narrowest step with our map alone, and out
  again takes that step (`Hybrid.Wheel`).
- **Dungeons** (new `Dungeons.lua`, in the TOC): every map of kind *Dungeon* under the world map, one entry per map
  group (its floors), in the bar's new dropdown *Dungeons* (A to Z, scrolled) with a floor dropdown beside it; drawn
  in a view of its own over the canvas from the game's map art (`Art.Of`, now exported): fitted, the wheel zooms up to
  four times, a drag moves it, a right click goes back to the map at its zone, the player's arrow on the floor shown.
  `Canvas.Show` of a dungeon's map opens it (Shift and a click on an entrance); inside a dungeon the full map opens
  on it; going small closes it.
- **The quest log** (`QuestLog.lua`, `Window.lua`): a window of Core's of its own over the full map in place of the
  panel at its left (the map takes the whole screen; `Window.FullSize` no longer takes its width off): moved by its
  title bar, docked, sized by its grip while the mouse is on it, place and size kept (`store.questLogPlace`). The pin
  on its title bar (`store.questLogPinned`) keeps it on the screen while the map is small, in the layer `LOW`,
  without background, border or the title bar's line; over the full map it is in `DIALOG` with its dark background.
  Its close button takes it out of both. The bar's *Quest Log* still puts it in or out over the full map.
- **Core's window** (`Window.lua`): `barLine = false` (a title bar without its line), `window.own[i]` (the module's
  own title bar buttons) and `button.picture` on them.
- Tests: Navigation 375 checks (the area drawn on the next frame, the wheel past the narrowest step, the dungeons,
  the pinned log). A game restart takes it in (a new file in Navigation's TOC).

### Guild: the guild window, the wire and the guild's records (Saneroki, 2026-10-20)
- **New module Guild** (`src/Guild/`, `SaneUI_Guild`, plan `Doc/ideas/Guild.md`): one window for everything a guild
  needs, on Social's full screen in place of the game's guild window there (offered to its board), or a window of its
  own without Social; the guild key opens it (override bindings, `Keys.lua`, `Bindings.xml`), `/sane guild`. Its page:
  the guild's crest in a ring, name, online, when last synced, the options' gear, *Sync*; the game's tabs Overview, Guild,
  Quests, Dungeons, Loot, Professions, Raid, Officers (officers only), small tabs under those with several views; a
  status line. Built views: the overview (who is where, the guild's news from the roster's history, guild chat with a
  line to write, the race to the highest level), the roster (head with the message of the day and invite, a sortable
  searchable table, online and offline folding, the member's page with rank up and down, notes, history, whisper,
  invite), equipment (everybody's gear on a paper doll with model, item level, slots). The other views say they come.
  Placeholders of the game's art stand where its own pictures go (`Art.lua`).
- **Core's wire** (new `src/Core/Data/Wire.lua`, `Core.Wire`, in Core's TOC): Sane UI's addon messages, built ahead of
  Data-build 1f.1: messages and packed blocks in parts, a queue that keeps to the game's budget, an inbox the scheduler
  takes in, senders by key, the player's own and other game versions' dropped, 90 a minute from a sender.
- **Core's guild records** (new `src/Core/Data/Guild.lua`, `Data.Guild`; the pack *Data: Guild*, saved data): the roster
  and its history (joins, leaves, rank changes, levels; a partial roster believed in nothing), members' records (the card:
  who a character is, what it wears, its professions), taken only from their owner, members only, newer only; hellos
  and asks by whisper. CLAUDE.md's *Game facts, not people*: people information built locally, never shipped.
- **Core's board** (`Board.lua`): a window of another module (`Core.Board.Offer`, `Withdraw`, `Offered`, `Open`,
  `Standing`, `Close`); Social leaves the game's guild window alone while Guild offers its own.
- **Sketches** of the guild window's look and parts (`dev/imagegen/sets/guild/`, Qwen 2.1 turbo; not shipped).
- Tests: `dev/tests/guild.lua` (79 checks), in `dev/tests/run`. A game restart takes it in (a new addon and pack, new files
  in Core's TOC).

### Navigation: your trip on screen, the flight's way on the map, the tram (Saneroki, 2026-10-20)
- **Core's trip underway** (new `src/Core/Data/Trips.lua`, `Data.Trips()`, in Core's TOC): the trip the player is
  on, a flight, a boat or a zeppelin, the tram: its stops, how far along, the time to the next stop and to the end;
  `Now`, `CanLand`, `Land`, `OnChange`. A flight is read at the flight master (`hooksecurefunc("TakeTaxiNode")`:
  its hops by the game's flight point IDs, each the set's flight with its path) and kept for the character until
  it lands, so a `/reload` in the air finds it; how far along from the player's place on its points; how long at
  the pace measured on this flight (after 8 seconds), before that the median of the character's last five
  flights' paces (a flight flown to its end), 30 yards a second before the first. Asked to land early
  (`TaxiRequestEarlyLanding`, hooked), it ends at the next flight point and teaches nothing. A ship aboard from
  `Data.Ships` (`Aboard` gives the run and the yards sailed too); the tram by the player's place in its map moving
  along its stations' line at its speed.
- **The tram** (set *Travel*, key 1000369, kind `tram`, `dev/tools/travel-data` from the game's tables): the
  Deeprun Tram's two stations (the game's triggers in its map where one leaves it), the run's 58.633 seconds (its
  six cars' motion, alike to the millisecond), the cities' entrances to it as its docks (pins on the city maps);
  the schema's notes say what a tram's path and docks are.
- **The trip view** (new `TripView.lua`, in Navigation's TOC; setting *Your trip on screen*, on): under the
  game's widgets at the top of the screen, from where to where, Core's bar of the way behind with a flight point's
  mark at each stop (dim once passed), the next stop and its time, the time to the end, the zone below; on a
  flight with a stop before its end the game's own *Request Stop* button (its art, words and look once asked).
  Drawn every second while a trip lasts, at once when one begins or ends; not while the map fills the screen.
  The dock watch steps aside on a trip (its aboard row gone; `DockWatch.Clock`).
- **The line while flying** (`Planner.lua`): the flight's way on from the player is the line's first leg, drawn
  anew every 3 seconds, the plan from where it lands after it; without a map pin, the flight's way alone; after
  landing, planned from the player (or the line goes). A leg in front (a flight's, a ship's) stays drawn when no
  way on from it is found.
- Tests: `dev/tests/navigation.lua` (351 checks: a flight of two hops taken, flown, measured, drawn on the map,
  landed early by Request Stop, flown whole and its pace kept; the tram; a ship's trip; the trip view).

### Combat: our own talents (Saneroki, 2026-10-20)
- **The talents** (new `Talents/`, 9 files in the TOC): the game's shared talent frame (`TalentFrameBaseTemplate`,
  `Blizzard_SharedTalentUI`) inherited, with the Camelot class layer the game's window adds ported (that layer is in
  `Blizzard_PlayerSpells`, never loaded): the class's art, clouds and lights (`Art.lua`), the trees' heads with
  their points and the unspent points (`Headers.lua`), the node templates with the class glow, tooltip and sounds
  (`Nodes.lua`), the primary and secondary specialization on the game's tabs with Activate (`Specs.lua`), Apply,
  Undo and the Reset menu (`Foot.lua`, `Changes.lua`), the commit's cast on a cast bar of ours from the game's
  `CastingBarFrameTemplate` (`Commit.lua`; no casting bar of the game's touched), the frame, its search marks and
  events while shown (`Tree.lua`). Every method of ours and every script the templates gave our frames behind the
  module's guard. Changes only on the active specialization and out of a fight; Apply as the game allows.
  Registered as the board part `talents`, scaled to fit its panel.
- **The spellbook** fits its panel's body: Core's board gives a window the panel's size, its head and edges
  are taken off now (`Book_.Size`).
- Tests: `dev/tests/talents.lua` (64 checks, new, in `dev/tests/run`); `dev/tests/combat.lua` 36 (the first
  layout's shares with the talents there).

### Navigation: the coast keeps its docks; the view Blended (Saneroki, 2026-10-20)
- `dev/tools/terrain-art`: the land's alpha fades out over the first yard of water (`SHALLOW`), so a beach one wades
  on stays; what stands on the water is kept as land (`standing`): where the minimap is brighter or warmer than the
  water around it (its mean colour nearby, taken twice; a lone speck dropped, the rest widened by a sample), so docks,
  piers, bridges and ships at their moorings are no longer cut away. `levels` reads a terrain file's ground and water
  surface; `terrain` (used by the other tools) is unchanged.
- A tile on a coast gets a mask of its own, 128 x 128 (`Art/Coasts/<key>.blp`, listed in the new `Coasts.lua`):
  `Terrain.lua` cuts the game's tile by it up close instead of by its block's overview, which has a quarter of the
  detail.
- The view *Blended* (`blend`, between Parchment and Scrying): Parchment's art over Scrying's terrain, its alpha by the
  view's height (`Canvas.Blend`, `Canvas.BLEND`: whole at 9,000 yards and up, gone at 1,200, faded by the zoom's
  factor between), the sea's colour between the two; a layer at alpha 0 or under art at 1 is not drawn.
- Tests: the coast tile's own mask, Blended at the world, between and close in; the views' count is three without
  Atlas.

### Data: quest areas, trainers, paths, and achievements, mounts, factions and more (Saneroki, 2026-10-20)
- `dev/tools/game-data` reads more of the game's tables:
  - QuestAreas: 6 areas of Forever's new quests, as the client draws them.
  - New sets:
    - Achievements 144 (not the statistics; one of each twin pair the client keeps per set of realms);
    - Mounts 139 (by their spells; names stay the spells' in Spells);
    - TransmogSets 7;
    - Enchantments 2,132;
    - Holidays 18 (their starts and lengths; not the weekly ones' starts);
    - Factions 74 (those the reputation panel shows);
    - Encounters 338 (the bosses, by instance).
  - New pack Collections (Achievements, Mounts, TransmogSets).
  - A toy is a field of Items (`toy`), not a set of its own.
- Batch 8, what Forever's beta servers sent:
  - Trainers 1,534 (one answer from every trainer only);
  - PatrolPaths 16 (creatures with one path);
  - 11 vendors whose list as sent holds more than batch 5's: taken, with stock limits. 44 more agree.
- Left out: the 16 spells whose trainers disagree, and 12 whose skill is one of the professions' child tiers. Also
  creatures with several paths (PatrolPaths holds one per creature), and vendors whose list as sent is shorter
  (sold out, or for the other side).

### Navigation: indoor maps of our own, without the black (Saneroki, 2026-10-20)
- **The pictures** (`dev/tools/indoor-art`, new; `src/Navigation/Art/Indoors/`, 2,785 pictures of 345 buildings,
  47 MB): the game's own indoor minimap textures (its table WMOMinimapTexture: per building, part and block of 128
  yards, 2 texels a yard), each part's blocks laid into one picture, the black under its clear texels replaced by
  its edge's colour, its edge softened, resized to 1.4 to 2 texels a yard into a power of two (premultiplied, so no
  black fringe); BLP2 DXT5 with mipmaps. Left out: parts whose textures were made for another shape of the building,
  that the building lacks, or that draw almost nothing, and placements tilted more than 10 degrees.
- **The data** (Core's new set *Indoors*, pack World; `assets/data/Indoors/`, source the game): per building (its root
  file) its parts' pictures (where their corners lie in the building, their height, whether the game flags them
  indoor), its placements (continent, place, height, turn, scale), its terrain tiles (`byTile`); 345 buildings,
  1,054 placements.
- **The layer** (`Indoors.lua`, new in the TOC; `Canvas.lua`: the layer `indoors` over the map's art, `Canvas.LEVELS`
  and `Canvas.MAP` one up): indoors, the building the player stands in (its part holding the player's place,
  `UnitPosition`, of those on the player's tile), its parts at the player's height (from `Indoors.BELOW`, a yard,
  under their floor to their top; the floor nearest below on top; without a height every indoor part), each as the
  square the canvas lays it out in, its texture coordinates turned to the building's turn inside it, clear around it
  (`CLAMPTOBLACKADDITIVE`). Looked at again on the tracker's steps four times a second (`Indoors.Track`).
- **Tests:** `dev/tests/navigation.lua`: a two-floored building at the player's place: the floor at the player's
  height, its picture's corners, the floor above after the stairs, nothing outdoors.

### Navigation: herbs and ore found, sparkles, the finders in turn (Saneroki, 2026-10-20)
Saneroki asked for the herbs and ore on the minimap in their own pictures, sparkles on them in the world, and Find
Herbs and Find Minerals in turn, silently, all of it with switches in the pin filter and the settings.
- **The pin filter** (`Navigation.lua`): Core's herbs and ore are *Possible herbs* and *Possible ore*; new kinds
  *Found herbs* and *Found ore* (the finders' icons before them, their own size sliders), on at first (settings
  version 3 puts them on in older settings).
- **Found** (`Found.lua`, new): what the game's minimap shows, found by asking its tooltip at points of it
  (`Minimap:UpdateMouseoverAtPoint` with its soft cursor on, `C_TooltipInfo.GetMinimapMouseover`) in a sweep of
  rows shifted by half a step, out of combat and never under the mouse; a point that names a herb or ore narrowed
  to its dot's middle by halving the way to its edges, which also gives how far a dot answers (the sweep's step).
  Kept in yards in the player's plane; a sweep settles what its finder shows; the other finder's are kept until
  looted beside, far or five minutes old. Drawn on a frame of ours over the game's minimap (ours or the game's in
  its corner, turned with it where it turns): the herb's or ore's icon cut round in the gold ring of the game's
  minimap buttons (laid as `ItemDisplay.xml` lays it), grey while your skill is too low.
- **Nodes** (`Nodes.lua`, new): a herb or ore by its name (Core's *Objects*), its picture (what it gives by
  gathering in *Drops*: the herb or ore whose first word its name has), your skill for it; the finders as the
  filter's two kinds say (`Nodes.Apply`), and in turn while moving (setting *Find Herbs and Find Minerals in
  turn*, seconds of moving, 6 at first). Every switch silent: the effect sounds off until its cast went through
  (`UNIT_SPELLCAST_SUCCEEDED`, then 0.25 s; at most 2 s), what they were kept in the store until then.
- **Sparkles** (`Sparkles.lua`, new; setting *Sparkles on herbs and ore*, on): gold stars (the cooldown's
  `star4`, added light) twinkling on a frame of ours on the plate of the game's soft interact target, if it is a
  herb or ore. The interact key's settings as the game's gamepad setup has them (on, plates for objects, 20 yards,
  all around), set out of combat where they reach less, kept per character and put back when switched off.
- Tests: `dev/tests/navigation.lua`, 332 checks (the names and pictures, the filter switching the finders silently,
  the turns while moving, a herb found on its dot and gone again, the sparkles and the settings put back).

### Inventory: the bag keys open our bags, the game's stay closed (Saneroki, 2026-10-20)
Saneroki asked that the bag key open the Inventory full screen with our bags and the game's bags stay closed.
- **Keys** (`Keys.lua`, new; `Bindings.xml`, new: `SANEUI_INVENTORY_BAGS`): the keys of the game's bag actions
  (`TOGGLEBACKPACK`, `OPENALLBAGS`, `TOGGLEBAG1`-`4`, `TOGGLEREAGENTBAG1`) run ours by the game's override bindings,
  as Combat's keys do: the full screen with the bags (`Window.Open`, `Window.Toggle`, `Board.Add`, `Board.Has`),
  pressed again back. A click on the game's bag buttons does the same (hooks after their clicks; not when it put an
  item into the bag).
- **The game's bags** stand unseen in a hidden frame of ours (`Core.Lend`), so the game opens and closes them as
  always (vendor, bank, mail) and nothing shows; Classic windows' *Bags* shows them again until they are all closed.
- **The setting** *Bag Keys Open Our Bags* (`bagKeys`, on at first) in the section *Bags*; standing down gives it all
  back.
- Tests: `dev/tests/inventory.lua` (105 checks): the override bindings, the game's bag windows unseen, the key and
  the backpack button toggling the full screen, Classic windows' bags, the setting, standing down.

### Inventory: every category and its name always in the sidebar, the bags' strip at first (Saneroki, 2026-10-20)
Saneroki asked that the bag slots and categories work and that the categories and their names always show.
- **Sidebars** (`Bags/Sidebar.lua`): never folded to icons any more (the arrow and the kept `narrow` gone): the
  names always show, one cut short whole in its tooltip. The bags' lists every category switched on, empty ones too
  (count 0); the setting *Hide Empty Categories* is gone. The alts' Storage lists every category too.
- **The bags' strip** (`Bags/Bags.lua`): shown at first (`strip` not false); its button a bag of the game's classic
  icons (an atlas Forever may lack is no longer used for it); the clean-up's atlas has a broom of the game's icons
  where the client lacks it.
- The alts' window at least four items wide (Storage stands wide now).
- Tests: `dev/tests/bags.lua` (186 checks): empty categories by name with 0, the strip shown at first.

### Inventory: the alts in the bags' look, Storage, displays and categories (Saneroki, 2026-10-20)
- **The look** (`Alts/Items.lua`): items 34 wide in the bags' flat look (the icon cut round its edge, a border in
  its quality's colour, the item level of gear, the bags' count font); a place's head in the bags' style with how
  many items it holds.
- **Displays**: the dropdown *View* on the head: Grid, List (the bags' list columns: name, item level, required
  level, type, bind, count, sell price), Compact (the categories side by side, the bags' planner); Group by
  Category (a head per category, the bags' order and names). An item's category is the bags' (`Items.Record`).
- **Storage** (`Alts/Alts.lua`, `ns.Sidebars.New` beside the roster): All Places, Bags, Bank, Equipped, All
  Categories and each category with how many of the character's items it holds; a click shows only that place or
  category. Kept in `store.alts` (look, group, narrow); `Bags.Store` gives the alts the bags' categories and
  columns.
- Tests: `dev/tests/inventory.lua` (92 checks): Storage, a place alone, a category alone, the list, compact, by
  category; the heads in the new style.

### Inventory: the bank, a window of its own (Saneroki, 2026-10-20)
- **The bank** (`Bags/Bank.lua`, new; the part `bank` after the bags): on the full screen while at a banker (its
  part's `Present`; `Board.lua` gives a part's `present` to Core's board, which leaves the window out while away;
  the first layout leaves it out too; `Window.Reboard` at `BANKFRAME_OPENED`/`CLOSED`, listened to from the login).
  A sidebar with All Bank Tabs, One Bank and each tab by its name with its slots taken; the bar with the slots
  taken, *Deposit All Reagents* (moved here from the bags' bar), the game's clean-up of the bank shown, the
  dropdown *View* (Grid, Compact, Group by Category, Sort By); the gold at its foot. The bags window shows the bank
  no more.
- **For two windows**: the item buttons a pool per window (`Cells.New`), a sidebar per window (`ns.Sidebars.New`),
  the drawing per window (`Bags/Canvas.lua`, new, out of `Bags.lua`), `Views.Build` with a window's own store; the
  views tell the bags' section by its place.
- Tests: `dev/tests/bags.lua` (184 checks): the bank's window coming and going, its sidebar, views, group by
  category, clean-up, deposit, a pin from it.

### Inventory: the stack splitter, the bags' settings (Saneroki, 2026-10-20)
- **The splitter** (`Bags/Split.lua`, new): Shift and a click on a stack (in All Items and the categories always, in
  One Bag and Each Bag with *Stack Splitter Everywhere*): how many (typed, - and +, the wheel), *Split* (Enter) into
  the first free slot, *Auto Split* (Alt and Enter) the whole stack in turns, each split after the one before is
  done (at most 2 seconds); the game's `StackSplitFrame` hidden when it opened.
- **The settings** (`Inventory.lua`, the section *Bags* on the page Inventory): Open With, Show Pinned Items, Pinned
  in One Bag and Each Bag, Show Recent Items, Recent in One Bag and Each Bag, Hide Empty Categories, Show Add
  Category, Merge Stacks, Junk Marker, Stack Splitter Everywhere, Show Item Level, Quality Borders, Show BoE, Show
  Set Name, Coin on Junk, Grey Junk. The dropdown *View* and the menus set them by `Core.Set`; they moved there from
  `store.bags` (`Bags.Settled` draws the bags anew).
- Tests: `dev/tests/bags.lua` (176 checks): the settings, the splitter.

### Inventory: the list's columns, the compact display planned (Saneroki, 2026-10-20)
- **The list's columns** (`Bags/Columns.lua`, new): icon, name, item level, required level, type, bind (BoP, BoE,
  BoU, Quest, SB once bound), count, sell price; a head over the list: a click sorts by a column (numbers high first,
  again the other way), a drag moves it, its right edge sizes it, a right click chooses the columns, moves one, makes
  the icons round (`Cells.Round`, a round mask) or puts it all back; a category's head folds its lines (Shift: all).
- **Compact** (`Layout.lua`): which categories share a band and how wide each is, planned for the fewest lines
  (`Plan`, dynamic programming); a block not last in its band at least three wide.
- Tests: `dev/tests/bags.lua` (169 checks): the columns' values, sorting, menu, moving, resetting, folding.

### Inventory: a "+" to put items in, the junk marker, junk sold one by one (Saneroki, 2026-10-20)
- **"+" cells** (`Views.lua`, `Layout.lua`, `Bags.lua`): after Pinned (shown when empty too) and every category
  that takes items: an item brought to it goes in (`Menus.Drop`); clicked with nothing, the next item clicked does.
- **Choosing by clicks** (`Bags/Select.lua`, new): a catcher over the items takes the mouse, the item under it lit
  in Sane UI's colour, the rest of the window dimmed; a click puts the item in (and ends) or, in the junk marker's
  mode, marks or unmarks it as junk (and stays); a right click, Esc, a click on the dimmed parts or a fight ends it.
- **The junk marker** (`Bags.lua`): the coin on the bar, while the marker is on: a click begins or ends the mode,
  an item brought to it is marked or unmarked at once. A grey item unmarked anywhere is kept out of Junk
  (`Categories.MarkJunk` puts it into Miscellaneous).
- **Selling junk** (`Foot.lua`): one item every `Foot.STEP` seconds, each checked to be still in its slot, while
  the vendor is there, out of a fight, the cursor empty; the chat says how many were sold, for how much, and how
  many could not be.
- Tests: `dev/tests/bags.lua` (161 checks): the "+" cells, choosing by a click, the junk marker, selling one by one.

### Inventory: the bags made over (Saneroki, 2026-10-20)
Saneroki asked for a much richer bag view, in features and looks.
- **The look** (`Bags/Cells.lua`): the item buttons a pool (`Cells.Take`), each the game's
  `ContainerFrameItemButtonTemplate` in a holder of ours that carries its bag; flat: the icon cut round its edge,
  a thin border of the screen's own pixels in the quality's colour (quest items twice as thick, in gold), a warm
  glow pressed, the count, the item level at the top left, BoE on unbound gear (a switch), the set's name (a
  switch), the game's `QuestNormal` on an item that starts a quest, the junk coin (a switch), red for what the
  character cannot use (`Contents.lua`: a red line in `C_TooltipInfo.GetBagItem`), dark squares for empty slots and
  pads. Sizes 34 and 4 apart (`Layout.SIZE`, `GAP`).
- **The window** (`Bags/Bags.lua`): a dark bar at the top (the slots taken of how many, every bag's in its tooltip;
  sell junk or deposit reagents, the bags' strip, the clean-up, the dropdown *View*), the sidebar at the left, a dark
  foot (currencies, gold; `Foot.lua`), heads in grey with a thin line to the right; the strip of the bags under the
  bar (`Foot.Bags`: each bag in its quality's border, its free slots on it).
- **The categories** (`Bags/Categories.lua`, new; `Groups.lua` gone): the built-in ones and their rules (Weapons /
  Trinkets, Armor, Item Set Gear by the equipment sets' locations, Consumables, Gear Enhancements, Camp Items by the
  game's item IDs, Trade Goods, Professions, Reagent Bag, Miscellaneous, Quest Items off at first, Special Bags,
  Junk last), the player's own with an icon, groups of categories (The Armory and Adventure Prep at first; named by
  their members until named), renamed, moved, hidden from All Items, switched off; pins, items put into a category,
  junk marks (unmarked: back where they were). Kept in `store.bags`, checked when read.
- **Recent** (`Bags/Recent.lua`, new): what came into the bags lately, counted from the login on (bags and what is
  worn), at most 15, newest first; not at the bank.
- **The views** (`Bags/Views.lua`, new) and **the sidebar** (`Bags/Sidebar.lua`, new, `ns.BagSidebar`): All Items,
  One Bag (every slot, empty ones too), Each Bag, Pinned and Recent (a second look), a category, a group; stacks of
  one item merged into one cell (not gear; not at a vendor, bank, mailbox, trade or auction house); counts in the
  sidebar; the sidebar folds to its icons. A middle click pins an item (or takes it out of the category it was put
  into); an item let go over a category's row or head goes into it.
- **The displays** (`Bags/Layout.lua`): grid (the last line filled with pads), list, compact (the categories side
  by side in bands, each near square).
- **The menus** (`Bags/Menus.lua`): an item's (Pinned, Junk, Put Into, Take Out of), a category's (Rename, Move Up
  and Down, Create Group With, Add to Group, Take Out of its group, Hide in All Items, Switch Off; the player's own:
  Icon, Delete), a group's (Rename, Move, Hide, Disband), Pinned's and Recent's (Hide; Recent: Clear); the dropdown
  *View*: Grid, List, Compact, Sort By (Default: gear by item level, then kind, quality, name), Show Pinned Items,
  Show Recent Items, Hide Empty Categories, Merge Stacks, Open With, Switched Off.
- Selling junk leaves out what is in a special bag, in an equipment set, pinned or refundable.
- Tests: `dev/tests/bags.lua` rewritten (147 checks): the records, the categories and their rules, the player's
  choices and what is kept, Recent, the views, the displays, the window with its sidebar, menus, drops, dropdown,
  events, the strip, selling junk, the bank, a fight.

### Art: concept art for a quiet grey look (Saneroki, 2026-10-20)
- New set `dev/imagegen/sets/ui-style/`: high fantasy but subtle, with small grey borders, in three directions
  from words alone (slate, moonsilver, iron): `concept.txt` (the character doll with its stats, the spellbook,
  Combat's full screen, a sheet of controls) and `fullscreen.txt` (Social's, Navigation's, Combat's and the
  character and bags' full screens and the docked windows, 16:9, moonsilver and iron).
- The leather look (Saneroki liked the brown book): `leather.txt` (leather binding, metal buckles and corner caps,
  parchment pages, every view), `leather-ref.txt` (the same with that book as image 1: it copied the book
  into every view), both from `leather-views.txt`; `shapes.txt` (fancy silhouettes instead of rectangles,
  and character dolls whose slots are shaped like their gear, laid out around the hero with their main stats).
- The character sheet (Saneroki chose `shapes`' doll-arc-2, now `assets/Concept art/UI style/sheet.png`): our sheet's
  twenty slots, each a light frame in its gear's silhouette with a plain inside for the item's icon
  (`slots-light.txt`, `slots-words.txt`; the dark backplates of `slots.txt` left too little room), the sheet's
  four tabs (equipment, skills, reputation, currency; `slots.txt`), the sheet emptied (`sheet-clean.txt`), and
  `compose.py`, which lays them out on it exactly with the game's icons; `sheet.txt` (the picture edited) did
  not keep the slots' number.
- A wide exploration (`dev/imagegen/sets/ui-explore/`, Saneroki found the sheet too airy): eighteen directions
  (leather, metal bars, castle stone, oak and iron, elven silver, gothic, dwarven, scrolls, arcane slate, druid,
  minimal, heraldry, knotwork, marble, stained glass, plate armour, mapmaker, notice board), each as a compact
  character sheet, a window with an unusual outline, a sheet of loose pieces, a spellbook and a frame made for
  stretching, with four models (`klein.txt`, `zimage.txt`, `qwen.txt`, `sdxl.txt`; `frame.txt` with FLUX.2 [dev]);
  `slice.py` cuts each frame into nine and draws it at four sizes as the game stretches it, `gallery.py` makes
  a page to look through them all (filters, liked ones). Then `elements.txt` (each direction's corner, buttons, tabs
  and title bar alone, with Qwen's transparency) and `shapes.txt` (fourteen silhouettes and ways of joining the
  tabs to the frame, in plain stone and steel).
- Qwen against FLUX.2 [dev] (`dev/imagegen/sets/ui-compare/`): the same 18 complete windows from both
  (`qwen.txt`, `flux.txt`), each model's window closed by its own edit and opened by Wan 2.2 from the closed to
  the open picture (`anim.py`, with the new workflow `dev/imagegen/workflows/wan22-14b-flf-2ref.json`: first
  and last frame from two pictures), and `compare.py`, a page with both side by side and `notes.html`, what each
  model offers for game elements.
- Full screens (`dev/imagegen/sets/ui-fullscreen/`): eight screens of the game's and our windows together, under a
  few rough rules (compact, slim borders, one connected family of pieces, plain textured free areas, faction
  neutral), for Qwen with and without its prompt enhancer (new workflow `qwen21-pe-t2i.json`), FLUX.2 and Z-Image.
- Small panels with Qwen (`dev/imagegen/sets/ui-panels/`, Saneroki: compact, little room for art, dynamic outlines
  for the character doll and the spellbook): `panels.txt` from words; `guides.py` draws exact layouts (slots,
  outline round them) which `guided.txt` has Qwen's edit paint; `anim.py` takes a panel out of its picture in
  code and has Wan 2.2 paint it appearing, played backwards for leaving. Qwen's ControlNet
  (`qwen21-cn-t2i.json`) painted the guide's lines themselves, so the edit took its place.
- Narrowed (`dev/imagegen/sets/ui-paper/`, Saneroki: Qwen as the model; leather, paper, cloth bookmarks, small
  metal accents and ink sketches, but thin and quiet behind the content): `style.txt` shared by the dolls on
  their layouts (`dolls.txt`, and `dolls-ref.txt` with a liked journal screen for the materials), small panels and
  full screens through the prompt enhancer. The doll's layouts in `ui-panels/guides.py` now have all twenty
  slots (the three weapons and the ammo below the hero), a third layout (the hero between two arcs) and
  `doll-quick`, the picked doll with a strip of quick stats outside each slot (`quick.txt`). Then the split look:
  leather and metal only for bindings and belts, pencil strokes for every border on the paper, leather patch
  buttons (`windows.txt`). `appear.py`: windows appearing from nothing in a few hundred milliseconds, by Wan and
  made in code (pencil lines drawn in, then the window faded in), each ending on its still. `ui-panels/anim.py`
  plays only a clip's motion, quickly, and its `clear()` copes with busier backgrounds.
  `gallery.py`: a page of the set's pictures, numbered, each opening full screen.
- The look picked from the gallery (Saneroki): the journal screen's parchment pages bound in stitched leather
  (`style.txt`), headers as leather strips with the title and patch buttons, leather bookmark tabs on the left,
  faint quick pencil sketches. New lists: `doll2`, `windows2` (from words and with the journal screen as
  reference), `views` (doll, stats, spellbook, chat) and `guild` (the guild window's board with the podium,
  members, armory, race and crafting, after the plan in `Doc/ideas/Guild.md`), each also by Qwen's edit with the
  journal screen and a leather window as references.
- Decided (Saneroki): the character doll's layout, the hero in the middle, the twenty slots in arcs close round him,
  the stats outside (`ui-panels/guides.py` doll-final, painted by `doll-final-words.txt`; a second picture for the
  look took over the layout); Kalam with a paper grain as the main font (`fonts.py`: hand-printed fonts on
  parchment). `chat-compact.txt`: two-line pencil chat bubbles. `paper.txt` and `paper-test.py`: a seamless grain
  tile, clouds scaled to cover and coffee stains with transparency laid by code, at three window sizes.
- The interface style written down (Saneroki's decisions): new guide `Doc/guides/interface-style.md`, the journal
  of parchment and stitched leather with pencil on the paper, part by part (paper, leather, title bar, patch
  buttons, dropdown bands, tabs, side tabs, chat bubbles, the doll, bags, the guild window, animation) and what
  code makes (text, stains, sketches); its pictures in `assets/Concept art/UI style/`; listed in CLAUDE.md's
  guides; `ui-paper/style.txt` rewritten from it; image-generation.md points to it.
- Sane UI's own look replaces Blizzard's art (Saneroki): every window and view Sane UI makes or recreates gets its
  own layout, art, fonts and style; the native windows stay mostly untouched. `gui-development.md` says so (a new
  section, its art, window and font rules narrowed to native windows; Kalam as Sane UI's own font on paper); the
  house style `dev/imagegen/style.txt` is now the journal look, its anchor `assets/Concept art/UI style/
  edges-and-buttons.png` instead of `Elements.png`. The guide gains its scope, the two top-tab styles, leather
  patch pieces repeated to any width and the chat window with bubbles anchored left, right and middle. New lists:
  `parts.txt` (one transparent part per picture, no text), `overlays.txt` (stains and faint sketches) and
  `refine.txt` (the picked views refined to the guide by Qwen's edit).
- The interface's strict harness (Saneroki: the free renders drifted from the decided design):
  `dev/imagegen/sets/interface/`. `refs.py` cuts each decided part out of its pick, `elements-*.txt` have
  Qwen's edit copy it cleanly from that crop alone (transparent, no text), `compose.py` lays the views out in code
  from them (the leather sliced and repeated, `paper.py`'s paper, pencil lines, Kalam, titles pressed into the
  leather, the game's icons, class icons as pencil sketches; the character doll is the pick itself with its
  content put in), `polish.txt`/`polish.py` give each view one light pass, `gallery.py` numbers it all from #1.
  Kalam's font files in `assets/fonts/Kalam/`. The guide gains *The harness*, the doll as a copy of its pick,
  class colours on paper and the open leather font. The exploration (its six sets, renders and the older concept
  art, `Elements.png` among them) is archived outside the project.
- The harness's round 2 (Saneroki's review): the unnamed elements archived; the edges, the patch for every
  button, the drawn tab's lines and the patch tab kept (`assets/Concept art/UI style/elements/`). No colour in the
  design (brown leather, paper, pencil). New: plain dropdown bands for code inlays (`elements-band.txt`, the
  crop's marks smoothed in `refs.py`), the patch tab as an interlocking arrow with worn stitched ends (`shape.py`,
  `elements-arrow.txt`), bubbles drawn in code as one piece of paper with the class icon's round in their
  silhouette, the doll's slots in arcs, a darker, browner paper (`paper.py`, `TONE`), the gallery split into parts
  in use and parts to pick.
- The harness made strict (Saneroki: the windows had lost their decided borders and title bar): the frame is cut
  from the pick (#12) at its own scale, corners and all, its edges repeated with cross-faded joins; the title bar
  is the pick (#61) at its own height; the polish pass (a global model pass) is gone; `compose.py` refuses any part
  not in its list of decided parts. The guide's *The harness* lists ComfyUI's tools for strict edits (masked
  inpainting, differential diffusion, low strength, negative words, a LoRA of the approved pictures).
- Only the liked sections (Saneroki: everything he names is cut out of its picture and only that is used): the
  decided references are now cut-outs (the top tab row of #78, #69's letters, #120's paper top, #133's bubble, the
  leather tabs with pointed sides, the patch of #183 for every button, the parts of two kit sheets in `kit/`, the
  pencil sketches in `sketches/`); the whole pictures and the dropped patch are gone. The window is #12 itself,
  cleaned in code (`clean.py`: the strap's rows over the paper cut out, the title label's writing covered by its own
  paper) and cut at its own scale so its parts fit exactly; the title is written on #12's label. The doll without
  the rectangle behind the hero, a stony ground under him, by masked inpainting (new workflow
  `dev/imagegen/workflows/qwen21-inpaint.json`: only the mask is repainted, guidance 3 with negative words). The
  harness's lists and crops keep only decided sources; the discarded band and arrow lists are gone.
- The style locked in (Saneroki): the arrow tabs back as a second leather tab style, the pointed tabs dropped; the
  paper a dark brown close to the leather (`paper.py`, `TONE`), the frame's and the doll's paper moved to it with
  their leather kept; everything on the paper made of clean, sharp pencil lines on transparency (`pencil.py`
  keeps only line-thin marks of #14's box; boxes, tabs, slots, buttons and rules are built from them); the podium
  an artist's pencil line sketch in perspective, the class icons in crisp lines. New `catalog.py`: every decided
  part at 4K scale (a gentle Qwen pass over the part upscaled twice, transparency put back) and variants of
  #14's pencil pieces and five kit parts to pick from; the GPU runner's new job `interface`. The guide gains
  *Pencil pieces* and *High resolution*.
- The interface harness finalized: `catalog.py` is the whole render (the picks cleaned, the parts at 4K, the
  variants, the pencil pieces, the views, the gallery), each step skipping what it made, with `--status` and
  `--rebuild`; the GPU runner's job `interface` runs it with its status and rebuild. The guide gains *Running it*
  (the commands and how a new decision flows into the harness) and drops the last earlier wording (cream paper,
  loose pencil, paper pieces on the page).
- The final pieces (Saneroki, 2026-10-22: every element rendered once at final quality, no varieties): new
  `pieces.py` cuts every decided element into transparent 4K puzzle pieces with `pieces.json` (how each is laid):
  #12 into the window's top, bottom, edges and clasp, #3 whole, the patch, the tabs, the edges, all 22 kit parts,
  #14's pencil box and rule, the paper, the stains and sketches. `catalog.py` renders each missing part once: all
  kit parts (their holes, light metal the cut took for the background, filled first) and the patch tab without
  its letters; new step `masks` finds the background of #12 and #3 with ComfyUI's background removal (new
  workflow `birefnet-mask.json`); the variants step is gone. `compose.py` builds every view from the pieces at any
  scale (layouts in 1080p pixels, `--scale`), each window on transparency, and a new 4K full screen of the
  character, guild and chat windows; the guild window takes two columns when narrow. The job `interface` is
  queued again.
- The paper lighter again (Saneroki, 2026-10-22): `paper.py`'s `TONE` a light cream (220, 204, 178), between the
  dark brown and an off-white that was a little too white; the frame's and the doll's paper follow it (the
  doll's tone now taken from plain paper behind the hero's head, not the darker ground sketch).
- The window's bottom fits (Saneroki, 2026-10-22: it had a straight cut-off): `pieces.py` cuts it as its two corners
  and the page stack between them (`FRAME_BOTTOM_X`), transparent above the stack (`BOTTOM_JOIN`); `compose.py`
  stretches the stack whole between the corners, edge to edge (`butt`; the cross-fades showed as blocks where its
  bowed lines did not meet) and draws the page's edge on it (`page_edge`: a little darkening, a light lip, a soft
  shadow). Buttons are the patch stretched by nine slices (no repeat seams), a little higher off the page's edge.
- The window's bottom one piece (Saneroki, 2026-10-22: the straight cut-off still showed; the page, the edges and
  the stack did not belong together): new step `catalog.py bottom` repaints the band where the page meets its stack
  once, the whole width with both edges, by a masked inpaint of the 4K #12 (`BOTTOM`); `pieces.py` cuts the bottom
  from it with its paper fading into the page (`FRAME_BOTTOM` from 806, `PAGE_END`); the code-drawn page edge is
  gone.
- The window's bottom repaint kept between the bindings and above the stack (a wider band painted new corner caps
  and no stack, then the page's tips past the bindings); the masks of #12 and #3 made. The top joined edge to edge
  too (`butt`; the cross-fade `band` is gone), the title label's light evened out in code (`LABEL`), the edges'
  tiles from under the top's corners to under the bottom's caps (`EDGES_START`, `EDGES_END`), the binding above
  the bottom's caps the edges' own (`CAPS`, `BINDING`: no strap knot). `compose.py --scale 2` takes whole numbers.
- The window's frame one image (Saneroki, 2026-10-22: the bottom never fitted; the sides liked): the bottom is
  the left edge turned a quarter, the right edge the left one mirrored where #12's book ends (`RIGHT_IN`), mitred
  corners, #12's rounded metal caps over the bottom corners (`CAPS`, `frame-cap-*`, `frame-corner-*`); the
  repainted bottom and its step `catalog.py bottom` are gone. The edges' tan paper moved toward the page's tone
  and fading into it (`match_edge`, `EDGE_FADE`), the clasp faded in. The character window's outside also found
  by its backdrop's colour and cut to its frame (the background removal kept only the hero; `backdrop`,
  `DOLL_FRAME`); its slot columns bent along the arc as one piece (no steps in its edge). The four parts whose
  cut-outs had holes (the arrow tabs, the edges) are rendered once more from the filled ones; every view laid out
  at 4K by the job.
- The interface harness's page of pieces (`gallery.py` writes `pieces.html` beside `index.html`): the 61 final
  pieces by group with what `pieces.json` says of each, previews that keep their transparency, a backdrop to choose
  (checks, the page's paper, dark, light), full quality and true pixels on a click, the 4K views built from them.
- **The interface lab** (`dev/tools/ui-lab`, `dev/uilab/`, `saneui showuilab`, 127.0.0.1 port 8774; guide
  `Doc/guides/ui-lab.md`): Sane UI's Lua run under Lua 5.1 as the game runs it and drawn in the browser, so windows
  are built with the code that goes into the game. A stand-in of the game's widget API: frames, buttons, check
  buttons, edit boxes, scroll frames, sliders, status bars, message frames, the tooltip, cooldowns, animations;
  textures with coordinates, tiling, nine slices, masks, blend modes, colours; font strings measured with the font
  files' widths; anchors, strata, levels, layers, clipping; scripts, events, timers, the mouse and the keys.
  Blizzard's API documentation tells what the game has that the lab does not do yet (told in the log, never nil),
  gives `Enum`, `Constants` and the events (an unknown one is an error). Blizzard's own shared Lua and font objects
  run as they are. A fake server (`dev/uilab/worlds/default.lua`): the player, the guild, the party, chat on a
  script, the game's items and spells from the data master; the page sends chat and events. Scenes
  (`dev/uilab/scenes/`: `basics`, `journal-chat`), the draft `dev/uilab/drafts/Journal.lua` (the journal window
  from the 4K pieces as the game lays them: the top in three, the edges and the bottom repeated tile by tile, the
  mitred corners under masks, the caps, the clasp, the paper cut to the page). Reload on a change with the saved
  variables kept, an inspector of the frames under the mouse (made at which file and line), a Lua console.
  Settings of the computer in `~/.config/saneui/uilab.json` (the client's tables, the listfile, the atlases).
  `dev/tests/uilab.py` in the test run. `pieces.py mitres`: the four masks of the mitred corners
  (`frame-mitre-*`), made with the pieces.
- `dev/tools/imagegen`: an option's seed input (`sampling_mode.seed`) gets the seed too.
- `gallery.py` takes another set's folder.
- Qwen's text-to-image workflow takes its size as `aspect_ratio` and `megapixels`, not `width` and `height`.

### Data: items, spells, talents and recipes from the game's own tables (Saneroki, 2026-10-20)
- New `dev/tools/game-data`: a build's client tables (and a beta's hotfixes) as staging for nine sets that were
  empty. Forever live 70245 and beta 70450 (with its server's updates of 2026-10-18) are in the master:
  - Items 22,491 (17,671 from live's client, 4,820 only the beta's server sent, as batch 7, live's base);
  - ItemSets 269, Spells 5,804, Auras 723 (what items' use puts on: food, potions, elixirs, trinkets);
  - SkillLines 118, Professions 2,512 recipes (with the skill they are learned at, yellow and grey);
  - Talents 473 (the nine class trees), Legacy 97 (the three trees, the challenges, the Legacy rank's rewards);
  - Currencies 7.
- Left out, with the reason in `dev/data/staging/game-<game version>-left.csv`:
  - about 1,560 test and placeholder items;
  - the forms of a spell players never learn, and spells another spell sets off;
  - skill lines with no spell (the empty twins of the professions);
  - the second copy of each Legacy challenge (one per set of realms);
  - item stats, armour, weapon damage and texts the game fills in: the client works them out, and the crawl
    will read them.
- Items: new fields `description`, `classes`, `unique` (at the end), so items the game keeps apart don't look
  alike.
- Quest 3373's start item 10454 taken out of its line: neither Forever client has the item.
- Batch 7 in `sources.toml`.

### Navigation: ship times, learnt on a ride, and the dock watch (Saneroki, 2026-10-20)
- **Core's timetables** (new `src/Core/Data/Ships.lua`, `Data.Ships()`, in Core's TOC): a boat's or zeppelin's
  timetable from its record in *Travel* (the game's way and stays): between two stops it sails at the game's
  transports' speed (30 yards a second, speeding up and slowing down at 1 yard a second each second), a leap
  onto another map takes no time; its round is the set's `wait`, else one learnt from two rides, else its sailing
  and stays, and a known round stretches the sailing to it. `Table`, `Next` (when it next arrives at a stop and
  leaves), `Aboard`, `Near`, `Seen`, `OnLearn`, `Now` (the server's time to a part of a second).
- **Learnt on a ride:** the player's place in the world (`UnitPosition`, its fourth answer the map) moving along a
  way at the ship's full speed says when it left its last stop; five looks that agree within four seconds are a
  ride, kept for the realm in Core's saved data (`ships[realm][key]`, on this computer only, trusted twelve
  hours); a second ride corrects an estimated round. Looked at every 3 seconds, every second near a stop or
  aboard; nothing in a taxi's flight or while *Travel* is not loaded.
- **The ships' time once round** (set *Travel*, `wait`, batch 6 in `sources.toml`, unverified): the original
  game's for the five ways Forever's client has unchanged, point for point and stay for stay (Booty Bay and
  Ratchet, Menethil Harbor and Theramore, the three zeppelins between Orgrimmar, Grom'gol and the Undercity),
  only where every record agrees to the millisecond.
- **The planner** (`Planner.lua`): `Planner.Ship(way, key)` from Core's timetable (`Planner.SAIL`, `Planner.LEAP`
  and `Planner.SAME` gone), each way with its trip and stop; the wait for a ship the time to its next departure
  where a ride taught its times on this realm, else half its round; the docks made anew when a ride taught a
  round (`Ships:OnLearn`).
- **The dock watch** (new `DockWatch.lua`, in Navigation's TOC; setting *Ship times at a dock*, on): within 60
  yards of where a ship stops (kept to 90), under the game's widgets at the top of the screen, a row for each
  ship there: its icon, where it goes (the game's area and zone, `Pins.Towards`), when it arrives and leaves,
  counting down (grey, how often it sails, until a ride taught its times); aboard, when it lands. Not while the
  map fills the screen; gone when the module stands down.
- Tests: `dev/tests/navigation.lua` (312 checks: the runs and timetables, a ride learnt, its next times, aboard,
  a second ride correcting the round, the dock watch's rows, its setting); `wowstub.lua` has `GetServerTime` and
  `UnitPosition` (`W.serverStart`, `W.place`).

### Combat: our own spellbook, your keys opening it, the planner a window of its own (Saneroki, 2026-10-20)
- **Decided** (Saneroki, `Doc/ideas/Combat.md`, *Our own spellbook and talents*; `Doc/ideas/Windows.md`): the
  spellbook and the talents are Combat's own windows that look, feel and work as the game's, built as
  Inventory's character sheet is; the game's own window goes back to the game, untouched (no longer seated);
  the book casts out of a fight only.
- **The board** (`Board.lua`) is a registry of parts, as Inventory's (`Board.Part`, `Board.Present`,
  `Board.Add`): `talents`, `spellbook`, `planner`; the first layout the talents and the spellbook side by side,
  shared by the game's sizes. The game's window, its seat, the empty panels' secure clicks and their words are
  gone.
- **The spellbook** (new `Book/`): `Book.lua` (the part: the open book at the game's 1612 x 702, scaled to fit,
  one page where the panel is narrow; the game's square icon tabs per skill line and the pet's; the game's
  paging controls and mouse wheel; the game's settings Hide passives and Show all ranks, its CVars; the full
  window's search), `Data.lua` (the Camelot book's tabs and filter, flyouts loose, the search), `Layout.lua` (the
  game's paging rules with Camelot's numbers), `Item.lua` (an entry as `SpellBookItemTemplate` draws it: frames,
  rank, level or Trainable, the cooldown by the game's duration object, the glow of a spell on no bar, autocast,
  the level-link lock, the sheen; tooltip, drag, link), `Casts.lua` (the game's `SecureActionButtonTemplate`
  over each castable icon, on UIParent, out of a fight only: a spell by its ID, a pet ability by name and its
  autocast on a right click, no cast on Shift; away at `PLAYER_REGEN_DISABLED`, back after the fight).
- **Your keys** (new `Keys.lua`, `Bindings.xml`): Combat's keys under Sane UI in the game's key bindings, put on
  the keys of the game's spellbook, pet book and talents by override bindings (out of a fight; anew when those
  keys change; cleared with the switch *Your spellbook and talents keys open ours* off and at standing down):
  the full screen with that window, pressed again back (`Window.Open`, `Window.Toggle`).
- **The talent planner** is a window of its own on the board (in the dropdown *Windows* while its addon is
  there), seated in its panel, opened and closed with it; its opening brings the full screen while its window
  is on the layout.
- **Classic windows** (Core's, `Window.lua`): while our keys are on the game's, the game's spellbook and talents
  are said to open from the micro menu (`Classic.Press` without a binding); the Sane UI button on the game's
  window opens ours with the spellbook or talents on it (`ours = Window.Open`).
- Tests: `dev/tests/book.lua` (35 checks, new, in `dev/tests/run`), `dev/tests/combat.lua` (35: the board, the
  keys, the planner, the quest marks; the seat's and clicks' checks gone with them).

### Windows: layouts deleted, Classic windows across modules and back (Saneroki, 2026-10-20)
- **Layouts** (`Core/Board.lua`): every layout can be deleted from its tab's right-click menu while another is
  left, the first too (the next is the first then); a tab's tooltip says so (`Board.TEXT.tabTip`).
- **Classic windows** (new `Core/Classic.lua`, in Core's TOC after `Window.lua`; `Edge.lua` builds its dropdown
  from it): the dropdown lists every window's game windows, each under its window's title, the open one's
  first; one of another module's chosen, both full screens go back first.
- **The button Sane UI on the game's windows** (`Classic.Attach`, `Window.Beside`, `Window.CloseOf`): an entry
  with `frame` puts it beside the game's window's close button; pressed, ours comes instead (`ours`, `full`, a
  kept choice's `back`). On the game's panels it is a `SecureActionButtonTemplate` on UIParent that clicks the
  game's close button (our code neither shows nor hides the game's panels), our part in `PostClick`, made and
  shown out of a fight only; plain windows (`plain`: the bags, the minimap) get a plain button.
- **The lists:** Social: the friends list and group finder get the button (`frame`, `full`, `ours`). Navigation:
  the map (on its border) and the minimap (at its top right). Combat (new): *Spellbook*, *Talents*
  (`PlayerSpellsFrame`, `Blizzard_PlayerSpells`). Inventory (new): *Character* (`CharacterFrame`), *Bags*
  (`ContainerFrameCombinedBags`, `ContainerFrame1`, `OpenAllBags`/`CloseAllBags`). The spellbook, talents and
  character sheet are not opened by our code: chosen, the key that opens them is said (`Classic.Press`).
- Tests: `dev/tests/window.lua` (the list across windows, the secure button and its click, `ready`),
  `dev/tests/social.lua` (the friends list's button; the first layout deleted), `dev/tests/navigation.lua`
  (the dropdown's titles).

### Inventory: a tab for each window, the alts' window named Alts (Saneroki, 2026-10-20)
- **Icon tabs** (`Core/Board.lua`): a window whose spec has an `icon` (a texture or file ID with its `coords`, or
  `function(texture)` that draws it) gets a tab of its own after the layouts' tabs and `+`, the game's
  `MinimalTabTemplate` with the icon in place of words: selected and in full colour while the window is in the
  layout chosen, greyed while not; a click puts it in or takes it off (`board:Toggle`), its tooltip says the
  window's title. Every module's board can use it; Inventory's windows have their icons (`Inventory/Board.lua`,
  `Board.ICONS`): your portrait for the character, the game's own icons of its character sheet's tabs (the PvP one
  by your faction), Strength for the stats, a bag, a group for the alts.
- **Alts**: the window of the other characters is headed *Alts* (`Alts/Alts.lua`). Its items stay one scrolling
  list (the mouse wheel, or the thin bar at its right).
- Tests: `dev/tests/sheet.lua` (90 checks): the icon tabs, in the dropdown's order, lit for the first layout's
  windows, a click on and off; `dev/tests/inventory.lua`: the window headed *Alts*. The stand-in's
  `MinimalTabTemplate` keeps whether it is selected.

### Navigation: indoors without black (Saneroki, 2026-10-20)
- `Hybrid.lua`: indoors the game's minimap kept drawing its own ground: the indoor plan on black, over our map. Its
  ground stays off now, outdoors and in (`C_Minimap.SetDrawGroundTextures(false)` once, when taken), so our map and
  the game's dots show inside too. Our own indoor maps, from the game's indoor pictures with the black taken out,
  come next.
- Tests: `dev/tests/navigation.lua` (296 checks): indoors, the game's minimap without its own ground.

### Navigation: spirit healers in the game's spirit icon (Saneroki, 2026-10-20)
- `Pins.lua`: a spirit healer's pin (the NPC's service and the place) is the game's `poi-soulspiritghost`, the pale
  spirit, in place of the tombstone.

### Windows: one full screen at a time (Saneroki, 2026-10-20)
- `Core/Edge.lua`: a window that begins to fill the screen sends every other shown full window back to its zone
  (Social's full screen goes back when the map's opens). Check in `dev/tests/window.lua`; the check of Esc on a full
  window that closes now fills one window at a time.

### Inventory: pinned items, the player's own groups, junk marks in the bags (Saneroki, 2026-10-20)
- **The item's menu** (`Bags/Menus.lua`, `Bags.Clicked`): Alt and a right click on an item in our bags, which the
  game's item button does nothing with (`OnModifiedClick`), opens the game's menu (`MenuUtil.CreateContextMenu`) by a
  hook after the button's own click (`Cells.lua`: nothing written into the button): *Pinned*, *Junk* (an item with a
  price), *Put Into* (the groups items go in, its own ticked; *New Group*), *Take Out of* a group of the player's own.
- **A group's head** (`Bags.lua`): takes an item let go over it (`OnReceiveDrag`, or a left click with an item on
  the cursor; `ClearCursor` puts it back in its slot): into Pinned pinned, into Junk marked, into its own group
  taken out; lit while an item it takes is over it, its tooltip says what can be done. A right click opens its menu:
  *Rename*, *Move Up*/*Move Down* past the groups shown (`Bags.drawn`), *Join With* (a group of the game's but Junk),
  *Hide*, *Delete* (the player's own, asked first), *Show … by Itself* for each group joined into it, *New Group*.
  The dropdown *View* ends with *Groups* (each ticked while shown) and *New Group*.
- **The groups** (`Bags/Groups.lua`, no frames): the order shown (`Groups.list`, `rank`: Pinned and New first, the
  player's `ranks`, then the rest), names, hidden and joined groups, the player's own (`own1`, …, made at the top
  under New), an item's home (`Groups.Home`), pins, `PutInto`, `MarkJunk`. Kept for the account by item ID in
  `store.bags` (`pinned`, `put`, `groups`, `ranks`), checked when read (`Groups.Check`).
- **Contents** (`Bags/Contents.lua`): the group `pinned` first in `Contents.GROUPS`; a record's `natural` (the game's
  group), `home` (the player's or that), `junk` (in Junk with a price, not pinned) and `group` (Pinned, New, or its
  home's through joins: `Contents.Place`); sorting by the player's order; the search by the player's names;
  `Contents.Junk` (the junk, and whether it is just the game's).
- **The views** (`Bags/Layout.lua`): heads in the player's order with the player's names, a group's head carrying its
  key; hidden groups left out unless a search finds their items; an empty group of the player's own shows its head
  under the bags (not while searching, not in the compact view).
- **Junk sold** (`Bags/Foot.lua`): the button shows while there is junk to us; the bags read anew at the answer
  (`Bags.Carried`), the game's `C_MerchantFrame.SellAllJunkItems` where the junk is just the game's, else
  `C_Container.UseContainerItem` on each item, only while the vendor is there and the cursor is empty. The game's
  junk coin goes on what is junk to us (`UpdateJunkItem`).
- Tests: `dev/tests/bags.lua` (161 checks): pins, junk marked and unmarked (a grey item kept), own groups made,
  filled, taken out of, hidden (found by a search), renamed, joined and shown by themselves, moved past the shown
  ones, deleted, bad saved data cleaned; on the window the item's menu, the heads' menus, drops on a head, the
  dropdown's groups, and the player's junk sold item by item.

### Navigation: merchants in the game's anvil (Saneroki, 2026-10-20)
- `Pins.lua`: a merchant's pin is the game's anvil (`repair`, as the game's own minimap shows merchants), in place of
  the work order scroll; a vendor of food, reagents, poisons, ammunition, potions or trade goods keeps that kind's
  icon.

### Navigation: a click on a pin puts the map pin there (Saneroki, 2026-10-20)
- **The click** (`PinView.lua`, `Act`, `Drop`): a plain click on any pin, on the small map and the full one, puts the
  game's map pin where it stands (its own map and place; a gathered marker's first pin's), with the game's sound,
  as Ctrl and a click on the map does; a gathered marker zooms in too. On the full map a quest in the log also leads
  the game's arrow to it (`QuestLog.Focus`), a quest giver's quests show as previews (`QuestLog.Preview`); on the
  small map nothing else opens. Shift and a click on a pin that leads into another map (an entrance, a way, a dock
  with one destination) opens it, without a map pin. Every tooltip ends with what a click does (`Pins.TEXT.drop`,
  `open`, `preview`, `openMap`).
- **Tests:** `dev/tests/navigation.lua` (295 checks): the map pin at a pin's place, Shift and a click opening an
  entrance's map, on the small map a giver's click the map pin only, on the full one its quests in the log.

### Inventory: the character sheet's parts windows of their own, the sidebar (Saneroki, 2026-10-20)
- **Windows of their own** (Saneroki): the sheet's parts are each a window on the module's board, moved and sized
  there like the bags and the characters; the side tabs are gone. `Board.ORDER`: `character`, `stats`, `reputation`,
  `skills`, `pvp`, `currency`, `statistics`, `bags`, `alts`; the first layout holds `Board.FIRST` (character, stats,
  bags, alts), the others come from the dropdown *Windows*.
- **The character** (`Sheet/Sheet.lua`): the paper doll alone (the game's left pane, its strip and level line, the
  model, the slots), scaled to fit its window and never larger than the game's (`Sheet.Size`), its least
  `Sheet.LEAST` of it. `Sheet.LEFT` stays its width (the other characters' paper doll reads it).
- **The pages** (`Sheet/Page.lua`): reputation, skills, PvP and currency stand on the game's right pane at the right
  of their window (its art stretched to the window's height) with the list or the rank taking the rest; statistics
  on its list alone. `Page.Part` registers them, `Page.Least` their least; `List.INSET` and `List.LEAST` the lists'.
- **The stats and the sidebar** (`Sheet/Sidebar.lua`, the part `stats`): the game's right pane as a window, the
  game's sidebar tabs on its stone as our own buttons in its art (Stats, Equipment Manager, Titles, Pet only with a
  pet, the three centred without it, greyed with the game's reason), the tab chosen naming the head and alone
  listening. `Sheet/Stats.lua` draws a list per unit (the player's, the pet's), only lists shown, and hears the pet's
  events too.
- **Gear sets** (`Sheet/Gear.lua`): the game's cards, Equip (as `EquipmentManager_EquipSet`), Save (asked first), New
  Set (its name asked, the game's question mark as its icon), a right click to rename or delete.
- **Titles** (`Sheet/Titles.lua`): None, then the titles you know by name; a click wears one.
- Tests: `dev/tests/sheet.lua` (85 checks): the windows not on the board at first and not built, the paper doll
  fitting its window, the sidebar's tabs, titles, gear sets and the pet's tab, each of the game's tabs put on and
  taken off the board (deaf while off), back to the full screen. `dev/tests/inventory.lua`: the stats list found by
  its unit, the board's first layout.

### Data: batch 5, more quests, NPCs and places, unverified (Saneroki, 2026-10-20)
- **Saneroki's decision:** the map showed too few quest givers, vendors, trainers and herb and ore nodes, so a batch
  of its own takes in a wider record of them, every fact unverified, replaced entry by entry when the game or our
  own sightings say so. `assets/data/sources.toml`: `[5]`.
- **Taken in** (`dev/tools/data import --apply --take`): only what agrees with the master or fills what it lacks;
  nothing the master had changed (each "taken" line fills a field it lacked, or joins a list keeping its entries):
  Quests 421 new, 948 agreeing, 3848 filled (givers, objectives, sides, reputations, skills, tags); NPCs 6293 new,
  3124 agreeing, 57 filled; Objects 823 new; Spawns 1905 new, 2861 agreeing, 248 joined (herb and ore nodes, quest
  givers, services); CreatureSpawns 3954 new (its first entries); Drops 947 new, 2234 joined; Vendors 1106 new (its
  first entries: what vendors sell, items only). Names are the game's wherever it gives them; points to a tenth of
  a percent of their zone map. The check: all fit.
- **Packs:** *Data: Spawns* grows from 374 KB to 1.6 MB (most of it herb and ore points), *Data: World* from 1.2 to
  2 MB, *Data: Quests* from 0.9 to 1.2 MB; new *Data: Creature Spawns* (1.4 MB, on demand) and *Data: Market* (0.3 MB).
- **A hand fix** (`assets/data/Quests/fixes.jsonl`, new): quest 92516 is *Hippogryph Harassment*, as Forever's server
  sends it.

### Combat: its full screen on Core's board (Saneroki, 2026-10-20)
- **On Core's board** (`src/Combat/Board.lua`, `Window.lua`): the talents and the spellbook are two windows on
  `Core.Board` (kept in `store.board`), as Social's and Inventory's: layouts behind tabs, heads dragged, gaps
  shared, the X and the dropdown *Windows*. The first layout puts them side by side, as wide as what each holds
  wants. Combat's own panel layout (`Board.Layout`, `Board.Fit`, its plates and margins) is gone; the board is
  laid out once the full screen stands (`docked`), not as its motion begins.
- **Seated in the body:** the game's window (and the planner) stands in its panel's body by Core's seat, as the
  guild window does on Social's board; with its own panel off the layout, in the other one while that has nothing
  of its own, else in the middle of the whole board (never behind the full screen).
- **An empty window is a click away:** its body is the secure click on the game's micro menu button (was a small
  *Open* button), lit under the mouse, on UIParent over the body, out of a fight only; the words say the key, the
  fight, that the game shows talents and spellbook one at a time, and the level the game gives talents at. The
  game's window is still never opened by our code: its `OnShow` (the action bars' grids) and its spellbook's
  (which spell each entry casts, a protected call's arguments) would run tainted (`src/Combat/README.md`).
- Tests: `dev/tests/combat.lua` (60 checks).

### Nameplates: a module of its own (Saneroki, 2026-10-20)
- **The game's plates in our dress** (`src/Nameplates/`, the addon `SaneUI_Nameplates`; Saneroki: the nameplates
  are a module of their own, not Combat's): on each plate the game shows with a health bar, a frame of ours on the
  plate, laid over its health bar row (`Plate.lua`); the game's bar row, name, auras, raid marker and
  classification mark at alpha 0 under it (calls only, nothing of theirs written), at 1 again when the plate goes,
  when the game hides its health bar (name only, widgets only: hooks after its `OnShow`/`OnHide`) and when the
  module stands down. The rest of the game's plate stays: its size and style, stacking, cast bar, level box,
  threat glow, widgets and what clicks it. One dress per plate, kept; each listens to its own unit's events.
- **The bar** (`Bar.lua`): a rectangle with round corners and a one-pixel border, the fill and background masked
  at both ends by Core's new caps, the border by caps of its own size; health as the game gives it (a secret value
  in a fight, taken by the bar untouched); the game's colours (class colours by its nameplate CVars, grey when
  tapped by others, `UnitSelectionColor`); the border lit in the game's colours on your target and focus.
- **Combo points** (`Resource.lua`): along the bottom of your target's bar, a third of its height, one segment per
  point: one status bar from none to the most (the count may be secret), lines between the segments; rogues and
  druids in cat form, on a target you can attack; its corners the bar's own caps.
- **The name and the auras** (`Plate.lua`, `Auras.lua`): the name centred above the bar in the game's nameplate
  font; above it, in the game's own aura containers (`CustomAuraContainerTemplate`), your debuffs from the left
  (`HARMFUL|PLAYER`) and up to three buffs of a foe from the right (the game's own plates' buff filter), icons
  drawn once per frame the container makes, in the look of the game's nameplate auras; as many as fit over the bar.
- **Marks** (`Marks.lua`): the game's marks for a rare and a rare elite, then the raid marker (its index may be
  secret: given to `SetSpriteSheetCell` as it is), right of the bar or of the game's level box beside it.
- **Settings:** *Your debuffs*, *Buffs on foes*, *Combo points in your target's bar*.
- **Core:** `Shape.CAP_LEFT`, `CAP_RIGHT`: the masks `src/Core/Art/cap-left.blp` and `cap-right.blp` (64 × 256,
  DXT5 with mipmaps), a bar's ends, round with a radius of a quarter of its height; `dev/tools/shape-art` makes
  them next to the circles, and now takes the names of the masks to make.
- Tests: `dev/tests/nameplates.lua` (52 checks, in `dev/tests/run`).

### Inventory: an alt's gear on a paper doll (Saneroki, 2026-10-20)
- **The paper doll** (`src/Inventory/Alts/Items.lua`): the place Equipped of the window *Characters* drawn as the
  game's paper doll where Core keeps what the character wears slot by slot: the sheet's columns, sizes and slot
  frames (`Sheet/Slots.lua`, read only), eight down each side as far apart as the grid is wide (at most as on the
  sheet), the weapons' row in the middle below them; the ranged slot where the game shows one or something is in
  it, the ammo beside it where some is worn; an empty slot its own picture, its name as its tooltip. The bags worn
  in their slots follow as a row of the grid. Read only: the game's tooltip by item ID, a modified click links or
  tries on. While searching the doll shows only if something in it is found, whole, what is not found dimmed as
  the game's bags dim it. A character Core has not read slot by slot yet (it has not logged in since) keeps the
  list.
- **Core:** `Data.Worn(key)` (`src/Core/Data/Characters.lua`): what a character wears slot by slot, by the game's
  inventory slot IDs (the gear, the ammo where the client has its slot, the bags' slots), kept as a packed string
  `slots` beside the place `worn` (which stays as it was, for `Data.Count`; the ammo only in `slots`: it lies in
  the bags and is counted there), read with it, kept even empty (read, wearing nothing), checked on load.
  Documented in `Doc/guides/data.md` and Core's README.
- Tests: `dev/tests/tooltips.lua` (`Data.Worn`: read in steps, packed, the ammo, a wrong shape set aside,
  everything taken off), `dev/tests/inventory.lua` (the doll: slots and places, tooltips, clicks, the ammo, no
  ranged slot, reused rows, the bags worn, the search).

### Inventory: the bags (Saneroki, 2026-10-20)
- **Our own bags** (`src/Inventory/Bags/`, the part `bags` on the module's full screen): every slot of the
  backpack, the bags, the reagent bag and the keyring, and the bank's tabs while the bank is open, each item the
  game's own `ContainerFrameItemButtonTemplate` in a frame of ours that carries the bag's ID (the template asks
  its parent for the bag: nothing written into the button), so using, dragging, splitting, selling and depositing
  are the template's own code, in a fight too; drawn as the game's `ContainerFrameMixin:UpdateItems` draws, with
  the item level of gear in the top right corner. The game's own bags and bank are not touched.
- **Four views** (`Layout.lua`, plain numbers), chosen and kept by the dropdown *View* on the panel's head: *All*
  (every slot in the bags' order, a part per kind of bag), *Categories* (new items first, the game's auction
  categories in Camelot's order, junk last, a cell per kind of bag's free slots), *List* (name in its quality's
  colour, item level, count; the button's click reaching over the line) and *Compact*; sorted inside a group by
  quality, name or item level, then by place.
- **What they hold** (`Contents.lua`): a record per slot used again; class, item level, quest, new and junk; free
  slots by kind of bag (the game's bag family); the search over name, group and item level (Core's fuzzy search):
  dimmed by the game's own dimming in *All*, left out elsewhere.
- **Head and foot** (`Bags.lua`, `Foot.lua`): the game's *Clean Up Bags* (and *Clean Up Bank* on a bank part's
  head) and, at a vendor or a banker, *Sell All Junk Items* (the game's, asked first) or *Deposit All Reagents*;
  at the foot the bag bar (a bag's items lit by the game's mark, bags picked up and put on out of a fight), the
  free slots, the watched currencies, the gold with every character's from Core's data.
- **Events while shown only**, drawn a frame after a burst; a lock greys one slot. Buttons are made out of a fight;
  one first needed in a fight waits for its end.
- Tests: `dev/tests/bags.lua` (67 checks, in `dev/tests/run`): the containers, records, groups, free slots, orders,
  the layout, the game's buttons and their holders, the views and the dropdown, the search, events, new items,
  the clean-up, the bag bar, selling junk, the bank, a fight, deaf while hidden, standing down.
  `dev/tests/inventory.lua`'s stand-in part now has a key of its own (`later`).

### Inventory: the character sheet's PvP, currency and statistics tabs (Saneroki, 2026-10-20)
- **PvP** (`Sheet/PvP.lua`): the season's rank (the game's renown of its PvP rank faction): season, rank and title,
  the game's rank ring (a paused `Cooldown`, its badge and rank), points, the season's countdown (a ticker only while
  shown); the side pane with the season's progress, the week's cap, the next reward (`Side.Icon`) and its vendor.
- **Currency** (`Sheet/Currency.lua`): the game's currency list (headers, sub-headers, currencies with count, icon,
  backpack tick, greyed at none), the choice kept by name, Shift-link, the watch key to the backpack; the side pane
  with caps, description, transfer loss or account-wide, and the switches Unused and Show on Backpack. The transfer
  button (a panel of the game's window manager) is left out.
- **Statistics** (`Sheet/Statistics.lua`): the game's statistics as its tree, categories folded by a click (our own
  fold state), each value or `--`, a cut-short name in a tooltip.
- `Sheet/Side.lua`: icon rows, the switches (`Side.Check`, moved from the reputation tab), the foot's height, the
  switches' sounds. `Sheet/Sheet.lua`: a side tab's icon may be a function (PvP's by the faction).
- Tests: `dev/tests/sheet.lua` (71 checks): PvP's rank, ring, reward and countdown (only while shown); currency's
  rows, choice, watch key and folding; statistics' tree, folding and redraw.

### Inventory: the character sheet's skills tab (Saneroki, 2026-10-20)
- **Skills** (`Sheet/Skills.lua`): the game's Camelot skills tab, ours: the top-level skill lines of `C_SkillInfo`
  without the class's own, headers (fold), sub-headers (fold by a click, as the game's), skills set in under a
  sub-header, the game's blue bar with rank, bonus in green, defense's bonus; the game's selection; the side pane
  with name, rank bar, description and, for a weapon skill, the game's sums against a foe of your level and a raid
  boss (hit, crit, glancing blows) under the game's category bands.
- **Shared rows** (`Sheet/Rows.lua`): the reputation tab's row parts moved out, now used by both tabs (three looks,
  light, indent). `Sheet/Side.lua`: category bands and spacers, as the game's side pane has them.
- Tests: `dev/tests/sheet.lua` (50 checks): the skills listed and left out, the first choice, bar and bonus, the
  indents, folding a sub-header, choosing, a trade's side without weapon lines, a weapon's boss line, deaf while
  hidden.

### Inventory: the other characters' window (Saneroki, 2026-10-20)
- **Characters** (`src/Inventory/Alts/`, the part `alts` on the module's full screen): what the account's characters
  have, as last seen, read only from Core's data framework. A roster down the left (`Roster.lua`: the one logged in
  first, the others by name, the account's bank last; class icon and colour, whole gold; the gold of them all under
  it; the chosen one lit as the game's options list lights a line), the chosen one's head (name, gold, level line,
  the day last seen) and its places in one scrolling list (`Items.lua`): Bags and Bank as grids of the game's item
  buttons in the order Core keeps them, Equipped as a list; the bank's day, or *Not seen yet*. Read only: the game's
  tooltips, a modified click links or tries on. The logic without frames in `Snapshot.lua`.
- **The search** across every character: an item's ID, or its name (whole, a piece, first letters; not letters
  spread out); the roster says how many each has, one without any dimmed; if the chosen one has none, the first that
  has is shown. An item's name the game does not know yet is asked for once, and its answer draws anew.
- **Core:** `Data.Items(key, place)` (`src/Core/Data/Characters.lua`): what a character keeps in a place (or the
  account's bank) item by item in the order kept, made once per change. Documented in `Doc/guides/data.md` and
  Core's README.
- Tests: `dev/tests/inventory.lua` (the window, the roster, the items, the search, reused rows, deaf while hidden;
  the failing part's test now fails at its showing too, as the alts' panel is built before it),
  `dev/tests/tooltips.lua` (`Data.Items`).

### Inventory: the character sheet's side tabs and reputation (Saneroki, 2026-10-20)
- **Side tabs** (`Sheet/Sheet.lua`): the game's `LargeSideTabButtonTemplate` right of the sheet, the Character tab with
  the portrait, each further tab a table its file registers (`Sheet.Tab`), built when first chosen and listening to
  the game only while shown; the head says the tab's title; the panel's least counts the tabs' width. The Character
  tab is the paper doll and stats as before, now as a tab.
- **Shared by the tabs:** a list in the game's look (`Sheet/List.lua`) and the side pane as the game lays out its
  `CharacterFrameSidePaneTemplate` (`Sheet/Side.lua`; the game's template registers into its own sheet, so not used).
- **Reputation** (`Sheet/Reputation.lua`): the factions of `C_Reputation` with the game's headers (fold by a click),
  headers with a standing (fold button), factions with its coloured bar (standing word and colour, friendships,
  renown, progress under the mouse) and its light (chosen, under the mouse, at war); the game's selection; the side
  pane with name, standing, description, bar and the switches At War, Move to Inactive, Show as Experience Bar. Our
  own rows: the game's are wired to its sheet (event registry, side pane).
- `Board.lua`: the first layout reads a least given as a function.
- Tests: `dev/tests/sheet.lua` (38 checks), in `dev/tests/run`: the side tabs, built when chosen, the left button
  only, the reputation list's looks and heights, the progress, folding, choosing, the switches, the empty side, the
  game's events while shown only, back and forth. `dev/tests/inventory.lua`: the side tab's stand-in, the width.

### Inventory: the character sheet's stats (Saneroki, 2026-10-20)
- **The stats** (`Sheet/Stats.lua`) in the sheet's right pane, as the game's Camelot sheet lists them: the game's
  `CharacterStatsPaneScrollBoxTemplate` under the stone, the game's rows (`CharacterStatFrame…ScrollBox…ElementTemplate`)
  filled by the game's functions for each stat (`PAPERDOLL_STATINFO`); the list put together by our code as the game's
  `UpdateStats` does it (categories, `primary`, `roles`, `showFunc`, `hideAt`; then the resistances with the game's
  atlases and tooltips), because the game's own builder borrows its sheet's frame pool.
- **Secret stats:** under a restriction (`Core.Restricted`) the stats are secret to addon code (the API's
  `SecretWhenUnitStatsRestricted`; the player's health always), and the game's functions do sums on them: the list is
  not drawn then and is drawn once the restriction ends (`PLAYER_REGEN_ENABLED`, `ADDON_RESTRICTION_STATE_CHANGED`).
- **Drawn** when shown and a frame after the game's stat events (`Core.Later`), only while shown.
- Tests: `dev/tests/inventory.lua` (44 checks): the list's elements, the rows' templates, a change drawn once, the
  wait under a fight, deaf while hidden.

### Inventory: the character sheet's paper doll (Saneroki, 2026-10-20)
- **Our own character sheet** (`Sheet/`, the part `character` on the module's full screen): the game's Camelot
  character window rebuilt from Blizzard's code at its size (398 + 233 by 464 under the panel's head), on the game's
  art: the left pane with its top strip and the level line (`PaperDollFrame_SetLevel`), the right pane's stat
  background and stone (the stats come next); the panel's head is the character's name and title (`UnitPVPName`).
- **Slots** (`Sheet/Slots.lua`): the game's `ItemButton` on its slot frame in the game's places (eight a side, the
  weapons at the bottom, the ranged slot where the game shows one, the ammo slot for a character that uses ammo),
  drawn as the game draws them (icon, count, quality, red while broken, grey while locked, the slot's picture when
  empty); a click or drag `PickupInventoryItem`, a modified click `HandleModifiedItemClick`, the game's tooltip.
  A right click calls nothing: `UseInventoryItem` is the game's own.
- **Model** (`Sheet/Model.lua`): the game's model scene for the character sheet
  (`ModelSceneUtil.SetUpCharacterSheetScene`), its turn and zoom buttons, the race's background (greyed) under the
  overlay; an item let go over it is put on (`AutoEquipCursorItem`).
- **Events only while shown**, every value through `Core.Plain`/`Core.Ask`, every function of the game's checked.
- Tests: `dev/tests/inventory.lua` (36 checks): built when first shown, nineteen slots and the ammo slot, the
  weapons' row, drawing, the level line, the model, the game's events (put on, locked, broken, the model), clicks,
  drag, modified click, tooltip, ammo, deaf while hidden.

### Inventory: its own window and full screen in the corner (Saneroki, 2026-10-20)
- **Our own windows** (Saneroki): the game's character sheet cannot be opened by our code (*Inventory: a new
  module*, below), so the module gets windows of its own: the character sheet, the bags and the other characters'
  snapshots, on its full screen. The plan: `Doc/ideas/Inventory.md`.
- **The window** (`Window.lua`): a `Core.Window` of the kind `screen`, docked in the bottom right corner at first,
  empty and see-through while small; Core's corner square (`Edge.lua`) fills the screen with it, pushed again or
  Esc it goes back. Settings: Core's *Expand window* and *Window corners* (`Inventory.lua`).
- **The board** (`Board.lua`): Core's board with the module's windows in the order `character`, `bags`, `alts`;
  each a part in files of its own that registers itself (`Board.Part`), every step of a part `ns.Safe`. The first
  layout: side by side, each as wide as its least width (Core's pads counted), the last taking the rest.
- **The corner of the game's bags is gone** (`Corner.lua` removed): the window's own corner takes its place.
- Tests: `dev/tests/inventory.lua` (16 checks): the window and its corner, parts registered before and after the
  full screen, the search, a part that fails, standing down.

### Navigation: the game's minimap square again, the player's arrow and dots back (Saneroki, 2026-10-20)
- **Square** (`Hybrid.lua`): in a small window that is not square (sized by its corner) the game's minimap was cut by
  a band of a texture of our own as its mask, and drew nothing: no dots, no arrow of its own, and ours hidden while
  it counted as shown. It is now always as large as the window's shorter side (`Hybrid.Side`), in its middle, cut by
  the game's own white square (`Hybrid.MASK`); the map at its scale. `Hybrid.Mask`, `Hybrid.BANDS`, `Hybrid.MASKS`,
  the 62 masks (`Art/Masks/`) and `dev/tools/minimap-masks` are gone.
- **Tests:** `dev/tests/navigation.lua` (290 checks): a wide window's minimap the square of its shorter side, in its
  middle, the game's square its mask; a thin one too.

### Navigation: every pin its own icon, the quests split, previews in the quest log (Saneroki, 2026-10-20)
- **Icons** (`Pins.lua`, `PinView.lua`): every pin in its own icon from the game's map icons (ObjectIconsAtlas): no
  quest discs, no numbers. `Pins.ICONS` (a quest in the log: `questturnin` when ready, `target` in progress; an
  offer `questnormal`; a grey quest `trivialquests`, without colour; done `islands-questbangdisable`; rares
  `dungeonskull`, the game's own rares too; treasures `vignetteloot`); services by their first service with an
  icon (`SERVICES`: repair, innkeeper, banker, auction house, stable master, battlemaster, weapon master, guild,
  spirit healer; a trainer the class book `class` where its title names one of the game's classes,
  `LOCALIZED_CLASS_NAMES_*`, else the profession scroll; a vendor by its goods, `GOODS`, else `poi-workorders`);
  places and ways (`PLACES`, `WAYS`: the boat `flightmasterferry`, the zeppelin `vehicle-air-horde`, the tram, the
  lift, portals, meeting stones `teleportationnetwork-32x32`, books `lorewalking-map-icon`). A gathered marker:
  its first pin's icon, no number (the pin buttons have no disc or count any more). The focused quest's glow stays.
- **The filter** (`Navigation.lua`, `TopBar.lua`): each kind its `icon`, shown before its words (`ns.KindLabel`, the
  setting's list too). The quests split: `log` (*Quests in your log*, the game's), `quest` (*Quest offers*), `low`
  (*Low-level quests*), `later` (*Quests for later*), `done`, each with its checkbox and size; the settings' version
  2 takes a saved filter over (`log` as `quest` was, `low` and `later` on). The quest areas' slider is their opacity
  (`ns.PIN_OPACITY`, 10 to 100 %; `ns.PinRange`; `Areas.lua` sets it on its layer).
- **Where a quest stands** (`Pins.Standing`): offered, low (the game's quest colour grey: its level more than
  `GetQuestGreenRange` below yours), later (with why: the level it asks, a quest first, one of some quests first),
  log, done, never. An NPC's pin: an offer wins, then a rare, then its service, then grey (`later` over `low`), then
  done; its tooltip lists its title (`Data.Map` hands NPCs' `title` on; *Warrior Trainer* in place of *Trainer*), its
  services, and its offered and grey quests with their levels and why (lines may carry their colour).
- **Previews** (`QuestLog.lua`): a click on a quest giver's pin (`QuestLog.Preview`): its quests on top of the log
  under *Not in your log*, grey, each with the game's red X (`xmarksthespot`) that takes it out (`Unpreview`); the
  map full screen with the log at the giver's place. Chosen, the words below from Core's data: why it is not for you
  yet, its level, who gives and takes it, its objectives in the log's words (the game's `QUEST_MONSTERS_KILLED`,
  `QUEST_ITEMS_NEEDED`, `QUEST_OBJECTS_FOUND`, the names from NPCs, Objects and the game's items), its rewards; no
  buttons. Kept until the next `/reload`.
- **Tests:** `dev/tests/navigation.lua` (292 checks; the data with a quest for later, a warrior trainer, quest
  levels): the icons, the grey quest and why, the trainer's title and book, a quest too low, the filter's icons and
  quest rows, the areas' opacity, the preview and its red X, the settings taken over.

### Combat: quest marks beside nameplates (Saneroki, 2026-10-20)
- **`QuestMarks.lua`** (new, in the TOC): a creature that belongs to a quest in your log shows a mark left of its
  nameplate while an objective of it is still to do, as the game says it: `C_QuestLog.UnitIsRelatedToActiveQuest`,
  then the tooltip data's `QuestObjective` lines (`C_TooltipInfo.GetUnit`; the first neither `completed` nor full).
  The game's sword cursor where the objective names the creature (to kill), its sack (to loot) otherwise, the open
  count left of it. A frame of ours per plate (`C_NamePlate.GetNamePlateForUnit`: none for forbidden plates, none
  for players), anchored left of the plate's health bar (read with `rawget`); looked at again on the quest log's
  events once a frame; a secret value in a fight leaves it as it was. Hidden at `GiveBack`.
- **Setting** *Quest marks on nameplates* (`questMarks`, on), under the header *Nameplates* (`Combat.lua`).
- **Tests:** `dev/tests/combat.lua` (49 checks): sword and count, sack, gone when done or unrelated, the plate
  removed, none for a player, the plate handed out again, the setting.

### Navigation: a size per kind of pin, quests to take see-through, done quests on demand (Saneroki, 2026-10-20)
- **Sizes** (`TopBar.lua`, `Navigation.lua`, `PinView.lua`, `Marks.lua`, `Route.lua`): each row of the pin filter
  that has a size carries the game's slider at its right (`MinimalSliderWithSteppersTemplate`, lent to the row by
  the game's menu, `AttachTemplate`, while it is open; `Sizer` gives the row's size), 50 to 200 % in steps of 10
  (`ns.PIN_SIZES`). Kept in the setting `pinSizes` (`[kind] = percent`, 100 not kept; no control on the options
  page, so it goes with the profile). `ns.PinPercent`, `ns.PinScale`; pins drawn at their kind's scale (a gathered
  marker at its first pin's), the party's marks at *Party and raid*'s, the route's lines at *Route to the map
  pin*'s. The game's minimap's dots have none (the game draws them).
- **Quests to take see-through** (`PinView.OFFERED`, 0.55): a giver of a quest this character can take but has
  not, so the quests in its log stand out.
- **Done quests** (`Pins.lua`, the kind `done`, off at first): an NPC whose quests of Core's data this character has
  all done (and that has no service) is a grey pin with the quests it did in its tooltip.
- **Tests:** `dev/tests/navigation.lua` (281 checks; the data now with a pack Quests: a giver of a quest to take
  and one of a quest done): the see-through giver, the done one shown only with its kind on, the slider row and a
  size kept in its steps and drawn. `dev/tests/wowstub.lua`: a menu checkbox takes initializers.

### Navigation: the route and the minimap's dots in the pin filter, the dots on the full map too (Saneroki, 2026-10-20)
- **Two kinds first in the pin filter** (`Navigation.lua`, `ns.KINDS`): *Route to the map pin* (`route`, the setting
  of that name gone: `Planner.Update` asks `Pins.Shows("route")`, and the filter's change plans anew only when that
  kind changed) and *Minimap dots* (`minimap`), both on at first, in both views. The settings' version 1
  (`Upgrade`): a saved filter gets both, the route as the old switch had it.
- **The game's minimap on the full map** (`Hybrid.lua`, `Canvas.lua`): `Hybrid.Place` for the full camera is `Wide`:
  square, at its widest step whose square at the map's zoom takes at most `Hybrid.ROOM` (0.5) of the canvas'
  shorter side, none at a zoom too close for its narrowest; `Hybrid.Follow` keeps it on the player (the canvas'
  `Here`, at each tracker step and after each layout), shown while wholly inside the canvas (`Canvas.Inside`, and
  `Hybrid.Keep` when the map moves). Its size, layer, step and ground set in one place (`Set`); in the small view
  it is anchored to the canvas' middle again. No ping on the full map. Off in both views with *Minimap dots*.
- **Tests:** `dev/tests/navigation.lua` (274 checks): the full map's minimap at the widest step that fits, on the
  player, off and on by the filter, no ping there; the route off and planned anew by the filter; older settings
  taken over.

### Navigation: what stands on the map keeps inside the window; the small window sized by its corner (Saneroki, 2026-10-20)
- **Inside the window** (`Canvas.lua`, `Route.lua`, `PinView.lua`, `Marks.lua`): in the small window the golden
  line and the pins reached past its edge over the screen (they are laid out past the view, `Canvas.MARGIN`, so a
  drag shows no gap; the game cut the map's textures at the canvas' edge, but not those lines and buttons).
  `Canvas.edge` is the canvas' rectangle in the holder's units, set at each layout (`Bounds`), at each step of the
  window's way (`Step`, the holder scaled) and when the holder has moved `Canvas.REFIT` (0.5) units since
  (`Moved`); then `Keep` has each layer fit itself. The route keeps its segments near the view (`parts`) and cuts
  each at the edge (`Route.Fit`: the share of it inside, along each axis, `Between`; the lines' thickness inside;
  the art keeps its place on the way, `SetTexCoord` from the share), placing anew only a segment whose cut
  changed, so a step of following touches those at the edge alone. Pins (`PinView.Fit`, each button's place and
  reach, the focused quest's glow included) and marks (`Marks.Fit`, `Put`: the arrow, the map pin, the party)
  show only while wholly inside (`Canvas.Inside`), so none is seen or clicked past the window either.
- **The corner sizes the small window** (Core `Window.lua`, Navigation `Window.lua`, `Canvas.lua`): Core's window
  option `grip = "hover"` keeps a sizable window's grip outside Edit Mode too, while it rests in its zone: unseen
  until the mouse is on the window (`window:Hover(on)`, its module's word) or on the grip, or while it sizes;
  hidden while its `usable()` says no, and while it is away (Edge hides it as before). Sizing there is kept and
  stays docked as in Edit Mode (`Sized`). Navigation's window has it (`usable`: not while it rests out of sight
  for the game's own minimap); the canvas tells it the mouse is on the map (`Entered`, and its look `Over`,
  which now runs on while a button is held, so it also sees the mouse leave after a drag).
- **Tests:** `dev/tests/navigation.lua` (267 checks): a segment past the canvas' edge cut there and the cut
  following a move; pins and marks shown only while inside (the isle's zeppelin tower laid out past the bottom
  edge is out of sight there); the grip seen with the mouse on the map and not off it. `dev/tests/window.lua`
  (366): the hover grip unseen at rest, seen on hover and on the grip, sizing outside Edit Mode kept docked, gone
  while the module says no. **Guide:** `Doc/guides/windows.md`, after the states.

### Navigation: the golden line drawn again (Saneroki, 2026-10-20)
- **The pulse from XML** (`Route.xml`, `Route.lua`): the first segment of a route stopped the module (the map
  window closed, the game's own minimap and map back), because the glint's pulse was a `TextureCoordTranslation`
  made in Lua, and this client gives one made there no `SetOffset`. The pulse is now the virtual animation group
  `SaneUINavigationGlintTemplate` (one repeat in 1.2 seconds, towards the way's next point), each glint's group
  made from it (`CreateAnimationGroup(nil, template)`), as the game's own dependency lines define theirs in XML.
  Where the game has not read the file yet (`C_XMLUtil.GetTemplateInfo` knows no such template) the glint stands
  still and the line is drawn all the same.
- **Tests** (`dev/tests/wowstub.lua`, `dev/tests/navigation.lua`, 260 checks): the stub notes the virtual
  templates of the XML files it loads and answers `C_XMLUtil.GetTemplateInfo` from them; an animation group asks
  for a template that is there, and a `TextureCoordTranslation` made in Lua has no `SetOffset`, as in the game.
  New check: the glint pulses by the template.
- **Guide** (`Doc/guides/gui-development.md`, *Motion*): a `TextureCoordTranslation` comes from an XML template.

### Social: Recent Allies no longer asks the game for them (Saneroki, 2026-10-20)
- **`Contacts/Allies.lua`**: the tab asked for the recent allies when shown (`C_RecentAllies.TryRequestRecentAlliesData`),
  which the game blocks for an addon (the error log: *the game blocked TryRequestRecentAlliesData()*, 4x). It asks
  no more: it shows them once the game has read them (`IsRecentAllyDataReady`, followed by `RECENT_ALLIES_DATA_READY`
  and `RECENT_ALLIES_CACHE_UPDATE` while shown), and until then says that the game's own friends list reads them on
  its Recent Allies tab (`TEXT.alliesWaiting`).
- Tests: `dev/tests/social.lua` (561 checks): not asked for, the words while waiting, the allies once ready.

### Social: every group you join a conversation of its own (Saneroki, 2026-10-20)
- **`Talks.lua`**: a group's chat goes to the conversation of the very group you are in (`G:<partyGUID>`, from
  `GROUP_JOINED`; a group you were in already when first asked about, by its category and the time), not to one
  per kind of group; it is named by the others in it (`members`, from the raid's roster or the party's units,
  `Talks.NAMES` of them and how many more), its kind follows the group (a party become a raid), and it ends when
  you leave (`GROUP_LEFT`: `ended`, no more to write in, `TEXT.groupOver`). The current ones per category are
  `Talks.current`, kept over a `/reload` (`char.talkGroups`; `Talks.Restore(saved, current)`). `Talks.Group(kind)`
  is `Talks.Groups()`. Saved groups keep `category`, `members`, `started`, `ended`.
- Tests: `dev/tests/social.lua` (561 checks): a party joined, its name, its chat, become a raid, left, the next
  one apart, saved and restored with its members.

### Social: chat views, the chat's own window, rows lit for messages not seen (Saneroki, 2026-10-20)
- **Chat views** (`Feed.lua` anew): as many as you make, each with a name and its own ticks (`shows`), kept in
  `store.views` (account-wide, as the layouts that hold them); at first one, the second chat, with the ticks the
  second chat had (`Feed.FIRST`). A view stands wherever you put it: a row of the conversations' list (chosen, in
  the page's own list of a view, `Feed.New(nil, page, TALK_HEAD)`, no longer in the chat's frame over its line)
  and a window of the layouts (`view:<id>`, a list in its body, its *Chats* on its head), in as many as you like;
  each place is a list of its own (`Feed.New`), all fed by `Feed.Added`. The switch *Second chat* (`boardFeed`)
  and the setting `split` are gone; `Channels.Split`, `FlipSplit`, `Feed.Room`, `Feed.Fit` too.
- **The conversations** (`Conversations.lua`): *New chat view* above *Whisper* and *Remove* (`Feed.Make`, chosen,
  showing nothing until its chats are ticked); a right click on a view renames it (its window's head too:
  `Board.Retitle`) or removes it (confirmed; `Feed.Remove`, out of every layout: `Board.Forget`); *Remove* removes
  a chosen view too (`Removable`). A view or a conversation chosen while the game's line is open closes it, unless
  the chat has its own window; the game's line opened while a view is chosen chooses the chat.
- **The chat's own window** (`Board.lua`, `chat`): in a layout that has it the chat stands in its body with its
  line (`board.own`, `Window`'s `Shows`), and the conversations list no row for it.
- **Not seen yet, lit**: a row is lit with the game's chat tabs' `ChatFrameTab-NewMessage` (additive, tinted with
  its chat colour, steady) and counts (`99+`): a conversation's waiting to be read, a view's that came while none of
  its lists was on show (`view.unread`, cleared when one is shown), the chat's that came while it stood out of sight
  on the full screen (`Window.Unread`, cleared when it is in sight).
- Tests: `dev/tests/social.lua` (558 checks): a view chosen in its own list, its ticks, rows lit and cleared (the
  chat's and a view's), *New chat view*, renaming and removing one, the chat's own window, a view's window on the
  board.

### Core and Social: the full screen's windows on Core's board, layouts behind tabs (Saneroki, 2026-10-20)
- **Core's board** (`src/Core/Board.lua`, new in Core's TOC after `Seat.lua`; `Core.Board.New(window, options)`):
  a module's full screen of windows that share it and never overlap, as the player arranges them. A layout is a
  tree of splits (`{ key }`, `{ split = "x"/"y", parts, shares }`, `Board.Lay` gives whole-pixel rects, `PAD` 12
  between and round). The gap between two neighbours is a strip with the game's sizing cursor: held, only a line
  follows; let go, `Board.Move` shares their room anew (neither under its `least`; through a layout that left a
  window out, written back to the kept split). A window's head is dragged: see-through, a gold shape where it would
  go; let go near a side of another, `Board.Beside` (a split the same way takes it in, `Tidy`), in its middle
  `Board.Swap`, near a side of the screen a strip of `STRIP` along it. The X takes it off (`Board.Without`); the
  dropdown *Windows* (left of *Classic windows*; `Window.Refresh` now ends the search box left of it) ticks those
  in the layout and adds one beside the largest. Layouts behind tabs after the title (`MinimalTabTemplate`, out of
  sight under the search box): the first is the module's `default` until changed, `+` an empty one, a right
  click renames, resets the first, deletes another (confirmed). A window with nothing to show now (`present`
  false) is left out of the laying out (`Board.Present`), its share kept. Kept in `store[key]`
  (`{ chosen, tabs = { { name, tree } } }`, account-wide as places are). One watcher runs only while a line or a
  head is held; the layout is laid out once when let go. Panels: Core's plate, head (`HEAD` 30) with title and X,
  a line, the body; the module's part built in it (`build`, `show`, `size`, `search`).
- **Social on it** (`Board.lua`, `Window.lua`, `Guild.lua`, `Layout.lua`, `Social.lua`, `Talks.lua`): its windows
  `talks`, `friends`, `guild`; the first layout made from `Layout.Board`'s rooms (`Default`, the guild window's
  room framed with its panel's head and edges); `Board.Show` returns the chat's place in the conversations, none
  in a layout without them (the chat out of sight: `Window`'s `Shows`). The guild window is held in its panel's
  body at the scale that fits (at most its own, at the body's top in its middle), `Guild.Least` its panel's least;
  opened again by the player while the full screen stands, it is back in its panel (an `OnShow` hook). The
  switches *Conversations* (`boardTalks`), *Guild window* (`boardGuild`) and *Friends list* (`boardFriends`) are
  gone: a layout holds a window or not; `talkSize` heads the section *Full screen*, *Group finder* has no parent.
  `Layout.HEADER` and `Layout.PAD` are the board's.
- **Docs:** `Doc/guides/windows.md` (section 3's table, section 7 *The board*, section 8 item 5 built), Core's and
  Social's READMEs, `Doc/agent/core.md`, `Doc/agent/social.md`.
- Tests: `dev/tests/social.lua` (550 checks): the layout functions (`Lay`, `Beside`, `Without`, `Swap`, `Move`,
  `Present` and its writing back), the tabs and `+`, the dropdown, a line dragged, a head dragged, the X, renaming
  and deleting a tab, the first's *Reset*; the guild window held in its panel, reopened, a layout without it.

### Social: words picked out of the messages on the full screen, copied with Ctrl+C (Saneroki, 2026-10-20)
- **Picking** (`Select.lua`, new in Social's TOC after `Bubble.lua`): a press on a bubble's words and a drag
  over as many messages as wished picks them, in the chat (its list takes the mouse only while the window
  stands full: `Select.Allow` from `Window`'s `Filled`, off at `Hide`), the second chat and a conversation
  (`Select.Attach` in `Feed`'s and `Conversations`' builds). The letter under the mouse is the game's text's
  answer (`FindCharacterIndexAtCoordinate`, the cursor over the list's effective scale, as the game's
  `ScrollingMessageFrame` asks it), beside a bubble the nearest line by height. The two ends are
  `{ message, caret }` with each message's place in its list when the press came, so a message that comes
  later is never picked; `Select.Span(entry)` gives a message's picked part.
- **Lit** (`Bubble.lua`): `Bubble.Init` asks `Select.Span` and `Bubble.Mark` lights it (pieces from
  `CalculateScreenAreaFromCharacterSpan`, between the bubble's fill and its text, in the game's grey for picked
  text, `Layout.PICKED`), so rows handed to other messages by a scroll stay right; `Bubble.Text(row)` gives the
  text to ask. The days' pills of a conversation are marked `pill` and skipped.
- **Copied**: the game's `CopyToClipboard` is for its secure code only, so the words wait in a hidden `EditBox`
  of ours, highlighted and focused; Ctrl+C (Cmd+C) copies them as any edit box does, and a frame later the
  keyboard goes back (the words stay lit). The words as they read (`Select.Words`: no colours, a link's code,
  icons; `||` a bar, `|n` a new line, UTF-8 letters whole); several messages a line each after the speaker's
  name (`Bubble.Speaker`, yours `Core.FullName("player")`). Any other key, Esc, focus taken elsewhere, the next
  press, another row of the conversations chosen or the full screen going lets them go. A line in use loses the
  keyboard meanwhile; the game closes it only while it is empty (the README's *Taint* says so).
- Tests: `dev/tests/social.lua` (526 checks): the chat's list takes the mouse only while full, a drag lit as it
  follows, the words waiting highlighted with the speakers' names, Ctrl+C and the keyboard given back, a press
  without a drag, one message without its colour codes, another key, another row chosen, `Select.Words`.

### Social: the conversations' list dragged to its width, no fading on the full screen (Saneroki, 2026-10-20)
- **The list's width** (`Conversations.lua`, `Layout.lua`, `Board.lua`): the line between the conversations' list
  and the one chosen is dragged by a strip over it (`Layout.TALK_GRIP`, 8 wide, above the list and the one
  chosen), the game's sizing cursor on it (`UI_RESIZE_CURSOR`, as Core's grip) and the line bright while the mouse
  is on it or holds it. Held, only the line follows the mouse; let go, the width is kept (`store.talkList`) and the
  full screen is laid out anew once (`Window.Reboard`), so the messages beside it are measured once for their new
  width, not at every step. `Layout.TalkList(wished, panelWidth)` keeps it between `TALK_LIST_LEAST` (150) and
  what leaves the one chosen `TALK_PAGE` (269, so a panel at `TALKS_MIN` has the list at `TALK_LIST`, 190, as
  before); `Layout.Board` takes it as `want.list` for the chat's frame, `Conversations.Size` for the list, its
  buttons, the line and the one chosen. The full screen gone while the line is held lets it go (`OnHide`).
- **No fading while full** (`Window.lua`): a message of the chat faded on the full screen once the mouse went
  over something not ours (the guild window) and the reveal ended. `FadeAfter` now gives none while the window
  fills the screen (`edge.full`), and `Filled(false)` tells every message anew on the way back.
- Tests: `dev/tests/social.lua` (512 checks): the list's bounds and the board with a dragged width; the line
  dragged, held and let go, at its least, let go when the full screen goes, the cursor; no fading while full
  with the mouse away.

### Navigation: Zephras Isle's terrain and walking data (Saneroki, 2026-10-20)
- **The data** (Core's sets *Tiles* and *Walking*, from the game's own files of the isle's map, 2991, build
  70245): the isle's 72 tiles (its WDT's minimap textures), and its walking data, 26 tiles with ground. Both the
  game's, new keys only (`dev/tools/data import`: 72 and 26 new). The schemas say so (the instances 0, 1 and
  2991); *Walking*'s now describes what it holds (a tile, its rectangles and openings, the tiles around it).
- **`dev/tools/terrain-art`:** `--maps <instances>` draws only those maps and leaves the others' textures,
  outlines and lines of `Outlines.lua` as they are. A zone straight on the world map is outlined as a continent's
  zone. The open sky around an isle that floats is cut away as the sea is (`sky`, `blank`): a sample the game's
  minimap texture leaves pure black is sky when black samples join it to a place of the grid with no tile (the
  terrain's holes and the cliffs under the isle's rim; a dark place within the land and the zeppelins' tower
  over the void stay; nothing on the continents, where no black reaches their grid's edge). Made with
  `--maps 2991`: `Art/Terrain/2991-*.blp` and `Art/Sketches/2991-*.blp` (four blocks each), `Art/Zones/2521.blp`,
  `Outlines.lua`'s line for 2991, from the Forever beta client's minimap textures (the newer build, 70450; the
  isle's tiles and file IDs are the same as live's), as the continents' were; theirs are not made again.
- **`dev/tools/walk-data`:** `--maps <instances>` makes only those maps' tiles; regions are numbered in the order of
  the tiles' keys (before: the order the processes finished in), and hold within one map. Made with `--maps 2991`;
  both zeppelins' docks lie by the island's own region.
- **Drawn** (`Terrain.lua`, `Art.lua`, `Painted.lua`): the overview, the stitched map, the maps under it and the
  painted map loop over every plane (`Coords.Planes`), so *Scrying* and *Atlas* draw the isle's terrain (its tiles
  up close, `view.continent` 2991) and *Parchment* the isle's own map under its stitched map, its frame faded off.
  Art's maps under the stitched map (`Under`) take pool keys of their own (`Draw`'s `under`), so the isle's map
  drawn under it is not taken over by the same map drawn cut to its outline at the zone's level.
- Tests: an isle tile in the test pack; *Scrying* on the isle (its tile cut by its block's overview, the overview),
  *Parchment* there (the world's map, the isle's own framed, its stitched map, its map cut to its outline over
  them) (`dev/tests/navigation.lua`); regions numbered by the keys' order, the open sky against a dark place
  within the land (`dev/tests/walk.py`).

### Social: the guild window held by Core's seat (Saneroki, 2026-10-20)
- **`Guild.lua` on `Core.Seat`**: the holding is the seat's, as for Combat's panels (one seat per window, label
  `Social: guild window`): lending its scale, layer and points, placing it against `UIParent` at its room's screen
  place, the hooks after its `SetPoint`, `SetScale`, `OnHide` and `OnSizeChanged`, and giving it back. Gone from
  Guild: its own `Core.Lend` per frame, `Place`, `Moved`, `Closed`, `Sized`, `Follow`, `held`, `slot`, `placing`,
  `base`. What stays its own: which window (the generic finding, `store.guildWindow`), opening it once per full
  screen out of a fight, closing what it opened as Esc does, `dismissed` (the seat's `gone`, out of a fight) and
  after the fight, and its size for the layout (`Measure`: `seat:Size()` in the full screen's units).
- **Its room exactly its size**: a seat fits a window into its room, centred and as large as fits. The layout's
  room (`Layout.Board`) is in whole units, so the window would come out up to half a unit smaller than the
  layout's scale and centred in it. `Guild.Hold` hands the seat its own size at the layout's scale (`rect[5]`), at
  the top right of the layout's room: it stands exactly at that scale, its top right corner at the room's. Seat is
  unchanged; Combat's use of it too.
- **Closed when it has no room**: a window opened for the full screen that the layout leaves no room (a small
  screen, the switch turned off) is closed as Esc closes it, also when it was never seated (before, only once it
  had been held).
- **In a fight**: the seat does not seat a protected window in a fight (before, Guild counted it as held while its
  lend refused); the full screen seats it once the fight is over (`PLAYER_REGEN_ENABLED`), as before.
- Tests: `dev/tests/social.lua` (502 checks): the window made smaller where the screen lacks room stands at the
  layout's scale with its top right corner at its room's; closed, its scale and layer are back too.

### Combat: its window at the bottom middle, your talents and spellbook on its full screen (Saneroki, 2026-10-20)
- **The known addons** (Saneroki, 2026-10-20, the one exception to *No other addons*): Sane UI's code may see that
  certain other addons are installed and adapt to them. Their names stand in one file only,
  `src/Core/Neighbours.lua` (new, in Core's TOC before `Bindings.lua`): `Core.Neighbours.Window(key)` is a handle on
  one while it is loaded and has what is used of it (`Frame`, `Shown`, `Open` and `Close` by its own functions behind
  `Core.Safe`, `Follow(fn)`: one hook after its opening function), nil otherwise. The first is a talent planner
  (`"talents"`).
- **The seat** (`src/Core/Seat.lua`, new, in Core's TOC after `Holder.lua`): a window that is not ours seated in a
  room of a full window, in UIParent's units (`Core.Seat.New(frame, { label, sized, gone })`,
  `seat:Hold(left, top, width, height, strata, level)`, `Free`, `Size`): as large as fits and never larger than it
  is, in the room's middle; only its place, scale and layer lent (`Core.Lend`), never its parent, so our code never
  shows or hides it; hooks after its `SetPoint` and `SetScale` put it back when the game places or scales it anew,
  `OnSizeChanged` fits it anew and tells `sized`, `OnHide` gives it back and tells `gone`; a protected window in a
  fight is not seated; its level only raised (the game's spellbook stands at 5000). `Core.Lent(frame)` (`Kit.lua`):
  whether a frame is lent now, to any module.
- **Edge's strip of a share of the screen's side** (`Edge.lua`, the window option `strip`): docked at an edge's
  middle, the strip that fills the screen is that share of the screen's side in its middle, anchored to UIParent,
  whatever the window's width, and stays there while the window is full; its length again at
  `DISPLAY_SIZE_CHANGED` and `UI_SCALE_CHANGED`.
- **Combat's window** (`src/Combat/Window.lua`, new): a `Core.Window` of the kind `screen`, docked at `BOTTOM` at
  first, empty and see-through while small (`Window.WIDTH` x `Window.HEIGHT`, not sizable, no mouse), with
  `strip = 0.5`: the middle half of the bottom edge fills the screen, pushed again or Esc it goes back. The board is
  laid out for the full screen as the motion begins (`filled`) and once it stands (`docked`).
- **The board** (`src/Combat/Board.lua`, new): two panels, *Talents* and *Spellbook*, side by side (`Board.Layout`:
  `MARGIN`, `GAP`, each as wide as its share of the widths both want; `Board.TALENTS`, `Board.SPELLBOOK` the game's
  own sizes for an empty one). The game's talents and spellbook are one window (`PlayerSpellsFrame`), seated in the
  panel of the tab it shows; with a talent planner Sane UI knows, the planner's window is the Talents panel (opened
  with the full screen, closed when it goes) and the game's window takes the Spellbook panel whatever it shows.
  Hooks after the game's window's `OnShow` (loaded on demand: `EventUtil.ContinueOnAddOnLoaded`) and its tabs'
  `OnShow`, and after the planner's opening: whatever opens one brings the full screen, or its panel when full.
  Our code never shows or hides the game's window (its `OnShow` and `OnHide` touch the action bars' protected
  grids, and a panel shown by addon code runs the window manager tainted: `Doc/guides/addon-standards.md`, *Known
  traps*). An empty panel shows a plate in Sane UI's look with its title, the game's key for it and an *Open*
  button: for the game's window a `SecureActionButtonTemplate` (`type = "click"` on the game's `TalentMicroButton`
  or `SpellbookMicroButton`, `useOnKeyDown = false`) on UIParent in `DIALOG`, not in our window (it would lock it
  in a fight), made, placed, shown and hidden out of a fight only, hidden at `PLAYER_REGEN_DISABLED` and back
  after; for the planner a button of ours. Going back gives the game's window back to its place, still open (Esc
  closes it with the full screen).
- **Settings:** the page *Combat* with Core's sections *Expand window* and *Window corners*.
- **Standing down** (`ns.GiveBack`): everything seated is given back, the planner closes, the window hides; the
  open buttons hide now or after the fight.
- **Abilities** (`Book/Window.lua`): no placing of the game's spellbook while it is lent (`Core.Lent`).
- **Docs:** `src/Combat/README.md`, `src/Core/README.md`, `Doc/guides/windows.md` (section 7, *Seated*; `strip`),
  `Doc/ideas/Combat.md`, `Doc/ideas/Windows.md` (the bottom middle is Combat's now, was Abilities'),
  `Doc/agent/` (README, core, abilities).
- Tests: `dev/tests/combat.lua` (40 checks), in `dev/tests/run`.
- A game restart takes it in (new files in Core's and Combat's TOCs).

### Social: the guild window on the full screen, the chats among the conversations (Saneroki, 2026-10-20)
- **The guild window** (`src/Social/Guild.lua`, new, in the TOC after `Board.lua`): at the full screen's top right,
  the very window the guild key opens, held there and working as always: the game's guild and communities window, or
  the window another addon shows when it answers the guild key instead. Found by what the key does, never by a name:
  `ToggleGuildFrame` (out of a fight, once per full screen), then among the windows the game knows by name (Esc's
  `UISpecialFrames`, its `UIPanelWindows`) the largest that was not open before; its name kept
  (`store.guildWindow`) to know it when it is open already. Its scale, layer and points lent (`Core.Lend`), placed
  at its room's screen position against `UIParent`, its parent never changed; hooks after its `SetPoint`, `OnHide`
  and `OnSizeChanged`. Opened for the full screen, it is closed with it as Esc closes it; one open already stays.
  Closed by the player, the friends list takes its room until the full screen comes anew; closed in a fight, it
  comes back after it. Setting *Guild window* (`boardGuild`, on), only while in a guild.
- **Layout** (`Layout.Board(width, height, want)`, no share any more): the guild window as large as it is, made
  smaller where the conversations would be narrower than `TALKS_MIN` or the friends list under it lower than
  `FRIENDS_LOW` (220), left out below `GUILD_LEAST` (0.6); the friends list under it and as wide
  (`FRIENDS_WIDTH` at least; `Friends.Size` lays its tabs out anew); the conversations take the rest
  (`TALKS_WIDTH`, `CHAT_LOW`, `FEED_LOW` gone). Without the conversations the chat stands in their place.
- **The chats among the conversations:** the chat and the second chat are the first two rows of the conversations'
  list (`Conversations.lua`: `CHAT`, `FEED`, the second chat while *Second chat* is on, now under
  *Conversations*), not apart in the middle any more. Chosen, one stands beside the list where a conversation does:
  `board.chat` is that part of the panel, the window's chat frame (`column`; the list, scroll bar and button are its
  children now) is seated there, and `Window.Pick` says whether it shows the chat, the second chat (`Feed.lua`: no
  panel of its own, its list made in that frame, over the chat's line, `Feed.Room`) or nothing (a conversation).
  The name line has *Chats*, the ticks of the one chosen. Rows show the last message (`Window.Last`, `Feed.Last`,
  redrawn a frame later, `Conversations.Said`).
- **The game's line and a conversation:** opened while a conversation is chosen, a frame later: by Enter alone the
  game's line closes again (`Input.Close`, its `ClearChat`) and the conversation's own line takes the cursor; a
  whisper to somebody with a conversation (a reply) chooses theirs; anything else chooses the chat, whose line it
  is. A conversation chosen while the game's line is in use closes it; one you began is chosen once the line is out
  of use (`Window.Writing`). `Talks.Whisper`, `Input.Line`.
- **Settings:** *Full screen* now *Conversations* (with *Messages kept per conversation* and *Second chat*),
  *Guild window*, *Friends list* (with *Group finder*); *Height of the second chat* (`feedShare`) is gone. The texts
  for an empty conversations' list went (the chat is always in it).
- **Docs:** the Social README's status line, its *To check in the game* section and its history's notes on trying
  in the game went; the tests' hidden channel has a name of its own. `Doc/agent/social.md`, `Doc/ideas/Social.md`
  and `Doc/ideas/Dialogue.md` follow.
- Tests: `dev/tests/social.lua` (500 checks): the layout with and without a guild window, the chats' rows, the
  second chat in the chat's place, the game's line and a conversation, the guild window held, put back, sized,
  closed, opened anew, closed with the full screen, one open already, another addon's that answers the key, out of
  a guild, switched off, in a fight and after it.
- A game restart takes it in (a new file in Social's TOC).

### Inventory: a new module, the bags from the corner (Saneroki, 2026-10-20)
- **The module** (`src/Inventory/`, addon `SaneUI_Inventory`, *Inventory* under Sane UI in the addon list): what the
  player carries and wears. It needs Core only and has no options page yet.
- **The corner** (`Corner.lua`): the mouse pushed into the screen's bottom right corner opens the game's own bags
  (`OpenAllBags`, as their key); whenever a bag is open, however it was opened, a push closes them (`CloseAllBags`).
  In a fight too: the game keeps a bag button's bag in a secure attribute, so items used from bags an addon opened
  stay the game's own clicks. A square of `Edge.CORNER` screen pixels in the strata `DIALOG` that takes only the
  mouse's coming, one push one change as at a docked window's corner (`Edge.AWAY`, `Edge.LOOK`, `Edge.QUIET`); no
  push during a drag, in Edit Mode or while a window of Sane UI's fills the screen; a window docked in that corner
  keeps it (its square lies above).
- **Not the character sheet** (from the game's error log): it opened with the bags at first
  (`ToggleCharacter("PaperDollFrame")`, closed by `HideUIPanel`). Shown by our code, the game's window manager ran
  tainted and the sheet's `OnShow` failed on the player frame's secret health (`ShowStatusBarText`,
  `TextStatusBar.lua`: "attempt to compare a secret number value (execution tainted by 'SaneUI_Inventory')"); the
  module stood down after that first push, and the manager's slots, written by our call, made the game's own close
  button fail the same way until a `/reload`. The sheet is placed only by the manager, so it is left to its key and
  micro button; the test sees that the module never calls the manager. The trap is in
  `Doc/guides/addon-standards.md`, *Known traps*.
- **Standing down** (`ns.GiveBack`): the corner goes; what is open stays open.
- Tests: `dev/tests/inventory.lua` (21 checks), in `dev/tests/run`.

### Navigation: the map on Zephras Isle (Saneroki, 2026-10-20)
- **The canvas on the planes** (`Coords.lua`, `Camera.lua`, `Canvas.lua`): the views use the planes the routes use
  (`Coords.PlaneOf`, `Coords.Planes`), so Zephras Isle (uiMap 2521) is on the map as a continent is. Standing on
  it the view follows the player there and the arrow shows (`Coords.Player`, `Live.Player`: the plane of the map
  the player is on, the isle's too; the parameter `anyPlane` is gone, and the planner no longer asks for the
  player itself, `Planner.Track`). Coming in over the isle at the world moves the camera into its plane, and a
  click on it there opens it (`Coords.PlaneAt`, which replaces `Coords.ContinentAt`: a continent or such a map
  under a point of the world map); Ctrl and a click puts the map pin on it.
- **A zone of its own** (`Coords.Alone`): a plane that is no continent has no continent's level; its zone's level
  reaches out to the world and a right click on it goes there. `Coords.ZoneAt` and `Coords.Zones` give the isle
  itself, so its pins (the zeppelins' tower, the game's own) and quest areas are drawn and *Parchment* draws its
  own map. At the world off the isle (not following) the camera goes into the plane under the middle at once, so
  over a continent the world is left at that continent's own zoom, not at the isle's much nearer one.
- **The bar and the quest log** (`TopBar.lua`, `QuestLog.lua`): the map selector lists the isle after the
  continents, its zones the isle itself; the quest log looks for a quest's place on the isle too. A pin's place
  (`Pins.lua`) and a map opened at a point (`Window.OpenTo`) are in the map's plane.
- Unchanged: the continents' zoom levels and their drawing (Terrain, Painted, Art loop over the continents as
  before); *Scrying* and *Atlas* show only the sea on the isle (no tiles, overview or painting of it yet).
- Tests: the isle's zones, the zone and the plane under a point, the player there; a camera on the isle (a zone
  out to the world, a right click to the world, the hand-over to a continent at the world, in again over it); the
  canvas there (following, the arrow, the zeppelin's tower as a pin with its tooltip, its own map in Parchment,
  the map selector, out to the world and in again by a click, the map pin); the test pack's zeppelin with its docks
  (`dev/tests/navigation.lua`).

### Navigation: the docks of the boats and zeppelins on the map (Saneroki, 2026-10-20)
- **Their map points** (`dev/tools/travel-data`, Core's set *Travel*): two new fields at the end of the schema,
  `docks` (each dock of a boat or zeppelin on its zone map: one per place it stops at, stops within 20 yards one, in
  the order it first comes to them, placed from its path by map-data's `Placer` like every map point) and
  `dockAreas` (the game's area each lies in, its AreaTable ID from the terrain or a building there; 0 where none
  is, Zephras Isle's two). 25 docks of the twelve ways, from the game's tables of build 70245, taken into the
  versions they belong to as our tool's correction in place (`--take`). The tool takes the terrain files too now.
- **Why the tool, not the run time:** the game's API has no way from a world's map to its zone maps (a world
  position needs its zone map first), and Core's map reader works per zone map, as for *Spawns* and *Places*; the
  client's `UiMapAssignment` and terrain areas place each dock once, exactly. *Places* keeps no piers, so a dock
  is one pin, never two.
- **On the map** (`Data.Map`, `Pins.lua`): a boat or zeppelin stands at each of its docks, one place each, also
  where it stops twice (Feathermoon), key `travel:<way>:<n>`, with `towards` (the way's other docks, each map and
  area; `to` their map where there is one). Its pin in the game's `TaxiNode_Continent_*`, named Boat or Zeppelin,
  the tooltip where it sails to in the game's names of the area and the zone ("To Ratchet, The Barrens":
  `C_Map.GetAreaInfo`, `C_Map.GetMapInfo`), a click opening that map where there is one place only; not marked
  unconfirmed, being the game's own ways. The docks on Zephras Isle wait with the isle's other pins (the canvas
  keeps to the continents).
- Tests: the test pack's boat with docks, its places and its pin with the tooltip (`dev/tests/navigation.lua`);
  the docks placed, one per dock, a dock on no map left out with its area (`dev/tests/walk.py`).

### Navigation: routes to Zephras Isle (Saneroki, 2026-10-20)
- **A plane of its own** (`Coords.lua`): a map straight on the world map that is no continent but has a box and a
  place there (`C_Map.GetMapRectOnMap`), as Zephras Isle (uiMap 2521, the world's map 2991, a zone of the world
  map), is a plane like a continent's, linked through the world map: `Coords.PlaneOf(map)` (its continent, else
  such a map), `Coords.Planes()` (the continents, then those maps). `MapToPlane` places a map's point from its
  plane; `Coords.Player(anyPlane)` (and `Live.Player`) gives such a plane only when asked. `ContinentOf` and
  `Continents` are as they were, so the canvas, its zoom levels, the map selector and the pins keep to the
  continents.
- **The planner** (`Planner.lua`): the pin's plane, the player's and the docks' (`Plane` over `Coords.Planes`), so
  the two zeppelins to the isle (*Travel* 11398 from the Eastern Kingdoms, 11457 from Kalimdor) join the journey; on
  the isle, where the canvas does not follow, `Planner.Track` asks where the player is itself. The walking data has
  nothing of the isle: walks there are straight. The map pin's mark shows on the isle (`Marks.lua`).
- Tests: an isle straight on the test world map, a pin on it, a zeppelin way to it (`dev/tests/navigation.lua`).

### Map data: what Navigation's map shows, from the game and two picked batches (Saneroki, 2026-10-20)
- **Saneroki's ask:** fill Core's map sets so that Navigation's pins of our own data show.
- **From the game** (`dev/tools/map-data`, new; source `game`, build 70245): *Zones*, the 50 zone maps with their
  name, side (the area's faction group; Zephras Isle a sanctuary), continent and area; *Places*, 25 entrances of
  dungeons and raids where the game sends a ghost back to (`Map`'s corpse point), with kind, name, instance and
  zone. No level ranges: the client's tables hold none for zones, and one level only for a dungeon.
- **Placing on the zone maps** (`Placer` in `dev/tools/map-data`, used by every tool that writes map points): a
  world position lies on the zone map of its area, as the game tells it: the building part it stands in (the
  cities inside a mountain or under the ground, Ironforge and Undercity), else the terrain's map chunk; the
  smallest map box only where neither tells. The smallest box alone put 28 % of the original game's spawns on
  the wrong zone (the Barrens' on Durotar's map, Darkshire on Deadwind Pass's, Brill on the Western
  Plaguelands'). `PlaceKeys` gives *Places* their numbers (half a percent, an entrance by its instance).
- **Picked** (two batches in `sources.toml`): batch 3, what Forever's beta servers sent, as sent (199 NPCs, among
  them Forever's new trainers and vendors in the old zones, and all of Zephras Isle); batch 4, the original
  game's (patch 1.12), only where every record of it agrees: a field the same, a spawn within 10 yards for an
  NPC and 3 for an object, a mailbox, meeting stone or spirit healer within half a percent, nothing a holiday
  brings (2,986 NPCs). Both unverified.
  - *NPCs* (3,185): the quest givers and takers of *Quests*, the NPCs with a service, the rares; name, title,
    levels, rank and boss, kind, family, faction, services, goods (what they sell, by the client's item classes,
    and the vendor kinds Forever's templates carry), a rare's respawn.
  - *Spawns* (3,117 entries, 13,533 points): those NPCs (3,005), the herb and ore node types of *Objects* (41;
    every template of one name counts for the one kept) and the treasure chests; one entry's points within 10
    yards of each other as one. Six entries have points of both batches and name both.
  - *Objects*: 71 treasure chests, the chests whose lock the client's own table calls a treasure.
  - *Places*: 100 mailboxes, 22 meeting stones, 51 spirit healers more.
  - Left out: 11,425 single spawns the two records do not share (most of them nodes where one says silver, the
    other gold or iron), NPCs in no record (95 quest givers of the old quest facts) or on no zone map (in
    dungeons), the services the two records differ in, names the game does not show players. No piers: a boat's
    or zeppelin's way in *Travel* stands at both ends already. No zone crossings or caves yet: no source tells
    them well enough.
- *Quests*' schema: a giver's and taker's `npc` is the game's creature ID (`int`), no longer a ref into *NPCs*: 97
  of the 1,805 creatures the old quest facts name are in no source we may take. The packs' bytes stay the same.
- Tests: `dev/tests/map_data.py` (24): placing by the terrain, in a turned building, on the smallest box, off
  every map; Places' keys; zones; entrances.

### Navigation: routes across the sea, by boat and zeppelin, and by the hearthstone (Saneroki, 2026-10-20)
- **The ships' ways** (`dev/tools/travel-data`): the transports' paths of the game's TaxiPath tables (no flight
  point at either end) into Core's set *Travel*, keyed by the TaxiPath ID: kind (a boat when its way keeps to the
  sea's level, else a zeppelin), length (yards once round, leaps not counted) and path, its points now with `map`
  (the world's map, where it changes), `stay` (a dock: the game's delay) and `jump` (the game's teleport or a change
  of map). Twelve ways kept; left out: paths with fewer than two docks, and a way whose docks a newer one all has
  (Menethil to Auberdine, now by way of Southshore). *Travel*'s schema: the path's three new parts; its key is the
  game's TaxiPath ID. Tests in `dev/tests/walk.py`.
- **In the game** (`Planner.lua`): the journey a graph over both ends' continents (each place in its own plane):
  the docks join it, boarded at their piers (`Walk.Nearest` takes a kind now, and opens only the tiles its reach
  comes into); a ship's way from each of its docks to each other is the wait for it (half its way once round) and
  the trip, estimated at `Planner.SAIL` yards a second and `Planner.LEAP` seconds a leap until its time once round
  is learnt (`wait`; the game's tables have no timetables). The line moves on to its next leg as the player comes
  nearer; aboard a ship it stays, and a new pin is planned from where the ship lands. The hearthstone: its place
  learnt per character where it is bound and where it brought the character, used while in the bags and bound
  there, its cooldown as a wait. Ship legs red from pier to pier, the hearthstone's pale blue (`Route.lua`).
- Not yet: the docks' sides (not in the client's tables), Zephras Isle (a zone on the world map, no continent),
  trams, lifts and portals.

### Navigation: routes to the map pin, on foot and by flight (Saneroki, 2026-10-20)
- **Saneroki's ask:** route planning around what cannot be walked, with flights.
- **The walking data** (`dev/tools/walk-data`, new): from the game's own files only, each terrain tile sampled
  every 2.08 yards: the ground's heights but its holes (smoothed over three samples), every collision triangle of
  every building placed on the continents (group files, cut into columns as a voxel field), the water (deep: a
  floor to swim on; magma and slime close what lies under them). Floors (not over 50°, 2 yards free above, one way
  within 2.6 yards) joined into surfaces by a flood (every two neighbours one way), each cut by a quadtree into
  rectangles of up to 32 samples, the ground's ragged edges taking a share of steep samples; regions of all one
  can walk or swim between, those under 3,000 samples left out. A block a tile: surfaces, rectangles, and only the
  openings the game cannot work out (CBOR, deflate, base64). Both continents: 1,724 tiles, 1.43 million
  rectangles, 10.7 MB in Core's set *Walking* (pack *Data: Routes*, loaded at the first route); two minutes to
  make. The baseline's building extraction now takes every group file (`wmo-roots --groups 1`).
- **The flights** (`dev/tools/travel-data`, new): the game's TaxiPath tables into Core's set *Travel*: 296 flights
  with their nodes, side, cost, length and path. *Travel*'s schema: `length` and `path` (new fields).
- **In the game:** `Walk.lua` unpacks a tile (`C_EncodingUtil`), works out the openings within a surface; `Search.lua`
  walks (A* through the openings, swimming twice, regions refused at once, the line pulled straight by a funnel; a
  job of Core's scheduler); `Planner.lua` plans walk, flights the character knows (read at the flight master, kept
  per character), walk, by Dijkstra on guesses, then searches the walks and chooses once more when one is much
  longer than guessed; planned again when the pin changes, after a landing, 40 yards off the line, and when the
  data arrives. `Route.lua` draws it (walks gold, flights pale). The setting *Route to the map pin* (on).
- Not yet: ships, zeppelins, portals and the hearthstone (no timetables in the game's tables); doodads (fences,
  trees) in the walking data.
- Tests: Navigation 210 checks (a made-up walking world: a wall with a door, a channel, the next tile, a region
  nobody reaches; the journey with a flight and without), `dev/tests/walk.py` 28 (CBOR, surfaces and rectangles on
  made-up ground: flat land, a steep speck, a hole, a cliff, a bridge, a shore; the block; regions; a flight's path).

### Navigation: pins, the quest log, the bar; classic windows kept (Saneroki, 2026-10-20)
- **Saneroki's asks** (`Doc/ideas/Navigation.md`): a classic window chosen is kept and the top right corner always
  fills the screen with our map; the minimap shows the map over its whole window, not a square in it; pins and
  every notation stand over the map, never behind it.
- **Classic windows kept:** Core's Edge takes entries with `checked` and `back` (a checkbox, ticked while the game's
  own is the one kept; chosen again, ours is the one again and the window stays). Navigation's two are the switches
  *Show the game's minimap* and *Show the game's map*; the game's map chosen opens at once. With the game's
  minimap chosen the small window rests out of sight (alpha 0, no mouse, no textures) and the corner still fills
  the screen with our map; Edit Mode shows it.
- **The minimap fills its window:** the game's minimap, square and as large as the window's longer side, is cut to
  the window's shape by a mask, a band as tall (or wide) as the shorter side in 32nds (`Hybrid.Mask`; 62 masks in
  `src/Navigation/Art/Masks/` by the new `dev/tools/minimap-masks`, 195 KB): the game draws its dots inside its
  mask only, so they cover the whole window and nothing past it.
- **Always on top:** `Canvas.LEVELS` stacks every layer from the canvas' level at each layout: the map's own up
  to `Canvas.MAP`, then quest areas, the route, the game's minimap, the pins, the marks; the bar over all.
- **Pins** (`Pins.lua`, `PinView.lua`): the game's per map (quests on its discs and marks, the arrow's quest's next
  way, flight points of the player's side, vignettes, area points, map links, entrances where it has them) and
  Core's (`Data.Map`), one per key (the game's hides the data's), filtered by the new multi setting *Pins on the
  map* and the bar's *Pins*, gathered when they would cover each other (a click zooms in), in the game's atlases;
  a press on a pin is the map's drag, a click the pin's (a quest's: the arrow leads to it; an entrance's: its map).
  Quest givers only with a quest this character can take (`Pins.Offered`). The party and raid in class colours
  (`Marks.Group`). Quest areas by the game's `QuestPOIFrame` over each zone in view (`Areas.lua`).
- **Core's map reader** (`Core/Data/Map.lua`, `Data.Map()`: `On`, `Spawns`, `OnChange`; data build step 1d.5's list
  per map, built ahead): the places of Spawns, Places and Travel per map, each with what it is; sets no pack holds
  passed over without a word. The three hold no entries yet: the database's pins come with the import.
- **The quest log** (`QuestLog.lua`) at the full map's left, coming in with the window's motion: the game's headers
  (folded as the game keeps them), quests with level, state and watch, their objectives; a click leads the arrow
  to the quest and shows its place and text (*Track*, *Share*, *Abandon* after the game's own question); Shift-click
  watches; the right button's menu; the mouse over it shades its area.
- **The bar** (`TopBar.lua`) over the full map: the quest log in or out (kept), the views (moved from `Window.lua`),
  the map selector (the world or a continent, a zone A to Z), the pin filter.
- **The golden line** (`Route.lua`): a way drawn with pooled `Line`s, the game's dependency bar art tinted gold, its
  glint moved by a `TextureCoordTranslation` animation; the planner comes next.
- `Live.lua`: map links, entrances, `TAXI_NODE_STATUS_CHANGED`, `PLAYER_LEVEL_UP`, `QUEST_WATCH_LIST_CHANGED`;
  `Coords.Zones(continent)`.
- Tests: Navigation 195 checks (the pins of both sources, one per thing, the filter, gathering and its click, the
  stacking, tooltips, the continent's pins, the quest log's rows and actions, the area, the line, the party, the
  resting window, the kept classic windows, the masks), windows 359 (kept choices).

### The Atlas' colour pass and packing (Saneroki, 2026-10-20)
- **The colour pass** (`Doc/ideas/Navigation.md`, *The colour pass*): `dev/tools/atlas join` moves each painting's
  broad hue and saturation toward the game's before joining (its brightness stays: Duskwood stays dark), keeping
  half of the model's own (`--mood`, default 0.5;
  `--as-painted` skips it), and pulls its water toward the open sea's blue (half its brightness, so Duskwood's
  river stays dark); lava stays as painted. The paintings
  on disk stay as painted, so the mood can change without painting again. Badlands' orange, Teldrassil's pink bark
  and green forest and Burning Steppes' grey ash come back, and neighbours painted a little apart meet evenly.
- **Lava glows, it does not smoke:** `atlas.toml`'s lava sentence drew a cloud of smoke over Burning Steppes.
- **`dev/tools/atlas pack`** (*Packed*): the painted squares as the Atlas module's art, nine levels of 512-pixel
  BLP2 DXT1 blocks with mipmaps and their `Index.lua`, into `assets/optimized/Atlas/`; a continent is joined and
  handed down the levels a band at a time; blocks with land not yet painted, or only open sea, are left out.
- **Tests:** `dev/tests/atlas.py`: the colour pass (the game's broad colour back, the fine detail kept, the mood,
  water toward the sea, lava kept); packing (the index's text, halving, painted, sea and missing ground where
  strips meet, the levels, the BLP header).

### The Atlas faithful: words of an edit, what stands in water kept (Saneroki, 2026-10-19)
- **Decided** (`Doc/ideas/Navigation.md`, *Faithful above all*): the painted view adds nothing the game does not
  have; ground too steep to walk is painted as bare rock and cliffs, so a player sees the way is closed.
- **The Atlas lab** (*The lab*): 26 hard places painted by every method (repaint words, starting from the terrain,
  the Qwen-Image 2.1 Fun ControlNet on heights and grey, FLUX.2 [klein], relief-shaded and texture-detailed
  inputs, a map built from the game's data alone, words of an edit), each scored against the game: layout,
  colour, relief, steep ground painted green, water added and lost. Words of an edit kept the layout on 8 of 8
  places, the repaint words on 2.
- **`dev/imagegen/maps/atlas.toml`** now holds words of an edit: make image 1 look like a photorealistic satellite
  photograph of exactly the same place, change only how things look, never where or what anything is; the
  square's ground in plain words (a phrase for each kind of ground cover), its liquids, its zone's colours and
  the light of its atmosphere, nothing added or taken away. `dev/tools/atlas`'s words follow it; the roof rule,
  the mostly-water line and the capitals' `square` lines (`zones.toml`) are gone.
- **What stands in water stays:** `dev/tools/atlas` makes only the open water flat (`open_water`): the minimap's
  piers, stilt houses, bridges, domes and ice over the game's water stay in the picture, and do not count as
  water (Booty Bay's boardwalk had been erased).
- **The words refined** (rounds 6 and 7 on 26 places, the zones whole, both continents): no sentence on the ground
  (the ground cover called Darkshore sand); "only a little water" under 1 % (the water sentence dug channels);
  the zone's light without its clauses about colour or haze, and "keep the colours of image 1, no clouds, fog,
  mist or smoke over the ground"; the minimap textures softened by 2 pixels (`SOFTEN`, was 0.8: a grid in the rock,
  a lake by Stormwind's cathedral). `atlas.toml`'s ground-cover phrases are gone.
- **Tests:** `dev/tests/atlas.py`: the new words, what stands in water, the light's quality, a little water.

### The Atlas' painting run: dev/tools/atlas (Saneroki, 2026-10-19)
- **`dev/tools/atlas`** (new): `paint` paints the Atlas square by square in the local ComfyUI: both continents'
  land in 1,456 squares of one tile at 2048 pixels, overlapping by an eighth, each from the game's terrain (its
  minimap textures softened a little, its liquids, its map chunks' zones) with its words put together from the
  zone briefs, `dev/imagegen/maps/atlas.toml` (new: the fixed words) and what the game has in it; each painting
  checked against the game's water, painted again with another seed when it fails, the best of three kept;
  resumable (`state.json`, `words.jsonl` in `assets/generated/atlas/`). In a console window a screen of its own: a
  progress bar with the share done, the square and zone being painted with its steps, the time left and when it
  ends; `p` pauses after the picture being painted and frees the graphics card, `q` quits at once. `status`
  tells how far it is; `join` stitches painted squares into one picture, each overlap cut along the line where
  the two paintings differ least; `--near` paints a few squares around a place, `--dry` runs without painting.
- **Every square on its own:** pasting a square's painted neighbours into its edges made the model paint a garish
  strip at the wrong scale along the opposite edge (Darnassus, 2026-10-19), so squares are joined by the cut.
- **The words:** a capital's `square` line in `zones.toml` (the six capitals); the roof rule only for house-sized
  blocks of colour (it had built a town on Darnassus' giant branch).
- **Tests:** `dev/tests/atlas.py` (new, in `dev/tests/run`): the phrases a square keeps, the words put together, the
  check on made-up pictures (added and lost water, a zone graded blue), the cut, the grid, the websocket's frames.

### Navigation: the Atlas a module of its own, the view Overlay gone (Saneroki, 2026-10-19)
- **Decided** (`Doc/ideas/Navigation.md`, *Atlas, a module of its own; Overlay gone*): the painted map is the addon
  `SaneUI_Atlas`; with it the map offers Parchment, Scrying and Atlas, without it Parchment and Scrying.
- **The module** (`src/Atlas/`, new: `SaneUI_Atlas.toc` loaded on demand, `Atlas.lua`, README): reads the index of
  its art once when loaded into a set of the blocks and answers Navigation as `SaneUI.Atlas` (`Ready`, `Levels`,
  `Span`, `Cells`, `Cell`, `Corner`, `Key`, `Has`, `File`, `PIXELS`). Its art (`Art/<continent>/<level>/<row>_<col>.blp`,
  512 pixels, BLP2 DXT1, level 0 at 2048 pixels a tile) and its `Index.lua` are made by `dev/tools/atlas` into
  `assets/optimized/Atlas/`, never into `src/`.
- **Navigation** (`Painted.lua`, new): finds the module at login without loading it (there, switched on for this
  character, loadable), offers its button and its choice only then (`ns.Offered`, `ns.View`, `ns.Offer`), loads it
  the first time the view is drawn and draws its blocks over the terrain as Scrying draws it: the coarsest level
  with as many pixels a yard as the screen shows, the next coarser one under it, from the canvas' pool; at most
  400 blocks of a level a continent. If it cannot be loaded or stands down, the map shows Scrying, its button and
  choice go, the problem is kept and told once. Its nearest zoom is three times the others' (`Camera.Near`, 6
  units a yard); the game's minimap's steps work as before.
- **Overlay gone:** its button, its choice, its words and tip, and the art's half see-through mode
  (`Art.HALF`); the default view is Scrying, a saved Overlay falls back to it (the settings' check).
- `dev/build` builds `SaneUI_Atlas` from `src/Atlas/` and `assets/optimized/Atlas/` together, only once
  `assets/optimized/Atlas/Index.lua` is there (rsync copies only what changed); `dev/tests/lint` accepts the TOC's
  `Index.lua` there, or missing while no art is made, and checks it when it is there.
- Tests (`dev/tests/navigation.lua`, 142 checks): the views offered with and without the module, a saved Overlay
  and Atlas falling back, the module found, failing to load and loaded, the index read, the block under a
  position, the level for a zoom, the blocks drawn, the nearer zoom, the fall back when it stands down.

### Art and animation in Git LFS (Saneroki, 2026-10-19)
- `.gitattributes` keeps PNG, BLP, TGA, JPG, GIF, WebP, MP4 and WebM files in Git LFS: the game's textures
  (`assets/optimized/`, the modules' `Art/`) moved there, and the drawings, concept art and flipbook sheets in
  `assets/` are committed now (they were local only). `assets/generated/` stays local. A new clone needs
  `git lfs install` once.
- `dev/build` installs nothing when a built file is a Git LFS pointer instead of the art, and names the files
  (`git lfs pull` fetches them).

### Navigation: the Atlas' look, each zone's atmosphere, painted only what the game has (Saneroki, 2026-10-19)
- **Decided** (`Doc/ideas/Navigation.md`): the painted view is a photorealistic render seen from straight
  above; every zone has its own atmosphere within it (light, air, colours, the state of what stands there);
  only what the game's terrain and files show is painted; it zooms about three times closer than the map now,
  painted at 2048 pixels a tile; the far levels are the same pictures, smaller; quality before speed, within a
  couple of days of painting, started only when Saneroki says so.
- **Atmospheres:** `dev/imagegen/maps/zones.toml` gives every zone and city an `atmosphere` (light, air, colour
  grading, the state of things and small props), which names no feature with a place, so it fits every square
  of the zone.
- **The Atlas pilot:** `dev/imagegen/sets/maps-atlas/pilot.txt`, one tile at 2048 in ten zones (Stormwind,
  Goldshire, Blackrock Mountain, Darkshire, Brill, Orgrimmar, Astranaar, Booty Bay, Everlook, Gadgetzan); each
  square's words put together from what the game has in it: its main zone's biome, plants, colours and
  atmosphere (phrases about water or lava dropped where it has none), its ground cover and its liquids. Before,
  "the flat dark blue areas are water" with no water in the square made the model paint Blackrock's ash plain
  as lakes, and a zone's list of buildings brought orc forts and tents into empty ash.
- **Tried for speed, not taken:** painting at 1024 and enlarging with two upscaling models (they sharpen, add no
  detail) and the Turbo model at 2048 (soft, flat rock).
- `Doc/guides/image-generation.md`, *Maps*: the briefs' fields a square may use, saying which liquids the game
  has, the view straight from above, the upscalers.

### Navigation: the views Parchment and Scrying; the painted view's guides, briefs and pilots (Saneroki, 2026-10-19)
- **The views' names:** the buttons read *Parchment* (was *Sketches*) and *Scrying* (was *Terrain*), with tips to
  match; *Overlay* stays until the painted *Atlas* takes its place (`Navigation.lua`, README, changelog). The
  code's keys are unchanged.
- **Five styles to choose from:** `dev/imagegen/sets/maps-styles/` paints Stormwind, Blackrock Mountain, a forest
  (Ashenvale around its lake town) and the whole world in five different styles (grimy realism, the original
  game's painted textures, high-fantasy matte painting, an old oil painting, a photorealistic render): the
  stylised look felt too cartoonish close up.
- **Decided** (`Doc/ideas/Navigation.md`): Sketches and Terrain stay as they are; the local image models paint a
  third view of its own in Overlay's place: the terrain repainted in the chosen look, *stylised game art* (bold,
  saturated), every road, building and tree where the game has it, as close as the minimap zooms (single
  buildings clear) and out to the whole world (levels of detail); the Maelstrom, ships and sea creatures as
  looped animations; caves, mines, entrances and ways between zones as pins, not painted; routes, flight paths
  and ship lines later, as interactive parts drawn by code.
- **The close-up pilot:** `dev/imagegen/sets/maps-pilot/close.txt`, the look on the terrain itself at the minimap
  textures' 512 pixels a tile (Stormwind, Goldshire with the city's gate, Westfall's edge, Orgrimmar, Razor Hill)
  and one tile at 1024; the terrain the only picture, the look in words.
- **Zone briefs:** `dev/imagegen/maps/zones.toml` (new), one table for each of the 43 zones and 6 cities and one for
  the sea: biome, land, plants, colours, buildings, roads, places, mood, a city's layout and a prompt paragraph,
  in words that name nothing (a name in the words comes back as garbled letters in the picture); caves, mines,
  entrances and ways between zones left out (pins); the sea's water, the Maelstrom and 11 sprites of its life.
- **`dev/tools/map-meta`** (new): from the game's terrain files, the texture and object files of each tile and
  the buildings' own files, both continents at 128 texels a tile in `assets/generated/maps/meta/`: the roads
  (the road and paving textures, thin roads kept whole, lone decoration patches dropped), the footprints of the
  3,206 standing buildings as they are turned, the ground cover in 13 kinds, and `places.json`: 856 areas, 114
  city districts (from the parts of the cities' buildings), 68 flight masters, 26 dungeon and raid entrances, 251
  caves and mines, 62 exits where two zones' roads meet. It reuses `dev/tools/terrain-art`'s reading of the root
  files.
- **The look pilot:** `dev/imagegen/sets/maps-pilot/looks.txt` (replacing the lists that redrew Sketches and
  Terrain): five looks (watercolour atlas, natural satellite painting, stylised game art, ink on parchment,
  gouache storybook) on two squares of 4 x 4 tiles at 256 pixels a tile, Stormwind with Elwynn and Westfall,
  Orgrimmar with Durotar and the Barrens. The words name no place and image 2 is softened: the model writes
  every legible name into the picture.
- `Doc/guides/image-generation.md`, *Maps*; `Doc/agent/development.md`, `navigation.md`.

### Tooltips: grooves easier to read (Saneroki, 2026-10-20)
- The groove's shade is stronger (`Pools.GROOVE` 0.6, was 0.4): a section's rules and name, a table's captions
  and the lines between its cells.
- Its words have a faint light edge one screen pixel under them, as cut letters catch the light, so the dark
  words read on the dark ground (their shadow: white at `Pools.GROOVE_LIGHT` 0.15, offset by `Core.Pixels`). The
  font kinds' `flat` is gone: `groove` says it; `Pools.lua` sets every other kind's shadow offset and colour
  back to its font's own.
- Tests: the stronger shade, the light edge under a table's captions and a section's name.

### Tooltips: grooves, a spell's table and its requirements (Saneroki, 2026-10-19)
- **Grooves:** a section's name stands in the middle with a rule at each side, name and rules in one dark
  see-through shade (`COLOR.GROOVE`, black at `Pools.GROOVE` 0.4), as are a spell's table captions and the lines
  between its cells: they look pressed into the ground. Groove texts have no shadow (font kinds `section`,
  `caption`, `hint`: `flat`, `groove`). The table's values are white. `COLOR.RULE` and `COLOR.CAPTION` are gone.
- **The bottom line** reads *Hold ALT for more*, as a caption between two rules (font `hint`, as written:
  `row.caps` is set only by `Read.Caption`); `row.center` is gone.
- **A spell's table** in Info: four columns and two rows for a spell that hurts or heals (*Dmg*/*Heal*, its cost,
  *Cast* or a swing's *Speed*, *Range*; *DPS*/*HPS*, *Per* its power, *CD*, *Crit* or, for one that lasts,
  *Duration*), one row for any other (cost, *Cast*, *CD*, *Range*); every cell filled, *---* where nothing is
  known. All columns of a panel's tables alike (`widestCell`), so the rows line up. *Melee* for melee range
  (the game's `MELEE`). `Numbers.Spell` gives `lasting`. Then the description, a little apart.
- **What a spell asks of you** (a stance, a form, a weapon: `SPELL_REQUIRED_FORM`, `SPELL_EQUIPPED_ITEM`; its
  reagents and tools) stands in its header under its school, a row each, red while the game has it red.
- **Physical spells are red** (the game's red; its combat log's yellow was too close to holy).
- Tests (458 checks): the centred name and its two rules, the groove's shade and alpha, the table's cells and
  white values, Revenge as an example (a stance in red, rage, Melee, its second row), a heal over time's
  Duration, reagents and tools in the header, the swing in red.

### Tooltips: Info, Alt for more, disenchanting and the price to post; careful gathering data (Saneroki, 2026-10-19)
- **One section Info** for a thing's own lines: an item's numbers, effects, description and durability; a
  spell's strips and description; a buff's and a quest's text (`TEXT.INFO`; *Stats*, *Effects*, *Description*
  and the section *Durability* are gone). A set's lines stay under *Set*.
- **Hold ALT for more info:** a tiny line (font kind `hint`) in the middle at the bottom of every panel of the
  game's data while Alt is not held (`Read.lua`). **Inventory** and **Addons** only while Alt is held
  (Inventory then shows every character: the limit of five is gone).
- **Gathering joins Professions:** the node that gives a herb or an ore stands under *Professions*, after the
  professions that use it; a node's own tooltip has its skill under *Professions* too. Each node has its own
  yellow and grey skill (Core's data); green begins halfway between them, as the game colours a recipe; on
  a node's tooltip the colour the game gives its line of the skill wins where it is a colour of difficulty.
- **Your character beside gear** is see-through: no ground behind it.
- **The durability bar** is like a unit's health bar: 18 high, flat, round corners (the panel's mask), with
  *Durability* at its left and the numbers at its right inside (`row.inside`).
- **Section names** in the rule's own quiet grey (`COLOR.RULE`), without a shadow (font kind `section`,
  `flat`; `Pools.lua` sets every other kind's shadow back); the rule is one hairline in that grey.
- **Gold:** *Disenchant*, what disenchanting a weapon or armour of uncommon quality and up brings: its
  materials as often and as many as disenchanting gives them (Core's new set *Disenchants*, by the item's
  class, quality and item level), each at the lowest price seen less the cut; *no prices seen* while a
  material lacks one; with Alt each material. With Alt, *Sell at*: the lowest offer less one copper, never
  so low that a sale brings less than a vendor pays (`Gold.PostAt`, as Economy's plan has it).
- **Core's data, picked anew** (CLAUDE.md, *Careful data*): the 47 nodes of 2026-10-18 under `hand` are
  replaced by batch 1: 53 herb and ore node types, one entry per name, the skill each needs as Forever's client
  asks it (its lock table, build 70245), where each turns yellow and grey (Forever's own for its new nodes,
  else the original game's rule), and what 51 of them give (`object:<id>` in Drops). The set *Objects* has
  the fields `yellowAt` and `greyAt`. New set **Disenchants** (pack *Items*, batch 2): 44 rows of Forever's
  client table of disenchanting with the original game's materials; rows whose materials are not certain
  (epics, uncommon and rare items of level 61 and up) are left out. Both batches are unverified (sources 1
  and 2 in `sources.toml`); `Doc/guides/data.md` lists the new set.
- Tests (453 checks): Info, the hint line, Inventory with Alt, the stage without ground, the durability bar,
  the captions' colour and shadow, disenchanting (no prices, the value, materials with Alt, another class),
  Sell at, gathering with the nodes' own ranges and the game's colour. Sample rows in
  `dev/tests/data/tooltips/` (Objects with their ranges, Disenchants).

### Navigation: Sketches, one stitched map of both continents, every zone's map in full (Saneroki, 2026-10-19)
- Saneroki's asks: both continents at every zoom; our own world and continent map stitched from Blizzard's zone
  maps; the dark undiscovered parts out again, every map always in full; soft fades at the zones' edges; the view
  *Blizzard maps* renamed *Sketches* (key `sketches`).
- `dev/tools/terrain-art` takes the game's map art too (a fourth folder; the private tools fetch it): every
  zone's full map (its art and every part the game reveals once explored), cut by its outline, laid on its
  continent's grid in the terrain's blocks (`src/Navigation/Art/Sketches/`, 45, 15.8 MB, DXT5 with alpha where no
  zone is); `Art/Edge.blp`, a box with its paper frame faded off. The outlines keep a zone's land and two map
  chunks of shore (the open sea, water reaching the grid's edge, left out: no zone's painted sea out to its box's
  edge; lakes and rivers stay), whole up to the border and fading past it (a Gaussian of 2.5 chunks, out at 0.08),
  and off the frame at the box's edges (`FRAME`).
- `Terrain.Overview` (was local): every continent's blocks in view, by link, at every level, from any pool and
  path; the terrain and the stitched map draw through it, so the other continent shows wherever it is in view.
- `Art.lua`: Sketches draws Blizzard's world map and every continent's in view under the stitched map, their
  frames faded off by the edge mask; up close the zones' own maps over it. Overlay: the stitched map far out,
  the zones' maps up close, half see-through. `Parts` (was `Explore`): every part of the set *Overlays*, never
  tinted; the parts the game lists as explored only until the set is there. `Art.FOG` and the dark parts gone.
- The canvas' ground follows the view: the sea's colour for the terrain, a dark paper (`Canvas.PAPER`) for
  Sketches. Tests: Navigation 113 checks (Sketches' layers, both continents at a continent's level, every part
  drawn).

### Navigation: the water cut away, zone-shaped maps, undiscovered parts dark (Saneroki, 2026-10-19)
- `dev/tools/terrain-art` now also reads the game's terrain files (root ADTs, `<tile key>.adt`) and client
  tables: each map chunk's heights (the four triangles of a cell), its water (`MH2O`: the liquid's type, its
  cells and surface; water and ocean count, magma and slime not) and area. The overview's alpha is the land,
  sampled 2 yards apart; its colour from land alone, spread into the sea, so no dark rim; BLP2 DXT5 (45
  textures, 15.8 MB). Each zone's outline (`src/Navigation/Art/Zones/<uiMapID>.blp`, 47, 4.2 MB): the chunks of
  its areas (an area's top parent, the zone map assigned to it), softened on the whole grid so neighbours share
  their border, over the zone map's box; `src/Navigation/Outlines.lua` lists them (new in the TOC). ImageMagick's
  range fit for DXT5: its cluster fit takes about a minute a texture with a partly see-through alpha.
- `Canvas.Masks` (new): masks by key, the alpha of a file over a rectangle of the plane; a pool's `Get` takes a
  mask (`Mask` swaps it, `End` lets go). The terrain's tiles are cut by their block's overview; the canvas'
  ground is the sea's colour.
- `Art.lua`: at a zone every zone in view with an outline is drawn in its own map, cut to it (both art views);
  a zone without one in the middle whole. The explored parts in both views, and the parts not yet explored
  nearly black (`Art.FOG`): every part of the map is Core's new set *Overlays* (pack World, index `byMap`; 572
  parts of 45 zones from the game's tables), those the game does not list as explored (known by their first
  texture) are dark. Tests: Navigation 113 checks (the coast mask, the outline, the dark part).

### Navigation: zones open by a click, the map goes with its window; Core: one push a visit (Saneroki, 2026-10-19)
- Core's Edge: one push is one change. After a push the edge or corner counts again only once the mouse has
  gone `Edge.AWAY` (24) of the screen's pixels from it; a look every `Edge.LOOK` (0.1 s) while it stays sees
  when (the window's motion moved the square from under the resting mouse and back, which filled the screen
  and took it back again and again). The strip tells `Pushed` its side.
- Core's Edge and Window: the option `moving(share)`: what the window holds stays in sight on the way and is
  placed at every step, instead of fading out and coming in; `filled(on, width, height)` now also says the size
  the window goes to. The stand-in's `GetCursorPosition` follows `W.cursorX`, `W.cursorY`; the Social test lets
  the mouse go from the edge before its second push.
- Navigation's map goes with the window (`Canvas.Morph`, `Canvas.Step`): laid out once at the start over what
  both views show, at the wider view's zoom; each step scales and moves the holder only, from the view it leaves
  (or where a way turned back stands) to the one it comes to, the middle straight, the zoom by equal factors.
  The canvas lays out again when it is sized while it stands (Edit Mode).
- The game's minimap covers the whole view (`Hybrid.Side`: the longer side; the canvas cuts the rest), its
  strata and level set from the canvas each time it is placed; the canvas sets its layers' levels at every
  layout (`Canvas.LEVELS`; `Marks.Stack`; the layers' `Build` return their frames). Its mask is set again after
  the game's answer to the setting `rotateMinimap` (`CVAR_UPDATE`; in this game the minimap's config is a
  function of its own, not `MinimapCluster:UpdateMinimapConfig`).
- The zone under the mouse lights up on a continent shown whole, the continent on the world (`Art.Light`: the
  game's `C_Map.GetMapHighlightInfoAtPosition`, a file or an atlas, added, on a frame of its own over the art);
  looked at only while the mouse is over the map and has moved. A plain click opens it (`Camera:Fit`).
- Tests: Navigation 109 checks (the minimap's level and cover, the map half way through the motion, the
  highlight and the click), windows 356 (one push a visit, a window whose content goes with the motion).

### Navigation: the whole module but the map's data (Saneroki, 2026-10-19)
- Saneroki's decisions: the minimap and the full screen map look and behave exactly the same (the minimap a
  smaller part of the screen, as the chat window is the same chat full screen); the three views at every zoom.
- One window, two cameras (`Window.lua`: `small`, `full`), one canvas for both (`Canvas.lua`): drag, the wheel
  around the mouse (instant, as Blizzard's map), right click one map out (zone, continent, world), Ctrl-click
  the game's map pin (`Marks.lua`: Blizzard's pin atlases, clicks and sounds), a click on the game's minimap
  pings; the tracker follows the player every frame while following (else every 0.1 s) and follows again after
  *Follow again after* seconds without the mouse on the map. The view buttons at the full map's top left.
- The map tree at run time (`Coords.lua`): the world map, its continents (`GetMapRectOnMap`: four answers, so
  `pcall` and not `Core.Ask`, which hands on three), `Link` and `WorldBox` put every continent and the world map
  into one continent's plane; `ContinentAt`, `ZoneAt`, `MapToPlane`; kept per session. The camera (`Camera.lua`):
  levels with 15 % slack, `Move` into another continent's plane at the same size on the screen, `StepOut`,
  `Fit`, `Show`.
- Terrain at every zoom (`Terrain.lua`): the game's tiles (up to 400) over the module's overview, always drawn
  under them; at the world every continent's overview. `dev/tools/terrain-art` (new) makes the overview from the
  game's minimap textures: 45 textures of 512 x 512, 64 texels a tile, BLP2 DXT1 with mipmaps, in
  `src/Navigation/Art/Terrain/`.
- Art (`Art.lua`): the world map at the world, the continent's, the zone's over it, and the explored parts
  (`C_MapExplorationInfo`, placed as Blizzard's exploration provider does; those shown only under the mouse left
  out); over the terrain the zone's map alone, half see-through.
- The game's minimap over ours (`Hybrid.lua`): reparented into the canvas, square mask, ground off (indoors on),
  rotation ignored, wheel ours, left and right clicks through, border and zoom buttons out of sight, the cluster
  at alpha 0 with every click under it off but Edit Mode's selection; shown while the view follows at one of its
  steps, each step's radius measured from the game (again after every loading screen, and the first time indoors
  or outdoors); its mask set again after the game's `UpdateMinimapConfig`; all given back exactly, out of combat.
- The game's map kept closed (`Native.lua`): override bindings for the keys of the game's map, quest log and
  minimap on `SaneUINavigationKey` (out of combat, again on `UPDATE_BINDINGS` when they changed); a hook after
  `WorldMapFrame`'s `OnShow` hides it, closes it on the next frame (`HideUIPanel`) and opens ours at its map; in a
  fight it stays the game's. Switches *Show the game's minimap* and *Show the game's map*; *Classic windows*.
- `Live.lua` (new): the player, the pin, the group, quests, flight points, vignettes, area POIs, explored parts,
  and the message `LIVE` once a frame after the game's events.
- `GiveBack`: the keys, the game's minimap, the window. Docs: the module's README, `Doc/agent/navigation.md`,
  `Doc/agent/README.md`, `Doc/agent/development.md`, the plan (the two decisions, far zoom answered, instant zoom,
  following).
- Tests: `dev/tests/navigation.lua` 98 checks (the map tree and links, the camera's levels and the continent
  switch, Live, the minimap taken and given back, the wheel through its steps, drag and following again, ping,
  Ctrl-click and the pin, right click, both views and the three views at the world, the game's map caught and
  its keys, the switches, standing down).

### Navigation: the first proof, the full screen map (Saneroki, 2026-10-18)
- A new module, `SaneUI_Navigation` (`src/Navigation/`): a window of Core's (kind `screen`, docked `TOPRIGHT`,
  small it shows nothing and takes no click) that fills the screen when the mouse goes into the top right
  corner, and shows the map of the player's continent there. Drag pans, the wheel zooms around the mouse
  (1.25 a notch, from 2 units a yard out to the whole continent). Three buttons at its top left, also the
  setting *Map view*: *Blizzard maps* (the continent's art, the zone's over it when the view is under 9000
  yards high), *Terrain* (the game's minimap textures; past 400 tiles in view, the art), *Overlay* (the art
  half see-through over the terrain, the zone's alone). `/sane map` (and `reset`).
- Built as the plan's design says: `Coords.lua` (map, world and plane, a map's box read from the game with
  the axes found from the map itself, the terrain's grid), `Camera.lua`, `Canvas.lua` (one holder frame moved by
  a drag, layout only on a zoom or past a margin, keyed texture pools, no `OnUpdate` at rest), `Terrain.lua`,
  `Art.lua` (the last tiles cut at the art's edge), `Window.lua`. Every script guarded; `GiveBack` hides the
  window.
- Core's data: the set *Tiles* (`assets/data/Tiles/`, pack World): each continent tile's minimap texture,
  1724 entries (Eastern Kingdoms and Kalimdor) from the game's own continent files, build 70245; the beta's
  are the same. Pack World's notes; the data guide's table; `Doc/ideas/Data.md`.
- Docs: the module's README, `Doc/agent/navigation.md` (*Built*), `Doc/agent/README.md`, the plan's status.
- Tests: `dev/tests/navigation.lua` 43 checks (the spaces and the grid, both orders of the game's vector, the
  camera's zoom around the mouse and its bounds, the map drawn each of the three ways from a sample pack, a
  drag that moves only the holder, the tile cap, closing, standing down), in `dev/tests/run`.

### Core's own doors guarded too; the lint covers all of src (Saneroki, 2026-10-18)
- `Core.Guard(label, fn)` (`Core.lua`): Core's door for a frame's script, a hook, a timer or a menu's function,
  as `module.Guard` is a module's. Core stands down for nobody: an error that ran into a module's code stands
  that module down (found by its place), Core's own is told once under the label and the next call tries
  again. All results handed on; no table or closure per call.
- Core's 95 bare doors guarded: its windows (`Window`, `Edge`, `Dock`, `Holder`, `Motion`, `Watch`,
  `Escape`), Edit Mode (`EditMode`, `Selection`), tips (`Kit`), aliases (`People`), the options (`Settings/`),
  Sync and the data scheduler (`Data/Steps.lua`: its guarded `OnUpdate` made once, at the first wake; Esc's
  timer function made once). Four are the guards themselves (the event frames, `Later`'s timer, the ear at
  the game's error window), marked `-- unguarded:`.
- `dev/tests/lint`: the check of guards runs over Core too; `Core.Guard(...)`, a one-step `Core.Safe(...)`
  and a frame's own `StartMoving`/`StopMovingOrSizing` count as guarded.
- Docs: `Doc/guides/addon-standards.md` 10 (Core's row, made once where it is set), Core's README.
- Tests: `dev/tests/core.lua` 347 checks (`Core.Guard`: results, told once and tried again, a module's error).

### Social: conversations on the full screen (Saneroki, 2026-10-18)
- A panel at the full screen's left (`Conversations.lua`, a part of `Board.lua`): the list of conversations, the
  newest message first (class icon, alias or name, last message, time, unread count; the title counts all), and
  the one chosen in the chat's bubbles with a pill per day, its name and note above, an edit box of ours under
  it that sends to it (`/` lines go to the game's line; nothing sent in chat lockdown). Right click: the game's
  menu of the player. Foot: *Whisper* (the game's line with `/w`), *Remove* (confirmed). The full window's
  search finds conversations by name and messages.
- `Talks.lua` (no frames): every whisper (a Battle.net friend by BattleTag) and the party's, raid's and
  instance group's chat, each a conversation; copies of the log's messages (`Log.KEPT`, now shared) with a
  `stamp`; `talkSize` kept each (the one read keeps all until left), 50 conversations at most; sent the game's
  way (`SendChatMessage`, `C_BattleNet.SendWhisper`); saved per character (`chars[key].talks`, Battle.net
  messages without the session's names).
- `Log.Read` puts `with` and `account` on whispers; `Heard` hands whispers and group chat to `Talks.Add`.
- `Layout.Board`: `talks` at the left, `TALKS_WIDTH` 600, down to `TALKS_MIN` 460 to keep the chat's
  `CHAT_MIN`, else left out. `Board` tells a part its size (`Part.Size`). `Window.Repaint` and `Resize` redraw it.
- Settings (*Full screen*): *Conversations* (`boardTalks`, on), *Messages kept per conversation* (`talkSize`,
  20 to 500, at first 100).
- Tests: Social 464 checks (the board with the panel, whispers in and out, Battle.net, a party, sending,
  commands, lockdown, aliases, search, trimming, saving and restoring, removing). The stand-in's `date` takes a
  time, as the game's.

### Errors handled gracefully, a hard rule (Saneroki, 2026-10-18)
- Core (`Core.lua`, *Errors*): every piece of Sane UI's code the game calls runs behind a guard, a step
  (`Safe`, `Guarded`) or the door it came in by. An error at a door that no step caught stands the module it
  came from down (`StandDown`: `off`, `GiveBack`, kept and told once); Core's own is told once under the door's
  name and Core goes on.
  - The module is found by the error's place: the first module folder its message or trace names
    (`Interface/AddOns/SaneUI_<Module>/`), so a step of Core that a module called is the module's.
  - Doors: game events (each listener on its own, as before, now caught by Core instead of only going to
    `CallErrorHandler`), `Core.Later` (its function was unguarded), a module's `OnLoad`/`OnLogin`/`OnLogout`
    (a failure now stands the module down, not only notes it; a failed `OnLoad`, or a stand-down before it,
    still keeps the module from being started further), and new `module.Guard(fn)`: a guarded function for
    scripts, hooks, timers and callbacks (nothing once the module stood down, all results passed on).
  - What slipped past every guard and reached the game's error window (Core listens there) is no longer only
    noted as "Lua error": it stands its module down too, and Core's own is told once as "Core". A Lua warning
    of ours is noted only (`Lua warning`).
  - The game's error window shows an error caught at a door only when the CVar `scriptErrors` is on, as for
    every addon; then it is not noted a second time. Players get no pop-up from Sane UI.
  - `/sane` lists a module that stood down as *stopped* (was *failed to start*, for a failed `OnLoad` only).
  - Event listeners of a module that stood down still hear their events: Social's channel wishes and the
    Tooltips' mouse switch work beside the game's own on purpose (they run `Safe`).
- Abilities: `ns.GiveBack` (leaves the spellbook to the game through `Book.StandDown`, drops a drag, takes the
  ghosts off the bars; the reservations stay saved) and `ns.GIVEN_BACK`; the update's timer, the login timers
  and the book's and the drag's `OnUpdate` are `ns.Guard`ed; `Ghosts.Refresh` does nothing once the module
  stood down.
- Docs: the hard rule in `Doc/guides/addon-standards.md` (10, with the table of doors) and Core's README.
- Tests: `dev/tests/core.lua` 344 checks (the doors, the module named by the error's place, the game's error
  window both ways, `Later`), `dev/tests/abilities.lua` 344 (its give-back). The stand-in shows Lua errors
  (`scriptErrors` on), so an error caught at a door still ends a test run unless the test collects it.
- Every module's doors guarded, and the lint holds them to it:
  - `dev/tests/lint` (check 6): in a module's folder, every function given to `SetScript`, `HookScript`,
    `hooksecurefunc`, `C_Timer.After`/`NewTimer`/`NewTicker`, `RegisterCallback`, `Menu.ModifyMenu`,
    `MenuUtil.CreateContextMenu`/`HookTooltipScripts`, a menu's `CreateButton`/`CreateCheckbox`/`CreateRadio`/
    `AddInitializer` (also through `pcall`) is `ns.Guard(fn)`, a name set to one, `nil`, `GameTooltip_Hide`, or
    a function whose one step is `ns.Safe`/`ns.Guarded`; an intended exception says `-- unguarded: <why>` on
    its line. Documented in `addon-standards.md` (10).
  - Abilities: the book's buttons, checkbox, hooks on the game's spellbook, the item's scripts and menu, the
    spellbook menu's lines, the window's hooks, the ghosts' hooks and the trainer's timer, 41 in all.
  - Tooltips: the tooltip hooks are `ns.Guard`s now (were functions running `Guarded`), the panel's `OnUpdate`,
    the driver's, the models' scripts and the inspect hook. The chat link's tooltip still closes on a click
    after a stand-down: its mouse-up runs `Safe`, its two flags are marked.
  - Social: the contacts' menus, scripts and callbacks, the input line's hooks, the window's `OnUpdate`, timer,
    scroll callbacks and size, the emote picker, the chat hooks and the native chat's hooks, 60 in all; the
    list on the chat's name opens and keeps the channel wishes after a stand-down (`Safe`), as before.

### Sync and the CVar list made again from Blizzard's options code (Saneroki, 2026-10-18)
- `Settings/Data/CVarLabels.lua` and `Sync/Data/Pages.lua` were made from older options code than
  `references/`, so both `--check` runs failed (noted at 1a.2). In the code now: the floating combat text's
  options for you are one dropdown of choices (a table of rows) instead of a checkbox per CVar, those for the
  target a menu; the gamepad's action bar options are gone; *Auto Ranged Combat* (Combat), the voice chat
  service and its Discord setting (Audio) are new; remote text to speech's tip is made in code; the button that
  shows the tutorials again writes three more tutorial CVars.
- `CVarLabels.lua`: 225 CVars (was 239), what the master's set *CVarLabels* already holds: new
  `autoRangedCombat`, `voiceProvider`, `voiceUseDiscordSettings`; gone the floating combat text's 12 checkboxes
  and the gamepad's 5 action bar options; `remoteTextToSpeech` without a tip.
- `dev/tools/sync-pages`:
  - Reads the TOCs with the load group `mainline` too, as `dev/blizzard/export.py` does
    (`[AllowLoadGameType mainline]` loads, `[ExcludeLoadGameType camelot]` does not). New pages: *Ping System*
    and *Advanced Options* (Gameplay), *Text* (Accessibility). Both Gameplay pages are Forever's:
    `Blizzard_PingUI` loads for `mainline`; *Advanced Options* is the only page with the swing timer, the
    cooldown viewer and the damage meter, which the game's camelot overrides switch on.
  - A CVar the options name through a variable counts by the names the file gives it: a local or a field set
    to it, a function's parameter, a column of a table's rows. So *Combat* keeps the floating combat text's 20
    CVars, *Social*, *Gamepad* and Accessibility's *Audio* and *General* get the ones they name so (censored
    messages, the gamepad's camera and stick sliders, combat audio alerts, the smallest name size), and
    Accessibility's *Subtitles* comes in.
  - `Pages.lua`: 15 pages and 259 CVars (was 11 and 197). A CVar that is now on a page leaves *Other
    per-character settings*.
- Tests: `dev/tests/sync.lua` 90 checks (the pages of `mainline`, a file left out for camelot, CVars named
  through a variable).

### Development: Blizzard updates, the todo list of a new build (Saneroki, 2026-10-18)
- `dev/tools/blizzard` (new, Python in `dev/blizzard/`): a new build's Blizzard interface code against
  `references/BlizzardInterfaceCode`, and what of the difference reaches Sane UI.
  - `check [<new>]`: the todo list in `dev/blizzard/reports/` (Markdown and JSON, not committed): broken (gone,
    or a name Blizzard's code no longer mentions), deprecated (with what the stand-in calls), changed
    (parameters, API arguments, returns and flags, payloads, structures, template keys, enums), review (hooked or
    used code that changed, with its diff; atlases no longer named), housekeeping (the TOCs' Interface number, the
    made files, notes citing changed Blizzard files, the adopt).
  - `show <name>`, `uses [--list] [--unknown]`, `adopt` (the new export into `references/`, with a `.build` note,
    and CVarLabels and Pages made again). `--old git:<revision>` compares with a commit's `references/`.
  - Reads exports as this client loads them (game type camelot with the group mainline) and the API
    documentation whole; Sane UI's globals by `luac5.1`'s listing.
- `dev/tools/cvar-labels`, `dev/tools/sync-pages`: `BLIZZARD_CODE` reads another export than `references/`.
- `Doc/guides/blizzard-updates.md` (new): the pipeline, the sections, how both sides are read, the limits.
- Tests: `dev/tests/blizzard.py` (new, in `dev/tests/run`), 74 checks.

### Aliases and notes of players (Saneroki, 2026-10-18)
- `Core/People.lua` (new, in Core's TOC): *Set Alias* and *Set Note* under the game's lines of its menu of a
  player.
  - `Menu.ModifyMenu` on every `MENU_UNIT_*` tag of a player: a chat name, friends, the guild and
    communities, the target, focus and group, recent allies, scoreboards.
  - Each asks in the game's input dialog (`Core.AskText`); empty text takes it away.
  - Kept for the account in `SaneUIDB.modules.SaneUI.people[key]`, by `Core.PlayerKeyOf`; personal, never
    shared.
  - API: `Core.People.Alias`, `Note`, `Shown`, `Set`, `Watch`.
- Social:
  - The alias shows above a bubble, inside the speaker's link (`Bubble.Speaker`), and the chat's search
    finds it.
  - The friends list shows it in place of a character friend's name, and of a Battle.net friend's
    character.
  - A change redraws both.
- Tooltips: a player's alias stands in the name's place, with the character's name small under the guild,
  then the note.
- `Doc/guides/data.md`: aliases are personal data. `Doc/ideas/Social.md`: the guild will show them.
- Tests: 330 checks (Core), 426 (Social), 460 (Tooltips); the stand-in's menu button keeps its tooltip.

### Ideas: a verified fact keeps its day and times (Saneroki, 2026-10-18)
- `Doc/ideas/Data.md`, *Verified and unverified*: a version keeps only the day of the import that last
  confirmed it and how many imports did (`"verified":{"day":...,"times":...}`), no list of confirmations. One
  count per import, only for a confirmation seen after that day, so a saved file taken in twice counts once.
  Whole reads of the client's files verify but do not count again, so a new build leaves the master's lines
  alone. Watchers note confirmations in the pack's saved file (`confirmed`); the harvest stages them.
  `Data-build.md` 1c.1 and 1c.3 take it in.

### Ideas: when in doubt, left out (Saneroki, 2026-10-18)
- `Doc/ideas/Data.md`, new *When in doubt, left out*: a batch's fact is taken in only if exact, agreed and
  current; contradicting, imprecise (rounded positions or chances, too few sightings), vague, overlapping,
  questionable or old facts are dropped before the import, never `--take`n, and stay where they were read with
  the reason. The older games' facts fall back only where they pass and Forever's client agrees. *Verified and
  unverified* now applies to what passed; a place seen once or a chance from too few loots is a candidate,
  not a fact.
- Decision 28: the quests and drops taken in as *old* fail the rule but stay, unverified, until the game's own
  data or a batch that passes replaces them entry by entry; the one exception.

### Ideas: verified and unverified facts, gathering nodes (Saneroki, 2026-10-18)
- `Doc/ideas/Data.md`, new *Verified and unverified*: a fact the game has not confirmed in its own game version
  (a batch, the older games' baseline, a place seen once, a chance from too few loots) is marked unverified
  and shown so; the game agreeing makes it verified without a new version; unverified versions are listed per
  source.
- New *Gathering nodes*: herbs, ore and other nodes have drop tables like creatures (gathers, chance and yield
  per gather and per visit); places merge by yards (a sighting near a known place is that place, a new one
  needs a second sighting; 8 yards, measured on known spawn points, the place whose mix holds the type
  first; fishing pools only to a cell), keep their spawn mix, and give what gathering routes need.
  `Data-build.md` 1d.3 takes it in.

### Ideas: an auction house per game version, Forever's per ruleset (Saneroki, 2026-10-18)
- `Doc/ideas/Data.md`, *Realms and regions*: every game version has its own houses (live, beta and PTR never
  share one); Forever has one realm per ruleset and region, so its house is game version, region, ruleset and
  side, named by the ruleset's realm number.

### Data: game facts apart from personal data (Saneroki, 2026-10-18)
- `Doc/guides/data.md`, new *Game facts and personal data*: the packs hold facts about the game, shared by
  every player; characters, progress, settings, the auction log and players' names are the player's own and
  stay on the computer. Learned facts are stripped where they are gathered; sharing and the harvest read only
  learned data and series. `Doc/ideas/Data.md`, *Harvest*: game facts only.

### Leveling: the plan for our own routes (Saneroki, 2026-10-18)
- `Doc/ideas/Leveling.md`: a tool that computes the leveling route from Core's quest, spawn and travel data,
  a simulator to measure it, what has to exist first, the order of work. Nothing built.

### Tooltips: your character beside gear, Gathering, binding in Gold, Addons with Alt (Saneroki, 2026-10-18)
- **Gear keeps its icon** (`Figures.lua`): no more character in the picture's place. With Alt held over a piece
  you can see on a character, your own character wearing it stands beside the panel (`Panel.Stage`): a
  `DressUpModel` on a dark ground like the panel's, as high as the panel, at its left (its right where the
  left has no room or the comparisons stand there: `Host.CompareSide`), turning slowly (one turn in ten
  seconds). Given your character once and kept while hidden; dressed anew in what you wear and trying the
  piece on each time it is shown; unseen until loaded; a piece your character cannot wear leaves none.
  Followed every frame (`Watch`), so Alt and the comparisons move it at once. New head field `dress`; the
  frame `panel.dresser` and the kind `dress` are gone.
- **How an item binds and whether you have its look** stand in the first row of *Gold* (`Gold.Terms`): the
  binding at the left (red until bound), the look at the right. Over the name only *Equipped*, on a
  comparison, which shows no binding.
- **Other addons' lines** (*Addons*) are shown only while Alt is held (`Read.lua`).
- **Gathering** (new `Gathering.lua`, `Kinds/Object.lua`): on a herb or an ore in the world, the skill it needs in
  the colour of your chance of a point (the game's difficulty colours: red, orange, yellow, green, grey),
  your skill after it, and at the right where each colour begins (what it needs, +25, +50, +100); on what
  nodes give, each node by name, the easiest first (Alt: all). Your skill from `C_SkillInfo`. The game's own
  line of the skill is left out on a node's tooltip.
- **Core's data:** 47 herb and ore nodes in `assets/data/Objects` (name, kind, skill line, the skill they need;
  source `hand`), what each gives in `assets/data/Drops` (`object:<id>`, `how = "gather"`), taken in through
  `dev/tools/data import`; the set *Objects* has the index `byName` (a thing in the world is known by its name).
- Tests (439 checks): Addons only with Alt; gear and the stage (size, sides, loading, turning, dressing, refusal,
  not asked again each frame); binding and look in Gold; Gathering on nodes and ores, every colour, a bonus,
  skill changes. Sample nodes in `dev/tests/data/tooltips/Objects` and `Drops`.
- `src/Tooltips/README.md`: the list *To check in the game* is gone (CLAUDE.md, *Trying it in the game*).

### Social: panels on the full screen (Saneroki, 2026-10-17)
- 2026-10-18 — Social: the group finder is the friends panel's last tab, *Group Finder*
  (`Contacts/Finder.lua`, a view of `Contacts`).
  - Its category and refresh button stand on a line of its own under the tabs, and its three foot
    buttons share the panel's width.
  - The switch *Group finder* (now under *Friends list*) offers the tab or takes it away, back to
    Friends.
  - The finder's own panel is gone, and so is `Layout.FINDER_WIDTH`.
  - The friends panel stands at the full screen's right, and the chat left of it (`Layout.Board`).
  - TOC: `Contacts\Finder.lua` in place of `Finder.lua`. Tests: 423 checks (Social).
- 2026-10-18 — Social: the full screen's friends panel holds all of the game's friends list: your BattleTag, status, broadcast, contacts menu; tabs Friends (favourites, invite button, tooltip, filter), Recent Allies, Requests (add friend, accept/decline/block), Raid (groups by drag, assistants, Raid Info), Quick Join; ignore list; search box and filter (`Friends.lua`, `Contacts/`). Handoff: `Doc/handoff/Social-friends-panel.md`.
- **Standing full, the chat window holds panels around the chat** (`Board.lua`, `Layout.Board`): the friends list
  at the left, the group finder at the right, a second chat above the chat. Each is a plate in Sane UI's look
  (`Core.Skin`) with a head; built when first shown, out of sight at the window's size, never sized on the
  way (they come in once it stands, go when it starts back). Too narrow a screen leaves out the group finder,
  then the friends list; too low a one the second chat. Each part runs under `ns.Safe`: a failing panel is
  noted, the chat goes on. The full window's search goes to every panel.
- **The chat stands in a frame of its own** (`Window.lua`: `column`, `Area`, `Seat`, `Lay`): the list, the button
  for the line to write in, the line (`Input.Take(frame, room, chat)`) and the smiley (`Picker.Take(frame, area)`)
  hang on it; measured by its size, not the window's.
- **Friends list** (`Friends.lua`), as the game's (Camelot's `FriendsFrame`): Battle.net and character friends in
  its order, status icons, the game's icon, the online count; a click chooses, *Send Message*, *Invite*
  (`FriendsFrame_InviteOrRequestToJoin` for Battle.net), the game's right click menu, *Add Friend*.
- **Group finder** (`Finder.lua`), as the game's vanilla-style browse view: a category, refresh, the listings
  (leader in class colour, activity, comment, members); *Send Message*, *Invite* a player alone, *List
  yourself* (the game's finder, `ns.OpenFinder`). `C_LFGList.Search` is restricted: called only on a click.
- **Second chat** (`Feed.lua`): its own ticks (setting `split`, `Channels.Split`/`FlipSplit`, the filter dropdown
  on its head), the chat's bubbles and width, no fading.
- **Settings** (*General*, section *Full screen*): `boardFriends`, `boardFinder`, `boardFeed`, `feedShare`; *Group
  finder* in *Classic windows* (`ToggleGroupFinderFrame`, `LFGVanilla_ShowFrame`).
- **Tests:** the stand-in's scrolling list is one per list (`boxes`); friends, Battle.net and group finder
  stand-ins; 22 new checks.

### Profiles anew: Accountwide settings (Saneroki, 2026-10-17)
- **Accountwide settings** (on at first): every character uses a profile, a named set of the settings of
  every module and of the game's own that Sync keeps (CVars, Edit Mode layout, chat windows, ...). At first
  there is one, *Accountwide*, used by every character, so all of them have the same settings; more can be
  made and given to characters, each its own. Off: no profile is in use, each character keeps its own Sane
  UI settings (a copy of its profile's to begin with, made anew each time it is switched off: `ownSince`,
  `since`) and Sync reads and writes nothing of the game's.
- **One place for each module's settings** (`Profiles.lua` rewritten): the table a module holds
  (`Core.Settings`, `store.options` through a metatable, never kept twice in the saved file) lives in the
  profile in use or the character's own. Another profile, Accountwide switched, the profile in use deleted:
  `Move` captures the game's settings, leaves a copy in the old place, fills the held table from the new one
  and tells each module what differs (`changed` by deep comparison, or `replaced` once), then `moved`
  (Sync writes the game's). Nothing moves at the logout (only `capture`), so a logout listener reads the
  right settings in any order (was: the account's put back first). A character is keyed by its GUID (a key
  copied with a file loses), one the game names only at login moves to its own profile then, and a module
  read later binds its settings in the place in use (was: the account's, for its first session).
- **The page Profiles:** *Accountwide settings*; *This character*: its profile, *New*, *Rename*, *Delete*,
  *Defaults*, *Copy from*, *Export*/*Import* (a window with a line of text, `Core.Serial`, read letter by
  letter, never run); *Characters*: each with its profile, *Forget* (its line and what every module keeps
  for it), *New Characters* first. The tab *Accountwide* is *Game settings* (Sync's parts, per profile).
  Names are unique in any letter case. `/sane profile [name]`. Gone: *Load*, *Save*, *Duplicate*, *Load at
  login*, *Save at logout*, *Empty*, *SaneUI Defaults*, the per-module switches.
- **The first shape brought over once** (`SaneUIDB.version` 2): the account's settings (also those kept aside
  by a logout that did not finish) are *Accountwide* (a profile of that name keeps its under *Accountwide
  (old)*); a line keeps its profile where it loaded it at login; *All settings accountwide* unticked is
  Accountwide off with each character's own kept; a module's `store.version` is stamped into each copy.
- **Settings carry their shape:** `Core.Options(name, list, hooks)` with `version` and `upgrade(values,
  from)`, run on each copy as it comes into use, before the kinds are checked (`Core.Settle`), so a value
  whose kind changed keeps its meaning (was: reset to its default before the module's upgrade saw it).
  Tooltips (3) and Social (3) use it; `Profiles.Copies` remains for old code. What no description has any more
  goes; a description that cannot be right is noted. `Core.Set(name, key, value)`, `Core.Reset(name)`,
  `Core.Described`, `Core.Same`; option fields `validate`, `reload`, `button`, `multi`.
- Tests: Core 320 (the page, every step, next sessions, a character never seen, Accountwide off with two
  characters, upgrades, the first shape), Sync 88 (profiles keep the game's settings; off, nothing is read or
  written).
  - *In the game:* the page *Profiles* shows *Accountwide settings* ticked and *Accountwide* in use; a second
    character gets the first one's game settings after its login; `/sane profile` lists the profiles.

### Core's shared tools
- `Core.AfterCombat(key, fn, ...)` (now, or once the fight is over; the same key once), `Core.Owed`,
  `Core.Locked(frame)`, `Core.Restricted()` (combat or the game's restrictions, kept from the event's payload),
  `Core.Off`, `Core.OnUnit`/`OffUnit`; the game's blocked actions of ours go to the error log
  (`ADDON_ACTION_BLOCKED`/`FORBIDDEN`); the error log keeps at most 100 kinds; errors from before the
  settings add to the kept count. `Kit.lua`: `Core.Word`, `RGB`/`Hex`, `Pixels`, `Tip`, `Pool`, `Confirm` (with
  its own word), `AskText`, `Font`, `Sound`, `Lend` (a frame of the game's changed for a while and given back
  exactly; its alpha at once in a fight). `Core.Fuzzy.Plain`. The switch *Animations* on Appearance (off:
  nothing of Sane UI moves). A button *Reset window positions* on General.

### Windows (Core) and Social
- Windows: close and Esc wait for a fight's end; a first zone (`first.dock`, talk in the middle), standing clear
  of a held zone (`Window.CASCADE`); a motion whose frame is hidden is at its end at once; no full screen in
  Edit Mode; every module hook guarded; letting go is done once. One Esc stand-in for all of Sane UI
  (`Core.Escape`, `SaneUIEscape`; the profile window and the feedback window too). New: `window.inside`,
  `SetTitle`, module `buttons`, tabs (`Views.lua`, the game's tab system), `toplevel`, `insets`,
  `Window.All`/`ResetAll` (`/sane window reset all`), the holder (`Holder.lua`), Edit Mode selection and its
  dialog with *Reset To Default Position* and grid snap (`Selection.lua`), `Core.Watch`/`Core.Hover` (Expand on
  them), `Motion.Fade`/`Slide`, `Fuzzy.Filter`, `Skin.TILES` (was `Edge.TEXTURES`), Shape's fixed
  radius/`Follow`/`alpha`/`Round`, `Edge.Options(..., under)` with changes followed by Core, the corners a
  section of their own (*Window corners*, no longer greyed with full screen), key bindings (`Bindings.xml`).
  `/sane window` is a panel with two tabs. Tests: windows 351.
- Social: a `screen` window of Core's, docked bottom left at first, no bar of its own, the mouse by
  `Core.Hover`; *Chat window* the one switch for ours or the game's chat (`Core.Set`, `Window.Follow`); a key;
  bubbles on `Core.Shape` (`Plate.lua` gone), tiles `Core.Skin.TILES` (`ns.BACKS` gone), `Core.Lend` for the
  game's chat and edit boxes, `Core.Motion.Slide`, `Core.Font`, `Core.Tip`, `Core.Fuzzy.Plain`; its tab
  *Appearance* has the messages' look first, then *Expand window* and *Window corners*. Tests: Social 349.
  - *In the game:* whether units behind the chat window still get their mouseover (the window takes the
    mouse's motion for `Core.Hover`).

### Settings: every kind of switch, a search on pages in tabs, pages built when first shown
- `Settings.lua`: a switch on a list page is a proxy setting (`Settings.RegisterProxySetting`) reading `Core.Settings` and writing through `Core.Set` (checked, `validate`, `reload` offered, the page shown anew; was `RegisterAddOnSetting`). `Config.Kind` names its control: words, and numbers with `entry` (or without `max`), in a box to type into (`SaneUISettingsEntryTemplate`, Banner.xml, on the game's `SettingsControlMixin`; a string was a checkbox that failed when clicked), `multi` the game's dropdown of checkboxes, `button` the game's button row, `color` its swatch row. A row under several switches, or two steps down, listens to each (`AddEvaluateStateCVar`); `hidden` via `AddShownPredicate`; a slider writes its `unit`. Pages of our own are built in their first `OnShow` (was: at every first opening of the options); a module's canvas has `OnDefault` → `Core.Reset`. `/sane options` in a fight opens them once it is over (`Core.AfterCombat`).
- `Panel.lua`: controls kept per page (`Panel.Page`): a click shows its own page anew, `Panel.Refresh()` the pages shown, a hidden one when shown next. New `TabbedFrame` (the page Profiles uses it too), `Edit`, `multi` dropdowns, box tips, `PlaceBox`, `ShowBox`, `Step`, `Number`, `Written`; `Tooltip` hooks; `RGB`/`Hex` are Core's; `ROW` gone.
- `Tabbed.lua`: writes through `Core.Set`; `headerTip` on the box title; a number inline under a list, an unknown key, no checkbox or another tab is on a line of its own (was: an error that emptied the tab, or not drawn); the new kinds; `hidden` lines close up; a search box (`Core.Fuzzy`) and *Defaults* over the tabs.
- `CVars.lua`: the list made when its tab is first shown; filtered once per showing (was twice).
- `dev/tests`: wowstub initializer predicates, `CreateControlInitializer`, `CreateColorSwatchInitializer`, `AddCheckbox`, `CreateFromMixins`, the game's row mixins; core.lua: two modules for the options tests only.
- Polish: Tooltips gets sections (*When and where*, *What they show*, *Look*), General one for *Errors* and one
  for *Windows* with *Reset window positions*. Tests: Core 320.
  - *In the game:* `/sane options` in a fight opens the options when it ends; on *Social* the search finds *Fade-in time* by "fade in"; *Defaults* asks first.

### Core's data framework: listeners after the job, jobs with handles
- **Listeners after the job, jobs with handles, holes in lists.** A set's `OnStamp` listeners are told on the frame after it arrived, never inside the loader's job, so a listener may run `Steps.Check`. Its failure is noted as `data: <set> listener`. New: `Data.WhenReady(set, fn)` and `handle:OffStamp(fn)`. `Core.Steps.Run(name or options, fn, ...)` gives a job's handle (`:Stop()`, `:Running()`, `ms`, `frames`; `Steps.Stop`, `Steps.Paused`, `Steps.Jobs` gives handles). Options: `priority` (served first in every frame), `done(problem)` (also after an error), `error(problem)`, `label`. A stopped job never goes on. The scheduler pauses by `Core.Restricted()`, from the restriction event's own state, and asks the game nothing per frame but the frame rate. `Each` gives the job's handle, tells `done(problem)` and notes a failing walk under `data job Each <set>`. An empty element of a list or map is no value at its own place, of every type. No read raises on a pack's values of the wrong kind. `Data.Find` keeps its answers unless the game version or build changed. A set that cannot be had makes no text on `Get`. `/sane data show` keeps a text key text. Tests: Lua 175.
  - *In the game:* `/sane data` lists each job with its milliseconds and frames, and says when they wait.

### Sync: guarded CVar writes, found in steps
- **Guarded CVar writes, CVars found in steps, a missing layout kept.** Every CVar write goes through `Sync.SetCVar`: not locked or read only, a secure one not in a fight, each in a pcall. One the game does not take is noted once (`Sync: setting CVars`) and the rest are written. The Graphics, Audio and per-character CVars are found by the scheduler job `Sync: the game's CVars`, a few milliseconds a frame, skipping locked, secure and read-only CVars; what is given meanwhile is written once they are found. Chat windows and the action bars check saved values of an older shape before use. Layout follows `Core.EditMode`, and a kept layout this character does not have stays kept until a layout is picked. `Sync.Word` is `Core.Word`; `Sync.CVarsOf` is gone. `wowstub.lua`: `GetCVarInfo` reports `locked`. Tests: Sync 81 (88 with the profiles).

### Abilities and Tooltips on Core's shared tools
- **Abilities:** what a fight holds up asks `Core.AfterCombat` once under its own key; no file listens for
  `PLAYER_REGEN_ENABLED`. The game's page buttons and row of tabs are lent (`Core.Lend`); `Locked` is Core's.
  Switches: `ns.options = Core.Settings`; the menu, the page checkbox and `/sane ab pages` set them with
  `Core.Set` (an open options page follows); `ns.OPTION` gave way to `Core.Described`. Layouts ask in the
  game's `GENERIC_INPUT_BOX`/`GENERIC_CONFIRMATION` (`Core.AskText`, `Core.Confirm`); no dialog of ours in
  the game's list. Tips, pools and sounds are Core's (`Core.Tip`, `Core.Pool`, `Core.Sound`). Every word in
  `ns.TEXT`, the game's by `Core.Word`. Fixed: the checkbox's sound when unticked; an entry a fight held at a
  fallback kept its compact size. Tests: 339.
- **Tooltips:** pools on `Core.Pool` (a draw still hides only the last one's parts), hairline `Core.Pixels`,
  `ns.options = Core.Settings`; an ID line's fallback reading is `Core.Fuzzy.Plain`. Host's alpha ledger and
  the font dressing stay the module's (they work per draw, where a ledger per piece would cost tables).
  Tests: 363.


### Tooltips: every section named, one section Addons, 3D models (Saneroki, 2026-10-17)
- **Every section under its name.** The only dividers are captions: a row has no `rule` any more (`ROW` in
  `Model.lua` has `space` instead: the game's empty line inside a section is a small gap, `SPACE` in
  `Panel.lua`). `Read.Section(name)` opens a section under its caption, or stays in the one of that name;
  `Read.Rest` puts each of the game's lines into the section `ctx.name` names (default `Read.Named`:
  *Description* for a description, else *Details*), a new name opening a new section. Items: *Stats* (a
  weapon's DPS or an armour's armour, then plain lines), *Effects* (green, or the game's spell-trigger
  line kinds), *Set* (from a line `ITEM_SET_NAME` up to an empty or gold line: `PATTERN.SET_NAME`),
  *Description* (gold, `FlavorText`), *Durability*; *Gold* now also over a vendor's price alone and over a
  comparison's. Spells: *Stats* over the strips, *Description*. Units: *Status* over target, bars, buffs and
  experience. Buffs: *Duration* over the time bar. Quests: *Description*. Alt's numbers: *IDs*.
  `Read.Generic` has no sections (`ctx.flat`). `ctx.tones` is gone.
- **One section Addons, whatever an addon writes where.** The caption is *Addons* (`TEXT.ADDONS`, was
  *Other addons*). Where the game's data says where its lines stand (`lineIndex`, `ctx.placed`), a line
  that is none of the data counts as another addon's wherever it stands after the game's first line
  (`ctx.firstOwn`): an addon that writes right after one of the game's lines
  (`TooltipDataProcessor.AddLinePostCall`) no longer puts its line among the panel's sections. Where the
  lines are only found by their text, after the game's last line as before. An empty line among addons'
  lines is a gap.
- **3D model in tooltips.** The setting `models` is *3D model in tooltips* (was *Live 3D portraits*; same
  key, ticked at first). New `Figures.lua` (in the TOC after `Auction.lua`, and in the module's file check):
  which model a thing has (`head.model`, `modelKind`, `modelZoom`, `modelTurn`, in `HEAD`): a mount's (by
  its item or its spell, the game's mount collection), a pet's (by its item, the pet collection), and gear
  on your own character (dressable items: `C_Item.IsDressableItemByID`, or by where it is worn). `Figure` in
  `Panel.lua`: a `PlayerModel` for units (as before) and displays (`SetDisplayInfo`), a `DressUpModel` for
  gear (`SetUnit("player")` once, then `Dress` and `TryOn(link)`); the icon until the game has loaded the
  model (`OnModelLoaded`, `GetModelFileID`), the icon where `TryOn` or the load fails or the option is off.
- Tests: `tooltips.lua` 408 checks (`shape(panel)`: the rows with captions by name): every kind's sections,
  an item set, a gap, a hint without sections, an addon's line right after one of the game's lines (and
  where lines are found by their text), the 3D models of a mount, a pet, gear (dressed anew, a cloak from
  behind, a failed try-on, a ring without), a mount's spell, switched off, without icons.
  - *In the game:* a restart of the game: a new file (`Figures.lua`). See the module's README, *To check in
    the game* (Addons, Section names, 3D models).

### Tooltips on Core's data: quests, your characters' things, other addons' lines apart (Saneroki, 2026-10-17)
- **Other addons' lines in a section of their own.** Whatever other addons write into a tooltip stands
  last on every panel, under the caption *Other addons* (`TEXT.ADDONS`): small and quiet, in their order, an
  empty line among them a divider. `Read.Rest` now shows the game's lines only; `Others` in `Read.lua`
  appends the others' after the kind's rows and Alt's details, for every kind alike. Before, they stood
  among the panel's own rows: before a buff's time bar, before a quest's *Objectives*, between an item's
  sections and *Gold*. `Read.Caption` is the shared caption row (`Kinds/Item.lua` uses it).
- **Inventory.** New `Kinds/Inventory.lua` (in the TOC before `Kinds/Item.lua`, and in the module's file
  check): an item's section *Inventory* from Core's characters' data (`Data.Count`): every character of the
  account that has it, by its whole name (first name and surname, *Sane Lunatic*, never *Sane*) in its
  class's colour, you first, the others by name, the account's bank last; *Bags 12 · Bank 8 · Worn 1* at
  the right; *Total* with two or more; five without Alt. Shown panels are drawn anew when the characters'
  data changes (`Data.OnCharacters`).
- **Quests from Core's data (1b.2).** `Quests.lua` reads the sets *Quests* and *Drops*
  (`Data.Set`, `Keys` by `byStartNPC`, `byFinishNPC`, `byStartItem`, `byObjective`), asks for them at the
  login (`Quests.Start(redraw)` → `Data.Prepare`) and draws the shown panels anew when they arrive
  (`OnStamp`); the lists are kept until the quest log, the level or the data change. No quest part until the
  packs are there, none with *Data: Quests* switched off, no error either way. `Data/Quests.lua`
  (`ns.QuestFacts`, 546 KB) is deleted, and so is it from the TOC and the module's file check.
- Tests: `tooltips.lua` 383 checks, on sample packs compiled from `dev/tests/data/tooltips/` by the new
  `dev/tests/data/packs.py` (a module's sample lines on the real schemas); the quests before and after the
  packs load, the Inventory section, other addons' lines after a buff's bar and a quest's objectives.
  `wowstub.lua`'s client has the pack Characters, as every install has.
  - *In the game:* see the module's README, *To check in the game* (Inventory, Other addons, quests from
    Core's data). A restart of the game: new files (`Kinds/Inventory.lua`, Core's `Data/Characters.lua`)
    and a new addon folder (`SaneUI_Data_Characters`, `SaneUI_Data_Quests`, `SaneUI_Data_World`).

### Scripts/update: GitHub's newest into the game in one go
- **`Scripts/update`** (Saneroki: try a Claude cloud session's work in the game without the git steps)
  fetches from GitHub, switches to the branch named (`--latest`: the `claude/` branch pushed to last; one only
  on GitHub is made here), pulls it forward only, then runs `dev/build`. Changes not committed stop it; so does
  a branch that has gone apart from GitHub's, except a cloud session's, which GitHub may start anew: that one
  is taken as GitHub has it, and commits only this computer had go to a branch `saved/<branch>-<commit>`.
  `--list` shows GitHub's branches, newest first; `--no-install` and `--check` go to `dev/build`. Tried on a
  stand-in GitHub: up to date, behind, ahead, gone apart, a session's branch squashed and started anew with
  and without a commit of this computer's, a branch deleted on GitHub, no branch checked out.
  It is the first file of `Scripts/` in git; `.gitattributes` keeps that folder LF.

### Navigation
- **Handoff** for the session that builds it: `Doc/agent/navigation.md` (what it is, the build order with
  what blocks each step, what Core and its data still lack, the open questions without a proposal); linked
  from `Doc/agent/README.md`.

### Core's data framework
- **1c.4 Characters, for the Inventory (in part, ahead of 1c.1).** New `src/Core/Data/Characters.lua` (in
  `SaneUI.toc`): each character of the account by its GUID with its whole name (a first name alone never
  replaces a whole one), realm, class, race, level, side, the day last seen, gold, and its places packed
  (`item\031count\030...`): bags (with the reagent bag and the keyring), what it wears, its bank, and the
  account's bank. Marks from the game's events, read as the scheduler's job *characters* (the bank only while
  open, read again at close; what is marked read at the logout); counts worked out in steps once loaded.
  `Data.Characters()`, `Data.Character(key)`, `Data.Count(item)`, `Data.CharactersStamp()`,
  `Data.OnCharacters(fn)`. Kept in the saved variable of the new pack **Characters**, a *pack of saved data*:
  `packs.toml` `saved = true` (the check knows it), made even without sets, its TOC `## X-SaneUI-Saved: 1`,
  no sets line and no file (`compile.py`, the lint). In the game `Data.Saved(pack, fn)` hands Core's readers
  the pack's part of their game version once loaded; a part of a format Core does not read is set aside under
  `broken`; `SaneUIDB.data[game].saved[pack]` notes how much each part held at the logout, and a saved file
  gone since is reported at once (copy the `.bak` back). Still open: the auction log, own auctions, a
  character deleted in *Profiles*.
- **1b.1 The Quests master.** The Tooltips module's quest facts, taken in once as the batch `old`
  (`sources.toml`) by a script outside the project: 4,796 quests into *Quests* (`assets/data/Quests/`) and
  3,883 creatures' drops into *Drops* (`assets/data/Drops/`, pack World). A quest's objectives carry their
  number in the game's list (`index`, a new first part); `requires.quest` is a plain quest ID (28 quests are
  named only by requirements). A drop is a creature's item and its chance; the quests that want the item
  come from the Quests index `byObjective`. Every one of 110,647 answers of the old file compared equal
  through Core's codec and handles. The check leaves refs into a set with no entries yet (NPCs, Items) until
  that set has some. The compiler leaves out empty parts at a tuple's end, as it does a row's empty fields
  (Quests 1.0 → 0.9 MB, Drops 0.5 → 0.4 MB). Tests: tools 208, Lua 151 (packs of saved data).
  - *In the game:* `/sane data` lists *Data: Characters*, *Data: Quests* and *Data: World* as loaded soon
    after the login; `/sane data show Quests 7` prints *Kobold Camp Cleanup*.
- **Players by their whole name** (Saneroki: a Forever player is first name and surname, and players can
  share either). `Core.PlayerKey(unit)` and `Core.PlayerKeyOf(text)` give a player's key: on Forever the
  first name and surname as one, any realm dropped (the whole name is unique across the region), nil for a
  name without its surname; on Retail `Name-Realm`. `Core.Surnames()` tells which (the Forever project, or
  `RegionalUniqueNamesEnabled`). `Core.FullName` no longer joins a Retail realm as a surname. The guide's
  new section *Players* makes it the database's rule: senders of shared data, their limits, quarantine,
  three senders and strikes by key; own characters by GUID; never a first name or surname alone. The plan
  (*Poisoning*, *Characters*) and steps 1c.4, 1f.1 and 1f.4 say so, with their tests. `/sane data` says how
  the client names players. `wowstub.lua` gains `UnitNameUnmodified`, `UnitIsPlayer` and
  `RegionalUniqueNamesEnabled`. Tests: Core 221 checks (Forever and Retail keys).
  - *In the game:* `/sane data` ends its first line with *players by first name and surname (regional
    names: yes)* on Forever.
- **1a.7 Every set's schema.** `assets/data/` holds the schema of every set of the plan, 28 in all, empty
  but checked: Items and ItemSets; Quests; NPCs, CreatureSpells, Objects, Zones, Travel, Places and Drops;
  Spawns, QuestAreas and PatrolPaths; CreatureSpawns; Walking; Guides; Spells, Auras, Trainers, QuestSpells,
  WeaponSkills, SkillLines and Professions; Talents and Legacy; Vendors; Currencies beside CVarLabels.
  `packs.toml` names their 11 packs. Their fields follow the plan's tables, Navigation's and today's data
  files in Abilities and Tooltips; prompt 2 settles them against the game. An index may now name a part of
  a list of tuples (`byItem = "goods.item"`; `schema.py`, `compile.py`), and an entry is listed once per
  value. The guide lists the sets with their keys (*The sets*). The Game pack now carries `Currencies.lua`,
  with no entries. Tests: tools 205 (every set of the plan in its pack; a tuple's part indexed, and the
  rules for it), Lua 143.
  - *In the game:* `/sane data` lists *Data: Game* with CVarLabels and Currencies.
- **1a.6 Versions in full.** In the game (`Data.lua`): `History`, `At`, `Versions`, `Changes`, `Keys` and
  `Each` (a job of the scheduler, two walks at once), every record with the patch its build is; a pack newer
  than the client answers with what the client's build has reached, in all of them; `Data.Find` tells the
  build anew and forgets the answers made from it; `/sane data show` prints what changed, by patch. The
  import (`dev/data/importer.py`) takes in every case: changed (also between two versions, the later lines
  kept to what they still change), older (put in front), gone (never from a batch), an entry back after
  gone, replaces, and conflicts listed or written in with `--take`; live first, so another game version
  stands on the import's live. A staged line without a day reads as its build's newest version
  (`master.current`). New `dev/data/views.py`: `dev/tools/data show`, `diff` and `stats`. Tests: Lua 142
  checks, tools 200 (each import case within its game version, `--take`, the three views).
- **1a.5 Packs in the game.** `src/Core/Data/Codec.lua` (a pack's row into a record, every type the
  compiler writes; a broken row read as far as it goes, never an error) and `src/Core/Data/Data.lua`
  (`Core.Data`), both in `SaneUI.toc` after `Steps.lua`: packs found by their TOC lines; the client's game
  version told by `WOW_PROJECT_ID`, `IsBetaBuild` and `IsTestBuild` (none told: every pack refused); a pack
  of another format or game version refused, one switched off left off; `Data.Set` handles with `Get`
  (never loads; the newest version the client's build has reached), `Stamp`, `OnStamp`, `State`, `Ready`,
  `hash` and `build`; `Prepare` as a job of the scheduler, after the loading screen, one pack a frame, out
  of combat; `Data.Add` for the set files; records made on first ask and kept weakly, frozen in the tests;
  every failure said once (missing and off quietly, the rest in chat). `/sane data` names the game version
  with what told it, the packs with their state and their sets' hashes, and the jobs; `/sane data show <set>
  <key>` prints an entry. `wowstub.lua` gains the addon list (`GetNumAddOns`, `GetAddOnInfo`, metadata and
  enable state per addon, `W.AddPack` and `LoadAddOn` of a compiled pack) and the client's game version.
  New `dev/tests/data/sample.py` compiles the sample master for the Lua test; `dev/tests/data.lua` 114
  checks (the codec reads back every row of both game versions as the tools meant it, the cases of loading
  and refusal, frozen records, `/sane data`).
  - *In the game:* `/sane data` names the game version (`forever-beta` on the beta: the check of what
    `IsBetaBuild` and `IsTestBuild` answer there) and lists *Data: Game*, not loaded; `/sane data show
    CVarLabels autolootdefault` asks for the pack, and the same again a moment later prints its entry
    (`label = AUTO_LOOT_DEFAULT_TEXT, ...`).
- **1a.4 The scheduler** `src/Core/Data/Steps.lua` (in `SaneUI.toc` after `Demo.lua`), `Core.Steps`: every
  long piece of the framework's work a job, a coroutine (`Run`, `Check`, `Fresh`, `Spend`, `Running`,
  `Jobs`); at most 5 ms a frame for all jobs and never more than a quarter of a frame at the frame rate, by
  `debugprofilestop`; each job its turn first in some frame; nothing in combat or while the game restricts
  addons (not for chat's restriction), the jobs going on after; a job that errors is dropped and reported,
  the others go on; its frame shown, with an `OnUpdate`, only while there is work. `wowstub.lua` gains
  `debugprofilestop`, `GetFramerate` and `C_RestrictedActions`. New `dev/tests/data.lua` (34 checks), run
  by `dev/tests/run`.
- **1a.3 Compile, and packs in BUILD.** `dev/data/compile.py` and `dev/tools/data compile <folder> [--game]`:
  a pack per `packs.toml` entry with entries (TOC, a Lua file per set, `LICENSE.txt`); rows, history and
  indexes (`replaces` and `replacedBy` the compiler's own), at most 50,000 statements per `Fill` function,
  the hash of the file itself, the newest build, the patch names; the same master gives the same bytes.
  Another game version's packs stand on live's newest version of each entry. `dev/tools/data game <folder>`
  tells a game folder's game version by its `.flavor.info`. `dev/build` makes `BUILD/SaneUI_Data_Game`,
  keeps the packs out of its clean-up, and installs the packs of the game folder's own game version (the
  beta's compiled into a scratch folder), removing packs it no longer makes. The lint compiles the packs of
  every game version and checks their TOCs and Lua. Tests: 148 checks (same bytes twice, live without the
  beta, the beta on live, every row read back by Lua 5.1 as Python wrote it, rows cut into functions,
  packs without entries not made).
  - *In the game:* the addon list shows *Data: Game* under Sane UI, not loaded.
- **1a.2 The master and its check.** `assets/data/` with `builds.toml` (Forever live 70245, the beta 70425
  and 70450, an empty PTR), `sources.toml` (`game`, `hand`), `packs.toml` (*Game*) and the first set,
  *CVarLabels* (225 CVars, from the game's options code in `references/`; the old Lua file stays as it is).
  `dev/data/` (Python, no package needed): `schema.py` (types and values), `master.py` (reading, versions
  worked out whole, another game version over live's newest, writing), `check.py` (the rules across lines),
  `importer.py` (staging: new entries and agreeing ones, the rest from 1a.6). `dev/tools/data check` and
  `import`; `dev/tools/cvar-labels --staging`. `dev/data/staging/` is not committed. `dev/tests/run` runs the
  check and `dev/tests/data/tools.py` (106 checks: every rule broken once on a sample master, the import's
  cases within their game versions, CVarLabels up to date with `references/`).
  - Found: the committed `CVarLabels.lua` (239 CVars) is not what `dev/tools/cvar-labels` makes from the
    committed `references/` (225; `--check` fails): it was made from other options code. Left as it is.
- **1a.1 The guide** `Doc/guides/data.md`, the reference from now on: the master in `assets/data/`
  (`builds.toml`, `sources.toml`, `packs.toml`, a schema per set with its types, a line of the master, fixes,
  another game version's files), staging and every case of the import, the check, a pack's TOC and set file,
  a row, what a module reads (with `OnStamp` for a view that redraws, as Navigation asked, and `State`),
  loading, the scheduler's jobs, the saved variables, messages and clocks to come, and how to add a set. The
  plan's *Contracts* now point to it. `Doc/agent/README.md` names it; `AGENTS.md` and `CLAUDE.md` (local)
  were handed over edited.
- **The plan's open decisions answered** (Saneroki, 2026-10-17), written into `Doc/ideas/Data.md`:
  - as proposed: packs as load-on-demand addons (1); saved variables declared by the packs (2); the
    auction history archived in the master and shipped back (6); the limits' numbers as start values to
    tune (12); a changed drop chance starts the whole history anew (13); 10 a second and 250 ms (15); areas
    as cells with 3 % around spawn points (17); the beta's batches as live's base (27);
  - otherwise: the master in `assets/data/`, the engine in `src/Core/Data/` (3); the packs not committed, as
    `BUILD/` is not (4); sharing with the guild, the party and the raid (9); every other creature's spawn
    points in a pack of their own, `SaneUI_Data_CreatureSpawns`, so Spawns stays lean (18, Navigation's
    open question 11).
  - `Doc/ideas/Data-build.md` follows; a cloud session pushes each commit to `main`.

### New designs across the modules (Saneroki, 2026-10-17)
- **Abilities, trainer data:** `Data/Classes/*.lua` are hand-edited in a new format: one string per spell
  family with its ranks in order (`"spell:level:copper"`; a bare spell is a rank the trainer does not sell),
  ordered by first level, then spell ID, plus a small conditions table per class (`talent`, `after`,
  `alone`, `side`, `raceIDs`) that holds from its rank to the end of the family.
- Abilities: `Data/Trainer.lua` reads the families at login into one list, `D.spells`, filtered by faction
  and race, and links each rank to the next. `D.Learned` counts a rank as learned when it or a later rank
  is known, for every class. `D.FamilyName` (numerals I-XX checked against the rank line) replaces
  `D.BaseName`. Dire Bear Form is Bear Form's next rank.
- Abilities: spell states are `trainable`, `level`, `talentfirst`, `spellfirst`, `quest`, `talent` and
  `other`, checked level first as in the game's spellbook. A spell that needs another spell first names it.
  Shift-click links use the game's spell link only. Quest reward rows use `raceIDs`.
- Abilities, fixed: the hunter's trainer list held 45 pet abilities, shown as grey hunter spells. An unused
  field on rogue poisons is gone.
- **Tooltips, palette:** built from the game's font colours by one mixing rule (`ns.COLOR`, `ns.Mix`,
  `ns.Like`). Spell schools take the combat log's colours. The background is the game's tooltip ground
  tinted by the panel's colour.
- Tooltips: a spell's first strip shows only the facts its tooltip states, read through the game's own
  sentences (every language), in the game's order. The computed numbers are in a second strip, with a cell
  only for a known value.
- Tooltips, layout in four steps (Measure, Picture, Lay, Finish):
  - width in steps of 8 (224-432), wrapping at 22 ems;
  - a row's right side gives way to its left;
  - strip cells sized by their words;
  - section names left-aligned with a rule;
  - hairlines from `PixelUtil`.
- Tooltips: `Native.lua` is now `Host.lua` (`ns.Host`), and a comparison's panel stands beside the other
  by the game's side.
- Tooltips: a description is found by its line type, else as a gold sentence, and only its digits are
  coloured. Auras are found through a getter table and coloured by what removes them.
- Tooltips: a player's side is a word on the race line (the emblem is gone). Rank words come from the
  game's strings, and a rare elite shows both. The target's name follows "Target". Pools are `{ taken }`
  lists with one `Take`. Quest icons are named `available` and `active`, after the game's gossip icons.
- **Tooltips, quest facts:** `ns.QuestFacts` has a new shape:
  - one record per quest, `levels;rule;races;classes;title`;
  - prerequisite signs `+` (done), `/` (one of) and `!` (closed);
  - the game's race and class IDs;
  - NPC and item records as lettered groups;
  - 546 KB instead of 686.

  Drop chances are whole percent, `<1%` below one. Quests the game repeats are offered by no NPC. An item's
  quest list names each quest once.
- Tooltips, quest availability: the game's class and race IDs, its trivial range for grey quests, and the
  quest's own min level. Fixed: Skyborne characters now get the quests meant for their race alone.
- Tooltips, spell numbers: the description is read as numbers with the words between them. Per second
  means cast again and again, and the spell's own global cooldown counts where the game gives it. Crit is
  the one spell chance this client has. Kill experience comes from one table by level. The kills line
  reads "Next level in N".
- **Core, motion:** the kinds are Glide (default), Swing, Even and Instant, each a time and one of
  Blizzard's easing curves (`EasingUtil`). An unknown saved kind falls back to the general one.
- Core, Expand: a window opens once the mouse has rested on it (0.2 s) and closes 0.5 s after it has gone.
  A watch frame checks the mouse only in between. `expand:Stay(on)` keeps it open.
- Core, Bar: drawn with the game's experience bar atlases (the fill over the part still to come, its pip,
  dividers, the flare flipbook). A gain rises for 0.35 to 1.1 s, depending on its size.
- Core, Skin: windows stand on the tile of the game's dark dialogs, under the bronze trim. `/sane window`
  opens on rest, has a *Keep open* box, and a bar that *Add* fills.
- Core, Fuzzy: ranks are whole numbers, from 600 for the whole text down to 100 for spread letters, plus up
  to 90 for a close fit. One pass through the text. The API is `Rank` and `Highlight` (in
  `NORMAL_FONT_COLOR`).
- Core, CVars tab:
  - over the list: a search box and the game's filter button;
  - two-line rows, the value edited in place, an undo arrow back to the default;
  - details in the row tooltip; status and count under the list.

  `CVarLabels.lua` holds `{ label, tip }` entries written by `dev/tools/cvar-labels`.
- Core, errors: the chat line reads "problem in <label>, noted in the error log (/sane errors)."
- **Sync:** one part per options page of the game (Gameplay, Accessibility, System), named in the game's
  words. Edit Mode layout, own channels, chat windows (now with their places) and the other per-character
  settings are under "Elsewhere in the game".
- Sync: what each page sets is generated from Blizzard's options code by the new `dev/tools/sync-pages`
  into `src/Core/Sync/Data/Pages.lua` (`--check`). "Other per-character settings" keeps every CVar the
  game stores per character that no page holds (`C_CVar.GetCVarInfo`).
- Sync: settings are `off` / `taken` / `named`; settings saved in the earlier shape are not read. Files:
  `Sync.lua`, `Layout.lua`, `Chat.lua`, `Game.lua`, `Data/Pages.lua`. `Parts.lua` and `Switches.lua` are
  removed.
- **Social, game channels:** set in the list on the chat's name ("On every character": The game decides /
  Always in it / Never in it), listed from the game; setting `presence`. A channel is joined only where the
  game offers it (`EnumerateServerChannels`), asked once per zone, and joining reacts to the game's channel
  notices.
- **Plans (`Doc/ideas/`):**
  - Economy: market value from prices seen selling between two scans, else the median of the days' lowest
    offers, with far days left out by the median absolute deviation. Days of stock. Views Buy, Sell,
    Auctions, Movement, Sales. Post next and Reprice, one click each.
  - Data: the characters' data grouped by when it is read; the auction log (`Data.AuctionLog`); quest
    areas grouped by touching cells; sizes left to measure.
  - Navigation: Blizzard's map-legend and vignette atlases for quests, rares and chests; a "Seen at" line
    for rares; overlapping pins gathered into one marker; walking data as a graph of points by region;
    guides made by our tool; the section *One pin per thing*.
  - Lore: a library of what the player read and heard (Tales, Writings, Overheard, Lands, Peoples, Halls,
    Cinematics), search over it, voice packs by level band, rules of its own.
  - Dialogue: one Continue binding while the box shows, paragraphs at a reading speed, answers under the
    words, rewards compared inline, a veil instead of hiding frames.
  - Windows and Sane Sync: Blizzard's own panel backgrounds as a background choice; sample voices taken
    from the cast.
- Repository: `references/BlizzardInterfaceCode/` (Blizzard's interface code, 46 MB) is committed, the rest of
  `references/` stays local. `.gitignore` keeps all of `.claude/` and Python's `__pycache__/` out, and `*.zip`. The root
  README lists five addons and links the Social README.
- Not yet tried in the game: everything above. The in-game checks are listed in each module's README.

### Images: one pipeline for concept art, interface parts and animations
- Saneroki asked (2026-10-17) for a pipeline on this computer's ComfyUI that keeps Sane UI's art alike.
  New `dev/imagegen/`:
  - `style.txt`, the house style: the look of the concept art in words; its picture, the anchor, is
    `assets/Concept art/Elements.png`.
  - `recipes/`: one per step, each a workflow by name, its settings and its fixed words: `concept` (from
    the anchor), `concept-free`, `part` (cut out of the set's concept), `part-new`, `part-clean`, `anim`
    (Wan 2.2 14B, a loop on the part), `anim-5b`, `effect` (Wan-Alpha, transparent).
  - `sets/example/`: a set from concept to parts to an animation, to copy for a new set.
- `dev/tools/imagegen`: a list can `include:` a recipe and name its `workflow:` (looked up by name in
  `dev/imagegen/workflows/`, then in ComfyUI's folder), `set:`, `count:`, `seed:`, `out:`, `fps:`,
  `flatten:` (references with transparency laid on a colour) and `before:` (text before each prompt).
  It saves a clip as a folder of frames with a `.gif` preview, and writes `contact.png` (a row per prompt,
  a column per seed) and `imagegen.jsonl` (how each picture was made). The old form, workflow first, stays.
- New `dev/tools/flipbook`: a clip's frames as a flipbook sheet, its sides powers of two, the frame's
  side from the drawn size as `Doc/guides/images.md` sizes it; loops by fading the end into the start or
  dropping a repeated last frame; `--glow` keeps only the added light, for additive blending over the still
  part; a `.gif` preview and the FlipBook's numbers.
- `dev/tools/art`: kind `sheet`, a flipbook kept whole (power-of-two sides, TexCoords 0-1).
- `Doc/guides/image-generation.md` rewritten: the pipeline, what keeps a set alike, ComfyUI and the models
  as installed and timed here, the house style, the recipes and the words found for them, a set step by
  step, the list, animation and flipbooks. Licence notes left out.
- New `dev/tests/imagegen.py` in `dev/tests/run`: the list's lines, every recipe and set, the flipbook's
  grid, sizes and loops (no ComfyUI needed).
- Tried with the example set: a concept, parts cut out of it, a looping glow packed as a flipbook, and an
  effect. Not tried yet: a flipbook in the game.

### Voices: the voice tool, and short sounds
- New `dev/tools/voicegen` (Saneroki, 2026-10-17): the voice tool of the Lore plan, Python's standard library
  and `ffmpeg` only.
  - `design` and `pick`: a preset's voice from its design prompt in `dev/voices/cast.md`, three previews to
    listen to, the one picked kept as a voice of our account and noted in `dev/voices/voices.json`.
  - `names`: `dev/voices/names.md` as two pronunciation dictionaries (respellings for every model, the sounds
    for the models that read them), sent again as a new version only when the list changed.
  - `say`: the voice database's lines, 3 requests at a time, with a dry run, a guard above 20,000 characters,
    and a stop when the key is wrong or the credits run out. Each file is known by the hash of all that shapes
    its sound, so nothing is paid for twice; `dev/voices/made.jsonl` notes each file's request and characters.
    The service's sound is kept as it came (`dev/voices/sound/master/`, with the timing of each character),
    and the game's file is cut to the speech, evened to -18 LUFS, and made Ogg Vorbis at 22.05 kHz.
  - `sound` and `ogg --ui`: short sounds for windows as candidates in `assets/generated/sounds/`, and the
    game's file of the one chosen (starting at once, short fades, the peak at -1 dB, 44.1 kHz).
  - `key` and `account`: the key is asked for without being shown and kept in
    `~/.config/saneui/voice-service.json`, readable by its owner only, with the service's address and models;
    nothing of it is in the repository.
- `dev/tools/voicedb`: `requests` gives the requests as data for the voice tool; `request` prints them as before.
- `Doc/guides/voice-generation.md`: new sections *The voice tool* (setting it up, the models, making the
  voices, what is kept) and *Short sounds* (the game's own first, then the service, a local model or
  `ffmpeg`, and the game's file); `Doc/guides/gui-development.md`: a sound of our own only where the game has
  none.
- `.gitignore`: `dev/voices/sound/` and `dev/voices/design/`.
- Tests: 17 checks of the voice tool in `dev/tests/voices.py` (what is sent per model, the hash, the
  dictionaries, the part kept); the whole flow tried against a stand-in for the service.

### Ideas: prices per auction house, the game's facts for every realm
- `Doc/ideas/Data.md`, new section *Realms and regions* (Saneroki, 2026-10-17).
  - **For every realm, kept once:** the game's facts (items, quests, NPCs, spells, places, vendors' fixed
    prices, drop chances), per game version only.
  - **Per auction house:** what players make (scans, the price series, sales). A house is named by game
    version, region, realm (or its group of connected realms) and side. No price of one house is used, shown
    or averaged into another's.
  - A realm's kind (PvP, roleplay, hardcore) needs nothing of its own. A self-found character scans
    nothing.
  - *To check in the game:* split by faction, neutral houses, connected realms.
  - *Series*, the API comment, *Saved variables*, *Messages* and *Tests* follow it.
- `Doc/ideas/Data-build.md`: 1c.2, 1e.1 and 1f.2 carry it.
- `Doc/ideas/Economy.md`, *The history*: per auction house.
- `Doc/ideas/SaneSync.md`, *A server*: facts merged once, prices per auction house.

### Ideas: data of game versions kept apart
- `Doc/ideas/Data.md`, new section *Game versions kept apart* (Saneroki, 2026-10-17): Forever live uses only
  what Forever live showed, never a discovery of its PTR or beta.
  - Every fact belongs to one game version (`forever`, `forever-ptr`, `forever-beta`).
  - The master keeps the PTR's and the beta's versions in files of their own.
  - Packs are compiled and installed per game version, by the folder's product.
  - Core refuses a pack of another game version.
  - Saved data is keyed by game version first.
  - The harvest, messages and backups keep it apart.
  - The clock is the reason: the beta's builds (70450) are higher than live's (70245), so a beta fact would
    have become a live version, and live's patch check would have stopped.
  - *Words*, *Files*, *Staging*, *Import*, *The patch check*, *Tests* and *Contracts* follow it.
  - New decision 27: data gathered on the beta counts as live's base (`since` 0); the rest of the beta's
    own data stays the beta's.
- `Doc/ideas/Data-build.md`: the commits that touch facts carry it (1a.2, 1a.3, 1a.5, 1a.6, 1c.1, 1c.3,
  1f.1).
- `Doc/ideas/SaneSync.md`: each game version gets its own data packs; a backup goes back only into its own
  game version; data from beyond the guild keeps its game version.

### Ideas: Sane Sync: finding the game, several game versions
- `Doc/ideas/SaneSync.md`, new part *Finding the game* (Saneroki, 2026-10-17), from the game folder on
  Saneroki's computer: an installation (`.build.info`, one row per game version) holds game versions in
  folders of their own (`_forever_`, product `wowf`; `_classic_beta_`, Forever's beta), each with its own
  addons and saved files. The game told by the version, live, PTR or beta by the product; the interface
  worked out from the version.
- Found through Battle.net's own list of installed games (`product.db`), then the usual places (every drive,
  every Wine prefix); shown to the player to confirm; otherwise a folder the player picks or types, checked.
- The player chooses which game versions get Sane UI (Forever's now, retail's later), any number at once in
  any number of installations, each with its own channel, pin, rollback and backups; an update waits only
  for the game version that runs. Sane UI put there by hand or by `dev/build` is taken over only after a yes.
- *In the background:* the same program and background work on Windows, macOS and Linux; tried on real
  Windows and Mac computers before players get it.

### Voices: how lore names are said
- `dev/voices/names.md` (new): 247 lore names (77 places, 96 people, 45 peoples and gods, 29 words), each with
  a respelling for the voice service's dictionary, its IPA and a note; 61 marked unsure, to be checked by ear
  in the trial. `dev/tools/voicedb` matches a name with an *'s* after it too, and its `names` command lists
  the names the texts have and the list lacks, without everyday contractions. Tests: 97 checks (voices).

### Ideas: Sane Sync: the computer set up, measured, two processes
- Saneroki's computer set up for the app (2026-10-17): the web view, the tray menu's library, `minisign` and
  the Tauri command line from Arch's own packages. A test program (tray, window, every planned plugin and
  crate) built and ran.
- `Doc/ideas/SaneSync.md`, *How it is built*: what was measured (the program 7.5 MB, 2.4 MB packed; a tray
  process that never made a web view about 25 MB; the window open about 220 MB; WebKit's helpers stay after
  the window closes). So **two processes, one program**: the background one never makes a web view, the
  window is the same program started again and ends with its window. Known pitfalls met in the test (NVIDIA
  on Wayland, the last window ending the program, the updater's settings, `reqwest`'s TLS feature, the size
  settings). Linux's web view plays Ogg Vorbis.
- New part *Setting up a computer*: what Arch, Debian and Ubuntu, Fedora, macOS and Windows need; the signing
  key made once when publishing starts.

### Voices: the voice database, the cast, the directions
- `dev/tools/voicedb` (new), the voice database: a workbench for making the voice overs, apart from the
  game's data and never shipped (`Doc/guides/voice-generation.md`, new; asked for by Saneroki, 2026-10-17).
  It reads its staging files (`dev/voices/staging/`), the cast, the names, the fixes and the directions, and
  writes `dev/voices/build/` (`lines.jsonl`, `voices.sqlite`): every text in parts, who says it (race and
  sex from the speaker's model, the kind from its name, title or class), its preset, the words ready to say
  (placeholders, stage directions, the player's sex), its tone, intensity, pace, volume, register, tags,
  stability and direction, and what a person should look at. Commands `stats`, `show`, `request` (what would
  be sent to the voice service), `batch` (lines for a language model to direct), `names`, `check`.
- `dev/voices/cast.md` (new): 98 voice presets (4 narrators; 64 for the playable races, by sex and by the
  kinds common, martial, refined and elder; 30 for other peoples and creatures), each with its design prompt
  and design text for the voice service, its settings, its delivery and what to avoid.
- `dev/voices/analysis/northshire.jsonl` (new): the 53 parts of Northshire's quests, directed by a language
  model with the guide's prompt.
- The numbers today: 26,229 parts voiced, 4.31 million characters, about 80 hours of speech, about $345 on
  the newest model and $172 on the fast one.
- `dev/tests/voices.py` (new, run by `dev/tests/run`): 94 checks of the cast, the words, the parts, the tone
  and the presets. `.gitignore`: the build, the staging files and the voice packs. `Doc/ideas/Lore.md` points
  to the guide.

### Ideas: Sane Sync: built with Rust and Tauri 2
- `Doc/ideas/SaneSync.md`, *How it is built*: the proposal is now Rust with Tauri 2 (stable; its own plugins
  give the tray, the start with the login, the app's own signed updates, one app at a time, the folder picker
  and notices), a window of plain HTML, CSS and JavaScript in the system's web view (no Node), and a table of
  what does what: downloads, minisign signatures for the manifests and the app alike, zips, file events for
  the saved files, the game's process, a reader of our own for saved files (never run), sound for the
  samples. Weight, what Saneroki's computer needs, the packages, and why not Go with Wails (its tray needs
  Wails 3, still in beta), a tray without a window, a bundled browser or others.

### Ideas: Sane Sync: hear a sample of the voices
- `Doc/ideas/SaneSync.md`, new *Voice packs* under *Updates* (what was a line in *Giving out a version*): the
  packs offered one by one and updated file by file; and Saneroki's button *Hear a sample* (2026-10-17): five
  samples, one per press, in a circle, the narrator and four voices of different races, sides and sexes, with
  the speaker, the pack and the words shown while it plays; made by the voice tool with the packs, about 80 KB
  each. `Doc/ideas/Lore.md`, *Downloading and updating*, points to it.

### Ideas: Lore: the voices are downloads of their own
- `Doc/ideas/Lore.md`, *Voice packs*: Saneroki (2026-10-16): the voices are Sane UI packages of their own,
  downloaded separately; Lore plays a voice only when it finds its package installed.
  - Packs titled *Voices: ...*; each holds its sound files and the index of its own lines (the `Voices`
    set is gone from `SaneUI_Data_Lore`).
  - Found at login from the addon list and the packs' TOC lines (`X-SaneUI-Voices`, `X-SaneUI-Format`) without
    loading them; a missing pack is silent, listed on Lore's page, no popups.
  - Not in git: built into `BUILD/SaneUI_Voice_*/` (ignored), left alone by `dev/build`, the sound kept safe
    outside the repository; the cast, the names list and the list of what was made are committed.
- `Doc/ideas/SaneSync.md`, *Giving out a version*: the app offers the voice packs one by one, installs only
  those picked, and updates them file by file.

### Ideas: Lore: what the voices cost and weigh
- `Doc/ideas/Lore.md`, *The estimate*: the game's texts (5.9 million characters, 100 to 125 hours) about $470
  on the newest model or $240 on its fast version, 1.8 to 2.2 GB as mono Ogg Vorbis at about 40 kbps
  (22.05 kHz, silence cut); with our own places and library about $590 / $300 and 2.2 to 2.8 GB. Sizes at
  other rates.

### Ideas: Lore: where the texts come from, the voice service
- `Doc/ideas/Lore.md`: Saneroki chose a cloud voice service for the AI voices (2026-10-16);
  `dev/tools/voicegen` sends the texts through its API. New parts *The texts* and *The service: cost and
  form*, researched today:
  - Almost every text comes from the server, not from the client's files. The original world's texts are
    Blizzard's own (Blizzard's IDs); Forever's own from a quest sweep (`RequestLoadQuestByID` over
    `QuestV2`'s 6,614 IDs, read back from `questcache.wdb`, whose layout was checked here), the hotfix cache,
    the client's `MailTemplate` and `ConversationLine`, and in play (progress and hand-in texts are sent only at
    the NPC).
  - About 6 million characters, about 100 hours of speech: about $480 on the newest model, $240 on its fast
    version, about 2.2 GB as mono Ogg Vorbis; a trial of a few hundred lines first.
  - Placeholders, male and female texts, racial languages, lines Blizzard already voiced.

### Ideas: Lore
- `Doc/ideas/Lore.md` (new): Saneroki's idea of a module **Lore** (2026-10-16): voice overs with AI voices, a
  library about the world and its lore, and lore tidbits in tooltips and other places.
  - Data is Core's (`SaneUI_Data_Lore`: the sets `Lore` and `Voices`; Core's watchers keep the books, talk
    and movies the player saw); each module shows tidbits in its own views; everything by the game's IDs.
  - The library: chapters by kind of lore, filled by playing, no spoilers.
  - AI voices made before on this computer (`dev/tools/voicegen`) and shipped as sound packs, about 2 GB;
    played only while the game's text still matches its hash, in parts, one queue, a voice bar; the game's
    text to speech as the fallback.
  - Open questions for Saneroki at the end.

### The page Sane UI: links and feedback
- `Settings/About.lua` (new, in Core's TOC after `Synced.lua`): under the banner of the page *Sane UI*,
  the sections *Community* (Discord, Website, GitHub) and *Feedback* (Report a bug, Suggest a feature,
  General feedback), the game's own section headers and button rows (`Config.Fill` calls `About.Fill`).
  - A link's *Copy link* shows its address selected in the game's `GENERIC_INPUT_BOX` (an addon cannot
    open a browser; `CopyToClipboard` is restricted). The addresses (`About.LINKS`) are empty for now:
    their rows say *Coming soon*, the button off.
  - A feedback button opens `SaneUIFeedbackFrame` (`ButtonFrameTemplate`, `InputScrollFrameTemplate`, made
    when first opened, Esc closes it). *Make report* turns what was written into a report to copy and
    paste on GitHub or Discord: versions, language, modules, class and level (no name), and for a bug the
    5 newest errors. Writing is kept per kind for the session.
  - `/sane feedback [bug|idea|note]`, `/sane bug`.
- `Settings/Settings.lua`: calls it; heads say so. `Settings/README.md`, `Doc/agent/core.md`.
- `dev/tests/wowstub.lua`: `ButtonFrameTemplate`, `InputScrollFrameTemplate`, `CLOSE`, `GetLocale`,
  `tinsert`, `ButtonFrameTemplate_HidePortrait`, `InputScrollFrame_SetInstructions`, two sounds.
- Tests: 207 checks (Core).

### Social: the button Sane UI on the game's chat; no title on the small window
- `Social.lua`: `ns.NATIVE` now has `frame` (the strip of buttons left of the game's chat,
  `ChatFrame1ButtonFrame`), `back` (ours shown again, the switch *Chat window* on) and `anchor`.
  - Core's button *Sane UI* stands just above the game's chat menu button and fades with the game's buttons.
  - A click brings our window back.
  - The line said when ours is put away names the button.
- `Window.lua` (Social):
  - The button is shown only while our window is away (`Back`).
  - Off at login, the window is made out of sight, so the button is there (`Window.Away`).
  - The small window's bar has no title *Social* any more (Saneroki).
- `Core/Window.lua`: `native.anchor(button)` says where `Attach` puts the button, for a game window
  without a close button. `Doc/guides/windows.md` says so too.
- Tests: 336 checks (Social).

### The name Sane Sync in the licence; licensing left to Saneroki
- `LICENSE`, section 2: *Sane Sync* is a name kept to Saneroki like *Sane UI*; an addon or app built from the
  code carries another name (Saneroki, 2026-10-16). The builds' `LICENSE.txt` follow.
- `AGENTS.md`: the licence rule is replaced by Saneroki's new one: agents do not handle licensing unless
  Saneroki asks (it stands over every earlier licensing note).
- `Doc/ideas/SaneSync.md`: the licence questions taken out; the name in the `LICENSE` noted as decided.

### Ideas: the app is Sane Sync; Sane UI is open source
- `Doc/ideas/App.md` renamed `Doc/ideas/SaneSync.md` (Saneroki, 2026-10-16: the app is called **Sane Sync**;
  not Core's Sync). Saneroki: the repository is public and fully open source, anybody may fork it and add
  code. New part *Open source*: only Saneroki's versions carry his signature, code from others comes in by
  pull request, a fork gives out its own versions with its own key, host and name; GitHub Releases and
  GitHub's build service as the proposal, the build service only building, signing on Saneroki's computer.
- Open question: *Sane Sync* in the `LICENSE`'s name section.

### Ideas: Onboarding: the switch and the ?
- `Doc/ideas/Onboarding.md`: Saneroki answered two questions. After an update What's new opens by itself,
  unless *Show what's new after an update* is off on the module's own page (put up by Core at login, as the
  module loads on demand). Help comes from a ? in a window's title bar, before the button to the game's
  own window, only in the Sane UI view: Blizzard's help plates over the window (this client hides
  Blizzard's own ? buttons); no tips by themselves, no `HelpTip`. `Doc/ideas/Windows.md`, *Title bars*:
  the ? noted.

### Ideas: the Sane UI app
- `Doc/ideas/App.md`, new (Saneroki, 2026-10-16): a small program for Windows, Linux and macOS, outside the
  game, that keeps Sane UI up to date. Proposals: versions given out as one signed zip per addon folder
  (Ed25519, the key only on Saneroki's computer; a folder that did not change is not downloaded again),
  installed only while the game is closed; channels, pinning and rollback with the saved files from before
  the update; daily backups of Sane UI's saved files; a tray icon and the start with the login per system;
  Go. It only reads and writes Sane UI's own files and never touches the running game.
- **Beyond the guild,** smallest first: Blizzard's web API for prices (to check for this game), a hidden
  realm channel, then a server through the app. Data goes out through an outbox the addon fills and comes
  back as a data file the app writes (never code), taken in like one more guild member's.
- The order of work and Saneroki's open questions (name, folder, hosting, defaults).

### Windows: Saneroki's answers to the review
- **Kinds of window** (Core, `Window.KINDS`): `kind = "screen"` (the chat, the minimap), `"panel"` (the
  spellbook, the guild, the bags), `"talk"` (a vendor, the bank) gives a window its kind's options; the
  module's own win. What the Combat module shows (unit frames, nameplates, buffs, action bars) is no window.
- **A dock zone holds one window at a time** (Core, `Dock.Hold`, `Dock.Holder`): while a window is docked
  there and shown, a drag offers the zone to no other (no shape; let go, it stays free), and a window opening
  with that zone kept stands free that time. Windows not shown hold nothing, so the talk windows share the
  middle.
- **Ours or the game's, never both** (the plan and the guide): a window does not replace the game's; it is
  set to one of the two and only that one is seen. Core keeps the game's out of sight by Economy's holder,
  made one way for every window (to build): held under a hidden frame while closed, the game opens and
  closes it unseen, Core follows by hooks after its `Show` and `Hide`. Override bindings, buttons over the
  micro menu and `RegisterPlayerInteraction` are not taken (the last needs a `/reload` to give back).
- **Full screen views:** the board per module, as proposed, is decided.
- Tests: 234 checks (windows).

### Windows reviewed: the guide, and what the review fixed
- **`Doc/guides/windows.md`**, new: how every window of Sane UI is built, for whoever builds the next one.
  The kinds (HUD, panel, talk) and their options, Core's parts and the module's share, the states and the
  invariants that keep them apart, what is kept, the recipe, the rules (taint with the game's own windows,
  combat, performance, resilience, look), what is not built yet in order, and every fact it rests on with
  the Blizzard file it was checked in. Linked from `AGENTS.md` and `Doc/agent/core.md`.
- **Core, fixed by the review:** a window holding the game's protected frames is not moved, sized, shown or
  hidden in a fight (`window:Locked()`: no drag, no sizing, no full screen, `Place` waits for the fight's
  end, a full screen motion on its way is finished as the fight begins, `Open` says `"locked"`). Esc closes
  a window made so (`escape = "close"`, one stand-in in `UISpecialFrames` for all). `Reset` keeps what a
  window was left as (full screen, the game's own). Without the game's Edit Mode `/sane arrange` gives our
  windows the same mode. Edit Mode's boxes of ours hide and show with Blizzard's when Edit Mode hides them
  for a while without closing (hooks after `ShowSystemSelections`/`HideSystemSelections`). Fuzzy: a score
  makes no tables (two kept rows) and each text is lowered once per match, about 10 µs a match.
- **Social:** the game's friends list in *Classic windows* is not asked for in a fight (the game refuses an
  addon then, "Interface action failed"); a line says to use the game's own key.
- **The plan (`Doc/ideas/Windows.md`) corrected:** Edit Mode's layouts are followed by one hook after
  `UpdateLayoutInfo`, keyed by preset number or type and name (a character's by the character too); Core
  never calls `SetHasActiveChanges` (its flag would be tainted) and enables *Save* and *Revert Changes*
  itself; Edit Mode works in a fight. The nine places, the middle, the title bars and Esc said one way
  throughout.

### Ideas: Onboarding
- `Doc/ideas/Onboarding.md`, new (Saneroki, 2026-10-16): a module of its own, loaded on demand when a new
  version of Sane UI is found, that helps players understand its features. Proposals: Core finds the new
  version at login (`SaneUIDB.seen`, per account, outside the profiles) and loads the module only then;
  Welcome the first time, What's new after an update, laid out like Blizzard's own splash; *Show me* per
  feature, one-time tips with `HelpTip`; the words in `News.lua`, kept in step with `changelog.txt` by a
  test. For later: Sane UI is not given to others yet. Six open questions, among them the name.

### The Navigation plan reviewed, and how it is built
- `Doc/ideas/Navigation.md` reordered: Saneroki's decisions, a review, the design, the build order, the
  reference, open questions with proposals (built as proposed if not answered). Every claim checked
  against `references/`. No code yet.
- **Corrected:** a canvas of our own instead of Blizzard's map canvas, whose pins call protected functions
  without a combat guard (a canvas made by an addon would raise blocked actions in a fight); the wheel
  never steps to the parent map there; no dungeon entrance pins from the game in this client; continents
  found at run time (the client's code names none); the native minimap's rotation ignored, not the CVar
  changed; positions read as possibly hidden; known flight points only from the flight master.
- **New in the design:** the three coordinate spaces; the layers and a holder that makes a pan one
  `SetPoint`; the small view on Blizzard's own hybrid minimap pattern; how the game's map and minimap are
  kept out of sight and given back, with the fight left to try; the planner and walking data in Core's
  scheduler and pack; the golden line's pulse as an engine animation; the leveling guide's secure item
  button kept out of the map window; what Navigation reads from Core; budgets, caps, tests, fallback.
- **Build order:** step 0 proves the risky parts in the game first (tiles, the native minimap's dots, the
  map key and a fight, hidden positions, the quest area frame, the frame time).

### Ideas: the Tooltips redesign reviewed, and how it is built
- `Doc/ideas/Tooltips/Build.md`, new: the review of the plan in `Types.md` and the plan for building it,
  checked against the module's code, the guides and Blizzard's API in `references/`. The pipeline (facts
  in the model, a pure `Look.lua`, the art as data in `Looks.lua`), every fact with its source, the
  rules and their order, the layers as drawn, falling back layer by layer, time and memory (about
  12 MB for all the art), the tests (every value has a look, no missing or dead art), the steps, what only
  the game can show, five choices open for Saneroki.
- `Doc/ideas/Tooltips/Types.md` corrected:
  - Things are known by IDs, not by their words: a creature type through `C_CreatureInfo`, an NPC's role
    and an object's kind from Core's World pack; the English words only until that pack exists.
  - The frame split into a border (stretched, corners kept) and a socket (fixed, round the picture);
    a unit's rank is its socket, which also covers the live model's square corners.
  - The ground a band at the top that fits every panel size; borders and sockets neutral metal for the
    accent; dead, ghost and offline desaturated.
  - One order of rules for items and a default for every item class; Mailbox and Holiday lose their
    grounds; the images counted again (still about 80).

### Ideas: Economy reviewed: checked against the code, a plan for building it
- `Doc/ideas/Economy.md` checked against Core's code, Blizzard's code in `references/` and
  `Doc/ideas/Data.md`. Corrected:
  - Hiding Blizzard's window: alpha 0 left its buttons taking the mouse and its place in the panel layout.
    Now a hidden parent set between talks, so the window never comes into sight and its `OnShow` and
    `OnHide` never run; tiny and clear in the middle of a talk; *Classic* gives it back to UIParent.
  - The talk's own events (`MERCHANT_SHOW`, ...) start a window: on this client the trainer and the auction
    house also open without the interaction manager.
  - Core already keeps *Classic* and full screen (`window:Open`, `Native`, `Remember`), and its title bar
    moves a window at any time; Esc closing a full window is Core's `escape = "close"`, being added.
  - Pets' species come from the link; the bank is this client's own `Camelot/BankFrame.lua`; the mailbox is
    not loaded on demand; the trainer's filters are shared with Blizzard's window.
- Added: the game's own item key for prices; links only for weapons, armour and pets; the scan's time in
  the server's clock; the size of a full history (about 45 MB a year) and what *kept in full* can mean in
  the game; market value and price to post; *sold between two scans* as an experiment checked against the
  player's own sales; buying only from the server's answer, the throttle, one click per post.
- New part *Building it*: who does what, a window's life as a table of states, what Economy needs from
  Core and the database (with what is done), rules for the code, the tests, the files, and the order of
  work with when each step is done (the vendor first, to prove the hiding).
- New wishes to the database (the scan's state, a stamp for series, one item key, a day's point from
  several scans) and a new open question (*kept in full*).

### The data plan: second pass, contracts and the build in commits
- `Doc/ideas/Data.md`, *Review*, new part *Second pass*. The formats, the limits of Lua and the client,
  and the rules that keep wrong data from staying, measured with Lua 5.1 where it says so. Corrected in
  the page's own sections:
  - rows cut by tab and ASCII 30/31, which no game text holds, instead of commas and `=`;
  - every version whole in the pack;
  - records kept weakly;
  - Lua's constant limit is per function: the compiler cuts rows into functions, and every saved variable
    keeps a budget of values;
  - compiling gives the same bytes for the same master: hashes instead of a dated release. The first
    of these corrections went in with commit 36c9f65;
  - learned data wins only while it is newer;
  - an empty answer is no fact;
  - days from the server's clock;
  - drop chances per corpse looted (`GetLootSourceInfo` is not in the client's code: to check first);
  - sharing: 90 messages a minute per sender, a random wait before *want*, the packed block capped, facts
    of a newer build wait, shared counts bounded;
  - jobs as coroutines, which never yield inside `pcall` (there is no `Core.Guarded`);
  - no licence line in a schema.
- New section *Contracts*: a master's line, a pack's TOC and Lua file, the answers' shapes, the saved
  variables, messages, clocks and jobs. Step 1a carries it into the guide.
- New `Doc/ideas/Data-build.md`: prompt 1's six steps cut into 25 commits, each with its tests and
  Saneroki's checks in the game, and how a session goes on where the last one stopped.

### Ideas: Navigation: leveling guide
- `Doc/ideas/Navigation.md`, new section *Leveling guide* (Saneroki, 2026-10-16): Navigation leads through
  leveling step by step, with the guides as Core's data (`Doc/ideas/Data.md`: set *Guides*, pack
  `SaneUI_Data_Guides`). What a guide and a step are, what Navigation does with them (proposal), step texts
  of our own, and the feasibility. Five new open questions, among them how the guides are made.

### Dialogue planned
- Saneroki's answers are in the page (2026-10-16):
  - Dialogue is a feature of Social, not a module of its own;
  - it stands in the middle of the screen (`CENTER`);
  - the rest of the interface is hidden by default, with a setting to keep it;
  - combat closes the dialogue;
  - books and letters (`ItemTextFrame`) are part of it.

  `Doc/ideas/Social.md` lists it.
- `Doc/ideas/Dialogue.md`: a new module (working name *Dialogue*) for talking to an NPC as a scene,
  standing for the game's gossip and quest windows. It covers:
  - the NPC's face, its words, and the answers;
  - quests and their rewards;
  - the keyboard, only while the talk is in sight and never in combat;
  - Economy's holder, with the way back to the game's windows.

  No code yet; the open questions are for Saneroki.
- `Doc/agent/README.md`: the page is listed.

### The data plan reviewed
- Saneroki agreed to decisions 19 to 26, and to English only (decision 7). The answers are written into the
  page's own sections: *Versions*, *Import*, *Loading*, *The game's own data*, *Learned*, *Performance*, *Files* and prompt 1's six steps.
- `Doc/ideas/Data.md`, section *Review*: the plan was checked against `references/` and Core. Corrected:
  - packed messages are made text (`EncodeBase64`) before sending, and the scan's cost is updated;
  - the send budget of 10 messages, then one a second, is Blizzard's own plan, not the server's limit.
- New decisions 19 to 26, built as proposed if not answered:
  - where learned data waits while its pack is not loaded;
  - `Get` never loads a pack;
  - hotfixes without a new build;
  - other languages;
  - items in tooltips;
  - domain code with its pack instead of Core;
  - the frame budget at high frame rates;
  - prompt 1 split into six steps.

### Nine dock zones
- `Core/Dock.lua`: the zones are the four corners, the middle of each edge (`TOP`, `BOTTOM`, `LEFT`, `RIGHT`)
  and `CENTER` (Saneroki, 2026-10-16). `TOP1`, `TOP3`, `BOTTOM1`, `BOTTOM3` are gone; `TOP2` and `BOTTOM2` are
  renamed `TOP` and `BOTTOM`. A window saved at an old name stands at its kept coordinates. `Dock.Anchor`
  needs no offset any more. Tests: 202 checks (windows).

### No banners for Abilities and Social
- `src/Abilities/Art/banner.blp` and `src/Social/Art/banner.blp` are gone, so the two modules' options pages
  show the game's own title instead of a picture (Settings looks for a banner and keeps the title without
  one). `dev/tools/art` still makes them in `assets/optimized/` but ships them to no module. The pictures
  in `assets/` stay. Social's smiley stays.

### Ideas: Economy: Hide Blizzard's window per window, Esc closes, mailbox, guild bank and bags
- `Doc/ideas/Economy.md` (Saneroki, 2026-10-16): moving, sizing and docking are Core's window system's, not
  the module's. *Hide Blizzard's window* is one switch per window. Esc closes a window, also in full screen,
  so the remembered view stays (Core needs a window option for it; `Edge` brings a full window back today).
  New section *More windows*: mailbox, guild bank and bags. Open: the two wishes to the database, and which
  module holds the bags.

### Ideas: quests, creatures and the map in the data plan
- **`Doc/ideas/Data.md`:** quests (requirements, chains, stages, breadcrumbs, places of the steps, quest
  areas as cells, the game's own area read by its point test), creatures (stats, abilities, buffs,
  services; what the game hides in combat), places on the map (spawns, services, rares, treasures, herbs
  and ore, flight points; one list per map), what every kill teaches (where, for which quest), and the
  beta's auction history pruned once on 1 November 2026, by hand with a prompt (no function of the addon).

### Ideas: Combat's first decisions
- `Doc/ideas/Combat.md` (Saneroki, 2026-10-16): Combat's frames are our own windows on Core's window system
  (unit frames and buffs without a title bar); the look is developed along the way; floating combat text,
  raid warnings, threat and the swing timers are Combat's too, each on demand (how, developed further);
  party style and click casting are decided during development. Their parts, the game's frames and what
  the reference says of them (combat text's event info is secret; the swing timers are this client's own);
  a window holding secure buttons moves and changes size only out of combat (for Core, to build). No code.

### Windows: title bars with a fuzzy search; what a window was left as
Tests: 330 checks (Social), 202 checks (windows). Not tried in the game. New file: restart the game.
- **Title bars** (Saneroki, 2026-10-16; `Window.lua`): `titleBar` (per kind of window; the small chat, unit
  frames have none) puts a bar `Window.BAR` (32) high across the window's top, `Window.BAR_LEVEL` above it, a
  thin bronze line under it: at its left a button with the game's magnifier (with `search`) and the
  `title`; at its right the buttons, which moved there from the window's corner (`chrome` and
  `Window.TITLED` are gone; the buttons show with the bar, not in Edit Mode). Every window that fills the
  screen has the bar at its top. A click on the title opens the game's `SearchBoxTemplate` over the bar up
  to the buttons (or Edge's dropdown), the cursor in it; every change goes to `options.search(text)`; Esc,
  or the cursor leaving it empty, closes and empties it (`search("")`). The bar (and the title: a press
  that became a drag opens no search) is `Window.Mover`'s handle: `window:Draggable()` (only with
  `titleBar`; not in Edit Mode, not while away; docked at a screen edge only with `dragDocked`), and such a
  drag docks only in `Window.DRAG_ZONES` (`CENTER`): `Dock.Watch(frame, only)`, `Dock.Find`/`Of` take `only`.
- **Fuzzy finding** (`src/Core/Fuzzy.lua`, new): `Query(text)` (the typed words), `Match(query, ...)`
  (every word in one of the texts: the total; nil), `Score(word, text, lower, places)`, `Mark(text,
  places)`.
- **What a window was left as** (Saneroki: every window remembers maximized or small, place, size, the game's
  own window or ours): `window:Remember(what, value)` in its place table (carried over by `Keep`): `full`
  (`Edge.Fill`), `native` (`window:Native(on)`, which the toggle buttons call now). `window:Open()`, for a
  module when the game asks for the window: `native.show()` if the game's was chosen, else ours shown and
  full again if it was left so (`"native"`, `"ours"`).
- **Edge:** the dropdown *Classic windows* in the title bar left of the buttons (`Edge.MENU_ROOM` gone);
  `Stand` refreshes the bar once the dropdown is there.
- **Social:** no title bar while small (Core's buttons left the small window); full, Core's title bar at the
  top (`search`: `Window.Search`, `Visible` keeps the messages `Core.Fuzzy.Match` finds every word in: their
  readable text, the speaker's name, the chat's), its own bar hidden (`Chrome`), the list under the title bar
  (`Top`).
- **`/sane window`:** a title bar (`titleBar`; its own title text gone), 60 high.
- Docs: Core's and Social's READMEs, `Doc/agent/core.md`, `Doc/guides/gui-development.md`, `Doc/ideas/Windows.md`
  (*Title bars*, *Full screen views*, *The game's own triggers*, the spellbook to be rebuilt on Core's window).

### Art: making pictures with image models
- `Doc/guides/image-generation.md` (Saneroki asked, 2026-10-16): local, free image generation for Sane UI's
  art. ComfyUI installed by hand (Python 3.13, CUDA 13), five models for a 12 GB card (Qwen-Image 2.1 as
  the main one: references and transparent pictures; FLUX.2 [klein]; Z-Image Turbo; SDXL; FLUX.2 [dev]),
  how to ask for interface art, and how a frame becomes pieces the game stretches (slice margins, nine
  pieces as in Blizzard's frame files). Researched, nothing installed or tried yet.
- `dev/tools/imagegen`: queues a whole set in ComfyUI from a workflow (API form, `{prompt}` and `{name}`
  in it) and a list (`name: prompt`, `style:`, `ref:`), the same seeds for every part; uploads the
  references (BLP turned into PNG), waits and saves `<name>-<seed>.png` with `--out`. Tried against a
  stand-in server only, not against ComfyUI yet.
- `.gitignore`: `assets/generated/` (what the models make). `AGENTS.md`, `Doc/agent/development.md`: the
  guide and the tool.

### Combat: a new module, set up
- Saneroki, 2026-10-16: a module **Combat** for everything about party, raid, buffs, unit frames, nameplates
  and pets. `src/Combat/`, addon `SaneUI_Combat` (`SaneUI_Combat.toc`, title *Combat* in the addon list,
  under Sane UI, needs Core only), first file `Combat.lua`: `Core.NewModule(ADDON, "Combat", ns)` and nothing
  else. It loads and changes nothing; no options page until its first part has switches. Module README.
- The plan: `Doc/ideas/Combat.md`: its parts and the game's frames each stands for in this client
  (camelot), the game's Edit Mode settings for them, what is secret in a fight, party and raid headers,
  buffs, nameplates; how every part works (the game's frame parented away, fallback, combat lock, present
  never compute, reads only, cheap, Edit Mode, one tabbed page); an order to build; open questions.
- `Doc/ideas/Windows.md`: the top left place (party and raid) is Combat's.
- `Doc/guides/addon-standards.md`, *Secret values*: corrected from the reference. `SetShown` and
  `Cooldown:SetCooldown` take no secret from addon code (`SecretArguments = "AllowedWhenUntainted"`); which
  widgets do (`AllowedWhenTainted`), and the game's duration objects for swirls and timer bars.
- `AGENTS.md`, `Doc/agent/README.md`, `Doc/agent/development.md`: five addons.

### Ideas: every look of a tooltip, from layers
- `Doc/ideas/Tooltips/Types.md`, section *Looks* (a proposal, after Saneroki, 2026-10-16: looks by element,
  creature type, class, race, rarity, kind of item, gatherables, chests): a look is put together from
  layers, each chosen by one thing: a ground (an element, a material, a creature type, a homeland, a
  profession), a frame (quality, rank, buff or debuff), the game's picture, an accent (the game's
  colour), marks (side, class, role, state, quest, a profession needed). Every dimension with all its
  values, the layer it chooses and how the module knows it (or that it does not read it yet), for items,
  spells, units, buffs, quests, world objects (herbs, veins, chests, mailboxes: a layout to come) and the
  rest; where a tooltip is shown changes rows, not looks. The list of images: about 80 (63 grounds, 16
  frames, a few marks) for every combination. No code.

### Ideas: Economy's windows, Classic remembered, the history in Core's database
- `Doc/ideas/Economy.md` (Saneroki, 2026-10-16): *Classic* is remembered per window, also across sessions;
  every Blizzard trade window has a button beside its close button back to ours (Core's `native` and
  `window:Attach()`). The windows open in the middle of the screen (`CENTER`) with Core's window handling;
  Economy fills them and sets their size; they are dragged, snap to the dock zones and keep place and dock.
  The full history is kept: the scan and the series *Prices* are Core's database's (`Doc/ideas/Data.md`),
  Economy only reads; its `Scan.lua`, `History.lua`, the size worries and *Keep history* are gone. Two wishes
  to the database (the last scan whole, sold between scans) and new open questions (dragging outside Edit
  Mode, a grip).

### Tooltips: live 3D portraits
Tests: 328 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **A unit's portrait is its live 3D model** (Saneroki, 2026-10-16: the first step of the redesign with templates per
  tooltip type, `Doc/ideas/Tooltips/Types.md`): `Figure` in `Panel.lua`, a `PlayerModel` in the portrait's place,
  64 large, `SetUnit` and `SetPortraitZoom(1)`. One per panel, made for its first unit; given the unit only when
  the GUID changes (again would reload the model and restart its animation), forgotten on hide. Where `SetUnit`
  does not return true (out of sight, hidden identity, an error: `Core.Ask`) or the client has no `PlayerModel`
  (`pcall`, not tried again), the flat `SetPortraitTexture` as before.
- The dragon, the plaque and the level stand on `panel.front`, a frame over the figure (a frame draws over its
  parent's regions); the level's pool text is lifted onto it (`Pools.Lift`) and put back on the panel when the
  pool uses it again. Frame levels each draw: figure the panel's + 1, front + 2.
- `Panel.Strength` sets the panel's alpha and the figure's by itself (a model frame need not follow its
  parent's); `Gate` in `Tooltips.lua` uses it.
- New option `models` (*Live 3D portraits*, on at first) on the page Tooltips.
- Docs: the module's README (setting, technical details, to check in the game, history),
  `Doc/agent/tooltips.md`, the plan in `Doc/ideas/Tooltips/Types.md`.

### Ideas: every tooltip type and portrait type, for the redesign
- `Doc/ideas/Tooltips/Types.md` (Saneroki, 2026-10-16): the Tooltips module is to get a new look from
  AI-generated art, keeping its data and layout. The page lists every type the module draws (items,
  spells, buffs, quests, the rest), how each is known, its look now and what it shows; the parts every
  design restyles; and, for units only, a table of portrait types (player, enemy, elite, rare, boss,
  pet, corpse, ...) with what the game says of each: race, gender, creature type and family, faction,
  reaction, rank, class, level. No code.

### Spellbook is Abilities
- The Spellbook module is renamed **Abilities**: its features will go beyond the spellbook. Folder
  `src/Abilities`, addon `SaneUI_Abilities` (`SaneUI_Abilities.toc`, title *Abilities* in the addon list and
  on its options page), first file `Abilities.lua`, `Core.NewModule(ADDON, "Abilities", ns)`. Commands
  `/sane abilities` and `/sane ab`; `/sane spellbook` and `/sane sb` stay as further words. Error labels
  `Abilities: ...`.
- Core (`Saved.lua`): `RENAMED` has `Spellbook = "Abilities"`, so everything kept under the old name
  (store, profiles, the account's and the character's settings) moves to the new one once at load.
- `dev/build` removes the old `SaneUI_Spellbook` folder from the game's AddOns folder; `dev/tools/art`
  writes the banner into `src/Abilities/Art`. The art files keep their names (`SaneSpellbook-*.png`).
- Unchanged on purpose: the spellbook's frames (`SaneUISpellbook`, `SaneUISpellbookHome`, ...) and
  texts about the game's spellbook; they name the spellbook, not the module.
- Tests: `dev/tests/spellbook.lua` is `dev/tests/abilities.lua`; it checks the move of the old saved
  settings and the old command words. Docs: READMEs, `AGENTS.md`, `Doc/agent/abilities.md` (was
  `spellbook.md`), the guides. 298 checks (Abilities).

### Windows: a dock place in the middle; buttons on free and centred windows
Tests: 327 checks (Social), 178 checks (windows). Not tried in the game. `/reload` is enough.
- **`Dock.ZONES.CENTER`** (Saneroki, 2026-10-16): the middle of the screen, touching no edge; a window let go
  with its middle within `Dock.REACH` of the screen's docks there, anchored by its centre. For the windows
  the player talks to (vendor, trainer, auction house: `Doc/ideas/Economy.md`).
- **Buttons** (`Window.lua`): a window free or docked in a zone of `Window.TITLED` (`CENTER`), Edit Mode
  closed, has a frame `Window.BUTTON_INSET` (4) from its top right corner, its parent `options.chrome` or the
  window, holding from the right: the game's close button (`UIPanelCloseButtonNoScripts`; `options.close`,
  else the window is hidden); with `edge` and *Can expand to fullscreen* on, the game's
  `MaximizeMinimizeButtonFrameTemplate` (`edge:Fill`; its look follows the window however it fills the
  screen or goes back: `window:Refresh()` from `Place`, `Edge.Fill`, `Edge:Update`, Edit Mode); with
  `options.native = { frame, show, back }`, the game's square button (`UI-SquareButton-*`) with its circling
  arrows (`UI-RefreshButton`), tip *Classic window*: `native.show()`. `window:Attach()` (also at `New`)
  puts the same button (tip *Sane UI window*: `native.back()`) on the game's window, beside its close button
  (`CloseButton` or the global *name*`CloseButton`, read raw), at its level: our frame, kept in our own
  table. Shown buttons stand side by side (`buttons.first`: the leftmost).
- **Edge:** a free or centred window fills the screen by its button (`placed`, was: only docked windows)
  and goes back to where it stood (`edge.left`, `edge.bottom`); full, the dropdown *Classic windows* stands
  left of the buttons.
- **Social:** `native = ns.NATIVE` (the game's chat: our window put away, as *Chat* in *Classic windows*),
  `close = ns.Close` (the same), `chrome = bar` (the buttons come with the mouse, as the bar); free or in the
  middle the list starts under them (`Top`).
- **`/sane window`:** its help names the middle and the buttons.
- Docs: Core's and Social's READMEs, `Doc/agent/core.md`, `Doc/ideas/Windows.md` (*The middle, and windows
  not docked*), `Doc/ideas/Economy.md`.

### Windows: moved and sized only in Blizzard's Edit Mode
Tests: 322 checks (Social), 158 checks (windows). Not tried in the game. New file: restart the game.
- **`Core.EditMode`** (`src/Core/EditMode.lua`, new, in the TOC before `Window.lua`): `active` and
  `Watch(fn)`, from the game's event registry (`EditMode.Enter`, `EditMode.Exit`, whose callbacks it runs
  through `securecallfunction`, so ours carry no taint into Edit Mode); at login it reads
  `EditModeManagerFrame:IsEditModeActive()` once (a `/reload` in Edit Mode). Edit Mode is never written.
- **`Window.New`:** no drag and no grip outside Edit Mode (`window.usable` is false there; the frame takes
  no mouse of its own: `bar` is gone, nothing calls `Window.Mover` on it). When Edit Mode opens, each window
  gets its box (`window.box`, made once): `Window.BOX_LEVEL` (100) above it, Edit Mode's art
  (`EditModeSystemSelectionLayout` from `Blizzard_EditMode`, copied, as it is local there; kit
  `editmode-actionbar-highlight`; `NineSliceUtil.ApplyLayout` on our own frame, not Blizzard's selection
  template, which would hand our frame to Edit Mode's manager), a copy at 0.4 added and the window's
  `title` (new option) while the mouse is on it. The box is what `Window.Mover` drags; the grip lies one
  level over it and is shown only in Edit Mode. A window filling the screen goes back when Edit Mode opens;
  one in hand when it closes is let go and kept (`Moved`, `Sized`). Without `NineSliceUtil` the box is
  there unseen.
- **Edge:** the screen's edge does nothing while Edit Mode is open (`Pushed`).
- **Social:** the bar is only the title (it takes no mouse); the grip left the chrome (Core shows it in
  Edit Mode); `title` names its box. Its tests move and size the window in Edit Mode.
- **`/sane window`:** its help and the command's line say *In Edit Mode*; `title` names its box.
- The place is kept at once when let go, as before: not yet in Edit Mode's layouts (`Doc/ideas/Windows.md`).
  The Spellbook module's own moving and sizing of the game's spellbook (`Window.Mover`, `Window.Sizer`) is
  as it was.

### Ideas: the Economy module
- `Doc/ideas/Economy.md` (new; Saneroki, 2026-10-16): a module *Economy* with windows of its own for the
  auction house, vendor, trainer and bank. *Hide Blizzard's windows* (ticked by default) and a *Classic*
  button on every window, always; expand and collapse, the last view remembered; Core's motion on
  opening. A full scan of the auction house every time it opens (the server allows one per 15 minutes,
  `C_AuctionHouse.ReplicateItems`), kept in a growing database of our own. Proposals: hiding Blizzard's
  windows without ending the talk with the NPC (their `OnHide` closes it), the database's three layers and
  its size, prices from the history, each window's views, settings, files, order of work; open questions.
  No code yet.

### Social: open points written down
- `src/Social/README.md`: *To check in the game* has the full screen without the bubbles going, marks in a
  channel of your own, and joins and leaves hidden also from the saved history; *Not there yet* no
  longer names the saved history, which is there. `Doc/ideas/Social.md`: what Saneroki is to decide (banner,
  smiley art, wrapping at full screen, a player's old `SaneUI_Chat` folder).

### Social: the messages stay in sight while the window fills the screen
Tests: 320 checks (Social). Not tried in the game; `/reload` is enough.
- Fixed (Saneroki, 2026-10-16): the bubbles went out of sight and came in again on the way to the full screen
  and back. `Window.lua` no longer gives the list to Core as the window's `content` (Core's `Edge.lua` fades
  that out and in); `Sized` puts the messages at the list's bottom on every frame of the way too (`Resettle`,
  no measuring: their wrapping stays), and `Placed` wraps them for the new width once the window stands.
  Core is unchanged: `content` stays an option for other windows.

### Social: a smiley with icons and emotes
Tests: 319 checks (Social). Not tried in the game. New files: restart the game.
- **Picker** (`src/Social/Picker.lua`, new, in the TOC after `Menu.lua`): a smiley button right of the line
  to write in, before the grip (`Layout.GRIP_ROOM` 18, `Layout.FACE` 24; the line now ends at
  `Layout.INPUT_RIGHT` = 44), shown by `Input` whenever the line is dressed (`Picker.Show`), hidden when it
  rests, closes or is given back; made with the line's plate (`Picker.Take`). Tooltip *Icons and emotes*.
- Its list is the game's menu: *Icons*, a row of the eight raid marks (a `CreateFrame` line whose initializer
  attaches eight `MenuTemplates.AttachBasicButton`s with the game's `UI-RaidTargetingIcon_<n>` and the name
  `RAID_TARGET_<n>` as tooltip, and returns the row's size); a click inserts `{rt<n>}` at the cursor and closes
  the menu. The game's chat draws no other pictures from what players write, and none in its public channels
  (`suppressRaidIcons`): while the line writes in a *Zone* channel (`GetChannelInfoFromIdentifier`) the row
  is a disabled line *No icons in the game's public channels*. Then *Emotes*: `Picker.EMOTES` (hello, wave,
  bye, thank, welcome, cheer, applaud, congratulate, laugh, dance, bow, hug) by their command in the game's
  language (`EMOTE<n>_CMD1`), done with `C_ChatInfo.PerformEmote` (or `DoEmote`) as the game's chat menu does.
- Art: the game has no smiley. `dev/tools/smiley-art` (new) draws `assets/SaneSocial-Smiley.png`;
  `dev/tools/art` has the kind `button` (24 x 24 units, 64 x 64 texels) and ships a picture under a name of
  its own (`src/Social/Art/smiley.blp`, the fifth field of `PICTURES`). Missing, the button shows the game's
  chat button art.
- Tests: the stand-in menu has `CreateFrame` lines and buttons with data and `SetEnabled`; checks for the
  smiley's place, the list in a public channel and elsewhere, a mark, an emote, the smiley going with the line.

### Full screen: the dropdown Classic windows; a full screen is square
Tests: 311 checks (Social), 148 checks (windows). Not tried in the game. `/reload` is enough.
- **Classic windows** (Saneroki, 2026-10-16; `Edge.lua`): a window's option `classic` (`{ text, show }` entries, or
  a function giving them) names the game's own windows it stands for. While the window stands full, the
  game's dropdown (`WowStyle1DropdownTemplate`, words fixed by `OverrideText`: *Classic windows*,
  `Edge.MENU_WIDTH` 180) sits `Edge.MENU_INSET` (10) from its top right corner, 50 levels above it; not on
  the way. One chosen: `edge:Fill(false)`, then `show()`. `Edge.MENU_ROOM` (48): where a full window's
  content should start to stand clear of it.
- **Social:** `ns.CLASSIC` (`Social.lua`): *Chat*: the switch *Chat window* off (`Shown(false)`, the window
  hidden, the game's chat back, an open options page follows) and a line saying `/sane social` or the
  switch brings it again; *Friends list*: `ToggleFriendsFrame(FRIEND_TAB_FRIENDS)`, as the game's key opens
  it, only if `FriendsFrame` is not shown (nothing if the game has no such function). Full, the list starts
  under the dropdown (`Top` in `Placed`; `Layout.ListHeight` takes the list's `top`).
- **Square full screen** (`Shape:Flatten(share)`): the full screen background's corners shrink as it comes
  (`edge.cover`) and its trim on the screen's edges slides out, so the full window is square whatever
  *Corner radius* and *Don't round corners on screen edges* say; only a window at rest is round. The two
  switches' tips say so.
- Ideas: `Doc/ideas/Windows.md` (*Classic windows*), `Navigation.md` (its full screen lists the native minimap
  and the native map and quest log), `Social.md`.

### One licence; data in Core; Actionbar Organizer gone
Tests: lint, all checks of every module.
- **One licence (Saneroki, 2026-10-16):** the project's `LICENSE` covers Core and every module with all their
  data (its point 1 now says so). Gone: `src/Tooltips/LICENSE` and the trainer data's own notice
  (`Abilities/Data/LICENSE-trainer-data.txt`); the Tooltips TOC's `X-License` is MIT like the others';
  `dev/build` gives every addon the project's `LICENSE.txt`. README, AGENTS.md, the agent map, the Tooltips
  and Abilities READMEs, `Data/Quests.lua`, `Data/Trainer.lua` and the public changelog no longer speak of
  a licence of a module's own.
- **Abilities:** no warning any more about Actionbar Organizer, the module's obsolete former addon (and
  its test check).
- **Navigation plan:** pin locations, spawns, patrol paths and the other map data are saved and handled by
  Core's database system, which Navigation only reads; route data loads on demand, by Core (Saneroki,
  2026-10-16). `Doc/ideas/Data.md` has *PatrolPaths* in the Spawns pack and a pack `SaneUI_Data_Routes`.
  Two open questions answered.

### Tooltips: a lighter Gold section
Tests: lint, 297 checks (Spellbook), 319 checks (Tooltips).
- **`CLAUDE.md`** is a local file now (`.gitignore`).
- **Tooltips:** `Addons/` (13 files) is gone, with the Loot, Guild and Inventory sections, *Crafted by* and
  *Disenchants into*, the Disenchant row, market odds and fair prices and the price chart (`Panel.lua`,
  `Pools.lua`). Lines other addons add still show, small, at a panel's end. The Gold section is the vendor's
  price and the AH profit by the prices you saw yourself (`Auction.lua`), with one advice line; with Alt the
  lowest price, the cut and the deposit (new check). `Data/Quests.lua` is the module's own data: its format is
  in its header, changes are made in it. Planned: auction prices from the Economy module's own database.
- **Spellbook** finds other bars' buttons only by the slot they carry; it warns only of its own former
  addon.
- `dev/tools/project-index` no longer indexes `CLAUDE.md` or `Scripts/`.

### Windows: round corners and a trim, opened by a click, a progress bar
Tests: 305 checks (Social), 141 checks (windows). Not tried in the game. New files: restart the game (a
`/reload` does not find them).
- **Round corners** (`src/Core/Shape.lua`, new): a window's plate is a fill with round corners and a bronze
  trim, `Shape.TRIM` (2) wide, that follows them. Each corner is a square piece cut by a circle mask twice
  its radius wide on the arc's centre (a mask is stretched whole and a texture takes three at most; a
  quarter picked by texture coordinates does not work, as Social's `Plate.lua` found); the rest of the fill
  is up to five strips that leave the corners out. All are painted alike (the gradient's colours where each
  lies, or the tile's coordinates from the top left), so they meet without a seam. The trim lies over the
  fill: strips along the sides, and in a round corner an arc, the corner's piece cut by the circle and by a
  hole mask the trim's width smaller. `shape:Look`, `Fit`, `Base`, `SetAlpha`, `SetShown`, `shape.radii`.
- **The switches** (`Shape.Options`, `Shape.DEFAULTS`, `Shape.KEYS`): *Corner radius* (`corners`, 0 to
  100 % of half the window's shorter side at rest, 10) and *Don't round corners on screen edges*
  (`squareEdges`, on). With it on a corner's radius is no larger than its gaps to the screen's edges:
  docked, the corners there are square; on the way to an edge a corner flattens out, and a side's trim
  slides out of the screen in its last two units. Off: every corner is round (at 100 % a square window is
  a circle).
- **Masks** `src/Core/Art/circle.blp`, `circle-hole.blp` (256 × 256, DXT5 with mipmaps): a white disc, and a
  white square with the disc taken out, drawn by code (`dev/tools/shape-art`, new). Without them (a game
  started before they were there) every corner is square.
- **Skin** (`Skin.lua`) is a Shape: the dark gradient as before, a bronze trim and round corners (was the
  game's tooltip border on `BackdropTemplate`, pushed out of the screen on docked sides). `skin:Dock(zone)`
  is gone: `skin:Rest()` (placed: the corners are measured on this size), `skin:Fit(...)`; it fits itself
  when its size changes. `Window.New`'s `corners` names the settings it is rounded by (else `edge`'s table).
- **Edge**: the full screen background is a Shape in the window (was one texture): corners measured on the
  window at rest, the tile repeated at its size (`Edge.TEXTURES` have `size`), the trim bronze. `edge.cover`
  says how far it has come (the fill's alpha is that times the opacity, the trim's that alone); a skin of
  the window fades out as it comes; while full a frame of its own refits it to a new screen size. The
  section *Expand window* has the two corner switches under *Can expand to fullscreen* (`Edge.DEFAULTS`,
  `Edge.KEYS`).
- **Expand**: `click = true`: a click opens it and pins it (it stays when the mouse leaves), a click again
  lets it go (with hover: it closes once the mouse has left); a press and a release more than
  `Expand.SLIP` (4) apart are a drag. `hover = false`: the mouse's coming does nothing. `expand:Pin()`,
  `expand.pinned`; `expand:Close()` unpins.
- **Bar** (`src/Core/Bar.lua`, new): a progress bar for any module, with a second fill after the first; a
  gain eases in, a loss is there at once; `count` gets the value on its way, for a number that counts up.
  `bar:SetSize(width, height)` moves as the kind of motion says. Nothing runs while it stands still.
- **`/sane window`** (`Demo.lua`): a window to try it all; a click keeps it open.
- **Social**: the section *Expand window* is first in the tab *Appearance* again, above *Messages* (asked
  for on 2026-10-15; a review had put it after *Animations*), now with the corner switches; a change of one
  goes to `Window.Expand` (`edge:Update`).
- Docs: Core's and Social's READMEs, `Doc/guides/gui-development.md` (the skin), `Doc/guides/images.md`
  (masks drawn by code), `Doc/agent/core.md`.

### Chat is Social
- The Chat module is renamed **Social** (`Doc/ideas/Social.md`): folder `src/Social`, addon
  `SaneUI_Social` (`SaneUI_Social.toc`), its first file `Social.lua`, module and title *Social* (addon
  list, options page, the window's bar). `/sane social`, and `/sane chat` as its second word.
- Core (`Saved.lua`): what was kept under a module's old name (`RENAMED`, `Chat = "Social"`) moves to its
  new one once at load, wherever a module's name is a key: `SaneUIDB.modules`, `perCharacter`, `account`,
  each profile, and the character's `SaneUICharDB.settings`. What the new name already has stays.
- `dev/build` removes the old `SaneUI_Chat` folder from the game's AddOns folder; a player's old copy is
  still to be handled (open).
- Tests: `dev/tests/chat.lua` is `dev/tests/social.lua`; Core checks the move of the saved settings.
- Docs: `Doc/agent/chat.md` is `Doc/agent/social.md`; READMEs, AGENTS.md, CLAUDE.md's example, the
  agent docs and `dev/tools/art` (the banner ships in `src/Social`) name Social. The banner drawing still
  reads *Sane Chat*.

### Navigation: our own data
- `Doc/ideas/Navigation.md`, new section *Our own data* (Saneroki, 2026-10-16): the module's data is in its
  own data files and `Art/`, and the map system works fully on its own. No code yet.

### Navigation: one pin per thing
- `Doc/ideas/Navigation.md`, new section *One pin per thing* (Saneroki, 2026-10-16): one pin per thing and
  place, by a key per pin kind and a distance per kind in world yards; one NPC with several roles is one
  pin; live game pins win over database pins of the same key; a test checks no duplicates ship. No code
  yet.

### Navigation: every kind of pin
- `Doc/ideas/Navigation.md`: Saneroki's decision on more pins: rares and where they spawn, quest and guide
  pins. New sections: a pin catalogue for the pin filter, dungeon maps and a map selector. No code yet.

### Ideas: one toggle, Click required to expand window
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): the setting is one toggle, *Click required to expand
  window* (ticked: a click is required; not ticked: hover is enough), in Core's *Hotcorners* for all
  modules and in each module for its own windows; changing Core's sets every module's to the same. The
  open question of a third state ("as Core's") is gone.

### Ideas: Expand on hover in Core's Hotcorners and in each module
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): *Expand on hover* is set in a section *Hotcorners* of Core's
  settings for the windows of all modules, and in each module's settings for its own windows, overriding
  Core's; each module handles hover and click only for its own windows, and the tooltips say so. Open:
  how a module's setting follows Core's until overridden (proposed: a dropdown with *Use global setting*,
  like *Animation type*), and the page of *Hotcorners*.

### Ideas: windows in Edit Mode's layouts; chat views as windows and tabs
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): Edit Mode's layouts keep the size and place of every Sane UI
  window, each layout its own, switching with Blizzard's frames; moves count as layout changes until
  *Save*, and Revert puts the windows on their default position, all as Edit Mode does it. Notes for
  building it (our places kept per layout in Sane UI's settings, Blizzard's events and hooks, enabling
  Blizzard's *Save* button, a dialog with *Reset To Default Position*). A window still saved in a removed
  quarter zone needs nothing (Core ignores a zone it does not know).
- `Doc/ideas/Social.md`: a chat view can be a window of its own and a tab of the small Social window, like
  the game's chat windows. The old `SaneUI_Chat` folder is deleted (gone from the game, `src/` and
  `BUILD/`); Sane UI is not given out yet, so no player's old copy is to be handled.

### Ideas: expand by a left click; Expand on hover
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): a docked window fills the screen only on a left click on its
  trigger area, not when the mouse merely reaches it; right and middle click stay free for later functions.
  A checkbox *Expand on hover* in the section *Expand window* (off by default, on for a window designed for
  hover) brings back today's expanding by the mouse alone. Notes for `Edge.lua` (the strip also takes the
  left button). `Doc/ideas/Navigation.md` points to it. No code yet.

### Ideas: the screen layout of docked windows; Chat becomes Social
- `Doc/ideas/Windows.md` (2026-10-16): Saneroki's plan for how the windows share the screen: only eight
  places (three at the top, one on each side, three at the bottom; Core's quarter zones go), full screen
  only from a place where a window is docked, the default window of each place (top left party and raid,
  tentative; top middle journal and progress; top right Navigation; bottom left Social; bottom middle
  Spellbook with action bars, talents and legacy; bottom right character sheet and bags; left and right to
  be decided), and moving and sizing only while Blizzard's Edit Mode is open. No code yet.
- `Doc/ideas/Social.md`: the Chat module is to be renamed Social and hold chat, more chat views with their
  own channel filters, guild, group finder and friends list. `Doc/ideas/Navigation.md` points to the plan.

### Navigation: feasibility, full screen, pins and routes
- `Doc/ideas/Navigation.md`: Saneroki's new decisions (quest log on the left in full screen; separate zoom and
  position per view; following the player; map selector, pin filter and three views on a top bar; own pin
  database, herb and ore icons; Blizzard's map pin with a route drawn as a pulsing
  golden line) and a feasibility analysis against Blizzard's code: all doable, north-up
  only, live minimap dots in the small view only, no terrain in dungeons, walking data to decide. No code
  yet.

### Navigation: planning notes
- `Doc/ideas/Navigation.md` (2026-10-16): what Saneroki has decided so far for the Navigation module, which
  replaces minimap, world map and quest log with one Core-docked window (top right, expands to the whole
  screen like Chat) that renders one map, zoomed by the wheel from minimap to world.
  Earlier notes from `Doc/ideas/Maps.txt` are folded in; open questions listed. No code yet.

### Tooltips: comparisons at absolute places; Press ALT for +N more
Tests: 347 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Comparisons still flickered.** The second panel hung on the first only while the first was shown;
  the game hides and refills the first several times a second, and a placement in such a moment put
  the second beside the main panel, where the first stands. Relative points also took over any wobble of
  what they hung on. `Native.lua` now pins each comparison panel to an absolute place on `UIParent`
  (`Pin`, only when the place changes; `Release` and `Stay` forget the pin), worked out by `Place` from
  steady values kept per main tooltip (`layouts`): the main panel's left, right and top, taken for a new
  thing (owner and item, `Thing`) and afterwards only once it has stood still for `STILL` (0.12 s)
  in a new place (`Native.Follow`, called every frame from the main panel's `Watch` in `Tooltips.lua`);
  the side (`Side`), once per thing; each comparison's slot width, the widest its panel has been for the
  thing. Gap 12, tops in a line.
- `TEXT.ALT_MORE` (*Press ALT for +%d more*) where Alt shows more: the Quest section, the Loot
  section's sources, the Guild section (under the names, which no longer carry the count).

### Tooltips: comparisons in one place, a gap apart; Questlog over the quests' standing
Tests: 342 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Flicker of comparisons:** their panels copied the game's points (`Beside`), and the game re-anchors
  its two comparisons several times a second, now the first on the second, now the other way round; a
  panel that could not hang on the other's (it would hang on itself), or whose other panel was hidden for
  a refresh, fell back to its own tooltip's corner, elsewhere by the size the game's tooltip has. Two
  places in turn. `Native.lua` now places the `shoppingTooltips` of `GameTooltip` and `ItemRefTooltip`
  itself (`Compare`): the first on the main panel, the second on the first, `COMPARE_GAP` (12) apart,
  tops in a line, on a side decided once per owner and item (`Side`: right where they fit, else left,
  else the roomier; the game's side, `GameSide`, where nothing can be measured).
- `Kinds/Item.lua`: *Starts* and *Needed for* have *Questlog* (`TEXT.QUESTLOG`) at the right.
- The chart's words have no dark plates (`Pools.ChartText`); they stay on their own frame over the lines.

### Tooltips: a Quest section with where you stand with each quest; the chart's words readable
Tests: 338 checks (Tooltips). Not tried in the game. `/reload` is enough.
- `Quests.lua`: `Quests.Item` lists the quest the item starts, then every quest for you that asks for
  it, by where you stand (`Standing`: active, offer, later, done; nil for another class, race or side, a
  closed quest, one no longer in the game; `Closed`), each once; entries carry `state`.
- `Kinds/Item.lua`: the quests under the caption *Quest* (`TEXT.QUEST`), *Starts* and *Needed for* small
  over them; each row: an icon (?, !, none, tick), the name in its standing's colour, its level small
  after it, *In log 1/4* / *Available* / *Not yet* / *Done* at the right; three not in your log without
  Alt, then *+N more*. A quest reward stays a source under *Loot*.
- `Kinds/Unit.lua`: the caption *Quest* over a creature's quests (put up by the first quest name).
- The chart's words (`Pools.ChartText`) stand on a frame of their own over the panel (its level two
  above), the ones inside the chart on a dark plate.

### Tooltips: gold for one item, the vendor price everywhere, captions Loot and Inventory
Tests: 332 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Gold** (`Kinds/Gold.lua`) works for one of the item: `Work(id, vendor, bound, facts, tooltip)`, `Sale`
  without a count; the vendor's price is `Gold.VendorEach` (`GetItemInfo`'s sell price, asked for when the
  game lacks the item; the price line only stands in meanwhile), on every item, *Can't be sold* (`NO_VENDOR`)
  at 0. A comparison's vendor row too. `TEXT.EACH` gone.
- The advice row has no coin (`PICTURE.coin` gone); the chart no dark ground.
- `Kinds/Item.lua`: caption *Loot* (`TEXT.LOOT`, was *Gear*; `LootSection`), caption *Inventory* over *You
  have*; the level it needs and the other requirements at the right, one under the other (the kind and
  slot at the left of the first).

### Tooltips: gold advice; item quests
Tests: 328 checks (Tooltips). Not tried in the game. New files: **restart the game** (a `/reload` does not
read them).
- **Item panel** (`Kinds/Item.lua`): requirements (class, races, skill, reputation, spell:
  `PATTERN.REQUIRES`) in the header under the level it needs; the game's lines (`Read.Rest("own")`), the
  durability bar, the item's quests, then Gear, Professions, Guild under captions, *You have*, other
  addons' lines (`Read.Rest("added")`), Gold. A comparison: its vendor price only. Alt: more in each.
- **Gold** (`Kinds/Gold.lua`): Vendor, Disenchant (materials × chance × average count × price, less 5%),
  AH profit (list price less 5% and the expected lost deposit: 60% of the vendor price for a 48 h auction,
  by the odds of a sale), a chart row, and the advice (`ah`, `de`, `vendor`; `buy` for a tooltip filled with
  `GetItemKey`), the better way needing 5% more; Alt: prices, listed, fees, source. Replaces the *Auction*
  row; `Auction.lua` is the last price source.
- **Panel:** a `chart` row kind (`Model` key `points`), drawn with `Pools.Segment` (Line objects); a `coin`
  picture.
- **Quests:** the quest data has `ITEMS` (quests asking for an item; the quest it starts) and `STARTERS`
  (creatures dropping a quest-starting item, with chance). `Quests.Item`,
  `Quests.ItemName`, `Quests.Level`, `Quests.Heading` (a quest's name with its level, coloured); `Offered` can
  take a trivial quest (an item's). `Kinds/Unit.lua`: every quest name with its level (by the game's line's
  quest id), a creature's quest-starting drops (the !, the item, its chance).

### Tooltips: drop chances on a creature's loot objectives
Tests: 296 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Data:** each drop has its chance, at most 100. A `DROPS` entry is `quest:item:objective[:chance]` now.
- **Shown:** `Quests.Of` gives a loot entry its chance (`extra`); `Kinds/Unit.lua` puts it after the item's
  name as the row's `label` (`TEXT.CHANCE`, *33%*), on the game's own objective line too (found by its
  words), and a drop the database knows has a sack even when its words name the creature.
- **Panel:** a row's `label` is drawn also when the row has a right text (`WordsAndAfter`).

### Spellbook: a reservation dragged off the bars is removed
- A reservation picked up from a button and let go where there is no button is taken off (`Drag.Stop`:
  `Engine.Clear` of the slot it came from), as the game does with a real action. Was: it stayed.
  Not tried in the game. Tests: 297 checks (Spellbook).

### Spellbook: a carried spell finds every action button
- **Dropping a grey spell missed some of a bar addon's buttons.** The drag knew buttons by a fixed list of
  names and slots, and trusted a hidden button to report its place. New `Buttons.lua`: every action
  button is found by what it is (a Button or CheckButton that carries an action slot, `EnumerateFrames`
  when a drag starts; by name where that is missing), so bars 9 and 10, paged bars and other bar addons
  count too; a hidden button's place is worked out from its first anchor when `GetRect` gives none
  (`Buttons.Rect`); shown buttons are tried before hidden ones; the gold frame is placed by that place.
  The bar ghosts use the same list (looked for again 5 seconds after each loading screen).
- Native drag with a stand-in macro on the game's cursor was offered and declined (it costs a character
  macro per reserved spell).
- Tests: the stand-in client walks its frames and knows a frame's kind. 297 checks (Spellbook).

### Spellbook: moving a reservation from button to button
- **A reservation's grey icon on the bar can be dragged to another button**, like a real action: where the
  game allows that (bars unlocked, or the pick-up key held). On a reserved button the two change places,
  on a real action that action goes onto the cursor; let go elsewhere and nothing changes. New
  `Engine.Move(from, to)` and `Drag.StartMove(slot)`. Hooks after the button's `OnDragStart`, `OnDragStop`,
  `OnShow` and `OnHide`. Where the bar hides the empty button, the grey icon takes the mouse itself (its
  tooltip and the drag) and carries its slot as `.action` for the drop; over a shown button it takes none.
- Not tried in the game. Tests: 295 checks (Spellbook).

### Spellbook: hidden empty buttons, and the order in a tab
- **A grey spell could not be dropped on an empty button its bar hides** (a bar addon set to hide empty
  buttons): a bar shows its empty buttons only while the game's own cursor carries something. The drag now
  also knows that addon's buttons of every slot the module looks after, and a hidden one counts when the
  mouse is inside its place (`Drag.lua`, `Under`: `GetRect`, the cursor in the button's scale), on a bar
  that is visible. Shown buttons are still asked `IsMouseOver`.
- **The grey icon on the bars hangs on the button's bar** in the button's place (was: on the button), so a
  reservation also shows on a hidden empty button; it follows the button to another bar out of combat.
- **Order in a tab:** the spells you have first (the game's order), then those you can learn now, then the
  rest by level, name and rank. `Layout.Order` replaces `Layout.Merge` (which filed new spells by name
  among the learned ones); `Layout.Compare` is gone; `Layout.ByLevel` puts what you can learn now first.
- Not tried in the game. Tests: 285 checks (Spellbook).

### Spellbook: reserving on a bar addon's bars
- **Dragging a grey spell onto a bar addon's action bar did nothing.** That addon makes buttons of its own
  for every bar, keeps their slot only in the secure attribute `action`, and hides the game's buttons. The
  drag read only the field `button.action` and scanned the game's (hidden) buttons, so it found no slot.
  New `ns.ActionOf(frame)`: the attribute first, then the field, inside a `pcall`; used by the drag,
  `ns.SlotOf` and `ns.Bar1Offset` (which reads that addon's first button when the game's is hidden). The
  grey icons are now put on that addon's buttons of every slot the module looks after, not only on those
  of bars 9 and 10. Not tried in the game.

### Review: settings texts, bugs, performance and documentation across every module
From a full QA, bug-hunt, performance and reasoning pass over the whole project (review agents per module and
lens, each finding checked against the code). Not tried in the game. Tests: 194 checks (Core), 281 (Spellbook),
460 (Tooltips), 304 (Chat), 62 (Sync), 105 (windows). The pass was cut short before Core's options pages, the
Tooltips module and the structural Spellbook performance items were done: see the orchestrator's report.
- **Settings texts, every module:** every switch, slider and dropdown has a tooltip that says in one or two
  sentences what it does and what "Off" means (the Spellbook's *Say in chat when a reserved button is filled*
  had none). Labels say what they are: Chat's *Fade in*, *Fade out*, *Slide up* (were "... speed" on a yes/no),
  *Fade-in time*, *Fade-out time*, *Slide time*, *Faded messages stay visible* (was *Opacity*), *All animations
  and fades*, *Show the game's chat too* (was *Show native chat*), *Bubble opacity* (100 solid; was
  *Transparency*, 0 solid, the opposite of every other opacity slider; a kept value is turned round once,
  `bubbleOpacity`), *Bubble colour*, *Solid colour*; Spellbook's *Show unlearned spells* (was *Show hidden
  spells*, which read as the opposite of the game's *Hide Passives* beside it), *Move and resize the spellbook*,
  *Show reservations on the action bars*, *Sane UI lays out the spellbook pages*; the Expand window section's
  tips; Sync's part tips name only what a part holds. British spelling throughout.
- **Spellbook, options:** the master switch *Sane UI lays out the spellbook pages* is first, under a header
  *Spellbook*, and the four switches that do nothing without it are under it, greyed out while it is off; the
  action bar switches under *Action bars*. Flipping it offers the /reload in the game's dialog (`Core.AskReload`)
  besides the chat line. The in-book checkbox has a tooltip. The spellbook's menu has the three switches about
  the book too, then the bar switches; its *Show unlearned spells* is greyed out while the pages are the game's,
  with the reason in its tooltip (`B.Why`). *Delete* of a layout asks first. A grey entry's click hints are the
  game's green instruction lines, not grey.
- **Spellbook, bugs:** a saved layout made in a fight recorded every hidden slot as "other", and *Load* then
  never restored those buttons: `RealEntry` gives nil for a hidden slot, and `Presets.Save` refuses in a fight.
  `Presets.List` passes over a hand-edited key that is no name (it broke the whole settings menu). A
  reservation's or layout's icon of another kind is left out (`ns.Texture`), and `S.Icon` never hands one on.
- **Spellbook, performance:** a resize drag redraws the pages ten times a second, not every frame, and once
  more at the end; `I.Set` makes no tables per entry, reads *Show all spell ranks* once per build, and keeps an
  entry's status words; `ScanBook` makes no table per spellbook item; a drag asks the mouse's foci before
  scanning 96 buttons and moves the gold frame only when the button under the mouse changes.
- **Chat:** a switch *Chat window* on the General tab shows or hides the window (`/sane chat` flips it; a kept
  `store.hidden` is moved into it once); the ticks of the list on the chat's name are a setting (`mute`, moved
  from `store.mute` once), so profiles and a character's own settings carry them; the four groups with a switch
  have the same words on the page and in the list; *Messages kept* starts at 10 (0 did what unticking does);
  each game channel's tip says "in a city" only for Trade and Services; the Appearance tab reads Messages,
  Animations, Expand window; the Expand window's *Animation type* is greyed out while *All animations and
  fades* is off (`Config.Free` takes a list of parents); a tick flipped in the list refreshes the open options
  page. The TOC's description and the README say the game's chat stays next to the window (the default).
- **Chat, performance:** the window lays nothing out while it fills the screen or goes back (`Sized` returns
  while `edge.away`; `Placed` does the work once at the end); a message's fading out walks only the messages
  that are due, with one fixed timer function (was: every message twice and a new closure per timer); the
  history is restored in O(n), not O(n^2).
- **Core:** a module step `OnLogout`, run before Profiles puts the account's settings back, so a module reads
  its own settings at logout (Chat's history saving still uses PLAYER_LOGOUT: to move). `Core.On` notes an
  event this client does not know (log and `/sane errors`). The game's error window is hooked at Core's
  `ADDON_LOADED`, so an error while a module's files are read is noted. `/sane errors clear` tells a recurring
  problem again; `/sane` marks a module that failed to start. `Core.AskReload(names)`: the game's dialog
  offering a /reload. `module.Safe` builds its label only on a failure; `module.Fire` makes each listener's
  label once; `Core.errors` keeps a text's first line (the log keeps the trace). `/sane window` builds into
  locals and publishes only on success; `/sane window reset` typed first in a session resets; the window is
  `SaneUIDemoWindow` and Esc hides it.
- **Windows:** the skin stands one frame level under its window, so the window's own regions (the demo's text,
  Edge's full-screen background) draw over its fill, not under it. Esc brings a full window back
  (`SaneUIEdgeEscape` in `UISpecialFrames`). Expand's size motion stops while Edge owns the size.
- **Sync:** the Graphics part takes *Texture Detail* again ("resolution" is out of `NEVER`; the screen's
  resolution is `gx*`); `characterFrameCollapsed` left the interface part's list (NEVER dropped it anyway); a
  channel's kind is asked of `C_ChatInfo.GetChannelInfoFromIdentifier` first, `EnumerateServerChannels` second, and what
  was kept stays when neither can tell (every joined channel counted as the player's own without the latter);
  the /reload dialog is offered once per giving, not once per session; `PLAYER_REGEN_ENABLED` only settles a
  waiting Edit Mode layout; the console list is resolved into every part's names in one pass and let go
  (`Resolve`, `part.has`).
- **Tooltips data:** quest 8315 (*The Calling*) has its next quest 8316 again; `Quests.lua` regenerated.
- **Dev:** the stand-in client loads every TOC line (Lua and XML with `Script`/`Include`) and errors on one it
  cannot, as the lint and the game accept them; `dev/build` prints its whole usage; `Scripts/addon-categories`
  repairs an orphan group for every addon.
- **Documentation:** the guides say what the code does on purpose (Sync's `VARIABLES_LOADED` and Edit Mode
  part, `GetFont`/`SetFont` to change a size, Core's skin and bronze border, Chat's fade `OnUpdate`, saved data
  checked by shape, the Settings API, globals the client demands, `Core.Later`, `GiveBack`, tables of
  functions, the checklist for a part that stays, small captions, the shipped pictures, the NineSliceLayouts
  path); the agent notes, the root README, AGENTS.md, CLAUDE.md's folder rows and the module READMEs no
  longer say "Settings module", "three addons", "six folders", and carry the current test counts.

### Review: Spellbook, Tooltips and Chat bugs, hardening, performance
From a full review of the three modules. Not tried in the game. Tests: 280 checks (Spellbook), 460 (Tooltips), 304 (Chat).
- **Spellbook, bug:** made small or large without a kept size of its own, the spellbook kept the height a kept
  size of the other gave it (the game sets only the book's width), stood out of the window and laid its pages
  out for that height. `Window.lua` fits the book to the window whenever it looks after it (at the game's own
  sizes that is the game's 1612 x 702 / 806 x 702).
- **Spellbook, performance:** Home was filled on every update while the spellbook was closed (its pane stays
  shown in the hidden book): `IsVisible`, not `IsShown`. It is filled when the book opens.
- **Spellbook, bug:** a rank named with a numeral (*Instant Poison II*, rank line *Rank 2*) is the trainer's
  *Instant Poison*. `ScanBook` knows it by both names (`D.BaseName`), the book's entries are grouped by the
  trainer's name (they fold with their grey ranks), and a rank the game pushes finds the button reserved
  for it by that name (`UndoPushes`). Was: a grey duplicate, and the new rank moved off its own button.
- **Spellbook, hardening:** reservations with a slot that is none (not 1 to 180, not whole) or an ID or name of
  another kind, a layout's slots likewise, and a kept window size or place that is no numbers are left out
  (the game's action functions fail on them, in every update). Giving the game's size back while the talents
  are shown leaves the window to the game's next tab change.
- **Tooltips, bug:** with *Show the icon* off (or no icon) an item's and a unit's level were gone with the
  plaque: they stand right of the name now. A line of the game's data without text (it adds no line, yet gets
  the index of the last one: `TooltipDataHandler`) took that line's type: the first line of data marks it.
- **Tooltips, inspect:** an answer read no longer clears an inspection another addon asked for since
  (`ClearInspectPlayer` only when nobody called `NotifyInspect` after us); talents kept without an item level
  are asked for again (paced as before) instead of five minutes without one.
- **Tooltips:** a spell's school is not kept before its description came; of several auction rows of one item
  (its kinds) the lowest price counts, also over rows that come later in the same list; a failing live value
  (health, power, target, buffs: `Live.Start`, `Live.Update`) is noted once and switches the live values off,
  not the module; a boolean mouse switch of version 2 is put right in every copy (`Profiles.Copies`).
- **Tooltips, performance:** another addon's unseen tooltip (owned, placed nowhere) is only made invisible on a
  fill (`Native.Veil`), not part by part (`FadeParts`) and given back each frame.
- **Chat, bug:** the edit box's insets and its label's height are read plain (`Insets`): a name the game hides
  would make them hidden, and growing the line stood the module down. Scrolled up, the oldest messages leaving
  a full log moved the reader on by their rows (the list keeps its offset from its top): `ScrollToOffset`
  back by their height. The button on the chat's name of a line at rest (IM style) took clicks, unseen.
- **Chat:** raid marks (`{skull}`) are their icons (`C_ChatInfo.ReplaceIconAndGroupExpressions`, as the game's
  chat, with arg17 and the group's expansion); a letterbox's message (arg16) is not shown, as in the game's
  chat. The game's channels are joined or left again when chat's lockdown ends (`ADDON_RESTRICTION_STATE_CHANGED`).
- **Chat, history:** a message with a Battle.net friend's name or link is not saved (it stands for the friend in
  that session only); a player's link is saved without its line number. `Log.Restore` mends a message without
  its time, with a tie or class that is none (`Bubble` would fail on them while drawing).
- **Chat, resilience and performance:** `Native.Show` gives each frame back by itself; a measured message's
  height is known without a guard (`Bubble.Known`: every message made the list ask for all heights, each in an
  `xpcall`); `Untimed` makes no closure per printed line; the speakers' caches count each by itself (the
  group's changes no longer emptied the classes too).
- **Tests:** the stub's spellbook items have their rank line (`subName`); the tooltip stub can give a line of
  data without text (`nothing`); the chat stub's list has a scroll offset, and the game's channel functions
  from the start.

### Review: Core and Sync bugs, hardening, performance
From a full review of Core, Settings and Sync. Not tried in the game. Tests: 194 checks (Core), 62 (Sync), 98 (windows).
- **Bug, Profiles:** a character's line that names *Empty* (an older version moved a saved profile called so,
  or a hand edit) counted as a profile with nothing saved: every change of the session was thrown away at the
  logout. `Wanted` now takes Empty as no profile. A saved profile called Empty or SaneUI Defaults whose
  *(old)* name is taken is moved to the next free one (*(old 2)*, ...) instead of being lost.
- **Bug, docked windows:** `Dock.Anchor` hung a window on the screen's lower left corner, at offsets worked
  out from the screen's size then: after a change of the UI scale or of the game window's size it stood away
  from its edge (and its edge strip with it). It now hangs on the screen's point of its zone (`TOPRIGHT` on
  `TOPRIGHT`, ...). A kept size larger than the screen is now is cut to the screen's; a window without a
  smallest size no longer breaks `SetResizeBounds`.
- **Edge:** a full window gives back clicks and the mouse's coming apart (`SetMouseClickEnabled`,
  `SetMouseMotionEnabled`), not as one. **Motion:** a clock's last `OnUpdate` at 1 no longer ends the motion
  twice (`OnFinished` does): Chat's layout after filling the screen ran twice.
- **Core:** a module whose `OnLoad` failed is not given `OnLogin` (it would fail on what was not made).
  `NoteError` copes with an error text the game hides (secret: it could not be compared nor saved) and
  counts in place; `/sane errors` skips saved entries it cannot read.
- **Sync, taint:** the game answers a new Edit Mode layout (`EDIT_MODE_LAYOUTS_UPDATED`) and a new chat colour
  (`UPDATE_CHAT_COLOR`) with events that run inside our call (synchronous), so its manager and chat frames ran
  under Sane UI's taint until a `/reload`. The Edit Mode part (`reload`, also when a waiting layout is set
  later: `Sync.AskReload`) and a chat colour alone now offer the reload, as the chat windows did. The dialog
  says the game "takes them over fully" after it.
- **Sync, timing:** given only once the game has its stored settings (`C_CVar.AreCVarsLoaded`, else on
  `VARIABLES_LOADED`): on a slow login the server's would have overwritten them, and the logout kept the old.
- **Sync, resilience:** when the game cannot list its CVars (`ConsoleGetAllCommands` failed or gone), the CVar
  parts keep what was saved instead of saving nothing over it; the list is asked again later. A flag part
  whose getter does not answer keeps what was saved (was saved as off).
- **Sync:** the chat channels of your own are joined before the chat windows are given (a join puts the channel
  into the first window, which the windows' part then puts right; it spread to every character). Edit Mode
  looks again on `PLAYER_SPECIALIZATION_CHANGED` of the player only. Building the CVar parts' lists makes no
  table nor string per CVar.
- **Settings, CVar list:** what the game said of a change ("The game keeps it at ...") stays while that CVar is
  shown; the redraw that follows the game's own `CVAR_UPDATE` wiped it a tenth of a second later.

### Windows: Expand window; the full window takes the mouse; a corner's square
Not tried in the game. Tests: 94 checks (windows), 294 checks (Chat).
- **Core, `Edge.lua`:** full (and on the way), a window is raised above the rest of its strata and takes the
  mouse and its wheel (`EnableMouse`, `EnableMouseWheel`, as the game's map does while locked): nothing behind
  it is clicked, nor the camera turned or zoomed; its layer, level and mouse are as before once it is back.
  Its background is half opaque at first (was solid) and may be one of Blizzard's tiles (`Edge.TEXTURES`:
  Solid black, Marble, Rock, Slate, Iron, Night, named as Chat's bubbles name them; tiled with
  `SetHorizTile`/`SetVertTile`). Docked in a corner, only a square of `Edge.CORNER` (4) of the screen's pixels
  in that corner sets it off (was a strip along both its edges); along an edge, the strip as before.
- **Core, the section *Expand window*** (`Edge.Options(list, at, tab)`): *Can expand to fullscreen* (on; off:
  no strips), *Animation type* (moved here from Chat's *Animations*), *Background opacity* (0 to 100 %, 50),
  *Background texture* (Solid black). `Window.New`'s `edge` takes the module's settings (`edge = ns.options`;
  `true`: `Edge.DEFAULTS`); a change of one (`Edge.KEYS`): `edge:Update()`, seen at once, also while full;
  it does not make the edge quiet.
- **Chat:** the section at the top of the tab *Appearance* (`Edge.Options(OPTIONS, 1, LOOK)`); `Window.Expand`.
  *Enable all Animations and Fades* off still makes it fill the screen at once.

### Profiles: Empty; SaneUI Defaults only Sane UI's own settings
Not tried in the game. Tests: 190 checks (Core).
- **Empty** (`Profiles.EMPTY`): no profile, as a profile in the lists (first, chosen at first; was *None* on a
  character's line). The settings as they are kept, the account's (or each character's own), loaded at every
  login and saved at every logout and `/reload`, as before. Loaded, it puts those back in use where a profile is
  in use (`Kept`); duplicated, it copies them (`KeptProfile`). Fixed with SaneUI Defaults: not saved over,
  renamed or deleted; on a character's line both checkboxes ticked and switched off. A saved profile called
  Empty is moved to *Empty (old)*.
- **SaneUI Defaults** leaves out the game's settings that Sync keeps (`GameSettings`): loading it (or duplicating
  it) changes only Sane UI's modules and general switches; with *Load at login* Sync's settings stay where they
  were (`Wanted`).
- `Home(name)` (where a module's settings come from without a profile) split out of `Wanted`.

### Sync: the Edit Mode layout is kept again
Not tried in the game. Tests: 57 checks (Sync).
- **Bug:** every login set the Edit Mode layout Modern, whichever one the player had chosen. The layout in use
  was read at the logout (`C_EditMode.GetLayouts().activeLayout`), when the game no longer says it: it said
  Modern (seen in the saved settings: Modern kept at a logout a minute after the game's own cache had the
  player's layout), and the next login gave that back.
- **Now** (`Sync/Parts.lua`): read from Edit Mode's manager (`layoutInfo`) while the character is in the world
  (`PLAYER_ENTERING_WORLD` to `PLAYER_LEAVING_WORLD`), a frame after it took new layouts and when the settings
  are taken; at the logout the last one seen. A layout that cannot be set yet (the manager without layouts
  early in a login, Edit Mode open, a fight) waits and is set as soon as it can (`EDIT_MODE_LAYOUTS_UPDATED`,
  `EditMode.Exit`, `PLAYER_REGEN_ENABLED`); meanwhile it is the one taken. Profiles save and load it the same way.
- **Tests:** the model's manager has `layoutInfo` and fires its event at once on `SetActiveLayout`, and says
  Modern after the logout, as the game; checks for waiting, Edit Mode open, a fight, a profile.

### Chat: no white ghost of a message in the window's corner
Seen in the game (a screenshot): a white copy of a message stood at the window's upper left, its second line
centred. It was the text that measures the messages (`Bubble.Ruler`), hidden only by its own alpha: a
FontString takes its alpha anew from its font object when that changes (the text size). Both rulers (the
messages', the line's in `Input.lua`) are now made by `ns.Ruler`: inside a frame of their own at alpha 0.
Tests: Chat 295 checks.

### Chat: an older history sorted anew, so the ticks hide it too
Seen in the game: loot, skill ups and a channel's joins and leaves from the saved history stayed in the window with
their ticks off; they had been saved as prints. Tests: Chat 289 checks.
- `Log.Restore(saved, version)`: a history without `historyVersion` = `Log.HISTORY` (2) has its prints sorted
  anew (`Guess`: a channel's link a notice, white a print, else by the kinds of chat of that very colour, the
  system's first) and its duplicate guild message of the day once. `History` saves `historyVersion`.
- `Group(kind, event, text)`: a line with neither kind nor event but a channel's link is a channel's notice.

### Chat: loot, skill ups and channel joins in their own groups in every client
Seen in the game (the saved history): this client's chat writes loot, skill and channel join lines without the
chat type number, so they went with *Addon messages* and their ticks did nothing. Tests: Chat 285 checks.
- `Log.Before`/`Log.After`: a filter (`ChatFrameUtil.AddMessageEventFilter`, or `ChatFrame_AddMessageEventFilter`)
  on every chat event we do not read (`Log.Unread`: from `ChatTypeInfo` and `ChatTypeGroup`) notes the window
  and event right before that window writes the line; each chat window's `OnEvent` (hooked) clears it. It
  returns `false` only: nothing is filtered or changed. `Group(kind, event)` takes the event first.
- An unknown chat type number is learned anew once (`learned`); the game's timestamp is taken off every line
  (`Untimed`, also the Classic `GetChatTimestampFormat`/`BetterDate`).
- The guild's message of the day was there twice (the game's line and ours): `Log.Motd` takes the game's line
  of the same moment as the guild's, and `Log.Line` leaves out one written after ours.

### Chat: a channel's tick hides all its messages
Tests: Chat 279 checks.
- `Log.Line`: a line of a channel's kind (`CHANNELn`) that comes with a message event we do not read (a
  community's channel, `CHAT_MSG_COMMUNITIES_CHANNEL`) is that channel's (`CHANNEL:n`), so its tick hides it; it
  went with the notices. Without an event, or with `CHAT_MSG_CHANNEL_JOIN`/`_LEAVE`/`_NOTICE...`, a notice.
- Test: every tick of the list, one after the other, takes exactly its messages out and brings them back.

### Chat: chat history; switches for system, creature, addon messages and channel joins; closer bubbles
Not tried in the game. Tests: Chat 276 checks.
- **Save chat history** (`history`, on) and *Messages kept* (`historySize`, 0 to 500, 100): `Log.Saved` at
  `PLAYER_LOGOUT` into `Core.Character("Chat").history`, `Log.Restore` at the login before the window shows,
  the messages a day old so they are faded out. `Log.Keep`: the log keeps max(200, history) messages.
- **Messages to show** (page Chat, General): `showSystem`, `showCreatures`, `showAddons` (on), `showJoins`
  (off). `ns.SHOWS` maps their groups to them; `Channels.Shown` and the new `Channels.Flip` (the list's
  ticks) use the setting for these, `mute` for the rest.
- **Channel joins and leaves** are a group of their own (`CHANNEL_NOTICES`: `CHANNEL_JOIN`, `CHANNEL_LEAVE`,
  `CHANNEL_NOTICE(_USER)`, `CHANNEL_LIST`, and every line of a `CHANNELn` kind without its event), hidden at
  first; they went with *System* or with the channel before.
- **Closer bubbles:** `Layout.SPACING` 3 (was 8).

### Chat: all bubbles alike, on a color or a game texture; Settings: a color swatch
Not tried in the game. Tests: Chat 264 checks.
- **One fill for every bubble**, yours too, and for the line to write in (`Bubble.Paint`); `Layout.THEIRS` and
  `YOURS` are gone. Only the text's color differs by kind of message.
- **Bubble background** (`bubbleBack`): *Solid color* or one of five quiet tiles of the game's own windows
  (`ns.BACKS`: Marble, Rock, Slate, Iron, Night). A plate can be tiled (`plate:Tile(file, size, alpha)`,
  `Plate.lua`): each of its seven pieces gets the texture coordinates of where it lies, from the plate's top
  left, measured anew on `OnSizeChanged`, so the tiling runs on without seams; Transparency is its alpha.
- **Bubble color** (`bubbleColor`, hex, at first `26262B`): a swatch, greyed out unless the background is solid.
- **Settings:** `Panel.Color` (the game's `ColorSwatchTemplate`, a click opens `ColorPickerFrame`, every move
  is set at once, Cancel sets the one before; `Panel.Hex`, `Panel.RGB`); `color = true` options in tabbed pages
  (`Tabbed.lua`; list pages skip them); `parentValue` greys a line out while a dropdown is not set to that value
  (`Config.Free`).

### Chat: every line the game's chat shows; the line to write in is grey
Not tried in the game. Tests: 258 checks (Chat).
- **Every other line** (`Log.Line`, was `Log.Note` for prints only): a hook on `AddMessage` of each of the
  game's chat windows (`CHAT_FRAMES` but the combat log) takes every line that is not of an event or a kind
  of chat we read ourselves (the chat type number, fifth value, and the event, eighth value). So the
  system's lines without an event (`DisplaySystemMessageInPrimary`), pings, loot, money, experience,
  reputation, battlegrounds, pet battles, boss emotes, channel notices and Battle.net toasts are notes now,
  worded as the game's chat has them. `CHAT_MSG_SYSTEM` is no longer read from its event. One line in two
  windows is taken once (`Fresh`, per frame). The time in front of a ping is taken off.
- **New groups to show:** *Pings*, *Loot, money and experience*, *Battlegrounds*, *Pet battles*; AFK and DND
  with whispers, boss emotes with creatures, channel and Battle.net notices with *System*. A channel's notices
  (`CHANNELn`) go with that channel.
- **The line to write in** has the others' grey fill (`Bubble.Paint`, was `Bubble.Yours` with the blue).

### Settings and Sync are part of Core
Not tried in the game. Tests: lint (4 addons), 183 checks (Core), 47 checks (Sync), 274 checks (Spellbook).
- **No addons of their own any more:** `src/Settings/` is `src/Core/Settings/`, `src/Sync/` is `src/Core/Sync/`,
  listed in Core's TOC after its other files; their TOCs are gone. Four addons: `SaneUI`, `SaneUI_Spellbook`,
  `SaneUI_Tooltips`, `SaneUI_Chat`. The folders `SaneUI_Settings` and `SaneUI_Sync` must go from the game's
  AddOns folder (the old Sync would load next to Core's).
- **Settings → `Core.Config`** (was the module `SaneUI.Settings`, load-on-demand). `Settings/Settings.lua` now
  puts up the pages at login (`PutUpPages`, `Core.pages`, `Core.frames`, `Core.Tabbed`, moved from Core.lua),
  hooks the options window's `OnShow` and owns `/sane options`; the controls are still made only when the
  options first open (`Config.Fill`, was `Config.OnLogin`). `Core.LoadSettings` is gone, and so is the message
  that the options are switched off. `## AddonCompartmentFunc` is in Core's TOC. Sane UI's banner is Core's
  (`src/Core/Art/banner.blp`, `Interface\AddOns\SaneUI\Art\banner`; `dev/tools/art` writes it there).
- **Sync → `Core.Sync`** (was the module `SaneUI.Sync`). Its switches keep the name `Sync`
  (`SaneUIDB.modules.Sync`): nothing saved changes. `Sync.Safe` notes as `Sync: <step>`; `Sync.OnLoad` runs
  at Core's `ADDON_LOADED` after Saved's and Profiles' handlers; the giving at `PLAYER_ENTERING_WORLD`.
  `module.optionsPage` is gone: Sync, no module, gets no page anyway. The CVar list always has its ticks and
  the filter *Kept*; the tab *Accountwide* always Sync's boxes.
- **Load cost:** the options' code (with the CVar labels) is read at login now, not when the options open;
  nothing of it runs or builds a frame before then.
- **Tests:** `W.LoadCore` reads Core's subfolders; `W.LoadSettings` and the Spellbook run `--no-settings`
  are gone; `core.lua` loads all of Core.
- **Tools:** `dev/tools/cvar-labels` writes `src/Core/Settings/Data/CVarLabels.lua`.

### Profiles: New Characters
Not tried in the game. Tests: 182 checks (Core and Settings).
- **Settings, tab *Profiles*, box *Characters*:** a first line *New Characters* with *Load at login*, *Save at
  logout* and a profile, gold, above the characters seen.
- **Core, `Profiles.lua`:** kept in `SaneUIDB.newCharacters`; `Profiles.Character(Profiles.NEW)` and
  `SetCharacter(Profiles.NEW, ...)` read and set it. A character with no line yet gets a copy of it
  (`Register`) at `ADDON_LOADED`, before `Arrange`, so *Load at login* counts from its first login; at
  `PLAYER_LOGIN` if the game gave no GUID before (then `Arrange` at once). Rename and Delete change it like
  every character's line (`Lines`).

### Profiles: SaneUI Defaults, always there and never changed
Not tried in the game. Tests: 175 checks (Core and Settings).
- **Core, `Profiles.lua`:** the profile *SaneUI Defaults* (`Profiles.DEFAULTS`) is always first in `List()` and
  never saved: made from the modules' descriptions (`Defaults`), it holds every switch at its default (the
  checkboxes, sliders and choices; Sync's: every part ticked, no CVar kept by name, nothing taken from the game)
  and follows each new version by itself. `Load` empties the settings in use of every module switched on and
  gives each switch its default (`Put`'s `fresh`), telling the modules; a module switched off keeps its own.
  With *Load at login* `Arrange` empties every module's, and one read later gets its defaults from
  `Core.Options`. `Duplicate` makes a profile of your own from it. `Save`, `Rename` and `Delete` refuse it
  (`Fixed`), no other profile takes its name, *Save at logout* never saves into it (`Character` reports
  `autoSave` false). `Exists` (any profile) is apart from `Saved` (a saved one). A saved profile of that name
  from before is moved to *SaneUI Defaults (old)*. Sane UI sets no CVar values of its own, so loading it leaves
  the game's values as they are.
- **Core, `Saved.lua`:** a table's default (Sync's `cvars`, `saved`) is copied into the settings, not shared
  with the description: what the module kept in it changed the default (`Core.Copy`, now also Profiles').
- **Settings, `Profiles.lua`:** with *SaneUI Defaults* chosen, *Rename* and *Delete* are switched off and *Save*
  offers no name; *Save at logout* is switched off on the line of a character that has it. Tooltips say so.

### Core: a docked window fills the screen from its screen edge; the kinds of motion; Chat: full screen
Not tried in the game. Tests: 161 checks (Core and Settings), 83 checks (windows), 254 checks (Chat).
- **Core, `Edge.lua` (new):** a window made with `Window.New(frame, { edge = true, ... })` and docked fills the
  screen when the mouse is pushed against that screen edge (a strip two physical pixels wide along each docked
  side, inside the window, strata `DIALOG`, only the mouse's coming: `OnEnter`), and goes back when pushed there
  again. Size and place spring from where the window is to the whole screen (then `SetAllPoints(UIParent)`) or
  back to its zone (`Dock.Rect`, new; then `window:Place()`); strata `HIGH`, unclamped and a solid black
  background (alpha with the way) while it is away; grip out of sight, no dragging or sizing. Its `content`
  fades out (0.15 s) and comes in once it stands (0.4 s, from 10 above); `docked`
  is called at the end, `filled(full)` at the start. Not within 0.25 s of a placing, not with a button held.
  `Place()` (a reset), hiding it, or a failing step bring it back at once; a failing step also switches it off
  for that window.
- **Core, `Motion.lua` (new):** kinds of motion, each a time and a curve, and one without motion;
  `Motion.Kind(key)` (nil or `"global"`: the general one), `Share`, `Choices`, and `Clock` (an animation group as a clock, as `Expand` had
  it, its step guarded). `Expand` moves by it (`Expand.Spring` and `Expand.TIME` are gone) and has `motion` and
  `still`.
- **Core, general switch** *Animation type* (`motion`) on the page *Appearance* under *Windows*: Core's
  switches name their page with `page = "Appearance"`. **Settings:** `Fill(page, name, onPage)` puts each on
  its page; the line that said *Appearance* had nothing yet is gone (`Note.xml`, `SaneUISettingsNoteMixin`).
- **Chat:** the window has `edge`; tab *Appearance*, under *Animations*: *Animation type* (`motion`, *Use global
  type* or one of Core's kinds), greyed out and without motion while all animations are off. Full, every message is
  there to read; the list is the content; the line to write in follows the window's layer (`Input.Layer`).
- `/sane window` fills the screen too. Tests: `wowstub` has `GetPhysicalScreenSize`; `core.lua` and
  `tooltips.lua` load `Motion.lua`.

### Chat: the animation lines renamed; Settings: room between a checkbox and its words
- **Chat, tab Appearance:** *Enable all Animations and Fades* (was *All animations*), *Opacity fade in speed*,
  *Opacity fade out speed* (were *Fade in*, *Fade out*), *Fade messages after* (was *Display messages for*).
  The keys stay.
- **Settings, `Panel.Check`:** the words 4 pixels right of the box (the game's template has them 2 into it), on
  every page of our own, Profiles too; in a tabbed page they line up with the words of a line without a box.

### Chat: its page in tabs, General and Appearance; Settings: a module's page in tabs
Not tried in the game. Tests: 246 checks (Chat), 160 checks (Core and Settings).
- **Settings, `Tabbed.lua`:** a module whose switches name a `tab` gets a page of our own drawn as Profiles is
  (title, the game's tabs, titled boxes per `header`), from its switches' descriptions: checkboxes, sliders
  (`Panel.Slider`, the game's `MinimalSliderWithSteppersTemplate`, value and `unit` beside it), dropdowns
  (`Panel.Dropdown`); `inline` puts a number on its parent switch's line; `parent` greys out (`Config.Free`).
  Replaces the sub-page of the entry below (`page`, gone again). Core: `Core.Tabbed`, the canvas page in
  `PutUpPages`.
- **Chat:** tab *General* (*Show native chat*, the channels), tab *Appearance*: *Messages* (*Text size*,
  *Transparency*, *Short names*) and *Animations*: *All animations*; *Fade in* and *Fade out* with a speed
  (0 to 2 s); *Display messages for* (s); *Opacity* of faded messages (new, `fadeFloorOn`, `fadeFloor`:
  faded messages fade to it, not to nothing); *Slide up speed* (0 to 2 s). New keys `fadeInOn`, `fadeInTime`,
  `fadeOutTime` (`fadeIn`, `fadeOut` are no longer read). All animations off now leaves every message on show.

### Chat: a page Appearance with the animations; Core: switches on a page under a module's, under another switch
Not tried in the game. Tests: 241 checks (Chat), 160 checks (Core and Settings).
- **Core/Settings:** an option's `page` puts it on a page of that name under the module's page (Core puts it up
  at login, `Core.pages["Chat/Appearance"]`); `parent` draws it under an earlier switch
  (`SetParentInitializer`), greyed out while any switch above it is off. Sliders with steps below 1 show two
  decimals. `Add` returns the initializer.
- **Chat, page Appearance** (Esc > Options > AddOns > Sane UI > Chat > Appearance): text size, bubble
  transparency and short names (moved from Chat), *Fade messages out* and its seconds (moved), and new:
  *All animations*, *Fade in (seconds)*, *Fade out (seconds)*, *Slide animation*, *Slide time (seconds)*.
  `Fade.Times`, `Window.Animate`; with no time a fade is at once, and `Refade` paints at once.

### Chat: gone messages stay gone when a new one comes; the fade-in shows
Not tried in the game. Tests: 229 checks (Chat).
- **Bug:** a new message brought gone ones back for a moment (to about a fifth). While a message is added the
  list keeps its scroll offset and is for a moment not at its end; its `OnScroll` counted as a scroll of
  yours and revealed every message, until the mouse ticker ended it. Only the wheel reveals now.
- **Fade-in** 0.4 s (`Layout.APPEAR`, was 0.25) and **slide** 0.3 s (`Layout.SLIDE`, was 0.2): a new message
  slides in from the list's bottom edge and is seen fading in on the way, not only once it is in.

### Chat: every message fades by itself, apart from the slide
Not tried in the game. Tests: 228 checks (Chat).
- **Fades kept on the message** (new `Fade.lua`): from, to, since and span on the entry; a row only shows
  `Fade.Alpha`. Before, the fades were animation groups on the list's rows, which the list hands to other
  messages when it lays them out: a new message coming while others faded out cut off or restarted
  their fades. Turning back starts from where it is.
- **Painting** (`Window` `Paint`, `Step`): `OnUpdate` on the window only while a message in view fades; one
  timer for the next message whose time is over (`Schedule`, `Due`).
- `Bubble.Fade`, `Bubble.Appear` and the rows' animation groups are gone. Fading in 0.25 s
  (`Layout.APPEAR`, was 0.15), out 1 s (`Layout.FADE`, was 2), eased.

### Chat: faded messages stay faded under the mouse; fade in, slide up, smooth scrolling
Not tried in the game. Tests: 217 checks (Chat).
- **Reveal** (`Window`): the mouse over the window no longer brings faded messages back; a turn of the mouse
  wheel over the list, or a scroll up, does, until the mouse is away at the newest message.
- **Fade in** (`Bubble.Appear`, `Layout.APPEAR` 0.15 s): a new message, and one shown again, on the row's body.
- **Slide** (`Window` `Slide`, `Layout.SLIDE` 0.2 s): two Translation animations on the list's `ScrollTarget`
  when the messages move up for a new one or for the line to write in.
- **Smooth scrolling:** `SetInterpolateScroll` on the list and its scroll bar.

### Chat: notes in bubbles, achievements and the guild's message of the day
Not tried in the game. Tests: 210 checks (Chat).
- **Notes** (the system's, emotes, printed lines) are bubbles too: in the middle of the row, in the others'
  fill, nothing above them, the text in the game's colour (`Bubble.Init`; the row's centred text is gone).
  `Layout.TextWidth` gives them a share of the row, `Layout.RowHeight` the bubble's height.
- **Achievements:** `CHAT_MSG_ACHIEVEMENT` (group System) and `CHAT_MSG_GUILD_ACHIEVEMENT` (group Guild) as
  notes, the name the player's link in brackets as in the game's chat.
- **The guild's message of the day** (`GUILD_MOTD`, `Log.Motd`): a note of the guild, in `GUILD_MOTD_TEMPLATE`.

### Chat: clicks go through, the scroll bar only scrolled up, a click on a name whispers
Not tried in the game. Tests: 206 checks (Chat).
- **Clickthrough:** the window takes no mouse any more (no `SetMouseMotionEnabled`, no `OnEnter`). The bar to
  move it by joins the grip and the chat button in `chrome`, hidden without the mouse over the window, so then
  only links and names take the mouse. A ticker (0.2 s, while the window is shown) asks `IsMouseOver` instead.
- **Scroll bar** (`Window` `Bar`): shown only while the list is scrolled up from the newest message, not with
  the mouse.
- **Names** are the game's link to the speaker (`Log` `Link`, `entry.link`: `GetPlayerLink`, or
  `GetBNPlayerLink` for Battle.net whispers): a click whispers to them, a right click opens their menu.

### Player names: first name and surname
Not tried in the game. Tests: 160 checks (Core and Settings), 276 checks (Tooltips), 274 (Spellbook).
- A Forever name is a first name and a surname; `UnitName` gives both (two values). Sane UI kept only the first.
  New `Core.FullName(unit)` (as the game's Camelot `NameUtil.FormatUnitNameForDisplay`: the separator is
  `Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR`). `Core.charName` is the whole name,
  so the Characters list of the page Profiles shows it (a character listed before updates at its next login).
- Tooltips: the target in a unit's panel and who cast a buff by the whole name; a player's title is found in
  `UnitPVPName` with the whole name, else the first name.
- Tests: the stand-in player is "Tester Stub"; Jaina is "Jaina Proudmoore" in the Tooltips suite.

### Game chat channels on the page Chat; Sync parts ticked in older saved settings
Not tried in the game. Tests: 194 checks (Chat), 47 checks (Sync), 160 checks (Core and Settings).
- **The game's chat channels** moved from the Sync module to the **Chat module**: a choice per channel under
  a header *Chat channels* on the page *Chat* (`ns.GAME_CHANNELS` and the switches in `Chat.lua`, the joining in the new
  `Join.lua`, through `ns.Safe` so an error there does not close the window). The tab *Chat channels* of the
  page Profiles is gone, and with it `Panel.Radio` (no other use).
- **Sync `Upgrade`** (at its `OnLoad`): saved settings of the first Sync version still had action bars, chat
  window places, graphics, sound and modifier keys unticked (the in-game settings showed them off). Every copy
  (`Core.Profiles.Copies`: in use, the account's kept aside, the profiles', this character's own) without
  `version` 2 gets those five ticked and its old `channel<id>` switches dropped, once.
- **Core:** `Core.Profiles.Copies(module)`.

### Profiles: All settings accountwide, modules account wide or not, a profile per character
Not tried in the game. Tests: 160 checks (Core and Settings), 53 checks (Sync).
- **All settings accountwide** (ticked at first, `SaneUIDB.separate` when not): for the account, replacing the
  per-character *Character specific settings*. Under it: *Ticked will sync all settings accountwide by
  default. Profiles overwrites the setting on a per character basis.*
- **Tab Accountwide** (was *Sync settings*): a first box *Sane UI* with a checkbox per module (General, Chat,
  Spellbook, Tooltips; `SaneUIDB.perCharacter`): unticked, that module's settings are each character's own.
  The tab's checkboxes are switched off while all settings are each character's. It is there without the Sync
  module too.
- **Characters** (tab Profiles): every character seen on the account (`SaneUIDB.characters`, noted at login),
  each on a line with *Load at login*, *Save at logout* and its profile. A character with a profile and Load
  at login uses it for itself only, not changing the account's; Save at logout puts its changes back into
  the profile. Set for any character from any character. The old per-character Load at login / Save at
  logout under the profile are gone.
- **Core `Arrange`:** each module's settings in use come from the account, the character's own or a profile,
  and are moved between them at login, when a switch changes and at logout. `Core.Profiles`: `AccountWide`,
  `SetAccountWide`, `Shared`, `SetShared`, `Characters`, `Character`, `SetCharacter` (were `Own`, `SetOwn`,
  `AutoLoad`, `AutoSave`, ...). `Core.realm`.
- **Sync:** every part ticked at first (also action bars, chat window places, graphics, sound, modifier keys).
- Tests: the Chat suite finds its window's title on the window itself (the options now have a "Chat" too).

### Profiles: a page with tabs and boxes; Sync in fine-grained parts
Not tried in the game. Tests: 156 checks (Core and Settings), 53 checks (Sync).
- **The page Profiles** is a page of our own (a canvas: `Settings.RegisterCanvasLayoutSubcategory`, one empty
  frame Core puts up at login, `Core.frames.Profiles`): its title, the line
  *Settings are saved account wide by default*, and tabs (`MinimalTabTemplate`, as the window's Game/AddOns)
  over a box: *Profiles* (boxes *Account or character* and *Saved profiles*: dropdown, Load, Save, Duplicate,
  Rename, Delete, Load at login, Save at logout), *Sync settings* (a titled box per group, checkboxes in two
  columns), *Chat channels* (a choice per channel), *CVars* (a line
  on what the ticks do, then the list). New `Settings/Panel.lua` (the parts) and `Settings/Synced.lua`; the
  list-page rows of the profiles (proxy settings, button rows) are gone.
- **Sync, fine-grained:** parts in groups: CVar parts by names, name prefixes or the game's own kind of
  CVar (Graphics, Sound), with hardware and character state never taken; plus chat window
  places and sizes, modifier keys (with `SaveBindings`), declined guild invitations, location for recent
  allies. Every CVar of a ticked part is kept, whoever the game keeps it for (was: only those it keeps per
  character). Off at first: action bars, chat window places, graphics, sound, modifier keys. New
  `Sync/Switches.lua` describes the switches in group order; `ns.Part`, `ns.GROUPS`, `ns.CVarsOf`.
- The test stand-in has canvas pages, tab groups, dropdown menus and the templates' parts.

### Options: Sane UI with only its logo, then Profiles, General, Appearance, the modules
Not tried in the game (the layout it replaces was). Tests: 150 checks (Core and Settings); the Spellbook, Chat
and Sync suites follow the new page names.
- **The pages:** *Sane UI* shows only its banner. Under it, in this order: *Profiles* (the profile rows
  without a header, the Sync module's sections, the CVar list), *General* (*Errors in chat*), *Appearance*
  (one line: nothing to set yet), then the modules' pages by their plain names: *Chat*, *Spellbook*,
  *Tooltips* (were *Sane Chat*, ...). `/sane options` and the minimap's addon list open *Sane UI*.
- **Core:** `Core.pages.top`, `.Profiles`, `[Core.name]` (*General*), `.Appearance`, then a page per module
  titled `module.title`; the game keeps that order (it sorts sub-pages only when asked). A module's
  `optionsPage` names one of Sane UI's own pages for its switches; Sync's is `"Profiles"` (was
  `onGeneralPage`).
- **Settings:** `Note.xml` (`SaneUISettingsNoteTemplate`), a line of text as a row.
- `CLAUDE.md`, the root README and the Spellbook and Tooltips READMEs name the pages as they are now.

### Sync, the game's CVars, and profiles loaded and saved by themselves
Not tried in the game. Tests: lint, 146 checks (Core and Settings), 43 checks (Sync, new), the other suites
unchanged.
- **New module Sync (`SaneUI_Sync`):** keeps the settings the game saves for each character with Sane UI's
  settings: the account's, a character's own, profiles. Parts, each a switch: Edit Mode layout (by name),
  chat windows (names, text size, colour, shown/locked/docked, message groups, channels; chat colours), your
  own chat channels, camera, nameplates, other game settings (the rest of the per-character CVars, without
  tracked/collapsed/counted/last-chosen state; guild invitations), action bars shown (off at first).
  - Taken when Sane UI's settings are saved (logout, profile save: Core's new `capture`), and only after the
    session gave them; given 2 s after entering the world, after a fight if in one, and when a profile is
    loaded. Only what differs is set.
  - Only CVars the game keeps per character (`GetCVarInfo`), found at run time (`ConsoleGetAllCommands`): no
    lists of CVar names; the account's and the computer's are shared by the game already.
  - All through the game's stored settings (C_CVar, `SetChatWindow*`, `Add/RemoveChatWindow*`,
    `ChangeChatColor`, `C_EditMode.SetActiveLayout`, `SetActionBarToggles`), never its frames: no taint. Chat
    windows and action bars show after a `/reload`; a dialog offers one when they changed.
  - The game's chat channels joined or left on every character as chosen; nothing while chat is locked
    down.
  - Its switches are sections of the general options page (`module.onGeneralPage`), not a page of its own.
  - Left out: graphics, sound and modifier keys (shared by the game already), and whatever would write into
    the game's frames or tables.
- **Settings, section *CVars*:** every CVar of the game in one list on the general page, searchable, each
  with a tick to keep it (Sync), its help, its default and its value. Read-only and locked ones are not changed, secure ones not in a fight. One row of the settings
  list with its own scroll box (`CVars.lua`, `CVars.xml`).
  - Labels: `Data/CVarLabels.lua`, made by the new `dev/tools/cvar-labels` from Blizzard's options code in
    `references/`: names of the game's strings only (239 CVars), the text comes from the game.
- **Profiles:** *Load at login* and *Save at logout*, this character's, for the chosen profile (children of
  the dropdown). Loading happens at Core's `ADDON_LOADED` before any module reads its settings (also at a
  `/reload`); saving at `PLAYER_LOGOUT` after the capture.
- **Core:** `Core.Options(name, list, changed, capture)`; options may carry `header`/`headerTip` (a section
  on the page) or no `text` (kept, without a control). `Core.pages` gives a module with `onGeneralPage` the
  general page. The general switch is now called *Errors in chat*.
- **Settings:** the general page in the order General, Profiles, the Sync module's sections, CVars; `Fill`
  makes section headers and skips switches without text.
- **Tests:** `dev/tests/sync.lua` (new), with a model of the game's chat windows, channels, Edit Mode and
  action bars. The stand-in has CVars (`W.cvarInfo`: default, where kept, secure, read-only, kind),
  `ConsoleGetAllCommands`, header tooltips, rows that can be children, and `W.LoadAddon` (a module by its
  TOC, folders too).

### Profiles: the account's settings or a character's own, and named copies of them
Not tried in the game. Tests: lint, 121 checks (Core and Settings), the other suites unchanged.
- **New section *Profiles*** on the general page *Sane UI*, under *General* (Settings, new `Profiles.lua`):
  - *Character specific settings* (checkbox): ticked, the character has settings of its own, at first a
    copy of the account's; unticked, it is back on the account's and keeps its own for the next time.
    Modelled on the game's *Character Specific Key Bindings* (a proxy setting without a default, so the
    options' *Defaults* button leaves it alone).
  - *Profile* (dropdown) with the buttons *Load*, *Save*, *Duplicate*, *Rename* and *Delete* under it,
    drawn as its children (indented; switched off while there is no profile). Names are asked for in the
    game's own `GENERIC_INPUT_BOX`, deleting is confirmed in `GENERIC_CONFIRMATION`; nothing is added to
    `StaticPopupDialogs`. Save offers the chosen profile's name; a taken or empty name for Duplicate or
    Rename is refused with a line in chat.
- **Core, new `Profiles.lua`:** `Core.Profiles` keeps and does all of it. A profile
  (`SaneUIDB.profiles[name][module]`) holds the switches of every module there are saved settings for,
  for all characters. Loading copies into the tables the modules hold (never replaced), puts spoiled
  values right (`Core.CheckOptions`, the old `Defaults` of `Saved.lua`) and calls each module's
  `changed(key, value)` for every switch that changed.
- **Per-character saved settings:** Core declares `SaneUICharDB` (`own`, `settings`, `profile`). With
  own settings, the account's are copied aside into `SaneUIDB.account` at Core's `ADDON_LOADED` and put
  back at `PLAYER_LOGOUT`, so the shared file always holds the account's for other characters; a leftover
  from a logout that did not finish is put back at the next login. With the account's settings in use
  nothing is copied.
- **Settings:** `Config.Refresh` shows values changed under the controls (`NotifyUpdate`), with the
  modules' callbacks muted, as Core told them already. The test stand-in has proxy settings, button rows,
  `NotifyUpdate` and the game's two generic dialogs; `W.LoadSettings` reads the Settings module by its
  TOC (the Spellbook and Chat suites use it too).

### Images: a guide, and the textures sized for 4K
Not tried in the game. Tests: lint, 85 checks (Core and Settings), the other suites unchanged.
- **New guide `Doc/guides/images.md`:** how a picture becomes a texture (format, size for 4K, encoder,
  drawing it), with the measurements behind each choice and what was tried and rejected, so it need not
  be looked up again. Listed in `CLAUDE.md`, `AGENTS.md` and the GUI guide. `dev/tools/art-measure`
  repeats its measurements (the graphics card's sampler simulated, PSNR against a perfect resize).
- **Sized for 4K:** `dev/tools/art` takes the size a picture is drawn at (UI units) and makes each side
  the power of two that holds 85 % of what a 4K screen at UI scale 1 shows (2.81 pixels a unit). The
  picture keeps its proportions in the texture (no longer squeezed in); the rest is cut off with
  `SetTexCoord`. Banners are now 1024 x 256 (342 KB; the 3 : 1 box fills the left 768), icons 128 x 128,
  the logo 256 x 256: 1.5 MB in all. Measured against the old 512 x 256: 2.8 dB closer to the drawing
  on 4K, 2.7 dB on 1440p.
- **The game's own filter for the banners,** not `TRILINEAR`: art drawn between half and full size of its
  file came out up to 5 dB blurrier with it. The banner sets its texture coordinates after `SetTexture`.

### Art and banners in the options
Not tried in the game. Tests: lint, 84 checks (Core and Settings), the other suites unchanged.
- **The art:** the banners, icons and logo drawn for Sane UI (PNGs in `assets/`, 1.6-1.9 MB each) are
  made into game textures by the new `dev/tools/art`: BLP2 with DXT5 and a full chain of mipmaps, as
  Blizzard's own logos are, in `assets/optimized/`. Banners 512 x 256 (171 KB), icons 128 x 128
  (22 KB), the big logo 256 x 256 (86 KB): 864 KB in all, from 15.3 MB. On the way the drawings' solid
  parts (alpha 252-253, a left-over of cutting them out) become fully solid, and the edge colour is
  carried into the clear pixels, so no dark seam shows. The DXT5 blocks come from ImageMagick's cluster
  fit: Pillow's own writer washed out the letters.
- **Banners in the options:** each page shows the banner of the addon it belongs to at the top, in place
  of the page's title: the general page Sane UI's (above *General*), *Sane Spellbook*, *Sane Chat* and
  *Sane Tooltips* their module's. A module ships its own as `Art/banner.blp`; Sane UI's is the Settings
  module's. The banner is a row of the game's own list (`Banner.xml`, `SaneUISettingsBannerTemplate`):
  made only when its page is shown, drawn at 300 x 100 with `TRILINEAR` filtering; the game's title is
  hidden only while the row is there (another page or scrolling it away brings it back). An addon
  without a banner file keeps the game's title (`SetTexture` reports the missing file).
- **Docs:** the GUI guide says how own pictures ship; `assets/` is listed in `CLAUDE.md` and the README.
  The original PNGs in `assets/` are not committed.

### Project: context for future coding chats
- Added `AGENTS.md` and compact notes in `Doc/agent/`: task routing, module architecture, saved data,
  secure execution and fallback contracts, development commands and pending client QA.
- Added `dev/tools/project-index` and its generated file index: hashes detect source changes,
  declarations/headings and TOC order help find the relevant files without rereading the project.
- Recorded existing documentation discrepancies; no addon behaviour changed. Offline suite passed:
  lint and 1,117 checks. External reference libraries and personal state stay outside the index.

### Tooltips: review fixes
Not tried in the game. Tests: 252 checks (Tooltips).
- **Fixed:**
  - Debuff panels take their kind's colour: `DebuffTypeColor` does not exist in this client; the colours
    come from `AuraUtil.GetDebuffDisplayInfoTable()` (the test no longer stubs the missing global).
  - A unit's panel freezes while its tooltip fades after the mouse left (it kept reading "mouseover":
    bars dropped to 0, or another unit's numbers showed). The unit's GUID is kept in the model's head.
  - Sizes measured through a hidden (secret) anchor: the panel's points are cleared before it is
    measured; a size the game hides spoils only that draw, and that tooltip is the game's this time.
    `GetFrameLevel` and `GetEffectiveScale` go through `Plain`.
  - The comparison tooltips can no longer anchor in a circle: `Release` clears points, `Beside` falls
    back to the corner if the game refuses an anchor.
  - Other addons' tooltips that nobody sees (owned, placed nowhere) get no panel, and a panel whose
    tooltip is no longer placed is released, which also stops its `OnUpdate`.
  - Releasing gives the tooltip its alpha first, then each part on its own.
- **A part fails, not the whole:** each kind's reader runs on its own; a reader that fails (a renamed
  game function) makes that kind's tooltips the game's own and says so once, the others are still drawn.
  The mouse switch is `Safe`, so it works after a stand-down. Core's `Guarded`, `StandDown` and
  `GiveBack` replace the module's own copies.
- **Lighter:** what your quests want from a creature or NPC is kept per NPC until your quest log or
  level changes (it was worked out at every read, five times a second on a unit frame), with no tables
  made; no substrings per line; the tooltip's named parts are looked up once; panels are made when first
  needed, not at login; the inspect list and the auction prices (older than 30 days) are pruned.
- **Tidier:** the pools in their own file (`Pools.lua`; `Panel.lua` 771 → 596 lines), one palette
  (`ns.COLOR`, the "done" green is the unit section's), one colour code helper, one font helper, one NPC
  id, prose and rank check each; dead code removed; three different "Numbers" renamed.
- The quest database stays loaded at login: it costs about 5 ms and 1–1.6 MB and is needed on the first
  creature you hover, so a load-on-demand addon would gain nothing noticeable.

### Chat: review fixes
Not tried in the game. Tests: 185 checks (Chat).
- **Fixed:**
  - Party and raid rings: `C_PartyInfo.IsGUIDInGroup` (the global `IsGUIDInGroup` is only a deprecated
    wrapper that may be missing, and every stranger's message raised a caught error).
  - A minimised undocked chat window (`ChatFrame<n>Minimized`) is hidden with the game's chat too; a frame
    the game moved to another parent meanwhile is left where the game put it when ours goes.
  - Errors keep the place they happened (`ns.Guarded`, Core's, instead of a plain `pcall`).
  - Giving the edit box back undoes its strata, level, alpha and mouse; anchors are put back with
    `Core.Repoint` (no `unpack` hole).
  - Community channels show their names (`ChatFrameUtil.ResolveChannelName`).
  - **Chat in a fight or a dungeon:** while chat is locked down (`C_ChatInfo.InChatMessagingLockdown`,
    `ADDON_RESTRICTION_STATE_CHANGED`) addons get no messages to show, so the game's own chat is on show
    for that time even with *Show native chat* off. Before, chat could vanish entirely.
- **Less taint:** our code no longer hides the game's edit box; the game puts it to rest itself, and in
  IM style a hook after its `Deactivate` makes it invisible. The chat picker still sets the chat type
  from our code: documented in the README, to be checked with `/console taintLog 1`.
- **Lighter:** a full log drops 25 messages at once with one list update (was two full rebuilds per
  message); a channel's short name, a sender's class and what a speaker is to you are cached (capped,
  cleared when friends, guild or group change); typing re-anchors only when the line's height changes;
  while the window is sized only the edit box follows, the bubbles rewrap once at the end; no closures
  per wake or fade.
- **Hardening:** `ns.GiveBack` gives back step by step (edit boxes and their anchors first), each step on
  its own; an unreadable message is left out and noted instead of closing the window; the
  `EventRegistry` callbacks are unregistered on a stand-down; menu callbacks, wake and fit are guarded.
- **Tidier:** one list of chat kinds (`Log.GROUPS`) and one visibility check (`Channels.Shown`); one
  round mask (`ns.Round`); the chat picker in its own file (`Menu.lua`); `Core.charKey`, `Window.Reset`
  and `RGBToColorCode` instead of copies.

### Spellbook: review fixes, lighter at login
Not tried in the game. Tests: 274 checks (Spellbook) and 270 with the Settings module switched off.
- **Fixed:**
  - A takeover that failed half way (a template missing) no longer leaves the column 60000 high: our
    frames are made into locals and kept only when all could be made; a failed `Arm` stands the book
    down and gives back what was taken; the column's own height is only noted below `TALL`.
  - Home no longer draws itself again over the game's page after `SetHome` fell back; its tab and cover
    clicks run through `Safe`.
  - A spell the game pushed onto a bar is taken off only the slot the game used
    (`SPELL_PUSHED_TO_ACTIONBAR` gives spell, slot and page); your own copy elsewhere stays.
  - A window reset or fallback in a fight is done when the fight ends; the small spellbook's inset is 3
    (809 against 806 in the game's XML), the open one's 6.
  - The tab row moved for Home is put back after a fight if a fight kept it; the search box beside it is
    sized like the game sizes it (`FitSearchBox`), without calling the game's code.
  - A hidden (secret) action slot is "unknown": a reservation is neither ended nor filled on a guess.
  - Saved data of the wrong shape (reservations, layouts, trainer rows, extras) is dropped or skipped.
- **Talents:** the game's own talent tree stays. `## OptionalDeps` is gone from the TOC.
- **Lighter:**
  - The trainer data is filled at login for your class only (`D.Class`, `D.AtLogin`, `D.Fill`); the
    other eight classes' tables are never built, and nothing reads the game while the files are read.
  - The list of spells still to come, and the name requests to the game, are built only when the pages,
    Home or a command read it and something changed (`S.All`); what you have (`S.ScanBook`) is read out
    of a fight only.
  - The watcher that keeps entries in place looks every frame for 10 frames after a layout, then five
    times a second. The reserved mark is a yes/no without a table. Trainer rows already kept are not
    read again. Bar ghosts do nothing on hover unless shown, and stop looking for buttons once all have
    one. A drag looks the bar buttons up once. `IsSpellKnownOrInSpellBook` where the client has it.
  - The `ITEM_DATA_LOAD_RESULT` listener, which could never act, is gone.
- **Tidier:** dead code removed (`binding`, `ns.GOLD`, `ns.charKey`, `D.Target`, `E.Swap`,
  `E.PlaceCursor`); duplicates merged (`L.Compare`, `L.ByLevel`, `B.Locked`, `B.Header`, `I.TextColor`,
  `RequestSpell`); the marks moved to `Spellbook.lua`; Core's `Coins`, `Ask`, `Points`/`Repoint`, `Trace`
  and `Later` used. Moving the takeover out of `Book.lua` was left: it shares about 30 of its locals.

### Core: the options' AddOns tab, shared tools, hardening
Not tried in the game. Tests: 80 checks (Core and Settings).
- **Fixed: the game's options had no AddOns tab** (so no Sane UI pages) when Sane UI was the only addon
  with options. `SettingsPanelMixin:OnShow` hides the *Game* and *AddOns* tabs for the session if no addon
  category exists when the window first opens, and Settings (load on demand) was only read after that, from
  a hook after `OnShow`. Core now puts up the pages at login, empty (`Core.pages`; only when the Settings
  addon is switched on for the character), and Settings fills them when it is read. Settings stays load on
  demand. A module whose switches fail to go on its page no longer keeps the others from theirs.
- **Shared tools in Core** for the modules, so none keeps a copy: `Core.Report` (keep a problem and tell
  it once; replaces `Safe(label, error, problem)`), `Core.Trace` (the `xpcall` handler), `module.Guarded`
  and `module.StandDown` with the module's `GiveBack` and `GIVEN_BACK` (a feature that stands in for the
  game's gives it back when a step fails), `Core.Later` (once, a moment later), `Core.Ask` (a game function
  that may be missing or fail, its answers plain), `Core.Coins`, `Core.Points`/`Core.Repoint`.
- **`Core.Safe` makes no garbage**: no table and no closure per call (the game's `xpcall` hands the
  arguments on).
- **Hardening of the saved settings:** a saved value of the wrong shape (an older version, a hand edit) is
  replaced instead of breaking the load; a switch of the wrong kind gets its default; a number is kept
  within its ends. `Core.NoteError` cannot fail on a spoiled error list (it runs while an error is handled).
  `Window:Place` copes with a window without minimum sizes.
- Guides: `gui-development.md` says why an options page must be registered before the window first opens;
  `addon-standards.md` names the new tools.

### Core: windows
Not tried in the game. Tests: 56 checks (`dev/tests/window.lua`, new), 155 checks (Chat), Spellbook unchanged.
- **A library for windows in Core,** so no module moves or sizes a window with code of its own:
  - `Window.lua`: `Core.Window.Mover` and `Sizer` (the dragging and a grip, for a frame that is not ours),
    and `Core.Window.New` (a window of ours: bar, grip, docking, skin, the place kept in the module's
    store as `{ x, y, width, height, dock }`).
  - `Dock.lua`: twelve zones at the screen's edges (four corners, left, right, three along the top and
    along the bottom). A window let go within 60 of one hangs on it; a tinted shape shows where while it
    is dragged. `Dock.Find` is plain numbers.
  - `Skin.lua`: dark fill and the game's tooltip border in bronze. On a docked side it reaches out of the
    screen by the border's width, so the window is flush with the edge there.
  - `Expand.lua`: a window opens to a larger size when the mouse comes (anywhere on it, or in one corner)
    and closes when it left; the size springs. Driven by one of the game's animations.
  - `Demo.lua`: `/sane window`, a window to try all of it.
- **Chat** uses `Core.Window.New`: its own drag scripts, `PanelResizeButtonTemplate` and place keeping
  are gone. New: it docks, and its grip leaves the lower right corner when that is at the screen's edge.
  The kept place has the same shape as before.
- **Spellbook** uses `Core.Window.Mover` and `Sizer` for its bar and grip; what it does around them
  (the game's sizes, the two modes, fights) is unchanged.
- Tests: the stand-in client reads Core's files from its TOC (`W.LoadCore`) and knows a button's
  textures and `SetCursor`; `dev/tests/run` runs `window.lua`.

### Spellbook, evening
Not tried in the game. Tests: 263 checks (Spellbook) and 259 more with the Settings module switched off.
- **The spellbook can be moved and resized** (`Book/Window.lua`, new): a drag bar over the window's title
  and a grip in its lower right corner, both frames of the module. Size (one for the open book, one for
  the small spellbook) and place are kept in `SaneUIDB.modules.Spellbook.window` and put on the game's
  window again after the game sizes or places it (hooks after `OnShow`, `UpdateSize`,
  `UpdateUIPanelPositions`); only on the spellbook tab, while the pages are the module's, out of a fight.
  Switch *Let me move and resize the spellbook* (on); `/sane sb window reset`.
- **The pages follow the window's size** (`Book.lua`, `Measure`, `B.Layout`): page width and height, columns
  and rows come from the spellbook frame's size at every draw; the right page is placed from the left
  page's frame. `Layout.Paginate(groups, cellWidth, viewHeight, metrics)` takes columns, entry height
  and paddings. Home draws with the same measures.
- **Compact pages:** switch *Compact spellbook pages* (on). Entries, the game's and ours, are scaled to
  0.75 and padded 8 and 4 instead of 15 and 10: four columns of ten on the game's own page (were three of
  seven). `Place` takes a size; a fallback gives every entry the game's size back.
- Tests: the stand-in client knows a frame's scale and size.

### Tooltips: a chat link's tooltip in the middle of the screen, closed by a click, no X
Tests: 286 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **In the middle:** `ItemRefTooltip`'s `OnShow` is hooked (`Pin` in `Tooltips.lua`) and puts it at the
  screen's `CENTER`; `SetItemRef` gives it `ANCHOR_PRESERVE`, so that stays. `Native`'s `Corner` gives
  `CENTER` for a tooltip held by its middle alone, so the panel stands in the tooltip's middle.
- **A click closes it:** hooks on `OnMouseDown`, `OnDragStart` and `OnMouseUp`; a press that began on it
  and did not drag it calls `Hide` (what the X's `HideUIPanel` does for it; `HideUIPanel` from an addon is
  refused in a fight). Dragging still works. In `ns.Safe`, like the mouse switch.
- **The mouse where the panel is:** `Native.Reach` (in `Cover`, for a tooltip that `IsMouseEnabled`) sets
  the tooltip's `SetHitRectInsets` to the panel's edges and takes the mouse off the game's invisible X;
  `Release` gives both back. So hovering (comparisons with Shift), dragging and clicking follow the panel.
- **No X:** the panel's own close button is gone (`Panel.Draw`, `CLOSE`).

### Tooltips: gone at once when the mouse leaves
Tests: 275 checks (Tooltips). Not tried in the game. `/reload` is enough.
- The game lets a tooltip fade out slowly once the mouse has left a unit or a thing in the world
  (`GameTooltip:SetWorldCursor`) or a unit frame (`UnitFrame_OnLeave`): both call `FadeOut`. Every
  adopted tooltip's `FadeOut` is hooked (`Faded`): its panel hides at once and a waiting draw is dropped
  (`pending`). The game's tooltip is not hidden from here (taint); its parts keep alpha 0 until it hides
  and `Release` gives them back.

### Tooltips: fixed: the comparison of what you wear jumped between two places again
Tests: 271 checks (Tooltips). Not tried in the game. `/reload` is enough.
- Came back with the review fixes: `Native.Release` lets go of the panel's points (so two comparison
  panels cannot hang on each other), and `Filled` then placed a refreshed panel with `Cover`. The game
  refreshes a comparison several times a second with `SetOwner` (which hides it) and `ClearAllPoints`,
  fills it, shows it and only then gives it its points: `Beside` found none, the panel went to the
  corner of the game's own tooltip, and the draw at the end of the frame put it beside the other panel
  again. Now `Release` notes where the panel stood, and the refreshed panel waits there, hung on
  `UIParent` only (`Native.Stay`), until it is drawn and placed beside the other panel.

### Tooltips: descriptions in the middle; done objectives left out
Tests: 269 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Descriptions** (a spell's, a buff's: the rows marked `prose`) are centred, each of their lines
  (`Panel.Draw` hands their text `"CENTER"`).
- **A creature's quest lines** leave out what is done: an objective the game says is `completed`, or
  whose count is full (*7/7*: `Done` in `Kinds/Unit.lua`). A quest's name and a party member's line are
  held back until an objective under them is still to do, so a quest with all done here is gone too.
  The tick (`check`) is no longer used there; a quest link keeps its ticks. The unused `titled` is gone.

### Tooltips: the mouse option a dropdown; Always and Default at first
Tests: 267 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Tooltips at the mouse cursor** (`cursor`) is one of `default` (where the game puts them; the new
  default), `shift`, `ctrl`, `alt`, `always`; was a switch. A tooltip the game places with
  `GameTooltip_SetDefaultAnchor` goes to the mouse when the choice holds; where the game put it is noted
  (`placed`), and a key pressed or let go while it is shown moves it to the mouse and back (`Follow`, with
  `SetAnchorType`, which keeps its lines; `SetOwner` would clear them). Its panel follows.
- **Show tooltips** is `always` at first (was `shift`).
- **Older settings** are put right before `Core.Options` checks them (they were in `OnLoad`, after it):
  version 3 makes a saved mouse switch `always` or `default`, and a saved `shift` for *Show tooltips* (the
  default of one day) `always`.

### Tooltips: seen only while a key is held; Settings: dropdowns
Tests: 261 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **The option *Show tooltips*** (`show`, default `shift`): while Shift, Ctrl, Alt, or Shift and Alt are held,
  or `always`. A tooltip that may not be seen yet is filled, placed and drawn as always; only its panel (or
  the game's tooltip where it has none) is see-through (`ns.Allowed`, `Gate` in `Tooltips.lua`; the panel's
  own strength is `panel.strength`, as `panel.alpha` is Native's note of the tooltip's alpha).
  `MODIFIER_STATE_CHANGED` shows or hides the shown tooltips at once.
- **Core:** an option can be one of a few (`choices = { { value, words }, ... }`); a saved value that is none
  of them gets the default (`Saved.lua`, `Chosen`).
- **Settings:** such an option is a dropdown (`Settings.CreateDropdownInitializer` with a
  `CreateControlTextContainer` of the choices). The test stand-in has both.

### Tooltips: quest data by side; grey default panels; more tooltips hooked
Tests: 236 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Quest data by side:** `Data/Quests.lua` tags what differs by side: a giver or a dropping creature that
  is one side's only ends in `h` or `a`; races, next quest and breadcrumb goal that differ read "h32 a15".
  `Quests.lua` takes the player's side (`UnitFactionGroup`). 21 tagged entries, 3738 creatures with quest
  drops.
- **Default panels are grey:** a tooltip of a kind without a reader of its own (a mailbox, a herb, a hint)
  no longer takes its colour from its name (often gold); `NEUTRAL` is the dead unit's grey (was a blue grey).
- **More tooltips take hints:** `ItemRefShoppingTooltip1/2`, `GameNoHeaderTooltip`, `GameSmallHeaderTooltip`,
  `BuffFrameTooltip`, `AuraButtonTooltip` are hooked at login too (those filled from data were already).

### Tooltips: a dead creature keeps its portrait and dragon
Tests: 235 checks (Tooltips). Not tried in the game. `/reload` is enough.
- The game fills a dead creature's tooltip as a corpse's (`Enum.TooltipDataType.Corpse`), which had no reader
  of its own and got the plain panel: no portrait, no dragon, no bars. It is read as a unit now
  (`Kinds/Unit.lua`); a corpse's data that does not say whose it is means the creature under the mouse, when
  the names agree (`Token`). Alt shows its NPC ID too (`Read.lua`).

### Tooltips: room under the name; no class for friendly NPCs
Tests: 232 checks (Tooltips). Not tried in the game. `/reload` is enough.
- A row close under the one before it (`row.flush`: a guild or an NPC's title under the name) now has a gap
  `FLUSH` (1) smaller than the usual one; was the usual gap and 2 more taken away, which left none.
- A creature's class is not shown when it is friendly to you (`UnitReaction` 5 or more: vendors, trainers).

### Tooltips: a larger quest database; grey panel for dead and offline units
Tests: 231 checks (Tooltips). Not tried in the game. No new file: `/reload` is enough.
- **The quest database grows:** 4606 quests (969 of them new, mostly Forever's own, IDs 90000 and up),
  1814 NPCs, 3732 creatures; 555 KB (was 456 KB).
- **Dead, ghost or offline:** the unit's panel takes a grey colour (`GONE`), which the background's gradient
  makes grey at the top and nearly black at the bottom.

### Tooltips: auction prices of our own
Tests: 229 checks (Tooltips). Not tried in the game. A new file (`Auction.lua`): restart the game.
- **The *Auction* row** is the module's own: `Auction.lua` (new) notes the lowest buyout of each thing
  whenever the game lists auctions (`AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` / `_ADDED`,
  `C_AuctionHouse.GetBrowseResults`) in the module's saved store (`prices[item]`, `seen[item]`: the day).
  Nothing is asked of the server. A thing never seen there has no *Auction* row.

### Tooltips: our own quest database
Tests: 229 checks (Tooltips). Not tried in the game. New files (`Data/Quests.lua`): restart the game.
- **The module's own quest database,** `Data/Quests.lua`, made by a tool of ours: `QUESTS[quest]`,
  `GIVERS[npc]` (gives; takes back), `DROPS[npc]`. Strings, taken apart on demand.
- `Quests.Of(npc)`: what it drops for your quests (objective from `C_QuestLog.GetQuestObjectives`, not when
  finished), the quests in your log it takes back (`ReadyForTurnIn`), the quests it offers (by the fields
  the database has). A broken entry ends the list there.
- **The quest section** merges the game's quest lines (kill or loot) with the database's loot for your
  quests, under the same quest name; objectives written count first ("0/7 Young Nightsaber slain") are read
  too. Offers and hand-ins: the quest's name like a quest's, under it *Offers* / *Turn in* / *In progress*
  with the game's ! or ? and the quest's level in its difficulty colour.
- **Licence:** the Tooltips module has a licence of its own (`src/Tooltips/LICENSE`, TOC
  `X-License`). `dev/build` copies a module's own `LICENSE` into its addon where it has one.
- **Dead creatures:** the game's *Corpse* line is left out (the class line says *Dead*); *Skinnable* (or
  what gathering it needs) goes on the class line in the game's colour for it. A creature whose "class" is
  its own name (the game's answer for one without a class) shows none.

### Tooltips: NPC title and faction in the header; a section for experience and quests
Tests: 227 checks (Tooltips). Not tried in the game. A new file (`Quests.lua`): restart the game.
- **An NPC's title** is the game's line before its level line (*Bowyer*, *Vendor*; was: only a line in
  `<...>`), shown like a guild; **its faction** the line right after the level line (not a skinnable or
  corpse line: `NOT_FACTION`), shown after what it is (*Humanoid · Stormwind*). A creature's **class** is
  always said (was: only when not a warrior).
- **A section for experience and quests** (`QuestSection` in `Kinds/Unit.lua`), under the bars: XP and
  kills to level, then the quests (`Quests.lua`, new): each quest's name, a sword (`Interface\CURSOR\Attack`)
  before what to kill, a sack (`Interface\CURSOR\LootAll`) before what to loot with its drop chance, the
  game's ? before a quest to hand in (*Turn in* in green when complete), the game's ! before a quest it offers
  (with its level). The game's quest lines are left out when the section has the objectives.
  Without it the game's quest lines are shown in the section the
  same way: the icon now before the objective (was: at the right), its count at the right, a tick when done.

### Tooltips: spec, titles, tapped; spell columns, Healing/CC/Utility; health numbers centred
Tests: 218 checks (Tooltips). Not tried in the game.
- **Spec** (`Inspect.Talents`): on this client a class's talents are one trait tree with three groups
  (`C_Traits.GetGroupDisplayInfoByTreeID`), each with its spent points (`C_Traits.GetGroupCurrencyInfo`, as
  the game's talent frame shows them). The group with the most points is the spec: "Fire Mage 0/31/20" on
  the class line. Yours from `C_ClassTalents.GetActiveConfigID` (read again after 5 s); another player's
  with `INSPECT_TRAIT_CONFIG_ID` when the inspection for the item level answers, kept with it. The spec IDs
  of this client are one per class, so `GetInspectSpecialization` says nothing.
- **Guild rank** small after the guild (`row.label`, `detail`); a player's **title** (`UnitPVPName` less the
  name, e.g. a PvP rank), unless the name line has it already.
- **Creatures:** the title line (*<Flight Master>*, or a pet's owner: `UnitOwner` line) as large as the name,
  close under it; the family after what it is (`UnitCreatureFamily`: *Beast · Wolf*); *Tapped*
  (`UnitIsTapDenied`) on the class line.
- **Health numbers** in the middle of the bar (were raised above the power strip). A bar's words stand on a
  frame of their own over the bar (`bar.words`), so the power bar laid over the health bar does not cover them.
- **Spells in columns:** the spell's numbers in pairs of columns; a spell without numbers in one strip.
- **What a spell is** under its name for every spell: its school; else *Healing* (heal or absorb named
  first), *CC* (`STATS.controls`: stun, fear, polymorph, root, ...; blue), *Physical* (damage), *Utility*
  (no colour). A swing is *Physical*.

### Tooltips: unit header in four lines, a weapon's numbers in one, a small plaque
Tests: 212 checks (Tooltips). Not tried in the game.
- **Unit header:** the guild in the name's font (`title`), close under it (`row.flush` now works for text
  rows too: the row gap and `FLUSH` less). Race (a creature: what it is) on its own line; under it the class
  line (`ClassLine`): the class (a creature's only when not a warrior), a creature's rank (*Elite*, *Boss*
  gold; *Rare*, *Rare Elite* silver), *PvP* red, *AFK*/*DND* yellow, *Offline*, *Dead*, *Ghost* grey.
  A dead creature gives no experience.
- **A weapon in one line:** "3.2 DPS  ·  1 - 3 dmg  ·  2.00 spd": the number and *DPS* large, the rest
  smaller after it on the same base line (`row.labelFont`, placed `BASE_LINE` of the size difference
  lower). Was: *DPS 3.2* with the damage line under it.
- **The plaque** is hardly larger than its words (`PLAQUE.pad` 2, `least` 22; was 7 and 14 more than the
  words). Rows beside the portrait that reach the plaque's height make room for a plaque wider than the
  portrait (`reserve`). The plaque's settings are one table (`PLAQUE`): `Panel.Draw` was over Lua 5.1's
  60 upvalues.

### Tooltips: items short and clear, prices, spell numbers, experience, a plainer plaque
Tests: 208 checks (Tooltips). Not tried in the game. A new file (`Numbers.lua`): restart the game.
- **Item header:** the line over the name says how it binds, short as players write it (`TEXT.BINDS` by
  `Enum.TooltipDataItemBinding`: BoP, BoE, BoU, BoA, WuE, Soulbound, Quest; red until bound), or *Equipped*
  on a comparison (`head.compared`, which now alone makes a panel stand back), and whether you have the
  look (*Uncollected*, *Look known*, from the game's transmog lines). Kind and slot are small and grey
  (`detail`), the level it needs beside them; a thing that is not worn says its kind from
  `C_Item.GetItemInfoInstant` (*Trade Goods · Cloth*). *DPS* stands before the large number (was: *Damage
  per Second* after it).
- **The sell price once:** the game also writes it as a line, "Sell Price: 81" (`TooltipDataRules.SellPrice`
  → `GameTooltip_OnTooltipAddMoney`, with *Minimum*/*Maximum* lines for a range); that line is left out.
- **Prices in the footer:** *Vendor* (the game's price) and *Auction* (not for a bound thing). The
  durability bar has no price beside it any more.
- **A comparison's changes:** the sentence over them (`ITEM_DELTA_DESCRIPTION`, `..._MULTIPLE_...`) is left
  out; the changes are marked the game's own lines (normal size, not small), and "damage per second" in
  them says *DPS* (`PATTERN.DPS_WORDS`, any case).
- **Trade goods:** *Used in* with the professions that use the kind of trade good (cloth: tailoring,
  leather, metal and stone: blacksmithing and engineering, herbs, meat, enchanting, parts), named and
  pictured by the professions' spells: by the game's kinds only, no table per item.
- **Spell numbers** (`Numbers.lua`, new): a second strip with the spell's damage or healing on average,
  per second, per point of its power (`GetSpellPowerCost`) and its crit (`GetSpellCritChance`). The melee
  swing and the shots: per swing, per second, speed, crit (`UnitDamage`, `UnitRangedDamage`). The first
  strip's cost also says its share of your mana.
- **Creatures:** XP for a kill by the original game's rule (level difference, grey
  level, elite ×2, rested ×2) and kills to your next level; a creature's class when it is not a warrior.
  Nothing is recorded (kills, loot, drop rates, *Dropped by*).
- **The plaque** is a gold rectangle with a soft edge (`Art/plaque.tga`, 32 x 32, made by
  `dev/tools/tooltip-art`, sliced; gold gradient). Was: the game's gold dialog plaque in three pieces.

### Tooltips: a unit's target above its health
Tests: 180 checks (Tooltips). Not tried in the game.
- The *Target* row comes first under the header's divider, above the health and power bars (was: under them).

### Tooltips: dragons closer, none for creatures without a rank
Tests: 180 checks (Tooltips). Not tried in the game.
- A creature without a rank has no dragon again (silver stays for rares and rare elites).
- The dragons are moved 4 to the left (`DRAGON_LEFT`): the portrait's round picture is a little narrower
  than its square, and a screenshot showed a gap between it and the dragon's body.

### Tooltips: the side's emblem in the top left corner
Tests: 180 checks (Tooltips). Not tried in the game.
- A player's side emblem hangs by its top left corner on the panel's top left corner, 2 in (was: centred
  on the right side, 8 in). The game's emblem picture has an empty border, so it is cut to the emblem
  itself (`SetTexCoord`, the edges measured from the art: `EMBLEMS` in `Panel.lua`) and drawn at the same
  scale as before. Alpha and layer are unchanged.

### Tooltips: narrower soft edge, also on bars and buff icons
Tests: 179 checks (Tooltips). Not tried in the game.
- The icons' and portraits' soft edge is narrower (the outer 6 of 64 fade, was 10).
- A unit's bars (and a buff's bar) fade out at their edge too: `Art/bar-mask.tga` is soft now (3 of 16).
- A unit's buff icons have a soft edge: `Art/aura-mask.tga` (new, 32 x 32), one mask for each icon
  (`Live.lua`).

### Tooltips: soft icons, silver dragon for every other creature
Tests: 178 checks (Tooltips). Not tried in the game.
- **Icons and portraits fade out at their edge** like the panel's border: `Art/icon-mask.tga` is now soft
  (round corners, the outer 10 of 64 fading), and portraits have `Art/portrait-mask.tga` (a circle, the
  same fade); one mask on the icon, its picture chosen by the kind. The frame behind a square icon is gone,
  and with it `Art/round.tga`, which nothing uses any more.
- **The silver dragon** goes round every creature's portrait that is not an elite or a boss (rare, rare
  elite, and those without a rank); the dragons' key `rare` is now `silver`.

### Tooltips: the target frame's dragons
Tests: 177 checks (Tooltips). Not tried in the game.
- **The dragon round a portrait is the game's own from its target frame** (`Interface\HUD\UIUnitFrameBoss2x`,
  as `GetBossPortraitFrameData` picks it): gold winged for a boss (`UnitIsBossMob`, or `worldboss`), gold
  for an elite, silver winged for a rare and a rare elite, and gold for every player. Was: the gold dialog
  dragon, turned, for elites only. Each dragon's box on the sheet and the middle and inner radius of the
  circle it curls round were measured from the art (`DRAGONS`, `DRAGON_RING` in `Panel.lua`); it is
  scaled so that the circle lies on the 64 portrait and covers its edge by 2, and placed by the
  portrait's middle. The sheet has no atlas file in the reference, hence the measured numbers.

### Tooltips: the game's gold plaque, item level on it, power over health
Tests: 174 checks (Tooltips). Not tried in the game.
- **The plaque is the game's own,** from the same set as the dragon: the title plate of the gold dialog box
  (`Interface\DialogFrame\UI-DialogBox-Gold-Header`: gold metal frame with rivets round a worn bronze
  field), in three pieces by `SetTexCoord` (ends 22, middle 104 of its 256 pixels, 42 high) so it can be
  as wide as its words. Was: `Art/round.tga` twice with a gradient. Its right side stays where a plaque with
  a level alone has it (46 wide round the icon's middle); longer words reach left. All its words are
  outlined: a unit's level in its difficulty colour, an item level light.
- **A player's item level is on the plaque,** "iLvl 50 - 60" (`TEXT.PLAQUE`; the dash in the item level's
  light colour, the level in its own), not in a row of its own;
  until another player's answer has come, the plaque has the level alone.
- **The power bar lies over the health bar's lower part** (5 high, nothing behind it, so an empty one is
  not a black bar); the health bar is 18 high, its numbers centred in the part above the power bar.

### Tooltips: fixes after a look at a buff
Tests: 173 checks (Tooltips). Not tried in the game.
- **Fixed: a square icon was cut to a thin strip, and the bars' corners stayed square.** A mask with slice
  margins does not keep its corners in the game. The masks are now pictures of their own shape, stretched
  whole: `Art/icon-mask.tga` (64 x 64) and `Art/bar-mask.tga` (256 x 16, so that over the bars' size its
  corners stay about round). `dev/tools/tooltip-art` makes them; `soft.tga` and `round.tga` are unchanged.
- **Other addons' ID lines are left out** ("Spell ID: 1459", "IconID  135932": `Read.IsIdLine`, a whole
  line of words ending in ID with a number): the section that Alt shows has the numbers. They had stood
  among a buff's lines, full size, with the number coloured.
- **A buff's time line** is the game's last own line that has a number in it and is not the description
  or an ID line (was: its last own line that is not the description).
- **A buff's bar is wide enough** for the time and the caster written inside it.

### Tooltips: a player's item level
Tests: 172 checks (Tooltips). Not tried in the game.
- **A player's item level** in a row of its own under *Target* (`Inspect.lua`, new). Yours from
  `GetAverageItemLevel`; another player's by inspecting them (`NotifyInspect`, `INSPECT_READY`,
  `C_PaperDollInfo.GetInspectItemLevel`), paced:
  out of a fight, `CanInspect`, `CheckInteractDistance(unit, 1)`, not with the inspect
  window open, one question at a time and 2 s after anybody's (`NotifyInspect` hooked), 15 s before the
  same player again, 5 s until an answer counts as lost; kept 5 minutes, at most about 200 players.
  `ClearInspectPlayer` after reading, unless the inspect window is open. The panel shows an ellipsis
  while the answer is on its way and is drawn anew when it comes.
- **A unit's level is coloured by its difficulty again** (`badgeR`, `badgeG`, `badgeB` are back), outlined
  so it reads on the plaque; an item's level stays dark brown. The plaque is quieter: a muted gold at
  alpha 0.75, the edge at 0.85, the light line at 0.3.
- **PvP stands at the end of the race and class line,** in red (a colour code inside the line).

### Tooltips: round icons, gold plaque
Tests: 167 checks (Tooltips). Not tried in the game.
- **Square icons have round corners:** a mask (`Art/round.tga`) on the icon, added for an item's or a
  spell's icon and taken off for a portrait; the frame behind the icon is `Art/round.tga` too (was a
  square), 2 larger on each side.
- **The level is on a gold plaque** at the icon's lower edge: `Art/round.tga` twice (a bronze edge, and a
  gold gradient inset by two pixels) with a light line along its top; the number in dark brown, in the
  title's font. The badge colours (`badgeR`, `badgeG`, `badgeB`) are gone from the model: a creature's
  level is no longer coloured by its difficulty.
- **The elite's dragon is 116** (was 140), its top left 71 left of and 34 over the panel's top right
  corner, so its tail covers the icon's lower edge too, under the plaque.

### Tooltips, a third look
Tests: 165 checks (Tooltips). Not tried in the game.
- **With Alt held, every panel shows its technical details** in a small section at the bottom
  (`Read.lua`, `Details`): the number of the thing at the left (*Spell ID* for spells, buffs and pet
  abilities; *Item ID*, *Quest ID*, ... after the name of the tooltip data's kind; *NPC ID* from a
  creature's GUID; a player's GUID), its icon's at the right (*Icon ID*). `MODIFIER_STATE_CHANGED` for
  Alt reads the shown panels anew.
- **A buff's time is inside its bar:** the game's line for how long it still runs (its last line of its
  own that is not the description) is taken from the rows and written into the bar at the left, the
  caster at the right (`BarText`); the bar is a `LiveBar` like a unit's (flat, half see-through, 16
  high, round corners).
- **The icon stands out over the corner** (10 past the right side, 10 over the top); the dragon keeps its
  place, now set from the panel's corner, and covers the icon's edge.

Tests: 157 checks (Tooltips). Not tried in the game.
- **Fixed: the game's tooltip sometimes showed under a panel.** The game sets a tooltip's alpha itself when
  it shows it and while it fades it out (a creature's, after the mouse left it), so alpha 0 on the tooltip
  did not hold. Now each part that can be seen is made invisible too (`Native.lua`, `FadeParts`: the
  border, the lines, `<name>Texture1..30`, `<name>StatusBar`, the money frames, `CompareHeader`); their
  alphas are noted and given back by `Release`.
- **The icon** is 64 (was 40) and stands in the top right corner (12 in, 4 down); the level or item level
  sits on its lower edge, outlined. The elite's dragon is 140 and placed by the icon, the middle of its
  open side on the icon's middle, drawn over the icon.
- **A unit's bars** are one block with round corners: a mask (`Art/round.tga`, new, made by
  `dev/tools/tooltip-art`) on both bars' fills and tracks.
- **Dividers** two pixels dark (alpha 0.55) and one light (0.10); were one each (0.45, 0.07).
- **Opacity** 97 at first (was 90). The module's saved settings have a version now (`version = 2`): a saved
  90 is taken for the old default and becomes 97; the gone setting `border` is removed.

Tests: 153 checks (Tooltips). Not tried in the game.
- **Fixed: the comparison of what you wear jumped between two places** with the mouse still. The game
  places comparison tooltips by the tooltips' sizes (side and slide in `AnchorShoppingTooltips`), and the
  module made each tooltip as large as its panel with padding, which the game took away and the module put
  back: two sizes, two places. The game's tooltips are no longer changed but for their alpha
  (`Native.lua`: `Fit` and the padding are gone). A panel whose tooltip the game placed beside another
  tooltip with a panel is placed beside that panel instead (`Beside`), by its own size.
- **Hints get panels too:** lines written into a tooltip without data (a button's name and explanation).
  `GameTooltip`, `ItemRefTooltip`, `ShoppingTooltip1/2` are hooked at login; a tooltip shown after it was
  cleared with no data told is drawn at the end of the frame as `Read.Generic`, its name as written.
  Only tooltips with a bar or a frame inside, or with a hidden line, stay the game's.
- **Units:** health and power bars are a flat colour at half alpha (`LiveBar`: one bar each, kept apart
  like the live texts), the health bar 16 high with "current   percent" written on it in a small font, the
  power bar 8 high right under it; the health text row is gone. Guild, race and class, kind and PvP use a
  new small font (`detail`, text size - 4); PvP is always "PvP" (the game's word is "Player vs. Player").
  No frame behind a portrait.
- **The elite's dragon** is 128 large, turned to look left (`SetTexCoord(1, 0, 0, 1)`) and lies round the
  top right corner, under the portrait and the texts.

### Core: the error log
Tests: 64 checks (Core and Settings).
- **Every problem is kept in a log** (`Core.log`, saved as `SaneUIDB.log`): time, label, the text with the
  place it happened, the addon's version, the game's build; newest last, the newest 100, the same problem
  twice in a row counted in one entry. `Core.NoteError` writes it. The log file is the saved settings
  file (an addon cannot write another): the game writes it at a `/reload` or a logout.
- **Errors nothing of ours caught are noted too:** at login Core hooks the game's error window
  (`hooksecurefunc(ScriptErrorsFrame, "DisplayMessageInternal", ...)`) and notes the errors that name a
  Sane UI addon, with their stack. The game's own error handling is not touched.
- **`dev/tools/errors`** prints the log from the game's saved settings file (`10`, a number, `all`, `short`).
- `/sane errors` says how many entries the log has; `/sane errors clear` empties it too.

### Tooltips, later the same day
Tests: 57 checks (Tooltips). Not tried in the game.
- **Tooltips are drawn anew on panels**, in a layout of their own: header (name in capitals, a line under
  it, icon at the right), divider, a spell's strip (cost, cast, cooldown, range), the other lines in rows
  with rules, another addon's lines small at the bottom, a health bar for units. Was: art behind the
  game's own lines. The game's tooltip stays under the panel, invisible (alpha 0) and padded to the
  panel's size.
- New files: `Texts.lua` (own words; the English patterns for the strip), `Read.lua` (lines into a model
  that is filled in place and says whether it changed), `Panel.lua` (frame, pools, layout), `Native.lua`
  (alpha, padding, corner; given back). `Skin.lua` is gone. `Look.lua` also returns the unit.
- **New switch *Anchor tooltips to the mouse cursor***, off at first: a hook on
  `GameTooltip_SetDefaultAnchor` sets `ANCHOR_CURSOR_RIGHT`. The switch *Colour the border* is gone.
- A tooltip is left to the game when it is plain lines, holds a bar, an item or another frame, or has a
  line the game hides.
- **Fixed: a tooltip flickered between its panel and the game's own**, mostly with a comparison open
  (seen in the auction house). Two causes. The game shows its comparison tooltips with `SetShown`, which
  makes a tooltip visible at full strength like `Show` but was not hooked. And data the game adds to a
  filled tooltip came as a fill of its own: read by that data alone, the price was not found, the coins
  counted as something a panel cannot show, and the tooltip was given back until the next fill. A tooltip
  is now always read by the data it was first filled from (`GetPrimaryTooltipData`). A tooltip that is
  cleared and shown before it is filled stays invisible until the next frame decides. Tests: 60 checks.
- **Fixed: the comparison panels changed their size several times a second.** The game tells us a
  comparison tooltip is filled and then goes on writing into it (what would change), on every refresh.
  The panel was drawn short at once and long a frame later. A filled tooltip is now drawn at the end of
  the frame (`Filled` queues it, a frame of the module's that only runs while one waits draws it:
  `Settle`); hidden and filled again in one go, the old picture stays until then. The same lines again
  draw nothing. Also: a comparison's panel hangs on the side that faces the tooltip it belongs to
  (`Native.lua`, `Corner`: a tooltip held by several points), and padding is given back on a hidden
  tooltip too. Tests: 66 checks.
- **Look, after the first try in the game** (`Panel.lua`): the divider with the diamond is gone; the
  strip's captions stand over their values, and every value is equally bright (one the tooltip left out
  was grey); the panel is built from `TooltipBackdropTemplate`, so it has the round corners of the game's
  tooltips, its border tinted with the tooltip's colour (the four flat edges are gone); padding 10
  (was 19), icon 30 (was 38), the header no taller than its lines or the icon, rules and rows closer.
- **New setting *Text size*** (10 to 20, 14 at first; a slider, which the Settings module shows for an
  option with `min` and `max`). Name and lines are that size, the strip's values and the subtitle 2
  smaller, another addon's lines 3, captions 5. The font file is asked of the game's font objects
  (`GameTooltipText`, `GameTooltipHeaderText`) at every draw and only the size is set (`SetFont`): the
  one place where a size of our own is used, because the size is the player's choice.
- **The comparison's tooltip of what you wear** says so at its top, inside the panel, in gold capitals
  (the text of the game's own tab, `CompareHeader.Label`), and its panel is drawn at alpha 0.85.
- **The test realm's line "Press F6 to submit an issue for this ..."** is left out (`Read.lua`,
  `IsFeedback`: known by the start of `PTR_IssueReporter.BugTooltipString`). Tests: 73 checks.
- **A layout for each kind of tooltip**. Tests: 108 checks. Not tried in
  the game.
  - New structure: `Model.lua` (head and rows as data, in two copies that are compared after a fill;
    replaces the fixed fields of the old model), `Read.lua` (the lines and the tools to sort them), one
    file per kind in `Kinds/` (`Item`, `Spell`, `Unit`, `Aura`, `Quest`), `Live.lua` (what changes while a
    panel is shown). `Look.lua` is gone, its parts are in the kinds.
  - **Items:** kind and slot; binding (red while `bonding` is bind on pickup, equip or use) with the
    needed level beside it; item level under the icon; damage per second or armour large; durability as
    a small bar with the price beside it. Recipes: caption *Creates* and the product's icon at the
    `NestedBlock` line. The lines are known by `DPS_TEMPLATE`, `ARMOR_TEMPLATE`, `ITEM_MIN_LEVEL`,
    `DURABILITY_TEMPLATE`, `ITEM_LEVEL` where the client has them, else by the English wording.
  - **Spells:** school from the description (English words, kept per spell), as the panel's colour and a
    word under the name; green for a heal, red for plain damage; the description's numbers coloured.
  - **Units:** name (class colour), guild, race and class or creature type, PvP, portrait
    (`SetPortraitTexture`) and level; health text, health bar, power bar; target; buffs and debuffs
    (outside a fight only); the side's emblem; a dragon for elites; a sword or a bag beside quest
    objectives. The tooltip's own lines for guild, class, level, side and PvP are left out.
  - **Buffs:** kind and dispel type, caster, a bar on the game's timer (`SetTimerDuration`). The buff is
    found from the tooltip's `getterName` and `getterArgs`.
  - **Quests:** level, state (`C_QuestLog`), objectives under a caption with boxes and counts.
  - **Look:** one gradient in the panel's colour, no band behind the name; dividers are a dark hairline
    with a faint light one under it; padding 14 (was 10), icon 40 (was 30).
  - **New setting *Opacity*** (30 to 100, 90 at first): the background's alpha.
  - A player's specialisation is not shown: there is no way to it without inspecting.
- **Fixed: after the update above and only a `/reload`, no panel was shown at all.** The game learns an
  addon's files when it starts; a `/reload` reads those anew but not files added since, so `Model.lua`,
  `Live.lua` and `Kinds/` were missing, the first tooltip failed and the module stood down. At login the
  module now checks that every file has left its part (`PARTS` in `Tooltips.lua`); if one is missing it
  asks in chat for a restart of the game and leaves the tooltips to the game, without an error.
  `ns.StandDown` no longer needs `Panel.lua` and `Native.lua` to be there. Tests: 109 checks.
- **Fixed: an error at the first tooltip after a unit's** (`Panel.lua: attempt to perform arithmetic on a
  secret number value`, found in the saved error list). The texts for a unit's health and its target came
  from the pool of texts; once given a hidden number, such a text answers with hidden numbers when asked
  for its width, and the next draw used it for an ordinary line and measured it. These texts are now kept
  apart (`LiveText`), one for each use and never measured. A hidden name of a target is handed to the
  text as it is. `Guarded` keeps the stack of an error for the log (`xpcall` with `debugstack`).
- **No border.** The panel is a plain frame; its background is drawn with a picture of our own,
  `Art/soft.tga` (a white square with round corners and a soft edge, made by `dev/tools/tooltip-art`),
  stretched with slice margins, coloured by the gradient and reaching 8 past the panel's sides, so the
  edge fades out softly. `TooltipBackdropTemplate` is no longer used. Tests: 163 checks.

### Spellbook, later the same day
Tests: 247 checks (Spellbook) and 243 more with the Settings module switched off.
- **The Home tab was under the spellbook's round icon.** It now stands where the row of the game's tabs
  began, and that row is moved 46 to the right while the pages are the module's (`Home.lua`, `PlaceTabs`;
  place only, put back on a fallback; in a fight, if the row is locked, Home takes the gap as before).
- **Home: quest rewards by level.** Small headings *Level 10*, fainter for a level not reached yet. A row
  says the place of the quest; the level is no longer in the row.
- **Home lists no weapon skills** under *At your trainer now*: the class trainer does not teach them.
- **General tab: two sections.** *Passive spells to learn* holds every passive spell to come (they are
  no longer in the class tabs or under *Other spells to learn*); *Skills to learn* holds weapon skills.
  New: `Data/WeaponSkills.lua`, `Sources.UnlearnedPassives`, `Sources.UnlearnedSkills`, entries with
  `skill = true`, the stats field `skill`. `Sources.Unlearned(tab, showRanks)` lost its third value.
- **Ranks fold into one entry** when *Show all spell ranks* is on (`Book.lua`, `Fold`): the highest rank
  you have or the lowest to learn stays, with a "+" button; the others' entries are parked. Unfolded, the
  ranks are a section under the tab's spells with a "-" heading. Kept until `/reload`. A folded entry
  carries the reserved clock for all its ranks (`BookItem.Set`, sixth value `family`).
- **`Layout.Paginate`:** a header may say its `height` and a group its `gap`, for small subsections.
- **A checkbox *Show hidden spells*** left of the page buttons (`SaneUISpellbookShowHidden`), the same
  switch as in the menu and the options; hidden while Home is on show.

### Removed
- **The built-in training list** and all that only it used: the folder `src/Spellbook/Training` with its
  tab, window, menus, art, key binding (`Bindings.xml`) and saved variables, `/sane sb train`, its line in
  the spellbook's menu, and the tool that built the folder. `dev/tests/lint` allows no globals but Sane UI's
  own.
- **`BINDING_HEADER_SANEUI`** in Core: no module has a key binding any more.

### Changed
- **`CLAUDE.md`, Workflow:** new rule *Parallel sessions*. Several Claude sessions may work in the folder
  at once on different modules; each keeps the others' changes, merges into the current file content and
  commits only its own files by path.
- **The trainer data** moved to `src/Spellbook/Data/Classes/`, the quest rewards to `Data/QuestSpells.lua`,
  read through `ns.Data` (`Data/Trainer.lua`, new).
- **`Sources.lua`** reads `ns.Data`. A spell whose texts the game has not fetched yet is asked for and listed
  when the answer arrives (was: the training code's own cache did that). The stats field `data` is the same.
- **A grey entry's tooltip** shows the trainer's base price as one line.
- **Module titles** in the addon list are the plain names: *Settings*, *Spellbook*, *Tooltips* (were
  *Sane UI Settings*, ...). The minimap's addon list shows *Settings*.
- **Settings is load-on-demand** (`## LoadOnDemand: 1`). Core loads it when the game's options window opens
  (hook on `SettingsPanel` `OnShow`) or on `/sane options`, which is now Core's command and says so when
  the module is switched off. `Core.LoadSettings()`.
- **Core starts a module that arrives after the login:** `OnLoad`, then `OnLogin` at once.
- **A module's options page is called "Sane" and its name** (*Sane Spellbook*, *Sane Tooltips*): that is
  the entry under *Sane UI* and the title at the top of the page.
- **The reserved mark** in the spellbook is a small clock (atlas `auctionhouse-icon-clock`), was a tick.
  With *Show all spell ranks* on, only the rank that was dragged onto the button carries it and says
  *Reserved on ...*; with one icon per spell, that icon does.
- **`Book.lua`:** `Book.SetHome(on)` parks every entry and hides the page buttons while Home is on show;
  `Book.Armed()`; the messages `BOOK_PAGES` (pages taken or given back) and `BOOK_JUMP` (the game jumps
  to a spell). `BookItem.Set` takes a fifth value, the text of the third line.
- **Version 0.3.0** in all four TOCs (Tooltips was added at 0.2.0).
- **Tests:** the stand-in client loads an addon on demand, knows a spell's rank line and whether its texts
  are there, the faction and the race. `spellbook.lua` feeds `ns.Data` and has a row of tabs.

### Added
- **Module Chat** (`src/Chat`, addon `SaneUI_Chat`), a first prototype: a chat window in the style of a
  messenger. Every message is a bubble, yours at the right, everybody else's at the left with class icon,
  name, the chat's name and the time; the system's lines and emotes are centred notes. The window is
  moved by its top bar and sized by a grip in the lower right corner (smallest 180 × 130); place and size
  are kept in Core's settings. A bubble takes a share of the window's width, so the messages wrap anew
  when the width changes. `/sane chat`, `/sane chat reset`. Files: `Chat.lua` (events, command, fall-back), `Log.lua` (what an event says, the
  last 200 messages), `Layout.lua` (sizes and the arithmetic from the width), `Bubble.lua` (one message,
  measured and drawn), `Window.lua`. Built from `TooltipBackdropTemplate`, `WowScrollBoxList` with an
  extent calculator, `MinimalScrollBar`, `PanelResizeButtonTemplate`; no art shipped.
- **Chat: the line to write in** (`Input.lua`). It is the game's own edit box, anchored to the bottom of
  our window whenever the game shows it (`ChatFrame.OnEditBoxShow` / `OnEditBoxHide` of `EventRegistry`),
  so Enter, `/`, slash commands, `/w`, `/r`, history and name completion stay the game's. The list of
  messages ends above it while it is shown (`Layout.INPUT`) and keeps the newest message in view. Its own
  anchors are put back when our window goes.
- **Chat: the list of chats to write in.** A click on the line's label (*Say:*, *Guild:*) opens a menu of
  the chats you can write in now (`Channels.lua`: say, yell, party, raid, instance, guild, officer, the
  channels you joined). The choice is set with the edit box's own `SetChatType`, `SetStickyType`,
  `SetChannelTarget` and stays until another is chosen or typed.
- **Chat: the game's own chat is out of sight while our window is open** (`Native.lua`): its windows,
  the tabs of undocked ones, the dock and its buttons get a hidden parent, and their own back when our
  window is hidden (`/sane chat` now switches between the two) or the module fails. The game's chat goes
  on collecting, so it is complete when it comes back.
- **Chat: printed lines.** What `print` and the game write into the main chat window without a chat event
  (`/sane`, error notes, help texts) is shown as a note (`Log.Note`; a hook on its `AddMessage`, lines
  without a chat type number).
- **Chat: the line to write in is only there while you write.** An empty line without the cursor is
  hidden (the game's IM style would keep it on show, faded and without the chat's name). A button with
  the game's chat icon at the right end of the window's bar opens and closes it (`Input.Toggle`). The
  tooltip on the chat's name is gone.
- **Chat: the newest message is at the bottom.** A few messages stand at the bottom of the window: the
  list's view gets the free room as top padding (`Window` `Settle`, `Layout.ListHeight`).
- **Chat: messages fade out, each by itself** (`Bubble.Fade`, an animation group per row), not while the
  mouse is over the window or the line to write in is open. Two settings on the module's options page:
  *Fade messages out* (on) and *Seconds before a message fades* (60; 5 to 300).
- **Core and Settings: a number as a setting.** An option described with `min`, `max` and `step` is shown
  as a slider (`Settings.CreateSliderOptions`, `CreateSliderInitializer`); the stand-in client knows both.
- **Chat: the window has no background and no border.** Its title, grip, scroll bar and chat button are
  only shown while the mouse is over it (and while a mouse button is held). The chat button moved to the
  lower left corner, as high as the line to write in, which now starts right of it.
- **Chat: drawn above the action bars** (strata `MEDIUM`, frame level 100), all parts as one; the game's
  edit box gets the window's strata instead of `DIALOG` once it is shown.
- **Chat: a message the list's top edge cuts is hidden** (`Window` `Trim`, `Bubble.Cut`; a row's content
  is now one frame inside the row).
- **Chat: round class icons with a ring** for what the speaker is to you: yellow friend, green guild,
  purple raid, blue party (`Log.lua` `Tie`, `Layout.TIES`). The name above a bubble is as large as the
  message; the chat's name and the time stay small, beside it.
- **Chat: a setting *Text size*** (10 to 24, at first 14). A font object of the module (`SaneUIChatFont`)
  copies the game's chat font and sets the size (`Bubble.Size`).
- **Chat: bubbles without a border.** A bubble is a plain fill with round corners (`Plate.lua`, new: two
  bars and four masked dots of plain colour; `Layout.RADIUS`), no longer `TooltipBackdropTemplate`.
- **Chat: bubbles half see-through, and a setting *Bubble transparency (%)*** (0 to 100, at first 50;
  `Bubble.Clear`, `Window.Repaint`). For that the plate's pieces no longer lie over each other: quarter
  dots in the corners, a bar above and below, the middle. The ring around an icon is 1 pixel (was 2).
- **Chat: the line to write in is drawn as your own bubbles** (`Bubble.Yours`, `Input.Paint`): the same
  plate, colour and transparency; it follows the transparency setting. `Layout.WRITE` is gone.
- **Chat: a setting *Short chat names*** (on): above a message the chat is named by the first letter of
  each word of its name (`Channels.Brief`; `entry.short`).
- **Chat: what the window shows can be chosen.** The list on the chat button and on the chat's name has
  a tick for every kind of chat and every channel you are in (`Channels.Shown`); a message carries its
  group (`entry.group`), the switched-off ones are kept in the module's store (`mute`), and the window
  shows the log without them (`Window.Refill`). The stand-in's menu checkboxes carry their data.
- **Chat: links in messages answer the mouse** (`Links.lua`, new): over an item's, spell's, quest's link its
  tooltip (`GameTooltip:SetHyperlink`); a click is the game's own (`SetItemRef`).
- **Chat, fixed: the bubbles' corners** were small whole circles (seen in the game): a mask's texture
  coordinates do not pick a quarter of it. A corner is now a square under the whole mask, twice its size.
- **Chat, fixed: unticking a channel in the list** did not hide its messages (reported from the game). A
  channel's messages were matched to the list by name; now by the channel's number (`"CHANNEL:2"`).
- **Chat: a setting *Show native chat*** (on): the game's own chat stays on show next to the window; switched
  off it is out of sight as before (`Window.Native`). The line to write in is ours either way.
- **Chat: a white ring** around the class icon of somebody who is nothing to you (`Layout.TIES.none`).
- **Chat: the line to write in has the same look and grows with its text.** The game's border art
  around the edit box is invisible, a plate lies behind it; the edit box wraps its text
  (`SetMultiLine`) and is as tall as the text needs, up to 6 lines (`Input.lua` `Dress`, `Grow`,
  `Layout.InputHeight`); the window's room for it follows (`Room(height)`). Undone when the window goes.
- **Chat: the chat button opens the line and the list of chats** (the one you write in marked); a click
  on the chat's name shows the same list.
- **Chat:** the window follows the newest message by a flag set from the list's `OnScroll`, also when it is
  sized smaller or the line to write in opens.
- **Tests:** `dev/tests/chat.lua` (68 checks), run by `dev/tests/run`. The stand-in client hands out its
  widget methods (`W.methods`) so a test can add what its module needs of a widget, and its menus know
  radio lines.
- **Spellbook: the Home tab and page** (`Book/Home.lua`). A button of the module that looks like an icon
  tab (the game's tab art, the hearthstone icon), left of the spellbook's first tab; the game's tabs are
  not touched. Its page lists what the trainer teaches now with prices and their total, and the quest
  reward spells with the place of the quest or the level needed. The spellbook opens on it; a click on
  another tab, a search or a jump to a spell closes it. Laid out with `Layout.Paginate`; what does not
  fit is counted in a line.
- **Spellbook: the switch *Open the spellbook on its Home page*** (on).
- **Spellbook: a yellow "!"** (atlas `QuestNormal`) on the icon of an unlearned spell that is a quest reward
  (the trainer does not sell it). Other unlearned spells carry none.
- **Spellbook: the reserved button on the action bar** carries the same clock as the spell in the
  spellbook, and shows the spell's tooltip (a hook after the button's own `OnEnter`).
- **Module Tooltips** (`src/Tooltips`, the addon `SaneUI_Tooltips`): a new look
  for the game's own tooltips. The tooltip is not replaced: its lines, size and place
  stay the game's, and the module puts art behind them. A dark background and a band behind the first
  line (two textures of the tooltip, anchored to the border's centre and to `TextLeft1`), the game's
  border tinted (`NineSlice:SetBorderColor`), and the icon of items and spells in a frame from
  `TooltipBackdropTemplate` on top of the left corner.
  - `Look.lua`: colour and icon from the tooltip's data. Item and toy: quality and icon; spell and aura:
    icon; player: class colour. Everything else takes the colour of its first line.
  - `Skin.lua`: the art. No art file is shipped.
  - `Tooltips.lua`: dresses a tooltip after `TooltipDataProcessor`'s post call for all types, and on
    `OnShow`/`Show` for lines written in by hand. Three switches: border, class colours, icons.
  - An error takes the art from all tooltips and leaves the game's own for the session (`ns.StandDown`).
  - Not tried in the game yet. Not in it: own panels and layout, a style
    editor, stat colours and markers, badges, spell school colours, drop tables, follow-cursor.
- `dev/tests/tooltips.lua` (43 checks), run by `dev/tests/run`. `wowstub.lua` lets an addon probe for
  `TooltipDataProcessor`, `TooltipBackdropTemplateMixin`, `UnitTokenFromGUID` and the tooltips by name.

## 0.2.0 (2026-10-14)
The split into three addons is not yet tried in the game. Tests: lint, 56 checks (Core and Settings),
204 checks (Spellbook) and 201 more with the Settings module switched off.

### Changed
- **One addon per module.** Sane UI was one addon folder with one TOC. Now Core is the addon `SaneUI`
  (*Sane UI* in the addon list) and every other module an addon of its own under it: `SaneUI_Settings`
  (*Sane UI Settings*) and `SaneUI_Spellbook` (*Sane UI Spellbook*). Each can be switched on and off by
  itself. Their TOCs say `## Dependencies: SaneUI` and `## Group: SaneUI`.
- **A module depends on Core only.** Spellbook no longer needs Settings: it runs the same with the Settings
  module switched off, without its options page.
- **Shared table:** the addons find each other in one global table, `SaneUI` (was the table the game hands
  the files of one addon). A module's own table is the one the game hands its addon:
  `local ADDON, ns = ...`, then `Core.NewModule(ADDON, "Spellbook", ns)` (was `Core.NewModule(name)`).
- **Start of a module:** `OnLoad` runs when the module's own addon is loaded (was: when Sane UI was).
- **Saved settings moved from Settings to Core** (`Core/Saved.lua`): `Core.Store`, `Core.Character`,
  `Core.Options` (were `Config.Store`, `Config.Character`, `Config.Options`). `SaneUIDB` keeps its shape
  and stays in `SavedVariables/SaneUI.lua`, so reservations, layouts and switches carry over.
- **Settings is the options module only.** It reads the described switches from Core at login
  (`Core.described`, `Core.optionOrder`), so the order in which the game reads the modules does not matter.
- **The options:** *Sane UI* is a general page and has one page per module that is switched on under it
  (`Settings.RegisterVerticalLayoutSubcategory`). Was: one page with a heading per module. A module that
  is switched off, or has no switches, has no page.
- **Rows of the options pages** go in through `Settings.RegisterInitializer` (the game's own code adds
  them) instead of `Settings.CreateCheckbox` and `layout:AddInitializer` (addon code added them).
- **The minimap's addon list** shows *Sane UI Settings* (was *Sane UI*): the entry belongs to the Settings
  module and is gone when that is switched off, as is `/sane options`.
- **The training list's own settings** (`SaneUITraining_...`) are declared by `SaneUI_Spellbook` and saved
  to `SavedVariables/SaneUI_Spellbook.lua` (was `SaneUI.lua`).
- **Art paths:** `Interface\AddOns\SaneUI_Spellbook\Training\...`.
- **Files:** `src/SaneUI.toc` is `src/Core/SaneUI.toc`; `src/Bindings.xml` is `src/Spellbook/Bindings.xml`
  (the key binding goes with the module). New: `src/Core/Saved.lua`, `src/Settings/SaneUI_Settings.toc`,
  `src/Spellbook/SaneUI_Spellbook.toc`. In the game the files of an addon no longer sit in a folder named
  after the module (`SaneUI/Core.lua`, `SaneUI_Spellbook/Spellbook.lua`).
- **Icons:** a gear for *Sane UI*, the engineering icon for *Sane UI Settings*, the book stays with
  *Sane UI Spellbook*.
- **`dev/build`** builds one folder per addon into `BUILD` (`BUILD/SaneUI`, `BUILD/SaneUI_Settings`,
  `BUILD/SaneUI_Spellbook`), each named after the TOC in its `src` folder and each with `LICENSE.txt`, and
  copies them all into the game. An addon folder in `BUILD` that no module makes any more is removed; one
  in the game is only named.
- **`dev/tests/lint`** checks every module's folder: one TOC, its files both ways, the dependency on
  `SaneUI`, the group, and that all TOCs share game version and addon version.
- **Tests:** the stand-in client loads a file as one of several addons and knows pages under a page.
  `core.lua` starts Core, then modules as addons of their own, then Settings. `spellbook.lua` reads Settings
  after Spellbook, and runs a second time without it (`--no-settings`).
- **The tool that builds the training list** writes the new first lines (`local _, ns = ...`) and the new
  art path.

### Added
- **A general switch,** *Say in chat when something goes wrong* (on): the first on the general options
  page. Switched off, problems are still kept for `/sane errors`.
- **`/sane`** says which modules are switched on, or that none is.

### Project
- **`CLAUDE.md`:** *Architecture*, the rows `src/` and `BUILD/` and the *Build* line describe one addon per
  module (was: one addon with one TOC, Settings as a base module next to Core).
- **Guides:** `addon-standards.md` (grouped addons, the shared table, where a module's settings are kept,
  a checklist line) and `gui-development.md` (pages under a page, rows through `RegisterInitializer`).
- READMEs of the project and of the three modules.

## 0.1.0 (2026-10-14)
Not yet tried in the game. Tests: lint, 45 checks (Core and Settings), 203 checks (Spellbook).

### Added
- **The addon Sane UI** (`src`, interface 16001, addon list category *Sane UI*): one addon folder,
  one TOC, one folder per module, each with a README.
- **Core** (`Core/Core.lua`): `NewModule` with `OnLoad`/`OnLogin` in TOC order, `Print`, `On` (game events),
  `Safe` and `NoteError` (errors caught, told once, kept), `Plain`/`Secret`, `Command` (`/sane <word>`),
  the character (`class`, `charName`, `charKey` = GUID).
- **Settings** (`Settings/Settings.lua`): one saved table `SaneUIDB` (`modules.<Module>`, its `options` and
  `chars`, `errors`); `Options`, `Store`, `Character`; a page in the game's own options built with
  Blizzard's vertical settings list; `/sane options`; the minimap's addon list opens it.
- **`/sane errors`** lists the kept errors, `/sane errors clear` forgets them. Errors carry a date.
- **Spellbook module** (`Spellbook/`): the former addon *Actionbar Organizer* 0.3.0, on Core and Settings.
- Spellbook's four switches are also on the options page; the spellbook's menu and the page share their
  texts (`ns.OPTION`). New on the page: *Let Sane UI lay out the spellbook's pages*.
- Spellbook warns when *Actionbar Organizer* is loaded next to it.
- **`dev/build`**: tests, builds `BUILD/SaneUI` (no READMEs, plus `LICENSE.txt`), copies it into the game.
  `--no-install`, `--check`. Replaces Actionbar Organizer's `install`.
- **`dev/tests/lint`**: every file in the TOC exists and every file is in the TOC; all Lua parses; no file
  writes a global that is not Sane UI's own.
- **`dev/tests/core.lua`**, **`dev/tests/run`** (everything). The stand-in client learned the game's options,
  `xpcall` with arguments, `CallErrorHandler`, `date`.
- `Doc/changelog.txt`, `Doc/Changed.md`, READMEs for the project and for Core and Settings.

- **`LICENSE`**: the code stays MIT. New in front of it: the name *Sane UI* and its logo are trademarks and
  the original art is all rights reserved, neither is under MIT; Blizzard's code and art stay Blizzard's;
  a request (not a condition) not to publish the whole addon again as a new one.

### Changed (against Actionbar Organizer 0.3.0)
- **Commands:** `/abo ...` is `/sane spellbook ...`, short `/sane sb ...`. `/abo book on|off` is
  `/sane sb pages on|off`.
- **Saved settings:** `ActionbarOrganizerDB` is `SaneUIDB.modules.Spellbook`; the training list's `ABO_...`
  are `SaneUITraining_...`. Nothing is carried over: the old addon was never installed under that name.
- **Names in the game:** frames `ActionbarOrganizerBook(Pager)` are `SaneUISpellbook(Pager)`, `ABOTraining...`
  are `SaneUITraining...`; popups `SANEUI_SPELLBOOK_SAVE/LOAD`; key binding `SANEUI_SPELLBOOK_TRAINING` under
  the header *Sane UI*.
- **Art paths:** `Interface\AddOns\SaneUI\Spellbook\Training\...`.
- **The minimap's addon list** opens the options (was: the training list, still on its key binding and
  `/sane sb train`).
- **Game events:** an error in one listener no longer keeps the others from hearing the event; it goes to the
  game's error handler.
- **Error lines** point to `/sane errors` instead of "tell Claude"; labels carry the module (`Spellbook: scan`).
- **The training list's tool** builds into `src/Spellbook/Training` with the new names.
- Tests moved to `dev/tests` (`run.lua` is `spellbook.lua`), tools to `dev/tools`.

### Removed
- Reading settings saved by Actionbar Organizer 0.1.0 and 0.2.0 (character under its name, trainer rows,
  the planner window's position).
- The folder `ActionbarOrganizer`.

### Project
- **`Doc/guides/`**, three guides written from Blizzard's posts and talks, the add-on policy and the
  Warcraft Wiki, with every template and function name checked against `references/`:
  `blizzard-design-principles.md` (13 principles, each with what it means for Sane UI, and a checklist),
  `addon-standards.md` (policy, TOC, loading, globals, taint, secret values, performance, saved variables,
  languages, resilience), `gui-development.md` (which Blizzard part to build what from; windows, layout,
  art, text, lists, menus, tooltips, changing Blizzard windows). Each lists its sources and says which
  were only read as a summary.
- **`CLAUDE.md`:** three new principles (*Simple*, *Maintainable*, *Design*) and a section *Guides* that
  says which guide to read before which kind of work. The folder paths stay as they are (`src/`, not the
  earlier `src/SaneUI/`).
- **`src/` holds the addon itself** (`src/SaneUI.toc`, `src/Core/`, ...), one folder level less than at first
  (`src/SaneUI/`). `dev/build`, the tests and the tools follow. The build is still `BUILD/SaneUI`.
- **Git history started anew:** one commit with the project's files (ignore and attribute files, licence,
  README, CLAUDE.md), one with the addon and everything else.
- `.gitignore`: `references/`, the history file of `Scripts/addon-categories`, editor
  leftovers. `BUILD/` is committed, so the repository carries the ready addon folder. `.gitattributes`: LF for
  text, art marked binary, `libs/` kept byte for byte.
- `CLAUDE.MD` renamed to `CLAUDE.md` (Claude Code only reads that spelling on Linux); added: one addon with
  one TOC, `dev/build`, the real name of `BUILD/`.
