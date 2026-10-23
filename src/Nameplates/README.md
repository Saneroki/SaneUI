# Sane UI: Nameplates

**Status:** built: the game's plates in Sane UI's dress (a round-cornered health bar with level, threat, name and health inside it, the unit's power and your combo points along its bottom, a border by rank, a ring on your target and focus, a red glow on aggro, your debuffs above, a foe's buffs left and crowd control right, the raid marker; strangers' plates hidden; smaller far away) · **Since:** 2026-10-20 · **Addon:** `SaneUI_Nameplates` · **Game:** WoW: Forever (interface 16001)

## TL;DR
Starts from the game's own nameplates and keeps what they do well: their size and style (the game's
nameplate settings), where they stand and stack, what clicks them, their cast bar and widgets. Over the game's
health bar it lays its own: a rectangle with round corners, everything on one line inside it: at the left the
unit's level and your threat on it, in the middle its name, at the right its health and how much is left
("12 100%" · "Young Wolf" · "1.32m | 100%"). Along its bottom a thin line of the unit's mana, rage or energy,
and on your target your combo points on top of it. Its border tells the unit's rank, a ring around it your
target and focus, a red glow your aggro or a player who may attack you. Right above the bar your own debuffs,
left of it up to three of a foe's buffs, right of it the raid marker and the crowd control on the unit. Plates
of players you cannot attack and do not know are hidden; every plate is smaller the farther away it is. When it
fails, every plate is the game's own again.

## How to use
- **Switch it on or off:** tick or untick *Nameplates* under *Sane UI* in the game's addon list (the game
  needs a restart when it was not in the list before).
- **Which plates:** every plate the game shows with a health bar: creatures and players, foes and friends.
  A plate the game shows by name only (a friendly player with the game's setting for that) or with widgets
  only stays the game's own; so do the plates the game keeps from addons in some places, and your own.
- **Players:** the plate of a player you cannot attack shows only while the player is in your party or raid,
  your guild, on your friends list (or a friend of your account), or your target; the others' plates are out of
  sight altogether. Players you can attack always have theirs, glowing red: they may attack you.
- **The bar:** round at its corners, a quarter of its height. Health: a player's class colour; grey for a
  creature tapped by another player; light yellow for a creature that does not attack on sight; red for one
  that does; the game's colour for friends.
- **Inside the bar:** at the left the unit's level in the game's colour for how hard it is to you (a skull where
  it is too high to tell), next to it your threat on it while you are on its threat list: grey while low, orange
  when you are about to take its aggro, red while you have it, and then the whole bar glows red. In the middle
  its name (a player's first name and surname), cut short where it is too long. At the right its health,
  short (under a thousand as it is, then thousands to one place, "1.2k", then millions to two, "1.32m"; cut,
  not rounded), and "| 100%" how much is left. In a fight the game hides some of these from addons: the health
  is then shortened by the game in the same steps, the threat in grey.
- **The border:** black; gold and thick on a boss, gold and thin on an elite (the game's gold dragon), silver
  and thin on a rare (its silver dragon, also a rare elite). A white ring a pixel outside it on your target, an
  orange one on your focus (the game's colours for them).
- **The power line:** along the bottom of the bar, inside it, a fifth of its height: the unit's mana, rage or
  energy in the game's colours. None on a unit without power.
- **Combo points:** as a rogue, or a druid in cat form, your combo points on your target show right on top of
  its power line (along the bar's bottom where it has none), as high as the line, one segment each (five), lit
  as you build them. Only on a target you can attack.
- **Auras:** right above the bar, without a gap, from its left the debuffs and damage over time you put on the
  unit, with the time each has left and its stacks, as many as fit over the bar (eight on the game's medium
  plates). Left of the bar, growing away from it, up to three of its buffs on units you can attack, as the game
  picks buffs for its own plates. Right of the bar (after the raid marker) up to two crowd controls on it, by
  anyone; your own show there, not twice. Hover one for its tooltip, as on the game's plates.
- **Raid marker:** right of the bar (none on a player you could fight, as on the game's plates).
- **Smaller far away:** full size within ten yards, down to a little over half the size at the plates' farthest
  reach, by the game's own scaling (its CVars for it).
- **Settings:** *Sane UI > Nameplates*: *Your debuffs*, *Buffs on foes*, *Crowd control*, *Power line*,
  *Combo points in your target's bar*, *Only players you know*, *Smaller far away*. The plates' size, style and
  which plates show are the game's own settings (*Options > Gameplay > Nameplates*).

## Technical details
- **Our dress** (`Plate.lua`): one frame of ours per plate the game hands out (`C_NamePlate.GetNamePlateForUnit`
  at `NAME_PLATE_UNIT_ADDED`; none for a forbidden plate or your own), a child of the plate (its place, scale and
  fading are ours too), `SetAllPoints` on the plate's `UnitFrame.HealthBarsContainer`, made once and kept: the
  game hands plates out again and takes its unit frames from a pool, so each add looks at the plate's unit frame
  anew (read with `rawget`, never written). While ours shows, the game's parts in `Plate.HIDDEN` (its bar row,
  `name`, `AurasFrame`, `RaidTargetFrame`, `ClassificationFrame`, `LevelFrame`, `PlayerLevelDiffFrame`,
  `selectionHighlight`, `aggroHighlight*`) are at alpha 0, and 1 again when the plate goes
  (`NAME_PLATE_UNIT_REMOVED`), when the game hides its health bar (hooks after its `OnShow` and `OnHide`, once per
  bar: name only, widgets only) and when the module stands down. Each dress registers its unit's events on itself
  (`RegisterUnitEvent`): health, power, name, level, faction, flags, classification and its threat list;
  `PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED` (the rings, the strangers' plates), `RAID_TARGET_UPDATE`,
  `GROUP_ROSTER_UPDATE`, `FRIENDLIST_UPDATE`, `GUILD_ROSTER_UPDATE`, `BN_FRIEND_INFO_CHANGED` (the strangers'
  plates), `UNIT_THREAT_SITUATION_UPDATE`, `PLAYER_REGEN_ENABLED` and `PLAYER_LEVEL_UP` (threat and level colours)
  go over all of them, the last five once a frame (`Core.Later`). After a `/reload` the plates already shown are
  dressed at the login (`C_NamePlate.GetNamePlates`).
- **Strangers' plates** (`Plate.Wanted`): a player (`UnitIsPlayer`) you cannot attack (`UnitCanAttack` false),
  not your target (`UnitIsUnit`), not in your party, raid or guild (`UnitInParty`, `UnitInRaid`,
  `UnitIsInMyGuild`), not a friend (`C_FriendList.IsFriend`, `C_BattleNet.GetAccountInfoByGUID`) by `UnitGUID`:
  the game's unit frame on the plate at alpha 0, ours hidden; alpha 1 again with any change, when the plate goes
  and when the module stands down. Where the game does not answer (a hidden value), the plate shows. The plate
  still takes the game's clicks (its place is the game's).
- **The bar** (`Bar.lua`): from the back, three glow plates (`Bar.HALO`: 2, 4 and 7 screen pixels beyond the
  ring, `Bar.GLOW` at falling strengths), the ring (a pixel outside the border, shown on target and focus in the
  game's `NamePlateConstants.TARGET_BORDER_COLOR` and `FOCUS_TARGET_BORDER_COLOR`), the border (the dress's
  size, `Bar.RANKS` by `UnitIsBossMob` and `UnitClassification`: boss 3 pixels in the game's `NORMAL_FONT_COLOR`,
  elite 1 pixel in it, rare and rare elite 1 pixel silver; `Bar.PLAIN` black, 1), then inside the border a
  `StatusBar` with the game's raid frames' fill (`Interface\RaidFrame\Raid-Bar-Hp-Fill`) and a dark background.
  Round by Core's caps (`Core.Shape.CAP_LEFT`, `CAP_RIGHT`, `assets/optimized/Core/Art/cap-*.blp`, made by
  `dev/tools/shape-art`): two mask textures per rectangle, at its ends, `Bar.CAP` (a quarter) of its height wide,
  `CLAMPTOWHITE`; the fill, the background, the power line and the combo points share the inner pair, every plate
  around it has its own. A cap is drawn for a bar's proportion, so the corners stay round at any size. Health
  goes to the bar as the game gives it (`UnitHealth`, `UnitHealthMax`, read through `pcall`, looked at with
  `type()` only: in a fight a secret value, which `SetMinMaxValues` and `SetValue` take). Colours
  (`Bar.Colour`): `RAID_CLASS_COLORS` by `UnitClass` for players, `Bar.TAPPED` for `UnitIsTapDenied`,
  `Bar.CALM` for `UnitReaction` 4, `Bar.HOSTILE` below it, else `UnitSelectionColor(unit, true)`. The glow is on
  while `Bar.Danger` (a player who `UnitCanAttack` you) or while you have the unit's aggro (`Bar.Glow`, from
  `Text.Threat`): a plain answer by `SetAlpha`, a hidden one by `SetAlphaFromBoolean`.
- **The power line** (`Bar.Power`): a `StatusBar` inside the bar along its bottom, `Bar.LINE` (a fifth) of the
  bar's height (two pixels at least), from 0 to `UnitPowerMax`, at `UnitPower` (both as the game gives them), in
  the game's `PowerBarColor` for `UnitPowerType`'s token; hidden where the most is a plain 0 or the setting is
  off. Its coming or going moves the combo points (`Resource.Again`).
- **The texts** (`Text.lua`): on a frame above the bar's (its level three above the bar's), the game's nameplate
  font (`SystemFont_NamePlate_Outlined`), one line each: the level at `LEFT` (`Text.INSET` in), the threat right of
  it (`Text.GAP`), the name at `CENTER` (white, `Text.NAME` of the bar's width, cut short beyond it), the health
  at `RIGHT`. Level: `UnitLevel`, coloured by the game's `GetRelativeDifficultyColor` against yours on a unit you
  can attack, `UNIT_LEVEL_NON_ATTACKABLE` otherwise, the game's skull (`Text.SKULL`) for a level below 1.
  Threat: `UnitDetailedThreatSituation("player", unit)`: nothing without a status; the scaled percentage as
  `%d%%` (`SetFormattedText`, hidden or not); its colour by the status (`Text.THREAT`: 0 grey, 1 orange, 2 and 3
  red), grey where the status is hidden; aggro from `Text.AGGRO` (2) up, or the hidden `isTanking` as it is. Name:
  `Core.FullName` for players, else `UnitName` as it is. Health: plain, `Text.Short` and `Text.Percent` ("1.32m |
  100%"); hidden, `AbbreviateNumbers` with `Text.STEPS` as its breakpoints (the game's own form where it takes
  none) and `UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)`, both into `SetFormattedText`.
- **Auras** (`Auras.lua`): three of the game's aura containers per dress (`CreateFrame("AuraContainer", ...,
  "CustomAuraContainerTemplate")`, `Blizzard_AuraContainer`): `own`, `Auras.OWN` (`HARMFUL|PLAYER|!CROWD_CONTROL`),
  its `BOTTOMLEFT` on the dress's `TOPLEFT`, growing right, as many as `Auras.Slots` of the dress's width; `foes`,
  `HELPFUL|INCLUDE_NAME_PLATE_ONLY` (the filter of the game's own plates), at most `Auras.BUFFS`, its
  `BOTTOMRIGHT` left of the dress's `BOTTOMLEFT`, growing left; `control`, `Auras.CC` (`HARMFUL|CROWD_CONTROL`), at
  most `Auras.CONTROL`, its `BOTTOMLEFT` right of the raid marker while it shows, else of the dress
  (`Auras.Place`), growing right; up a row each. The game assigns the auras, icons, times and stacks (hidden values
  and all); our code runs only when a container makes a frame (`Dress`, its `initializeFrame`, guarded): a
  `Auras.SIZE` square icon cut by the game's nameplate aura mask (`UI-HUD-CoolDownManager-Mask`), its border
  (`UI-HUD-CoolDownManager-IconOverlay`), a `CooldownFrameTemplate` with the game's swipe, the count in a frame
  above it, handed to the frame with `SetIcon`, `SetDurationCooldown`, `SetApplicationCount`. A plate taken back
  sets its containers to `"none"`, disabled. Without the template the plates show no auras (noted once).
- **Marks** (`Marks.lua`): the raid marker `Interface\TargetingFrame\UI-RaidTargetingIcons`, `Marks.RAID` square,
  right of the bar, `SetSpriteSheetCell(GetRaidTargetIndex(unit), 4, 4)` as the game does (the index may be secret:
  only its type is looked at); each change places the crowd control anew.
- **Combo points** (`Resource.lua`): rogues and druids only listen (`UNIT_POWER_UPDATE` with `COMBO_POINTS`,
  `UNIT_MAXPOWER`, `UNIT_DISPLAYPOWER` of the player; `PLAYER_TARGET_CHANGED`, `COMBO_TARGET_CHANGED`; a plate
  coming or going, a power line coming or going), once a frame (`Core.Later`). Shown while the game gives combo
  points (`UnitPowerMax("player", Enum.PowerType.ComboPoints)`, at most `Resource.MOST`) and energy is the power
  shown, on the dress of `C_NamePlate.GetNamePlateForUnit("target")` while `UnitCanAttack` allows. One `StatusBar`
  from 0 to the most, its value `GetComboPoints("player", "target")` as the game gives it (secret or not), in the
  game's `PowerBarColor.COMBO_POINTS`, as high as the power line and on its top (`Resource.Fit`, at every update),
  else along the bar's bottom; lines between the segments and along its top in the border's dark.
- **Scale** (`Scale.lua`): the game's CVars `nameplateMaxScale`, `nameplateMinScale`, `nameplateMaxScaleDistance`
  and `nameplateMinScaleDistance` set to `Scale.CVARS` while *Smaller far away* is on, to their defaults
  (`C_CVar.GetCVarInfo`) when it is off or the module stands down; through `C_CVar.SetCVar`, only those this
  client has, never in a fight (then at `PLAYER_REGEN_ENABLED`).
- **Standing down** (`ns.GiveBack`): the game's scaling back, the game's unit frames at alpha 1 and their parts
  too on every unit frame ours ever lay over (the game hands them out again from its pool), then every dress off,
  each by itself; a dress taken off gives the game's parts back first, its bar as made and its texts empty, and
  only then lets its auras and strip go (each step by itself, so one that fails keeps no plate dressed). The hooks
  and events do nothing after it, until a `/reload`.
- Tests: `dev/tests/nameplates.lua`.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Nameplates.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Nameplates.lua` | The module's own table (`ns`), registered with Core (`Core.NewModule`); its words (`ns.TEXT`), its settings, `GiveBack`, the start |
| `Bar.lua` | The health bar: round at both ends, its border by rank, a ring on your target and focus, the power line, the glow |
| `Text.lua` | Inside the bar: level and threat, the name, health |
| `Auras.lua` | Your debuffs above the bar, a foe's buffs left of it, crowd control right of it, in the game's own aura containers |
| `Marks.lua` | The raid marker, right of the bar |
| `Resource.lua` | Your combo points on the power line of your target's bar |
| `Scale.lua` | Plates smaller far away (the game's CVars for it) |
| `Plate.lua` | Our dress on each plate the game shows, laid over its health bar; the game's own bar, name, auras and marks out of sight under it; strangers' plates hidden |

## Not there yet
The raid marker in our own style in place of the game's (Saneroki, 2026-10-21; `Doc/guides/interface-style.md`,
*To redesign*).

## History
- **2026-10-20:** made a module of its own (Saneroki: nameplates are not Combat's): the game's plates with a
  round-cornered health bar, combo points inside your target's, the name, your debuffs and three buffs of a foe,
  the rare's mark and the raid marker.
- **2026-10-23:** everything inside the bar (Saneroki): level and threat at the left, the name in the middle,
  health and its percent at the right; the unit's power as a line along its bottom, the combo points on it; the
  border by rank (gold and thick on bosses, gold on elites, silver on rares) in place of the rare's mark, a ring
  on target and focus, a red glow on aggro and on players who may attack you; the game's level box gone; your
  debuffs right on the bar, a foe's buffs left, crowd control right; strangers' plates hidden; plates smaller
  far away.
- **2026-10-23:** health in thousands to one place and millions to two ("1.2k", "1.32m", Saneroki); the glow no
  longer compares the game's hidden answer about aggro (the module stood down in a fight).
