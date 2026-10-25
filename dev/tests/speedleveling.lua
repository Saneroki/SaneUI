-- Runs the Speed Leveling module against the stand-in client (wowstub.lua): what is wanted and in which order (the
-- guide's step, the quests' objectives from Core's data, creatures the game marks on nameplates, the NPCs to hand in
-- to), the language, the macro of Find and its room, whether the target is wanted, the header's snippets as the game
-- runs them (which action each state puts on the key's keys), the keys from the game's key bindings, the hint, the
-- game's settings for Loot first kept and put back, the switches, a fight, and standing down.
-- Usage, from the project folder:  lua5.1 dev/tests/speedleveling.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
function methods:SetAttribute(name, value)
    self._attributes = self._attributes or {}
    self._attributes[name] = value
    if self._changed then self._changed(name, value) end
end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end

-- The header's snippets run as the game runs them: compiled with their arguments, on a handle of the frame whose
-- override bindings are kept here.
local overrides = {} -- [key] = its action while an override binding of the header's is on it
local function Snippet(body, arguments)
    return assert(loadstring("return function(" .. arguments .. ") " .. body .. " end"))()
end
W.templates.SecureHandlerAttributeTemplate = function(frame)
    local handle = {}
    function handle:GetAttribute(name) return frame:GetAttribute(name) end
    function handle:ClearBindings() for key in pairs(overrides) do overrides[key] = nil end end
    function handle:SetBinding(priority, key, action)
        assert(priority == true, "an override above the others")
        overrides[key] = action
    end
    function handle:SetBindingClick(priority, key, name, button)
        assert(priority == true, "an override above the others")
        overrides[key] = "CLICK " .. name .. ":" .. (button or "LeftButton")
    end
    function handle:RunAttribute(name, ...) return Snippet(frame:GetAttribute(name), "self, ...")(handle, ...) end
    frame._changed = function(name, value)
        if name:match("^_") then return end
        local body = frame:GetAttribute("_onattributechanged")
        if body then Snippet(body, "self, name, value")(handle, name, value) end
    end
end
local drivers = {} -- [frame] = { [state] = its conditions }
function RegisterStateDriver(frame, state, values)
    drivers[frame] = drivers[frame] or {}
    drivers[frame][state] = values
end
function UnregisterStateDriver(frame, state)
    if drivers[frame] then drivers[frame][state] = nil end
end
function ClearOverrideBindings() for key in pairs(overrides) do overrides[key] = nil end end
local bound = {} -- [command] = the keys the game's key bindings give it
function GetBindingKey(command) return unpack(bound[command] or {}) end

-- Units: the target and the nameplates, by what the test gives them; a quest text makes the game mark it.
local units = {}
UnitExists = function(unit) return units[unit] ~= nil or unit == "player" end
UnitIsPlayer = function(unit) return unit == "player" or (units[unit] and units[unit].player) or false end
UnitName = function(unit)
    if units[unit] then return units[unit].name end
    return "Tester", "Stub"
end
Enum.TooltipDataLineType = { QuestObjective = 8 }
C_TooltipInfo = { GetUnit = function(unit)
    local quest = units[unit] and units[unit].quest
    return { lines = quest and { { type = 8, leftText = quest } } or {} }
end }

-- The quest log.
local log = { entries = {}, objectives = {}, complete = {} }
C_QuestLog = rawget(_G, "C_QuestLog") or {}
C_QuestLog.GetNumQuestLogEntries = function() return #log.entries end
C_QuestLog.GetInfo = function(index) return log.entries[index] end
C_QuestLog.IsComplete = function(quest) return log.complete[quest] == true end
C_QuestLog.GetQuestObjectives = function(quest) return log.objectives[quest] end
C_QuestLog.UnitIsRelatedToActiveQuest = function(unit) return units[unit] ~= nil and units[unit].quest ~= nil end
log.entries = { { isHeader = true, title = "Elwynn Forest" }, { questID = 10 }, { questID = 11 }, { questID = 12 } }
log.objectives[10] = { { text = "Kobold Vermin slain: 2/10", finished = false }, { text = "Candle: 0/8", finished = false } }
log.objectives[11] = {}
log.objectives[12] = { { text = "Wolf slain: 8/8", finished = true } }
log.complete[11] = true

local language = "enUS"
GetLocale = function() return language end

-- The game's settings Loot first uses.
W.cvarInfo.softTargetInteract = { default = "2" }
W.cvarInfo.autoLootDefault = { default = "0" }

-------------------------------------------------------------------------------
--  Core, its data as the test gives it, and the module
-------------------------------------------------------------------------------
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local Core = SaneUI.Core

-- The leveling guide Sane UI knows, as the game has it loaded, by what Neighbours says of it: its addon object found by
-- its name through a library, the library from a global stub; its targeting part's lists of the step at hand.
local known = Core.Neighbours.KNOWN.guide
local guideLists = { { "Marshal McBride" }, { "Kobold Vermin", "Defias Thug" }, { "Garrick Padfoot" }, {} }
local guide = { [known.part] = { [known.lists] = function() return unpack(guideLists) end } }
local library = { GetAddon = function(_, name) return name == known.addon and guide or nil end }
_G[known.stub] = setmetatable({ GetLibrary = function(_, name) return name == known.library and library or nil end },
                              { __call = function(self, name) return self:GetLibrary(name) end })
W.loaded[known.addon] = true

local records = {
    Quests = {
        [10] = { objectives = { { index = 1, kind = "kill", what = 100 }, { index = 2, kind = "loot", what = 500 } },
                 finishNPCs = { { npc = 300 } } },
        [11] = { objectives = {}, finishNPCs = { { npc = 301, side = "horde" }, { npc = 302, side = "alliance" } } },
        [12] = { objectives = { { index = 1, kind = "kill", what = 105 } }, finishNPCs = { { npc = 303 } } },
    },
    NPCs = { [100] = { name = "Kobold Vermin" }, [105] = { name = "Prowler" }, [200] = { name = "Kobold Worker" },
             [201] = { name = "Kobold Laborer" }, [202] = { name = "Kobold Tunneler" }, [203] = { name = "Kobold Geomancer" },
             [204] = { name = "Young Wolf" }, [300] = { name = "Marshal Dughan" }, [301] = { name = "Gar'Thok" },
             [302] = { name = "Deputy Willem" }, [303] = { name = "Eagan Peltskinner" } },
    Drops = {
        ["npc:200"] = { items = { { item = 500, how = "loot", chance = 40 } } },
        ["npc:201"] = { items = { { item = 9, how = "loot", chance = 90 }, { item = 500, how = "loot", chance = 60 } } },
        ["npc:202"] = { items = { { item = 500, how = "loot" } } },
        ["npc:203"] = { items = { { item = 500, how = "loot", chance = 5 } } },
        ["npc:204"] = { items = { { item = 500, how = "skin", chance = 99 } } },
        ["object:7"] = { items = { { item = 500, how = "gather", chance = 100 } } },
    },
}
local byItem = { [500] = { "npc:200", "npc:201", "npc:202", "npc:203", "npc:204", "object:7" } }
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
W.Fire("PLAYER_LOGIN")
local Key, Wanted = ns.Key, ns.Wanted
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
check(header and header._template == "SecureHandlerAttributeTemplate", "the header is a secure handler")
check(find._template == "SecureActionButtonTemplate" and find:GetAttribute("type") == "macro", "Find is a secure macro button")
check(fight:GetAttribute("type") == "macro", "Fight is a secure macro button")
check(_G["BINDING_NAME_" .. FIND] == ns.TEXT.binding, "the key has its words in the game's key bindings")
check(Printed("give it a key"), "with no key, the module says how to give it one")
check(ns.options.told == true and header:GetAttribute("keys") == 0, "told once; no keys on the header")
check(next(overrides) == nil, "no key: no override binding")

local conditions = drivers[header] and drivers[header].mode
check(conditions and conditions:find("^%[@softinteract,exists,dead%] loot; "), "loot comes first while Loot first is on")
check(conditions:find("%[@target,harm,nodead,combat%] fight; %[@target,harm,nodead%] foe; %[@target,help,nodead%] friend; find$"),
    "then a foe in a fight, a foe, a friend, else find")
check(W.cvars.softTargetInteract == "3" and W.cvars.autoLootDefault == "1", "Loot first: the interact key and auto loot on")
check(ns.options.foundCVars.softTargetInteract.was == "2" and ns.options.foundCVars.autoLootDefault.was == "0",
    "what they were is kept")
check(fight:GetAttribute("macrotext") == "/tm [harm,nodead] !8\n/startattack [harm,nodead]", "Fight marks and attacks")

-------------------------------------------------------------------------------
--  What is wanted
-------------------------------------------------------------------------------
local names = Wanted.Names()
check(Joined(names) == "Kobold Vermin, Defias Thug, Garrick Padfoot, Marshal McBride, Kobold Laborer, Kobold Worker, "
    .. "Kobold Geomancer, Deputy Willem", "the guide's creatures and NPCs, the quests' creatures, then the NPCs to hand in to: "
    .. Joined(names))
-- The likeliest three droppers of the item to loot; none that only gives it skinned, no object; not the kill done
-- (quest 12), not the NPC of a quest not finished, not one of the other side.
check(not Joined(names):find("Tunneler") and not Joined(names):find("Young Wolf"), "three droppers, looted only")
check(not Joined(names):find("Prowler") and not Joined(names):find("Dughan") and not Joined(names):find("Gar'Thok"),
    "no finished objective, no NPC of an open quest, none of the other side")

-- A creature the game marks for a quest on its nameplate, which Core's data does not know: before the NPCs.
units.nameplate1 = { name = "Stonetusk Boar", quest = "Stonetusk Boar slain: 1/5" }
units.nameplate2 = { name = "Brother Paxton" }
units.nameplate3 = { name = "Someone Else", player = true, quest = "Someone Else slain: 0/1" }
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
names = Wanted.Names()
check(names[#names - 1] == "Stonetusk Boar" and names[#names] == "Deputy Willem", "a marked creature, before the NPCs")
check(not Joined(names):find("Paxton") and not Joined(names):find("Someone"), "nothing unmarked, no player")

-- The guide switched off: its names go.
Core.Set(ns.name, "guide", false)
check(Joined(Wanted.Names()) == "Kobold Vermin, Kobold Laborer, Kobold Worker, Kobold Geomancer, Stonetusk Boar, Deputy Willem",
    "without the guide: the quests' names only")
Core.Set(ns.name, "guide", true)
-- The guide gone (unloaded, or its ways changed): the quests still.
W.loaded[known.addon] = nil
check(Wanted.Names()[1] == "Kobold Vermin" and #Wanted.Names() == 6, "no guide: the quests' names")
W.loaded[known.addon] = true
guide[known.part][known.lists] = function() error("changed") end
check(#Wanted.Names() == 6, "a guide whose function fails counts as not there")
guide[known.part][known.lists] = function() return unpack(guideLists) end

-- The quest log changes: read anew half a second later; a marked creature is looked for again on the plates shown.
log.complete[10] = true
W.Fire("QUEST_LOG_UPDATE")
W.Wait(1)
names = Wanted.Names()
check(Joined(names):find("Marshal Dughan, Deputy Willem$") and not Joined(names):find("Laborer"),
    "a finished quest: its NPC, in the log's order, and no more creatures")
check(Joined(names):find("Stonetusk Boar", 1, true), "the plate still shown is looked at again")
log.complete[10] = nil
W.Fire("QUEST_LOG_UPDATE")
W.Wait(1)

-- Another language: Core's English names are not used; the guide's and the game's marks are.
language = "deDE"
W.Fire("QUEST_LOG_UPDATE")
W.Wait(1)
check(Joined(Wanted.Names()) == "Kobold Vermin, Defias Thug, Garrick Padfoot, Marshal McBride, Stonetusk Boar",
    "on a German client: the guide's names and the marked creature")
language = "enUS"
W.Fire("QUEST_LOG_UPDATE")
W.Wait(1)

-------------------------------------------------------------------------------
--  The macro of Find
-------------------------------------------------------------------------------
local macro = Key.Macro({ "Kobold Vermin", "Bad;Name", "Marshal McBride" })
check(macro == "/cleartarget\n/targetexact [noexists][dead] Kobold Vermin\n/targetexact [noexists][dead] Marshal McBride\n"
    .. "/cleartarget [dead]\n/tm [exists] !8\n/startattack [harm,nodead]", "Find: let go, the names in order, mark, attack: " .. macro)
check(Key.Macro({}) == "", "nothing wanted: an empty macro")
local many = {}
for index = 1, 60 do many[index] = ("A Rather Long Creature Name %02d"):format(index) end
macro = Key.Macro(many)
check(#macro <= Key.ROOM and macro:find("Name 01", 1, true) and not macro:find("Name 60", 1, true), "as many as fit, the first first")
check(macro:sub(-27) == "/startattack [harm,nodead]" or macro:find("/startattack %[harm,nodead%]$"), "the end always there")
Core.Set(ns.name, "skull", false)
check(not Key.Macro({ "Kobold Vermin" }):find("/tm", 1, true), "no skull: no mark")
check(fight:GetAttribute("macrotext") == "/startattack [harm,nodead]", "no skull: Fight only attacks")
Core.Set(ns.name, "skull", true)

-- The moment before a press: written from what is wanted now, out of a fight only.
guideLists[2] = { "Hogger" }
find._scripts.PreClick(find, "LeftButton", true)
check(find:GetAttribute("macrotext"):find("/targetexact [noexists][dead] Hogger\n", 1, true), "before a press: the guide's step now")
W.combat = true
guideLists[2] = { "Kobold Vermin", "Defias Thug" }
find._scripts.PreClick(find, "LeftButton", true)
check(find:GetAttribute("macrotext"):find("Hogger", 1, true), "in a fight the last macro stays")
W.combat = false
find._scripts.PreClick(find, "LeftButton", true)
check(not find:GetAttribute("macrotext"):find("Hogger", 1, true), "after the fight: anew")

-------------------------------------------------------------------------------
--  The key: what each state puts on it
-------------------------------------------------------------------------------
bound[FIND] = { "E", "SHIFT-E" }
W.Fire("UPDATE_BINDINGS")
check(header:GetAttribute("keys") == 2 and header:GetAttribute("key1") == "E", "the key's keys onto the header")
check(overrides.E == FIND and overrides["SHIFT-E"] == FIND, "no state yet: Find, above other overrides")

header:SetAttribute("state-mode", "loot")
check(overrides.E == "INTERACTTARGET" and overrides["SHIFT-E"] == "INTERACTTARGET", "a corpse with loot: Interact With Target")

units.target = { name = "Young Wolf" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "foe")
check(header:GetAttribute("wanted") == false and overrides.E == FIND, "a foe nobody wants: Find")
units.target = { name = "Kobold Laborer" }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("wanted") == true and overrides.E == FIGHT, "a wanted foe: Fight")
units.target = { name = "Stranger Boar", quest = "Stranger Boar slain: 0/3" }
W.Fire("PLAYER_TARGET_CHANGED")
check(overrides.E == FIGHT, "a foe the game marks for a quest: Fight")
units.target = { name = "Young Wolf" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "fight")
check(overrides.E == FIGHT, "in a fight any living foe: Fight")

units.target = { name = "Deputy Willem" }
W.Fire("PLAYER_TARGET_CHANGED")
header:SetAttribute("state-mode", "friend")
check(overrides.E == "INTERACTTARGET", "a wanted NPC: talk")
Core.Set(ns.name, "talk", false)
check(overrides.E == FIND, "Talk to NPCs off: Find")
Core.Set(ns.name, "talk", true)
check(overrides.E == "INTERACTTARGET", "on again: talk")
units.target = { name = "Brother Paxton" }
W.Fire("PLAYER_TARGET_CHANGED")
check(overrides.E == FIND, "an NPC nobody wants: Find")
units.target = { name = "Someone Else", player = true }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("wanted") == false, "a player is never wanted")

-- In a fight the module says nothing new: the target's wanted stays, the key's keys too, until it is over.
units.target = { name = "Deputy Willem" }
W.Fire("PLAYER_TARGET_CHANGED")
W.combat = true
units.target = { name = "Brother Paxton" }
W.Fire("PLAYER_TARGET_CHANGED")
check(header:GetAttribute("wanted") == true, "in a fight the attribute stays")
bound[FIND] = { "Q" }
W.Fire("UPDATE_BINDINGS")
check(header:GetAttribute("key1") == "E", "in a fight the keys stay")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(header:GetAttribute("wanted") == false, "after the fight: the target asked again")
check(header:GetAttribute("keys") == 1 and header:GetAttribute("key1") == "Q" and overrides.Q == FIND and overrides.E == nil,
    "after the fight: the new key")
header:SetAttribute("state-mode", "find")
check(overrides.Q == FIND, "nothing of these: Find")

-------------------------------------------------------------------------------
--  Loot first off and on, standing down
-------------------------------------------------------------------------------
Core.Set(ns.name, "loot", false)
check(not drivers[header].mode:find("softinteract", 1, true), "Loot first off: no loot state")
check(W.cvars.softTargetInteract == "2" and W.cvars.autoLootDefault == "0", "the game's settings back as they were")
check(next(ns.options.foundCVars) == nil, "nothing kept any more")
Core.Set(ns.name, "loot", true)
check(drivers[header].mode:find("^%[@softinteract"), "on again: loot first")
-- Changed by the player since: left as the player has it.
W.cvars.autoLootDefault = "0"
Core.Set(ns.name, "loot", false)
check(W.cvars.softTargetInteract == "2" and W.cvars.autoLootDefault == "0", "a setting changed since is left alone")
Core.Set(ns.name, "loot", true)

ns.StandDown("a test")
check(ns.off and drivers[header].mode == nil, "standing down: the driver stopped")
check(next(overrides) == nil, "no override binding of ours")
check(find:GetAttribute("macrotext") == "" and fight:GetAttribute("macrotext") == "", "the macros empty")
check(W.cvars.softTargetInteract == "2" and W.cvars.autoLootDefault == "0", "the game's settings back")
units.target = { name = "Deputy Willem" }
W.Fire("PLAYER_TARGET_CHANGED")
check(next(overrides) == nil, "nothing more after standing down")

io.write(("Speed Leveling: all %d checks passed.\n"):format(passed))
