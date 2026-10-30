# Sane UI: Nameplates

**Status:** built: the game's plates in Sane UI's dress (a round-cornered health bar with level, threat, name and health inside it, the unit's power along its bottom, your combo points in a row under the bar of the unit holding them, one border lit on your target and focus, a line behind it by rank, a red glow on aggro, your debuffs above, a foe's buffs left and crowd control right, the raid marker; strangers' and critters' plates hidden; smaller far away; combat text rising over them and over your character) · **Since:** 2026-10-20 · **Addon:** `SaneUI_Nameplates` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Starts from the game's own nameplates and keeps what they do well: their size and style (the game's
nameplate settings), where they stand and stack, what clicks them, their cast bar and widgets. Over the game's
health bar it lays its own: a rectangle with round corners, everything on one line inside it, each piece only
while it shows: your quest objective on the unit (a sword or a sack, "0/7"), its level, its raid marker, a
player's item level ("i32"), your threat on it, its name, its health and how much is left ("1.32m | 100%"). The
bar is as wide as that line, no wider. Along its bottom a thin line of the unit's mana, rage or energy,
and your combo points in a row of their own under the bar of the unit you have them on, inside the same outline. Its one border is lit on your target and focus, a line
behind it tells the unit's rank, a red glow behind that your aggro or a player who may attack you. Right above the bar your own debuffs,
left of it up to three of a foe's buffs, right of it the crowd control on the unit. Plates
of players who may not attack you nor you them and whom you do not know are hidden, and critters' plates (a setting shows them); every plate is smaller the farther away it is. When it
fails, every plate is the game's own again.

## How to use
- **Switch it on or off:** tick or untick *Nameplates* under *Sane UI* in the game's addon list (the game
  needs a restart when it was not in the list before).
- **Which plates:** every plate the game shows with a health bar: creatures and players, foes and friends.
  A plate the game shows with widgets only stays the game's own; so do the plates the game keeps from addons in
  some places, and your own. Friendly players are never shown by name only while the module is on (the game's
  setting *Show only names for friendly players* is off meanwhile and back as it was when the module is off).
- **Players:** dressed exactly like the creatures: the bar, the power line, the line inside it, auras, cast bar. A
  player's plate shows while a fight with the player can start (the player may attack you, or you the player), and
  while the player is in your party or raid, your guild, on your friends list (or a friend of your account), or your
  target; every other player's plate is out of sight altogether. Players who may attack you glow red. Whether
  friendly players have plates at all is the game's own setting (*Friendly player nameplates*, its key).
- **Critters:** critters, wild pets and companion pets (rabbits, rats, deer, someone's pet) have no plate, and so no
  name over them, unless one is your target or a quest of yours wants it (its plate then shows the count). Setting
  *Plates on critters* (off at first) gives them their plates.
- **The bar:** round at its corners, a quarter of its height. Health: a player's class colour; grey for a
  creature tapped by another player; light yellow for a creature that does not attack on sight; red for one
  that does; the game's colour for friends.
- **Inside the bar:** one line, left to right, each piece taking room only while it shows, and the bar as wide
  as the line and a little inset, no wider. Each text has a little room to spare: the game draws small letters a
  little wider or narrower than large ones, so as a plate grows or shrinks its texts are measured again at the size
  it shows at, and the bar widens only once a text outgrows its spare (a name is never cut short by it):
  - *quest:* while the unit belongs to a quest in your log with an objective still open, the game's sword (to
    kill it) or sack (to loot it) outside the bar, left of it, and the count ("0/7") first in the line;
  - *level* in the game's colour for how hard it is to you (a skull where it is too high to tell), the name right
    after it;
  - *raid marker* right after the level, as on Sane UI's unit frames, a little apart from it and from what follows;
  - *item level* of a player ("i32"), once the game let Sane UI inspect them (out of a fight, near enough);
  - *threat* while you are on its threat list: grey while low, orange when you are about to take its aggro, red
    while you have it, and then the whole bar glows red;
  - *name* (a player's first name and surname): a long name makes the bar longer (cut short only past 400);
  - *health*,
  short (under a thousand as it is, then thousands to one place, "1.2k", then millions to two, "1.32m"; cut,
  not rounded), and "| 100%" how much is left. In a fight the game hides some of these from addons: the health
  is then shortened by the game in the same steps, the threat red while you have aggro and grey otherwise (orange
  cannot be told then). The health takes the room of the most it
  can show, so the bar does not change width as health goes down.
- **The border:** one thin outline: black, a quiet 50% grey on your target, orange on your focus (the game's
  colour for it); on a player you know, by how: green your guild, blue your party (in a raid, your own subgroup),
  purple the rest of your raid, pink a friend (where more than one holds, in that order: a guild member in your raid
  is green; your target's grey and your focus's orange over them); a soft red, half transparent, on any foe none of your attacks reach, as the game checks your own spells from your character (a
  warrior's strikes, Charge, and Shoot only with a bow; a mage's bolts). Behind it, from the same edge but reaching
  farther, a line for the unit's rank: gold and thick on a boss, gold and thin on an elite (the game's gold
  dragon), silver and thin on a rare (its silver dragon, also a rare elite); and behind that, the red glow.
- **The power line:** along the bottom of the bar, inside it, a third of its height: the unit's mana, rage or
  energy in the game's colours, without a background: spent power shows nothing, the bar is seen through it.
  None on a unit without power.
- **Combo points:** as a rogue, or a druid in cat form, your combo points show in a row of their own right under
  the bar of the unit you have them on (your target or not), a third as high, inside the same outline (a cast's bar comes under them), one segment
  each (five), a pixel apart, lit as you build them; a point not built shows the bar's dark. No row while you
  have none. Where the game hides the count, on your target's plate only. In Retail the points are your
  character's, whatever you target: they show on your target's plate alone, one segment each up to seven.
- **Auras:** right above the bar, without a gap, from its left the debuffs and damage over time you put on the
  unit, with the time each has left and its stacks, as many as fit over the bar (eight on the game's medium
  plates). Left of the bar, growing away from it, up to three of its buffs on units you can attack, as the game
  picks buffs for its own plates. Right of the bar up to two crowd controls on it, by
  anyone; your own show there, not twice. Hover one for its tooltip, as on the game's plates.
- **Cast bar:** under the bar, inside the plate's one outline (the border, the rank's line and the glow go around the
  bar and the cast bar together while a cast shows, around the bar alone otherwise), as wide and as high as the bar,
  in the game's own cast bar art: the spell's icon at its left end with the
  seconds left inside it, then the spell's name and its target's on one line, cut where the bar ends (the start
  always shows); filling as a cast goes on, emptying as a channel does. Its art says whether it can be interrupted:
  the game's golden fill (a channel its channel fill), its grey where it cannot. Interrupted, it is full and red and says *Interrupted*, with who did it
  where the game names them. Done or interrupted, it stays half a second; failed, it goes at once. It shows every
  cast, also those the game hides from addons in a fight: the game then draws its progress, and the seconds come from
  the spell's cast time (none for a channel). Setting *Cast bar* (off: the game's own).
- **Raid marker:** in the line right after the level, as on Sane UI's unit frames (none on a player you could
  fight, as on the game's plates).
- **Size by distance:** your target's plate is always *Nameplate size* (125% at first). Any other's depends on how
  far its unit is from your character and on nothing else (rank, the camera): full within 10 yards, gradually down to
  half at 40 yards, then to a quarter at 60, the farthest the game shows plates of units you have not targeted. It
  shrinks and grows quickly and smoothly, eased: fast at first, slower as it arrives, never past its size, there in
  about a quarter of a second; selected or let go, quicker still. The game tells addons only between which range
  checks a unit stands (5, 8, 10, 15 yards and so on); between two of them the distance moves on every frame at the
  pace its unit passed the last two (a run's before that is known), never past the next, so a plate follows a moving
  unit all the way, not in a step at each. A plate appears at the size of its distance, never larger, and fades in
  from unseen in a straight line, in about 0.7 seconds: as long as running takes from 60 yards, where the game first
  shows plates, to 55 (the game tells addons no distance that far, so the fade is timed). A plate going out of sight
  at 60 yards is taken by the game at once. No other transparency of ours. The game's
  own scaling (by the camera) and fading are off meanwhile (fading behind walls stays the game's).
- **Combat text:** what a creature or player with a plate takes rises over its bar and fades, in Sane UI's own font
  (Kalam Bold, outlined): auto attacks and physical damage in white, spell damage in red, a critical hit larger with a short
  swell, a glancing blow smaller, heals in green with a "+". What did no harm is the game's word in white ("Miss", "Parry",
  ...); with *Drawings for what did no harm* on (off by default) a miss, dodge, parry, block, evade or immunity is a
  pencil drawing instead, in white (an arrow flying over a target; a fighter bending far back
  under an arrow; crossed swords with sparks; a shield with an arrow breaking on it; a fighter in a wide stance, his
  head swung aside from an arrow flying up past it) and an immunity in bright red (a bubble with an "i"); a resist, absorb, reflect or interrupt stays the word. Hits at once stand
  side by side. The game says what a unit took, not from whom, so in a group it is everybody's damage on it.
- **Over your character:** the same for what you take, rising from about your character's feet, below the middle of
  the screen, where your character stands (your character has no plate in this client): damage with a "-". While ours shows, the
  game's own combat text is off (*Instead of the game's*): its numbers over units and its scrolling text about you,
  with that text's notes on entering a fight, low health, reputation and honor. The game's XP numbers over a kill are
  its own and stay. Only the game's settings the client has are switched (`C_CVar.GetCVarInfo`): where Retail's
  client lacks those for its numbers over units, those numbers stay as the game has them.
- **Settings:** *Sane UI > Nameplates*: *Quest progress*, *Item level*, *Your debuffs*, *Buffs on foes*, *Crowd control*, *Power line*,
  *Combo points under the bar*, *Out of reach: red border*, *Only players you know*, *Plates on critters*, *Size by distance*, *Nameplate size*; the section *Combat text* (*Over nameplates*, *Over your character*, *Heals*,
  *Drawings for what did no harm*, *Instead of the game's*). The plates' size, style and
  which plates show are the game's own settings (*Options > Gameplay > Nameplates*).

- **Barriers, lost health, dispels:** a barrier in the game's shield art on the bar, after the health or pushed against its right end;
  maximum health lost for a while: the fill ends earlier and the rest is hatched; what you or your group can take off a friend, or a buff
  you can remove from a foe: a ring around the plate in its kind's colour and the aura's icon above the bar's right end. Switches
  *Barriers*, *Lost maximum health*, *Dispellable auras*. The module's own part is small: `dress.marks` in `Bar.lua`, `Plate.lua`'s events.

## Technical details
- **Our dress** (`Plate.lua`): one frame of ours per plate the game hands out (`C_NamePlate.GetNamePlateForUnit`
  at `NAME_PLATE_UNIT_ADDED`; none for a forbidden plate or your own), a child of the plate (its place, scale and
  fading are ours too), centred on the plate's `UnitFrame.HealthBarsContainer`, made once and kept: the game hands
  plates out again and takes its unit frames from a pool, so each add looks at the plate's unit frame anew (read
  with `rawget`, never written); its size set by `Scale.lua`; as high as its line needs (`Text.Height`: the font's height, `Text.PAD` over and
  under, a pixel of border each) and as wide as the line wants (`Plate.Place`, at every fit and line change; the
  row's width, read in the dress's units, until the line is laid out). While ours shows, the game's parts in `Plate.HIDDEN` (its bar row,
  `name`, `AurasFrame`, `RaidTargetFrame`, `ClassificationFrame`, `LevelFrame`, `PlayerLevelDiffFrame`,
  `selectionHighlight`, `aggroHighlight*`) are at alpha 0, and 1 again when the plate goes
  (`NAME_PLATE_UNIT_REMOVED`), when the game hides its health bar (hooks after its `OnShow` and `OnHide`, once per
  bar: name only, widgets only) and when the module stands down. Each dress registers its unit's events on itself
  (`RegisterUnitEvent`): health, power, name, level, faction, flags, classification and its threat list;
  `PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED` (the borders, the strangers' plates), `RAID_TARGET_UPDATE`,
  `GROUP_ROSTER_UPDATE`, `FRIENDLIST_UPDATE`, `GUILD_ROSTER_UPDATE`, `BN_FRIEND_INFO_CHANGED` (the strangers'
  plates), `UNIT_THREAT_SITUATION_UPDATE`, `PLAYER_REGEN_ENABLED` and `PLAYER_LEVEL_UP` (threat and level colours)
  go over all of them, the last five once a frame (`Core.Later`). After a `/reload` the plates already shown are
  dressed at the login (`C_NamePlate.GetNamePlates`).
- **Players you know** (`Plate.Kin`, found anew at each `Wear` and kept as `dress.kin`), the closest first:
  `"guild"` (`UnitIsInMyGuild`), `"party"` (in a raid, `UnitInRaid` gives its index and `GetRaidRosterInfo` its
  subgroup: yours is your party; else `UnitInParty`), `"raid"`, `"friend"` (`C_FriendList.IsFriend`,
  `C_BattleNet.GetAccountInfoByGUID` by `UnitGUID`). The border takes its colour (`Bar.KIN`) under your target's
  and focus's (`Lit`), and is lit anew where it changed (`Plate.Light`).
- **Strangers' plates** (`Plate.Wanted`): a player (`UnitIsPlayer`) you cannot attack nor it you (`UnitCanAttack`
  false both ways), not your target (`UnitIsUnit`), none you know (`Plate.Kin` nil):
  the game's unit frame on the plate at alpha 0, ours hidden; alpha 1 again with any change, when the plate goes
  and when the module stands down. Where the game does not answer (a hidden value), the plate shows. The plate
  still takes the game's clicks (its place is the game's).
- **Critters' plates** (`Plate.Wanted`, setting `critters` off): a unit that is no player whose creature type
  (`UnitCreatureType`'s ID, not its word) is in `Plate.CRITTERS` (8 Critter, 12 Non-combat Pet, 14 Wild Pet: the
  client's CreatureType table, the same in both games), not your target, without a quest piece on its dress
  (`dress.room.quest`): out of sight as a stranger's, the game's name on it with it. `QUEST_LOG_UPDATE` and
  `UNIT_QUEST_LOG_CHANGED` look at every plate anew. A hidden type shows the plate. A dress that comes back in sight
  (a stranger or critter targeted, a health bar shown again) is filled anew (`dress.away`): texts hidden while they
  were filled may not have measured.
- **The bar** (`Bar.lua`): each layer on a frame of its own one level above the last (the glow, the outline, the
  bar; the line of texts three above the bar), so the glow never covers the outline. From the back, `Bar.HALO` (6) glow plates in `Bar.GLOW` on a frame of their own a level
  under the dress (`dress.glow`, whose alpha alone switches the glow: a texture's own alpha would replace its vertex
  alpha), reaching 1 to 6 screen pixels beyond the rank's line, each as strong (`Bar.Strength`) as its band needs so
  that together they are solid at the bar's edge and fade to nothing outwards (`Bar.Fade`: one minus the band's
  share, squared); the rank's line (`dress.rankLine`, `Bar.RANKS` by `UnitIsBossMob` and `UnitClassification`: from
  the dress's edge, boss 4 pixels in the game's `NORMAL_FONT_COLOR`, elite 2 in it, rare and rare elite 2 silver;
  none for `Bar.PLAIN`); the border, one pixel (the dress's size), `Bar.BORDER` black,
  `Bar.TARGET` (a quiet 50% grey) on your target, the game's `NamePlateConstants.FOCUS_TARGET_BORDER_COLOR` on your focus (`Bar.Border`); then inside the border a
  `StatusBar` with the game's raid frames' fill (`Interface\RaidFrame\Raid-Bar-Hp-Fill`) and a dark background.
  Round by Core's caps (`Core.Shape.CAP_LEFT`, `CAP_RIGHT`, `assets/optimized/Core/Art/cap-*.blp`, made by
  `dev/tools/shape-art`): two mask textures per rectangle, at its ends, `Bar.CAP` (a quarter) of its height wide,
  `CLAMPTOWHITE`; the fill, the background, and the power line share the inner pair, every plate
  around it has its own. A cap is drawn for a bar's proportion, so the corners stay round at any size. Health
  goes to the bar as the game gives it (`UnitHealth`, `UnitHealthMax`, read through `pcall`, looked at with
  `type()` only: in a fight a secret value, which `SetMinMaxValues` and `SetValue` take). Colours
  (`Bar.Colour`): `RAID_CLASS_COLORS` by `UnitClass` for players, `Bar.TAPPED` for `UnitIsTapDenied`,
  `Bar.CALM` for `UnitReaction` 4, `Bar.HOSTILE` below it, else `UnitSelectionColor(unit, true)`. The glow is on
  while `Bar.Danger` (a player who `UnitCanAttack` you) or while you have the unit's aggro (`Bar.Glow`, from
  `Text.Threat`): a plain answer by `SetAlpha`, a hidden one by `SetAlphaFromBoolean`.
- **The power line** (`Bar.Power`): a `StatusBar` inside the bar along its bottom, `Bar.LINE` (a third) of the
  bar's height (two pixels at least), from 0 to `UnitPowerMax`, at `UnitPower` (both as the game gives them), in
  the game's `PowerBarColor` for `UnitPowerType`'s token; hidden where the most is a plain 0 or the setting is
  off; no background.
- **The line** (`Text.lua`): on a frame above the bar's (its level three above the bar's), in the game's nameplate
  font's face and outline (`SystemFont_NamePlate_Outlined`'s `GetFont`), `Text.SMALLER` (0.72) of its height, set on
  every text of ours once (`SetFont`), so later changes of the game's font object change none. Each piece has its room (`dress.room[piece]`, none while it does not
  show); `Text.Layout` places the pieces from `Text.INSET` (3) in, `Text.GAP` apart (`Gap`: `Text.BESIDE` (2) either
  side of the raid marker, `Text.NEAR` (0) between the level and the name), each at `LEFT` of the frame at its
  x; the quest's icon (`OUTSIDE`) right of the frame's left, `Text.OUTSIDE` (4) apart from
  it, its width kept as `dress.outside` for the foe's buffs (`Auras.Place`), and wants the bar as wide as the line and its insets
  (`dress.want`, `Plate.Place`). A plain text's room is its own whole width (`GetUnboundedStringWidth`: not as cut
  by the width it was given), rounded up, and `Text.SLACK` (1) more; every text's room (not the icons') then
  `Text.SPARE` (6%) of that more, kept while the text fits in it with at most twice that left over (`Text.Spare`), so
  a small change of a width changes nothing. As a plate grows or shrinks (`Scale.Step`), once its size moved on by
  `Scale.TEXT` (4%) since and when it settles, the texts measured on themselves (count, level, item level, name) are
  measured again at that size, after the plate took it (`Text.Refit`; not while the dress is out of sight, nor a text
  that answers hidden): the line is laid out anew only where one outgrew its spare or left too much of it. A text that answers hidden (a font string once
  given a hidden value may ever after), the health's most and the threat's "100%" are measured on a ruler of ours
  (`Text.Width`: a font string at alpha 0, never given a hidden value, on a frame of its own on `UIParent`, always
  shown, since a hidden one may not measure what it is given). A width the game gives as none, endless or beyond
  `Text.WIDEST` (just after a `/reload`, its fonts and scales not set up yet) counts as none: the ruler's guess is then
  `Text.GUESS` of the font's height a letter; `Plate.Place` gives a bar wider than `Plate.WIDEST` `Plate.PLAIN`; and
  half a second after `PLAYER_ENTERING_WORLD` every plate is filled and measured anew (`Plate.Refresh`). A plate is shown before it is filled, so its own
  texts are measured while they show. Icons are `Text.ICON` (1.2) times the font's
  height (`Text.size`). Several pieces set at once lay out once (`dress.holding`). The pieces:
  - *quest*: `Core.UnitQuest(unit)` (`src/Core/Objectives.lua`), not for players: the icon `Text.QUEST` (the game's
    cursors `Attack` and `LootAll`) outside, the count inside; kept as it was while the game hides it; again on
    `QUEST_LOG_UPDATE` and `UNIT_QUEST_LOG_CHANGED`, once a frame.
  - *level*: `UnitLevel`, coloured by the game's `GetRelativeDifficultyColor` against yours on a unit you can
    attack, `UNIT_LEVEL_NON_ATTACKABLE` otherwise, the game's skull (`Text.SKULL`) for a level below 1.
  - *gear*: `Core.Inspect.Level(unit, UnitGUID(unit))` for players, "i" and the level in `Text.GEAR`. Asked for when
    the plate comes and, while a shown player has none, again `Core.Inspect.GAP` and a quarter seconds later (Core
    paces the questions) and at a fight's end; an answer (`Core.Inspect.Watch`) fills that player's plate.
  - *threat*: `UnitDetailedThreatSituation("player", unit)`: nothing without a status; the scaled percentage as
    `%d%%` (`SetFormattedText`, hidden or not) in the room of "100%"; its colour by the status (`Text.THREAT`: 0
    grey, 1 orange, 2 and 3 red); where the status is hidden (a fight), red or grey by the hidden `isTanking`
    (`Text.Aggro`: the game's `C_CurveUtil.EvaluateColorFromBoolean` turns it into a colour the text takes as it is); aggro from `Text.AGGRO` (2) up, or the hidden
    `isTanking` as it is.
  - *name*: `Core.FullName` for players, else `UnitName` as it is; its room the plain name's (at most `Text.MOST`),
    a hidden one the last plain one's (`Text.NAME` before any).
  - *health*: the game hides a plate's unit's health from addons always (its most often): plain, `Text.Short` and
    `Text.Percent` ("1.32m | 100%"); hidden, `AbbreviateNumbers` with
    `Text.STEPS` as its breakpoints (the game's own form where it takes none) and `UnitHealthPercent(unit, true,
    CurveConstants.ScaleTo100)`, both into `SetFormattedText`. Its room that of the most health in that form
    on the ruler (kept while the most is hidden), else of `Text.Guess`: about `Text.PER_LEVEL` (60) a level, a
    player's `Text.PLAYER` (100), three times for an elite or rare, a boss's in millions, every digit an 8 and the
    places a real one may have ("8.8k", "8.88m"). The health text is as wide as it is (`SetWidth(0)`), never cut short.
- **Auras** (`Auras.lua`): three of the game's aura containers per dress (`CreateFrame("AuraContainer", ...,
  "CustomAuraContainerTemplate")`, `Blizzard_AuraContainer`): `own`, `Auras.OWN` (`HARMFUL|PLAYER|!CROWD_CONTROL`),
  its `BOTTOMLEFT` on the dress's `TOPLEFT`, growing right, as many as `Auras.Slots` of the dress's width; `foes`,
  `HELPFUL|INCLUDE_NAME_PLATE_ONLY` (the filter of the game's own plates), at most `Auras.BUFFS`, its
  `BOTTOMRIGHT` left of the dress's `BOTTOMLEFT` past the icons outside it (`dress.outside`), growing left; `control`, `Auras.CC` (`HARMFUL|CROWD_CONTROL`), at
  most `Auras.CONTROL`, its `BOTTOMLEFT` right of the dress (`Auras.Place`), growing right; up a row each. The game assigns the auras, icons, times and stacks (hidden values
  and all); our code runs only when a container makes a frame (`Dress`, its `initializeFrame`, guarded): a
  `Auras.SIZE` square icon cut by the game's nameplate aura mask (`UI-HUD-CoolDownManager-Mask`), its border
  (`UI-HUD-CoolDownManager-IconOverlay`), a `CooldownFrameTemplate` with the game's swipe, the count in a frame
  above it, handed to the frame with `SetIcon`, `SetDurationCooldown`, `SetApplicationCount`. A plate taken back
  sets its containers to `"none"`, disabled. Without the template the plates show no auras (noted once).
- **Marks** (`Marks.lua`): the raid marker `Interface\TargetingFrame\UI-RaidTargetingIcons`, in the line after the
  level (`Text.size` square, its room in the line, placed by `Text.Layout`), `SetSpriteSheetCell(GetRaidTargetIndex(unit), 4, 4)` as the game does (the index may be
  secret: only its type is looked at).
- **Range** (`Range.lua`): the game tells addons no distance, but whether a unit is within reach of an item's use
  (`C_Item.IsItemInRange`) or of one of your spells (`C_Spell.IsSpellInRange`), from your character. Each unit is
  asked against a ladder, the shortest reach first: items of the game whose use reaches a foe (`Range.ENEMY`: 5 to 40
  yards) or a friend (`Range.FRIEND`: 5 to 50), picked from the game's own tables (item effects, their spells' ranges
  and targets; loaded with `C_Item.RequestLoadItemDataByID`), and your spells with a range (`C_SpellBook`, not
  passive, not off-spec; `C_Spell.SpellHasRange`, `GetSpellInfo`'s `maxRange`; harmful ones for foes, helpful for
  friends; none with a least range), made anew at `SPELLS_CHANGED`. The first rung that reaches the unit bounds the
  distance from above, the last that did not from below (`Range.Check`; none reaches: up to `Range.FAR`, 60). The
  distance kept (`Range.Follow`) is in the middle the first time; where the unit went on to the next two rungs, at the
  rung it passed (the one distance the ladder knows for sure), with its pace (`dress.pace`): the two rungs passed last
  over the time between (`dress.mark`, `dress.markAt`; not older than `Range.STALE`, 3 s), else `Range.RUN` (7 yards a
  second) that way; none beyond `Range.FASTEST` (40) or where the rungs are no neighbours of the last (a jump, or the
  ladder changed: then `Range.Settle` within them). Every frame `Range.Drift` (from Scale.lua's driver) moves it on at
  that pace, never past the two rungs it stands between: there it waits, its pace spent, for the unit to pass. Each
  look asks first the two rungs the unit stood between (`Still`, by `dress.rung`: two questions while it stays), else
  up the ladder from the shortest.
  Where nothing answers (an item the game will not check), the last distance stays. While the game restricts
  addons (`Core.Restricted`: a fight, an encounter, a keystone, a PvP match, a map) no item is asked about any unit,
  foe or friend: the game forbids that to addons then (each question a blocked action), so distances there come from
  your spells alone. Out of reach (`dress.out`): a foe one of your harmful spells without a least range says no for
  and none yes, or none can say and the ladder puts it beyond the farthest of them (`Range.longest`) (a spell with a least range, Charge or Auto Shot, says no to a foe too close as well, so its no counts
  for nothing); cleared when the plate goes; its border red at half its alpha (`Plate.Light`, `Bar.Border`'s `out`, `Bar.FAR`). `Range.Look` does every plate, every
  `Range.EVERY` (0.1) seconds, from Scale.lua's driver. `/sane range` prints what the game answers for your target:
  the distance found, and each of your attacks with its reach and the game's answer.
- **Cast** (`Cast.lua`): a frame of ours under the dress (`TOPLEFT` on its `BOTTOMLEFT`, under the combo points'
  row where it shows, as high as the dress, `Cast.Fit`),
  inside the dress's outline (`Bar.Outline`, run as it shows or hides: the border, the rank's line and the glow
  anchored down to its bottom, each in two halves round at their corners by Core's corner masks, as round as without
  it; the bar then reaches down to it, square at its bottom, so nothing of the outline shows between them), a `StatusBar` cut round by `Bar.Caps` filled in the
  game's cast bar atlases (`Cast.ART`, through `SetStatusBarTexture` as the game's own: `ui-castingbar-filling-standard`,
  `-filling-channel`, `ui-castingbar-uninterruptable`, `ui-castingbar-interrupted`), the icon square at its left end inside the border, a
  font string of the seconds on the icon, one of the spell's and its target's names from the icon to the bar's end
  (`SetWordWrap(false)`: cut short). `Cast.Update` reads the cast at each of the unit's `Cast.EVENTS`
  (`UNIT_SPELLCAST_*`, registered with Plate.EVENTS) and when a plate is filled: `UnitCastingInfo`, else
  `UnitChannelInfo` (name, icon, start, end, not interruptible), `UnitShouldDisplaySpellTargetName` and
  `UnitSpellTargetName`, each taken as it is, hidden or not: the fill (and the grey bar over it, `bar.lock`) runs from
  the cast's start to its end in the game's milliseconds (`SetMinMaxValues`) and the bar's guarded `OnUpdate`, only
  while it shows, gives both the time now (`SetValue`), so the game draws the progress though we may not read it; a
  channel fills from its end (`SetReverseFill`) in the dark over its colour, so it empties. Not interruptible: the grey
  bar seen by the game's answer (`SetAlpha`, or `SetAlphaFromBoolean` where it is hidden). The seconds (`%.1f` under
  ten): from the end where it may be read, else reckoned from the spell's `castTime` (`C_Spell.GetSpellInfo`) from the
  start or from now; a reckoned end passed by `Cast.WAIT` (1) second without the game's word counts as done.
  Interrupted (`UNIT_SPELLCAST_INTERRUPTED`): full in `Cast.BROKEN`, the text the game's `INTERRUPTED` and the
  interrupter's name (its `interruptedBy` GUID: `UnitTokenFromGUID` and `UnitName`, else `GetPlayerInfoByGUID`). Done
  (its end passed, `UNIT_SPELLCAST_STOP`, `_CHANNEL_STOP`: `Done`) or interrupted, it stays `Cast.HOLD` (0.5)
  seconds; `UNIT_SPELLCAST_FAILED` hides it at once. With the setting off ours hides and the game's `CastBarsContainer` (in
  `Plate.HIDDEN` otherwise) is at alpha 1 again.
- **Combo points** (`Resource.lua`): rogues and druids only listen (`UNIT_POWER_UPDATE` with `COMBO_POINTS`,
  `UNIT_MAXPOWER`, `UNIT_DISPLAYPOWER` of the player; `PLAYER_TARGET_CHANGED`, `COMBO_TARGET_CHANGED`; a plate
  coming or going), once a frame (`Core.Later`). Shown while the game gives combo
  points (`UnitPowerMax("player", Enum.PowerType.ComboPoints)`, at most `Resource.MOST` of the game: 5 in Forever, 7
  in Retail) and energy is the power shown: every plate's unit that `UnitCanAttack` allows is asked
  `GetComboPoints("player", unit)`, and its row shows while that is a plain number above 0; a hidden count shows on
  your target's plate only (`UnitIsUnit`), as it is, since more than none cannot be told. Retail keeps the points on
  your character, so the game counts them for every unit: there only your target's plate is asked. A row of its own
  under the dress (`TOPLEFT` on its `BOTTOMLEFT`, `Resource.SHARE` (a third) of its height, `Resource.Fit`), inside
  its outline: `Bar.Outline` (run as the row or the cast shows or hides) puts the cast under it and anchors the
  border, the rank's line and the glow down to the lowest row; the health bar square at its bottom then, the
  row round at its bottom corners only while it is the lowest (`Resource.Shape`, Core's corner masks), square
  above a cast. Inside it one `StatusBar` per point, a pixel apart, over the bar's dark, in the game's `PowerBarColor.COMBO_POINTS`: segment
  *i* from *i* - 1 to *i*, each given that count as the game gives it (secret or not):
  the bar clamps it, so a segment is full from its point on and empty below it, nothing computed with the count.
  The row's own pair of masks shapes every segment (they reach the first and the last).
- **Scale** (`Scale.lua`): your target's plate at `Scale.Full()`; any other's from its distance alone (`Range.lua`):
  `Scale.Full()` (the setting
  *Nameplate size*, key `plateSize`, `Scale.SIZE` 125% at first) times its share on `Scale.CURVE` (1 to 10 yards, 0.5 at 40, 0.25 at
  60). The game's scaling and fading are off by its CVars (`Scale.CVARS`: `nameplateMaxScale`, `MinScale`,
  `SelectedScale`, `LargerScale`, `MinAlpha`, `MaxAlpha`, `SelectedAlpha`, `NotSelectedAlpha` 1; and, whenever the
  module is on, `Scale.ALWAYS`: `nameplateShowOnlyNameForFriendlyPlayerUnits` 0, so friendly players' plates keep their
  health bar, auras, cast bar and clicks, kept and given back like the others), and whatever scale
  the game still gives a plate (`GetScale`) is undone: our dress at our size over it, the game's unit frame (its
  cast bar) at the share alone over it. A driver frame's guarded `OnUpdate` (hidden while no plate shows) runs
  `Range.Look` every `Range.EVERY` seconds, aims each plate at its share (anew too when the game's scale for it
  changed; every frame as `Range.Drift` moves its distance on) and moves it every frame, eased, never past it (`Scale.Step`: each moment the same share of what is left,
  `exp(-elapsed / Scale.EASE)` (0.08 s) with its distance, `Scale.QUICK` (0.05 s) when selected or let go; within
  `Scale.SNAP` of its size, there).
  `Scale.Born`: a plate appearing is asked about at once (`Range.One`, not at the next look) and shows at the size of its
  distance (your target's full), never larger; its alpha from 0 to 1 in a straight line within `Scale.SHOW` (5/7 s:
  running at 7 yards a second from 60 yards to 55; no item or spell reaches a foe at 55 or 60 yards, so nothing tells
  the two apart).
  Off, a plate taken back, standing down (`Scale.Leave`): the dress at `Scale.Full()` over the game's own scaling,
  seen, the unit frame at 1. While on, the CVars are ours (`Ours`): what each had before is kept first (`foundCVars` in the
  module's settings, once, never a value of ours); set again `Scale.AGAIN` (3) seconds after `PLAYER_ENTERING_WORLD`
  and `VARIABLES_LOADED` (the game's stored settings and Sync's profile come after the login) and after a `CVAR_UPDATE`
  of one of them. Switched off, standing down, or at the logout (`ns.OnLogout`, `Scale.Logout`: the game writes its
  settings after it, at a `/reload` too): each goes back to what it had (the game's default for one of ours whose
  earlier value is not known), nothing is kept, and nothing of ours sets them again until ours are on at the next
  start; so a module off or not loaded leaves the game's and the profiles' values alone. CVars through Core's
  `Sync.SetCVar` where it is there (else `C_CVar.SetCVar`), only those this client has, never in a fight (then at
  `PLAYER_REGEN_ENABLED`).
- **Combat text** (`CombatText.lua`): each dress hears its unit's `UNIT_COMBAT` (in `Plate.EVENTS`; kind, flags,
  amount, school) and hands it to `CombatText.Hit` (the combat log is closed to addons in this client); your own
  through `Core.OnUnit("UNIT_COMBAT", "player")` while *Over your character* is on, onto a point of ours on `UIParent`
  `CombatText.SELF` (-130: under its middle, about at your character's feet), at `Scale.Full()`. A number is a pooled frame on its host with one font
  string (`Core.Journal.FONT_BOLD`, `OUTLINE`; the game's `CombatTextFont` face where that cannot be set) and one
  texture, `CombatText.HEIGHT` high (times `CombatText.CRIT` 1.5 for a critical hit or heal, `CombatText.SMALL` 0.75
  for a glancing blow or a word, as the game's combat feedback); one animation group rises `CombatText.RISE` in
  `CombatText.TIME` and fades over its last `CombatText.FADE`, a critical one swells to `CombatText.SWELL` and back;
  `OnFinished` (guarded) returns it to the pool, as does the dress taken off (`CombatText.Clear`). Lanes
  `CombatText.LANES` in turn, at most `CombatText.MOST` a host (the oldest goes). What did no harm
  (a WOUND of 0 is a miss, or a block by its flags) is the word from `CombatFeedbackText`; with the setting `combatPictures`
  on (off by default, set by neither shared profile) and for `CombatText.PICTURES` (MISS, DODGE, PARRY and DEFLECT, BLOCK, EVADE, IMMUNE)
  it is the drawing `Art/combat-<name>`, `CombatText.PICTURE` (30) square, white or tinted by `CombatText.TINTS`
  (`SetVertexColor`: the immunity bright red), the word again where `SetTexture` finds no file. Colours, three only: physical white (school mask 1, or none told), any spell school red
  (`CombatText.SPELL`), heals green (both the game's combat text colours); over you with a "-". Amounts in the game's abbreviation (`AbbreviateNumbers` with `Text.STEPS`), written with
  `SetFormattedText`. What the game hides (secret values) is never compared, only written into a text, the one thing
  open to addons (`format`, `..`), and a curve or number formatter refuses it from them. A hidden amount is written as it is. A hidden
  school picks its colour inside the text (`CombatText.Hued`): written as the exponent in `CombatText.SHADE` it reads as
  255 for the physical school, 25 or less for a spell school, in hex the green and blue of `|cffffffff` or of a red; where the game
  refuses that, white. A hidden kind is a plain number: by its school over a foe (`UnitCanAttack`), where it is damage, white
  over a friend or your character, where it may be a heal, and neither drawing nor word can show. The
  game's CVars (`CombatText.CVARS`): `floatingCombatTextCombatDamage_v2` and `...CombatHealing_v2` at 0 while *Over
  nameplates* and *Instead of the game's* are on, `enableFloatingCombatText` at 0 while *Over your character* and
  *Instead of the game's* are on; else (and standing down) at their defaults; never in a fight (then at
  `PLAYER_REGEN_ENABLED`). What they had before ours is kept in
  the setting `combatFoundCVars` and goes back (`Restore`, once per group: plates, self) when ours is switched off,
  the module stands down, or at `PLAYER_LOGOUT` (`CombatText.Logout`, from `ns.OnLogout`, before Core's profiles
  take the game's settings), so a module off or not loaded leaves the game's and the profiles' values alone. Set
  again `CombatText.AGAIN` (3) seconds after `PLAYER_ENTERING_WORLD` and
  `VARIABLES_LOADED` (the game's stored settings and Sync's profile come after the login and turned the heal numbers
  back on), and after a `CVAR_UPDATE` of one of them; through `Core.Sync.SetCVar` where Sync is there.
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
| `Bar.lua` | The health bar: round at both ends, its border lit on your target and focus, the rank's line and the glow behind it, the power line |
| `Text.lua` | The line inside the bar: quest, raid marker, level, item level, threat, name, health; the bar as wide as the line |
| `Auras.lua` | Your debuffs above the bar, a foe's buffs left of it, crowd control right of it, in the game's own aura containers |
| `Marks.lua` | The raid marker, in the line |
| `Resource.lua` | Your combo points in a row under the bar of the unit holding them |
| `Cast.lua` | A unit's cast under its plate's bar: the icon with the seconds left, the spell and its target, cut to fit |
| `Range.lua` | How far each plate's unit is from your character (range checks of items and your spells), whether your attacks reach it |
| `Scale.lua` | Every plate's size by that distance alone, on a spring; the game's own scaling and fading off |
| `CombatText.lua` | The combat text: what a unit takes rising over its plate, and over your character; drawings for what did no harm |
| `Art/combat-*.blp` | The combat text's drawings (miss, dodge, parry, block, evade, immune): original art of Sane UI, drawn by an image model and picked by Saneroki (`assets/interface/combat-text/`; the miss drawn by code), traced by `dev/tools/combat-art` into `assets/CombatText/`, made into textures by `dev/tools/art` |
| `Plate.lua` | Our dress on each plate the game shows, laid over its health bar; the game's own bar, name, auras and marks out of sight under it; strangers' and critters' plates hidden |

## Not there yet
The raid marker in our own style in place of the game's (Saneroki, 2026-10-21; `Doc/guides/interface-style.md`,
*To redesign*).

## History
- **2026-10-30:** barriers, lost maximum health and dispellable auras on the plates (Saneroki), each its own switch
  (Core's `HealthMarks.lua`).
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
- **2026-10-23:** plates up to twice their size close by; the power line and the combo points without a
  background, the points as segments of their own; the red glow thin and fading out, not an outline (Saneroki).
- **2026-10-23:** the size by distance on a curve of two steps (Saneroki): twice at your feet, its own size at 40
  yards, half at 60, read from the game's own scaling and laid over it.
- **2026-10-23:** the red glow solid at the bar's edge and fading out, a blurred edge (Saneroki).
- **2026-10-23:** the glow a real fade on a frame of its own, narrower (six pixels); our bar half as wide again as
  the game's (Saneroki).
- **2026-10-23:** one line inside the bar, each piece taking room only while it shows: quest objective, raid
  marker, level, item level, threat, name, health; the bar as wide as the line (Saneroki). Combat's quest marks
  step aside meanwhile; the quest reading and the inspections are Core's now.
- **2026-10-23:** the line's text and icons smaller (Saneroki); each text measured whole on itself, so none is cut
  short and no room is left over.
- **2026-10-23:** one border, black or lit on target and focus; the rank's line and the glow behind it from the same
  edge (Saneroki); the ring is gone.
- **2026-10-23:** plates half the size (Saneroki): their own size at your feet, half at 40 yards, a quarter at 60;
  one straight line, so the game's own scaling does it all and nothing of ours rescales plates any more.
- **2026-10-23:** a compact bar, as high as its line (Saneroki), less room at its ends; plates one and a half times
  larger at your feet, the same straight line down to a quarter of that at 60 yards.
- **2026-10-23:** our bar twice the size (Saneroki); the health's room from its most or a guess by level and rank,
  no more room for "888.8k"; the ruler on a frame always shown.
- **2026-10-23:** one control over size and transparency (Saneroki): full within 10 yards, half at 40, a quarter at
  60, read from the game's scaling and set by us alone; plates spring in and fade out at the edge; the game's larger
  target and its fading off.
- **2026-10-23:** the quest's icon and the raid marker outside the bar, left of it, the count inside; long names
  make the bar longer (Saneroki).
- **2026-10-23:** your target's border red while none of your attacks reach it (Saneroki): your own spells' range
  checks, 40 yards for a character without any.
- **2026-10-23:** distance from your character, never the camera (Saneroki): range checks of the game's items and
  your spells, a ladder from 5 to 50 yards; size by it alone, on a spring, the setting *Nameplate size*; no fading;
  a red border on any foe out of reach of your attacks. The game's scaling had measured from the camera.
- **2026-10-23:** the glow under the outline, always (Saneroki); sizes change evenly, no spring; nameplates half
  the size (*Nameplate size* 125%); a spell with a least range no longer turns a close foe red; `/sane range`.
- **2026-10-23:** your target always full size (Saneroki); plates glide evenly from rung to rung of the range ladder
  (the distance at the rung a unit just passed), slowly, as its unit moves; far foes red when the ladder puts them
  beyond your farthest attack though your spells cannot say.
- **2026-10-23:** no endless bars after a `/reload`: widths the game cannot give yet are guessed, and every plate is
  measured anew once the world shows.
- **2026-10-23:** the outline one screen pixel at every size (Saneroki): a plate is laid out anew when its size
  settles or has moved on by a tenth (`Plate.Refit`), not only at its first size.
- **2026-10-23:** the game's scaling and fading kept off (Saneroki): its CVars set again after the game's stored
  settings and a profile's, and whenever one changes.
- **2026-10-23:** the game's nameplate CVars ours only while the module and the setting are on (Saneroki): what they had
  before goes back when it is switched off and at every logout.
- **2026-10-23:** our own cast bar (Saneroki): under the bar, as high as it, the seconds in the spell's icon, the
  spell and its target cut to fit; the game's out of sight while ours shows.
- **2026-10-23:** the cast bar says whether you can interrupt it now (green: your interrupt ready and in reach), and
  an interrupted cast is red and says so, and by whom (Saneroki).
- **2026-10-23:** the cast bar's colour from the cast alone (Saneroki): interruptible or not, red when interrupted; it
  stays half a second after it was done or interrupted.
- **2026-10-23:** the power line a third of the bar's height (Saneroki), the combo points as high on it.
- **2026-10-23:** the cast bar also for casts whose times the game hides from addons (Saneroki): the game draws its
  progress, the seconds are reckoned; the game's own cast bar no longer stands in.
- **2026-10-23:** the cast bar in the game's own cast bar art, inside the plate's one outline (Saneroki): the border,
  rank line and glow go around the bar and the cast bar together while a cast shows.
- **2026-10-23:** no line between the bar and the cast bar (Saneroki): the bar reaches down to it, the bar's dark
  behind their corners.
- **2026-10-23:** every round fits (Saneroki): the outline and the plates around it round the same with or without a
  cast bar (two halves, Core's corner masks), the glow and the rank's line that much rounder by their reach, the bar
  and the cast bar a pixel less; the bar square at its bottom and the cast bar at its top where they meet, the icon
  round at the bottom left, the cast fill at the bottom right. The seam is gone.
- **2026-10-23:** the bar's dark solid (Saneroki): a white or red outline no longer shows through the bar's soft edges,
  so it is as thin as the black.
- **2026-10-23:** your target's outline a quiet 50% grey (Saneroki), a hint rather than white.
- **2026-10-23:** the threat red in a fight while you have aggro (Saneroki): the game's hidden answer turned into its
  colour; orange only where the game shows how high your threat is.
- **2026-10-23:** the combo points in a row of their own under your target's bar (Saneroki), half its height,
  inside the same outline; a cast's bar under them.
- **2026-10-23:** the combo points' row thinner (Saneroki): a third of the bar's height, as the power line.
- **2026-10-23:** the combo points' row on whichever plate holds at least one point, your target's or not, and on
  none while you have none (Saneroki).
- **2026-10-25:** Retail: the combo points on your target's plate alone (Retail keeps them on your character), up to
  seven.
- **2026-10-25:** critters, wild pets and companion pets without a plate or a name (Saneroki), unless your target or
  wanted for a quest of yours; the setting *Plates on critters* shows them.
- **2026-10-29:** no item's range asked about a foe in a fight (Saneroki): the game blocked each such question,
  thousands of "Interface action failed because of an AddOn" in Retail's taint log; the spells answer alone there.
- **2026-10-29:** no item's range asked about a friend either while the game restricts addons (a fight, an
  encounter, a keystone, a PvP match): thousands more blocked actions in Retail while friends were still asked.
- **2026-10-29:** sizes change quickly and eased, no longer slowly and evenly; the raid marker in the line right
  after the level, as on the unit frames (Saneroki).
- **2026-10-29:** sizes follow a moving unit every frame (Saneroki): between two range checks the distance moves on
  at the pace its unit passed the last two; looked at twice as often, two questions a look while it stays.
