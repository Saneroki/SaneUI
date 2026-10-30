-- Runs the Speed Leveling key against the stand-in client (wowstub.lua): what is wanted around you and in which order
-- (the guide's steps, the quests' objectives from Core's data nearest first, the creatures the game marks, the NPCs
-- to hand in to, a quest Core lacks by the game's own words), the macros of Find written into a chain for the 255
-- character limit, whether the target and the thing in front of you are wanted, the header's snippet as the game runs
-- it (which action each state puts on the key), the keys, the hint, the hearth and the quest items, the quest givers
-- (a guide's quests taken and handed in), the game's settings lent and put back, the switches, a fight, and standing
-- down.
-- The guide format's words come from Core (Core.Neighbours.KNOWN.guide); the test names none of its own.
-- Usage, from the project folder:  lua5.1 dev/tests/speedleveling.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
bit = require("encoding").bit -- the game's bit library (Unlock.lua reads it at load)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  The secure parts, as the game runs them
-------------------------------------------------------------------------------
local methods = W.methods
-- Enough of a font string and a frame for the guide's view to be drawn beside the key.
function methods:GetStringHeight() return self._text and self._text ~= "" and 14 or 0 end
function methods:GetStringWidth() return #(self._text or "") * 6 end
function methods:SetAlpha(alpha) self._alpha = alpha end
function methods:SetScale(scale) self._scale = scale end
function methods:SetHeight(height) self._height = height end
function methods:GetHeight() return self._height end
function methods:SetWidth(width) self._width = width end
function methods:GetWidth() return self._width end
function methods:SetSize(width, height) self._width, self._height = width, height end
function methods:SetRotation(angle) self._rotation = angle end
function methods:SetTextColor(r, g, b) self._color = { r, g, b } end
function methods:GetLeft() return 900 end
function methods:GetTop() return 600 end
function methods:GetBottom() return 300 end
GetPlayerFacing = function() return 0 end
function methods:SetAttribute(name, value)
    self._attributes = self._attributes or {}
    self._attributes[name] = value
    if self._changed then self._changed(name, value) end
end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end

local overrides = {} -- [key] = its action while an override binding of the header's is on it
local function Snippet(body, arguments)
    return assert(loadstring("return function(" .. arguments .. ") " .. body .. " end"))()
end
W.templates.SecureHandlerAttributeTemplate = function(frame)
    local handle = {}
    function handle:GetAttribute(name) return frame:GetAttribute(name) end
    function handle:SetAttribute(name, value) frame:SetAttribute(name, value) end
    function handle:ClearBindings() for key in pairs(overrides) do overrides[key] = nil end end
    function handle:SetBinding(priority, key, action) overrides[key] = action end
    function handle:SetBindingClick(priority, key, name) overrides[key] = "CLICK " .. name .. ":LeftButton" end
    function handle:RunAttribute(name, ...) return Snippet(frame:GetAttribute(name), "self, ...")(handle, ...) end
    frame._changed = function(name, value)
        if name:match("^_") then return end
        local body = frame:GetAttribute("_onattributechanged")
        if body then Snippet(body, "self, name, value")(handle, name, value) end
    end
end
local drivers = {}
function RegisterStateDriver(frame, state, values) drivers[frame] = drivers[frame] or {} drivers[frame][state] = values end
function UnregisterStateDriver(frame, state) if drivers[frame] then drivers[frame][state] = nil end end
function ClearOverrideBindings() for key in pairs(overrides) do overrides[key] = nil end end
local bound = {}
function GetBindingKey(command) return unpack(bound[command] or {}) end

-- Units: the target and the nameplates; a quest text makes the game mark one.
local units = {}
UnitExists = function(unit) return units[unit] ~= nil or unit == "player" end
UnitIsPlayer = function(unit) return unit == "player" or (units[unit] and units[unit].player) or false end
UnitIsDead = function(unit) return units[unit] and units[unit].dead or false end
UnitCanAttack = function(_, unit) return units[unit] and units[unit].foe or false end
UnitIsFriend = function(_, unit) return units[unit] ~= nil and not units[unit].foe and not units[unit].neutral end
UnitCanAssist = function(_, unit) return units[unit] ~= nil and not units[unit].foe and not units[unit].neutral end
C_Timer.NewTicker = function(every, fn)
    local ticker = { cancelled = false }
    function ticker:Cancel() self.cancelled = true end
    local function Tick()
        if ticker.cancelled then return end
        fn(ticker)
        if not ticker.cancelled then C_Timer.After(every, Tick) end
    end
    C_Timer.After(every, Tick)
    return ticker
end
-- Items: which reach a unit (a use with a range), whether the target is within it, the spell each casts.
local reach = {} -- [item] = true (in reach), false (too far); nil: no range at all
C_Item.ItemHasRange = function(id) return reach[id] ~= nil end
C_Item.IsItemInRange = function(id) return reach[id] end
C_Item.GetItemSpell = function(id) return "Use", 90000 + id end
UnitName = function(unit) if units[unit] then return units[unit].name end return "Tester" end
UnitGUID = function(unit) return units[unit] and units[unit].guid or nil end
local spoils = {} -- [GUID] = the corpse has loot for you
CanLootUnit = function(guid) return spoils[guid] == true, spoils[guid] == true end
Enum.TooltipDataLineType = { QuestObjective = 8 }
C_TooltipInfo = { GetUnit = function(unit)
    local quest = units[unit] and units[unit].quest
    return { lines = quest and { { type = 8, leftText = quest } } or {} }
end }
C_QuestLog = rawget(_G, "C_QuestLog") or {}
C_QuestLog.UnitIsRelatedToActiveQuest = function(unit)
    return units[unit] ~= nil and (units[unit].quest ~= nil or units[unit].related == true)
end

-- The quest log.
local log = { entries = {}, objectives = {}, complete = {} }
C_QuestLog.GetNumQuestLogEntries = function() return #log.entries end
C_QuestLog.GetInfo = function(index) return log.entries[index] end
C_QuestLog.IsComplete = function(quest) return log.complete[quest] == true end
C_QuestLog.GetQuestObjectives = function(quest) return log.objectives[quest] end
C_QuestLog.IsOnQuest = function() return false end
C_QuestLog.IsQuestFlaggedCompleted = function() return false end
C_QuestLog.GetTitleForQuestID = function() return nil end
log.entries = { { isHeader = true, title = "Elwynn" }, { questID = 10 }, { questID = 11 }, { questID = 12 } }
log.objectives[10] = { { text = "Kobold Vermin slain: 2/10", type = "monster", finished = false },
                       { text = "Candle: 0/8", type = "item", finished = false },
                       { text = "Ley Line: 0/1", type = "object", finished = false } }
log.objectives[11] = {}
log.objectives[12] = { { text = "Wolf slain: 8/8", type = "monster", finished = true } }
log.complete[11] = true

-- An orc warrior of the Horde, level 5.
UnitRace = function() return "Orc", "Orc", 2 end
UnitClass = function() return "Warrior", "WARRIOR", 1 end
UnitFactionGroup = function() return "Horde" end
UnitLevel = function() return 5 end
UnitXP = function() return 0 end
UnitXPMax = function() return 400 end

-- The player's place: a map, and where the game says the player stands on it (for nearest-by-zone).
local here = { map = 1411, x = 50, y = 50 }
C_Map = rawget(_G, "C_Map") or {}
C_Map.GetBestMapForUnit = function() return here.map end
C_Map.GetMapInfo = function(id) return { mapID = id, name = "Zone", mapType = 3 } end
C_Map.GetPlayerMapPosition = function() return { x = here.x / 100, y = here.y / 100 } end

-- Items in your bags, usable unless named, their cooldowns; spells you know; the quest items of the log.
local unusable, cooling, learned = {}, {}, {}
C_Item.IsUsableItem = function(id) return not unusable[id] end
C_Container = { GetItemCooldown = function(id) return cooling[id] and 100 or 0, cooling[id] or 0, 1 end }
IsPlayerSpell = function(id) return learned[id] == true end
C_Spell.GetSpellCooldown = function() return { startTime = 0, duration = 0 } end
local specials = {}
GetQuestLogSpecialItemInfo = function(index)
    return specials[index] and ("|Hitem:" .. specials[index] .. ":::|h[Item]|h") or nil, 134400, 1, false
end
local language = "enUS"
GetLocale = function() return language end
IsQuestLogSpecialItemInRange = function() return 1 end

-- The game's settings the key lends: its interact key, and Click-to-Move (off, as most players have it).
W.cvarInfo.softTargetInteract = { default = "2" }
W.cvarInfo.autointeract = { default = "0" }
W.cvarInfo.SoftTargetInteractArc = { default = "0" }
W.cvarInfo.SoftTargetInteractRange = { default = "10" }
W.cvars.autointeract = "0"

-------------------------------------------------------------------------------
--  Core, its data, and the module
-------------------------------------------------------------------------------
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local Core = SaneUI.Core

-- The leveling guide Sane UI knows is NOT installed: the module stands on its own. A guide of its own is pasted.
local known = Core.Neighbours.KNOWN.guide
local records = {
    Quests = {
        [10] = { objectives = { { index = 1, kind = "kill", what = 100 }, { index = 2, kind = "loot", what = 500 },
                                { index = 3, kind = "object", what = 7001 } },
                 finishNPCs = { { npc = 300 } }, finishObjects = { { object = 7002 } } },
        [11] = { objectives = {}, finishNPCs = { { npc = 301, side = "horde" }, { npc = 302, side = "alliance" } },
                 finishObjects = { { object = 8000, side = "alliance" }, { object = 8001, side = "horde" } } },
        [12] = { objectives = { { index = 1, kind = "kill", what = 105 } }, finishNPCs = { { npc = 303 } } },
    },
    NPCs = { [100] = { name = "Kobold Vermin" }, [105] = { name = "Prowler" }, [200] = { name = "Kobold Worker" },
             [201] = { name = "Kobold Laborer" }, [202] = { name = "Kobold Tunneler" }, [204] = { name = "Young Wolf" },
             [300] = { name = "Marshal Dughan" }, [301] = { name = "Gar'Thok" }, [302] = { name = "Deputy Willem" },
             [303] = { name = "Eagan Peltskinner" } },
    Drops = {
        ["npc:200"] = { items = { { item = 500, how = "loot", chance = 40 } } },
        ["npc:201"] = { items = { { item = 500, how = "loot", chance = 90 } } },
        ["npc:202"] = { items = { { item = 500, how = "loot", chance = 60 } } },
        ["npc:204"] = { items = { { item = 500, how = "skin", chance = 99 } } },
        ["object:7"] = { items = { { item = 500, how = "gather", chance = 100 } } },
    },
    -- Where creatures live, for nearest-by-zone (shares of 100 of the map 1411; the player stands at 50,50).
    Spawns = {
        ["npc:100"] = { points = { { map = 1411, x = 50, y = 51 } } }, -- the kill, nearest
        ["npc:201"] = { points = { { map = 1411, x = 52, y = 52 } } }, -- a dropper, near
        ["npc:200"] = { points = { { map = 1411, x = 80, y = 80 } } }, -- a dropper, far
        ["npc:202"] = { points = { { map = 1411, x = 90, y = 10 } } }, -- a dropper, farther
        -- Herbs and ore (Gathering.lua): a Peacebloom here and in the next zone (1413), where three Steelbloom grow
        -- and one Iron Deposit.
        ["object:1617"] = { points = { { map = 1411, x = 1, y = 1 }, { map = 1413, x = 1, y = 1 } } },
        ["object:1623"] = { points = { { map = 1413, x = 2, y = 2 }, { map = 1413, x = 3, y = 3 }, { map = 1413, x = 4, y = 4 } } },
        ["object:1735"] = { points = { { map = 1413, x = 5, y = 5 } } },
    },
    Objects = { [1617] = { kind = "herb", skill = 182, skillLevel = 1 }, [1623] = { kind = "herb", skill = 182, skillLevel = 115 },
                [1735] = { kind = "ore", skill = 186, skillLevel = 125 } },
    SkillLines = { [182] = { name = "Herbalism" }, [186] = { name = "Mining" } },
}
local byKind = { herb = { 1617, 1623 }, ore = { 1735 } }
local byItem = { [500] = { "npc:200", "npc:201", "npc:202", "npc:204", "object:7" } }
local realSet = Core.Data.Set
Core.Data.Set = function(name)
    if not records[name] then return realSet(name) end
    local handle = {}
    function handle:Get(key, field)
        local record = records[name][key]
        if field then return record and record[field] end
        return record
    end
    function handle:Keys(index, value)
        if name == "Drops" and index == "byItem" then return byItem[value] or {} end
        if name == "Objects" and index == "byKind" then return byKind[value] or {} end
        return {}
    end
    return handle
end

local ns = W.LoadAddon(root, "SpeedLeveling", "SaneUI_SpeedLeveling")
Core.Data.Set = realSet
W.Fire("ADDON_LOADED", "SaneUI_SpeedLeveling")

-- A pasted guide with a step at hand: an NPC to talk to, a quest to take and one to hand in, a creature to kill.
local C = {}
for theirs, ours in pairs(known.commands) do if not C[ours] then C[ours] = theirs end end
local function L(command, values, words) return "." .. C[command] .. " " .. values .. (words and (" >> " .. words) or "") end
local GUIDE = table.concat({
    "#forever", "#" .. "name Test", "#" .. "group G", "step",
    L("friend", "Marshal McBride"), L("take", "40"), L("handin", "41,2"), L("foe", "Defias Thug"),
}, "\n")
W.Fire("PLAYER_LOGIN")
ns.Guide.AddAll(ns.Format.Parts(GUIDE), false)
local Key, Wanted, Items, Quests = ns.Key, ns.Wanted, ns.Items, ns.Quests
local header, find, fight = _G[Key.HEADER], _G[Key.FIND], _G[Key.FIGHT]
local FIND, FIGHT = "CLICK " .. Key.FIND .. ":LeftButton", "CLICK " .. Key.FIGHT .. ":LeftButton"

local function Joined(list) return table.concat(list, ", ") end
local function Printed(text)
    for _, line in ipairs(W.printed) do if line:find(text, 1, true) then return true end end
    return false
end

-------------------------------------------------------------------------------
--  The start
-------------------------------------------------------------------------------
check(ns.title == "Speed Leveling" and SaneUI.SpeedLeveling == ns, "the module is Speed Leveling")
check(header and find._template == "SecureActionButtonTemplate", "the header and Find are made")
check(_G["BINDING_NAME_" .. FIND] == ns.TEXT.binding, "the key's words in the game's key bindings")
check(Printed("has no key on this account"), "with no key, the module says how to give it one")
check(_G[Key.LINK .. 2] and _G[Key.LINK .. (Key.LINKS + 1)], "the chain's buttons are made")

local conditions = drivers[header].mode
check(conditions:find("^%[@softinteract,exists,dead%] loot; "), "loot comes first while Loot first is on")
check(conditions:find("%[@target,harm,nodead,combat%] fight; %[@softinteract,exists,help,nodead%] near; "
    .. "%[@target,harm,nodead%] foe; %[@target,noharm,nodead%] friend; %[@target,exists,dead%] corpse; find$"),
    "then a foe in a fight, an NPC in front of you, a foe, a friend, a corpse, else find: " .. conditions)
check(W.cvars.softTargetInteract == "3", "Loot first: the interact key on")
check(ns.options.foundCVars.softTargetInteract.was == "2", "what the interact key was is kept")
check(fight:GetAttribute("macrotext") == "/tm [harm,nodead] !8\n/startattack [harm,nodead]", "Fight marks and attacks")

-------------------------------------------------------------------------------
--  What is wanted, in order
-------------------------------------------------------------------------------
-- The guide's NPC first, then the NPCs to hand finished quests in to (quest 11, Horde side), then the guide's
-- creature, then the quests' creatures (to kill, then the droppers) nearest first by their zone.
local names = Wanted.Names()
check(names[1] == "Marshal McBride", "the guide's NPC first")
check(names[2] == "Gar'Thok", "then the NPC of a finished quest, of your side")
check(Joined(names):find("Gar'Thok, Defias Thug, Kobold Vermin,", 1, true), "then the guide's creature, then the quests'")
-- The quest's creatures nearest first: the kill (50,51) then the droppers Laborer (52,52), Worker (80,80), Tunneler (90,10).
check(Joined(names):find("Kobold Vermin, Kobold Laborer, Kobold Worker, Kobold Tunneler", 1, true),
    "the creatures nearest first by their spawn: " .. Joined(names))
check(not Joined(names):find("Young Wolf") and not Joined(names):find("Prowler") and not Joined(names):find("Dughan"),
    "no skinner, no finished kill, no NPC of an open quest")

-- A creature the game marks on a nameplate, which Core does not know: before the NPCs... after? it is near, so among them.
units.nameplate1 = { name = "Stonetusk Boar", quest = "Stonetusk Boar slain: 1/5" }
units.nameplate2 = { name = "Someone", player = true, quest = "Someone slain: 0/1" }
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
names = Wanted.Names()
check(Joined(names):find("Stonetusk Boar", 1, true) and not Joined(names):find("Someone"),
    "a marked creature is wanted, a player never")

-- A quest Core's data does not hold: the creature its objective names in the game's own words.
do
    local quests = records.Quests
    records.Quests = { [11] = quests[11] } -- keep 11 (for the handin NPC); drop 10 and 12
    Wanted.Changed()
    names = Wanted.Names()
    check(Joined(names):find("Kobold Vermin", 1, true), "a quest Core lacks: the creature its words name")
    check(not Joined(names):find("Candle") and not Joined(names):find("Ley Line"), "not an item or an object objective")
    records.Quests = quests
    Wanted.Changed()
end

-- Retail, no quest data at all: the guide's names and the game's words and marks; nothing fails.
do
    local quests = records.Quests
    records.Quests = {}
    W.Play("retail")
    Wanted.Changed()
    names = Wanted.Names()
    check(names[1] == "Marshal McBride" and Joined(names):find("Defias Thug", 1, true), "Retail: the guide's names")
    check(Joined(names):find("Kobold Vermin", 1, true) and Joined(names):find("Stonetusk Boar", 1, true),
        "the game's own objective words and marks")
    records.Quests = quests
    W.Play("forever")
    Wanted.Changed()
end

-------------------------------------------------------------------------------
--  The macros of Find, in a chain for the 255 character limit
-------------------------------------------------------------------------------
local texts = Key.Macros({ "Kobold Vermin", "Bad;Name", "Marshal McBride" })
check(texts[1]:find("^/cleartarget\n/targetexact %[noexists%]%[dead%] Kobold Vermin\n"
    .. "/targetexact %[noexists%]%[dead%] Marshal McBride\n"), "Find: let go, then the names (a bad one dropped)")
check(texts[1]:find("/tm %[exists%] !8\n/startattack %[harm,nodead%]$"), "the ending: mark and attack")
check(Joined(Key.Macros({})) == "" or Key.Macros({})[1] == "", "nothing wanted: an empty macro")

-- Many long names: the first fill Find, the rest the chain, each clicked from the one before.
local many = {}
for index = 1, 80 do many[index] = ("A Rather Long Creature Name %02d"):format(index) end
texts = Key.Macros(many)
check(#texts[1] <= Key.ROOM, "Find's macro fits the 255 the game runs: " .. #texts[1])
check(texts[1]:find("/click [noexists][dead] " .. Key.LINK .. "2", 1, true), "Find clicks the next of the chain")
check(texts[2] and #texts[2] <= Key.ROOM and texts[2]:find("Name", 1, true), "the chain holds more names")
check(texts[1]:find("Name 01", 1, true) and not texts[1]:find("Name 80", 1, true), "the first names first")

Core.Set(ns.name, "skull", false)
check(not Key.Macros({ "Kobold Vermin" })[1]:find("/tm", 1, true), "no skull: no mark")
check(fight:GetAttribute("macrotext") == "/startattack [harm,nodead]", "no skull: Fight only attacks")
Core.Set(ns.name, "skull", true)

-- The moment before a press: written from what is wanted now, out of a fight only.
find._scripts.PreClick(find, "LeftButton", true)
check(find:GetAttribute("macrotext"):find("Marshal McBride", 1, true), "before a press: the guide's step now")
W.combat = true
find._scripts.PreClick(find, "LeftButton", true)
check(find:GetAttribute("macrotext"):find("Marshal McBride", 1, true), "in a fight the last macro stays")
W.combat = false

-------------------------------------------------------------------------------
--  The key: what each state puts on it
-------------------------------------------------------------------------------
bound[FIND] = { "E", "SHIFT-E" }
W.Fire("UPDATE_BINDINGS")
check(header:GetAttribute("keys") == 2 and header:GetAttribute("key1") == "E", "the key's keys onto the header")

header:SetAttribute("state-mode", "loot")
check(overrides.E == "INTERACTTARGET" and overrides["SHIFT-E"] == "INTERACTTARGET", "a corpse with loot: Interact With Target")
header:SetAttribute("state-mode", "near")
check(overrides.E == "INTERACTTARGET", "an NPC in front of you: talk at once")
units.target = { name = "Young Wolf" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "foe")
check(header:GetAttribute("wanted") == false and overrides.E == FIND, "a foe nobody wants: Find")
units.target = { name = "Kobold Laborer" }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("wanted") == true and overrides.E == FIGHT, "a wanted foe: Fight")
header:SetAttribute("state-mode", "fight")
check(overrides.E == FIGHT, "in a fight any living foe: Fight")
units.target = { name = "Marshal McBride" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "friend")
check(overrides.E == "INTERACTTARGET", "a wanted NPC: talk")
Core.Set(ns.name, "talk", false)
check(overrides.E == FIND and not drivers[header].mode:find("near", 1, true), "Talk to NPCs off: Find, and no near state")
Core.Set(ns.name, "talk", true)

-------------------------------------------------------------------------------
--  The things of the world your quests want, in front of you
-------------------------------------------------------------------------------
local function Thing(id) return "GameObject-0-1-0-12-" .. id .. "-0000ABCD" end
check(Wanted.Object(Thing(7001)), "an open objective's object")
check(Wanted.Object(Thing(7)), "a thing an item to loot comes from")
check(Wanted.Object(Thing(8001)) and not Wanted.Object(Thing(8000)), "a finished quest's object, of your side")
check(not Wanted.Object(Thing(9999)) and not Wanted.Object("Creature-0-1-0-12-7001-0000ABCD"), "nothing else, no creature")

units.target = nil
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "find")
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", "", Thing(7001))
check(header:GetAttribute("object") == true and overrides.E == "INTERACTTARGET", "a wanted thing in front of you: Interact")
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", Thing(7001), Thing(9999))
check(header:GetAttribute("object") == false and overrides.E == FIND, "a thing nobody wants: Find")
-- An NPC in front of you that the condition help misses (one your spells could not help, as many quest givers are):
-- the module tells the header it is one to talk to; a thing, a foe or a corpse there is none.
local npc = "Creature-0-1-0-12-4242-0000ABCD"
units.softinteract = { name = "Gryan Stoutmantle", guid = npc }
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", Thing(9999), npc)
check(header:GetAttribute("npc") == true and overrides.E == "INTERACTTARGET" and header:GetAttribute("action") == "interact",
    "an NPC in front of you that help misses: talk at once")
units.softinteract = { name = "Gryan Stoutmantle", guid = npc, foe = true }
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", npc, npc)
check(header:GetAttribute("npc") == false and overrides.E == FIND, "a foe in front of you: no talk")
units.softinteract = { name = "Stone", guid = Thing(9999) }
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", npc, Thing(9999))
check(header:GetAttribute("npc") == false and overrides.E == FIND, "a thing in front of you is no NPC")
units.softinteract = { name = "Gryan Stoutmantle", guid = npc }
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", Thing(9999), npc)
Core.Set(ns.name, "talk", false)
check(header:GetAttribute("npc") == false and overrides.E == FIND, "Talk to NPCs off: no talk to the NPC in front")
Core.Set(ns.name, "talk", true)
-- /sane key: what the key sees, in chat and kept for the account (to be read after a /reload).
units.softinteract = { name = "Gryan Stoutmantle", guid = npc, neutral = true }
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", "", npc)
Key.Check()
local seen = Core.Store(ns.name).keyCheck
check(seen and #seen.lines == 5 and seen.lines[1]:find("a press does interact", 1, true)
    and seen.lines[2]:find("Gryan Stoutmantle, a Creature, no foe", 1, true) and Printed("In front of you"),
    "/sane key: what the key sees, said and kept: " .. tostring(seen and seen.lines[2]))
units.softinteract = nil
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", npc, "")
check(header:GetAttribute("npc") == false, "nothing in front of you: no NPC")

-------------------------------------------------------------------------------
--  A step's item used on the one found, and walking to the NPC found
-------------------------------------------------------------------------------
local USE = "CLICK " .. Key.USE .. ":LeftButton"
local useButton = _G[Key.USE]
local usingGuide = table.concat({ "#forever", "#name Use", "#group G", "step",
    L("goal", "10,1"), -- an objective not yet done keeps the step at hand
    L("friend", "Wounded Guard"), L("foe", "Kobold Vermin"),
    L("use", "7001", "Use the Cage on a Worg Pup"),
    L("use", "7002", "Use the Net on a weakened Raptor below 20% health"),
    L("use", "7003", "Use the Salve on the Wounded Guard"),
    L("use", "7004", "Use the Dust on their corpses"),
    L("use", "7005", "Use the Horn to start the quest"),
}, "\n")
ns.Guide.AddAll(ns.Format.Parts(usingGuide), false)
ns.Guide.Choose("G\\Use")
for id = 7001, 7005 do W.items[id] = { name = "Item " .. id, count = 1 } end
reach[7001], reach[7002], reach[7003], reach[7004] = true, true, false, true -- 7005 has no range: used on nothing

-- A living foe the words name: the item, before fighting it.
units.target = { name = "Worg Pup", foe = true, guid = "Creature-0-1-0-1-111-01" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "foe")
check(header:GetAttribute("use") == true and overrides.E == USE, "a foe the step's words name: Use, before fighting")
check(useButton:GetAttribute("macrotext") == "/use item:7001", "Use uses that step's item")
-- The game refuses it (not too far): not again on that target, the key fights.
W.Fire("UNIT_SPELLCAST_FAILED", "player", "cast", 97001)
check(header:GetAttribute("use") == false, "the game refused the item: not again on this target")
-- A foe whose words say it must be weakened first: never the item.
units.target = { name = "Raptor", foe = true, guid = "Creature-0-1-0-1-222-01" }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("use") == false, "a foe to weaken first: the item is the player's click")
-- A new target of the refused kind: tried anew.
units.target = { name = "Worg Pup", foe = true, guid = "Creature-0-1-0-1-111-02" }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("use") == true, "another of that kind: tried anew")

-- A corpse the words speak of, of a creature the step wants: the item on it.
units.target = { name = "Kobold Vermin", foe = true, dead = true, guid = "Creature-0-1-0-1-333-01" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "corpse")
check(header:GetAttribute("use") == true and useButton:GetAttribute("macrotext") == "/use item:7004"
    and overrides.E == USE, "a wanted corpse the words speak of: its item on it")
units.target = { name = "Young Wolf", foe = true, dead = true, guid = "Creature-0-1-0-1-444-01" }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("use") == false and overrides.E == FIND, "a corpse nobody wants: Find")

-- A friendly NPC the words name, too far for the item: the game's Click-to-Move lent, the key talks (walks there).
units.target = { name = "Wounded Guard", guid = "Creature-0-1-0-1-555-01" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "friend")
check(header:GetAttribute("use") == false and overrides.E == "INTERACTTARGET", "too far for the item: talk, which walks")
check(W.cvars.autointeract == "1" and ns.options.foundCVars.autointeract.was == "0", "Click-to-Move lent, what it was kept")
-- Your target's corpse, far from you, with loot: Click-to-Move lent, the key interacts, which walks and opens it.
local carcass = "Creature-0-1-0-1-666-01"
units.target = { name = "Young Wolf", foe = true, dead = true, guid = carcass }
spoils[carcass] = true
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "corpse")
check(header:GetAttribute("corpse") == true and overrides.E == "INTERACTTARGET" and W.cvars.autointeract == "1",
    "your target's corpse with loot: walked to and opened")
spoils[carcass] = nil
W.Fire("LOOT_CLOSED")
check(header:GetAttribute("corpse") == false and overrides.E == FIND and W.cvars.autointeract == "0",
    "emptied: Find, Click-to-Move back")
spoils[carcass] = true
Core.Set(ns.name, "corpses", false)
check(header:GetAttribute("corpse") == false and overrides.E == FIND, "Walk to corpses off: Find")
Core.Set(ns.name, "corpses", true)
spoils[carcass] = nil
-- A fight over: the interact key looks all around for a moment, at its corpses only; on while it finds them, then back.
units.target = nil
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "find")
W.cvars.SoftTargetInteractArc, W.cvars.SoftTargetInteractRange = "0", "10"
local behind = "Creature-0-1-0-1-777-01"
units.softinteract = { name = "Gryan Stoutmantle", guid = behind }
W.Fire("PLAYER_REGEN_ENABLED")
check(W.cvars.SoftTargetInteractArc == "2" and W.cvars.SoftTargetInteractRange == "30", "after a fight: all around, further")
check(header:GetAttribute("left") == true and header:GetAttribute("npc") == false and overrides.E == FIND,
    "meanwhile an NPC it picks far away takes no press")
units.softinteract = { name = "Young Wolf", foe = true, dead = true, guid = behind }
W.Wait(Key.TICK)
check(W.cvars.autointeract == "1", "a corpse it picks: Click-to-Move lent")
W.Wait(Key.LOOK * 3)
check(W.cvars.SoftTargetInteractArc == "2", "on while it finds corpses")
units.softinteract = nil
W.Wait(Key.LOOK + Key.TICK)
check(W.cvars.SoftTargetInteractArc == "0" and W.cvars.SoftTargetInteractRange == "10" and W.cvars.autointeract == "0"
    and header:GetAttribute("left") == false, "none left: as far as before, Click-to-Move back")
W.Fire("PLAYER_REGEN_ENABLED")
W.Fire("PLAYER_REGEN_DISABLED")
check(W.cvars.SoftTargetInteractArc == "0", "a new fight: back at once")
W.Wait(Key.LOOK + Key.TICK)
units.target = { name = "Wounded Guard", guid = "Creature-0-1-0-1-555-01" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "friend")
-- Within the item's reach now: looked at again a few times a second; the item, Click-to-Move given back.
reach[7003] = true
W.Wait(1)
check(header:GetAttribute("use") == true and useButton:GetAttribute("macrotext") == "/use item:7003"
    and overrides.E == USE, "within reach: the item on it")
check(W.cvars.autointeract == "0" and ns.options.foundCVars.autointeract == nil, "Click-to-Move given back")
-- An NPC the game says belongs to a quest of yours (one to hand it in to), that no list names: wanted, walked to.
units.target = { name = "Sergeant Willem", guid = "Creature-0-1-0-1-777-01", related = true, neutral = true }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("wanted") == true and overrides.E == "INTERACTTARGET" and W.cvars.autointeract == "1",
    "an NPC the game says your quest wants: wanted, walked to, talked to")
units.target = { name = "Sergeant Willem", guid = "Creature-0-1-0-1-777-01", related = true, foe = true }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("wanted") == false, "a foe the game relates to a quest, with nothing to kill or loot: not wanted")
-- An NPC nobody wants: neither.
reach[7003] = false
units.target = { name = "Brother Paxton", guid = "Creature-0-1-0-1-666-01" }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("use") == false and W.cvars.autointeract == "0", "an NPC nobody wants: no item, no walking")
-- Walk to the NPC found off: the key talks, the game's setting left alone.
Core.Set(ns.name, "walk", false)
units.target = { name = "Wounded Guard", guid = "Creature-0-1-0-1-555-01" }
W.Fire("PLAYER_TARGET_CHANGED")
check(W.cvars.autointeract == "0", "Walk to the NPC found off: Click-to-Move left alone")
Core.Set(ns.name, "walk", true)
check(W.cvars.autointeract == "1", "on again: lent")
-- A neutral NPC, wanted (not the game's friend, yet it cannot be attacked): walked to and talked to as well.
units.target = { name = "Wounded Guard", guid = "Creature-0-1-0-1-555-01", neutral = true }
W.Fire("PLAYER_TARGET_CHANGED")
check(W.cvars.autointeract == "1" and overrides.E == "INTERACTTARGET", "a neutral NPC that is wanted: walked to, talked to")
-- A fight begins: no item on the target, Click-to-Move given back for the fight.
W.Fire("PLAYER_REGEN_DISABLED")
check(header:GetAttribute("use") == false and W.cvars.autointeract == "0", "a fight: no item, no Click-to-Move")
W.Fire("PLAYER_REGEN_ENABLED")
check(W.cvars.autointeract == "1", "after the fight: lent again while that NPC is your target")
-- Use items on what is found off: never the item.
units.target = { name = "Worg Pup", foe = true, guid = "Creature-0-1-0-1-111-03" }
W.Fire("PLAYER_TARGET_CHANGED")
Core.Set(ns.name, "useOn", false)
check(header:GetAttribute("use") == false, "Use items on what is found off: never the item")
Core.Set(ns.name, "useOn", true)
units.target = nil
W.Fire("PLAYER_TARGET_CHANGED")
check(W.cvars.autointeract == "0", "no target: Click-to-Move given back")
ns.Guide.Choose("G\\Test")

-------------------------------------------------------------------------------
--  The hearth and the quest items
-------------------------------------------------------------------------------
-- The guide's step wants the hearth: Find hearths, nothing else. (A guide line of ours, through Guide.Uses.)
local pasted = table.concat({ "#forever", "#name Hearth", "#group G", "step", "." .. C.hearth .. " >> Hearth now" }, "\n")
ns.Guide.AddAll(ns.Format.Parts(pasted), false)
ns.Guide.Choose("G\\Hearth")
W.items[6948] = { name = "Hearthstone", count = 1 }
check(Key.Find()[1] == "/use item:6948", "the guide's step wants the hearth: the Hearthstone alone")
cooling[6948] = 3600
learned[556], W.spells[556] = true, { name = "Astral Recall" }
-- Astral Recall is wanted only if the guide lists the shaman spell; our hearth line lists both the stone and recall.
check(Key.Find()[1] == "/cast Astral Recall", "the stone cooling down: a shaman's Astral Recall")
cooling[6948] = nil
check(Key.Find()[1] == "/use item:6948", "the stone first")
Core.Set(ns.name, "hearth", false)
check(not Key.Find()[1]:find("6948", 1, true), "Hearthstone off: never the stone")
Core.Set(ns.name, "hearth", true)
ns.Guide.Choose("G\\Test")

-- Nothing found around you: one quest item of the log, usable and in range.
specials[2] = 6000
W.items[6000] = { name = "Torch", count = 1 }
check(Key.Macros({}, Items.Pick(nil))[1]:find("/use item:6000$"), "no names: the quest item alone")
unusable[6000] = true
check(not (Items.Pick(nil) or ""):find("6000"), "not usable: none")
unusable[6000] = nil
specials[2] = nil

-------------------------------------------------------------------------------
--  The quest givers: a guide's quests taken and handed in
-------------------------------------------------------------------------------
local gossip = { active = {}, available = {}, options = {}, chosenActive = nil, chosenAvailable = nil, chosenOption = nil }
C_GossipInfo = {
    GetActiveQuests = function() return gossip.active end,
    GetAvailableQuests = function() return gossip.available end,
    GetOptions = function() return gossip.options end,
    SelectActiveQuest = function(id) gossip.chosenActive = id end,
    SelectAvailableQuest = function(id) gossip.chosenAvailable = id end,
    SelectOption = function(id) gossip.chosenOption = id end,
}
IsShiftKeyDown = function() return false end
-- The guide "Test" takes quest 40 and hands in 41.
gossip.available = { { questID = 40 }, { questID = 99 } }
gossip.active = { { questID = 41, isComplete = true } }
W.Fire("GOSSIP_SHOW")
check(gossip.chosenActive == 41, "a done quest the guide hands in is handed in first")
gossip.active = {}
W.Fire("GOSSIP_SHOW")
check(gossip.chosenAvailable == 40 and gossip.chosenAvailable ~= 99, "then a quest the guide takes is taken")
IsShiftKeyDown = function() return true end
gossip.chosenAvailable = nil
W.Fire("GOSSIP_SHOW")
check(gossip.chosenAvailable == nil, "Shift held: nothing done, the window as it is")
IsShiftKeyDown = function() return false end

-- A talk that is done: the quest taken, the key leaves the NPC alone; a talk that comes up anyway is closed.
local closed = 0
C_GossipInfo.CloseGossip = function() closed = closed + 1 end
local giver = "Creature-0-1-0-1-888-01"
units.npc, units.softinteract = { name = "Some Farmer", guid = giver }, { name = "Some Farmer", guid = giver }
GetQuestID, AcceptQuest = function() return 40 end, function() end
W.Wait(Key.LOOK + Key.TICK) -- what the fights above left: the interact key's look around is over
header:SetAttribute("state-mode", "near")
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", nil, giver)
check(overrides.E == "INTERACTTARGET", "before the talk: talk")
W.Fire("QUEST_DETAIL")
check(header:GetAttribute("left") == true and header:GetAttribute("npc") == false and overrides.E == FIND,
    "the quest taken: the key goes on, no talking again")
gossip.available, gossip.active, gossip.options = {}, {}, { { gossipOptionID = 5 } }
W.Fire("GOSSIP_SHOW")
W.Wait(0.1)
check(closed == 1, "the talk opening again after it: closed, whatever else the NPC offers")
ns.Quests.Forget()
check(header:GetAttribute("left") == false and overrides.E == "INTERACTTARGET", "forgotten: talk")
W.Wait(Key.LOOK)
W.Fire("GOSSIP_SHOW")
W.Wait(0.1)
check(closed == 1 and header:GetAttribute("left") == true, "a talk with options and nothing done: open, the key goes on")
gossip.options = {}
W.Fire("GOSSIP_SHOW")
W.Wait(0.1)
check(closed == 2, "the goodbye screen: closed")
gossip.available = { { questID = 99 } }
W.Fire("GOSSIP_SHOW")
W.Wait(0.1)
check(closed == 2, "a quest the guide does not know: yours to choose")
gossip.available = {}
Core.Set(ns.name, "leave", false)
W.Fire("GOSSIP_SHOW")
W.Wait(0.1)
check(closed == 2, "Close the talk off: open")
Core.Set(ns.name, "leave", true)
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", giver, "Creature-0-1-0-1-889-01")
units.softinteract = { name = "Another Farmer", guid = "Creature-0-1-0-1-889-01" }
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", giver, "Creature-0-1-0-1-889-01")
check(header:GetAttribute("left") == false, "another NPC: the first forgotten")
units.npc, units.softinteract = nil, nil
W.Fire("PLAYER_SOFT_INTERACT_CHANGED", "Creature-0-1-0-1-889-01", nil)
header:SetAttribute("state-mode", "find")

-- Two of the guide's quests at one NPC: both taken, the key not through with it before; one it does not know ignored.
do
    local quests = ns.Guide.Quests
    local wanted = { take = { [40] = true, [42] = true }, handin = {}, gossip = {} }
    ns.Guide.Quests = function() return wanted end
    local accepted, shownQuest = {}, 40
    GetQuestID, AcceptQuest = function() return shownQuest end, function() accepted[#accepted + 1] = shownQuest end
    local talker = "Creature-0-1-0-1-890-01"
    units.npc, units.softinteract = { name = "Two Quests", guid = talker }, { name = "Two Quests", guid = talker }
    W.Fire("PLAYER_SOFT_INTERACT_CHANGED", nil, talker)
    header:SetAttribute("state-mode", "near")
    gossip.active, gossip.options, gossip.available = {}, {}, { { questID = 40 }, { questID = 42 }, { questID = 99 } }
    gossip.chosenAvailable = nil
    W.Fire("GOSSIP_SHOW")
    check(gossip.chosenAvailable == 40, "two of the guide's quests: the first")
    W.Fire("QUEST_DETAIL")
    wanted.take[40] = nil
    check(accepted[1] == 40 and header:GetAttribute("left") == false and overrides.E == "INTERACTTARGET",
        "taken: the key is not through with the NPC, the next press talks")
    gossip.available = { { questID = 42 }, { questID = 99 } }
    W.Fire("GOSSIP_SHOW")
    check(gossip.chosenAvailable == 42, "the talk again: the second")
    shownQuest = 42
    W.Fire("QUEST_DETAIL")
    wanted.take[42] = nil
    check(accepted[2] == 42 and header:GetAttribute("left") == true, "both taken: through with it")
    local shut = closed
    gossip.available = { { questID = 99 } }
    W.Fire("GOSSIP_SHOW")
    W.Wait(0.1)
    check(gossip.chosenAvailable == 42 and closed == shut + 1, "a quest the guide does not know, right after: ignored, closed")
    W.Fire("GOSSIP_SHOW")
    W.Wait(0.1)
    check(closed == shut + 1, "a talk you open after that stays open for it")
    -- A quest offered alone that the guide does not know.
    local closedQuest = 0
    CloseQuest = function() closedQuest = closedQuest + 1 end
    wanted.take[43] = true
    shownQuest = 43
    W.Fire("QUEST_DETAIL")
    wanted.take[43] = nil
    shownQuest = 99
    W.Fire("QUEST_DETAIL")
    W.Wait(0.1)
    check(#accepted == 3 and accepted[3] == 43 and closedQuest == 1, "offered right after a quest: never taken, closed")
    W.Fire("QUEST_DETAIL")
    W.Wait(0.1)
    check(#accepted == 3 and closedQuest == 1, "offered in a talk of your own: never taken, open")
    -- A hand-in that may open the next quest there: while the guide wants one, the key talks once more.
    wanted.take[44] = true
    local next = "Creature-0-1-0-1-891-01"
    units.npc = { name = "Two Quests", guid = next }
    units.softinteract = units.npc
    W.Fire("PLAYER_SOFT_INTERACT_CHANGED", talker, next)
    GetNumQuestChoices, GetQuestReward = function() return 0 end, function() end
    wanted.handin[41] = true
    shownQuest = 41
    W.Fire("QUEST_COMPLETE")
    check(header:GetAttribute("left") == false, "the guide still wants a quest: the key may talk again")
    wanted.take[44], wanted.handin[41] = nil, nil
    ns.Key.Refresh()
    check(header:GetAttribute("left") == true, "it wants none: the key leaves it alone")
    ns.Quests.Forget()
    ns.Guide.Quests = quests
    units.npc, units.softinteract = nil, nil
    W.Fire("PLAYER_SOFT_INTERACT_CHANGED", next, nil)
    header:SetAttribute("state-mode", "find")
    GetQuestID, AcceptQuest, CloseQuest, GetNumQuestChoices, GetQuestReward = nil, nil, nil, nil, nil
    gossip.available, gossip.chosenAvailable = {}, nil
end

-- The rewards: the biggest upgrade, else the guide's, else the one worth the most.
do
    local quests, upgrade, info = ns.Guide.Quests, Core.Upgrade, C_Item.GetItemInfo
    local wanted = { take = {}, handin = { [41] = true }, gossip = {} }
    ns.Guide.Quests = function() return wanted end
    units.npc = { name = "Reward Giver", guid = "Creature-0-1-0-1-892-01" }
    local links = { "item:1:x", "item:2:x", "item:3:x" }
    local items = { [links[1]] = { 100, 1 }, [links[2]] = { 300, 1 }, [links[3]] = { 200, 2 } }
    local gains, picked = {}, nil
    Core.Upgrade = function(link) if gains[link] then return "better", gains[link] end end
    C_Item.GetItemInfo = function(link)
        local item = items[link]
        if item then return "Thing", link, 1, 1, 1, "", "", 1, "", 1, item[1], 1, 1, item[2] end
    end
    GetQuestID, GetNumQuestChoices = function() return 41 end, function() return 3 end
    GetQuestReward = function(index) picked = index end
    GetQuestItemLink = function(_, index) return links[index] end
    GetQuestItemInfo = function() return "Thing", 1, 1 end
    gains[links[2]], gains[links[3]] = 5, 9
    W.Fire("QUEST_COMPLETE")
    check(picked == 3, "the biggest upgrade")
    gains[links[2]], gains[links[3]], picked = nil, nil, nil
    wanted.handin[41] = 1
    W.Fire("QUEST_COMPLETE")
    check(picked == 1, "no upgrade: the reward the guide names")
    wanted.handin[41], picked = true, nil
    W.Fire("QUEST_COMPLETE")
    check(picked == 2, "none named: the one a vendor pays the most for")
    Core.Store("Tooltips").prices = { [2] = 9000, [3] = 1000 }
    picked = nil
    W.Fire("QUEST_COMPLETE")
    check(picked == 3, "or the auction house, for what can go there; what binds when picked up cannot")
    Core.Store("Tooltips").prices = nil
    items[links[2]], picked = nil, nil
    W.Fire("QUEST_COMPLETE")
    check(picked == nil, "the game does not know one yet: not yet")
    items[links[2]] = { 300, 1 }
    W.Wait(ns.Quests.WAIT)
    check(picked == 2, "then it does: chosen")
    Core.Set(ns.name, "rewards", false)
    picked = nil
    W.Fire("QUEST_COMPLETE")
    check(picked == nil, "Choose quest rewards off: yours")
    wanted.handin[41] = 3
    W.Fire("QUEST_COMPLETE")
    check(picked == 3, "or the one the guide names")
    Core.Set(ns.name, "rewards", true)
    ns.Guide.Quests, Core.Upgrade, C_Item.GetItemInfo = quests, upgrade, info
    GetQuestID, GetNumQuestChoices, GetQuestReward, GetQuestItemLink, GetQuestItemInfo = nil, nil, nil, nil, nil
    units.npc = nil
    ns.Quests.Forget()
end

-- Shift seen once in a talk: the rest of it is yours, let go or not, until the talk is over.
do
    local Quests, did = ns.Quests, {}
    local function Held(on) IsShiftKeyDown = function() return on end end
    local function Over()
        units.npc = nil
        W.Fire("QUEST_FINISHED")
        W.Wait(Quests.OVER)
        units.npc = { name = "Some Farmer", guid = giver }
    end
    AcceptQuest = function() did[#did + 1] = "taken" end
    CompleteQuest = function() did[#did + 1] = "completed" end
    GetQuestReward = function(choice) did[#did + 1] = "reward " .. choice end
    IsQuestCompletable, GetNumQuestChoices = function() return true end, function() return 1 end
    units.npc = { name = "Some Farmer", guid = giver }
    gossip.chosenAvailable, gossip.available = nil, { { questID = 40 } }
    Held(true)
    W.Fire("GOSSIP_SHOW")
    Held(false)
    check(gossip.chosenAvailable == nil, "Shift held as the talk begins: nothing done")
    W.Fire("GOSSIP_SHOW")
    check(gossip.chosenAvailable == nil, "let go: the talk stays yours")
    W.Fire("QUEST_DETAIL")
    check(#did == 0, "the quest you opened to read is not taken")
    W.Fire("GOSSIP_CLOSED")
    W.Wait(Quests.OVER)
    GetQuestID = function() return 41 end
    W.Fire("QUEST_PROGRESS")
    W.Fire("QUEST_COMPLETE")
    check(#did == 0, "the gossip window gone for a quest's: the same talk, nothing handed in, no reward chosen")
    gossip.available, gossip.options = {}, {}
    local before = closed
    W.Fire("GOSSIP_SHOW")
    W.Wait(0.1)
    check(closed == before, "nor is a goodbye screen closed")
    Over()
    GetQuestID = function() return 40 end
    W.Fire("QUEST_DETAIL")
    check(did[1] == "taken", "the talk over: the next one is done for you again")
    ns.Quests.Forget()
    Held(true)
    W.Fire("QUEST_DETAIL")
    Held(false)
    units.npc = { name = "Another Farmer", guid = "Creature-0-1-0-1-889-01" }
    W.Fire("QUEST_DETAIL")
    check(#did == 2, "another NPC is another talk")
    ns.Quests.Forget()
    Over()
    did = {}
    Held(true)
    GetQuestID = function() return 41 end
    W.Fire("QUEST_PROGRESS")
    check(#did == 0, "Shift first seen at a later step: not on to the rewards")
    Held(false)
    W.Fire("QUEST_COMPLETE")
    check(#did == 0, "and no reward chosen")
    Over()
    W.Fire("QUEST_PROGRESS")
    W.Fire("QUEST_COMPLETE")
    check(did[1] == "completed" and did[2] == "reward 1", "without Shift: on to the rewards, the only one chosen")
    ns.Quests.Forget()
    Over()
    units.npc = nil
    AcceptQuest, CompleteQuest, GetQuestReward, IsQuestCompletable, GetNumQuestChoices = nil, nil, nil, nil, nil
end
GetQuestID, AcceptQuest = nil, nil
gossip.chosenAvailable = nil

-------------------------------------------------------------------------------
--  What would hold you up: Loot's switches, the game's questions
-------------------------------------------------------------------------------
-- Take all loot: Loot's switches set once and given back; what you changed after that stays.
local lootOptions = Core.Settings("Loot")
if not Core.Described("Loot", "takeAll") then
    Core.Options("Loot", { { key = "takeAll", default = false }, { key = "showUpgrades", default = true } }, {})
    lootOptions = Core.Settings("Loot")
end
lootOptions.takeAll, lootOptions.showUpgrades = false, true
ns.options.lootLent = {}
ns.Errands.Update()
check(lootOptions.takeAll == true and lootOptions.showUpgrades == true, "Take all loot: Everything on, upgrades still shown")
lootOptions.takeAll = false
ns.Errands.Update()
check(lootOptions.takeAll == false, "what you change on Loot's page afterwards stays")
lootOptions.takeAll = true
Core.Set(ns.name, "lootAll", false)
check(lootOptions.takeAll == false and next(ns.options.lootLent) == nil, "off: put back")
Core.Set(ns.name, "lootAll", true)
check(lootOptions.takeAll == true, "on again: set")

-- The game's questions, answered by what their own Yes does.
local cursor, answered, hidden = true, {}, {}
CursorHasItem = function() return cursor end
local shown = {}
local function Question(which)
    StaticPopupDialogs[which] = { OnAccept = function(_, data) answered[#answered + 1] = which .. ":" .. tostring(data) end }
end
for _, which in ipairs({ "LOOT_BIND", "EQUIP_BIND", "EQUIP_BIND_TRADEABLE", "EQUIP_BIND_REFUNDABLE", "DELETE_ITEM",
                         "DELETE_GOOD_ITEM", "OTHER_QUESTION" }) do
    Question(which)
end
StaticPopupDialogs.DELETE_ITEM.OnAccept = function() answered[#answered + 1] = "deleted"; cursor = false end
StaticPopup_FindVisible = function(which) return shown[which] end
StaticPopup_Hide = function(which) hidden[#hidden + 1] = which; shown[which] = nil end
local showPopup = StaticPopup_Show
local function Ask(which, data)
    local box = { text = "" }
    function box:IsShown() return true end
    function box:SetText(text) self.text = text end
    shown[which] = { which = which, data = data, GetEditBox = function() return box end }
    W.popups[#W.popups + 1] = shown[which]
    showPopup(which, nil, nil, data)
    return box
end
-- The module hooked the function as it started; the hook runs after the game's.
Ask("EQUIP_BIND", 16)
check(answered[1] == "EQUIP_BIND:16" and hidden[1] == "EQUIP_BIND", "equipping: answered, the question gone")
Ask("LOOT_BIND", 3)
check(answered[2] == "LOOT_BIND:3" and hidden[2] == "LOOT_BIND", "what binds when picked up: answered")
Ask("OTHER_QUESTION", 1)
check(#answered == 2 and #hidden == 2, "another question is the game's")
Ask("DELETE_ITEM")
W.Wait(1)
check(answered[3] == "deleted" and ns.options.deleteRefused == false, "destroying: answered, the item gone")
Core.Set(ns.name, "noAsk", false)
Ask("EQUIP_BIND", 16)
check(#answered == 3, "Equip and delete without asking off: the game asks")
Core.Set(ns.name, "noAsk", true)
-- The game refuses: the item stays on the cursor, the question stands with its word typed in, not tried again.
DELETE_ITEM_CONFIRM_STRING = "DELETE"
cursor = true
local box = Ask("DELETE_GOOD_ITEM")
W.Wait(1)
check(ns.options.deleteRefused == true and box.text == "DELETE", "refused: the word typed in, kept for next time")
local count = #answered
box = Ask("DELETE_GOOD_ITEM")
check(#answered == count and box.text == "DELETE", "not tried again: the word at once")
ns.options.deleteRefused = false
cursor = false
shown = {}

-------------------------------------------------------------------------------
--  The game's settings, and standing down
-------------------------------------------------------------------------------
Core.Set(ns.name, "loot", false)
Core.Set(ns.name, "objects", false)
Core.Set(ns.name, "talk", false)
check(W.cvars.softTargetInteract == "2" and next(ns.options.foundCVars) == nil, "all off: the interact key back as it was")
Core.Set(ns.name, "loot", true)
check(W.cvars.softTargetInteract == "3", "on again: the interact key on")

-------------------------------------------------------------------------------
--  Gathering for the next zone
-------------------------------------------------------------------------------
-- The guide goes from here (1411) to the next zone (1413): there half the herbs need 115, the ore 125. Herbalism
-- 92 is short; Mining not learnt says nothing.
local skills = { { name = "Herbalism", rank = 92 } }
C_SkillInfo = { GetNumSkillLines = function() return #skills end, GetSkillLineInfo = function(index) return skills[index] end }
local trip = table.concat({ "#forever", "#" .. "name Trip", "#" .. "group G", "step", L("place", "1411,50,50"),
    L("take", "60"), "step", L("place", "1413,40,40"), L("take", "61") }, "\n")
ns.Guide.AddAll(ns.Format.Parts(trip), false)
ns.Guide.Choose("G\\Trip")
local need = ns.Gathering.Need(1413)
check(need and need.herb == 115 and need.ore == 125 and ns.Gathering.Need(1411).herb == 1,
    "a zone's asks: the skill that gathers half its herbs, its ore")
local short = ns.Gathering.Short()
check(short and short.map == 1413 and #short.short == 1 and short.short[1].skill == "Herbalism"
    and short.short[1].have == 92 and short.short[1].need == 115, "the next zone ahead: Herbalism short, Mining not learnt")
ns.Steps.Update()
local said
for _, widget in ipairs(W.frames) do
    if widget._shown and type(widget._text) == "string" and widget._text:find("Herbalism 92 of 115", 1, true) then said = widget end
end
check(said ~= nil, "the view says so under its head")
skills[1].rank = 120
check(ns.Gathering.Short() == nil, "enough for it: nothing said")
skills[1].rank = 92
Core.Set(ns.name, "gather", false)
check(ns.Gathering.Short() == nil and not said._shown, "Gathering for the next zone off: nothing said")
Core.Set(ns.name, "gather", true)
here.map = 1413
check(ns.Gathering.Short() == nil, "there already, nothing further ahead: nothing said")
here.map = 1411
ns.Guide.Choose("G\\Test")

check(not ns.off and #SaneUI.Core.log == 0, "no error stood the module down along the way: "
    .. tostring(SaneUI.Core.log[1] and SaneUI.Core.log[1].text))
ns.StandDown("a test")
check(ns.off and drivers[header].mode == nil, "standing down: the driver stopped")
check(next(overrides) == nil, "no override binding of ours")
check(find:GetAttribute("macrotext") == "" and _G[Key.LINK .. 2]:GetAttribute("macrotext") == "", "the macros empty")
check(W.cvars.softTargetInteract == "2", "the interact key back")

io.write(("Speed Leveling: all %d checks passed.\n"):format(passed))
