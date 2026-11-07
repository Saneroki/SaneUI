local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Group
--  The reminders shown on the health bars (Reminders.GROUP, Show on healthbars:
--  Saneroki, 2026-11-06): each watched on every member the party and raid
--  frames show, your own slot too, and on your own frame, your target's and
--  your focus's (Units.lua), its icon on that frame (from the health
--  leftwards) while its settings want it, as on a bar: missing or active, the
--  offset, in or out of a fight, resting, only yours. A buff only on a unit you
--  can help, a debuff on any; none on the dead and the offline; a party's
--  family (a shout) on your own party only; Members.MOST on a frame at most, in
--  the order made. Off with the reminders, or with the switch groupBuffs.
--
--  In a fight the game hides most auras from addons (ShouldSpellAuraBeSecret;
--  a spell it never hides is read as ever), Forever's client even their numbers
--  and lists. Then, for each member by their GUID, what the last look saw
--  counts, until it runs out by the clock (Reminders.Known); one that comes in
--  the fight is known from your own cast of a name watched: on the member it
--  was aimed at (UNIT_SPELLCAST_SENT's name), for as long as it lasted when
--  last read (Reminders.Ends). A cast that reaches many (a group's version, a
--  shout), or one aimed at no name of the frames, gives it to each member whose
--  auras changed within Members.WINDOW of it, either first (UNIT_AURA: the
--  game still tells that much). While a fight lasts the frames are looked at
--  each Members.EVERY second, as nothing tells when a HoT ran out by the
--  clock; at its end every frame is read again (Group.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Reminders = ns.Reminders
local Members = {}
ns.GroupReminders = Members

Members.MOST = 4     -- icons on a frame at most
Members.WINDOW = 0.5 -- seconds between your cast and a member's auras changing, either first
Members.EVERY = 1    -- seconds between looks in a fight, and while a reminder on the frames shows early (its offset)
-- For a preview while none is on the frames.
Members.SAMPLES = { "Interface\\Icons\\Spell_Nature_Regeneration", "Interface\\Icons\\Spell_Nature_Rejuvenation",
                    "Interface\\Icons\\Spell_Nature_ResistNature" }

local seen = setmetatable({}, { __mode = "k" }) -- [a reminder] = { [a member's GUID] = { on, instance, ends, left } }
local changed = {} -- [a member's GUID] = when their auras last changed, in a fight
local cast         -- your last cast of a name watched, in a fight: { name, at, open (any member whose auras changed) }
local fighting     -- from PLAYER_REGEN_DISABLED to _ENABLED (the game's lockdown starts only after the first)
local ticker

local function On()
    return not ns.off and ns.options.reminders ~= false and ns.options.groupBuffs ~= false
end

local function Placed(reminder)
    return reminder.bar == Reminders.GROUP
end

-- Whether any reminder is on the frames, and they are on.
function Members.Any()
    if not On() then return false end
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) then return true end
    end
    return false
end

-- Who the member is, apart from the token, which another may take in a fight.
local function Key(unit)
    return Core.Ask(UnitGUID, unit) or unit
end

-- What is known of the reminder's aura on the member now: { on, left }; nil where nothing is.
local function Look(reminder, unit, key)
    local states = seen[reminder]
    if not states then
        states = {}
        seen[reminder] = states
    end
    states[key] = Reminders.Known(reminder, unit, states[key])
    return states[key]
end

-- Whether the reminder reaches the member: a party's family (a shout) your own party only.
local function Reaches(reminder, unit)
    local family = Reminders.Family(reminder.name)
    return not (family and family.party) or Core.Ask(UnitInParty, unit) or Core.Ask(UnitIsUnit, unit, "player")
end

-- The icons of the reminders on the health bars that the unit's auras and their settings want shown, into list
-- (emptied first); how many, Members.MOST at most.
function Members.Missing(unit, list)
    wipe(list)
    if not On() or Core.Ask(UnitIsDeadOrGhost, unit) or Core.Ask(UnitIsConnected, unit) == false then return 0 end
    local key = Key(unit)
    local helped = Core.Ask(UnitCanAssist, "player", unit) ~= false
    for _, reminder in ipairs(Reminders.List()) do
        if #list >= Members.MOST then break end
        if Placed(reminder) and (reminder.harmful or helped) and Reaches(reminder, unit)
            and Reminders.Wanted(reminder, Look(reminder, unit, key), unit) then
            list[#list + 1] = reminder.icon
        end
    end
    return #list
end

-- Those icons on a face of the health bars (a member's, or a unit frame's: GroupFace.Icons).
function Members.Show(face, unit)
    ns.GroupFace.Icons(face, face.missing, unit and Members.Missing(unit, face.missing) or 0)
end

-- The icons for a preview: the reminders on the frames, the samples where none is.
function Members.Icons()
    local icons = {}
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) then icons[#icons + 1] = reminder.icon end
    end
    return icons[1] and icons or Members.SAMPLES
end

-- Whether the reminder watches a spell of that name: its own, or one of its family.
local function Named(reminder, name)
    local family = Reminders.Family(reminder.name)
    return reminder.name == name or (family ~= nil and Reminders.Family(name) == family)
end

-- A buff the game hides now that a reminder on the frames watches by that name.
local function Watched(name)
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) and not reminder.harmful and Named(reminder, name) and Reminders.Hidden(reminder) then
            return true
        end
    end
    return false
end

-- Your cast of that name gave the member that aura: every reminder on the frames watching it knows it is on, for as long
-- as it lasted when last read.
local function Gave(name, key)
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) and not reminder.harmful and Named(reminder, name) and Reminders.Hidden(reminder) then
            seen[reminder] = seen[reminder] or {}
            seen[reminder][key] = { on = true, ends = Reminders.Ends(reminder, name) }
        end
    end
end

-- The member of the frames a cast was aimed at, by the name the game gave (a first name, or a whole one; a realm
-- after it dropped): their key; nil where none has it.
local function Aimed(target)
    if type(target) ~= "string" then return nil end
    target = target:match("^[^-]+")
    if not target then return nil end
    local found
    local function Match(face)
        local unit = face.unit
        if found or not unit or face.small then return end
        if Core.Ask(UnitName, unit) == target or Core.FullName(unit) == target then found = Key(unit) end
    end
    ns.Group.Each(Match)
    ns.Units.Each(Match)
    return found
end

-- Every face of the health bars anew, as the reminders say: the group frames', the unit frames'.
function Members.Refresh()
    ns.Group.Each(ns.GroupFace.Buffs)
    ns.Units.Each(ns.Units.Buffs)
end

-- A member's auras changed (UNIT_AURA: GroupFace.lua, Units.lua): in a fight, when, for a cast open to any of them
-- (just after it, or just before: Members.Cast).
function Members.Heard(unit)
    if not Core.Restricted() then return end
    local key, at = Key(unit), GetTime()
    changed[key] = at
    if cast and cast.open and at - cast.at <= Members.WINDOW then Gave(cast.name, key) end
end

-- Your own cast of a spell, by its name and whom it was aimed at (a name, or nil), where the game tells it in a fight
-- (Reminders.lua): that member has it; one that reaches many, or aimed at no member, each whose auras changed with it.
function Members.Cast(name, target)
    if not On() or not Watched(name) then return end
    local at, aimed = GetTime(), Aimed(target)
    cast = { name = name, at = at, open = aimed == nil or Reminders.Many(name) }
    if aimed then Gave(name, aimed) end
    if cast.open then
        for key, when in pairs(changed) do
            if at - when <= Members.WINDOW then Gave(name, key) end
        end
    end
    Members.Refresh()
end

local Apply

-- A fight began or ended: what changed in it is forgotten; the frames anew (a reminder only out of a fight goes), a
-- look each second while it lasts.
local function Fight(on)
    fighting = on
    wipe(changed)
    cast = nil
    Apply()
end

-- Out of a group: nobody's auras are kept.
local function Roster()
    if Core.Ask(IsInGroup) then return end
    wipe(changed)
    for reminder in pairs(seen) do seen[reminder] = nil end
end

local function Early()
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) and reminder.missing and (reminder.early or 0) > 0 then return true end
    end
    return false
end

-- The frames as the reminders say; a look each second in a fight, and while one of them shows early, as no aura's
-- event tells when that is.
function Members.Apply()
    local timed = Members.Any() and (fighting or Early())
    if timed and not ticker then
        ticker = C_Timer.NewTicker(Members.EVERY, ns.Guard(Members.Refresh))
    elseif ticker and not timed then
        ticker:Cancel()
        ticker = nil
    end
    Members.Refresh()
end
Apply = Members.Apply

function Members.Start()
    ns.On("PLAYER_REGEN_DISABLED", function() Fight(true) end)
    ns.On("PLAYER_REGEN_ENABLED", function() Fight(false) end)
    ns.On("PLAYER_UPDATE_RESTING", Members.Refresh)
    ns.On("GROUP_ROSTER_UPDATE", Roster)
end
