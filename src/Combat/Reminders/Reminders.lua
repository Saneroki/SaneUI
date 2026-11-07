local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders
--  A reminder watches one buff or debuff, by its name (so any rank of it), on
--  you or the unit it was made on, and puts its icon on a reminder bar (Bars.lua)
--  while its settings want it; or, placed on the party and raid frames, on each
--  member's frame (Group.lua); or on the nameplates, under each plate
--  (Plates.lua). Kept per character, a buff being a character's, with the
--  bars, one at first; a bar made is yours until you delete it:
--      bar       which reminder bar: its number, which never changes; GROUP:
--                the party and raid frames; PLATES: the nameplates. A new
--                one goes on the first bar (Saneroki, 2026-11-07)
--      missing   shown while the aura is not there
--      active    shown while it is
--      early     with missing: seconds before it runs out to show it already
--      combat    "any", "out" (only out of a fight), "in" (only in one)
--      noRest    not shown in resting areas (cities, inns)
--      own       only your own cast of it counts
--      class     shown only while you or one of your party or raid is of
--                that class (its token, "DRUID"); nil: any, no group needed
--                (When class in group, Saneroki, 2026-11-07: "my own
--                included")
--  An aura may have more than one: a copy (Reminders.Copy, the + in the
--  window) with its own place and settings.
--  A name of a family (Reminders.FAMILIES) counts all its names: a Gift of the
--  Wild for a Mark of the Wild. Made from the menu of a click on an aura or a
--  spell of the spellbook (Units/Lists.lua), set in the window (Editor.lua,
--  /sane reminders).
--
--  In a fight the game hides most auras from addons (ShouldSpellAuraBeSecret;
--  never-secret spells are read as ever), Forever's client even their numbers
--  and lists. Then what the last look saw counts, until it runs out by the
--  clock; where the game still answers for the aura's instance (GetAuraDuration),
--  that it is there. One that comes in a fight is known from your own cast of
--  that name (the game tells your casts): on for as long as it lasted when last
--  read (kept on the reminder, lasts), else until the fight ends.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Reminders = {}
ns.Reminders = Reminders

Reminders.EVERY = 0.25  -- seconds between looks, while there are reminders on bars
Reminders.MOST_EARLY = 9999 -- the longest offset, in seconds
Reminders.GROUP = 0     -- the place of the reminders on the party and raid frames: no bar has that number
Reminders.PLATES = -1   -- the place of the reminders on the nameplates: nor that one
-- Names that count as the same buff, a group's version with the one: any of them on a unit is enough, whoever cast it.
-- own: a paladin's blessing is each paladin's own on a unit, so a reminder of one starts with only yours counting, and
-- any of your blessings is enough; party: a shout reaches your own party only.
local BLESSINGS = { own = true,
    "Blessing of Kings", "Blessing of Wisdom", "Blessing of Might", "Blessing of Salvation", "Blessing of Light",
    "Blessing of Sanctuary", "Greater Blessing of Kings", "Greater Blessing of Wisdom", "Greater Blessing of Might",
    "Greater Blessing of Salvation", "Greater Blessing of Light", "Greater Blessing of Sanctuary" }
Reminders.FAMILIES = {
    { "Power Word: Fortitude", "Prayer of Fortitude" }, { "Divine Spirit", "Prayer of Spirit" },
    { "Shadow Protection", "Prayer of Shadow Protection" }, { "Arcane Intellect", "Arcane Brilliance" },
    { "Mark of the Wild", "Gift of the Wild" }, { "Battle Shout", party = true }, BLESSINGS,
}

local seen = setmetatable({}, { __mode = "k" }) -- [a reminder] = what was last known: { on, instance, ends, left }
local families = {} -- [a name] = its family
local ticker
local classes, looked = {}, nil -- your class and your party's or raid's ([token] = true), when last read

for _, family in ipairs(Reminders.FAMILIES) do
    for _, name in ipairs(family) do families[name] = family end
end

-- The family of that name, or nil.
function Reminders.Family(name)
    return families[name]
end

-- Whether the reminder watches a spell of that name: its own, or one of its family.
function Reminders.Watches(reminder, name)
    local family = families[reminder.name]
    return reminder.name == name or (family ~= nil and families[name] == family)
end

-- Whether the reminder reaches the unit: a party's family (a shout) your own party only.
function Reminders.Reaches(reminder, unit)
    local family = families[reminder.name]
    return not (family and family.party) or Core.Ask(UnitInParty, unit) or Core.Ask(UnitIsUnit, unit, "player")
end

-- Whether you or one of your party or raid is of that class (its token, "DRUID"): read again at most once a second, and
-- anew as the group changes.
function Reminders.InGroup(class)
    local now = GetTime()
    if not looked or now - looked >= 1 then
        looked = now
        wipe(classes)
        local _, own = Core.Ask(UnitClass, "player")
        if type(own) == "string" then classes[own] = true end
        local raid = Core.Ask(IsInRaid)
        local count = raid and (Core.Ask(GetNumGroupMembers) or 0) or 4
        for index = 1, count do
            local unit = (raid and "raid" or "party") .. index
            if Core.Ask(UnitExists, unit) then
                local _, token = Core.Ask(UnitClass, unit)
                if type(token) == "string" then classes[token] = true end
            end
        end
    end
    return classes[class] == true
end

-- Whether the reminder is on a bar: not on the party and raid frames, nor on the nameplates.
function Reminders.OnBar(reminder)
    return reminder.bar ~= Reminders.GROUP and reminder.bar ~= Reminders.PLATES
end

-- This character's reminders, in the order made.
function Reminders.List()
    local char = Core.Character(ns.name)
    char.reminders = char.reminders or {}
    return char.reminders
end

-- This character's bars: their numbers, in the order made.
function Reminders.Bars()
    local char = Core.Character(ns.name)
    char.reminderBars = char.reminderBars or { 1 }
    return char.reminderBars
end

-- A new bar, and its number.
function Reminders.AddBar()
    local bars = Reminders.Bars()
    local char = Core.Character(ns.name)
    char.lastBar = math.max(char.lastBar or 0, bars[#bars] or 0) + 1
    bars[#bars + 1] = char.lastBar
    Reminders.Apply()
    return char.lastBar
end

-- A bar gone, its reminders on the first of those left, so none is lost. The last bar stays.
function Reminders.TakeBar(bar)
    local bars = Reminders.Bars()
    if not bars[2] then return end
    for index = #bars, 1, -1 do
        if bars[index] == bar then table.remove(bars, index) end
    end
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.bar == bar then reminder.bar = bars[1] end
    end
    ns.ReminderBars.Drop(bar)
    Reminders.Apply()
end

-- The reminder of an aura ({ name, harmful, unit }), if it has one.
function Reminders.Find(spell)
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.name == spell.name and reminder.harmful == spell.harmful and reminder.unit == spell.unit then
            return reminder
        end
    end
    return nil
end

-- The first reminder of an aura of that name, if it has one (Edit tracked holds an aura by its name).
function Reminders.Named(name)
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.name == name then return reminder end
    end
    return nil
end

-- The reminder of that aura, made if it has none, on bar (a bar's number, GROUP or PLATES; nil: the first bar): a buff shown
-- when it is missing, a debuff on you or the party and raid frames when it is there, a debuff on another (yours on a
-- foe) when it is missing; only yours counting where its family says so (a blessing).
function Reminders.Make(spell, bar)
    local reminder = Reminders.Find(spell)
    if reminder then return reminder end
    bar = bar or Reminders.Bars()[1]
    local stays = spell.harmful and (spell.unit == "player" or bar == Reminders.GROUP)
    local family = families[spell.name]
    reminder = { id = spell.id, name = spell.name, icon = spell.icon, harmful = spell.harmful, unit = spell.unit,
                 bar = bar, missing = not stays, active = stays or false, early = 0, combat = "any", noRest = false,
                 own = family and family.own or false }
    table.insert(Reminders.List(), reminder)
    Reminders.Apply()
    return reminder
end

-- The aura tracked once more: a copy of the reminder, right after it, its own from now on.
function Reminders.Copy(reminder)
    local copy = {}
    for key, value in pairs(reminder) do
        if type(value) == "table" then
            copy[key] = {}
            for inner, each in pairs(value) do copy[key][inner] = each end
        else
            copy[key] = value
        end
    end
    local list = Reminders.List()
    local at = #list + 1
    for index, each in ipairs(list) do
        if each == reminder then at = index + 1 end
    end
    table.insert(list, at, copy)
    Reminders.Apply()
    return copy
end

function Reminders.Take(reminder)
    local list = Reminders.List()
    for index = #list, 1, -1 do
        if list[index] == reminder then table.remove(list, index) end
    end
    Reminders.Apply()
    ns.ReminderEditor.Refresh()
end

-- Whether the game hides this aura from addons now.
function Reminders.Hidden(reminder)
    local secrets = rawget(_G, "C_Secrets")
    if not (secrets and secrets.ShouldAurasBeSecret) then return Core.Restricted() end
    if Core.Ask(secrets.ShouldAurasBeSecret) == false then return false end
    return Core.Ask(secrets.ShouldSpellAuraBeSecret, reminder.id) ~= false
end
local Hidden = Reminders.Hidden

-- Whether a cast of that name reaches many: a group's version of a family (its names after the first; a greater
-- blessing), a shout.
function Reminders.Many(name)
    local family = families[name]
    if not family then return false end
    if family.party or name:find("^Greater ") then return true end
    return not family.own and family[1] ~= name
end

-- When an aura of that name the reminder watches, given now, runs out: by how long it lasted when last read; nil
-- where that is not known.
function Reminders.Ends(reminder, name)
    local lasts = reminder.lasts
    local seconds = lasts and (lasts[name] or lasts[reminder.name])
    return seconds and GetTime() + seconds or nil
end

-- How long an aura the reminder watches lasts, read where the game shows it, kept for a fight.
local function Learn(reminder, data)
    local name, seconds = Plain(data.name), Plain(data.duration)
    if type(name) ~= "string" or type(seconds) ~= "number" or seconds <= 0 then return end
    reminder.lasts = reminder.lasts or {}
    reminder.lasts[name] = seconds
end

-- Whether the game still has that aura instance on the unit: true; nil where it will not say (it fails on one gone,
-- and on any while it refuses addons auras: in a fight in Forever's client).
local function Still(unit, instance)
    local read = C_UnitAuras.GetAuraDuration
    if not read then return nil end
    local ok, duration = pcall(read, unit, instance)
    if ok and type(duration) ~= "nil" then return true end
    return nil
end

-- The reminder's aura on the unit, by any name of its family, only yours where it says so; nil where none is, or the
-- game hides it.
function Reminders.Aura(reminder, unit)
    local filter = (reminder.harmful and "HARMFUL" or "HELPFUL") .. (reminder.own and "|PLAYER" or "")
    local read = C_UnitAuras.GetAuraDataBySpellName
    local family = families[reminder.name]
    if not family then return Core.Ask(read, unit, reminder.name, filter) end
    for _, name in ipairs(family) do
        local data = Core.Ask(read, unit, name, filter)
        if type(data) == "table" then return data end
    end
    return nil
end

-- What is known of the reminder's aura on the unit now, kept in state (what was known; made where the game tells
-- it): { on, instance, ends, left (seconds, nil: none or unknown) }; nil where nothing is.
function Reminders.Known(reminder, unit, state)
    if Hidden(reminder) then
        if not state then return nil end
        if state.ends and state.ends <= GetTime() then
            if state.instance and Still(unit, state.instance) then
                state.ends = nil -- past its end and still there: renewed
            else
                state.on, state.instance, state.ends = false, nil, nil -- run out
            end
        end
    else
        state = state or {}
        local data = Reminders.Aura(reminder, unit)
        local ends = type(data) == "table" and Plain(data.expirationTime) or nil
        state.on = type(data) == "table"
        state.instance = state.on and Plain(data.auraInstanceID) or nil
        state.ends = ends and ends > 0 and ends or nil
        if state.on then Learn(reminder, data) end
    end
    state.left = state.ends and math.max(0, state.ends - GetTime()) or nil
    return state
end

-- What is known of a bar's reminder's aura now.
local function Look(reminder)
    seen[reminder] = Reminders.Known(reminder, reminder.unit, seen[reminder])
    return seen[reminder]
end

-- Whether the reminder's settings want it shown, with the aura as known, on unit (nil: the reminder's own).
function Reminders.Wanted(reminder, state, unit)
    if not state then return false end
    unit = unit or reminder.unit
    local fighting = InCombatLockdown()
    if (reminder.combat == "out" and fighting) or (reminder.combat == "in" and not fighting) then return false end
    if reminder.noRest and IsResting() then return false end
    if reminder.class and not Reminders.InGroup(reminder.class) then return false end
    if Core.Ask(UnitIsDeadOrGhost, "player") then return false end
    if unit ~= "player" then
        if not Core.Ask(UnitExists, unit) or Core.Ask(UnitIsDeadOrGhost, unit) then return false end
        local foe = reminder.harmful and reminder.bar ~= Reminders.GROUP -- a member's debuff is on a friend; a plate's on a foe
        if foe and Core.Ask(UnitCanAttack, "player", unit) == false then return false end
    end
    if not state.on then return reminder.missing end
    return reminder.active or (reminder.missing and state.left ~= nil and state.left <= reminder.early)
end

-- Whether any reminder is on a bar or the nameplates: the looks run.
local function Looked()
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.bar ~= Reminders.GROUP then return true end
    end
    return false
end

-- Every reminder of a bar looked at, every bar filled, then every nameplate (Plates.lua). In Edit Mode a bar shows all
-- it holds, to be placed.
function Reminders.Update()
    if ns.off then return end
    local bars = {}
    for _, bar in ipairs(Reminders.Bars()) do bars[bar] = {} end
    for _, reminder in ipairs(Reminders.List()) do
        local list = bars[reminder.bar]
        local state = list and Look(reminder)
        if list and (Core.EditMode.active or Reminders.Wanted(reminder, state)) then
            list[#list + 1] = { icon = reminder.icon, left = state and state.on and state.left or nil }
        end
    end
    for place, bar in ipairs(Reminders.Bars()) do ns.ReminderBars.Fill(bar, place, bars[bar]) end
    ns.PlateReminders.Update()
end

-- A menu's last line for an aura ({ id, name, icon, harmful, unit }): Add tracking, its reminder made on the first aura
-- bar, the aura on Edit tracked's list and the window opened on it, its settings under the list (Saneroki, 2026-11-07: "a
-- add Tracking that will add that spell to the edit auras window and open the edit auras window"; "put the add tracked
-- down to the bottom"); none where it is tracked: the line above it, Edit tracked..., opens the window on it
-- (Units/Lists.lua: Lists.Track, Lists.Entries).
function Reminders.Entry(root, spell)
    if ns.options.reminders == false or Reminders.Named(spell.name) then return end
    root:CreateButton(ns.TEXT.trackAdd, ns.Guard(function() ns.AuraLists.Track(spell) end))
end

local sentCast, sentTarget -- your last cast sent: its GUID, the name of whom it was aimed at

local function Sent(_, target, cast)
    sentCast, sentTarget = Plain(cast), Plain(target)
end

-- Your own cast of a spell a reminder watches, where the game tells it in a fight: the aura is there, as long as it
-- lasted when last read (else until the fight ends).
local function Cast(_, cast, spell)
    spell = Plain(spell)
    local name = spell and Core.Ask(C_Spell.GetSpellName, spell)
    if not name then return end
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.name == name and Reminders.OnBar(reminder) and Hidden(reminder) then
            seen[reminder] = { on = true, ends = Reminders.Ends(reminder, name) }
        end
    end
    cast = Plain(cast)
    local aimed = cast ~= nil and cast == sentCast and sentTarget or nil
    ns.GroupReminders.Cast(name, aimed)
    ns.PlateReminders.Cast(name, aimed)
end

-- Another unit behind the token: what was known of it no longer counts.
local function Unit()
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.unit ~= "player" then seen[reminder] = nil end
    end
end

-- The group changed: its classes read anew, and everything shown as they say (once a frame).
local again = Core.Later(ns.Guard(function() Reminders.Apply() end))
local function Roster()
    looked = nil
    again()
end

-- The looks run while there are reminders on bars or the nameplates and the setting is on; the bars and the plates'
-- icons go when it is off. The party and raid frames as the reminders on them say.
function Reminders.Apply()
    local on = not ns.off and ns.options.reminders ~= false
    local looking = on and Looked()
    if looking and not ticker then
        ticker = C_Timer.NewTicker(Reminders.EVERY, ns.Guard(Reminders.Update))
    elseif ticker and not looking then
        ticker:Cancel()
        ticker = nil
    end
    if on then
        Reminders.Update()
    else
        ns.ReminderBars.Hide()
        ns.PlateReminders.Hide()
    end
    ns.GroupReminders.Apply()
end

function Reminders.Start()
    local bars, known = Reminders.Bars(), { [Reminders.GROUP] = true, [Reminders.PLATES] = true } -- on no bar there is: the first
    for _, bar in ipairs(bars) do known[bar] = true end
    for _, reminder in ipairs(Reminders.List()) do
        if not known[reminder.bar] then reminder.bar = bars[1] end
    end
    Core.On("PLAYER_TARGET_CHANGED", Unit)
    Core.On("PLAYER_FOCUS_CHANGED", Unit)
    Core.On("GROUP_ROSTER_UPDATE", Roster)
    Core.OnUnit("UNIT_SPELLCAST_SENT", "player", Sent)
    Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", Cast)
    Core.EditMode.Watch(ns.Guard(Reminders.Apply))
    ns.GroupReminders.Start()
    ns.PlateReminders.Start()
    Reminders.Apply()
end

-- Standing down: the looks stop, the bars, the plates' icons and the window go.
function Reminders.GiveBack()
    Reminders.Apply()
    ns.ReminderEditor.Hide()
end
