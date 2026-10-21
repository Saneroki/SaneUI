# Sane UI: Nameplates

**Status:** built: the game's plates in Sane UI's dress (a round-cornered health bar, combo points in your target's, the name, your debuffs and a foe's buffs, the rare's mark, the raid marker) · **Since:** 2026-10-20 · **Addon:** `SaneUI_Nameplates` · **Game:** WoW: Forever (interface 16001)

## TL;DR
Starts from the game's own nameplates and keeps what they do well: their size and style (the game's
nameplate settings), where they stand and stack, what clicks them, their cast bar, level box, threat glow and
widgets. Over the game's health bar it lays its own: a rectangle with round corners and a thin border, lit
white on your target and orange on your focus. Inside your target's bar, along its bottom, your combo points.
Above the bar the name; above the name your own debuffs (from the left) and up to three buffs of a foe (from
the right). Right of the bar the mark of a rare and the raid marker. When it fails, every plate is the game's
own again.

## How to use
- **Switch it on or off:** tick or untick *Nameplates* under *Sane UI* in the game's addon list (the game
  needs a restart when it was not in the list before).
- **Which plates:** every plate the game shows with a health bar: creatures and players, foes and friends.
  A plate the game shows by name only (a friendly player with the game's setting for that) or with widgets
  only stays the game's own; so do the plates the game keeps from addons in some places, and your own.
- **The bar:** round at its corners, a quarter of its height; health in the game's colours: a player's class
  colour where the game's nameplate settings colour by class, grey for a creature tapped by another player,
  else the game's colour for what the unit is to you (hostile, neutral, friendly).
- **Combo points:** as a rogue, or a druid in cat form, your combo points on your target show along the
  bottom of its bar, a third of its height, one segment each (five), lit as you build them. Only on a target
  you can attack.
- **Auras:** one row above the name, as many as fit over the bar (eight on the game's medium plates): from
  the left the debuffs you put on the unit, with the time each has left and its stacks; from the right up to
  three of its buffs, on units you can attack, as the game picks buffs for its own plates. Hover one for its
  tooltip, as on the game's plates.
- **Marks:** right of the bar, or of the game's level box beside it: the game's silver star on a rare, its
  silver dragon on a rare elite, then the raid marker (none on a player you could fight, as on the game's
  plates).
- **Settings:** *Sane UI > Nameplates*: *Your debuffs*, *Buffs on foes*, *Combo points in your target's bar*.
  The plates' size, style and which plates show are the game's own settings (*Options > Gameplay >
  Nameplates*).

## Technical details
- **Our dress** (`Plate.lua`): one frame of ours per plate the game hands out (`C_NamePlate.GetNamePlateForUnit`
  at `NAME_PLATE_UNIT_ADDED`; none for a forbidden plate or your own), a child of the plate (its place, scale and
  fading are ours too), `SetAllPoints` on the plate's `UnitFrame.HealthBarsContainer`, made once and kept: the
  game hands plates out again and takes its unit frames from a pool, so each add looks at the plate's unit frame
  anew (read with `rawget`, never written). While ours shows, the game's `HealthBarsContainer`, `name`,
  `AurasFrame`, `RaidTargetFrame` and `ClassificationFrame` are at alpha 0 (`Plate.HIDDEN`), and 1 again when
  the plate goes (`NAME_PLATE_UNIT_REMOVED`), when the game hides its health bar (hooks after its `OnShow` and
  `OnHide`, once per bar: name only, widgets only) and when the module stands down. Each dress registers its
  unit's events on itself (`RegisterUnitEvent`): `UNIT_HEALTH`, `UNIT_MAXHEALTH`, `UNIT_NAME_UPDATE`,
  `UNIT_FACTION`, `UNIT_FLAGS`, `UNIT_CLASSIFICATION_CHANGED`; `PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED`
  (the borders) and `RAID_TARGET_UPDATE` go over all of them. After a `/reload` the plates already shown are
  dressed at the login (`C_NamePlate.GetNamePlates`).
- **The bar** (`Bar.lua`): a border texture the size of the dress, and inside it, one pixel in (`Core.Pixels`),
  a `StatusBar` with the game's raid frames' fill (`Interface\RaidFrame\Raid-Bar-Hp-Fill`) and a dark background.
  Round by Core's caps (`Core.Shape.CAP_LEFT`, `CAP_RIGHT`, `assets/optimized/Core/Art/cap-*.blp`, made by
  `dev/tools/shape-art`): two mask textures per rectangle, at its ends, `Bar.CAP` (a quarter) of its height wide,
  `CLAMPTOWHITE`; the fill and the background share the inner pair, the border has its own. A cap is drawn for a
  bar's proportion, so the corners stay round at any size. Health goes to the bar as the game gives it
  (`UnitHealth`, `UnitHealthMax`, read through `pcall`, looked at with `type()` only: in a fight a secret value,
  which `SetMinMaxValues` and `SetValue` take). Colours as the game's plates choose them (`Bar.Colour`):
  `RAID_CLASS_COLORS` by `UnitClass` for players where the CVars `nameplateShowClassColor` (foes) or
  `nameplateShowFriendlyClassColor` (friends) say so, `Bar.TAPPED` for `UnitIsTapDenied`, else
  `UnitSelectionColor(unit, true)`. The border's colours for your target and focus are the game's
  (`NamePlateConstants.TARGET_BORDER_COLOR`, `FOCUS_TARGET_BORDER_COLOR`).
- **The name** (`Plate.lua`): the game's nameplate font (`SystemFont_NamePlate_Outlined`), white, centred over the
  bar's width, one line, `Plate.NAME_GAP` above it (the game's gap). A player's first name and surname
  (`Core.FullName`); anything else, or a name hidden in a fight, as `UnitName` gives it.
- **Auras** (`Auras.lua`): two of the game's aura containers per dress (`CreateFrame("AuraContainer", ...,
  "CustomAuraContainerTemplate")`, `Blizzard_AuraContainer`), anchored above the name: `own`, `HARMFUL|PLAYER`,
  from its `BOTTOMLEFT` growing right; `foes`, `HELPFUL|INCLUDE_NAME_PLATE_ONLY` (the filter of the game's own
  plates), at most `Auras.BUFFS`, from its `BOTTOMRIGHT` growing left; up a row each. The game assigns the auras,
  icons, times and stacks (hidden values and all); our code runs only when a container makes a frame (`Dress`,
  its `initializeFrame`, guarded): a `Auras.SIZE` square icon cut by the game's nameplate aura mask
  (`UI-HUD-CoolDownManager-Mask`), its border (`UI-HUD-CoolDownManager-IconOverlay`), a `CooldownFrameTemplate`
  with the game's swipe, the count in a frame above it, handed to the frame with `SetIcon`,
  `SetDurationCooldown`, `SetApplicationCount`. Your debuffs get the room the buffs leave
  (`Auras.Room`: `Auras.Slots` of the dress's width, less three), set with `SetAuraGroupMaxFrameCount`. A plate
  taken back sets its containers to `"none"`, disabled. Without the template the plates show no auras (noted once).
- **Marks** (`Marks.lua`): `UnitClassification` to the game's atlases for its plates (`Marks.ATLAS`), `Marks.RARE`
  square; the raid marker `Interface\TargetingFrame\UI-RaidTargetingIcons`, `Marks.RAID` square,
  `SetSpriteSheetCell(GetRaidTargetIndex(unit), 4, 4)` as the game does (the index may be secret: only its type is
  looked at). Right of the game's `PlayerLevelDiffFrame` while it shows, else of the bar.
- **Combo points** (`Resource.lua`): rogues and druids only listen (`UNIT_POWER_UPDATE` with `COMBO_POINTS`,
  `UNIT_MAXPOWER`, `UNIT_DISPLAYPOWER` of the player; `PLAYER_TARGET_CHANGED`, `COMBO_TARGET_CHANGED`; a plate
  coming or going), once a frame (`Core.Later`). Shown while the game gives combo points
  (`UnitPowerMax("player", Enum.PowerType.ComboPoints)`, at most `Resource.MOST`) and energy is the power shown, on
  the dress of `C_NamePlate.GetNamePlateForUnit("target")` while `UnitCanAttack` allows. One `StatusBar` from 0 to
  the most, its value `GetComboPoints("player", "target")` as the game gives it (secret or not), in the game's
  `PowerBarColor.COMBO_POINTS`; lines between the segments and along its top in the border's dark. Its fill and
  background take the bar's inner caps (masks of another frame, as the game's own bars do).
- **Standing down** (`ns.GiveBack`): the game's parts at alpha 1 on every unit frame ours ever lay over (the game
  hands them out again from its pool), then every dress off, each by itself; a dress taken off gives the game's
  parts back first, its bar as made, and only then lets its auras and strip go (each step by itself, so one that
  fails keeps no plate dressed). The hooks and events do nothing after it, until a `/reload`.
- Tests: `dev/tests/nameplates.lua`.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Nameplates.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Nameplates.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings, `GiveBack`, the start |
| `Bar.lua` | The health bar: round at both ends, in the game's colours, its border lit on your target and focus |
| `Auras.lua` | Your debuffs and a foe's buffs, in the game's own aura containers |
| `Marks.lua` | The mark on rares and the raid marker, right of the bar |
| `Resource.lua` | Your combo points along the bottom of your target's bar |
| `Plate.lua` | Our dress on each plate the game shows, laid over its health bar; the game's own bar, name, auras and marks out of sight under it |

## History
- **2026-10-20:** made a module of its own (Saneroki: nameplates are not Combat's): the game's plates with a
  round-cornered health bar, combo points inside your target's, the name, your debuffs and three buffs of a foe,
  the rare's mark and the raid marker.
