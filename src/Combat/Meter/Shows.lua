local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Meter - Shows
--  Which bars a character has: what the window's ticks say, unless you chose otherwise
--  for that character (a right click on their name, Controls.lua). Kept by their GUID for
--  this account, only where it differs from the ticks, in store.meterPeople:
--      [guid] = { [kind] = true or false }
-------------------------------------------------------------------------------
local Shows = {}
ns.MeterShows = Shows

-- The bars, in their order, and each one's tick.
Shows.KINDS = { { kind = "threat", tick = "meterThreat" }, { kind = "damage", tick = "meterDamage" },
                { kind = "healing", tick = "meterHealing" }, { kind = "interrupts", tick = "meterInterrupts" } }

local function Chosen(person)
    local people = ns.store.meterPeople
    return people and people[person.guid]
end

local function Ticked(kind)
    for _, each in ipairs(Shows.KINDS) do
        if each.kind == kind then return ns.options[each.tick] and true or false end
    end
    return false
end

-- Whether that character has that bar.
function Shows.Is(person, kind)
    local chosen = Chosen(person)
    local own = chosen and chosen[kind]
    if own ~= nil then return own end
    return Ticked(kind)
end

-- That character's bars, in their order.
function Shows.Of(person)
    local list = {}
    for _, each in ipairs(Shows.KINDS) do
        if Shows.Is(person, each.kind) then list[#list + 1] = each.kind end
    end
    return list
end

-- That bar on or off for that character alone. What comes out as the ticks have it is no choice of its own.
function Shows.Flip(person, kind)
    local on = not Shows.Is(person, kind)
    local people = ns.store.meterPeople or {}
    ns.store.meterPeople = people
    local chosen = people[person.guid] or {}
    if on == Ticked(kind) then chosen[kind] = nil else chosen[kind] = on end
    people[person.guid] = next(chosen) ~= nil and chosen or nil
end

-- Whether that character has choices of their own.
function Shows.Own(person)
    return Chosen(person) ~= nil
end

-- That character as the window's ticks say again.
function Shows.Clear(person)
    if ns.store.meterPeople then ns.store.meterPeople[person.guid] = nil end
end

-- The kinds anybody may have now, to read them of the game: [kind] = true.
function Shows.Wanted()
    local wanted = {}
    for _, each in ipairs(Shows.KINDS) do
        if ns.options[each.tick] then wanted[each.kind] = true end
    end
    for _, chosen in pairs(ns.store.meterPeople or {}) do
        for kind, on in pairs(chosen) do
            if on then wanted[kind] = true end
        end
    end
    return wanted
end
