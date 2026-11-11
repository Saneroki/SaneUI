local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Aura log
--  The buffs and debuffs seen on whoever you can attack (creatures, bosses, a
--  foe of the other faction), kept as a history, for a view to show (Combat's
--  full screen, its window Aura history). What the game tells addons is the
--  limit, and the log keeps no more than that:
--      out of a fight  every aura of the units looked at, as it comes: what, on
--                      whom, from whom, when, how long it lasts, whether it can
--                      be dispelled or stolen, and whether the cast that gave it
--                      could be interrupted (where that cast was seen)
--      in a fight      the game hides every aura from addons (secret values),
--                      save the spells it lets them see: only those are kept, as
--                      they come. Once the fight is over every unit is looked at
--                      again: what is still on is kept with the time it came (its
--                      end less its duration), and what went is closed
--  Every value goes through Core.Plain: a hidden one is skipped, never kept or
--  compared.
--
--  The units looked at: your target, your focus, the mouse's, your soft target,
--  the boss frames' and every nameplate's, each by its own UNIT_AURA
--  (Core.OnUnit, never every unit about: a raid sends hundreds a second), a
--  frame later; in a fight at most each AuraLog.FIGHT seconds. Kept per character
--  (Core.Character), the newest AuraLog.MOST, oldest first.
--
--      Core.AuraLog.Entries()    the list, oldest first; each entry:
--          id, name, icon        the spell
--          harmful               a debuff (true) or a buff
--          on, boss              whom it was on (a name), and whether that is a boss
--          from                  who put it there (a name; nil: not told)
--          stamp, ends, gone     when it came, was due to end, went (time(); nil: unknown, none)
--          lasts, stacks         its duration in seconds (0: none), its most applications
--          dispel, steal         its dispel type (Magic, Curse, Poison, Disease; nil: none), whether it can be stolen
--          cast                  its cast could be interrupted (true), could not (false), or was not seen (nil)
--          instant               that cast was instant
--      Core.AuraLog.Live(entry)  the unit it is on now, the aura still there, and its instance; or nil
--      Core.AuraLog.Listen(fn)   fn() once after the list changed (a frame later, a burst one call)
--      Core.AuraLog.Clear()      the list emptied
-------------------------------------------------------------------------------
local Plain, Ask = Core.Plain, Core.Ask

-- The game's own, asked by name: a stand-in or a client update may lack one (Core.Ask then answers nil).
local function Game(name) return rawget(_G, name) end
local AuraLog = {}
Core.AuraLog = AuraLog

AuraLog.MOST = 400   -- entries kept, the oldest dropped first
AuraLog.FIGHT = 1    -- seconds between two looks at a unit in a fight
AuraLog.CAST = 10    -- seconds after a cast began within which an aura of its spell came from it
AuraLog.UNITS = { "target", "focus", "mouseover", "softenemy" } -- and boss1-5, nameplate1-40 as they come

local list            -- the entries, Core.Character's (made at the first look after the login)
local live = {}       -- [GUID] = { [aura instance] = entry }: what is on, as last looked at
local where = {}      -- [GUID] = the unit last seen with it
local casts = {}      -- [GUID] = { id, name, interruptible, instant, at }: the last cast it began
local pending = {}    -- [unit] = true: to look at
local listeners = {}

local function List()
    if not list and Core.charKey then
        local char = Core.Character(Core.name)
        char.auraLog = char.auraLog or {}
        list = char.auraLog
    end
    return list
end

-- Whether the game tells addons the auras now (in a fight it hides them).
local function Open()
    if Core.Restricted() then return false end
    local secrets = rawget(_G, "C_Secrets")
    return not (secrets and secrets.ShouldAurasBeSecret and Ask(secrets.ShouldAurasBeSecret) == true)
end
AuraLog.Open = Open

local Tell = Core.Later(function()
    for _, fn in ipairs(listeners) do Core.Safe("aura log", fn) end
end, 0, "aura log")

function AuraLog.Listen(fn)
    listeners[#listeners + 1] = fn
end

function AuraLog.Entries()
    return List() or {}
end

function AuraLog.Clear()
    local entries = List()
    if entries then
        for index = #entries, 1, -1 do entries[index] = nil end
    end
    for guid in pairs(live) do live[guid] = nil end
    Tell()
end

function AuraLog.Live(entry)
    local unit = entry and entry.guid and where[entry.guid]
    if not unit or Plain(Ask(Game("UnitGUID"), unit)) ~= entry.guid then return nil end
    for instance, held in pairs(live[entry.guid] or {}) do
        if held == entry then return unit, instance end
    end
end

-- Whom a unit stands for: someone you can attack, not you, not a friend.
local function Foe(unit)
    return Ask(Game("UnitExists"), unit) == true and Ask(Game("UnitCanAttack"), "player", unit) == true
end

local function Boss(unit)
    if unit:match("^boss%d") then return true end
    return Ask(Game("UnitClassification"), unit) == "worldboss"
end

-------------------------------------------------------------------------------
--  Casts: whether the one that gave an aura could be interrupted
-------------------------------------------------------------------------------
-- A cast's name, whether it cannot be interrupted, and its spell, from the game's answers (locked: where that one
-- stands, then the spell: UnitCastingInfo 8, UnitChannelInfo 7).
local function Picked(locked, ok, ...)
    if not ok then return nil end
    local name = ...
    local stuck, id = select(locked, ...)
    return Plain(name), Plain(stuck), Plain(id)
end

local function Began(unit)
    local guid = Ask(Game("UnitGUID"), unit)
    if type(guid) ~= "string" then return end
    local casting, channel = Game("UnitCastingInfo"), Game("UnitChannelInfo")
    local name, locked, id
    if type(casting) == "function" then name, locked, id = Picked(8, pcall(casting, unit)) end
    if not name and type(channel) == "function" then name, locked, id = Picked(7, pcall(channel, unit)) end
    if type(name) ~= "string" or type(locked) ~= "boolean" then return end -- hidden in a fight: nothing known
    casts[guid] = { id = type(id) == "number" and id or nil, name = name, interruptible = not locked, at = GetTime() }
end

-- The game tells a cast's change: it can (or cannot) be interrupted now.
local function Turned(unit, interruptible)
    local guid = Ask(Game("UnitGUID"), unit)
    local cast = type(guid) == "string" and casts[guid]
    if cast and not cast.instant then cast.interruptible = interruptible end
end

-- A cast done: one not begun before was instant, which nothing interrupts.
local function Done(unit, _, spell)
    local guid, id = Ask(Game("UnitGUID"), unit), Plain(spell)
    if type(guid) ~= "string" or type(id) ~= "number" then return end
    local cast = casts[guid]
    if cast and cast.id == id and GetTime() - cast.at < AuraLog.CAST then return end
    local spells = rawget(_G, "C_Spell")
    local name = spells and spells.GetSpellName and Ask(spells.GetSpellName, id)
    casts[guid] = { id = id, name = name, interruptible = false, instant = true, at = GetTime() }
end

-- The cast its caster began for an aura just come (the same spell, a little before), or nil.
local function CastOf(from, id, name)
    local cast = from and casts[from]
    if not cast or GetTime() - cast.at > AuraLog.CAST then return nil end
    if cast.id == id or (cast.name ~= nil and cast.name == name) then return cast end
end

-------------------------------------------------------------------------------
--  Looking at a unit
-------------------------------------------------------------------------------
local function Name(unit)
    if type(unit) ~= "string" then return nil end
    return Core.FullName(unit)
end

-- An aura seen first: a new entry, the newest last; the oldest dropped past AuraLog.MOST.
local function Add(aura, unit, guid, id, harmful, now, clock)
    local lasts, ends = Plain(aura.duration), Plain(aura.expirationTime)
    lasts = type(lasts) == "number" and lasts > 0 and lasts or 0
    local came = now
    if lasts > 0 and type(ends) == "number" and ends > 0 then
        came = math.min(now, ends - lasts) -- one on for a while (from a fight, before you saw it): when it came
    end
    local source = Plain(aura.sourceUnit)
    local from = type(source) == "string" and Ask(Game("UnitGUID"), source) or nil
    local dispel = Plain(aura.dispelName)
    local entry = {
        id = id, name = Plain(aura.name), icon = Plain(aura.icon), harmful = harmful,
        on = Name(unit), guid = guid, boss = Boss(unit) or nil,
        from = type(source) == "string" and Name(source) or nil,
        stamp = math.floor(clock - (now - came) + 0.5), lasts = lasts, stacks = Plain(aura.applications) or 0,
        dispel = type(dispel) == "string" and dispel ~= "" and dispel or nil,
        steal = Plain(aura.isStealable) == true or nil,
    }
    if lasts > 0 then entry.ends = entry.stamp + math.floor(lasts + 0.5) end
    local cast = CastOf(type(from) == "string" and from or nil, id, entry.name)
    if cast then entry.cast, entry.instant = cast.interruptible, cast.instant or nil end
    local entries = List()
    entries[#entries + 1] = entry
    while #entries > AuraLog.MOST do table.remove(entries, 1) end
    return entry
end

-- The plain ones of a list of auras into seen ([instance] = aura); whether all were.
local function Sort(found, seen)
    local whole = true
    for _, aura in ipairs(found) do
        local instance, id = type(aura) == "table" and Plain(aura.auraInstanceID), type(aura) == "table" and Plain(aura.spellId)
        if type(instance) == "number" and type(id) == "number" then
            seen[instance] = aura
        else
            whole = false
        end
    end
    return whole
end

-- One kind of a unit's auras, as the game tells them now: [instance] = aura, every value plain; and whether all were
-- (in a fight the game hides most). Read under pcall: a table the game keeps closed errors when an addon indexes it.
local function Read(unit, filter, seen)
    local auras = rawget(_G, "C_UnitAuras")
    local found = auras and auras.GetUnitAuras and Ask(auras.GetUnitAuras, unit, filter)
    if type(found) ~= "table" then return false end
    local ok, whole = pcall(Sort, found, seen)
    return ok and whole == true
end

local function Look(unit)
    if not Foe(unit) then return end
    local guid = Ask(Game("UnitGUID"), unit)
    if type(guid) ~= "string" or not List() then return end
    where[guid] = unit
    local clock = Ask(Game("time"))
    if type(clock) ~= "number" then return end
    local now, open = GetTime(), Open()
    local helpful, harmful = {}, {}
    local whole = Read(unit, "HELPFUL", helpful)
    whole = Read(unit, "HARMFUL", harmful) and whole
    local held = live[guid] or {}
    live[guid] = held
    local changed = false
    for _, kind in ipairs({ { helpful, false }, { harmful, true } }) do
        for instance, aura in pairs(kind[1]) do
            local entry = held[instance]
            if not entry then
                held[instance] = Add(aura, unit, guid, Plain(aura.spellId), kind[2], now, clock)
                changed = true
            else
                local stacks = Plain(aura.applications)
                if type(stacks) == "number" and stacks > (entry.stacks or 0) then entry.stacks, changed = stacks, true end
                local ends, lasts = Plain(aura.expirationTime), Plain(aura.duration)
                if type(ends) == "number" and type(lasts) == "number" and lasts > 0 then
                    local due = math.floor(clock + (ends - now) + 0.5)
                    if entry.ends and math.abs(due - entry.ends) > 1 then entry.ends, changed = due, true end
                end
            end
        end
    end
    -- What is no longer there went: only told where the game showed all (in a fight it hides most).
    if open and whole then
        for instance, entry in pairs(held) do
            if not (helpful[instance] or harmful[instance]) then
                entry.gone = entry.ends and math.min(clock, entry.ends) or clock
                held[instance] = nil
                changed = true
            end
        end
        if next(held) == nil then live[guid], where[guid] = nil, nil end
    end
    if changed then Tell() end
end

local function Run()
    for unit in pairs(pending) do
        pending[unit] = nil
        Look(unit)
    end
end
local soon, fought = Core.Later(Run, 0, "aura log"), Core.Later(Run, AuraLog.FIGHT, "aura log")
local function Flush()
    if Core.Restricted() then fought() else soon() end
end

local function Asked(unit)
    if type(unit) ~= "string" then return end
    pending[unit] = true
    Flush()
end

-- A unit's own events heard (Core.OnUnit), once per unit.
local heard = {}
local function Hear(unit)
    if heard[unit] then return end
    heard[unit] = true
    Core.OnUnit("UNIT_AURA", unit, function() Asked(unit) end)
    Core.OnUnit("UNIT_SPELLCAST_START", unit, function() Began(unit) end)
    Core.OnUnit("UNIT_SPELLCAST_CHANNEL_START", unit, function() Began(unit) end)
    Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", unit, Done)
    Core.OnUnit("UNIT_SPELLCAST_INTERRUPTIBLE", unit, function() Turned(unit, true) end)
    Core.OnUnit("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit, function() Turned(unit, false) end)
end

-- Every unit looked at again: once the game tells the auras again after a fight.
local function All()
    local now = GetTime()
    for guid, cast in pairs(casts) do
        if now - cast.at > AuraLog.CAST then casts[guid] = nil end
    end
    for _, unit in ipairs(AuraLog.UNITS) do pending[unit] = true end
    for index = 1, rawget(_G, "MAX_BOSS_FRAMES") or 5 do pending["boss" .. index] = true end
    for unit in pairs(heard) do pending[unit] = true end
    Flush()
end

function AuraLog.Start()
    for _, unit in ipairs(AuraLog.UNITS) do Hear(unit) end
    for index = 1, rawget(_G, "MAX_BOSS_FRAMES") or 5 do Hear("boss" .. index) end
    Core.On("PLAYER_TARGET_CHANGED", function() Asked("target") end)
    Core.On("PLAYER_FOCUS_CHANGED", function() Asked("focus") end)
    Core.On("UPDATE_MOUSEOVER_UNIT", function() Asked("mouseover") end)
    Core.On("PLAYER_SOFT_ENEMY_CHANGED", function() Asked("softenemy") end)
    Core.On("INSTANCE_ENCOUNTER_ENGAGE_UNIT", All)
    Core.On("NAME_PLATE_UNIT_ADDED", function(unit)
        unit = Plain(unit)
        if type(unit) ~= "string" then return end
        Hear(unit)
        Asked(unit)
    end)
    Core.On("PLAYER_REGEN_ENABLED", All)
    Core.On("ADDON_RESTRICTION_STATE_CHANGED", function()
        if Open() then All() end
    end)
end

Core.On("PLAYER_LOGIN", function() Core.Safe("aura log", AuraLog.Start) end)
