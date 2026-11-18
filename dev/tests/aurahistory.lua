-- Runs Core's aura log (src/Core/AuraLog.lua) and the Abilities module's aura history (src/Abilities/AuraHistory.lua) against
-- the stand-in client (wowstub.lua): the buffs and debuffs seen on whoever you can attack, never a friend; when each
-- came, on whom, from whom, its duration, dispel type and stacks; whether the cast that gave it could be interrupted; an
-- aura gone; a fight in which the game hides the auras (W.Secret): nothing hidden kept or compared, nothing closed, a
-- spell the game shows kept, the rest once the fight is over with the time it came; the most kept; the window on the
-- full screen, newest on top, its icon's tooltip and menu, what it shows, the search, clearing; which spells the
-- game hides (/sane secrets); your casts and the game's meter after a fight; your group's casts shared. At its end it
-- runs again as Retail loads the module ("retail": W.Play).
-- Usage, from the project folder:  lua5.1 dev/tests/aurahistory.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
local RETAIL = arg[1] == "retail"
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
local fight = require("combatclient").Install(W)
local units = fight.units

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:SetClampedToScreen(on) self._clamped = on end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:GetFrameLevel() return self._level or 1 end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:IsProtected() return self._protected or false end
function methods:SetTexture(texture, wrap) self._texture, self._wrap = texture, wrap return true end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
local function noop() end
function methods:CreateAnimationGroup()
    local group = setmetatable({}, { __index = function() return noop end })
    function group:CreateAnimation() return setmetatable({}, { __index = function() return noop end }) end
    return group
end
W.templates.PagingControlsHorizontalTemplate = function(controls)
    controls.PageText = W.NewWidget("FontString", nil, controls)
    function controls:GetCurrentPage() return 1 end
end
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
EasingUtil = { OutQuartic = function(p) return 1 - (1 - p) ^ 4 end }
IsMouseButtonDown = function() return false end
GetCursorPosition = function() return 0, 0 end
GetBindingKey, GetBindingText = function() end, function(key) return key end
EventUtil = { ContinueOnAddOnLoaded = function() end }
TalentMicroButton, SpellbookMicroButton = W.NewWidget("Button", "TalentMicroButton"), W.NewWidget("Button", "SpellbookMicroButton")
ClearOverrideBindings, SetOverrideBinding = function() end, function() end
C_SpellBook.IsSpellBookItemLooseFlyoutMember = function() return false end
C_SpecializationInfo = { GetCombatConfigIDForSpecGroup = function(group) return 100 + group end }
for _, bar in ipairs({ MainActionBar, StanceBar }) do
    bar.UpdateDividers, bar.Update, bar.UpdateState = function() end, function() end, function() end
end
for _, button in ipairs(MainActionBar.actionButtons) do button.Update, button.UpdateButtonArt = function() end, function() end end
-- The game's linear list: a line's height set once.
local linear = CreateScrollBoxListLinearView
CreateScrollBoxListLinearView = function()
    local view = linear()
    function view:SetElementExtent(extent) self.extentEach = extent end
    return view
end

-- The clock of the day: a second of it for each of the game's.
local DAY = 1700000000
time = function() return DAY + math.floor(W.clock) end

-- You, Hogger (a boss here, for the list's On bosses), a gnoll on a nameplate, and a friend on another.
units.player = { name = "Droopy", surname = "Fairwind", player = true, class = "DRUID", level = 60, health = 850, most = 1000 }
units.target = { name = "Hogger", level = 11, foe = true, classification = "worldboss", health = 100, most = 100 }
units.nameplate1 = { name = "Riverpaw Gnoll", level = 10, foe = true, health = 100, most = 100 }
units.nameplate2 = { name = "Brisa", surname = "Ashford", player = true, level = 60, health = 100, most = 100 }
local GUIDS = { player = "Player-1-1", target = "Creature-0-1-1-1-448-1", nameplate1 = "Creature-0-1-1-1-117-2",
                nameplate2 = "Player-1-2" }
UnitGUID = function(unit) return GUIDS[unit] end
C_NamePlate = { GetNamePlateForUnit = function() end } -- no plate of the game's to dress

-- The auras on each unit, and what the game hides in a fight: every value, save a spell it shows (plain).
local secret, plain = false, {}
C_Secrets = { ShouldAurasBeSecret = function() return secret end }
local function On(unit, filter, aura)
    W.auras[unit] = W.auras[unit] or { HELPFUL = {}, HARMFUL = {} }
    table.insert(W.auras[unit][filter], aura)
    return aura
end
local function Off(unit, filter, aura)
    for index, held in ipairs(W.auras[unit][filter]) do
        if held == aura then table.remove(W.auras[unit][filter], index) end
    end
end
local read = C_UnitAuras.GetUnitAuras
C_UnitAuras.GetUnitAuras = function(unit, filter)
    local found = read(unit, filter)
    if not secret then return found end
    for index, aura in ipairs(found) do
        if not plain[aura.spellId] then
            local hidden = {}
            for key in pairs(aura) do hidden[key] = W.Secret() end
            -- every other one a table the game keeps closed: indexing it errors
            if index % 2 == 0 then setmetatable(hidden, { __index = function() error("secret table") end }) end
            found[index] = index % 2 == 0 and setmetatable({}, getmetatable(hidden)) or hidden
        end
    end
    return found
end

-- A unit's cast, as UnitCastingInfo tells it: its name, whether it cannot be interrupted, its spell.
local casting = {}
UnitCastingInfo = function(unit)
    local cast = casting[unit]
    if cast then return cast.name, cast.name, 136000, 0, 1500, false, "Cast-1", cast.locked, cast.id end
end
UnitChannelInfo = function() end
C_Spell.GetSpellName = function(id) return ({ [7386] = "Sunder Armor", [1715] = "Hamstring" })[id] end

-- The tooltip's two ways in.
function GameTooltip:SetSpellByID(id) self._spell, self._aura = id, nil end
function GameTooltip:SetUnitAuraByAuraInstanceID(unit, instance) self._aura, self._spell = { unit, instance }, nil end

if RETAIL then W.Play("retail") end
W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
-- The history is on Abilities' full screen; the menu of its auras is Combat's (your marks), through Core.
local ns = W.LoadAddon(root, "Abilities", "SaneUI_Abilities")
local combat = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Abilities")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Abilities == ns and not ns.off and not combat.off, "the modules are made and started")
local Log, History, TEXT = Core.AuraLog, ns.AuraHistory, ns.TEXT
check(Log and History and #Log.Entries() == 0, "Core keeps the log, Abilities shows it; nothing in it yet")

local function Find(name, on)
    for _, entry in ipairs(Log.Entries()) do
        if entry.name == name and (not on or entry.on == on) then return entry end
    end
end
local function Count(name)
    local found = 0
    for _, entry in ipairs(Log.Entries()) do
        if entry.name == name then found = found + 1 end
    end
    return found
end
local function Changed(unit)
    W.Fire("UNIT_AURA", unit, { isFullUpdate = true })
    W.Wait(0.05)
end

-------------------------------------------------------------------------------
--  Out of a fight: everything the game tells
-------------------------------------------------------------------------------
-- Hogger begins a cast of Frenzy that can be interrupted, and gets its buff; you put three Sunder Armor on him.
casting.target = { name = "Frenzy", id = 8599, locked = false }
W.Fire("UNIT_SPELLCAST_START", "target", "Cast-1", 8599)
casting.target = nil
W.Wait(1)
local now = W.clock
local FRENZY = On("target", "HELPFUL", { name = "Frenzy", spellId = 8599, icon = 132152, auraInstanceID = 21, duration = 120,
                                       expirationTime = now + 120, sourceUnit = "target", dispelName = "Magic",
                                       isStealable = true, applications = 0 })
local SUNDER = On("target", "HARMFUL", { name = "Sunder Armor", spellId = 7386, icon = 132363, auraInstanceID = 22,
                                       duration = 30, expirationTime = now + 30, sourceUnit = "player", applications = 3 })
Changed("target")
local frenzy, sunder = Find("Frenzy"), Find("Sunder Armor")
check(frenzy and sunder and #Log.Entries() == 2, "your target's buff and debuff, one entry each")
check(frenzy.on == "Hogger" and frenzy.boss and frenzy.from == "Hogger" and not frenzy.harmful and frenzy.id == 8599
    and frenzy.icon == 132152, "the buff: what, on whom (a boss), from whom")
check(frenzy.stamp == time() and frenzy.lasts == 120 and frenzy.ends == time() + 120 and not frenzy.gone,
    "when it came, how long it lasts, when it is due to end")
check(frenzy.dispel == "Magic" and frenzy.steal, "that it can be dispelled (Magic) and stolen")
check(frenzy.cast == true and not frenzy.instant, "its cast was seen, and could be interrupted")
check(sunder.harmful and sunder.stacks == 3 and sunder.from ~= nil and sunder.from:find("Droopy", 1, true)
    and sunder.dispel == nil and sunder.cast == nil, "the debuff: yours, three stacks, nothing to dispel, no cast of his")
check(Log.Live(frenzy) == "target", "both still on: the unit they are on")

-- Two more Sunder Armor: the same aura, more stacks, no new entry; its time renewed.
W.Wait(10)
SUNDER.applications, SUNDER.expirationTime = 5, W.clock + 30
Changed("target")
check(Count("Sunder Armor") == 1 and sunder.stacks == 5 and sunder.ends == time() + 30, "renewed: its stacks and end, one entry")

-- Frenzy dispelled: it went, at that moment.
W.Wait(5)
Off("target", "HELPFUL", FRENZY)
Changed("target")
check(frenzy.gone == time() and Log.Live(frenzy) == nil and Log.Live(sunder) == "target", "the one dispelled went then")

-- An instant cast of a gnoll: a debuff from it, which nothing could have interrupted.
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
W.Wait(0.05)
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate1", "Cast-2", 1715)
On("nameplate1", "HARMFUL", { name = "Hamstring", spellId = 1715, icon = 132316, auraInstanceID = 31, duration = 15,
                              expirationTime = W.clock + 15, sourceUnit = "nameplate1", applications = 0 })
On("nameplate1", "HELPFUL", { name = "Thick Hide", spellId = 9999, icon = 132090, auraInstanceID = 32, duration = 0,
                              expirationTime = 0, applications = 0 })
Changed("nameplate1")
local hamstring, hide = Find("Hamstring"), Find("Thick Hide")
check(hamstring and hamstring.on == "Riverpaw Gnoll" and not hamstring.boss and hamstring.cast == false and hamstring.instant,
    "a nameplate's unit, heard by its own events: an instant cast's debuff")
check(hide and hide.lasts == 0 and hide.ends == nil and hide.from == nil, "an aura without an end, from nobody told")

-- A friend's plate: nothing of it.
On("nameplate2", "HELPFUL", { name = "Mark of the Wild", spellId = 1126, icon = 136078, auraInstanceID = 41, duration = 1800,
                              expirationTime = W.clock + 1800, sourceUnit = "player" })
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
W.Wait(0.05)
Changed("nameplate2")
check(not Find("Mark of the Wild"), "a friend's auras are not kept")

-------------------------------------------------------------------------------
--  A fight: the game hides the auras
-------------------------------------------------------------------------------
local before = #Log.Entries()
W.Combat(true)
secret = true
plain[1715] = true -- a spell the game shows addons in a fight
local fought = W.clock
On("target", "HELPFUL", { name = "Thrash", spellId = 3391, icon = 132152, auraInstanceID = 23, duration = 60,
                          expirationTime = fought + 60, sourceUnit = "target", applications = 0 })
On("target", "HELPFUL", { name = "Bloodrage", spellId = 2687, icon = 132277, auraInstanceID = 26, duration = 600,
                          expirationTime = fought + 600, sourceUnit = "target", applications = 0 })
On("target", "HARMFUL", { name = "Hamstring", spellId = 1715, icon = 132316, auraInstanceID = 24, duration = 15,
                          expirationTime = fought + 15, sourceUnit = "player", applications = 0 })
Changed("target")
check(#Log.Entries() == before, "in a fight a look waits a while (Core.AuraLog.FIGHT)")
W.Wait(Log.FIGHT + 0.1)
check(Find("Hamstring", "Hogger") and not Find("Thrash") and #Log.Entries() == before + 1,
    "in a fight only a spell the game shows is kept, nothing hidden")
check(Log.Live(sunder) == "target" and not sunder.gone, "and what it hides is not taken for gone")

-- The fight over: every unit looked at again, what is still on kept with the time it came.
W.Wait(20)
secret = false
W.Combat(false)
W.Wait(0.05)
local thrash = Find("Thrash")
check(thrash and thrash.stamp == DAY + math.floor(fought) and thrash.on == "Hogger",
    "once the fight is over, the aura it hid, with the time it came")
check(Count("Hamstring") == 2, "the one kept in the fight once only")
check(Find("Bloodrage") and next(Core.errors) == nil, "a closed table of the game's is read without an error")

-- Kept per character, the newest Core.AuraLog.MOST.
local most = Log.MOST
Log.MOST = #Log.Entries() + 1
for index = 1, 3 do
    On("nameplate1", "HARMFUL", { name = "Rend " .. index, spellId = 772 + index, icon = 132155, auraInstanceID = 50 + index,
                                  duration = 21, expirationTime = W.clock + 21, sourceUnit = "player", applications = 0 })
end
Changed("nameplate1")
check(#Log.Entries() == Log.MOST and Find("Rend 3") and not Find("Frenzy"), "past the most, the oldest go first")
check(Core.Character(Core.name).auraLog == Log.Entries(), "kept with the character's saved settings")
Log.MOST = most

-------------------------------------------------------------------------------
--  What a fight hides: your own casts, and the fight's spells from the game's meter
-------------------------------------------------------------------------------
local NAMES = { [772] = "Rend", [78] = "Heroic Strike", [12294] = "Mortal Strike", [6603] = "Auto Attack",
                [6016] = "Pierce Armor", [6552] = "Pummel", [7386] = "Sunder Armor", [1715] = "Hamstring" }
C_Spell.GetSpellName = function(id) return NAMES[id] end
C_Spell.GetSpellTexture = function(id) return 130000 + id end
C_Spell.IsSpellHarmful = function(id) return id ~= 0 end
-- Core's data: Rend puts an aura on, Heroic Strike does not.
local Data, set = Core.Data, Core.Data.Set
local SPELLS = { [772] = { name = "Rend", effects = { { effect = 6, aura = 3 } } },
                 [78] = { name = "Heroic Strike", effects = { { effect = 2, aura = 0 } } } }
Data.Set = function(name)
    if name == "Spells" then return { Ready = function() return true end, Get = function(_, id) return SPELLS[id] end } end
    if name == "Auras" then return { Ready = function() return true end, Get = function() end } end
    return set(name)
end
check(Log.Leaves(772) and not Log.Leaves(78) and not Log.Leaves(99999), "Core's data tells which spells put an aura on")

-- A fight: your Rend on Hogger, then a Heroic Strike; the game hides the auras.
local me = Core.FullName("player")
W.Combat(true)
secret = true
W.Fire("UNIT_SPELLCAST_SENT", "player", "Hogger", "Cast-9", 772)
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-9", 772)
local rendAt = W.clock
W.Fire("UNIT_SPELLCAST_SENT", "player", "Hogger", "Cast-10", 78)
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-10", 78)
local rend = Find("Rend")
check(rend and rend.kind == "cast" and rend.on == "Hogger" and rend.from == me and rend.harmful and rend.stamp == time()
    and rend.icon == 130772, "your cast in a fight of a spell that puts an aura on: on whom, when")
check(not Find("Heroic Strike"), "a strike that puts none on is left out")
local REND = On("target", "HARMFUL", { name = "Rend", spellId = 772, icon = 132155, auraInstanceID = 27, duration = 21,
                                       expirationTime = rendAt + 21, sourceUnit = "player", applications = 0 })
Changed("target")
W.Wait(Log.FIGHT + 0.1)
check(Count("Rend") == 1 and rend.kind == "cast", "in the fight its aura stays hidden")

-- The game's meter: the fight's spells of you and Brisa, plain once it is over.
Enum.DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, Hps = 3, Interrupts = 5, Dispels = 6, DamageTaken = 7 }
Enum.DamageMeterSessionType = { Overall = 0, Current = 1, Expired = 2 }
local sessions = {}
local FIGHT = {
    [0] = { ["Player-1-1"] = { { spellID = 772 }, { spellID = 6603 }, { spellID = 12294 } },
            ["Player-1-2"] = { { spellID = 772 }, { spellID = 12294, creatureName = "Wolf" } } },
    [7] = { ["Player-1-1"] = { { spellID = 6016, combatSpellDetails = { unitName = "Hogger" } } },
            ["Player-1-2"] = { { spellID = 6016, combatSpellDetails = { unitName = "Hogger" } } } },
    [5] = { ["Player-1-2"] = { { spellID = 6552, combatSpellDetails = { unitName = "Hogger" } } } },
}
local WHO = { ["Player-1-1"] = { name = me, isLocalPlayer = true }, ["Player-1-2"] = { name = "Brisa" } }
C_DamageMeter = {
    GetAvailableCombatSessions = function() return sessions end,
    GetCombatSessionFromID = function(_, kind)
        if secret then error("hidden in a fight") end
        local sources = {}
        for guid in pairs(FIGHT[kind] or {}) do
            sources[#sources + 1] = { sourceGUID = guid, name = WHO[guid].name, isLocalPlayer = WHO[guid].isLocalPlayer or false }
        end
        table.sort(sources, function(a, b) return a.sourceGUID < b.sourceGUID end)
        return { combatSources = sources }
    end,
    GetCombatSessionSourceFromID = function(_, kind, guid)
        local spells = {}
        for index, spell in ipairs(FIGHT[kind] and FIGHT[kind][guid] or {}) do
            spells[index] = { spellID = spell.spellID, creatureName = spell.creatureName or "",
                              combatSpellDetails = spell.combatSpellDetails or { unitName = "" } }
        end
        return { combatSpells = spells }
    end,
}
-- The game's newest fight by its type too (Combat's meter asks so), the same one.
C_DamageMeter.GetCombatSessionFromType = function(_, kind) return C_DamageMeter.GetCombatSessionFromID(1, kind) end
C_DamageMeter.GetCombatSessionSourceFromType = function(_, kind, guid) return C_DamageMeter.GetCombatSessionSourceFromID(1, kind, guid) end
sessions[1] = { sessionID = 1, name = "Hogger", durationSeconds = 30 }

-- In a party: what is sent to it after the fight (Core.Wire's block, caught here).
IsInGroup = function() return true end
local sent = {}
local sendBlock = Core.Wire.SendBlock
Core.Wire.SendBlock = function(kind, text, channel) sent[#sent + 1] = { kind = kind, text = text, channel = channel } return true end
W.Wait(5)
secret = false
W.Combat(false)
W.Wait(0.05)
check(Count("Rend") == 1 and rend.kind == nil and rend.lasts == 21 and rend.ends == rend.stamp + 21 and Log.Live(rend) == "target",
    "after the fight its aura found on Hogger is folded into your cast, one entry")
check(not Find("Mortal Strike"), "the meter is read a moment after the fight (Core.AuraLog.AFTER)")
W.Wait(Log.AFTER + 0.1)
local function Fight(name, what, from)
    for _, entry in ipairs(Log.Entries()) do
        if entry.kind == "fight" and entry.name == name and entry.what == what and (not from or entry.from == from) then return entry end
    end
end
local strike, pet = Fight("Mortal Strike", "damage", me), Fight("Mortal Strike", "damage", "Wolf")
check(strike and strike.on == "Hogger" and strike.fight == "Hogger" and strike.harmful and strike.stamp == time()
    and strike.icon == 142294, "the fight's spells: your damage, on the fight's foe, its name with it")
check(pet and Fight("Rend", "damage", "Brisa"), "a member's, and a pet's by its name")
check(not Fight("Rend", "damage", me) and not Fight("Auto Attack", "damage"), "not your casts logged already, no swings")
local pierce = Fight("Pierce Armor", "taken")
check(pierce and pierce.from == "Hogger" and pierce.hits == 2 and (pierce.on == me or pierce.on == "Brisa"),
    "the foe's spell that hit the group: one entry, from him, how many it hit")
local pummel = Fight("Pummel", "interrupt", "Brisa")
check(pummel and pummel.on == "Hogger", "an interrupt in the fight, on whom")
local fights = #Log.Entries()
W.Combat(true)
W.Combat(false)
W.Wait(Log.AFTER + 0.1)
check(#Log.Entries() == fights, "a fight the meter holds is read once")
check(not ns.off, "the module stands, its meter reading the same fights")

-------------------------------------------------------------------------------
--  Your group's casts: yours sent after a fight, theirs taken in
-------------------------------------------------------------------------------
local skew = GetServerTime() - time()
check(#sent == 1 and sent[1].kind == Log.KIND and sent[1].channel == "PARTY"
    and sent[1].text == ("772\t%d\tHogger"):format(rend.stamp + skew),
    "after the fight your casts of it go to your party once: the spell, when by the server's clock, whom at")
check(not sent[1].text:find("^78\t") and not sent[1].text:find("\n78\t"), "not a cast the log left out")
local brisa = Core.FullName("nameplate2")
On("target", "HARMFUL", { name = "Hamstring", spellId = 1715, icon = 132316, auraInstanceID = 28, duration = 15,
                          expirationTime = W.clock + 15, sourceUnit = "nameplate2", applications = 0 })
Changed("target")
local theirs
for _, entry in ipairs(Log.Entries()) do
    if entry.id == 1715 and entry.from == brisa then theirs = entry end
end
local before = #Log.Entries()
local server = GetServerTime()
Log.Heard(brisa, ("1715\t%d\tHogger"):format(server), "PARTY")
check(theirs and theirs.shared and #Log.Entries() == before, "a member's cast that is an aura seen already marks it")
Log.Heard(brisa, ("772\t%d\tHogger\nnonsense\t1\n6552\t%d\tHogger"):format(server - 20, server - 7200), "PARTY")
local shared = Log.Entries()[#Log.Entries()]
check(#Log.Entries() == before + 1 and shared.kind == "cast" and shared.shared and shared.from == brisa and shared.id == 772
    and shared.on == "Hogger" and shared.stamp == time() - 20 and shared.name == "Rend",
    "a member's cast comes in from them, at its time on this computer's clock; a bad or too old line is left")
Log.Heard(brisa, ("772\t%d\tHogger"):format(server - 20), "PARTY")
Log.Heard(brisa, ("772\t%d\tHogger"):format(server - 3), "WHISPER")
check(#Log.Entries() == before + 1, "heard twice, one entry; a whisper not taken")

-- The switch Share casts in a fight with your group: off, nothing sent nor taken.
Core.Set("Abilities", "auraShare", false)
Log.Heard(brisa, ("1715\t%d\tHogger"):format(server - 30), "PARTY")
check(#Log.Entries() == before + 1, "off: a member's casts not taken")
W.Combat(true)
secret = true
W.Fire("UNIT_SPELLCAST_SENT", "player", "Hogger", "Cast-11", 772)
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-11", 772)
secret = false
W.Combat(false)
W.Wait(Log.AFTER + 0.1)
check(#sent == 1, "and yours not sent")
Core.Set("Abilities", "auraShare", true)
Core.Wire.SendBlock, IsInGroup = sendBlock, function() return false end

-------------------------------------------------------------------------------
--  The window on the full screen
-------------------------------------------------------------------------------
local spec
for _, window in ipairs(ns.Board.layouts.options.windows()) do
    if window.key == History.KEY then spec = window end
end
check(spec and spec.title == TEXT.historyTitle and spec.icon == ns.Board.ICONS.history, "a window of the full screen, in its list")
local panel = { body = CreateFrame("Frame", nil, UIParent) }
spec.build(panel)
spec.show(panel, true)
local lines, box = History.lines, History.box
check(#lines == #Log.Entries() and lines[1].entry == Log.Entries()[#Log.Entries()], "every entry, newest on top")
check(box.view.extentEach == History.ROW, "lines of one height")

-- A line as Thrash shows it: its icon, its words in each column.
local row
for index, line in ipairs(box.lines) do
    if line.entry == thrash then row = box.rows[index] end
end
check(row and row.icon.entry == thrash and row.icon.parts.picture._texture == 132152 and row.name._text == "Thrash"
    and row.kind._text == TEXT.historyBuff, "its icon and name, a buff")
check(row.cells.on.top._text == History.SKULL .. "Hogger" and row.cells.on.under._text == TEXT.historyFrom:format("Hogger"),
    "on whom, a boss with the skull, and from whom")
check(row.cells.came.top._text == Core.ClockAt(thrash.stamp, true) and #row.cells.came.top._text == 8,
    "when it came, to the second")
check(row.cells.lasts.top._text == "1m" and row.cells.lasts.under._text == TEXT.historyOn, "its duration, on now")
check(row.cells.removable.top._text == TEXT.historyNone and row.cells.cast.top._text == TEXT.historyNone,
    "nothing to dispel, no cast seen")

-- A line of the fight: what it was, on whom with how many more, the fight under its time, no duration known.
local fought
for index, line in ipairs(box.lines) do
    if line.entry == pierce then fought = box.rows[index] end
end
check(fought and fought.kind._text == TEXT.historyWhat_taken and fought.cells.on.top._text == pierce.on .. " +1"
    and fought.cells.on.under._text == TEXT.historyFrom:format("Hogger")
    and fought.cells.came.under._text == TEXT.historyFight:format("Hogger") and fought.cells.lasts.top._text == TEXT.historyNone,
    "a line of the fight: hit your group, from Hogger, the fight's name, no duration")

local member
for index, line in ipairs(box.lines) do
    if line.entry == shared then member = box.rows[index] end
end
check(member and member.kind._text == TEXT.historyCastShared and member.cells.on.under._text == TEXT.historyFrom:format(brisa),
    "a member's cast: Cast in a fight, from them")

-- Its tooltip: the aura's own while it is on, else the spell's; a click its menu, as the buffs on the unit frames.
row.icon._scripts.OnEnter(row.icon)
check(GameTooltip._aura and GameTooltip._aura[1] == "target" and GameTooltip._aura[2] == 23, "on: the aura's own tooltip")
row.icon._scripts.OnLeave(row.icon)
local gone
for index, line in ipairs(box.lines) do
    if line.entry.name == "Rend 1" then gone = box.rows[index] end
end
Off("nameplate1", "HARMFUL", W.auras.nameplate1.HARMFUL[#W.auras.nameplate1.HARMFUL - 2])
Changed("nameplate1")
gone.icon._scripts.OnEnter(gone.icon)
check(GameTooltip._spell == 773 and not GameTooltip._aura, "gone: the spell's tooltip")
local menus = #W.menus
row.icon._scripts.OnMouseUp(row.icon, "LeftButton")
local menu = W.menus[#W.menus]
check(#W.menus == menus + 1 and menu.owner == row.icon and menu[1].title == "Thrash", "a click: the aura's menu")
local track
for _, item in ipairs(menu) do
    if item.text == TEXT.trackAdd then track = item end
end
check(track ~= nil, "with Add tracking in it, as the buffs' menu has")

-- Kept up to date while shown: a new aura comes in.
On("target", "HARMFUL", { name = "Faerie Fire", spellId = 770, icon = 136033, auraInstanceID = 25, duration = 40,
                          expirationTime = W.clock + 40, sourceUnit = "player", applications = 0 })
Changed("target")
W.Wait(0.05)
check(History.lines[1].entry.name == "Faerie Fire", "a new aura on top while it is shown")

-- What it shows: the dropdown's choices, then the search.
local choices = {}
for _, item in ipairs(History.menu._items) do
    if item.text then choices[#choices + 1] = item end
end
check(#choices == #History.SHOWS + 1 and choices[#choices].text == TEXT.historyClear, "the kinds to show, and Clear history")
choices[3].fn() -- Debuffs
local debuffs = true
for _, line in ipairs(History.lines) do debuffs = debuffs and line.entry.harmful end
check(ns.store.auraHistoryShow == "debuffs" and debuffs and #History.lines > 0, "Debuffs: those alone")
choices[4].fn() -- On bosses
local bosses = true
for _, line in ipairs(History.lines) do bosses = bosses and line.entry.boss end
check(bosses and #History.lines > 0, "On bosses: those on a boss alone")
choices[5].fn() -- From fights
local fightsOnly = true
for _, line in ipairs(History.lines) do fightsOnly = fightsOnly and line.entry.kind ~= nil end
check(fightsOnly and #History.lines > 0, "From fights: the meter's and your casts alone")
choices[1].fn()
spec.search(panel, "brisa")
local byBrisa = #History.lines > 0
for _, line in ipairs(History.lines) do
    local entry = line.entry
    byBrisa = byBrisa and ((entry.from or ""):find("Brisa", 1, true) or (entry.on or ""):find("Brisa", 1, true)) ~= nil
end
check(byBrisa and History.lines[1].entry.from == brisa, "the search finds by whom from")
spec.search(panel, "gnoll")
local gnolls = true
for _, line in ipairs(History.lines) do gnolls = gnolls and line.entry.on == "Riverpaw Gnoll" end
check(gnolls and #History.lines > 0, "the search finds by whom it was on")
spec.search(panel, "faerie")
check(#History.lines == 1 and History.lines[1].entry.name == "Faerie Fire", "and by the aura's name")
spec.search(panel, "")

-- Cleared, once you say yes.
local popups = #W.popups
choices[#choices].fn()
check(#W.popups == popups + 1 and #Log.Entries() > 0, "Clear history asks first")
W.popups[#W.popups].data.callback()
check(#Log.Entries() == 0 and #History.lines == 0 and History.lines and not ns.off, "and then the list is empty")
spec.show(panel, false)

-- Durations and the clock.
check(History.Span(45) == "45s" and History.Span(130) == "2m 10s" and History.Span(120) == "2m" and History.Span(3600) == "1h"
    and History.Span(3900) == "1h 5m", "durations short: 45s, 2m 10s, 1h 5m")
check(Core.ClockAt(DAY, true) == os.date("%H:%M:%S", DAY), "the clock to the second, as the setting Units says")
check(not ns.off and #W.errors == 0, "nothing failed")

-------------------------------------------------------------------------------
--  Which spells the game hides (/sane secrets: Core's Secrecy.lua)
-------------------------------------------------------------------------------
-- The game's answers for a few spells (0 never hidden, 1 always, 2 in a fight), the rest not there.
local LEVELS = { [772] = { 2, 0 }, [1715] = { 0, 2 }, [7386] = { 2, 2 }, [40001] = { 1, 1 } }
C_Spell.DoesSpellExist = function(id) return LEVELS[id] ~= nil end
C_Spell.GetSpellName = function(id) return ({ [772] = "Rend", [1715] = "Hamstring", [7386] = "Sunder Armor", [40001] = "Shroud" })[id] end
C_Secrets.GetSpellAuraSecrecy = function(id) return LEVELS[id][1] end
C_Secrets.GetSpellCastSecrecy = function(id) return LEVELS[id][2] end
local Secrecy = Core.Secrecy
Secrecy.TOP, Secrecy.STEP = 50000, 10000
W.Combat(true)
SlashCmdList.SANEUI("secrets")
W.Wait(0.05)
check(Core.Store(Core.name).secrecy == nil, "in a fight the scan waits")
W.Combat(false)
W.Wait(1.1)
local answer = Core.Store(Core.name).secrecy
check(answer and answer.spells == 4 and answer.top == 50000 and answer.game == Core.GAME,
    "after the fight it goes on: every spell there is asked")
check(answer.aura[0][1715] == "Hamstring" and answer.aura[1][40001] == "Shroud" and answer.aura[0][772] == nil
    and answer.cast[0][772] == "Rend" and answer.counts.aura[2] == 2 and answer.counts.cast[2] == 2,
    "the visible and the always hidden kept by name, the ones hidden in a fight counted")
SlashCmdList.SANEUI("secrets clear")
check(Core.Store(Core.name).secrecy == nil, "/sane secrets clear forgets it")

-- As Retail loads the module: this file once more, in a client of its own.
if not RETAIL then
    check(os.execute(("lua5.1 '%s/dev/tests/aurahistory.lua' retail"):format(root)) == 0,
        "in Retail the aura history works as in Forever")
end

io.write(("Aura history%s: all %d checks passed.\n"):format(RETAIL and " in Retail" or "", passed))
