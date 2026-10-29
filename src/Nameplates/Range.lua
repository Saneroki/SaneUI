local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Range
--  How far each plate's unit is from your character, and whether any of your
--  attacks reach it. The game tells addons no distance; it does tell whether
--  a unit is within the range of an item's use (C_Item.IsItemInRange) or of
--  one of your spells (C_Spell.IsSpellInRange), measured from your character.
--  So each unit is asked against a ladder of ranges, the shortest first:
--  items of the game whose use reaches that far (Range.ENEMY for foes,
--  Range.FRIEND for friends: game facts, picked from its own item and spell
--  tables), and your own spells with a range (harmful ones for foes, helpful
--  ones for friends). The first that reaches it bounds the distance from
--  above, the last that did not from below (Range.Check; nothing reaches it:
--  up to the farthest the game shows plates, Range.FAR). The distance kept
--  (Range.Follow) is at the rung a unit just moved past (the one distance
--  known for sure) and from there moves on every frame (Range.Drift) at the
--  pace the unit passed its last two rungs (a run's, Range.RUN, before that
--  is known), never past the two rungs it stands between: there it waits for
--  the unit to pass the next. So a plate's size follows its unit smoothly
--  between the rungs (Scale.lua), not in a step at each.
--
--  Out of reach: a foe none of your harmful spells reaches now (one says no,
--  none yes; or none can say and the ladder puts it beyond the farthest of
--  them). A spell that reaches only from afar (a least range: Charge,
--  Auto Shot) says no to a foe too close as well, so its no counts for
--  nothing. Its border is red then (Bar.Border), your target's and every
--  other foe's alike (the setting Out of reach: red border).
--
--  Looked at every Range.EVERY seconds for every plate shown (Scale.lua's
--  driver calls Range.Look), and once as a plate appears (Range.One, so it
--  shows at its size at once); first the two rungs it stood between at the
--  last look (two questions while it stays there), else up the ladder from
--  the shortest. Where the game will not answer for an item (an item it has not
--  loaded), the spells answer alone, and a distance that cannot be told keeps
--  the last one. An item is never asked about a foe in a fight: the game
--  forbids that to addons then, and each such question was a blocked action
--  (Saneroki, 2026-10-29: thousands in Retail's taint log); the spells answer
--  alone there.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Range = {}
ns.Range = Range

Range.FAR = 60     -- the farthest the game shows plates of units not targeted, in yards
Range.EVERY = 0.1  -- seconds between looks
Range.RUN = 7      -- yards a second a running unit covers: the pace taken where it is not known yet
Range.FASTEST = 40 -- a pace beyond this many yards a second is no pace but a jump (a charge, a blink): none then
Range.STALE = 3    -- seconds after which the last rung passed tells nothing of a unit's pace any more
Range.longest = 0
-- Items whose use reaches a foe that far: { yards, item }, from the game's tables (its item effects, their spells'
-- ranges and targets).
Range.ENEMY = { { 5, 3912 }, { 8, 238736 }, { 10, 9606 }, { 15, 275347 }, { 20, 10645 }, { 25, 274414 },
                { 30, 835 }, { 35, 1402 }, { 40, 4945 } }
-- And a friend.
Range.FRIEND = { { 5, 1970 }, { 10, 21267 }, { 15, 1251 }, { 20, 12450 }, { 25, 13289 }, { 30, 954 },
                 { 35, 18904 }, { 40, 18662 }, { 45, 221316 }, { 50, 274093 } }

local ladders = { foe = {}, friend = {} } -- { yards, item = id } or { yards, spell = id }, the shortest first
local attacks = {}                       -- your harmful spells with a range

-- Your spells with a range, as your spellbook has them now: harmful, helpful, each with its reach.
local function Spells()
    local book, spell = rawget(_G, "C_SpellBook"), rawget(_G, "C_Spell")
    local enum = rawget(_G, "Enum")
    local harmful, helpful = {}, {}
    if not (book and spell and enum and enum.SpellBookSpellBank and enum.SpellBookItemType) then return harmful, helpful end
    local bank, kind = enum.SpellBookSpellBank.Player, enum.SpellBookItemType.Spell
    for line = 1, Core.Ask(book.GetNumSpellBookSkillLines) or 0 do
        local info = Core.Ask(book.GetSpellBookSkillLineInfo, line)
        if type(info) == "table" and not info.shouldHide and (Plain(info.offSpecID) or 0) == 0 then
            local first = (Plain(info.itemIndexOffset) or 0) + 1
            for index = first, first + (Plain(info.numSpellBookItems) or 0) - 1 do
                local item = Core.Ask(book.GetSpellBookItemInfo, index, bank)
                local id = type(item) == "table" and Plain(item.spellID)
                if id and Plain(item.itemType) == kind and not Plain(item.isPassive) and Core.Ask(spell.SpellHasRange, id) then
                    local data = Core.Ask(spell.GetSpellInfo, id)
                    local most = type(data) == "table" and Plain(data.maxRange)
                    local least = type(data) == "table" and Plain(data.minRange) or 0
                    if type(most) == "number" and most > 0 then
                        local entry = { most, spell = id, least = least }
                        if Core.Ask(spell.IsSpellHarmful, id) then harmful[#harmful + 1] = entry end
                        if Core.Ask(spell.IsSpellHelpful, id) then helpful[#helpful + 1] = entry end
                    end
                end
            end
        end
    end
    return harmful, helpful
end

-- A ladder: the items and the spells, the shortest reach first; spells that reach only from afar (a minimum range)
-- say nothing of how near a unit is, and stay out.
local function Ladder(items, spells)
    local ladder = {}
    for _, entry in ipairs(items) do ladder[#ladder + 1] = { entry[1], item = entry[2] } end
    for _, entry in ipairs(spells) do
        if (entry.least or 0) == 0 then ladder[#ladder + 1] = entry end
    end
    table.sort(ladder, function(a, b) return a[1] < b[1] end)
    return ladder
end

-- The ladders and your attacks made anew (your spells changed), the items asked to load.
function Range.Rebuild()
    local harmful, helpful = Spells()
    attacks = harmful
    Range.longest = 0 -- the farthest any of your attacks reaches
    for _, entry in ipairs(harmful) do Range.longest = math.max(Range.longest, entry[1]) end
    ladders.foe = Ladder(Range.ENEMY, harmful)
    ladders.friend = Ladder(Range.FRIEND, helpful)
    local items = rawget(_G, "C_Item")
    local load = items and items.RequestLoadItemDataByID
    if load then
        for _, list in ipairs({ Range.ENEMY, Range.FRIEND }) do
            for _, entry in ipairs(list) do pcall(load, entry[2]) end
        end
    end
end

-- Whether we are in a fight as the game's restrictions count it: its lockdown, or its addon restriction for combat,
-- which may begin a moment before.
local function Fighting()
    if InCombatLockdown() then return true end
    local restricted, enum = rawget(_G, "C_RestrictedActions"), rawget(_G, "Enum")
    local kinds = enum and enum.AddOnRestrictionType
    return restricted and kinds and kinds.Combat
        and Core.Ask(restricted.IsAddOnRestrictionActive, kinds.Combat) == true or false
end

-- Whether a rung reaches the unit: true, false, or nil where the game will not tell (an item about a foe in a fight
-- is not asked: blocked).
local function Reaches(rung, unit, foe, fighting)
    if rung.spell then return Core.Ask(C_Spell.IsSpellInRange, rung.spell, unit) end
    if foe and fighting then return nil end
    local items = rawget(_G, "C_Item")
    local ask = items and items.IsItemInRange or rawget(_G, "IsItemInRange")
    return Core.Ask(ask, rung.item, unit)
end

-- Whether a unit still stands where it stood at the last look (at: the index of the nearest rung that reached it,
-- false for beyond them all): that rung still reaches it and the one under it still does not. Two questions.
local function Still(ladder, at, unit, foe, fighting)
    local above = at and ladder[at]
    if at and not above then return false end -- the ladder is shorter now
    local below = ladder[(at or #ladder + 1) - 1]
    if not (above or below) then return false end
    if above and Reaches(above, unit, foe, fighting) ~= true then return false end
    if below and Reaches(below, unit, foe, fighting) ~= false then return false end
    return true
end

-- Between which distances a unit stands (the farthest rung that did not reach it, the nearest that did; nil, nil
-- where no rung could tell), and for a foe whether your attacks reach it (true, false, or nil where none of your
-- spells could tell); then where on the ladder (the index of that nearest rung, false beyond them all: the at of
-- the next look, which asks those two rungs first; nil where none could tell).
function Range.Check(unit, at)
    local foe = Core.Ask(UnitCanAttack, "player", unit) == true
    local fighting = foe and Fighting()
    local ladder = foe and ladders.foe or ladders.friend
    local below, above, told, index = nil, nil, false, nil
    if at ~= nil and Still(ladder, at, unit, foe, fighting) then
        below = ladder[(at or #ladder + 1) - 1]
        above, below, told, index = at and ladder[at][1], below and below[1], below ~= nil, at
    else
        for position, rung in ipairs(ladder) do
            local reach = Reaches(rung, unit, foe, fighting)
            if reach == true then
                above, index = rung[1], position
                break
            elseif reach == false then
                below, told = rung[1], true
            end
        end
        if not above and told then index = false end
    end
    local least, most = nil, nil
    if told or above then least, most = below or 0, above or Range.FAR end
    if not foe then return least, most, nil, index end
    local no = false
    for _, entry in ipairs(attacks) do
        local reach = Core.Ask(C_Spell.IsSpellInRange, entry.spell, unit)
        if reach == true then return least, most, true, index end
        if reach == false and (entry.least or 0) == 0 then no = true end
    end
    -- Beyond the farthest of your attacks by the ladder, though they could not say: out of reach too.
    if no or (least and Range.longest > 0 and least >= Range.longest) then return least, most, false, index end
    return least, most, nil, index
end

-- A unit's distance kept from look to look: where the ladder puts it between two rungs, it stays where it was if it
-- was there; where it moved past a rung, it is at that rung now (the one distance the ladder knows for sure); the
-- first time, in the middle.
function Range.Settle(yards, least, most)
    if not least then return yards end
    if not yards then return (least + most) / 2 end
    if yards < least then return least end
    if yards > most then return most end
    return yards
end

-- A unit's distance followed from look to look (between least and most, the rungs the ladder puts it between now):
-- where it went on to the next two rungs, at the rung it passed, its pace anew: from the rung passed before (if not
-- long ago), else a run's that way. Where the rungs are the same, it moves on (Range.Drift); where they are others
-- (a jump: a charge, a blink, or the ladder itself changed), within them (Range.Settle), without a pace. The first
-- time in the middle, without a pace.
function Range.Follow(dress, least, most, now)
    if not least then return end -- nothing could tell: as it was
    local yards, wasLeast, wasMost = dress.yards, dress.least, dress.most
    dress.least, dress.most = least, most
    if not yards then
        dress.yards, dress.pace = Range.Settle(nil, least, most), 0
        return
    end
    if wasLeast == least and wasMost == most then return end
    local rung, way = nil, nil
    if wasMost == least then
        rung, way = least, 1 -- out, past the rung between them
    elseif wasLeast == most then
        rung, way = most, -1 -- in
    end
    if not rung then
        dress.yards, dress.pace = Range.Settle(yards, least, most), 0
        dress.mark, dress.markAt = dress.yards ~= yards and dress.yards or nil, now
        return
    end
    local mark, since = dress.mark, now - (dress.markAt or now)
    local pace = way * Range.RUN
    if mark and mark ~= rung and since > 0 and since < Range.STALE and (rung - mark) * way > 0 then
        pace = (rung - mark) / since
    end
    if math.abs(pace) > Range.FASTEST then pace = 0 end
    dress.yards, dress.pace, dress.mark, dress.markAt = rung, pace, rung, now
end

-- A unit's distance moved on at its pace between looks, never past the rungs it stands between: at one it waits,
-- its pace spent, until the unit passes it. Whether it moved.
function Range.Drift(dress, elapsed)
    local pace, yards, least, most = dress.pace, dress.yards, dress.least, dress.most
    if not pace or pace == 0 or not yards or not least then return false end
    yards = yards + pace * elapsed
    if yards <= least then
        yards, dress.pace = least, 0
    elseif yards >= most then
        yards, dress.pace = most, 0
    end
    dress.yards = yards
    return true
end

-- One plate looked at: its distance and whether it is out of your reach; its border lit anew where that changed.
function Range.One(unit, dress)
    local least, most, reach, at = Range.Check(unit, dress.rung)
    dress.rung = at
    Range.Follow(dress, least, most, GetTime())
    local out = (ns.options or {}).range ~= false and reach == false
    if out ~= (dress.out == true) then
        dress.out = out
        ns.Plate.Light(dress)
    end
end

-- Every plate looked at (Scale.lua's driver, every Range.EVERY seconds; a plate as it appears, Scale.Born).
function Range.Look()
    for unit, dress in pairs(ns.Plate.shown) do Range.One(unit, dress) end
end

local rebuild = Core.Later(Range.Rebuild)

-- /sane range: what the game answers for your target, each of your attacks with its reach, and the distance found.
local function Tell()
    if Plain(UnitExists("target")) ~= true then return ns.Print("Range: no target.") end
    local least, most, reach = Range.Check("target")
    ns.Print(("Range: between %s and %s yards; your attacks %s."):format(least or "?", most or "?",
        reach == true and "reach it" or reach == false and "do not reach it" or "cannot tell"))
    for _, entry in ipairs(attacks) do
        local data = Core.Ask(C_Spell.GetSpellInfo, entry.spell)
        local answer = Core.Ask(C_Spell.IsSpellInRange, entry.spell, "target")
        ns.Print(("  %s (%s to %s yards): %s"):format(type(data) == "table" and Plain(data.name) or entry.spell,
            entry.least or 0, entry[1], tostring(answer)))
    end
end
Core.Command("range", "what the nameplates know of your target's distance and your attacks' reach", ns.Guard(Tell))

function Range.Start()
    ns.On("SPELLS_CHANGED", rebuild)
    Range.Rebuild()
end
