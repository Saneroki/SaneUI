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
--  (QuestMarks.lua). Our own frames for you, your target and your focus in a
--  nameplate's look, in place of the game's (Units/); the game's action bars
--  clean, their buttons' icons alone (ActionBars.lua). Each part falls back to the game's own when it fails
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
    unitsTip = "Our own frames in place of the game's, in the look of a nameplate, green: the level and raid marker on the left, then the name, the health and how much is left on the right. Under a frame, as a cast bar under a nameplate, a row with the name of its target or your pet; while you cast or run out of breath, that too under your own. A click targets, a right click opens the game's menu. Placed in the game's Edit Mode.",
    unitPlayer = "Your frame",
    unitPlayerTip = "Your own frame instead of the game's: your level and health, no name. The game's totems stay where the game's frame was: move that in Edit Mode. Off: the game's own frame.",
    unitCast = "Your cast bar",
    unitCastTip = "Part of your frame while you cast, under your powers: the spell's icon and name and the seconds left, instead of the game's cast bar. Off: the game's own.",
    unitBreath = "Your breath bar",
    unitBreathTip = "Part of your frame while the game counts down your breath, your fatigue or a feign death: what it counts and the seconds left, instead of the game's bars at the top of the screen. Off: the game's own.",
    unitPet = "Your pet",
    unitPetTip = "Under your frame while you have a pet: a row with its health and name, instead of the game's pet frame. Off: the game's pet frame.",
    unitTarget = "Your target's frame",
    unitTargetTip = "Your target's frame instead of the game's; with the game's go its auras and its cast bar. Off: the game's own frame.",
    unitTargetTarget = "Your target's target",
    unitTargetTargetTip = "Under your target's frame while your target has a target: a row with that one's health and name. A click targets it.",
    unitFocus = "Your focus's frame",
    unitFocusTip = "Your focus's frame instead of the game's; with the game's go its auras and cast bar. Off: the game's own frame.",
    unitFocusTarget = "Your focus's target",
    unitFocusTargetTip = "Under your focus's frame while your focus has a target: a row with that one's health and name.",
    unitSize = "Unit frame size",
    unitSizeTip = "How large the three frames and their rows are.",
    unitAuras = "Auras on the frames",
    unitAurasTip = "The auras that matter most, three of each kind: debuffs above a frame from its left (on a foe yours), buffs above it from its right, crowd control right of it. Right click an icon (out of a fight) to always or never show it, or to open your aura lists (/sane auras).",
    auraAlways = "Always show",
    auraNever = "Never show",
    auraLists = "Aura lists...",
    auraFight = "In a fight the game keeps auras from addons: after it",
    listsTitle = "Aura lists",
    listsInput = "A spell's number, or its name (one of your own):",
    listsEmpty = "None yet.",
    listsPut = "%s: %s.",
    listsUnknown = "The game does not know that spell here by its name: type its number, or right click its icon on a unit frame.",
    listsRule = "The game lets the lists act on the buffs of you, your group and friendly units, and on the debuffs of foes; on the rest it decides itself.",
    samples = { player = "You", target = Core.Word("TARGET", "Target"), focus = Core.Word("FOCUS", "Focus"),
                targettarget = "Target's target", focustarget = "Focus's target", pet = Core.Word("PET", "Pet"),
                cast = "Cast bar", breath = Core.Word("BREATH_LABEL", "Breath") },
    actionBars = "Action bars",
    cleanBars = "Clean action bars",
    cleanBarsTip = "The game's action bars without their borders, decorations and backgrounds: only the buttons that hold something, each its icon alone. Empty buttons show while you drag something onto the bars, and in Edit Mode. Off: the game's own look.",
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
    or "no quest marks beside nameplates; ") .. "the game's own unit frames and action bars are back"

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
    { key = "unitAuras", default = true, text = ns.TEXT.unitAuras, tip = ns.TEXT.unitAurasTip },
    { key = "auraWhite", default = {} }, -- the spells always shown on the unit frames: { [number] = name } (Units/Lists.lua)
    { key = "auraBlack", default = {} }, -- those never shown
    { key = "cleanBars", default = true, text = ns.TEXT.cleanBars, header = ns.TEXT.actionBars, tip = ns.TEXT.cleanBarsTip },
    { key = "questMarks", default = true, text = ns.TEXT.questMarks, header = ns.TEXT.nameplates, tip = ns.TEXT.questMarksTip },
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
    if key == "cleanBars" then ns.Guarded(ns.ActionBars.Apply) end
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
    ns.Safe("aura lists", ns.AuraLists.Hide)
    ns.Safe("action bars", ns.ActionBars.GiveBack)
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

Core.Command("auras", "your aura lists for the unit frames: always and never shown", function() ns.Guarded(ns.AuraLists.Toggle) end)

function ns.OnLogin()
    ns.Window.Build()
    ns.Board.Follow()
    ns.Keys.Start()
    ns.QuestMarks.Start()
    ns.Units.Start()
    ns.ActionBars.Start()
end
