local ADDON, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_Combat): it needs Core and nothing else, and is
--  switched on and off in the game's addon list.
--
--  What the fight shows on the screen (Saneroki, 2026-11-18: "I want a combat
--  module that has the unit frames, party frames, Nameplates and the edit aura
--  tracking functionality in it"), each part in files of its own, each part
--  ours or the game's by a switch of its own (Ours or the game's, the first
--  section of its options, its setup's first step and Core's dropdown Classic
--  windows: "people can for example choose to use our party and unit frames
--  but disable our nameplates"):
--    the unit frames      you, your target and your focus in a nameplate's
--                         look, their targets and your pet in rows under
--                         them (Units/), in place of the game's
--    the party and raid   one frame of ours for both, in place of the game's
--                         two (Units/Group.lua)
--    the nameplates       the game's plates in our dress, the combat text
--                         over them (Nameplates/, the addon SaneUI_Nameplates
--                         until 2026-11-18)
--    aura tracking        your marks of auras on the game's buff list and the
--                         frames, Edit tracked, the aura icons on invisible
--                         bars, on the health bars and under the plates
--                         (Units/Lists.lua, Reminders/)
--  and beside them: a mark beside a creature's nameplate while it belongs to
--  an objective still to do (QuestMarks.lua), rings around the mouse for the
--  global cooldown and your cast (MouseRings.lua), the threat and damage
--  meter (Meter/), the red error text off (ErrorText.lua). Its setup, step by
--  step (Setup.lua: the parts, the unit frames, the party and raid frames with
--  their previews and Edit Mode, the nameplates' steps). What is for the full
--  screen (our spellbook and talents, Sane Macros, the action bars, the aura
--  history) is Abilities'. Each part falls back to the game's own when it
--  fails (Core's StandDown, GiveBack), and only reads what it shows: the game's
--  live data, and Core's data framework for anything kept. The plan is
--  Doc/ideas/Combat.md.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Combat", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = "Combat",
    setup = "Set up step by step",
    setupTip = "A window that walks you through Combat a step at a time: which parts are ours, your unit frames, your party and raid frames with a preview of 5, 10, 20 and 40 and a place for them in Edit Mode, and every part of the nameplates, each with a sample that shows each choice at once. Also /sane setup combat.",
    -- Ours or the game's (Saneroki, 2026-11-18): each part's switch, the first section.
    parts = "Ours or the game's",
    partsTip = "Which parts of the fight are SaneUI's. A part switched off is the game's own again, as it was before SaneUI; the others stay ours. The same choices stand in the dropdown Classic windows of a full screen.",
    partUnits = "Unit frames",
    partUnitsTip = "Your frame, your target's and your focus's in a nameplate's look, with your pet and their targets in rows under them, instead of the game's. Off: the game's own frames. Each frame has its own switch below.",
    partPlates = "Nameplates",
    partPlatesTip = "The game's nameplates in SaneUI's dress, and the combat text rising over them and over your character. Off: the game's own plates and combat text. Back on, they are ours after a /reload.",
    partAuras = "Aura tracking",
    partAurasTip = "Track an aura and its icon shows where and when you choose: on an invisible aura bar, on the health bars of your unit frames and your party and raid frames, or right under each nameplate (Edit tracked, /sane auras). Off: no aura icons and no aura bars.",
    nameplates = "Nameplates",
    questMarks = "Quest marks on nameplates",
    questMarksTip = "A creature that belongs to a quest in your log shows a small mark beside its nameplate while an objective of it is still to do: a sword to kill it, a sack to loot it, with the count still open. As the game says it in the creature's tooltip.",
    units = "Unit frames",
    unitsTip = "Our own frames in place of the game's, in the look of a nameplate, green: the level and raid marker on the left, then the name, the health and how much is left on the right. Under a frame, as a cast bar under a nameplate, a row with the name of its target or your pet; under your own your pet, with its health and its resource. Directly above the health bar the unit's cast; your breath over your own health bar. A click targets, a right click opens the game's menu. Placed in the game's Edit Mode.",
    unitPlayer = "Your frame",
    unitPlayerTip = "Your own frame instead of the game's: your level and health, no name. The game's totems stay where the game's frame was: move that in Edit Mode. Off: the game's own frame.",
    unitCast = "Cast bars",
    unitCastTip = "On your frame, your target's and your focus's while the unit casts, directly above the health bar: the spell's icon and name and the seconds left, grey where it cannot be interrupted, instead of the game's cast bars. Off: the game's own for you, none for the others.",
    unitBreath = "Your breath bar",
    unitBreathTip = "Part of your frame while the game counts them down: your breath over your health bar, in the game's bubbles; your fatigue or a feign death above it. Each with the seconds left, instead of the game's bars at the top of the screen. Off: the game's own.",
    unitPet = "Your pet",
    unitPetTip = "Under your frame while you have a pet: a row with its health and name and its resource under it, instead of the game's pet frame. Off: the game's pet frame.",
    unitTarget = "Your target's frame",
    unitTargetTip = "Your target's frame instead of the game's, with its own auras and cast bar. Off: the game's own frame.",
    unitTargetTarget = "Your target's target",
    unitTargetTargetTip = "Under your target's frame while your target has a target: a row with that one's health and name. A click targets it.",
    unitFocus = "Your focus's frame",
    unitFocusTip = "Your focus's frame instead of the game's, with its own auras and cast bar. Off: the game's own frame.",
    unitFocusTarget = "Your focus's target",
    unitFocusTargetTip = "Under your focus's frame while your focus has a target: a row with that one's health and name.",
    unitLookOut = "Look out for",
    unitLookOutTip = "While you have no focus, the mouse on your focus's place shows Look out for. Click it and type a name, or pick @tank, @healer or one of your party or raid by its +: it is looked out for, in a fight too. Once found, the place says Focus found: Add it now, and a click on it (or its key) makes that one your focus. The X stops it. The game lets no addon set a focus by itself, so the click is yours.",
    lookOut = "Look out for",
    lookOutWatching = "Looking out for %s",
    lookOutTry = "Looking out for %s: click to try",
    lookOutLater = "Looking out for %s after the fight",
    lookOutFound = "Focus found: Add it now",
    lookOutClick = "Click: make it your focus.",
    lookOutTryClick = "Click: make it your focus, if it is near.",
    lookOutRight = "Right click: change it, or stop it by the X.",
    lookOutStop = "Stop looking out",
    lookOutGroup = "Look out for one of your group",
    lookOutTank = "Tank (@tank)",
    lookOutHealer = "Healer (@healer)",
    lookOutParty = "Party member",
    lookOutRaid = "Raid member",
    lookOutKey = "Focus who you look out for",
    unitSize = "Unit frame size",
    unitSizeTip = "How large the three frames and their rows are.",
    unitAuras = "Auras on the frames",
    unitAurasTip = "The auras that matter most above a frame: four buffs on its left, crowd control in its middle, debuffs on its right (on a foe yours). Those you mark Important come first, with the game's golden animated outline, and those you mark Prioritize on unit frames come first without one; those you mark Unimportant or Hide from unit frames never show. Click an icon (out of a fight) to mark it, or to open Edit tracked (/sane auras).",
    auraImportant = "Important",
    auraUnimportant = "Unimportant",
    auraHidden = "Hidden",
    auraFramesShow = "Prioritize on unit frames",
    auraFramesHide = "Hide from unit frames",
    buffList = "Your buffs and debuffs",
    buffListOn = "Marks and menu on the game's list",
    buffListTip = "The game's list of your buffs and debuffs at the top of the screen. Click one for its menu: Important (the game's golden animated outline around it, and first on the unit frames), Unimportant (faded, and never on the unit frames), Hidden (out of sight until the mouse is on the list), and for the unit frames alone, with the list as it is: Prioritize on unit frames (first there, no glow) and Hide from unit frames; Edit tracked..., and last Add tracking. In a fight the game keeps what came during it from addons. A right click cancels a buff, as in the game. Off: the game's list as it is. The spellbook's right click opens the same menu.",
    auraLists = "Edit tracked...",
    auraFight = "In a fight the game keeps this aura from addons: after it",
    listsTitle = "Edit tracked",
    listsInput = "Search any class's auras, an enemy's or an item's, or type a spell's number:",
    listsEmpty = "None yet. Search for an aura above, or click one on your frames or a spell in the spellbook.",
    listsPut = "%s: %s.",
    listsAdded = "%s is on the list: tick what it should be.",
    listsThere = "%s is on the list already.",
    listsGone = "%s is off the list and every mark.",
    listsRule = "On the unit frames the game lets these act on the buffs of you, your group and friendly units, and on the debuffs of foes; on the rest it decides itself.",
    unitBarrier = "Barriers",
    unitBarrierTip = "What absorbs damage on a unit, in the game's shield art on its health bar: after the health while it fits, against the bar's right end when it does not. On your unit frames and your party and raid frames.",
    unitLost = "Lost maximum health",
    unitLostTip = "Maximum health taken away for a while: the health bar ends earlier and the rest of its length is hatched. On your unit frames and your party and raid frames.",
    unitDispel = "Dispellable debuffs",
    unitDispelTip = "What you or your group can take off a unit (on a foe, a buff you can remove): the game's icon of its type, a green drop for poison and so on, big over the left of the health bar. On your unit frames and your party and raid frames.",
    group = "Party and raid frames",
    groupTip = "One frame for your party and your raid in place of the game's: going up from its bottom left corner, then a column to the right for each raid group, up to forty, sized to fit. The raid marker and the name on the left, how much health is left on the right, or nothing there on a frame too narrow for it; a tank's or a healer's mana as a line inside the bar, and a tiny mark of its role in the top left corner, a shield or a plus. Big over the left of the frame float a dispellable debuff's type, a ready check and a resurrection on its way. The dead are red, the offline grey, a red border is on who has aggro. A click targets, a right click opens the game's menu, and hover macros work on them. Your own slot is like any other, named Party or Raid, with a cog in place of its health's words that opens the group's tools, in place of the game's raid manager at the screen's edge. Click the frame in Edit Mode for its sizes and a preview. Off: the game's own.",
    groupTools = "Group tools: ready check, raid markers and more",
    groupRaid = Core.Word("RAID", "Raid"),
    groupParty = Core.Word("PARTY", "Party"),
    groupReady = Core.Word("READY_CHECK", "Ready Check"),
    groupRole = Core.Word("ROLE_POLL", "Role Check"),
    groupCountdown = "Countdown",
    groupAssist = Core.Word("ALL_ASSIST_LABEL_LONG", "Make Everyone Assistant"),
    groupTarget = Core.Word("TARGET", "Target"),
    groupGround = "Ground",
    groupMenu = "Group menu",
    groupLeave = Core.Word("PARTY_LEAVE", "Leave Group"),
    groupBeside = "Pets and targets beside a party",
    groupBesideTip = "In a party of five or less, right of each member's frame two small ones, half as wide and high: what they target above, their combat pet under it, each with its name alone (beside you your target and your pet). A click targets it; a pet called or gone shows or goes in a fight too. Not in a raid.",
    groupClass = "Class colours",
    groupClassTip = "The health of every player on the party and raid frames in their class's colour; a foe beside a party yellow or red by how it stands to you, a pet green. Off: green, as on the unit frames.",
    groupBuffs = "Aura icons on the health bars",
    groupBuffsTip = "On your unit frames and the party and raid frames, the icons of the auras you show there: in Edit tracked (/sane auras) track an aura and choose Unit frames or Group frames under the list, and its icon shows on your frame, your target's and your focus's, or on each member's, of those Watch on names, while its settings want it, a buff they are missing, say. A group's version counts for the one (a Gift of the Wild for a Mark of the Wild); Only yours counts your own cast alone, for your HoTs. In a fight the game hides most auras from addons: one that runs out or is taken off shows at once, one you cast on someone goes, the rest is read again when the fight ends.",
    groupWidth = "Max width",
    groupHeight = "Max height",
    groupUnitWidth = "Max unit width",
    groupPreview = "Preview",
    groupSamples = {
        first = { "Aldren", "Brisa", "Caelum", "Dorin", "Elsbeth", "Fenrick", "Gwyn", "Halden", "Ilsa", "Joren", "Kestra", "Lorcan" },
        last = { "Ashford", "Brightwater", "Crowley", "Dunmere", "Everhart", "Fallowfield", "Greymoor", "Hollow" },
        pets = { "Wolf", "Imp", "Voidwalker", "Cat", "Boar", "Raptor" },
        foes = { "Kobold Miner", "Murloc Raider", "Gnoll Brute", "Forest Spider", "Defias Bandit", "Young Wolf" },
    },
    samples = { player = "You", target = Core.Word("TARGET", "Target"), focus = Core.Word("FOCUS", "Focus"),
                targettarget = "Target's target", focustarget = "Focus's target", pet = Core.Word("PET", "Pet"),
                cast = "Cast bar", breath = Core.Word("BREATH_LABEL", "Breath"), fatigue = Core.Word("EXHAUSTION_LABEL", "Fatigue") },
    -- A unit frame's dialog in Edit Mode (Units/Units.lua): its width and what it shows.
    frameWidth = "Width",
    showLevel = "Level",
    showLevelMax = "Hide the level at %d",
    showMark = "Raid marker",
    showGear = "Item level",
    showName = "Name",
    showHealth = "Health",
    showPercent = "Health in percent",
    showPowerNow = "Resource: current",
    showPowerMost = "Resource: maximum",
    showPowerPercent = "Resource: percent",
    showPowerRight = "Resource numbers on the right",
    -- When it shows (Saneroki, 2026-11-18): there and in the setup's step (Setup.lua), always in sight at first.
    showMouseover = "Show only on mouseover",
    showMouseoverTip = "Out of sight until the mouse is on it: on its place, its row or its auras. A cast or a timer on it shows it too, and Edit Mode. Out of sight it still takes the mouse. Off: always in sight.",
    showFight = "Always show in combat",
    showFightTip = "In sight in a fight, and after it while your health or your resource is not full (rage and combo points: while you have any), and while you are dead.",
    showGroup = "Always show in a group",
    showGroupTip = "In sight in a party or raid.",
    hideErrors = "Hide the red error text",
    hideErrorsTip = "The game's red line at the top of the screen, like Spell is not ready yet or Not enough rage, and its sound. Yellow lines, like a quest's progress, stay.",
    mouseRings = "Rings around the mouse",
    mouseRingsTip = "See-through rings around the mouse only while something runs, gone when it is over. They stand around the whole picture of the cursor, start and end at its tip, and grow with the game's Cursor Size.",
    mouseCooldown = "Global cooldown",
    mouseCooldownTip = "The inner, thinner ring, in white, fills while the global cooldown runs.",
    mouseCast = "Your cast",
    mouseCastTip = "The outer ring, in your class's colour, fills while you cast and empties while you channel, a bright line with a soft glow at its head. Interrupted, it goes at once.",
    meter = "Threat and damage meter",
    meterTip = "Your party or raid, you on top, each with their class, level, item level and name and a bar each for threat, damage, healing and interrupts. No background, and clicks go through it. With the mouse on it the buttons show at the end of the first line, that line drags it and its corner sizes it, unless it is locked; the mouse wheel scrolls the others; a right click on a name chooses that character's own bars. At first out of sight out of a fight and alone, and the mouse on its place brings it. Instead of the game's own damage meter.",
    meterLocked = "Lock window",
    meterLockedTip = "The meter stays where it is and at its size: its first line no longer moves it and its corner no longer sizes it. Also in the cog of its first line. Edit Mode still arranges it, as it does the game's own meter.",
    meterKinds = { threat = "Threat", damage = "Damage", healing = "Healing", interrupts = "Interrupts" },
    meterTicks = { meterMine = "My self on top", meterThreat = "Show Threat", meterDamage = "Show Damage",
                   meterHealing = "Show Healing", meterInterrupts = "Show Interrupts",
                   meterReset = "Reset on new combat", meterHideRest = "Hide outside combat",
                   meterHideAlone = "Hide when not in group", meterHover = "Show on mouseover" },
    meterWhen = "When it shows",
    meterAsWindow = "As the window's ticks",
    meterTicksTip = "What the meter shows",
    meterOrder = "Order by",
    meterDps = "DPS",
    meterHps = "HPS",
    meterTotalDamage = "Total damage",
    meterTotalHealing = "Total healing",
    meterNext = "The next fight",
    meterPrevious = "The fight before",
    meterFight = "Fight",
    meterAbout = "%s, %d:%02d",
    meterSavedFights = "Saved fights",
    meterSavedTip = "Save this fight under a name of your own, or load one you saved, in a group or not.",
    meterSave = "Save this fight...",
    meterSaveAsk = "Save this fight as:",
    meterSaved = "Fight saved as %s.",
    meterSaveLater = "Your fight is saved as %s when it is over: the game hides its numbers until then.",
    meterLoad = "Load",
    meterBack = "Back to the fights",
    reminders = "Aura icons",
    remindersOn = "Aura icons and bars",
    remindersTip = "Track an aura and its icon shows on an invisible aura bar while its settings want it, when the aura is missing or active, in or out of a fight, or some seconds before it runs out: on you, your target or your focus, the bar as wide as what shows on it, placed in Edit Mode, as many bars as you like. Click a buff or debuff, or right click a spell in the spellbook, and choose Add tracking; or open Edit tracked (/sane auras), search any spell and choose Add tracking under the list, or tick its Tracked. Under the list its settings can show it on the health bars instead, your unit frames' and each member's of your party or raid (a buff only on a unit you can help), or right under each nameplate. Off: no icons, no bars.",
    aurasOpen = "Edit tracked",
    aurasOpenTip = "Every aura's setup in one window: search any class's spells, an enemy's or an item's, and tick what it should be, Hidden, Unimportant, Important, Hide from unit frames, Prioritize on unit frames, and Tracked: its icon on an aura bar, the health bars of your unit frames and the party and raid frames, or the nameplates, its settings under the list.",
    trackAdd = "Add tracking",
    reminderBar = "Aura bar %d",
    reminderNewBar = "New bar",
    reminderDeleteBar = "Delete bar",
    reminderColumn = "Tracked",
    reminderPick = "Click an aura's line for its tracking here: its icon on an aura bar, your unit frames and the party and raid frames, or the nameplates.",
    reminderNone = "Not tracked yet. Add tracking shows its icon on Aura bar 1; then set here where and when.",
    reminderWatch = "Watch on",
    reminderUnits = { player = "You", target = "Your target", focus = "Your focus", group = "Everyone", tank = "Tank",
                      healer = "Healer", dps = "DPS", party = "Party %s", raid = "Group %s", raidMenu = "Group" },
    reminderFrames = "Unit frames",
    reminderGroup = "Group frames",
    reminderOnPlates = "Right under each nameplate, on its unit",
    reminderPlates = "Nameplates",
    reminderOnBar = "Shows on",
    reminderMissing = "Display when missing",
    reminderActive = "Display when active",
    reminderWhen = "Combat",
    reminderCombat = { any = "In and out of combat", out = "Only show outside of combat", ["in"] = "Only show inside of combat" },
    reminderRest = "Hide in rested areas",
    reminderInGroup = "Only in groups",
    reminderIgnore = "Ignore everywhere",
    reminderTitle = "Edit Tracked conditions",
    reminderOwn = "Only yours",
    reminderEarly = "Offset time (seconds)",
    reminderClass = "When class in group",
    reminderClassAny = "Not needed",
    listsCopy = "Track it once more: a copy of this line under it, with its own place and conditions.",
    listsCopied = "%s is tracked once more: set its place and conditions below.",
    listsCopyGone = "That tracking of %s is deleted; the others stay.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the game's own unit, party and raid frames, nameplates and damage meter are back, no quest marks beside nameplates, no aura icons or bars, no rings around the mouse"

-- The module's switches; the nameplates add theirs (Nameplates/Nameplates.lua), Settings.lua hands them to Core.
ns.OPTIONS = {
    -- The setup, step by step (Setup.lua, the window of the addon Onboarding).
    { key = "setup", text = ns.TEXT.setup, tip = ns.TEXT.setupTip, button = function() Core.Onboarding.Open(ns.name) end },
    -- Ours or the game's: each part, its switches below under it.
    { key = "units", default = true, text = ns.TEXT.partUnits, tip = ns.TEXT.partUnitsTip, header = ns.TEXT.parts,
      headerTip = ns.TEXT.partsTip },
    { key = "group", default = true, text = ns.TEXT.group, tip = ns.TEXT.groupTip },
    { key = "plates", default = true, reload = true, text = ns.TEXT.partPlates, tip = ns.TEXT.partPlatesTip },
    { key = "reminders", default = true, text = ns.TEXT.partAuras, tip = ns.TEXT.partAurasTip },
    { key = "unitPlayer", default = true, parent = "units", text = ns.TEXT.unitPlayer, tip = ns.TEXT.unitPlayerTip,
      header = ns.TEXT.units, headerTip = ns.TEXT.unitsTip },
    { key = "unitCast", default = true, text = ns.TEXT.unitCast, tip = ns.TEXT.unitCastTip, parent = "units" },
    { key = "unitBreath", default = true, text = ns.TEXT.unitBreath, tip = ns.TEXT.unitBreathTip, parent = "units" },
    { key = "unitPet", default = true, text = ns.TEXT.unitPet, tip = ns.TEXT.unitPetTip, parent = "units" },
    { key = "unitTarget", default = true, text = ns.TEXT.unitTarget, tip = ns.TEXT.unitTargetTip, parent = "units" },
    { key = "unitTargetTarget", default = true, text = ns.TEXT.unitTargetTarget, tip = ns.TEXT.unitTargetTargetTip, parent = "units" },
    { key = "unitFocus", default = true, text = ns.TEXT.unitFocus, tip = ns.TEXT.unitFocusTip, parent = "units" },
    { key = "unitFocusTarget", default = true, text = ns.TEXT.unitFocusTarget, tip = ns.TEXT.unitFocusTargetTip, parent = "units" },
    { key = "unitLookOut", default = true, text = ns.TEXT.unitLookOut, tip = ns.TEXT.unitLookOutTip, parent = "unitFocus" },
    { key = "unitSize", default = 100, min = 50, max = 200, step = 5, unit = "%", text = ns.TEXT.unitSize, tip = ns.TEXT.unitSizeTip, parent = "units" },
    { key = "unitAuras", default = true, text = ns.TEXT.unitAuras, tip = ns.TEXT.unitAurasTip, parent = "units" },
    { key = "unitBarrier", default = true, text = ns.TEXT.unitBarrier, tip = ns.TEXT.unitBarrierTip, parent = "units" },
    { key = "unitLost", default = true, text = ns.TEXT.unitLost, tip = ns.TEXT.unitLostTip, parent = "units" },
    { key = "unitDispel", default = true, text = ns.TEXT.unitDispel, tip = ns.TEXT.unitDispelTip, parent = "units" },
    -- Each frame's width, what it shows and when: chosen in Edit Mode's dialog (Units/Units.lua) and the setup, added
    -- below.
    { key = "auraWhite", default = {} }, -- the spells always shown on the unit frames: { [number] = name } (Units/Lists.lua)
    { key = "auraBlack", default = {} }, -- those never shown
    { key = "auraHidden", default = {} }, -- those out of sight in the game's list (Units/BuffList.lua)
    { key = "auraShow", default = {} }, -- first on the unit frames, nothing else about them changed
    { key = "auraHide", default = {} }, -- never on the unit frames, nothing else about them changed
    { key = "auraKept", default = {} }, -- every spell on the lists' window, with a mark or none, until its X
    { key = "groupBuffs", default = true, text = ns.TEXT.groupBuffs, tip = ns.TEXT.groupBuffsTip, header = ns.TEXT.group, parent = "group" },
    { key = "groupClass", default = true, text = ns.TEXT.groupClass, tip = ns.TEXT.groupClassTip, parent = "group" },
    { key = "groupBeside", default = true, text = ns.TEXT.groupBeside, tip = ns.TEXT.groupBesideTip, parent = "group" },
    -- Chosen in Edit Mode's dialog (Units/Group.lua).
    { key = "groupWidth", default = 960, min = 100, max = 2000 },
    { key = "groupHeight", default = 140, min = 30, max = 800 },
    { key = "groupUnitWidth", default = 240, min = 40, max = 400 },
    { key = "groupPreview", default = 5, min = 0, max = 40 },
    { key = "hideErrors", default = true, text = ns.TEXT.hideErrors, tip = ns.TEXT.hideErrorsTip },
    { key = "questMarks", default = true, text = ns.TEXT.questMarks, header = ns.TEXT.nameplates, tip = ns.TEXT.questMarksTip },
    { key = "mouseCooldown", default = true, text = ns.TEXT.mouseCooldown, tip = ns.TEXT.mouseCooldownTip,
      header = ns.TEXT.mouseRings, headerTip = ns.TEXT.mouseRingsTip },
    { key = "mouseCast", default = true, text = ns.TEXT.mouseCast, tip = ns.TEXT.mouseCastTip },
    { key = "meter", default = true, text = ns.TEXT.meter, tip = ns.TEXT.meterTip, header = ns.TEXT.meter },
    { key = "meterLocked", default = false, text = ns.TEXT.meterLocked, tip = ns.TEXT.meterLockedTip }, -- in its flyout too
    -- Chosen in the meter's own flyout (Meter/Controls.lua).
    { key = "meterMine", default = true },
    { key = "meterThreat", default = true },
    { key = "meterDamage", default = true },
    { key = "meterHealing", default = true },
    { key = "meterInterrupts", default = true },
    { key = "meterReset", default = true },
    { key = "meterHideRest", default = true },
    { key = "meterHideAlone", default = true },
    { key = "meterHover", default = true },
    { key = "meterOrder", default = "dps" },
    { key = "buffList", default = true, text = ns.TEXT.buffListOn, tip = ns.TEXT.buffListTip, header = ns.TEXT.buffList },
    { key = "aurasOpen", text = ns.TEXT.aurasOpen, header = ns.TEXT.reminders, tip = ns.TEXT.aurasOpenTip, button = function() ns.Guarded(ns.AuraLists.Open) end },
}
-- A switch changed (Settings.lua): the unit frames, the quest marks, the rings and the rest as the settings say; the
-- nameplates' own to them. The switch Nameplates off: the plates are the game's at once (on again: a /reload).
function ns.Changed(key, value)
    if key == "plates" then
        if value == false then ns.Safe("nameplates", ns.Nameplates.GiveBack) end
        ns.Guarded(ns.QuestMarks.Update)
    end
    if ns.Nameplates.Owns(key) then ns.Nameplates.Changed(key, value) end
    if key == "questMarks" then ns.Guarded(ns.QuestMarks.Update) end
    if key:match("^unit") then ns.Guarded(ns.Units.Apply) end
    if key:match("^group") or key == "unitBarrier" or key == "unitLost" or key == "unitDispel" then
        ns.Guarded(ns.Group.Apply)
    end
    if key == "hideErrors" then ns.Guarded(ns.ErrorText.Apply) end
    if key:match("^mouse") then ns.Safe("mouse rings", ns.MouseRings.Apply) end
    if key:match("^meter") then ns.Guarded(ns.Meter.Apply) end
    if key == "buffList" then ns.Guarded(ns.BuffList.Style) end
    if key == "reminders" or key == "groupBuffs" then ns.Guarded(ns.Reminders.Apply) end
end

-- Another profile's settings came in.
function ns.Replaced()
    ns.Nameplates.Replaced()
end

-- What each unit frame shows and how wide it is (Saneroki, 2026-11-18: "options there where you can define the width
-- of the unit frames and where you can define in edit mode what each frame includes"; each frame its own): a key per
-- frame of each (its setting and the suffix: unitTargetLevel), chosen in Edit Mode's dialog of that frame, no control on
-- the options page. At first as before: level, marker, name (none on your own), health and its share, each power now
-- and its share; no item level, the level shown at the top too, 240 wide. Last when it shows (Saneroki, 2026-11-18:
-- "the default is set to always visible and that there are options for the questlog, focus target, player and target
-- unit frames to be show only on mouseover, show always during combat, always show in party"), in the setup's step
-- too: Show only on mouseover off, so always in sight; under it Always show in combat and in a group, on.
ns.FRAME_SHOWS = {
    { suffix = "Width", text = ns.TEXT.frameWidth, default = 240, min = 120, max = 480, step = 10 },
    { suffix = "Level", show = "level", text = ns.TEXT.showLevel, default = true },
    { suffix = "LevelMax", show = "levelMax", text = ns.TEXT.showLevelMax, default = false, under = "Level", top = true },
    { suffix = "Mark", show = "mark", text = ns.TEXT.showMark, default = true },
    { suffix = "Gear", show = "gear", text = ns.TEXT.showGear, default = false },
    { suffix = "Name", show = "name", text = ns.TEXT.showName, default = true },
    { suffix = "Health", show = "health", text = ns.TEXT.showHealth, default = true },
    { suffix = "Percent", show = "percent", text = ns.TEXT.showPercent, default = true },
    { suffix = "PowerNow", show = "powerNow", text = ns.TEXT.showPowerNow, default = true },
    { suffix = "PowerMost", show = "powerMost", text = ns.TEXT.showPowerMost, default = false },
    { suffix = "PowerPercent", show = "powerPercent", text = ns.TEXT.showPowerPercent, default = true },
    -- Its resource's numbers at its bar's left, or its right (Saneroki, 2026-11-18: "a checkbox that toggles to have
    -- the class resource numbers left or right anchored").
    { suffix = "PowerRight", show = "powerRight", text = ns.TEXT.showPowerRight, default = false },
    { suffix = "Mouseover", text = ns.TEXT.showMouseover, default = false },
    { suffix = "Fight", text = ns.TEXT.showFight, default = true, under = "Mouseover" },
    { suffix = "Group", text = ns.TEXT.showGroup, default = true, under = "Mouseover" },
}
for _, frame in ipairs({ "unitPlayer", "unitTarget", "unitFocus" }) do
    for _, entry in ipairs(ns.FRAME_SHOWS) do
        local default = entry.default
        if frame == "unitPlayer" and entry.suffix == "Name" then default = false end -- your own frame names nobody
        ns.OPTIONS[#ns.OPTIONS + 1] = { key = frame .. entry.suffix, default = default, min = entry.min, max = entry.max,
                                        parent = entry.under and frame .. entry.under or nil }
    end
end

-- Ours or the game's in Core's dropdown Classic windows too (Saneroki, 2026-11-18: "The classic window dropdown will
-- have options to select unit frames, nameplates, party frames as well"), and on Onboarding's first page: each part a
-- tick, ticked while the game's own is the one kept; a pick sets the part's switch, the full screen stays as it is.
local PARTS = { { key = "units", text = ns.TEXT.partUnits }, { key = "group", text = ns.TEXT.group },
                { key = "plates", text = ns.TEXT.partPlates } }
local classic = {}
for index, part in ipairs(PARTS) do
    classic[index] = { text = part.text, stay = true,
        checked = function() return ns.options and ns.options[part.key] == false end,
        show = function() Core.Set(ns.name, part.key, false) end,
        back = function() Core.Set(ns.name, part.key, true) end }
end
Core.Classic.Add(ns.TEXT.title, function() return not ns.off and ns.options and classic or nil end)

-- Standing down, every part gives back what it stands in for: each step by itself, so one that fails keeps none of
-- the others from giving back.
function ns.GiveBack()
    ns.Safe("quest marks", ns.QuestMarks.Hide)
    ns.Safe("unit frames", ns.Units.GiveBack)
    ns.Safe("group frames", ns.Group.GiveBack)
    ns.Safe("aura lists", ns.AuraLists.Hide)
    ns.Safe("error text", ns.ErrorText.GiveBack)
    ns.Safe("mouse rings", ns.MouseRings.Hide)
    ns.Safe("meter", ns.Meter.GiveBack)
    ns.Safe("reminders", ns.Reminders.GiveBack)
    ns.Safe("buff list", ns.BuffList.Style)
    ns.Safe("nameplates", ns.Nameplates.GiveBack)
end

-- The game is about to write its settings: its nameplate and combat text CVars as they were before ours.
function ns.OnLogout()
    ns.Nameplates.Logout()
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

Core.Command("auras", "Edit tracked: every aura's marks and where its icon shows (/sane auras rejuv searches)", function(rest)
    if type(rest) == "string" and rest:find("%S") then return ns.Guarded(ns.AuraLists.Open, rest) end
    ns.Guarded(ns.AuraLists.Toggle)
end)
Core.Command("meter", "the threat and damage meter on or off", function() ns.Guarded(ns.Meter.Toggle) end)
Core.Command("reminders", "Edit tracked, for the buffs and debuffs shown on aura bars, health bars and nameplates", function() ns.Guarded(ns.AuraLists.Toggle) end)

function ns.OnLogin()
    if ns.options.plates ~= false then ns.Nameplates.Start() end
    ns.QuestMarks.Start()
    ns.Units.Start()
    ns.Group.Start()
    ns.ErrorText.Apply()
    ns.Safe("mouse rings", ns.MouseRings.Apply)
    ns.Meter.Build()
    ns.BuffList.Start()
    ns.Reminders.Start()
end
