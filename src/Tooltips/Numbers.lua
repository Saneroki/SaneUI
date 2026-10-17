local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Numbers
--  Figures a tooltip leaves out that follow from what the game does say:
--
--  - a spell: what it does on average, per second, per point of what it
--    costs, and your chance of a critical strike with spells;
--  - the melee swing and the shots: on average, per second, how fast;
--  - a spell's mana as a share of all yours;
--  - a creature: what killing it gives you, and how many such kills your
--    next level is away.
--
--  A spell's effect comes from its description, whose numbers on this client
--  already hold your spell power and talents (no table of spell coefficients).
--  The description is cut at its numbers, and the words between them say what
--  each one is (Texts.lua, STATS.words; English only, so in another language
--  a spell has no figures): an amount, two numbers that make one ("16 to 25"),
--  an amount spread over a time or repeated each second for it, a time. A
--  strike that adds to the weapon's damage, a shield and the like are left
--  alone.
--
--  Per second means while you cast it again and again: a cast takes its cast
--  time, at least the spell's global cooldown, and waits for its cooldown; of
--  what it does over time only the part before the next cast counts, as a
--  new cast starts it anew. For an effect over time alone that is what it
--  does per second of its time.
--
--  Asked when a panel is read, never while it is shown; nothing is kept.
-------------------------------------------------------------------------------
local Plain = SaneUI.Core.Plain
-- Asks the game: each answer nil when hidden, all nil when the function is not there or fails
local Ask = SaneUI.Core.Ask
local STATS = ns.STATS[GetLocale()]
local Numbers = {}
ns.Numbers = Numbers

local USUAL_GCD_MS = 1500 -- the pause after a spell, where the game gives none for it
-- The spells that are a weapon's swing: the melee swing (false) and the shots (true)
local SWING = { [6603] = false, [75] = true, [2764] = true, [3018] = true, [5019] = true }

local out = {} -- the answer, used again

-------------------------------------------------------------------------------
--  Reading a description
-------------------------------------------------------------------------------

-- The description cut at its numbers: values[i] is its i-th number, gaps[i] the words after it
-- and gaps[0] those before the first. Used again for every description; Cut gives the count.
local values, gaps = {}, {}
local function Cut(text)
    local count, from = 0, 1
    for at, digits, after in text:gmatch("()(%d[%d,]*%.?%d*)()") do
        gaps[count] = text:sub(from, at - 1)
        count = count + 1
        values[count] = tonumber((digits:gsub(",", ""))) or 0 -- "1,250" is 1250
        from = after
    end
    gaps[count] = text:sub(from)
    return count
end

local function Matches(text, patterns)
    for _, pattern in ipairs(patterns) do
        if text:find(pattern) then return true end
    end
    return false
end

-- What a description says the spell does: right away, over time, how long that time is (in
-- seconds) and whether it heals (the words before its first amount say so). nil when it names no
-- amount of its own.
local function Effect(description)
    local words = STATS and STATS.words
    if not (words and description) then return nil end
    local text = description:lower()
    for _, word in ipairs(words.elsewhere) do
        if text:find(word, 1, true) then return nil end
    end
    local count = Cut(text)
    local now, later, lasting, heals = 0, 0, nil, nil
    local index = 1
    while index <= count do
        local first, value = index, values[index]
        if index < count and gaps[index]:find(words.joint) then
            value, index = (value + values[index + 1]) / 2, index + 1
        end
        local after = gaps[index]
        local time = index < count and gaps[index + 1]:find(words.time) and values[index + 1]
        local counted = true
        if time and after:find(words.spread) then
            later, lasting, index = later + value, time, index + 1
        elseif time and Matches(after, words.repeats) then
            later, lasting, index = later + value * time, time, index + 1
        elseif now == 0 and (after:find(words.hurt, 1, true) or gaps[first - 1]:find(words.mend)) then
            now = value
        else
            counted = false
        end
        if counted and heals == nil then heals = gaps[first - 1]:find(words.mend) ~= nil end
        index = index + 1
    end
    if now + later <= 0 then return nil end
    return now, later, lasting, heals
end

-------------------------------------------------------------------------------
--  What the game says of a spell
-------------------------------------------------------------------------------

-- How long one cast keeps you from the next, in milliseconds: its cast, at least its global
-- cooldown, at least its own cooldown.
local function Pace(id)
    local info = Ask(C_Spell and C_Spell.GetSpellInfo, id)
    local cast = type(info) == "table" and tonumber(Plain(info.castTime)) or 0
    local cooldown, gcd = Ask(rawget(_G, "GetSpellBaseCooldown"), id)
    if not (type(gcd) == "number" and gcd > 0) then gcd = USUAL_GCD_MS end
    return math.max(cast, gcd, type(cooldown) == "number" and cooldown or 0)
end

-- What the spell costs: how much, the kind of power (0: mana) and that power's name ("MANA").
local function Price(id)
    local costs = Ask(C_Spell and C_Spell.GetSpellPowerCost or rawget(_G, "GetSpellPowerCost"), id)
    if type(costs) ~= "table" then return nil end
    for _, entry in ipairs(costs) do
        entry = Plain(entry)
        local amount = type(entry) == "table" and tonumber(Plain(entry.cost))
        if amount and amount > 0 then return amount, Plain(entry.type), Plain(entry.name) end
    end
    return nil
end

-- A spell's mana as a share of all yours, in %; nil for a spell that costs no mana.
function Numbers.Share(id)
    local amount, power = Price(id)
    if not amount or power ~= 0 then return nil end
    local most = Ask(UnitPowerMax, "player", 0)
    return most and most > 0 and amount / most * 100 or nil
end

-- A weapon's swing: on average, per second, its speed and your chance of a critical strike
local function Swing(ranged)
    local low, high, speed
    if ranged then
        speed, low, high = Ask(rawget(_G, "UnitRangedDamage"), "player")
        out.crit = Ask(rawget(_G, "GetRangedCritChance"))
    else
        low, high = Ask(rawget(_G, "UnitDamage"), "player")
        speed = Ask(rawget(_G, "UnitAttackSpeed"), "player")
        out.crit = Ask(rawget(_G, "GetCritChance"))
    end
    if not (low and high and speed and speed > 0) then return nil end
    out.amount, out.heal, out.speed = (low + high) / 2, false, speed
    out.perSecond = out.amount / speed
    return out
end

-- A spell's figures, or nil:
--   amount, heal, perSecond      what one cast does on average; whether it heals; per second
--   perPower, power              per point of what it costs, and that power's name ("Mana")
--   crit                         your chance of a critical strike with spells, in %
--   speed                        a weapon's swing: seconds between two
function Numbers.Spell(id, description)
    if not id then return nil end
    wipe(out)
    local ranged = SWING[id]
    if ranged ~= nil then return Swing(ranged) end
    local now, later, lasting, heals = Effect(description)
    if not now then return nil end
    local pace = Pace(id)
    local running = lasting and lasting > 0 and math.min(1, pace / (lasting * 1000)) or 1
    out.amount, out.heal = now + later, heals
    out.perSecond = (now + later * running) * 1000 / pace
    local amount, _, name = Price(id)
    if amount then out.perPower, out.power = out.amount / amount, type(name) == "string" and ns.Global(name) or nil end
    -- This client has one chance for every school (the character sheet's)
    out.crit = Ask(rawget(_G, "GetSpellCritChance"))
    return out
end

-------------------------------------------------------------------------------
--  Experience
-------------------------------------------------------------------------------

-- The game's rule for what a kill gives (as the original game has it), by your level: a row holds
-- the highest level it is for, how many levels below yours a creature's gain fades to nothing,
-- and how many levels below yours a creature is grey and gives nothing at all.
local KILL_RULE = {
    { 7, 5, 5 }, { 9, 6, 5 }, { 11, 7, 6 }, { 15, 8, 6 }, { 19, 9, 6 }, { 29, 11, 7 }, { 39, 12, 8 },
    { 44, 13, 9 }, { 49, 14, 10 }, { 54, 15, 11 }, { 59, 16, 12 }, { math.huge, 17, 9 },
}
local RISE, RISE_LEVELS = 0.05, 4 -- a creature above you gives 5 % more per level, for up to 4 levels
local DOUBLED = { elite = true, rareelite = true, worldboss = true } -- give twice as much

-- What killing a creature of this level gives at your level (rested or not), or nil for nothing
local function Gain(mine, theirs, doubled)
    local row
    for _, entry in ipairs(KILL_RULE) do
        if mine <= entry[1] then
            row = entry
            break
        end
    end
    local below = mine - theirs
    if below >= row[3] then return nil end
    local gain = (mine * 5 + 45) * (below > 0 and 1 - below / row[2] or 1 + RISE * math.min(-below, RISE_LEVELS))
    if doubled then gain = gain * 2 end
    return math.floor(gain + 0.5)
end

-- What killing the unit gives you, and how many such kills your next level is away; nil for a
-- unit that gives nothing (a player, a friend, one somebody else has tapped, a dead or a grey one,
-- or you are at the highest level).
function Numbers.Experience(unit)
    local mine, theirs = Ask(UnitLevel, "player"), Ask(UnitLevel, unit)
    if not (mine and theirs and theirs > 0) then return nil end
    local top = Ask(rawget(_G, "GetMaxPlayerLevel")) or rawget(_G, "MAX_PLAYER_LEVEL")
    if top and mine >= top then return nil end
    if Ask(UnitIsPlayer, unit) or not Ask(UnitCanAttack, "player", unit) then return nil end
    if Ask(rawget(_G, "UnitIsTapDenied"), unit) or Ask(UnitIsDead, unit) then return nil end
    local gain = Gain(mine, theirs, DOUBLED[Ask(UnitClassification, unit) or ""])
    if not gain or gain <= 0 then return nil end
    local rested = Ask(rawget(_G, "GetXPExhaustion"))
    if rested and rested > 0 then gain = gain + math.min(gain, rested) end
    local have, need = Ask(UnitXP, "player"), Ask(UnitXPMax, "player")
    return gain, have and need and need > have and math.ceil((need - have) / gain) or nil
end
