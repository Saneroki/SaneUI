local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Group
--  The reminders placed on the party and raid frames (Reminders.GROUP, chosen
--  in the window where a bar is): each watched on every member those frames
--  show, your own slot too, its icon on that member's frame (GroupFace.lua,
--  from the health leftwards) while its settings want it, as on a bar: missing
--  or active, the offset, in or out of a fight, resting, only yours. None on
--  the dead and the offline; a party's family (a shout) on your own party
--  only; Members.MOST on a frame at most, in the order made. Off with the
--  reminders, or with the frames' switch (groupBuffs).
--
--  In a fight the game hides most auras from addons (ShouldSpellAuraBeSecret;
--  a spell it never hides is read as ever). Then, for each member by their
--  GUID, what the last look saw counts: the aura's instance, which the game can
--  still say is there or not (GetAuraDuration fails on one gone), and when it
--  ends; so a HoT that runs out or is taken off shows at once. One that comes
--  in the fight is known from your own cast of a name watched and a new aura of
--  yours on a member (GetUnitAuraInstanceIDs with PLAYER: the game hides which
--  aura it is, not its number) within Members.WINDOW of it, either first: each
--  member who got one has it (a group's version reaches many). Anything else
--  waits for the fight's end, when every frame is read again (Group.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Reminders = ns.Reminders
local Members = {}
ns.GroupReminders = Members

Members.MOST = 4     -- icons on a frame at most
Members.WINDOW = 0.5 -- seconds between your cast and the new aura of yours it gave, either first
Members.EVERY = 1    -- seconds between looks while a reminder on the frames shows early (its offset)
-- For a preview while none is on the frames.
Members.SAMPLES = { "Interface\\Icons\\Spell_Nature_Regeneration", "Interface\\Icons\\Spell_Nature_Rejuvenation",
                    "Interface\\Icons\\Spell_Nature_ResistNature" }

local seen = setmetatable({}, { __mode = "k" }) -- [a reminder] = { [a member's GUID] = { on, instance, ends, left } }
local mine = {}  -- [a member's GUID] = { [the instance of an aura of yours on them] = true }, in a fight
local fresh = {} -- new auras of yours in a fight no cast was matched to yet: { key, id, at }
local cast       -- your last cast of a name watched, in a fight: { name, at }
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

-- The icons of the reminders on the frames that the member's auras and their settings want shown, into list (emptied
-- first); how many, Members.MOST at most.
function Members.Missing(unit, list)
    wipe(list)
    if not On() or Core.Ask(UnitIsDeadOrGhost, unit) or Core.Ask(UnitIsConnected, unit) == false then return 0 end
    local key = Key(unit)
    for _, reminder in ipairs(Reminders.List()) do
        if #list >= Members.MOST then break end
        if Placed(reminder) and Reaches(reminder, unit)
            and Reminders.Wanted(reminder, Look(reminder, unit, key), unit) then
            list[#list + 1] = reminder.icon
        end
    end
    return #list
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

-- Your cast of that name gave the member that aura of yours: every reminder on the frames watching it knows it is on.
local function Gave(name, key, id)
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) and not reminder.harmful and Named(reminder, name) and Reminders.Hidden(reminder) then
            seen[reminder] = seen[reminder] or {}
            seen[reminder][key] = { on = true, instance = id }
        end
    end
end

-- The instances of your own buffs on the member, into found (emptied first).
local function Yours(unit, found)
    wipe(found)
    local ids = Core.Ask(C_UnitAuras.GetUnitAuraInstanceIDs, unit, "HELPFUL|PLAYER")
    if type(ids) ~= "table" then return found end
    for _, id in ipairs(ids) do
        id = Plain(id)
        if id then found[id] = true end
    end
    return found
end

-- Every face of the group frames anew, as the reminders say.
function Members.Refresh()
    ns.Group.Each(ns.GroupFace.Buffs)
end

-- A member's auras changed (UNIT_AURA, GroupFace.lua): in a fight a new one of yours is matched to your cast, or kept
-- a moment for the cast that comes after it.
function Members.Heard(unit)
    if not Core.Restricted() then return end
    local key = Key(unit)
    local known = mine[key]
    local now = Yours(unit, {})
    mine[key] = now
    if not known then return end
    local at = GetTime()
    for index = #fresh, 1, -1 do
        if at - fresh[index].at > Members.WINDOW then table.remove(fresh, index) end
    end
    for id in pairs(now) do
        if not known[id] then
            if cast and at - cast.at <= Members.WINDOW then
                Gave(cast.name, key, id)
            else
                fresh[#fresh + 1] = { key = key, id = id, at = at }
            end
        end
    end
end

-- Your own cast of a spell, by its name, where the game tells it in a fight (Reminders.lua): the new auras of yours
-- just before it are its, and those just after.
function Members.Cast(name)
    if not On() or not Watched(name) then return end
    local at = GetTime()
    for _, new in ipairs(fresh) do
        if at - new.at <= Members.WINDOW then Gave(name, new.key, new.id) end
    end
    wipe(fresh)
    cast = { name = name, at = at }
    Members.Refresh()
end

-- A fight began: your auras on each member as they are now, so that what is new in it can be told; the frames anew
-- (a reminder only out of a fight goes).
local function Fight()
    wipe(fresh)
    cast = nil
    if not Members.Any() then return end
    ns.Group.Each(function(face)
        if face.unit then mine[Key(face.unit)] = Yours(face.unit, {}) end
    end)
    Members.Refresh()
end

-- Out of a group: nobody's auras are kept.
local function Roster()
    if Core.Ask(IsInGroup) then return end
    wipe(mine)
    for reminder in pairs(seen) do seen[reminder] = nil end
end

local function Early()
    for _, reminder in ipairs(Reminders.List()) do
        if Placed(reminder) and reminder.missing and (reminder.early or 0) > 0 then return true end
    end
    return false
end

-- The frames as the reminders say; a look each second while one of them shows early, as no aura's event tells when
-- that is.
function Members.Apply()
    local timed = Members.Any() and Early()
    if timed and not ticker then
        ticker = C_Timer.NewTicker(Members.EVERY, ns.Guard(Members.Refresh))
    elseif ticker and not timed then
        ticker:Cancel()
        ticker = nil
    end
    Members.Refresh()
end

function Members.Start()
    ns.On("PLAYER_REGEN_DISABLED", Fight)
    ns.On("PLAYER_UPDATE_RESTING", Members.Refresh)
    ns.On("GROUP_ROSTER_UPDATE", Roster)
end
