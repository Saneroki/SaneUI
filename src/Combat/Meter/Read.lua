local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Meter - Read
--  What the meter shows, as the game tells it: who is in the group, and the numbers
--  of a fight from the game's own damage meter (C_DamageMeter, in both games). The
--  combat log is closed to addons, so that is the only way to these numbers.
--
--  A fight's numbers are hidden while you fight (secret values): they go to a bar
--  and into words as they came, and are never compared or added up here. So:
--      who          each of the game's sources is told by its GUID, plain for the
--                   members of your group; where it is hidden after all, a member's
--                   own numbers are asked for by their GUID, which gives the total
--                   but no rate (Read.One)
--      the order    the game's list comes best first: in a fight its places stand in
--                   for the numbers (read.rank)
--      a bad read   a table the game will not let us read yet: the fight's numbers
--                   stay empty until it is over, and nothing is reported, as nothing
--                   is wrong
--
--  A person is { guid, name, class, level, item, unit, me }: unit only while they
--  are in your group; what was seen of them is kept until the next /reload, so a
--  past fight still shows who left since.
--
--  A read fight is { people, numbers, top, rank, seconds, hidden }; a row asks it for one number by Read.Entry:
--      numbers[guid].damage = { total, rate }  also healing, interrupts (no rate), threat (and its share)
--      top.damage                              the highest total, a bar's whole length
--      rank.damage[guid]                       its place in the game's list
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local Read = {}
ns.MeterRead = Read

-- What each kind is read as; rate: read so when the list is sorted by the rate (Read.ORDERS).
Read.TYPES = {
    damage = { total = "DamageDone", rate = "Dps" },
    healing = { total = "HealingDone", rate = "Hps" },
    interrupts = { total = "Interrupts" },
}

-- What the list can be sorted by: its key, the number of which kind, the words in the flyout Order by.
Read.ORDERS = {
    { key = "dps", kind = "damage", field = "rate", text = ns.TEXT.meterDps },
    { key = "hps", kind = "healing", field = "rate", text = ns.TEXT.meterHps },
    { key = "threat", kind = "threat", field = "total", text = ns.TEXT.meterKinds.threat },
    { key = "interrupts", kind = "interrupts", field = "total", text = ns.TEXT.meterKinds.interrupts },
    { key = "damage", kind = "damage", field = "total", text = ns.TEXT.meterTotalDamage },
    { key = "healing", kind = "healing", field = "total", text = ns.TEXT.meterTotalHealing },
}

local seen = {} -- [guid] = a person, however they left

-- Whether the game's meter is there to ask.
function Read.Ready()
    local enum = rawget(_G, "Enum")
    return type(rawget(_G, "C_DamageMeter")) == "table" and type(enum) == "table" and enum.DamageMeterType ~= nil
end

-- Who a unit of your group is, kept.
local function Person(unit, guid, me)
    local person = seen[guid] or { guid = guid }
    seen[guid] = person
    person.unit, person.me = unit, me
    person.name = Core.FullName(unit) or person.name or "?"
    person.class = select(2, Ask(UnitClass, unit)) or person.class
    local level = Ask(UnitLevel, unit)
    if level and level > 0 then person.level = level end
    person.item = Core.Inspect.Level(unit, guid) or person.item
    return person
end

-- You, then everybody else of your party or raid. Your own slot of a raid is you: never twice.
function Read.People()
    local people = {}
    for _, person in pairs(seen) do person.unit = nil end
    local mine = Plain(UnitGUID("player"))
    if mine then people[1] = Person("player", mine, true) end
    local raid = Ask(IsInRaid)
    for index = 1, (raid and Ask(GetNumGroupMembers) or Ask(GetNumSubgroupMembers)) or 0 do
        local unit = (raid and "raid" or "party") .. index
        local guid = Plain(UnitGUID(unit))
        if guid and guid ~= mine then people[#people + 1] = Person(unit, guid, false) end
    end
    return people
end

-- The fights the game holds now, oldest first: { id, name, seconds }. Plain, even in a fight.
function Read.Sessions()
    local list = {}
    if not Read.Ready() then return list end
    local sessions = Ask(C_DamageMeter.GetAvailableCombatSessions)
    if type(sessions) ~= "table" then return list end
    for _, session in ipairs(sessions) do
        local id = Plain(session.sessionID)
        if id then list[#list + 1] = { id = id, name = Plain(session.name), seconds = Plain(session.durationSeconds) } end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- The game's list of one fight, read as that type: where is { id = session } or { type = "Current" / "Overall" }.
local function Session(where, name)
    local kind = Enum.DamageMeterType[name]
    if where.id then return C_DamageMeter.GetCombatSessionFromID(where.id, kind) end
    return C_DamageMeter.GetCombatSessionFromType(Enum.DamageMeterSessionType[where.type], kind)
end

local function Numbers(read, guid)
    local numbers = read.numbers[guid]
    if not numbers then
        numbers = {}
        read.numbers[guid] = numbers
    end
    return numbers
end

-- Everybody on the game's list of one kind. A source in the fight who is not in the group now is kept among the
-- people the fight shows.
local function Fill(read, session, kind, mine)
    read.top[kind] = session.maxAmount
    local ranks = {}
    read.rank[kind] = ranks
    for place, source in ipairs(session.combatSources or {}) do
        local guid = source.isLocalPlayer and mine or Plain(source.sourceGUID)
        if guid then
            Numbers(read, guid)[kind] = { total = source.totalAmount, rate = source.amountPerSecond }
            ranks[guid] = place
            if not seen[guid] then seen[guid] = { guid = guid } end
            local person = seen[guid]
            person.name = person.name or Plain(source.name)
            person.class = person.class or Plain(source.classFilename)
        else
            read.unknown = true
        end
    end
end

-- A fight's numbers of the kinds asked for: types = { [kind] = the game's type to read it as }.
function Read.Fight(where, types, people)
    local read = { people = people, numbers = {}, top = {}, rank = {}, where = where }
    if not Read.Ready() then return read end
    local mine = Plain(UnitGUID("player"))
    for kind, name in pairs(types) do
        local ok, session = pcall(Session, where, name)
        if ok and type(session) == "table" then
            read.hidden = read.hidden or Core.Secret(session.maxAmount)
            read.seconds = read.seconds or Plain(session.durationSeconds)
            if not pcall(Fill, read, session, kind, mine) then read.unknown = true end
        else
            read.unknown = true
        end
    end
    return read
end

-- One member's number of a kind, for a fight that could not tell who its sources are: asked by their GUID, the total
-- alone (the game gives no rate that way).
function Read.One(read, kind, guid)
    local where, types = read.where, Read.TYPES[kind]
    if not (where and types and Read.Ready()) then return nil end
    local name = Enum.DamageMeterType[types.total]
    local ok, source
    if where.id then
        ok, source = pcall(C_DamageMeter.GetCombatSessionSourceFromID, where.id, name, guid)
    else
        ok, source = pcall(C_DamageMeter.GetCombatSessionSourceFromType, Enum.DamageMeterSessionType[where.type], name, guid)
    end
    if not ok or type(source) ~= "table" then return nil end
    return { total = source.totalAmount }
end

-- One character's number of a kind in a read fight: from the game's list, else, where that list could not tell who
-- its sources are, asked for by their GUID (Read.One) once, and kept with the fight for the row that draws it.
function Read.Entry(read, kind, guid)
    local numbers = read.numbers[guid]
    local entry = numbers and numbers[kind]
    if entry or not read.unknown then return entry end
    read.asked = read.asked or {}
    local key = guid .. " " .. kind
    if read.asked[key] then return nil end
    read.asked[key] = true
    entry = Read.One(read, kind, guid)
    if entry then Numbers(read, guid)[kind] = entry end
    return entry
end

-- Whoever fought in a past fight, as far as they are known, and you, in it or not.
function Read.Fought(read)
    local list = {}
    for guid in pairs(read.numbers) do
        local person = seen[guid]
        if person and person.name and not person.me then list[#list + 1] = person end
    end
    local mine = seen[Plain(UnitGUID("player")) or ""]
    if mine then list[#list + 1] = mine end
    return list
end
