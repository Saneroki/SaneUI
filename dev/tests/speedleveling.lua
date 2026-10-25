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
UnitIsFriend = function(_, unit) return units[unit] ~= nil and not units[unit].foe end
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
Enum.TooltipDataLineType = { QuestObjective = 8 }
C_TooltipInfo = { GetUnit = function(unit)
    local quest = units[unit] and units[unit].quest
    return { lines = quest and { { type = 8, leftText = quest } } or {} }
end }
C_QuestLog = rawget(_G, "C_QuestLog") or {}
C_QuestLog.UnitIsRelatedToActiveQuest = function(unit) return units[unit] ~= nil and units[unit].quest ~= nil end

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
    },
}
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
check(Printed("give it a key"), "with no key, the module says how to give it one")
check(_G[Key.LINK .. 2] and _G[Key.LINK .. (Key.LINKS + 1)], "the chain's buttons are made")

local conditions = drivers[header].mode
check(conditions:find("^%[@softinteract,exists,dead%] loot; "), "loot comes first while Loot first is on")
check(conditions:find("%[@target,harm,nodead,combat%] fight; %[@softinteract,exists,help,nodead%] near; "
    .. "%[@target,harm,nodead%] foe; %[@target,help,nodead%] friend; %[@target,exists,dead%] corpse; find$"),
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
-- Within the item's reach now: looked at again a few times a second; the item, Click-to-Move given back.
reach[7003] = true
W.Wait(1)
check(header:GetAttribute("use") == true and useButton:GetAttribute("macrotext") == "/use item:7003"
    and overrides.E == USE, "within reach: the item on it")
check(W.cvars.autointeract == "0" and ns.options.foundCVars.autointeract == nil, "Click-to-Move given back")
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

-------------------------------------------------------------------------------
--  The game's settings, and standing down
-------------------------------------------------------------------------------
Core.Set(ns.name, "loot", false)
Core.Set(ns.name, "objects", false)
Core.Set(ns.name, "talk", false)
check(W.cvars.softTargetInteract == "2" and next(ns.options.foundCVars) == nil, "all off: the interact key back as it was")
Core.Set(ns.name, "loot", true)
check(W.cvars.softTargetInteract == "3", "on again: the interact key on")

check(not ns.off and #SaneUI.Core.log == 0, "no error stood the module down along the way: "
    .. tostring(SaneUI.Core.log[1] and SaneUI.Core.log[1].text))
ns.StandDown("a test")
check(ns.off and drivers[header].mode == nil, "standing down: the driver stopped")
check(next(overrides) == nil, "no override binding of ours")
check(find:GetAttribute("macrotext") == "" and _G[Key.LINK .. 2]:GetAttribute("macrotext") == "", "the macros empty")
check(W.cvars.softTargetInteract == "2", "the interact key back")

io.write(("Speed Leveling: all %d checks passed.\n"):format(passed))
