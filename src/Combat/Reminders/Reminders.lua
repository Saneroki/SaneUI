local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders
--  A reminder watches one buff or debuff, by its name (so any rank of it), on
--  you or the unit it was made on, and puts its icon on a reminder bar (Bars.lua)
--  while its settings want it. Kept per character, a buff being a character's:
--      bar       which reminder bar, 1 to Reminders.BARS
--      missing   shown while the aura is not there
--      active    shown while it is
--      early     with missing: seconds before it runs out to show it already
--      combat    "any", "out" (only out of a fight), "in" (only in one)
--      noRest    not shown in resting areas (cities, inns)
--  Made by a right click on an aura (Clicks.lua, Units/Auras.lua), set in the
--  window (Editor.lua, /sane reminders).
--
--  In a fight the game hides most auras from addons (ShouldSpellAuraBeSecret;
--  never-secret spells are read as ever). Then what the last look saw counts:
--  the aura's instance, which the game can still say is there or not
--  (GetAuraDuration fails on one gone), and when it ends. So an aura that goes
--  or runs out shows at once; one that comes in a fight is known only from your
--  own cast of that name, where the game tells it, else at the fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Reminders = {}
ns.Reminders = Reminders

Reminders.BARS = 5      -- how many reminder bars there are
Reminders.EVERY = 0.25  -- seconds between looks, while there are reminders
Reminders.MOST_EARLY = 9999 -- the longest offset, in seconds

local seen = setmetatable({}, { __mode = "k" }) -- [a reminder] = what was last known: { on, instance, ends, left }
local ticker

-- This character's reminders, in the order made.
function Reminders.List()
    local char = Core.Character(ns.name)
    char.reminders = char.reminders or {}
    return char.reminders
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

-- The reminder of that aura, made if it has none: a buff shown when it is missing, a debuff on you when it is there,
-- a debuff on another (yours on a foe) when it is missing.
function Reminders.Make(spell)
    local reminder = Reminders.Find(spell)
    if reminder then return reminder end
    local stays = spell.harmful and spell.unit == "player"
    reminder = { id = spell.id, name = spell.name, icon = spell.icon, harmful = spell.harmful, unit = spell.unit,
                 bar = 1, missing = not stays, active = stays or false, early = 0, combat = "any", noRest = false }
    table.insert(Reminders.List(), reminder)
    Reminders.Apply()
    return reminder
end

function Reminders.Take(reminder)
    local list = Reminders.List()
    for index = #list, 1, -1 do
        if list[index] == reminder then table.remove(list, index) end
    end
    Reminders.Apply()
end

-- Whether the game hides this aura from addons now.
local function Hidden(reminder)
    local secrets = rawget(_G, "C_Secrets")
    if not (secrets and secrets.ShouldAurasBeSecret) then return Core.Restricted() end
    if Core.Ask(secrets.ShouldAurasBeSecret) == false then return false end
    return Core.Ask(secrets.ShouldSpellAuraBeSecret, reminder.id) ~= false
end

-- What is known of the aura now: { on, left (seconds, nil: none or unknown) }; nil where nothing is.
local function Look(reminder)
    local state = seen[reminder]
    if Hidden(reminder) then
        if not state then return nil end
        local auras = C_UnitAuras
        if state.instance and auras.GetAuraDuration
            and Core.Ask(auras.GetAuraDuration, reminder.unit, state.instance) == nil then
            state.on, state.instance, state.ends = false, nil, nil
        end
        if state.ends and state.ends <= GetTime() then state.ends = nil end -- past its end and still on: renewed
    else
        state = state or {}
        seen[reminder] = state
        local filter = reminder.harmful and "HARMFUL" or "HELPFUL"
        local data = Core.Ask(C_UnitAuras.GetAuraDataBySpellName, reminder.unit, reminder.name, filter)
        local ends = type(data) == "table" and Plain(data.expirationTime) or nil
        state.on = type(data) == "table"
        state.instance = state.on and Plain(data.auraInstanceID) or nil
        state.ends = ends and ends > 0 and ends or nil
    end
    state.left = state.ends and math.max(0, state.ends - GetTime()) or nil
    return state
end

-- Whether the reminder's settings want it shown, with the aura as known.
function Reminders.Wanted(reminder, state)
    if not state then return false end
    local fighting = InCombatLockdown()
    if (reminder.combat == "out" and fighting) or (reminder.combat == "in" and not fighting) then return false end
    if reminder.noRest and IsResting() then return false end
    if Core.Ask(UnitIsDeadOrGhost, "player") then return false end
    if reminder.unit ~= "player" then
        if not Core.Ask(UnitExists, reminder.unit) or Core.Ask(UnitIsDeadOrGhost, reminder.unit) then return false end
        if reminder.harmful and Core.Ask(UnitCanAttack, "player", reminder.unit) == false then return false end
    end
    if not state.on then return reminder.missing end
    return reminder.active or (reminder.missing and state.left ~= nil and state.left <= reminder.early)
end

-- Every reminder looked at, every bar filled. In Edit Mode a bar shows all it holds, to be placed.
function Reminders.Update()
    if ns.off then return end
    local bars = {}
    for index = 1, Reminders.BARS do bars[index] = {} end
    for _, reminder in ipairs(Reminders.List()) do
        local state = Look(reminder)
        local list = bars[reminder.bar]
        if list and (Core.EditMode.active or Reminders.Wanted(reminder, state)) then
            list[#list + 1] = { icon = reminder.icon, left = state and state.on and state.left or nil }
        end
    end
    for index, list in ipairs(bars) do ns.ReminderBars.Fill(index, list) end
end

-- Your own cast of a spell a reminder watches, where the game tells it in a fight: the aura is there, for how long
-- unknown.
local function Cast(_, _, spell)
    spell = Plain(spell)
    local name = spell and Core.Ask(C_Spell.GetSpellName, spell)
    if not name then return end
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.name == name and Hidden(reminder) then
            seen[reminder] = { on = true }
        end
    end
end

-- Another unit behind the token: what was known of it no longer counts.
local function Unit()
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.unit ~= "player" then seen[reminder] = nil end
    end
end

-- The looks run while there are reminders and the setting is on; the bars go when not.
function Reminders.Apply()
    local on = not ns.off and ns.options.reminders ~= false and Reminders.List()[1] ~= nil
    if on and not ticker then
        ticker = C_Timer.NewTicker(Reminders.EVERY, ns.Guard(Reminders.Update))
    elseif ticker and not on then
        ticker:Cancel()
        ticker = nil
    end
    if on then Reminders.Update() else ns.ReminderBars.Hide() end
    ns.ReminderClicks.Sync()
end

function Reminders.Start()
    ns.ReminderClicks.Start()
    Core.On("PLAYER_TARGET_CHANGED", Unit)
    Core.On("PLAYER_FOCUS_CHANGED", Unit)
    Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", Cast)
    Core.EditMode.Watch(ns.Guard(Reminders.Apply))
    Reminders.Apply()
end

-- Standing down: the looks stop, the bars and the window go, the buffs' right clicks are the game's again.
function Reminders.GiveBack()
    Reminders.Apply()
    ns.ReminderEditor.Hide()
end
