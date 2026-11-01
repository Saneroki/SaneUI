local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Meter - Threat
--  The one thing of the meter the game keeps no record of. Each look in a fight
--  every member's threat on the mob you are fighting is asked
--  (UnitDetailedThreatSituation): its share, how close to taking aggro, and its
--  raw threat, whose gains are added up per fight and over all fights.
--
--  The mob: your target while you can attack it, else the first boss. Its GUID may
--  be hidden, so a new mob is only known by a new target: what a member had on the
--  old one is forgotten, and only what they gain from then on counts.
--
--  On a boss the game hides these numbers (shown, never computed with): the share
--  still goes to the bar and the words as it came, but nothing can be added up, so
--  the total and the threat per second of that fight stay as they were.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local Threat = {}
ns.MeterThreat = Threat

Threat.SCALE = 100 -- the game's raw threat is a hundred times the threat it speaks of
Threat.KEPT = 30   -- past fights whose threat is kept for their pages: the game's meter keeps few more

local fight, all = {}, {}   -- [guid] = threat: this fight, all fights together
local past, order = {}, {}  -- [the game's session] = a fight's threat; in the order they came
local last = {}             -- [guid] = raw threat on the mob last looked at
local shares = {}           -- [guid] = its share on the mob now, as the game gave it
local started               -- when this fight began; nil out of one
local spent = 0             -- seconds of the fights before it

-- The mob the fight is about: nil where there is none.
local function Mob()
    if Plain(UnitExists("target")) and Ask(UnitCanAttack, "player", "target") then return "target" end
    if Plain(UnitExists("boss1")) then return "boss1" end
    return nil
end

-- One member's look at the mob. pcall: a client update may take it away, and a unit may be gone.
local function Look(guid, unit, mob)
    local ok, _, _, share, _, raw = pcall(UnitDetailedThreatSituation, unit, mob)
    if not ok then return end
    shares[guid] = share
    raw = Plain(raw)
    if not raw then return end
    local gain = last[guid] and raw - last[guid] or 0
    last[guid] = raw
    if gain > 0 then
        gain = gain / Threat.SCALE
        fight[guid] = (fight[guid] or 0) + gain
        all[guid] = (all[guid] or 0) + gain
    end
end

-- Every member's threat now (Read.People's list).
function Threat.Sample(people)
    local mob = Mob()
    wipe(shares)
    if not mob then return end
    for _, person in ipairs(people) do
        if person.unit then Look(person.guid, person.unit, mob) end
    end
end

-- Another mob: nobody's threat so far says anything about it.
function Threat.Retarget()
    wipe(last)
    wipe(shares)
end

-- A fight begins: its threat from nothing, and its own clock.
function Threat.Begin()
    fight, started = {}, GetTime()
    Threat.Retarget()
end

-- A fight is over.
function Threat.End()
    if started then spent = spent + GetTime() - started end
    started = nil
    Threat.Retarget()
end

-- The game's meter gave the fight that just ended its number: its threat stays with it, for its page.
function Threat.Close(session)
    if not session or past[session] then return end
    past[session] = fight
    order[#order + 1] = session
    if #order > Threat.KEPT then past[table.remove(order, 1)] = nil end
end

-- The game's meter was reset: nothing is left.
function Threat.Clear()
    fight, all, past, order, spent = {}, {}, {}, {}, 0
    Threat.Retarget()
end

-- How many seconds the live page has lasted so far: this fight, or all of them.
function Threat.Seconds(where)
    local now = started and GetTime() - started or 0
    return where.type == "Overall" and spent + now or now
end

-- Adds what is known to a fight being read (Read.Fight): where says which fight, seconds how long it took.
function Threat.Into(read, where, seconds)
    local kept = where.id and past[where.id] or (where.type == "Overall" and all) or (where.type == "Current" and fight) or {}
    local top = 0
    for guid, total in pairs(kept) do
        local numbers = read.numbers[guid] or {}
        read.numbers[guid] = numbers
        numbers.threat = { total = total, rate = seconds and seconds > 0 and total / seconds or 0 }
        top = math.max(top, total)
    end
    read.top.threat = top
    if where.id then return end
    for guid, share in pairs(shares) do
        local numbers = read.numbers[guid] or {}
        read.numbers[guid] = numbers
        numbers.threat = numbers.threat or { total = 0, rate = 0 }
        numbers.threat.share = share
    end
end
