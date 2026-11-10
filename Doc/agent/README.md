# Sane UI: the project map

The compact map for a new chat: what is where, what to read for a task, where Blizzard's code is. The source wins
over every note here; `CLAUDE.md` holds the rules. Read as little as needed: this page, the row for the task, then
the code and the tests near it. Long documents by section: `saneui showsections FILE` (lines and tokens per
section), `saneui showsections FILE words` (the sections named).

## The addons

Fifteen addons in `src/`, one folder each with its TOC and its README (a *TL;DR* first, then *How to use*, the technical
sections, *Files*; most keep a *History*). Version 0.3.0, `## Interface: 16001, 120105` (Forever and Retail).
Core is the library every module depends on and the only one needed; every module is independent of the others.

| Module (addon) | What it is | Plan, note, tests |
| --- | --- | --- |
| Core (`SaneUI`, `src/Core/`) | The library: events, errors and guards, the saved settings of every module in profiles, the `/sane` command, what every window can do (moving, docking, full screens, tabs, Esc), the options (`Settings/`), Sync (`Sync/`, the game's own settings kept with ours), the data framework (`Data/`), the guild's records and the wire to the guild and the group | `src/Core/README.md` (its *Files* section describes every file); [core.md](core.md) (contracts and traps); `Settings/README.md`, `Sync/README.md`, [sync.md](sync.md); `Doc/guides/windows.md`, `Doc/guides/data.md`; tests `core.lua`, `window.lua`, `sync.lua`, `data.lua`, `guild.lua` |
| Abilities (`SaneUI_Abilities`) | The spellbook with the spells not learned yet, reserved action buttons that fill when a spell is learned, the Home page of what the trainer teaches, Action Bar 1 kept on its page, bars that touch, buttons that follow a new rank | [abilities.md](abilities.md); tests `abilities.lua` |
| AuctionData, AuctionScans (`SaneUI_AuctionData`, `SaneUI_AuctionScans`) | No code: the saved files of the auction prices and of every full scan whole (`SaneUIData_Market`, `SaneUIData_Scans`); Core fills and reads them | `Doc/guides/data.md`, *The full auction scan* |
| Combat (`SaneUI_Combat`) | Its window at the bottom middle and its full screen with our own spellbook and talents (the game's own window there in Retail), Sane Macros (macros and sequences in the game's macro window's stead, `Macros/`) and the action bars as windows; the frames of you, your target, focus, pet and their targets in the nameplates' look, party and raid frames, the game's bars out of the way and its menu bar on mouseover, frames and bars out of sight at rest; rings around the mouse for the global cooldown and your cast; the threat and damage meter on the game's own `C_DamageMeter` (`Meter/`); reminders of buffs and debuffs on invisible bars, on the party and raid frames and under the nameplates (`Reminders/`); marks on the game's buff list (`Units/BuffList.lua`) and the aura lists' window, with a search over every class's, the enemies' and the items' auras (`Units/Lists.lua`, `Units/AuraSearch.lua`); boss frames, party pets and your buffs to come | `Doc/ideas/Combat.md`; tests `combat.lua` (with its client fixture `combatclient.lua`), `book.lua`, `talents.lua`, `meter.lua`, `reminders.lua`, `auralists.lua` |
| Economy (`SaneUI_Economy`) | The tab *Deals* on the game's auction house window: what to buy and sell right now, a click each, the gold on sale; Core's prices, forecast and fees. The tick *Send to banker* on the mail window's Send Mail tab: ticked, the mailbox opens there with the mail to the banker filled in (its name, today's date, the trade goods, reagents, waylaid crates and writs not soulbound), for one press of Send, by itself with Speed Leveling on | `Doc/ideas/Economy.md`; tests `economy.lua` |
| Guild (`SaneUI_Guild`) | The guild window on Social's full screen or alone: overview, roster, everybody's gear; the other views to come; its data and sharing are Core's | `Doc/ideas/Guild.md`; tests `guild.lua` |
| Inventory (`SaneUI_Inventory`) | The bottom right corner: the character sheet, the bags (categories, bank, vendor, make room), the alts' things; stat weights decide upgrades | `Doc/ideas/Inventory.md`; tests `inventory.lua`, `sheet.lua`, `bags.lua` |
| Loot (`SaneUI_Loot`) | Stands in for the loot window and the roll frames: a line a thing at the mouse, kinds taken at once, the master looter's menu, room made when the bags are full, roll cards, a feed | tests `loot.lua` |
| Lore (`SaneUI_Lore`) | NPC talks as a scene over the world, the interface faded out, each reward read for you; books, voice overs and the library to come | `Doc/ideas/Dialogue.md`, `Doc/ideas/Lore.md`; tests `lore.lua` |
| Nameplates (`SaneUI_Nameplates`) | The game's plates in our dress: one line in a round-cornered bar, power and combo points, auras in three groups, borders by rank, smaller far away, the combat text; at a setting the health bar only, or the spells only (a faint dot, an arrow over your target) | tests `nameplates.lua` |
| Navigation (`SaneUI_Navigation`) | The minimap and the world map in one window, drawn from the game's tiles and art: pins from Core's data and the game, the quest log, routes by walking data with flights and ships, found herbs and ore, the satchel of minimap buttons, dungeon maps | `Doc/ideas/Navigation.md`; [navigation.md](navigation.md); tests `navigation.lua` |
| Social (`SaneUI_Social`) | The messenger-style chat window that stands in for the game's chat, its full screen with conversations, friends and the guild, the game's channels joined or left by its ticks | `Doc/ideas/Social.md`; [social.md](social.md); tests `social.lua` |
| SpeedLeveling (`SaneUI_SpeedLeveling`) | One key for questing and the leveling guide over the world, run by our own engine on text guides (the guide packs, bought guides opened for the account, pasted guides); class quest chains; professions along the way (off by default); a party on one guide, read together for all its classes, kept on the same step | `Doc/ideas/Leveling.md`; tests `speedleveling.lua`, `speedguide.lua`, `classquests.lua`, `classquests.py` |
| Tooltips (`SaneUI_Tooltips`) | The game's tooltips drawn anew on dark panels, a layout per kind, with the quests, professions, alts and prices of an item, a price graph and the forecast | `Doc/ideas/Tooltips/`; [tooltips.md](tooltips.md); tests `tooltips.lua` |

Tests are `dev/tests/<name>`; `dev/tests/run` lists them all in its header, with what each covers. The tools, the build and
the tests: [development.md](development.md). What is not built yet stands in each plan and on the task board (`saneui board list`).

## Shared names

- One global table, `SaneUI` (`SaneUI.Core` is Core); a module's own things live in its private `ns`. Saved
  variables, declared only in Core's and the two data addons' TOCs: `SaneUIDB` (account: settings, profiles, the
  error log), `SaneUICharDB` (character), `SaneUIData_Characters`, `SaneUIData_Guild`, `SaneUIData_Learned`,
  `SaneUIData_Shared`, `SaneUIData_Market`, `SaneUIData_Scans` (`Doc/guides/data.md`, *Saved variables*).
- `/sane` (`/saneui`) lists the modules and their commands. Core: `errors`, `options` (`config`, `settings`),
  `window`, `profile`, `data`, `feedback`, `arrange`; Abilities `abilities`; Social `social`; Combat `auras`, `meter`, `reminders`, `macros`;
  Guild `guild`; Loot `loot`; Navigation `map`; Nameplates `range`; Speed Leveling `guides`, `key`
  (`rg -n 'Core.Command\(' src`).
- Art ships from `assets/optimized/<Module>/Art/` (`dev/build` puts it into the addon's `Art/`); `src/` holds no
  pictures or sounds. XML only for templates and key bindings (`Bindings.xml`, `Core/Settings/*.xml`,
  `Navigation/Route.xml`).

## Blizzard's code

The ground truth for the client's API, events, frames, templates and strings is Blizzard's own interface code, its
newest export of each game (`dev/tools/blizzard where` prints the code and art folders; never a `references/`
folder, which is gone). Look a name up before using it:

| Need | Where |
| --- | --- |
| A symbol's code in both games, with the diff | `dev/tools/blizzard show <Name> [--retail]` |
| What differs between Forever and Retail (globals, `C_X.Function`, enums, events, art) | `dev/tools/blizzard games` (the lookup's `symbols.tsv`, `files.tsv`, `addons.tsv`, `art.tsv`); `dev/tests/games.lua` takes Forever's extras away in a test (`W.Play("retail")`) |
| What Sane UI takes from Blizzard's code | `dev/tools/blizzard uses [--list] [--unknown]` |
| API signatures, enums, events, which widget methods take a secret value | `Interface/AddOns/Blizzard_APIDocumentationGenerated/` in the export (`rg -n 'Name = "X"'`) |
| The game's own spellbook, its frame, search, tabs, pager | `Blizzard_PlayerSpells`, `Blizzard_PagedContent` |
| Chat edit boxes, slash and secure flow, docking | `Blizzard_ChatFrame` |
| Tooltips: the data processor, comparisons, line kinds | `Blizzard_SharedXMLGame/Tooltip/` (`TooltipDataHandler.lua`), `Blizzard_GameTooltip` |
| Menus (the new menu system) | `Blizzard_Menu` (its implementation guide) |
| The options framework | `Blizzard_Settings_Shared` (its README), `Blizzard_SettingsDefinitions_*` |
| Scroll boxes, fonts, templates, pools, secure templates | `Blizzard_SharedXML`, `Blizzard_SharedXMLBase`, `Blizzard_Fonts_Shared`, `Blizzard_FrameXML` (`SecureTemplates.lua`) |
| Edit Mode, unit frames, nameplates, action bars, auction house, the panel manager | `Blizzard_EditMode`, `Blizzard_UnitFrame`, `Blizzard_NamePlates`, `Blizzard_ActionBar`, `Blizzard_AuctionHouseUI`, `Blizzard_UIParentPanelManager` |
| The game's art by path or atlas name | the export's art folder (look a known path up; never list it all); `saneui showgameart` for the numbered pieces Sane UI's look is picked from |

Restrict every search in the export to an addon folder and a name; check the flavour folders (`Mainline`, `Classic`,
`Camelot`, `Shared`) and the TOC conditions before assuming a file loads in a game. After a new build of either game:
`Doc/guides/blizzard-updates.md`.

## Keeping the map useful

These notes hold stable architecture, contracts and traps, not a manual or a diary: update the note of a module when a
contract, a file's responsibility or a workflow changes; what the player sees stands in the module's README; every
change goes into `Doc/Changed.md`. Nothing here says that something is untried in the game.
