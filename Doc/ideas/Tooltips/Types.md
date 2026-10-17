# Tooltips: every type, for the redesign

Planning notes (Saneroki, 2026-10-16): the Tooltips module gets a new look, with art made by AI image
generation. **The data and the layout stay** as they are (`src/Tooltips/README.md`, *What each panel
shows*); only the look changes. This page lists every type of tooltip the module draws, so each can
get a design of its own, and, for the types with a portrait (units only), what the game says about the
unit: race, gender, creature type, faction and more.

For each type: how the module knows it (the game's data kind, `Enum.TooltipDataType`, and what it asks
the game), what it looks like now, and what its panel shows. A *variant* is the same type with a
different look (a quality, a school); it needs no layout of its own.

## The plan (Saneroki, 2026-10-16)

- **One template per tooltip type,** made by AI image generation: the panel's ground, its frame, the place
  for the picture, the dividers and captions, the ring or plaque. A template per type, not per thing:
  a few dozen images, not thousands. A look is put together from layers (a ground by the thing's theme,
  a border and a socket by its standing, a colour, marks): see *Looks*, with every look and the list of
  images. How it is built (the code, falling back, the cost, tests, the steps): [Build.md](Build.md).
- **The picture comes from the game,** not from us: a unit's live 3D model (done: the option *Live 3D
  portraits*, `Figure` in `Panel.lua`), and later an item's 3D model where it has one (a weapon, a shield,
  a helm alone; armour worn by your own character); where the game cannot draw a model, its flat picture
  (a unit's portrait, an item's or spell's icon).
- **The data fills the template:** what the game says and what the module's own databases know, as the
  panels show it now.
- **One step at a time.** The way the panels are drawn may have to change for the templates (a stage for a
  whole model, art behind the rows); that comes after the models.

## The parts every design restyles

What a panel is made of now (`Panel.lua`, `Pools.lua`); the new art replaces these part by part.

| Part | Now | Used by |
| --- | --- | --- |
| Background | One gradient in the panel's colour, strong at the top, dark at the bottom; round corners, soft edge 8 wide (`Art/soft.tga`); no border | every type |
| Name | Capitals, in the thing's colour; 14 (the text size setting) | every type |
| Line over the name | Small: binding (*BoE*, red until bound), *Equipped*, *Uncollected* | items |
| Subtitle lines | Small and grey under the name: kind and slot, school, race, class line | every type |
| Icon | 64, over the top right corner (10 out at the right and the top), round corners, soft edge (`Art/icon-mask.tga`) | items, spells, buffs |
| Portrait | 64: the unit's live 3D model, its face in view (`PlayerModel`, cut square); where the game cannot draw it, the flat picture, round with a soft edge (`SetPortraitTexture`, `Art/portrait-mask.tga`) | units |
| Plaque | Gold rectangle on the icon's lower edge with the level or *iLvl 50 - 60* (`Art/plaque.tga`) | items, units |
| Dragon ring | The game's target-frame dragon round the portrait: gold, gold winged, silver winged (`Interface\HUD\UIUnitFrameBoss2x`) | units with a rank, players |
| Side | *Alliance* or *Horde* as a word on the race line (*Human · Alliance*) | players |
| Divider | One dark pixel line, a faint light one under it | every type |
| Caption | Small capitals between two lines (*QUEST*, *GOLD*, *OBJECTIVES*) | sections |
| Strips | The facts the tooltip states (cost, range, cast, cooldown, in the game's order), then the computed numbers; a cell only for a known value | spells |
| Large number | 4 larger than the text: a weapon's DPS | weapons |
| Bars | Flat, half see-through, round corners (`Art/bar-mask.tga`): health with its numbers inside, power over its lower part; durability (100 wide); a buff's running time with the caster inside | units, items, buffs |
| Small icons | 16, beside a row: sword (to kill), sack (to loot), ! (offered), ? (to turn in), tick (done), box (objective), profession icons | sections |
| Buff icons | 20, round corners (`Art/aura-mask.tga`), up to 16 | units |
| Alt details | Small, at the bottom: the thing's number left, its icon's number right | every type |

## Tooltip types

### Items (`Item`, `Toy`: `Kinds/Item.lua`, `Kinds/Gold.lua`)

The panel's colour is the item's quality (`ITEM_QUALITY_COLORS`); the icon is the item's.

| # | Type | Known by | Shows (kept) |
| --- | --- | --- | --- |
| I1 | Weapon | the game's damage line (*(53.8 damage per second)*) | Binding; name; kind and slot (*Axe · Two-Hand*); level and class needs at the right; item level on the plaque; *53.8 DPS* large with hit and speed small; stats, *Equip:* lines; durability bar; Quest and Gold sections |
| I2 | Armour | the armour line (*115 Armor*) | As a weapon, with the armour in place of the DPS |
| I3 | Jewellery, trinket, off-hand without armour | worn, but no damage and no armour line | As armour, without the large number |
| I4 | Bag | its kind (*Container*) | Kind, slots; Gold |
| I5 | Consumable (potion, food, elixir, scroll, bandage) | its kind (*Consumable*) | Its *Use:* line, level needed; Gold |
| I6 | Trade good, reagent | its kind (*Trade Goods · Cloth*) | **Professions** section (*Used in* with the professions' icons); Quest section where quests want it; Gold |
| I7 | Recipe | the game's nested block (what it makes) | Like an item; under the caption *Creates* the made thing with its icon; the profession and skill it needs at the right |
| I8 | Quest item | binding *Quest* | **Quest** section: *Needed for* with each quest's standing (*In log 1/4*, *Available*, *Not yet*, *Done*) |
| I9 | Item that starts a quest | the quest facts (`ns.QuestFacts`: an item's `b`, a creature's `s`) | **Quest** section: *Starts* and the quest with its standing |
| I10 | Junk | quality Poor | Grey name; Gold: mostly *Vendor* alone |
| I11 | Toy, mount, pet, key and other items | the game's data kind `Toy`, or its kind (*Miscellaneous*) | Name, kind, lines; Gold |
| I12 | Comparison (what you wear) | the game's comparison tooltips (`ShoppingTooltip1`, `2`) | *Equipped* over the name in gold; 85% opacity; the changes (*+2.2 DPS*) as lines; no sections, only the vendor price for one |
| I13 | Item at the auction house (to buy) | the game filled it for the auction house's lists (`GetItemKey`) | Gold: *Buy if under* (green while the price now is under it, red over it) and *now* with that price |

Quality, a variant of every item type: Poor (grey), Common (white), Uncommon (green), Rare (blue),
Epic (purple), Legendary (orange), Artifact (light gold).

### Spells (`Spell`, `PetAction`: `Kinds/Spell.lua`)

The panel's colour is what the spell is; the icon is the spell's.

| # | Type | Known by | Shows (kept) |
| --- | --- | --- | --- |
| S1 | Spell that hurts | a damage number in its description | School and rank; strip: *DPS* over *Damage*, *Cast* over *Cooldown*, *Mana* (with its share) over *Per Mana*, *Range* over *Crit*; description with its numbers in the panel's colour |
| S2 | Spell that heals | a healing number | As S1, with *HPS* and *Healing*; green unless a school is named |
| S3 | Crowd control | its description (stun, fear, ...) | One row: cast, cooldown, cost, range; *CC*; blue |
| S4 | Utility | none of the above | One row; *Utility*; grey |
| S5 | Passive | the game's *Passive* line | *Passive* in place of the rank |
| S6 | Melee swing, shot | the game's swing spells | *Speed* in place of *Cast* |
| S7 | Pet ability | the game's data kind `PetAction` | As a spell |

Colour, a variant of S1 to S4 (`Texts.lua`, `ns.STATS`): Fire `#FF6E1C`, Frost `#4DC7F7`, Arcane
`#EB61D6`, Nature `#80CC47`, Shadow `#C273FF`, Holy `#FABA38`; no school named: Healing `#59D966`,
Physical `#D94538`, CC `#949EFF`, Utility grey `#9E9E9E`.

### Units (`Unit`, `Corpse`: `Kinds/Unit.lua`)

Every unit has a portrait; the types are listed in the table under *Portrait types* below (P1 to
P21): a player, an enemy, an elite, a rare, a raid boss and so on are each a type of its own there.

### Buffs and debuffs (`UnitAura`: `Kinds/Aura.lua`)

| # | Type | Known by | Shows (kept) |
| --- | --- | --- | --- |
| A1 | Buff | helpful | *Buff* and what takes it away; description; a bar that runs out with its time, *17 minutes remaining* and *by* the caster inside; blue `#4D9EFF` |
| A2 | Debuff: Magic, Curse, Poison, Disease | harmful, with a kind | *Debuff · Magic*; as a buff; the game's colour of its kind (magic blue, curse purple, poison green, disease brown) |
| A3 | Debuff without a kind | harmful, no kind | As A2; red `#D94538` |
| A4 | Buff or debuff without a time | no duration | As A1 or A2, without the bar; the caster in a line of its own |

### Quests (`Quest`: `Kinds/Quest.lua`)

| # | Type | Known by | Shows (kept) |
| --- | --- | --- | --- |
| Q1 | Quest link | the game's data kind `Quest` | *Level 27* in the colour of its difficulty and where it stands for you (*In progress*, *Ready to turn in*, *Completed*, or nothing); its text; *Objectives* with a box each, ticked and green when done |

### Everything else (`Read.Generic`)

A grey panel fading to black, the name in capitals, its lines; an empty line becomes a divider. No
icon (the game gives none for these). Each could get a design of its own:

| # | Type | Known by |
| --- | --- | --- |
| G1 | Thing in the world: mailbox, herb, ore vein, chest, door, *Wanted* poster (a layout of its own to come: *Looks*, world objects) | the game's data kind `Object` |
| G2 | Currency | `Currency` |
| G3 | Mount, companion pet | `Mount`, `CompanionPet`, `BattlePet` |
| G4 | Macro | `Macro` |
| G5 | Minimap: what is under the mouse there | `MinimapMouseover` |
| G6 | Totem on the bar | `Totem` |
| G7 | Equipment set, outfit | `EquipmentSet`, `Outfit` |
| G8 | Flyout, instance lock, achievement, party quest progress | `Flyout`, `InstanceLock`, `Achievement`, `QuestPartyProgress` (some may not occur in this client) |
| G9 | Hint: a button's name and explanation (bags, menu buttons, options) | a tooltip written line by line, without data |

### On any type

Not types of their own, but a different look of any of them:

- **Chat link** (`ItemRefTooltip`): stays in the middle of the screen, closed by a click, no X.
- **Alt held**: the small technical section at the bottom; on an item every quest and where the
  prices come from.
- **Icons and portraits switched off**: no icon, no plaque, no dragon; the level stands right of the name.
- **Dead, ghost, offline**: a grey panel fading to black (units only).

## Looks (proposal)

A tooltip can look different by many things: a spell's element, a creature's type, a player's race and
class, an item's quality and kind, a herb, a chest. Hundreds of combinations, but each look is built
from a few **layers**, and each layer is chosen by one thing only. So a few dozen images give every
combination, and a new image is made only where the look should differ in kind.

### The layers

| Layer | What it is | Chosen by | Made by |
| --- | --- | --- | --- |
| **Ground** | The scene or material in a band at the panel's top (flames, frost, a forest, plate steel), fading out on every side, dark where the rows begin | The thing's theme: an element, a material, a creature type, a homeland, a profession | AI image, shared between layouts |
| **Border** | The panel's edge and corners, stretched with the panel (its corners kept) | The layout, and the thing's standing: an item's quality, buff or debuff | AI image, neutral metal |
| **Socket** | The mount round the picture, of a fixed size: round for units, square for items, spells, buffs | A unit's rank (it replaces the dragon) | AI image, neutral metal |
| **Picture** | The 3D model, the icon, the flat portrait | The thing itself | The game |
| **Accent** | A colour laid over border and socket, the base's gradient and the name | The game's colour: quality, class, reaction, school, the kind of a debuff | No image: a tint |
| **Marks** | Small signs in the border's corner | Facts on top: class, an NPC's role, PvP, quest, a profession needed | The game's own art, never tinted |
| **Wash** | Ground, border and socket grey | Dead, ghost, offline | No image: desaturated, the game's way for what is not available |
| **Rows** | The data | As the panels show it now | The game and our databases |

The rule for choosing a layer:
- **Own image (ground, border, socket):** the look differs in kind (fire and frost, a spider and a
  dragon, cloth and plate, an elite and a boss).
- **Accent:** only the colour differs (quality, class, reaction).
- **Mark:** a fact that comes on top of any look (PvP, a vendor, *Uncollected*).
- **Nothing:** the model or the text shows it already (gender, a beast's family, a reputation faction).

Every fact is known by an ID or by the game's own value, not by its words in one language; what the
game does not say comes from Core's data (`Doc/ideas/Data.md`). Each layout has a default for what is
unknown or hidden. Details: [Build.md](Build.md).

### Items

| Dimension | Values | Layer | Known by |
| --- | --- | --- | --- |
| Quality | Poor, Common, Uncommon, Rare, Epic, Legendary, Artifact, Heirloom (`Enum.ItemQuality` 0 to 7; 8, the WoW Token, does not occur) | Border: **Plain** (Poor, Common), **Fine** (Uncommon, Rare), **Grand** (Epic), **Legendary** (Legendary, Artifact, Heirloom), the tiers differing in ornament; the square socket; accent: the quality's colour | `C_Item.GetItemQualityByID`, `ITEM_QUALITY_COLORS` |
| Kind | Below | Ground | `C_Item.GetItemInfoInstant`: class, subclass, slot (`INVTYPE_*`) |
| Facts | Binding, *Equipped*, *Uncollected*, starts a quest, needed for a quest, not usable (red), broken, for one class, needs a profession | Marks (binding stays words) | As now |

The kinds and their ground (class and subclass as the game names them, `Enum.ItemClass` and its
subclasses). The first that fits decides: the data kind *Toy*; then class and subclass; then class and
slot; then the class's default (the last list); then Neutral. The quality never picks the ground: a poor
weapon has the Weapon ground, only *Miscellaneous · Junk* the Junk one.

| Item | Class · subclass, slot | Ground |
| --- | --- | --- |
| Axes, maces, swords, daggers, fist weapons, polearms, staves | Weapon | Weapon |
| Bows, guns, crossbows, thrown weapons, wands | Weapon | Ranged |
| Fishing pole | Weapon · Fishing pole | Fishing |
| Cloth armour, cloaks, shirts, tabards | Armor · Cloth; `INVTYPE_CLOAK`, `_BODY`, `_TABARD` | Cloth |
| Leather armour | Armor · Leather | Leather |
| Mail armour | Armor · Mail | Mail |
| Plate armour | Armor · Plate | Plate |
| Shield | Armor · Shield | Shield |
| Held in the off-hand; libram, idol, totem, sigil, relic | Armor · Generic with `INVTYPE_HOLDABLE`; Libram, Idol, Totem, Sigil, Relic | Relic |
| Ring, neck, trinket; gems | Armor · Generic with `INVTYPE_FINGER`, `_NECK`, `_TRINKET`; Gem | Jewel |
| Potion, elixir, flask | Consumable · Potion, Elixir, Flask | Alchemy |
| Food and drink | Consumable · Food & Drink | Cooking |
| Bandage | Consumable · Bandage | First Aid |
| Scroll; book recipe | Consumable · Scroll; Recipe · Book | Scroll |
| Oils, sharpening stones, enchantments | Consumable · Item Enhancement; Item Enhancement | Enchanting |
| Other consumables | Consumable · Generic, Other | Consumable |
| Bags, profession bags | Container | Bag |
| Quiver, ammo pouch; arrows, bullets | Quiver; Projectile | Ammo |
| Cloth | Trade Goods · Cloth | Tailoring |
| Leather, hides | Trade Goods · Leather | Leatherworking |
| Ore, bars, stone | Trade Goods · Metal & Stone | Mining |
| Herbs | Trade Goods · Herb | Herbalism |
| Meat, fish | Trade Goods · Meat | Cooking |
| Elementals (essences, motes) | Trade Goods · Elemental | Elemental (a creature type's ground) |
| Dusts, essences, shards | Trade Goods · Enchanting | Enchanting |
| Parts, explosives, devices | Trade Goods · Parts, Explosives, Devices | Engineering |
| Other trade goods; reagents | Trade Goods · Other; Reagent; Miscellaneous · Reagent | Reagent |
| Recipe, pattern, plans, schematic, formula, manual | Recipe · Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Fishing, Leatherworking, Tailoring | That profession's |
| Quest item | Quest | Quest |
| Key | Key | Lockpicking |
| Junk | Miscellaneous · Junk | Junk |
| Mount, its gear | Miscellaneous · Mount, Mount Equipment | Mount |
| Companion pet | Miscellaneous · Companion Pet; Battle Pet | Critter (a creature type's ground) |
| Toys, holiday items and everything else | Miscellaneous · Other, Holiday; the data kind `Toy` | Neutral |

The class's default, where the subclass and slot have no row of their own: Weapon: Weapon. Armor:
Neutral (a shirt, a tabard or a cloak: Cloth). Consumable: Consumable. Container: Bag. Gem: Jewel.
Reagent: Reagent. Projectile, Quiver: Ammo. Trade Goods: Reagent. Item Enhancement: Enchanting. Recipe:
Scroll (also Jewelcrafting and Inscription, which have no ground). Quest: Quest. Key: Lockpicking.
Miscellaneous and every other class (Glyph, Profession, Housing, ...): Neutral.

Which subclass this client gives a potion, food or a scroll is to check in the game: the original
game's data had none for consumables. If they are all *Generic*, they share the Consumable ground.

### Spells

| Dimension | Values | Layer | Known by |
| --- | --- | --- | --- |
| Element | Physical, Holy, Fire, Nature, Frost, Shadow, Arcane; no school named: Healing (it heals), Neutral (utility) | Ground; accent: the school's colour (*Spells* above) | Its description, as now (`Texts.lua`, `ns.STATS`) |
| Source | Class spell, profession, general (mount, hearthstone), racial, pet ability | A profession's spell has the profession's ground (a crafting or gathering spell); every other spell its element's. One border **Spell**, the square socket; accent: the class's colour on a class spell | Its skill line, from Core's Spells pack; not read yet |
| Facts | Passive, crowd control, rank, not learned yet, a talent's ranks | Marks | As now; a talent's ranks: not read yet |

### Units

| Dimension | Values | Layer | Known by |
| --- | --- | --- | --- |
| Rank | Normal (and trivial, minor: dimmed), Elite, Rare, Rare elite, Boss (dungeon, raid and world boss), Player | Socket: one each, six, round (they replace the dragons); border: **Unit** | `UnitClassification`, `UnitIsBossMob`, `UnitIsPlayer` |
| Race (players) | The ten races (*What the columns can be*) | Ground: the race's homeland, one each | `UnitRace` (file name) |
| Creature type (NPCs) | Beast, Critter and Non-combat Pet, Demon, Dragonkin, Elemental, Giant, Humanoid, Mechanical, Undead; Totem and Not specified: Neutral | Ground, one each; Humanoid has two: **Town** (friendly) and **Camp** (hostile or neutral) | `UnitCreatureType`, turned into its ID by `C_CreatureInfo` (its word differs by language); `UnitReaction` |
| Class (players) | The nine classes | Accent: the class colour; mark: the class's crest (the game's class circle, `UI-Classes-Circles`) | `UnitClass` (file name), `RAID_CLASS_COLORS` |
| Reaction (NPCs) | Hostile, unfriendly, neutral, friendly | Accent: red, orange, yellow, green | `UnitReaction` |
| Side | Alliance, Horde, none | A word on the race line (players; not shown for NPCs) | `UnitFactionGroup` |
| Role (NPCs) | Quest giver (! and ?), vendor, repair, trainer (class, profession), flight master, innkeeper, banker, auction house NPC, stable master, guild master, battlemaster, spirit healer, guard | Mark: the game's icon for it, from the minimap's tracking menu (`Interface\MINIMAP\TRACKING\`) | Core's World pack, an NPC's `services` by its creature ID; until then its title line (*<Flight Master>*, English only) and, for quests, the quest facts |
| State | Dead, ghost, offline, AFK, DND, tapped, PvP | Marks; dead, ghost and offline also wash the look (desaturated) | As now |
| Gathering a corpse | Skinning, Herbalism, Mining, Engineering | Mark: the profession's icon, red while you cannot | The game's line (*Skinnable*), as now |
| Quests | A quest target: to kill, to loot | Marks (sword, sack), as now | As now |
| Nothing of its own | Gender, a beast's family, a reputation faction, level | The model and the text show them | |

### Buffs and debuffs

| Dimension | Values | Layer | Known by |
| --- | --- | --- | --- |
| Helpful or harmful | Buff, debuff | Border: **Buff**, **Debuff**; the square socket | As now |
| Element | A buff: its spell's element (as a spell's). A debuff: its kind: Magic (Arcane), Curse (Shadow), Poison (Nature), Disease (its own: **Disease**), none (Physical) | Ground; accent: the kind's colour | The aura (`dispelName`), its description |
| Facts | Time left, stacks, who cast it | The bar and marks, as now | As now |

### Quests

| Dimension | Values | Layer | Known by |
| --- | --- | --- | --- |
| Quest | Every quest | Border and ground: **Quest** (one each) | |
| Kind | Normal, elite, group, dungeon, raid, PvP; for a class, for a profession | Marks | The quest's tag (`C_QuestLog.GetQuestTagInfo`), not read yet; the quest facts (class) |
| Standing | Not taken, in progress, ready to turn in, done, failed | Marks (!, ?, tick), as now | As now |

### World objects (a layout to come; now *Everything else*)

Every object is known by its kind in Core's World pack (*Objects*: kind and the skill it needs, by the
object's ID), if the tooltip's data gives the ID (to check in the game). Until then, and without an ID,
only by the game's words, in English: the line that names the profession it needs, *Locked*, its name.

| Object | Ground |
| --- | --- |
| Herb | Herbalism |
| Mineral vein, deposit | Mining |
| School of fish, pool | Fishing |
| Chest, footlocker, locked box | Lockpicking |
| Something for a quest (the game's quest lines; the quest facts, no objects in them yet) | Quest |
| Anvil, forge | Blacksmithing |
| Cooking fire, campfire | Cooking |
| Book, plaque, sign, letter, *Wanted* poster | Scroll |
| Mailbox (mark: the game's mailbox icon), door, lever, portal, meeting stone, anything else | Neutral |

One border, **World**. Accent: the colour of how hard it is to gather (the game's: red while you
cannot, orange, yellow, green, grey). Marks: the skill it needs, *Locked*. Picture: the game has none
for an object; the profession's icon, or later the item it gives (from Core's data).

### Everything else

Border **Plain**, ground **Neutral** (no ground: the base alone), but:

| Tooltip | Ground |
| --- | --- |
| Currency, money | Currency |
| Mount | Mount |
| Companion pet | Critter |
| A zone on the map (with the Maps module) | Its side: Alliance, Horde, contested, sanctuary (marks) |
| Hint (a button's name and explanation) | None: the border alone |

### Where a tooltip is shown

Where a tooltip stands changes its rows, not its look. This is true in the bags, the bank, on the character
(*Equipped*), beside another (a comparison: faded), at a vendor (the price or cost), at the auction
house (*Buy if under*), in the loot window, as a quest's reward, in the mail and the trade window, in
chat (a link: in the middle of the screen), at a trainer (the cost), in the talents (the ranks), on the
action bars.

### The images to make

| Layer | Images | Count |
| --- | --- | --- |
| Grounds: elements | Physical, Holy, Fire, Nature, Frost, Shadow, Arcane, Healing, Disease (Neutral is no picture: the base alone) | 9 |
| Grounds: professions | Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Fishing, Herbalism, Leatherworking, Lockpicking, Mining, Skinning, Tailoring | 13 |
| Grounds: gear | Weapon, Ranged, Cloth, Leather, Mail, Plate, Shield, Relic, Jewel, Ammo | 10 |
| Grounds: goods and places | Scroll, Consumable, Bag, Reagent, Quest, Junk, Mount, Currency | 8 |
| Grounds: creatures | Beast, Critter, Demon, Dragonkin, Elemental, Giant, Humanoid town, Humanoid camp, Mechanical, Undead | 10 |
| Grounds: homelands | One per race: Human, Dwarf, Night Elf, Gnome, Orc, Undead, Tauren, Troll, this client's own race (2 sides: 1 or 2) | 9 to 10 |
| Borders | Items: Plain, Fine, Grand, Legendary (Plain also for everything else). Unit. Spell. Buff, Debuff. Quest. World | 10 |
| Sockets | Round, for units: Normal, Elite, Rare, Rare elite, Boss, Player. Square, for items, spells and buffs: one | 7 |
| Marks | Only where the game has no art: *Uncollected*, *Locked* | 2 |
| **In all** | | **about 80** |

Each picture is drawn once and fits every layout and every panel size that uses it, as
[Build.md](Build.md) (*The layers as drawn*) says: a ground is a band at the top, as wide as the
panel, its proportions kept, fading out on all sides, dark where the rows begin; a border stretches
with its corners kept (the ornament in the corners, even mouldings between); a socket has a fixed size
and solid metal round its window. Borders and sockets are neutral metal, so the accent can tint them.

## Portrait types

Only units have a portrait: players, NPCs, creatures, pets. Each row is a type that looks different now or
should look different. The columns say what the game tells about such a unit, and with which function;
*not shown* means the game knows it but the panel does not show it yet.

| # | Portrait type | Known by | Race | Gender | Creature type · family | Faction | Reaction (name colour) | Rank | Class | Plaque | Ring now | Panel colour now |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | Player, your side (you, party, raid too) | `UnitIsPlayer`, same `UnitFactionGroup` | yes (`UnitRace`) | male, female (`UnitSex`; not shown) | Humanoid (not shown) | Alliance or Horde: a word on the race line | friendly | none | yes, with spec and talent points | level; *iLvl* before it | gold dragon | class colour |
| P2 | Player, other side (enemy) | `UnitIsPlayer`, the other `UnitFactionGroup` | yes | male, female (not shown) | Humanoid (not shown) | the other side's word | hostile; *PvP* in red | none | yes (spec once inspected) | level, *iLvl* once inspected | gold dragon | class colour |
| P3 | Player dead, ghost, offline | `UnitIsDead`, `UnitIsGhost`, `UnitIsConnected` | yes | male, female (not shown) | Humanoid (not shown) | side word | as P1 or P2 | none | yes; *Dead*, *Ghost*, *Offline* | level | gold dragon | grey `#9E9E9E` |
| P4 | Friendly NPC: vendor, trainer, flight master, innkeeper, banker, guard | not a player, `UnitReaction` 5 or more; its title line (*<Flight Master>*) | none (the game has no race for an NPC; the portrait shows it) | `UnitSex` (often unknown; not shown) | mostly Humanoid | reputation faction from its line (*Stormwind*); side `UnitFactionGroup` (not shown) | friendly: green | normal; a guard may be elite | not shown for a friendly NPC | level | none (gold for an elite guard) | name colour: green |
| P5 | Quest giver | a friendly NPC the quest facts know (`ns.QuestFacts.npc`: `g`, `t`) | none | `UnitSex` (not shown) | mostly Humanoid | reputation faction | friendly: green | normal | not shown | level | none | green; **Quest** section with *Offers* (!), *Turn in*, *In progress* (?) |
| P6 | Neutral creature | `UnitReaction` 4 | none | `UnitSex` (not shown) | any; family for beasts | its faction line, if any | neutral: yellow | normal | for humanoids (*Warrior*, *Mage*) | level in its difficulty colour | none | yellow |
| P7 | Enemy: hostile creature | `UnitReaction` 3 or less | none | `UnitSex` (not shown) | any (*Humanoid · Defias Brotherhood*, *Beast · Wolf*) | its faction line | hostile: red (unfriendly: orange) | normal | for humanoids | level in its difficulty colour | none | red; XP and kills to level |
| P8 | Quest target | an enemy your quests want: the game's quest lines, the quest facts (`ns.QuestFacts.npc`: `d`) | none | (not shown) | any | its faction line | hostile | any | for humanoids | level | by rank | as P7; **Quest** section: sword (to kill), sack (to loot, with *33%*), count at the right |
| P9 | Elite | `UnitClassification` *elite* | none | (not shown) | any | its faction line | hostile, neutral or friendly | *Elite*, gold | for humanoids | level | gold dragon | name colour; XP twice |
| P10 | Rare | *rare* | none | (not shown) | any | its faction line | mostly hostile | *Rare*, silver | for humanoids | level | silver winged dragon | name colour |
| P11 | Rare elite | *rareelite* | none | (not shown) | any | its faction line | mostly hostile | *Rare Elite*, silver | for humanoids | level | silver winged dragon | name colour |
| P12 | Dungeon or raid boss | `UnitIsBossMob` | none | (not shown) | any | its faction line | hostile | *Boss*, gold | for humanoids | level, *??* when far above you | gold winged dragon | name colour |
| P13 | World boss | *worldboss* | none | (not shown) | mostly Dragonkin, Demon, Giant | its faction line | hostile | *Boss*, gold | rarely | *??* | gold winged dragon (as P12) | name colour |
| P14 | Trivial creature | *trivial*, or a grey level | none | (not shown) | any | its faction line | any | none | for humanoids | grey level | none | name colour; no XP |
| P15 | Minor creature | *minus* (small adds) | none | (not shown) | any | its faction line | any | none | rarely | level | none | name colour |
| P16 | Critter | creature type *Critter* (rabbit, rat, deer) | none | (not shown) | Critter | none | neutral or friendly | none | none | level 1 | none | name colour; no XP |
| P17 | Combat pet: a hunter's beast, a warlock's demon | its owner line (*Somniferie's Pet*) in place of a title | none | (not shown) | Beast or Demon, with its family (*Wolf*, *Imp*) | its owner's side | as its owner | none | none | level | none | name colour; power bar: focus (a beast) or mana (a demon) |
| P18 | Companion | creature type *Non-combat Pet*, an owner line | none | (not shown) | Non-combat Pet | its owner's side | as its owner | none | none | level | none | name colour |
| P19 | Totem | creature type *Totem*, an owner line | none | none | Totem | its owner's side | as its owner | none | none | level | none | name colour |
| P20 | Tapped creature | `UnitIsTapDenied`: somebody else's kill | none | (not shown) | any | its faction line | hostile | any | for humanoids | level | by rank | as its rank; *Tapped* in grey; no XP |
| P21 | Dead creature (corpse) | the game's data kind `Corpse`, `UnitIsDead` | none | (not shown) | any | its faction line | as alive | by rank | for humanoids | level | by rank | grey `#9E9E9E`; *Dead* and what it yields (*Skinnable*; red while you cannot gather it) |

Also on every unit: health bar (green, `#66C75C`) with its numbers, power bar in the game's colour
(`PowerBarColor`), whom it targets, its buffs (outside a fight), and Alt's *NPC ID* or a player's GUID.

### What the columns can be

**Races** (`UnitRace`: name, file name, number; players only). For a portrait per race and gender:
10 races, 20 portraits.

| Race | File name | Number | Side |
| --- | --- | --- | --- |
| Human | Human | 1 | Alliance |
| Dwarf | Dwarf | 3 | Alliance |
| Night Elf | NightElf | 4 | Alliance |
| Gnome | Gnome | 7 | Alliance |
| Orc | Orc | 2 | Horde |
| Undead | Scourge | 5 | Horde |
| Tauren | Tauren | 6 | Horde |
| Troll | Troll | 8 | Horde |
| This client's own race (its name: to be read in the game) | ? | 95 | Alliance |
| The same race | ? | 96 | Horde |

**Gender** (`UnitSex`): 1 unknown or none, 2 male, 3 female. Players are always male or female; for
an NPC the game often says unknown.

**Classes** (`UnitClass`), each in the game's class colour (`RAID_CLASS_COLORS`): Warrior, Paladin,
Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid. A creature has one too (*Warrior*, *Mage*,
*Paladin*, *Rogue*); the panel shows it only where it says more than the name.

**Creature types** (`UnitCreatureType`, not for players): Beast, Critter, Demon, Dragonkin, Elemental,
Giant, Humanoid, Mechanical, Undead, Totem, Non-combat Pet, Not specified.

**Families** (`UnitCreatureFamily`, beasts and demons only), as the original game names them: Wolf, Cat,
Spider, Bear, Boar, Crocolisk, Carrion Bird, Crab, Gorilla, Raptor, Tallstrider, Scorpid, Turtle, Bat,
Hyena, Owl, Wind Serpent; demons: Imp, Voidwalker, Succubus, Felhunter, Doomguard; and Remote Control.

**Faction:**
- Side (`UnitFactionGroup`): *Alliance*, *Horde*, or none (neutral). A player always has one (a
  word on the race line); an NPC of a city or a side does too (not shown).
- Reputation faction: the game's line after the level line (*Stormwind*, *Orgrimmar*, *Darkspear
  Trolls*, *Defias Brotherhood*, *Booty Bay*, *Argent Dawn*, ...), shown after the creature type.

**Reaction** (`UnitReaction`, the name's colour, `FACTION_BAR_COLORS`): 1 hated and 2 hostile red, 3
unfriendly orange, 4 neutral yellow, 5 friendly to 8 exalted green.

**Rank** (`UnitClassification`): *normal*, *elite*, *rare*, *rareelite*, *worldboss*, *trivial*,
*minus*; and `UnitIsBossMob` for a dungeon's or raid's boss.

**Level** (`UnitLevel`): a number in the colour of how hard the unit is for you
(`GetCreatureDifficultyColor`: grey, green, yellow, orange, red), *??* (-1) for one far above you.

**Power** (`UnitPowerType`, `PowerBarColor`): mana (blue), rage (red), energy (yellow), focus (orange).
