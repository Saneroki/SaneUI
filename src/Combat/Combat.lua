local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_Combat): it needs Core and nothing else, and is
--  switched on and off in the game's addon list.
--
--  Everything about the fight will be here, each part in files of its own:
--  the unit frames (you, your target, its target, your focus, your pet), the
--  party and the raid, your buffs and debuffs, the nameplates, and what goes
--  with them (cast bars, totems, bosses). The plan is Doc/ideas/Combat.md.
--
--  Built so far: its window (Window.lua), docked in the screen's bottom middle
--  and filling the screen when the mouse is pushed against the middle half of
--  the bottom edge; full, it holds on Core's board (Board.lua) your talents
--  (Talents/) and your spellbook (Book/), our own windows as the game's, and
--  the window of a talent planner Sane UI knows (Core.Neighbours). Beside a
--  creature's nameplate, a mark while it belongs to an objective still to do
--  (QuestMarks.lua). Around the mouse, while they run, rings for the global
--  cooldown and your cast (MouseRings.lua). Our own frames for you, your target and your focus in a
--  nameplate's look, in place of the game's (Units/); the game's action bars
--  clean, their buttons' icons alone, and out of sight at rest with those frames (ActionBars.lua, Units/, Core.Rest);
--  its experience and stance bars gone, its menu bar on
--  mouseover (GameBars.lua). One frame of ours for your party and raid in place of the
--  game's two (Units/Group.lua). The threat and damage meter, a window on the screen and on the full screen
--  (Meter/). Reminders of buffs and debuffs on bars of their own (Reminders/). Each part falls back to the game's own when it fails
--  (Core's StandDown, GiveBack), and only reads what it shows: the game's live
--  data, and Core's data framework for anything kept (Doc/ideas/Data.md).
--  Our spellbook and talents are made after WoW: Forever's, so in Retail
--  neither is there (ns.Serves): no full screen there, the quest marks only.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Combat", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = "Combat",
    talents = Core.Word("TALENTS", "Talents"),
    spellbook = Core.Word("SPELLBOOK", "Spellbook"),
    planner = "Talent planner",
    book = "Spellbook and talents",
    keys = "Your spellbook and talents keys open ours",
    keysTip = "The keys you gave the game's spellbook, pet spellbook and talents open our own windows on Combat's full screen, and close them again. Off: they open the game's own windows, as before. Your key bindings stay as they are either way.",
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
    unitSize = "Unit frame size",
    unitSizeTip = "How large the three frames and their rows are.",
    unitRest = "Hide the unit frames at rest",
    unitRestTip = "Your frame, your target's and your focus's are out of sight while nothing goes on. Each shows while the mouse is on its place or while it has a cast or a timer to show, and they all show while your health or your resource is not full (rage and combo points: while you have any), in a fight, in a group and in Edit Mode. Out of sight they still take the mouse. Off: always in sight.",
    unitAuras = "Auras on the frames",
    unitAurasTip = "The auras that matter most, three of each kind, above a frame: buffs on its left, crowd control in its middle, debuffs on its right (on a foe yours). Those you mark Important come first, with a yellow glow; those you mark Unimportant never show. Right click an icon (out of a fight) to mark it, or to open your aura lists (/sane auras).",
    auraImportant = "Important",
    auraUnimportant = "Unimportant",
    auraHidden = "Hidden",
    buffList = "Your buffs and debuffs",
    buffListOn = "Marks and menu on the game's list",
    buffListTip = "The game's list of your buffs and debuffs at the top of the screen. Right click one, out of a fight, for its menu: Create reminder, Important (a yellow glow around it, and first on the unit frames), Unimportant (faded, and never on the unit frames), Hidden (out of sight until the mouse is on the list). Shift + right click cancels a buff, and in a fight a right click does, as in the game. Off: the game's list as it is, a right click cancels.",
    auraLists = "Aura lists...",
    auraFight = "In a fight the game keeps auras from addons: after it",
    listsTitle = "Aura lists",
    listsInput = "A spell's number, or its name (one of your own):",
    listsEmpty = "None yet.",
    listsPut = "%s: %s.",
    listsUnknown = "The game does not know that spell here by its name: type its number, or right click its icon on a unit frame.",
    listsRule = "On the unit frames the game lets Important and Unimportant act on the buffs of you, your group and friendly units, and on the debuffs of foes; on the rest it decides itself.",
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
    groupBuffs = "Your missing buffs",
    groupBuffsTip = "On the party and raid frames, an icon for each buff of your class a unit is missing: yours or the same from anyone (a paladin's blessings: only yours). In a fight the game hides auras from addons, so they stay as they were until it ends.",
    groupWidth = "Max width",
    groupHeight = "Max height",
    groupUnitWidth = "Max unit width",
    groupPreview = "Preview units",
    groupSamples = {
        first = { "Aldren", "Brisa", "Caelum", "Dorin", "Elsbeth", "Fenrick", "Gwyn", "Halden", "Ilsa", "Joren", "Kestra", "Lorcan" },
        last = { "Ashford", "Brightwater", "Crowley", "Dunmere", "Everhart", "Fallowfield", "Greymoor", "Hollow" },
    },
    samples = { player = "You", target = Core.Word("TARGET", "Target"), focus = Core.Word("FOCUS", "Focus"),
                targettarget = "Target's target", focustarget = "Focus's target", pet = Core.Word("PET", "Pet"),
                cast = "Cast bar", breath = Core.Word("BREATH_LABEL", "Breath") },
    actionBars = "Action bars",
    cleanBars = "Clean action bars",
    cleanBarsTip = "The game's action bars without their borders, decorations and backgrounds: only the buttons that hold something, each its icon alone. Empty buttons show while you drag something onto the bars, and in Edit Mode. Off: the game's own look.",
    barsRest = "Hide the action bars at rest",
    barsRestTip = "The game's action bars are out of sight while nothing goes on. The mouse on any of them shows them all, and they show while your health or your resource is not full (rage and combo points: while you have any), in a fight, in a group, in a vehicle, while something is dragged onto them, while you set your keys and in Edit Mode. Out of sight they still take the mouse, and their keys work. Off: always in sight.",
    hideTracking = "Hide the game's experience and reputation bars",
    hideTrackingTip = "The game's experience and reputation bars are gone from the screen. Off: the game's own.",
    hideStance = "Hide the game's stance bar",
    hideStanceTip = "The game's stance, form and aura buttons are gone from the screen. Their keys and your action bars still change them. Off: the game's own.",
    menuHover = "Menu bar on mouseover",
    menuHoverTip = "The game's menu bar is out of sight, and shows while the mouse is on it; in Edit Mode it always shows. Off: always in sight.",
    mouseRings = "Rings around the mouse",
    mouseRingsTip = "See-through rings around the mouse only while something runs, gone when it is over. They stand around the whole picture of the cursor, start and end at its tip, and grow with the game's Cursor Size.",
    mouseCooldown = "Global cooldown",
    mouseCooldownTip = "The inner, thinner ring, in white, fills while the global cooldown runs.",
    mouseCast = "Your cast",
    mouseCastTip = "The outer ring, in your class's colour, fills while you cast and empties while you channel, a bright line with a soft glow at its head. Interrupted, it goes at once.",
    meter = "Threat and damage meter",
    meterTip = "Your party or raid, you on top, each with their class, level, item level and name and a bar each for threat, damage, healing and interrupts. No background, and clicks go through it. With the mouse on it the buttons show at the end of the first line, that line drags it and its corner sizes it; the mouse wheel scrolls the others. Instead of the game's own damage meter.",
    meterPin = "The threat and damage meter on or off: here and on the screen.",
    meterKinds = { threat = "Threat", damage = "Damage", healing = "Healing", interrupts = "Interrupts" },
    meterTicks = { meterMine = "My self on top", meterThreat = "Show Threat", meterDamage = "Show Damage",
                   meterHealing = "Show Healing", meterInterrupts = "Show Interrupts",
                   meterReset = "Reset on new combat" },
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
    reminders = "Reminders",
    remindersOn = "Reminder bars",
    remindersTip = "Right click a buff or debuff and choose Create reminder: its icon then shows on an invisible reminder bar while its settings want it, when the aura is missing or active, in or out of a fight, or some seconds before it runs out. A bar is as wide as what shows on it, and is placed in Edit Mode. /sane reminders opens the list, with your bars: make as many as you like, and give each spell its bar. Off: no bars.",
    reminderCreate = "Create reminder",
    reminderEdit = "Edit reminder",
    reminderCancel = "Shift + right click cancels it",
    reminderBar = "Reminder bar %d",
    reminderNewBar = "New bar",
    reminderDeleteBar = "Delete bar",
    reminderNone = "None yet. Right click a buff or debuff and choose Create reminder.",
    reminderOnYou = "On you",
    reminderOnOther = "On the unit it was made on",
    reminderOnBar = "Bar",
    reminderMissing = "Display when missing",
    reminderActive = "Display when active",
    reminderWhen = "Combat",
    reminderCombat = { any = "In and out of combat", out = "Only show outside of combat", ["in"] = "Only show inside of combat" },
    reminderRest = "Don't show in resting areas",
    reminderEarly = "Offset time (seconds)",
    reminderDelete = "Delete reminder",
}

-- Our own spellbook and talents are made after the game's in WoW: Forever (Doc/guides/addon-standards.md, *Forever
-- and Retail*): the book after its book, whose art is that game's and which holds the spells of its flyouts loose
-- (C_SpellBook.IsSpellBookItemLooseFlyoutMember), the talents after its talents of two specializations, each with a
-- config of its own (C_SpecializationInfo.GetCombatConfigIDForSpecGroup). In a game without that (Retail) ours is
-- not there and the game's own stays: no window of it on the full screen, its key the game's (Board.Present); with
-- neither, no full screen at all (Window.lua), nor its settings.
local NEEDS = {
    spellbook = { "C_SpellBook", "IsSpellBookItemLooseFlyoutMember" },
    talents = { "C_SpecializationInfo", "GetCombatConfigIDForSpecGroup" },
}

-- Whether our window of that key ("spellbook", "talents") serves this game; without a key: either of them.
function ns.Serves(key)
    if key == nil then return ns.Serves("spellbook") or ns.Serves("talents") end
    local need = NEEDS[key]
    local api = need and rawget(_G, need[1])
    return type(api) == "table" and type(api[need[2]]) == "function"
end

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = (ns.Serves()
    and "the bottom edge no longer fills the screen; your talents and spellbook keys open the game's own again; "
    or "no quest marks beside nameplates; ") .. "the game's own unit, party and raid frames, action, experience, stance and menu bars and damage meter are back, a right click on a buff cancels it, no reminder bars"

local OPTIONS = {
    { key = "unitPlayer", default = true, text = ns.TEXT.unitPlayer, tip = ns.TEXT.unitPlayerTip,
      header = ns.TEXT.units, headerTip = ns.TEXT.unitsTip },
    { key = "unitCast", default = true, text = ns.TEXT.unitCast, tip = ns.TEXT.unitCastTip },
    { key = "unitBreath", default = true, text = ns.TEXT.unitBreath, tip = ns.TEXT.unitBreathTip },
    { key = "unitPet", default = true, text = ns.TEXT.unitPet, tip = ns.TEXT.unitPetTip },
    { key = "unitTarget", default = true, text = ns.TEXT.unitTarget, tip = ns.TEXT.unitTargetTip },
    { key = "unitTargetTarget", default = true, text = ns.TEXT.unitTargetTarget, tip = ns.TEXT.unitTargetTargetTip },
    { key = "unitFocus", default = true, text = ns.TEXT.unitFocus, tip = ns.TEXT.unitFocusTip },
    { key = "unitFocusTarget", default = true, text = ns.TEXT.unitFocusTarget, tip = ns.TEXT.unitFocusTargetTip },
    { key = "unitSize", default = 100, min = 50, max = 200, step = 5, unit = "%", text = ns.TEXT.unitSize, tip = ns.TEXT.unitSizeTip },
    { key = "unitRest", default = true, text = ns.TEXT.unitRest, tip = ns.TEXT.unitRestTip },
    { key = "unitAuras", default = true, text = ns.TEXT.unitAuras, tip = ns.TEXT.unitAurasTip },
    { key = "unitBarrier", default = true, text = ns.TEXT.unitBarrier, tip = ns.TEXT.unitBarrierTip },
    { key = "unitLost", default = true, text = ns.TEXT.unitLost, tip = ns.TEXT.unitLostTip },
    { key = "unitDispel", default = true, text = ns.TEXT.unitDispel, tip = ns.TEXT.unitDispelTip },
    { key = "auraWhite", default = {} }, -- the spells always shown on the unit frames: { [number] = name } (Units/Lists.lua)
    { key = "auraBlack", default = {} }, -- those never shown
    { key = "auraHidden", default = {} }, -- those out of sight in the game's list (Units/BuffList.lua)
    { key = "group", default = true, text = ns.TEXT.group, tip = ns.TEXT.groupTip, header = ns.TEXT.group },
    { key = "groupBuffs", default = true, text = ns.TEXT.groupBuffs, tip = ns.TEXT.groupBuffsTip },
    -- Chosen in Edit Mode's dialog (Units/Group.lua).
    { key = "groupWidth", default = 960, min = 100, max = 2000 },
    { key = "groupHeight", default = 140, min = 30, max = 800 },
    { key = "groupUnitWidth", default = 240, min = 40, max = 400 },
    { key = "groupPreview", default = 5, min = 0, max = 40 },
    { key = "cleanBars", default = true, text = ns.TEXT.cleanBars, header = ns.TEXT.actionBars, tip = ns.TEXT.cleanBarsTip },
    { key = "barsRest", default = true, text = ns.TEXT.barsRest, tip = ns.TEXT.barsRestTip },
    { key = "hideTracking", default = true, text = ns.TEXT.hideTracking, tip = ns.TEXT.hideTrackingTip },
    { key = "hideStance", default = true, text = ns.TEXT.hideStance, tip = ns.TEXT.hideStanceTip },
    { key = "menuHover", default = true, text = ns.TEXT.menuHover, tip = ns.TEXT.menuHoverTip },
    { key = "questMarks", default = true, text = ns.TEXT.questMarks, header = ns.TEXT.nameplates, tip = ns.TEXT.questMarksTip },
    { key = "mouseCooldown", default = true, text = ns.TEXT.mouseCooldown, tip = ns.TEXT.mouseCooldownTip,
      header = ns.TEXT.mouseRings, headerTip = ns.TEXT.mouseRingsTip },
    { key = "mouseCast", default = true, text = ns.TEXT.mouseCast, tip = ns.TEXT.mouseCastTip },
    { key = "meter", default = true, text = ns.TEXT.meter, tip = ns.TEXT.meterTip, header = ns.TEXT.meter },
    -- Chosen in the meter's own flyout (Meter/Controls.lua).
    { key = "meterMine", default = true },
    { key = "meterThreat", default = true },
    { key = "meterDamage", default = true },
    { key = "meterHealing", default = true },
    { key = "meterInterrupts", default = true },
    { key = "meterReset", default = true },
    { key = "meterOrder", default = "dps" },
    { key = "buffList", default = true, text = ns.TEXT.buffListOn, tip = ns.TEXT.buffListTip, header = ns.TEXT.buffList },
    { key = "reminders", default = true, text = ns.TEXT.remindersOn, tip = ns.TEXT.remindersTip, header = ns.TEXT.reminders },
}
if ns.Serves() then
    table.insert(OPTIONS, 1, { key = "keys", default = true, text = ns.TEXT.keys, header = ns.TEXT.book, tip = ns.TEXT.keysTip })
    -- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
    Core.Edge.Options(OPTIONS, 1)
end
-- Core's window takes the section in by itself (Edge.lua); the keys bound anew, the quest marks looked at again,
-- the unit frames and action bars as the settings say.
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "keys" then ns.Guarded(ns.Keys.Bind) end
    if key == "questMarks" then ns.Guarded(ns.QuestMarks.Update) end
    if key:match("^unit") then ns.Guarded(ns.Units.Apply) end
    if key:match("^group") or key == "unitBarrier" or key == "unitLost" or key == "unitDispel" then
        ns.Guarded(ns.Group.Apply)
    end
    if key == "cleanBars" or key == "barsRest" then ns.Guarded(ns.ActionBars.Apply) end
    if key == "hideTracking" or key == "hideStance" or key == "menuHover" then ns.Guarded(ns.GameBars.Apply) end
    if key:match("^mouse") then ns.Safe("mouse rings", ns.MouseRings.Apply) end
    if key:match("^meter") then ns.Guarded(ns.Meter.Apply) end
    if key == "buffList" then ns.Guarded(ns.BuffList.Apply) end
    if key == "reminders" then ns.Guarded(ns.Reminders.Apply) end
end })

-- Standing down, the game's keys open the game's windows again first (ours do nothing now), every window on the
-- full screen gives back what it lent, and the window goes: each step by itself, so one that fails keeps none of
-- the others from giving back.
function ns.GiveBack()
    ns.Safe("keys", ns.Keys.Leave)
    ns.Safe("board", ns.Board.Leave)
    ns.Safe("window", ns.Window.Hide)
    ns.Safe("quest marks", ns.QuestMarks.Hide)
    ns.Safe("unit frames", ns.Units.GiveBack)
    ns.Safe("group frames", ns.Group.GiveBack)
    ns.Safe("aura lists", ns.AuraLists.Hide)
    ns.Safe("action bars", ns.ActionBars.GiveBack)
    ns.Safe("game bars", ns.GameBars.GiveBack)
    ns.Safe("mouse rings", ns.MouseRings.Hide)
    ns.Safe("meter", ns.Meter.GiveBack)
    ns.Safe("reminders", ns.Reminders.GiveBack)
    ns.Safe("buff list", ns.BuffList.Apply)
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

Core.Command("auras", "your aura lists: important, unimportant, hidden", function() ns.Guarded(ns.AuraLists.Toggle) end)
Core.Command("meter", "the threat and damage meter on or off", function() ns.Guarded(ns.Meter.Toggle) end)
Core.Command("reminders", "your reminders of buffs and debuffs", function() ns.Guarded(ns.ReminderEditor.Toggle) end)

function ns.OnLogin()
    ns.Window.Build()
    ns.Board.Follow()
    ns.Keys.Start()
    ns.QuestMarks.Start()
    ns.Units.Start()
    ns.Group.Start()
    ns.ActionBars.Start()
    ns.GameBars.Start()
    ns.Safe("mouse rings", ns.MouseRings.Apply)
    ns.Meter.Build()
    ns.BuffList.Start()
    ns.Reminders.Start()
end
