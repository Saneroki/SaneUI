local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Spell
--  A spell's or a pet ability's tooltip:
--
--      FIREBALL                        [icon]
--      Fire  ·  Rank 1                            what it is: its school, or Healing, CC,
--      ------------------------------------       Physical, Utility; the rank
--        MANA     |  RANGE  |   CAST              what its tooltip states, in the order the
--      30 (6%)    |  35 yd  |  1.5 sec            game writes it: cost, range, cast, cooldown
--        DPS   | DAMAGE | PER MANA |  CRIT         and for one that hurts or heals, what follows
--        8.4   |   21   |   0.68   |  6.2%        from it (Numbers.lua)
--      ------------------------------------
--      Hurls a fiery ball that causes 16 to       the description, its numbers in the
--      25 Fire damage ...                         panel's colour
--
--  A cell only for what is known: a spell whose tooltip states no cooldown has
--  no cooldown cell, and a strip with nothing in it is no strip. A weapon's
--  swing has its speed where a spell has what it does per point of its cost.
--  The panel's colour says what the spell is: its school's, green for one that
--  heals, blue for crowd control, the physical colour for one that hurts, none
--  for the rest.
-------------------------------------------------------------------------------
local Plain = SaneUI.Core.Plain
local Read, TEXT, FACTS, COLOR = ns.Reader, ns.TEXT, ns.FACTS, ns.COLOR
local TYPE = Enum.TooltipDataType or {}
local LINE = Enum.TooltipDataLineType or {}
local STATS = ns.STATS[GetLocale()]

local PASSIVE = LINE.SpellPassive or -1
local DETAIL = COLOR.DETAIL
local DETAIL_HEX = ns.Hex(DETAIL[1], DETAIL[2], DETAIL[3])

-- The schools a description can name, by the game's numbers of them (Texts.lua): the game's name
-- for each, and the colour its combat log gives each (COMBATLOG_DEFAULT_COLORS.schoolColoring,
-- which the game loads only with its combat log; so the numbers are here).
local SCHOOL_ART = {
    [2] = { "STRING_SCHOOL_HOLY", "Holy", 1.00, 0.90, 0.50 },
    [3] = { "STRING_SCHOOL_FIRE", "Fire", 1.00, 0.50, 0.00 },
    [4] = { "STRING_SCHOOL_NATURE", "Nature", 0.30, 1.00, 0.30 },
    [5] = { "STRING_SCHOOL_FROST", "Frost", 0.50, 1.00, 1.00 },
    [6] = { "STRING_SCHOOL_SHADOW", "Shadow", 0.50, 0.50, 1.00 },
    [7] = { "STRING_SCHOOL_ARCANE", "Arcane", 1.00, 0.50, 1.00 },
}
-- What a spell is: { name, r, g, b }; a school has real set.
local SCHOOL = {}
for index, art in pairs(SCHOOL_ART) do
    SCHOOL[index] = { ns.Global(art[1]) or art[2], art[3], art[4], art[5], real = true }
end
local HEALTH, CC = COLOR.HEALTH, ns.GameColor("LIGHTBLUE_FONT_COLOR", 0.53, 0.67, 1.00)
local HEALING = { TEXT.HEALING, HEALTH[1], HEALTH[2], HEALTH[3] }
local PHYSICAL = { ns.Global("STRING_SCHOOL_PHYSICAL") or TEXT.PHYSICAL, 1.00, 1.00, 0.00 } -- the combat log's physical
local CONTROL = { TEXT.CC, CC[1], CC[2], CC[3] }
local UTILITY = { TEXT.UTILITY } -- no colour of its own

-- What a spell is, from its description: the first school it names; else healing (or a shield),
-- crowd control (a stun, a fear, ...), physical (it hurts), or utility. Found once for each spell
-- and kept.
local known = {} -- [spell] = one of the above
local function School(id, description)
    local found = known[id]
    if found then return found end
    found = UTILITY
    if STATS and description then
        local lower, first = description:lower(), nil
        for index, word in pairs(STATS.schools) do
            local at = lower:find("%f[%a]" .. word .. "%f[%A]")
            if at and (not first or at < first) then first, found = at, SCHOOL[index] end
        end
        if not first then
            local healAt = lower:find(STATS.heals, 1, true) or lower:find("%f[%a]absorb")
            local damageAt = lower:find(STATS.damage, 1, true)
            local controls = false
            for _, word in ipairs(STATS.controls) do
                if lower:find(word) then controls = true end
            end
            if healAt and (not damageAt or healAt < damageAt) then found = HEALING
            elseif controls then found = CONTROL
            elseif damageAt then found = PHYSICAL end
        end
    end
    -- Not kept without a description: the game's spell data may still be on its way.
    if description then known[id] = found end
    return found
end

-- The facts, in the order the game's tooltip writes them: line by line, the left side first.
local ORDER = { "cost", "range", "cast", "cooldown" }
local CAPTION = { cost = TEXT.COST, range = TEXT.RANGE, cast = TEXT.CAST, cooldown = TEXT.COOLDOWN }
local MEMO = { cost = "factCost", range = "factRange", cast = "factCast", cooldown = "factCooldown" }
local facts = {} -- what the tooltip states, for one read: [key] = value; power = a cost's caption

-- The fact one side of a line states (Texts.lua, FACTS): its key and value, and for a cost its
-- power's name. Nil when it states none.
local function Fact(text)
    for index = 1, #FACTS do
        local fact = FACTS[index]
        local found = text:match(fact.pattern)
        if found then
            local value = fact.unit and Read.Memo(MEMO[fact.key], fact.unit, found) or found
            return fact.key, value, fact.caption
        end
    end
    return nil
end

-- A line of facts: each of its sides states one, or is empty. Notes them; false for any other line.
local function Facts(line)
    local left, right = line.left, line.right
    local leftKey, leftValue, leftPower, rightKey, rightValue, rightPower
    if left ~= "" then
        leftKey, leftValue, leftPower = Fact(left)
        if not leftKey then return false end
    end
    if right ~= "" then
        rightKey, rightValue, rightPower = Fact(right)
        if not rightKey then return false end
    end
    if not (leftKey or rightKey) then return false end
    if leftKey then facts[leftKey], facts.power = leftValue, leftPower or facts.power end
    if rightKey then facts[rightKey], facts.power = rightValue, rightPower or facts.power end
    return true
end

local function Spell(ctx)
    local L, head, id = ctx.L, ctx.head, ctx.id
    -- The lines before the description that state facts; what the description says.
    wipe(facts)
    local passive, description
    for index = 2, ctx.count do
        local line = L[index]
        if Read.IsProse(line) then
            description = description or line.left
        elseif line.type == PASSIVE and not passive then
            passive, line.used = line.left, true
        elseif not description and not line.blank and Facts(line) then
            line.used = true
        end
    end

    -- What it is, and what follows from its description (Numbers.lua); a weapon's swing: its speed
    Read.Title(true)
    local school = id and School(id, description) or UTILITY
    local numbers = id and ns.Numbers.Spell(id, description)
    if numbers and school == UTILITY then school = numbers.heal and HEALING or PHYSICAL end -- a swing
    if school[2] and (school.real or not passive) then
        Read.Accent(school[2], school[3], school[4])
        head.numbers = true
    end
    head.icon = ctx.options.icons and id and Plain(C_Spell.GetSpellTexture(id)) or nil

    -- Under the name: what it is, in its colour, and its rank
    local rank = L[1].right
    if rank == "" then rank = passive or "" end
    local hex = school[2] and ns.Hex(school[2], school[3], school[4]) or DETAIL_HEX
    if rank ~= "" then
        Read.Text("sub", Read.Memo("school", "|cff%s%s|r  \194\183  %s", hex, school[1], rank), DETAIL[1], DETAIL[2], DETAIL[3])
    else
        Read.Text("sub", Read.Memo("school", "|cff%s%s|r", hex, school[1]), DETAIL[1], DETAIL[2], DETAIL[3])
    end

    -- The facts it states; its cost also as a share of all your mana
    ctx.rule = true
    local strip
    for _, key in ipairs(ORDER) do
        local value = facts[key]
        if value then
            if not strip then
                strip = Read.Row()
                strip.kind = "strip"
            end
            local caption = CAPTION[key]
            if key == "cost" then
                caption = facts.power or caption
                local share = id and ns.Numbers.Share(id)
                if share then value = Read.Memo("cost", "%s (%d%%)", value, math.floor(share + 0.5)) end
            end
            Read.Cell(strip, caption, value)
        end
    end
    -- What follows: per second, on average, per point of its cost (a swing: its speed), critical strikes
    if numbers then
        local row = Read.Row()
        row.kind = "strip"
        Read.Cell(row, numbers.heal and TEXT.HPS or TEXT.DPS, Read.Memo("perSecond", "%.1f", numbers.perSecond))
        Read.Cell(row, numbers.heal and TEXT.HEALING or TEXT.DAMAGE, Read.Memo("amount", "%d", math.floor(numbers.amount + 0.5)))
        if numbers.speed then
            Read.Cell(row, TEXT.SPEED, Read.Memo("speed", "%.2f", numbers.speed))
        elseif numbers.perPower then
            Read.Cell(row, Read.Memo("per", TEXT.PER, numbers.power or facts.power or ns.Global("MANA") or TEXT.MANA),
                Read.Memo("perPower", numbers.perPower < 10 and "%.2f" or "%.1f", numbers.perPower))
        end
        if numbers.crit then Read.Cell(row, TEXT.CRIT, Read.Memo("crit", "%.1f%%", numbers.crit)) end
    end
    ctx.rule = true
    ctx.each = Read.Prose
    Read.Rest()
end

if TYPE.Spell then ns.KINDS[TYPE.Spell] = Spell end
if TYPE.PetAction then ns.KINDS[TYPE.PetAction] = Spell end
