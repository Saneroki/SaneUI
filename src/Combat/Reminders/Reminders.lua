local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders
--  A reminder watches one buff or debuff, by its name (so any rank of it), on
--  you or the unit it was made on, and puts its icon on a reminder bar (Bars.lua)
--  while its settings want it; or, placed on the party and raid frames, on each
--  member's frame (Group.lua). Kept per character, a buff being a character's,
--  with the bars, one at first; a bar made is yours until you delete it:
--      bar       which reminder bar: its number, which never changes; GROUP:
--                the party and raid frames
--      missing   shown while the aura is not there
--      active    shown while it is
--      early     with missing: seconds before it runs out to show it already
--      combat    "any", "out" (only out of a fight), "in" (only in one)
--      noRest    not shown in resting areas (cities, inns)
--      own       only your own cast of it counts
--  A name of a family (Reminders.FAMILIES) counts all its names: a Gift of the
--  Wild for a Mark of the Wild. Made from the menu of a click on an aura or a
--  spell of the spellbook (Units/Lists.lua), set in the window (Editor.lua,
--  /sane reminders).
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

Reminders.EVERY = 0.25  -- seconds between looks, while there are reminders on bars
Reminders.MOST_EARLY = 9999 -- the longest offset, in seconds
Reminders.GROUP = 0     -- the place of the reminders on the party and raid frames: no bar has that number
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

for _, family in ipairs(Reminders.FAMILIES) do
    for _, name in ipairs(family) do families[name] = family end
end

-- The family of that name, or nil.
function Reminders.Family(name)
    return families[name]
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

-- The first reminder of an aura of that name, if it has one (Edit auras holds an aura by its name).
function Reminders.Named(name)
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.name == name then return reminder end
    end
    return nil
end

-- The reminder of that aura, made if it has none, on bar (a bar's number or GROUP; nil: the first bar): a buff shown
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
        local auras = C_UnitAuras
        if state.instance and auras.GetAuraDuration and Core.Ask(auras.GetAuraDuration, unit, state.instance) == nil then
            state.on, state.instance, state.ends = false, nil, nil
        end
        if state.ends and state.ends <= GetTime() then state.ends = nil end -- past its end and still on: renewed
    else
        state = state or {}
        local data = Reminders.Aura(reminder, unit)
        local ends = type(data) == "table" and Plain(data.expirationTime) or nil
        state.on = type(data) == "table"
        state.instance = state.on and Plain(data.auraInstanceID) or nil
        state.ends = ends and ends > 0 and ends or nil
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
    if Core.Ask(UnitIsDeadOrGhost, "player") then return false end
    if unit ~= "player" then
        if not Core.Ask(UnitExists, unit) or Core.Ask(UnitIsDeadOrGhost, unit) then return false end
        local foe = reminder.harmful and reminder.bar ~= Reminders.GROUP -- a member's debuff is on a friend
        if foe and Core.Ask(UnitCanAttack, "player", unit) == false then return false end
    end
    if not state.on then return reminder.missing end
    return reminder.active or (reminder.missing and state.left ~= nil and state.left <= reminder.early)
end

-- Whether any reminder is on a bar.
local function OnBars()
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.bar ~= Reminders.GROUP then return true end
    end
    return false
end

-- Every reminder of a bar looked at, every bar filled. In Edit Mode a bar shows all it holds, to be placed.
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
end

-- A menu's line for an aura ({ id, name, icon, harmful, unit }): Show on raid frames, ticked while it has a reminder
-- (there or on a bar); a click makes one on the party and raid frames, or deletes it. Its settings are Edit auras',
-- the menu's last line (Units/Lists.lua).
function Reminders.Entry(root, spell)
    if ns.options.reminders == false then return end
    root:CreateCheckbox(ns.TEXT.reminderCreate, ns.Guard(function() return Reminders.Named(spell.name) ~= nil end),
        ns.Guard(function()
            local reminder = Reminders.Named(spell.name)
            if reminder then return Reminders.Take(reminder) end
            Reminders.Make(spell, Reminders.GROUP)
        end))
end

-- Your own cast of a spell a reminder watches, where the game tells it in a fight: the aura is there, for how long
-- unknown.
local function Cast(_, _, spell)
    spell = Plain(spell)
    local name = spell and Core.Ask(C_Spell.GetSpellName, spell)
    if not name then return end
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.name == name and reminder.bar ~= Reminders.GROUP and Hidden(reminder) then
            seen[reminder] = { on = true }
        end
    end
    ns.GroupReminders.Cast(name)
end

-- Another unit behind the token: what was known of it no longer counts.
local function Unit()
    for _, reminder in ipairs(Reminders.List()) do
        if reminder.unit ~= "player" then seen[reminder] = nil end
    end
end

-- The looks run while there are reminders on bars and the setting is on; the bars go when it is off. The party and
-- raid frames as the reminders on them say.
function Reminders.Apply()
    local on = not ns.off and ns.options.reminders ~= false
    local looking = on and OnBars()
    if looking and not ticker then
        ticker = C_Timer.NewTicker(Reminders.EVERY, ns.Guard(Reminders.Update))
    elseif ticker and not looking then
        ticker:Cancel()
        ticker = nil
    end
    if on then Reminders.Update() else ns.ReminderBars.Hide() end
    ns.GroupReminders.Apply()
end

function Reminders.Start()
    local bars, known = Reminders.Bars(), { [Reminders.GROUP] = true } -- a reminder on no bar there is: on the first
    for _, bar in ipairs(bars) do known[bar] = true end
    for _, reminder in ipairs(Reminders.List()) do
        if not known[reminder.bar] then reminder.bar = bars[1] end
    end
    Core.On("PLAYER_TARGET_CHANGED", Unit)
    Core.On("PLAYER_FOCUS_CHANGED", Unit)
    Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", Cast)
    Core.EditMode.Watch(ns.Guard(Reminders.Apply))
    ns.GroupReminders.Start()
    Reminders.Apply()
end

-- Standing down: the looks stop, the bars and the window go.
function Reminders.GiveBack()
    Reminders.Apply()
    ns.ReminderEditor.Hide()
end
