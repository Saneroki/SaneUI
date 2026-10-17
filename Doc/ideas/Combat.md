# Combat

Planning notes for the **Combat** module. This is not a spec yet: it collects what Saneroki has decided so far
(2026-10-16) and proposals for him to discuss. The module is set up (`src/Combat/`, addon `SaneUI_Combat`);
nothing in it is built.

## What it is

Saneroki, 2026-10-16: **a module called Combat that handles everything about party, raid, buffs, unit frames,
nameplates, pets** and what goes with them. It is one module (`SaneUI_Combat`), switched on and off by
itself in the game's addon list like every other; each of its parts has its own files and its own switch.

Decided (Saneroki, 2026-10-16):

- **Our own windows, on Core's window system.** Every part's frames are Sane UI windows (`Core.Window`):
  docked, moved and sized in Edit Mode like every other module's; the game's own frame is put out of
  sight. Unit frames and buff frames are windows without a title bar (`Doc/ideas/Windows.md`,
  *Title bars*).
- **The look** is developed along the way and decided later.
- **Also Combat's:** floating combat text, raid warnings, threat and the swing timers, each in a performant,
  on demand way that is developed further (*On demand* below).
- **Party style** (the game's raid style or classic party frames) and **click casting** are decided during
  development.

## Its parts

| Part | What it covers | The game's own frames it stands for |
| --- | --- | --- |
| **Unit frames** | You, your target, your target's target, your focus | `PlayerFrame`, `TargetFrame`, `TargetFrameToT`, `FocusFrame`, `FocusFrameToT` (`Blizzard_UnitFrame`) |
| **Pet** | Your pet (hunter, warlock, a summoned creature), the vehicle you ride | `PetFrame`; `AlternatePowerBar`, `PlayerPowerBarAlt` |
| **Party** | Up to four others in your group, with their pets | `PartyFrame` (members `PartyFrame.MemberFrame1..4`), or `CompactPartyFrame` in raid style |
| **Raid** | Up to forty, in groups, and the raid's tools (marks, ready check, leader) | `CompactRaidFrameContainer`, `CompactRaidFrameManager` (`Blizzard_CompactRaidFrames`); `ReadyCheckFrame` |
| **Buffs** | Your own buffs and debuffs, your weapon enchants; the buffs shown on every other part | `BuffFrame`, `DebuffFrame`, `DeadlyDebuffFrame` (`Blizzard_BuffFrame`) |
| **Nameplates** | The plates over the heads of creatures and players | `NamePlateDriverFrame` and its plates (`Blizzard_NamePlates`) |
| **Cast bars** | Your casting, your target's and focus's, a nameplate's | `PlayerCastingBarFrame`, `TargetFrameSpellBar`, `FocusFrameSpellBar`, `PetCastingBarFrame` |
| **Bosses** | The boss frames of an encounter | `BossTargetFrameContainer` (`Boss1..5TargetFrame`); this client has no arena frames |
| **Class resources** | What a class counts beside its power: combo points, totems, ... | `ComboFrame` (on the target frame), `TotemFrame`; this client has no runes, shards or holy power bars |
| **Swing timers** | The time to your next melee swing and shot | `SwingTimerMainHandFrame`, `SwingTimerOffHandFrame`, `SwingTimerRangedFrame` (`Blizzard_SwingTimer`, this client's own) |
| **Threat** | Who a creature is after, how close you are to pulling it | The target frame's `NumericalThreat`; the nameplates' threat colours (CVar `nameplateThreatDisplay`) |
| **Combat text** | Damage, healing and what happens to you, floating over your character | `CombatText` (`Blizzard_CombatText`, loaded on demand) |
| **Raid warnings** | The raid leader's warnings and boss messages in the middle of the screen | `RaidWarningFrame` (`Blizzard_RaidWarning`) |

## What this client has (from `references/`, 2026-10-16)

WoW: Forever is the game type *camelot* in Blizzard's TOCs: the mainline family (its `[Family]` files are
`Mainline`) with overrides of its own (`[Game]`, the `Camelot` folders). A line for `standard` (retail)
does not load here. Paths below are under `references/BlizzardInterfaceCode/Interface/AddOns/`.

**Unit frames** (`Blizzard_UnitFrame`): every one is a `SecureUnitButtonTemplate` and so protected. Camelot's
own (`Blizzard_UnitFrame/Camelot/`): the level in a small circle, a narrower target name, small round PvP
icons, no role icon in instances, gold winged portraits for elites and bosses and silver for rares,
the combo points at the target frame's top right. Swing timers are camelot's own too
(`Blizzard_SwingTimer`).

**Edit Mode:** the game's frames are Edit Mode systems with settings of their own. Player: frame size,
cast bar under it. Target and focus: buffs on top, frame size (focus: larger frame). Party: *Use raid-style
party frames*, and in raid style width, height, border, sorting, auras. Raid: groups, sorting, row size,
width and height. Boss: larger frame, cast bar at the side. Pet: frame size. Buffs and debuffs (*AuraFrame*):
orientation, wrap, direction, icon size, padding, how many. Cast bar: size, locked to the player frame,
cast time. Our frames cannot join these systems (Blizzard's list is secure); they follow Edit Mode as Core's
windows do and may read these settings as defaults.

**Secret values** (`Blizzard_APIDocumentationGenerated`): what an addon may read in a fight.

| Plain | Secret (shown, never computed with) |
| --- | --- |
| `UnitExists`, `UnitLevel`, `UnitIsDead`, `UnitIsConnected`, `UnitAffectingCombat`, `UnitReaction`, `UnitCanAttack`, `UnitClassification` | `UnitHealth`, `UnitHealthPercent`, absorbs, incoming heals, `UnitInRange`, a raid mark: at any time |
| Name, class, GUID and role of a player or a member of your group (an enemy player's name in PvP may be secret) | The same of a creature that is not in your group |
| Your own casts and your pet's | Everybody else's casts (`UnitCastingInfo`, `UNIT_SPELLCAST_*`) |
| Threat of you, your pet or an ally against one unit | Auras (`C_UnitAuras`) and `UNIT_AURA` while auras are restricted (combat, encounter, PvP match) |
| Max health and max power of a player | Power of most kinds; max health and power of a creature |

The widgets that take a secret from addon code are those marked `AllowedWhenTainted`: a bar's value and
range, a text, colours, alpha (also `SetAlphaFromBoolean`), a texture. `SetShown` and `Cooldown:SetCooldown`
do not: a cooldown swirl or a buff's bar takes the game's duration object (`C_UnitAuras.GetAuraDuration`
into `SetCooldownFromDurationObject` or `StatusBar:SetTimerDuration`; to try). Auras can be sorted without
reading them: `C_UnitAuras.GetUnitAuraInstanceIDs` and the game's filters (`AuraUtil.AuraFilters`:
crowd control, big defensive, important, dispellable, ...). `C_Secrets.HasSecretRestrictions()` says at run
time whether secrets are on at all. `COMBAT_LOG_EVENT_UNFILTERED` is restricted
(`C_CombatLog.IsCombatLogRestricted`): no part may depend on the combat log.

**Party and raid:** the game's secure group headers load (`SecureGroupHeaderTemplate`,
`SecurePartyHeaderTemplate`, `SecureRaidGroupHeaderTemplate`, `SecureGroupPetHeaderTemplate`): they arrange
the members and change them in a fight, which addon code cannot. Raid-style party frames exist.

**Buffs:** `BuffFrame` and `DebuffFrame` are aura containers with buttons; a right click cancels a buff in
Blizzard's secure code. `SecureAuraHeaderTemplate`, the older way for addons to cancel buffs, loads only
in classic, not here. The way here looks like `CustomAuraContainerTemplate` with its `AuraButton`
(`Blizzard_AuraContainer`, `SetCancelAuraButtons`): to try whether it cancels in a fight.

**Nameplates:** `NamePlateDriverFrame` makes the plates (`NAME_PLATE_UNIT_ADDED`/`REMOVED`); some plates
are forbidden to addon code (`FORBIDDEN_NAME_PLATE_*`). One size for all (`C_NamePlate.SetNamePlateSize`,
restricted), set by CVars (`nameplateShowAll`, `nameplateShowEnemies`, `nameplateStyle`, ...). Camelot's
own: 190 wide, name centred over the bar with health text inside, the level coloured by difficulty with a
skull, white border for the target and orange for the focus; styles Thin, Modern, Block, CastFocus.
A plate's health, auras and cast are secret; drawing over a plate is display only.

**Swing timers, threat, combat text, raid warnings:** swing timers and raid warnings are Edit Mode systems
(*SwingTimer*, *RaidWarning*); `Blizzard_SwingTimer` loads only in this client (`AllowLoadGameType: camelot`).
Threat (`UnitThreatSituation`, `UnitDetailedThreatSituation`) is plain for you, your pet or an ally against
one unit. Combat text comes from `COMBAT_TEXT_UPDATE`, and what happened from
`C_CombatText.GetCurrentEventInfo`, whose answers are secret: written into a text as they come, never added
up or compared. The combat log is restricted, so combat text can't be built from it.

## How every part works

The same rules for each part, so the parts look and behave as one. Decided: our own windows on Core's
system, and on demand (Saneroki, 2026-10-16); the rest is a proposal.

- **The game's frame is put away, never changed.** A part that draws its own frame parents the game's to
  a hidden frame of ours (as Social does with the game's chat, `src/Social/Native.lua`) and gives it its
  own parent back when the part is switched off or fails. Nothing is written into Blizzard's frames or
  tables, and nothing of theirs is replaced (`Doc/guides/addon-standards.md`, *Taint*).
- **Fallback:** an error in a part stands that part down and gives the game's frame back (Core's
  `StandDown`, `GiveBack`), not the whole module. A part whose Blizzard frame is missing in a client
  update stays off.
- **Combat lock:** unit frames are secure buttons (a click targets, as the game's do); they can only be
  made, shown, moved and given back out of combat. Whatever is asked for in a fight waits for
  `PLAYER_REGEN_ENABLED`. Secure frames are never made in a fight. A Core window that holds secure
  buttons is locked with them, so its moves and size changes (expanding, full screen) wait until the fight
  is over too; Core's window system needs a way for that (to build).
- **On demand** (decided; how is developed further): a part that is switched off, or has nothing to show,
  costs nothing: no frames, no events. Ideas: the raid's frames once you are in a raid, the boss frames at
  an encounter (`INSTANCE_ENCOUNTER_ENGAGE_UNIT`), combat text and swing timers from the first fight on,
  raid warnings with the first warning. Secure frames must be there before a fight starts, so they are
  made beforehand, out of combat (at login, on joining a group).
- **Present, never compute** (`Doc/guides/blizzard-design-principles.md`, 12): in a fight the game hands
  health, power and auras to addons as secret values. A part passes them straight to the widgets that
  take them (a bar's value, a text, a colour; a cooldown swirl the game's duration object) and does no sums,
  comparisons or sorting with them.
  A part that would need hidden combat data is the wrong part.
- **Only reads:** a part shows the game's live unit data. Anything to keep (a creature's facts, a spell's)
  comes from Core's data framework (`Doc/ideas/Data.md`); Combat gathers and stores no game data of its own.
- **Cheap in a fight:** unit events per unit (`RegisterUnitEvent`), auras from `UNIT_AURA`'s list of what
  changed, not a full scan; pools of reused frames; no `OnUpdate` except a cast bar while it runs; nothing
  rebuilt in combat.
- **Core's windows** (decided): each part's frames are Core windows, moved and sized in Blizzard's Edit
  Mode (`Doc/ideas/Windows.md`, *Edit Mode*); unit frames and buffs without a title bar. The party and raid
  sit in the top left place of the screen layout (tentative, `Doc/ideas/Windows.md`).
- **Options:** one page *Combat*, a tab per part (Core's tabbed pages, `Core.Tabbed`), each tab with the
  part's switch on top.

## Order to build (proposal)

1. **Unit frames** for you and your target: the base every other part reuses (a secure unit button, its
   health and power bars, name, level, portrait, the buffs on it).
2. **Pet, target's target, focus:** the same frame, smaller.
3. **Party**, then **Raid:** many of the same frame, arranged by the game's secure group header.
4. **Buffs:** your own, at the top right as the game has them.
5. **Cast bars**, **bosses**, **class resources**, **swing timers**, **threat.**
6. **Combat text** and **raid warnings.**
7. **Nameplates:** last, they are the most restricted by the game (*Nameplates* above).

Each step is built plain first, tried in the game, then given its look (`blizzard-design-principles.md`, 7).

## Open questions

- **The look:** developed along the way (decided); what it becomes is open.
- **Click casting** (during development): a spell on a click of a party or raid frame (healers)? It would
  be built from the game's secure attributes, set out of combat.
- **Party as raid** (during development): party in the game's raid style (the compact frames), or as the
  classic party frames?
- **The loss-of-control alert:** Combat's too?
- **On demand:** how each part loads and wakes, in detail.
- **Where each part stands** besides party and raid (top left): the screen layout has places still to
  decide (`Doc/ideas/Windows.md`).
