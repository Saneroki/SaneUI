local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Engine
--  Keeps the reservations and turns them into real buttons.
--
--  The one rule (Saneroki's decision): what you put on a button last wins. So a slot
--  holds a real action OR a reservation, never both; a real action that lands on
--  a reserved slot ends the reservation.
--
--  The game only lets buttons change out of combat and with an empty cursor.
--  Until then E.pending is set and the work is tried again.
-------------------------------------------------------------------------------
local E = {}
ns.Engine = E
local S = ns.Sources

E.pending = false

local pushed = {} -- [action slot] = { id = spell, at = when }: the game itself put a new spell there
local grace = {}  -- [slot] = until when a slot we just changed may still read as its old self
local PUSH_WINDOW = 60
local GRACE = 1

local function Copy(entry)
    return { kind = entry.kind, id = entry.id, name = entry.name, icon = entry.icon }
end
E.Copy = Copy

-- Are two entries the same thing? Spells by name (any rank), items by ID, macros by name.
function E.Same(a, b)
    if not a or not b or a.kind ~= b.kind then return false end
    if a.kind == "spell" then
        return (a.name ~= nil and a.name == b.name) or (a.id ~= nil and a.id == b.id)
    elseif a.kind == "item" then
        return a.id ~= nil and a.id == b.id
    elseif a.kind == "macro" then
        return a.name ~= nil and a.name == b.name
    end
    return false
end

-- Why real buttons cannot be changed right now, or nil when they can.
function E.Blocked()
    if InCombatLockdown() then return "combat" end
    if GetCursorInfo() then return "cursor" end
    return nil
end

local REASONS = {
    combat = "You are in combat: real buttons can be changed after the fight.",
    cursor = "Your cursor is holding something. Put it down first.",
}

-- The sentence for a "combat" or "cursor" answer of the functions below.
function E.Reason(why)
    return REASONS[why] or "That did not work."
end

local function TakeOff(slot)
    PickupAction(slot)
    ClearCursor()
end

-- Call after changing a slot yourself. For a moment the slot is not judged by what the
-- game still reports for it, and filling it is not worth a chat line.
local function Touched(slot)
    grace[slot] = GetTime() + GRACE
end
E.Touched = Touched

local function PutOnCursor(entry)
    local what = S.Available(entry)
    if not what then return false end
    ClearCursor()
    if entry.kind == "spell" then
        C_Spell.PickupSpell(what)
    elseif entry.kind == "item" then
        C_Item.PickupItem(what)
    elseif entry.kind == "macro" then
        PickupMacro(what)
    end
    return GetCursorInfo() ~= nil
end

-- First empty, unreserved button on a bar you can see (Bar 1's normal row included).
local function FreeSlot()
    for _, bar in ipairs(ns.BARS) do
        for i = 1, ns.NUM_BUTTONS do
            local slot = bar.offset + i
            local button = _G[bar.prefix .. i]
            local holder = button and button:GetParent()
            if (not holder or holder:IsVisible()) and not ns.HasAction(slot) and not ns.char.reserved[slot] then
                return slot
            end
        end
    end
    return nil
end

-- The game says which spell it put on which slot. Slot 0 (a controller in use) is no slot.
function E.NotePushed(spellID, slot)
    if spellID and type(slot) == "number" and slot > 0 then pushed[slot] = { id = spellID, at = GetTime() } end
end

-- The game drops a newly learned spell on the first free button by itself. That was not
-- your decision, so it must not end a reservation: the spell goes to its own reserved
-- button if it has one, and off a button that is reserved for something else. Only the
-- slot the game used is undone; the same spell on another button is yours.
local function UndoPushes(reserved, now)
    for slot, push in pairs(pushed) do
        pushed[slot] = nil
        local real = now - push.at < PUSH_WINDOW and ns.RealEntry(slot)
        if real and real.kind == "spell" and real.id == push.id then
            -- A spell still to come is reserved by the trainer's name of it ("Instant Poison", not "... II").
            local name, base = C_Spell.GetSpellName(push.id), ns.Data.Info(push.id)
            local ownSlot
            for other, entry in pairs(reserved) do
                if entry.kind == "spell" and (entry.name == name or (base and entry.name == base)) then ownSlot = other break end
            end
            if ownSlot and ownSlot ~= slot then
                TakeOff(slot) -- it is placed on its own button below
            elseif not ownSlot and reserved[slot] then
                PickupAction(slot)
                local free = FreeSlot()
                if free then PlaceAction(free) end
                ClearCursor()
            end
        end
    end
end

-- Compare the reservations with the real bars and act on the differences.
function E.Reconcile()
    if not ns.char then return end
    if E.Blocked() then
        E.pending = true
        return
    end
    E.pending = false

    local reserved = ns.char.reserved
    local now = GetTime()
    local again = false
    UndoPushes(reserved, now)

    for slot, entry in pairs(reserved) do
        -- "unknown": the game hides the slot right now. It is neither ended nor filled on a
        -- guess; the next update looks again.
        local has = ns.HasAction(slot)
        if has == true then
            if grace[slot] and now < grace[slot] then
                again = true
            else
                reserved[slot] = nil -- something real was put here: that decision wins
            end
        elseif has == false and S.Available(entry) then
            if PutOnCursor(entry) then PlaceAction(slot) end
            ClearCursor()
            if ns.HasAction(slot) == true then
                reserved[slot] = nil
                -- Only worth a chat line when it happened by itself, not right after your own drop.
                local yours = grace[slot] and now < grace[slot]
                if ns.options.announce and not yours then
                    ns.Print(("%s is now on %s."):format(S.Name(entry), ns.SlotLabel(slot)))
                end
            end
        end
    end

    if again then ns.QueueUpdate(false, GRACE) end
end

-------------------------------------------------------------------------------
--  What you can do to a slot. Each returns true, or false plus "combat" / "cursor".
-------------------------------------------------------------------------------

-- Reserve a slot for an entry. A real action there is taken off the bar first;
-- with toCursor it stays on your cursor, as when you drop one real button on another.
-- Something you already have becomes a real button at once (or right after the fight).
function E.Reserve(slot, entry, toCursor)
    if ns.HasAction(slot) then
        local why = E.Blocked()
        if why then return false, why end
        if toCursor then
            PickupAction(slot)
        else
            TakeOff(slot)
        end
    end
    ns.char.reserved[slot] = Copy(entry)
    Touched(slot)
    ns.QueueUpdate(false, 0)
    return true
end

-- Carry a reservation to another slot, as when you drag a real button onto another one: a
-- reservation there comes back to the first slot, a real action there goes onto your cursor.
function E.Move(from, to)
    local entry = ns.char.reserved[from]
    if not entry or from == to then return false end
    local other = ns.char.reserved[to]
    local ok, why = E.Reserve(to, entry, true)
    if not ok then return false, why end
    ns.char.reserved[from] = other and Copy(other) or nil
    Touched(from)
    ns.QueueUpdate(false, 0)
    return true
end

-- Empty a slot: end its reservation or take the real action off the bar.
function E.Clear(slot)
    if ns.HasAction(slot) then
        local why = E.Blocked()
        if why then return false, why end
        TakeOff(slot)
    end
    ns.char.reserved[slot] = nil
    Touched(slot)
    ns.QueueUpdate(false, 0)
    return true
end
