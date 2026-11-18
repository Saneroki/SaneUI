local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Meter - Fights
--  Which fight the meter shows. Its pages are the fights the game's meter holds,
--  oldest first; the last page is the live one, and a new fight goes back there:
--      Reset on new combat ticked   the live page is this fight alone: every number starts at nothing
--      unticked                     the live page is all fights added up
--
--  A saved fight is plain numbers under a name of your own (store.meterFights), kept
--  over logins and for every character of the account, in a group or not. A fight is
--  saved once its numbers are plain: asked in a fight, it is saved when the fight
--  ends. A loaded one stays until an arrow, the flyout or a new fight leaves it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Fights = {}
ns.MeterFights = Fights

local page     -- the page looked at, in the game's list; nil: the live one
local loaded   -- the saved fight looked at, read for the meter (Loaded)
local before   -- the newest fight the game held when this one began
local closing  -- a fight is over and has no number yet: its threat waits for it (Settle)
local fighting -- from the game's word that a fight begins to its word that it ended

local function Live()
    return { type = ns.options.meterReset and "Current" or "Overall" }
end

-- The fight looked at: where to read it, and what the game says of it.
local function Where(sessions)
    local session = page and sessions[page]
    if session then return { id = session.id }, session end
    page = nil
    return Live(), sessions[#sessions]
end

-- A saved fight as a read one: every number plain, its people its own.
local function Loaded(record)
    local read = { people = {}, numbers = {}, top = {}, rank = {}, seconds = record.seconds, saved = record }
    for index, one in ipairs(record.people) do
        local guid = one.guid or "saved" .. index -- a character's own bars still count for them
        read.people[index] = { guid = guid, name = one.name, class = one.class, level = one.level, item = one.item,
                               me = one.me }
        local numbers = {}
        read.numbers[guid] = numbers
        for kind, entry in pairs(one.numbers) do
            numbers[kind] = entry
            read.top[kind] = math.max(read.top[kind] or 0, entry.total or 0)
        end
    end
    return read
end

-- The fight looked at, its kinds read as types says (Read.Fight).
function Fights.Read(types)
    if loaded then return loaded end
    local people = ns.MeterRead.People()
    if fighting then ns.MeterThreat.Sample(people) end
    local where, session = Where(ns.MeterRead.Sessions())
    local read = ns.MeterRead.Fight(where, types, people)
    if where.id then read.seconds = session.seconds or read.seconds end
    if fighting and not where.id then read.seconds = ns.MeterThreat.Seconds(where) end
    ns.MeterThreat.Into(read, where, read.seconds)
    if where.id then read.people = ns.MeterRead.Fought(read) end
    return read
end

-- The page shown and how many there are.
function Fights.Page()
    local count = math.max(#ns.MeterRead.Sessions(), 1)
    return page or count, count
end

-- Whether a saved fight is shown.
function Fights.Loaded()
    return loaded ~= nil
end

-- One page on (+1) or back (-1). From a saved fight the arrows lead back to the fights.
function Fights.Step(step)
    if loaded then
        loaded = nil
        return
    end
    local now, count = Fights.Page()
    local wanted = math.max(1, now + step)
    page = wanted < count and wanted or nil
end

-- What the page's tooltip says of the fight shown: its name and how long it took (nil where the game gives neither).
function Fights.About()
    if loaded then return loaded.saved.name, loaded.seconds end
    local sessions = ns.MeterRead.Sessions()
    local session = page and sessions[page] or sessions[#sessions]
    if session then return session.name, session.seconds end
    return nil
end

-- Whether a fight is on, as the game told: as it tells of one its lockdown has not begun yet (InCombatLockdown).
function Fights.Fighting()
    return fighting or false
end

-- A fight begins: the live page, and the threat from nothing.
function Fights.Began()
    page, loaded, closing, fighting = nil, nil, nil, true
    local sessions = ns.MeterRead.Sessions()
    before = sessions[#sessions] and sessions[#sessions].id
    ns.MeterThreat.Begin()
end

-- The game listed the fight that ended: its threat goes with it.
function Fights.Settle()
    if not closing then return end
    local sessions = ns.MeterRead.Sessions()
    local newest = sessions[#sessions]
    if newest and newest.id ~= before then
        closing = nil
        ns.MeterThreat.Close(newest.id)
    end
end

-- A fight is over.
function Fights.Ended()
    closing, fighting = true, false
    ns.MeterThreat.End()
    Fights.Settle()
end

-- The game's meter was reset.
function Fights.Cleared()
    page, closing = nil, nil
    ns.MeterThreat.Clear()
end

-- The saved fights, oldest first.
function Fights.List()
    ns.store.meterFights = ns.store.meterFights or {}
    return ns.store.meterFights
end

-- The name a fight is offered to be saved as: its own and the time.
function Fights.Suggest()
    return (Fights.About() or ns.TEXT.meterFight) .. " " .. Core.ClockAt()
end

-- The fight shown, as plain numbers.
local function Saved(name)
    local types = {}
    for kind, each in pairs(ns.MeterRead.TYPES) do types[kind] = each.rate or each.total end
    local read = Fights.Read(types)
    local record = { name = name, when = GetServerTime(), seconds = read.seconds, people = {} }
    for index, person in ipairs(read.people) do
        local numbers = {}
        for kind, entry in pairs(read.numbers[person.guid] or {}) do
            numbers[kind] = { total = Plain(entry.total), rate = Plain(entry.rate) }
        end
        record.people[index] = { guid = person.guid, name = person.name, class = person.class, level = person.level,
                                 item = person.item, me = person.me, numbers = numbers }
    end
    return record
end

local function Keep(name)
    local list = Fights.List()
    list[#list + 1] = Saved(name)
    ns.Print(ns.TEXT.meterSaved:format(name))
    ns.Meter.Refresh()
end

-- The fight shown saved under that name (empty: the one offered). In a fight, once it is over.
function Fights.Save(name)
    if not name or name == "" then name = Fights.Suggest() end
    if InCombatLockdown() then ns.Print(ns.TEXT.meterSaveLater:format(name)) end
    Core.AfterCombat("meter save", Keep, name)
end

-- That saved fight shown.
function Fights.Load(record)
    loaded = Loaded(record)
end

-- Back to the fights.
function Fights.Unload()
    loaded = nil
end

-- That saved fight gone for good; shown, the fights again.
function Fights.Delete(record)
    if loaded and loaded.saved == record then loaded = nil end
    local list = Fights.List()
    for index, each in ipairs(list) do
        if each == record then return table.remove(list, index) end
    end
end
