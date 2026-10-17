# Tooltips redesign: how it is built

The engineering plan for the new look in [Types.md](Types.md) (Saneroki, 2026-10-16): what each part does,
what it may rely on, what happens when something is missing or fails, what it costs, how it is tested,
and in which steps it is built. Written for the session that builds it. Checked against the module's
code and `references/` on 2026-10-16; what only the game can show is marked *to check in the game*.

**Status:** plan. Built: the live 3D portrait (step 0). Nothing else yet.

## The review (2026-10-16)

A full pass over the plan in *Types.md*, after Saneroki: are the choices good, complete, and enough to
build from? What held, and what was changed (the changes are written into *Types.md*):

| | Finding | Done |
| --- | --- | --- |
| Kept | Layers, each chosen by one thing: a few dozen images for every combination, not one per combination. | |
| Kept | The picture comes from the game (models, icons, portraits): no art per thing. | |
| Kept | The accent is the game's own colour (`ITEM_QUALITY_COLORS`, `RAID_CLASS_COLORS`, ...): colours keep the meaning they have in WoW. | |
| Kept | Where a tooltip stands changes its rows, not its look. | |
| Kept | Reader → plain model → draw, as the module works now: the look can be worked out from plain data and tested outside the game. | |
| Changed | Some things were to be known by their words: a mailbox by its name, an NPC's role by *<Flight Master>*, a creature type by `UnitCreatureType`'s word. That fails in every other language (addon standards, *Text and languages*), and lists of NPCs and objects are data work, which is Core's (CLAUDE.md, *Backend and views*). | Known by IDs: a creature type by `C_CreatureInfo`; an NPC's services and an object's kind from Core's World pack (`Doc/ideas/Data.md`, *NPCs* `services`, *Objects*). The English words only until that pack exists. |
| Changed | Unit facts can be secret: `UnitCreatureType`, `UnitCreatureFamily`, `UnitRace`, `UnitClass`, `UnitSex` and `UnitGUID` are `SecretWhenUnitIdentityRestricted` in this client. A secret used as a table key locks the table for good. | Every fact through `Core.Plain`; nil gives the layout's default. Tested. |
| Changed | The *frame* was three shapes in one picture: an edge that stretches with the panel, a plate that stretches with the name, a socket of fixed size round the picture. One picture cannot do all three. | Split into the **border** (stretched, corners kept) and the **socket** (fixed size); the name plate is left out for now. A unit's rank is its socket, as the game's target frame shows the rank by the dragon round the portrait. The socket also hides the live model's square corners. |
| Changed | Where a ground lies, and how one picture fits panels from 220 to 440 wide and 60 to 700 high, was open. A picture must not be stretched (gui guide, *Art*), and a mask cannot keep round corners at every size (masks stretch whole: the module's README). | A band at the panel's top, as wide as the panel, its proportions kept, fading out on all four sides in its own alpha: it fits every size without a mask, a cut or a stretch. |
| Changed | A vertex colour multiplies: painted gold tinted green turns to mud. | Borders and sockets are drawn in neutral light metal and take the accent, as the game tints its grey tooltip border (`TooltipBackdropTemplateMixin:SetBackdropBorderColor`, `SharedTooltipTemplates.lua`). The game's own art (the marks) is never tinted. |
| Changed | Dead, ghost, offline were to wash the look grey, with no art said for it. | `SetDesaturated(true)` on ground, border and socket: the game's way for what is not available. No images. |
| Changed | An item could match two rows (a poor weapon: Junk or Weapon?), and not every class and subclass of the game had one. | One order of rules and a default for every item class: there is an answer for every item. |
| Changed | Grounds for one rare thing (Mailbox, Holiday). | Dropped: Neutral, and the game's mark for a mailbox. |
| Added | What happens when a file is missing, a fact unknown, an error. | *Falling back* |
| Added | Memory and time. | *What it costs* |
| Added | Tests, steps, what only the game can show, what is still open. | the sections below |

## The pipeline

```text
the game's tooltip -> reader (Kinds/*.lua) -> model: head + rows            (as now)
                                              the head holds the FACTS     (new: item class, creature type, ...)
model -> Model.Commit                          (only a change draws: as now)
      -> Look.Of(head)                         pure: facts -> keys (ground, border, socket, marks, wash)
      -> Panel.Draw                            keys -> art (Looks.lua); a layer is set only when its key changed
```

- **Facts in the model, not looks.** A reader writes what the game says about the thing into the head,
  as plain values (*Facts*); it never names a picture. Each new field goes into `HEAD` in `Model.lua`,
  or a changed fact would never draw the panel again (a field not listed there is not compared).
- **The look is worked out, not stored** (`Look.lua`, new): a pure function of the head, made of tables.
  No frames, no calls to the game, no state, so it is tested outside the game like the readers.
- **The art is data** (`Looks.lua`, new): each key with its file and how it is drawn. The code names no
  file: a picture is added by one line there and the file.
- **The panel draws the keys** (`Panel.lua`): one texture per layer per panel, made on the first draw
  that needs it; a texture is given a file only when its key changed (as `Pools.Text` keeps fonts).

## Facts

What each layout needs for its look, and from where. Everything read through `Core.Plain`; a hidden
value is nil.

| Layout | Fact | From | Without words | Can be secret |
| --- | --- | --- | --- | --- |
| Item | quality | `C_Item.GetItemQualityByID`, `GetItemInfo` | yes | no |
| Item | class, subclass, slot | `C_Item.GetItemInfoInstant` (as `Crafts` in `Kinds/Item.lua` does) | yes | no |
| Item | a toy | the tooltip's data kind `Toy` | yes | no |
| Spell | school | its description, as now (`Texts.lua`); later Core's Spells pack | English only, now | no |
| Spell | source: class, profession, general | Core's Spells pack (skill lines); not read yet | yes | no |
| Unit | player, rank | `UnitIsPlayer`, `UnitClassification`, `UnitIsBossMob`, as now (`head.dragon`) | yes | not marked so |
| Unit | race | `UnitRace`, its file name (second answer) | yes | when its identity is restricted |
| Unit | class | `UnitClass`, its file name (second answer) | yes | the same |
| Unit | creature type | `UnitCreatureType` (a word), turned into its ID: the words of every ID asked once from `C_CreatureInfo.GetCreatureTypeIDs` and `GetCreatureTypeInfo` | yes, by the ID | the same |
| Unit | reaction | `UnitReaction(unit, "player")` | yes | no |
| Unit | side | `UnitFactionGroup`, its first answer | yes | no |
| Unit | state | `UnitIsDead`, `UnitIsGhost`, `UnitIsConnected`, `UnitIsTapDenied` | yes | no |
| Unit | an NPC's services | Core's World pack (`NPCs:Get(creature).services`) by the creature ID in its GUID; until then the title line, in English | yes, from the pack | the GUID, when restricted |
| Buff | helpful or harmful, its kind | as now (`dispelName`) | yes | buffs are not asked for in a fight |
| Object | kind, skill needed | Core's World pack (*Objects*) by the object's ID, if the tooltip's data gives one (*to check in the game*); else the game's words, in English | from the pack | |

Do not get round a restricted identity (asking for a model or a type by an ID found elsewhere): where
the game hides who a unit is, the panel shows the default look.

## Look.lua: the rules

- One table per layout, read in a fixed order: the first rule that matches decides. Each layout ends in
  its default, so there is an answer for every input, nil included.
- A fact that is nil, unknown or secret never errors and never becomes a table key: it gives the
  default (`Core.Plain` makes a secret nil before anything looks it up).
- **Items:** the ground by (1) the data kind *Toy*: Neutral; (2) class and subclass; (3) class and slot
  (Armor · Generic); (4) the class's default; (5) Neutral. The quality picks only the border's tier and
  the accent, never the ground (a poor weapon has the Weapon ground). Facts (quest, binding) are only
  marks.
- **Units:** a player: the ground of the race's homeland; an NPC: of its creature type, a Humanoid's by
  its reaction (friendly, 5 and up: Town; else Camp); unknown: Neutral. The rank picks the socket.
  Dead, ghost and offline set the wash.
- **Spells:** a profession's spell (once the source is read): the profession's ground; else the
  school's; no school: Healing if it heals, else Neutral.
- **Buffs:** a debuff by its kind (Magic: Arcane, Curse: Shadow, Poison: Nature, Disease: Disease, none:
  Physical); a buff by its spell's school.
- **The answer:** `ground`, `border`, `socket`, the accent (r, g, b from the game's table, as `head.accent`
  now), `wash`, and up to three marks in a fixed order. Every key is a constant string from the tables:
  no string is put together and no table made per draw.

## Looks.lua: the art as data

```lua
-- Each look's picture and how it is drawn; sizes and coordinates as dev/tools/art prints them.
-- A key without a line here: its layer is not drawn, and the panel looks as it does now.
ns.LOOKS = {
    ground = {
        fire = { file = "ground-fire", coords = { 0, 1, 0, 0.73 } }, -- the band, 440 x 160 at the widest
    },
    border = {
        fine = { file = "border-fine", margin = 32, inset = 18, tint = true },
    },
    socket = {
        elite = { file = "socket-elite", size = 84, tint = true, round = true },
    },
}
```

Files under `Interface\AddOns\SaneUI_Tooltips\Art\looks\`, BLP as [images.md](../../guides/images.md)
says, made by `dev/tools/art` from `assets/`.

## The layers as drawn

| Layer | Region | Draw layer | Size and place | Art |
| --- | --- | --- | --- | --- |
| Base | `panel.back` (now) | BACKGROUND 1 | the panel and 8 past its sides, round soft edge | `soft.tga` and the gradient in the accent, as now. Stays under everything: the opacity setting, and the dark under the text |
| Ground | `panel.ground` (new) | BACKGROUND 2 | at the panel's top, as wide as the panel, proportions kept (a band of 440 x 160 at the widest), never higher than the panel | fades out on all four sides in its alpha, laid on by `dev/tools/art` (a kind `ground`), so every ground fades alike; dark in its lower half, where the rows begin. Nothing else stands behind it |
| Border | `panel.border` (new) | BORDER | the panel, as `panel.back` | one texture with slice margins (`SetTextureSliceMargins`, as `soft.tga` and the plaque are drawn): the ornament in the corners, even mouldings between ([image-generation.md](../../guides/image-generation.md), *From a picture to pieces*); neutral metal, tinted with the accent |
| Picture | `panel.icon`, `panel.figure` | ARTWORK; the figure a frame level over the panel | as now | the game's |
| Socket | `panel.socket` (new), on `panel.front` | OVERLAY, under the plaque | fixed size, its window on the picture | a mount with a window: round for units, square for items, spells and buffs. Solid metal round the window, so it covers the live model's square corners. Replaces the dragon |
| Marks | a small pool on `panel.front` | OVERLAY | 16 to 20 large, in one fixed place (a row in the border's lower left corner) | the game's own: the minimap's tracking icons (`Interface\MINIMAP\TRACKING\`: auction house, bank, battlemaster, class and profession trainer, flight master, food, inn, mailbox, poisons, reagents, repair, stable master, ammunition), the class circles (`Interface\TargetingFrame\UI-Classes-Circles` with `CLASS_ICON_TCOORDS`), the quest ! and ?. Never tinted |
| Rows | as now | ARTWORK, OVERLAY | inside the border's inset | |

- **The content stands inside the border:** `PAD` in `Panel.lua` becomes the border's `inset`, a value
  of the draw. The icon stays out over the top right corner; its socket covers the border's corner there.
- **Wash:** `SetDesaturated(true)` on ground, border and socket; the accent grey, as a dead unit's is now.
- **Frame levels:** as now, the figure over the panel, `panel.front` over the figure (`Panel.Draw`, after
  the panel's own level).

## Falling back

Each layer falls back by itself, down to the look of today:

| What | Then |
| --- | --- |
| A fact unknown, hidden or nil | the layout's default key |
| A key without a line in `Looks.lua` | that layer is not drawn |
| `SetTexture` finds no file (it says so: [images.md](../../guides/images.md), *Drawing it*) | that layer hidden; the key is noted, said once, and not asked for again this session |
| The option *Illustrated look* off | no ground, border, socket or marks: today's panel with its dragon |
| An error in `Look.lua` or while a layer is drawn | as every error now: the reader's kind or the whole module gives the tooltips back to the game (`ns.Read`, `ns.Guarded`) |
| New files after an update and only a `/reload` | the client finds no new file until it restarts: the layer falls back as missing, and the module's notice asks for the restart |

## What it costs

- **Time:** a panel is drawn only when its model changed (`Model.Commit`), not every frame; a unit's
  health and buffs do not draw it again (`Live.lua`). `Look.Of` is a few table lookups, with no new
  table or string. A texture is set only when its key changed.
- **Memory:** a loaded texture costs about its file's size (DXT5 with mipmaps, [images.md](../../guides/images.md),
  *Memory*). Whether the client lets go of a file no region shows any more is not documented, so count
  every ground seen as loaded until the next `/reload`. All of it loaded at once:

  | Art | Count | Texture | Each | Together |
  | --- | --- | --- | --- | --- |
  | Grounds | 59 | 512 x 256 | 171 KB | 10 MB |
  | Grounds, at the full size rule | 59 | 1024 x 512 | 684 KB | 40 MB |
  | Borders | 10 | 256 x 256 | 86 KB | 0.9 MB |
  | Sockets | 7 | 256 x 256 | 86 KB | 0.6 MB |

  So grounds of 512 x 256, unless they look poor in the measurement (*To check in the game*): about
  12 MB for everything, a few MB in a usual session. The band is soft and lies under dark text: half
  the size rule's sharpness should not show (reasoned, not measured).
- **Loading:** each file is read the first time it is shown, not at login ([images.md](../../guides/images.md),
  *Load on use*).
- **Models:** one model frame per panel (four panels at most: the tooltip, the chat link's, two
  comparisons). It is given a unit or an item only when that changes; a hidden one draws nothing.

## Tests

In `dev/tests/tooltips.lua` (or a file of its own for `Look.lua`):

- **Every value has a look:** each `Enum.ItemQuality`; each item class with each of its subclasses
  (from the enums); each creature type ID; each classification; the ten race file names; the nine class
  file names; each school; each kind of debuff; nil for each fact. Each gives a key that `Looks.lua`
  has, or none.
- **A secret fact** (the tests' stand-in for one) gives the default and is never a key.
- **No missing and no dead art:** every file `Looks.lua` names is in `src/Tooltips/Art/looks/`, and every
  file there is named. So `dev/build` fails on a missing picture.
- **The panel:** a key that did not change sets no texture again; a missing file hides its layer and is
  said once; the option off draws today's panel; the wash desaturates; socket and marks are on
  `panel.front`.
- What the tests cannot judge is the look: say so, and keep the list below.

## Steps

Each step is a commit that ships on its own and changes nothing the player sees until its art is there.

0. **Live 3D portraits.** Done (2026-10-16).
1. **Facts and `Look.lua`,** with their tests. Creature type IDs from `C_CreatureInfo`. Nothing drawn yet.
2. **`Looks.lua`, the layers in `Panel.lua`, the option *Illustrated look*;** the border's inset in place of
   `PAD`. Tried in the game with placeholder pictures made by a tool (a flat colour and the key's name on
   each), so the layout and every fall-back can be seen before there is any art.
3. **Art, first set** (what is seen most): borders and sockets; the grounds of the schools, the creature
   types and gear. With `dev/tools/imagegen` and `dev/tools/art` ([image-generation.md](../../guides/image-generation.md),
   [images.md](../../guides/images.md)); `dev/tools/art` gets the kinds `ground`, `border` and `socket`.
4. **Art, second set:** professions, goods and places, homelands.
5. **An item's 3D model** in its place, once units look right in the game: `SetItem(itemID)` on the
   model frame (weapons, shields, a helm alone), `TryOn` on your own character for armour; the camera
   by `Model_ApplyUICamera` with `C_TransmogCollection.GetAppearanceCameraID` where the client has them
   (`Model_ApplyUICamera` is in `Blizzard_SharedXML/Mainline/ModelFrames.lua`; Blizzard's Classic
   wardrobe does it so: `Blizzard_Collections/Classic/Blizzard_Wardrobe.lua`). Checked for before use.
6. **World objects,** a layout of their own, once Core's World pack knows objects.
7. **An NPC's services and a spell's source** as marks and grounds, once Core's packs have them.

## To check in the game

- Whether the tooltip of a thing in the world carries its ID: `/dump C_TooltipInfo.GetWorldCursor()` over
  a herb or a mailbox (`id`, or a `guid` *GameObject-...*). Without one, objects are known only by their
  words.
- Which subclass this client gives a potion, food or a scroll (`C_Item.GetItemInfoInstant`). If they are
  all *Generic*, they share the Consumable ground until Core's item data says more.
- Grounds at 512 x 256 beside 1024 x 512, on 4K and 1440p (`dev/tools/art-measure`, then in the game).
- Text on a ground at the lowest opacity (30 %).
- The socket over the live model: its corners covered at every UI scale.
- The frame rate with three or four model frames shown (`C_AddOnProfiler`, in the addon list).
- How long the first draw with a new ground takes.

## Open, for Saneroki

Claude's choices, written into *Types.md*; say if one should go another way:

1. A unit's rank on its socket (as the game's dragon), not a whole frame per rank.
2. The ground a band at the top, not under the whole panel.
3. Grounds of 512 x 256.
4. A player's side is a word on the race line; no picture behind the lines.
5. Mailbox and Holiday without a ground of their own.
