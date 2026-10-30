local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Spell
--  A spell's or a pet ability's tooltip:
--
--      REVENGE                         [icon]
--      Physical  ·  Rank 1                        what it is: its school, or Healing, CC,
--      Requires Defensive Stance                  Physical, Utility; the rank. What it asks of
--      ─────────────── INFO ───────────────       you, each in a row of its own: a stance, a
--         DMG   |   RAGE   |  CAST   | RANGE      form, a weapon, reagents, tools
--          22   |    5     | Instant | Melee      a table of four columns: what one cast does,
--         DPS   | PER RAGE |   CD    | CRIT       its cost, its cast, its range; per second,
--         4.4   |   4.40   |  5 sec  | 2.0%       per point of its cost, its cooldown, your
--                                                 chance of a critical strike (or, for one that
--      Instantly counterattacks an enemy for      lasts, how long); "---" for what is not known
--      22 damage ...                              (Numbers.lua). Then, a little apart, the
--                                                 description, its numbers in the panel's colour;
--                                                 any other line of the game's under Details
--                                                 (Read.Named)
--
--  A spell that neither hurts nor heals has one row: its cost, cast, cooldown
--  and range, and none where its tooltip states none of them. A weapon's
--  swing has its speed where a spell has its cast. The panel's colour says what
--  the spell is: its school's, green for one that heals, blue for crowd
--  control, red for a physical one, none for the rest.
-------------------------------------------------------------------------------
local Plain, Ask = SaneUI.Core.Plain, SaneUI.Core.Ask
local Read, TEXT, FACTS, COLOR, PATTERN, LINES = ns.Reader, ns.TEXT, ns.FACTS, ns.COLOR, ns.PATTERN, ns.LINES
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
-- Physical in red, the game's red (its combat log has it yellow, too close to holy)
local PHYSICAL = { ns.Global("STRING_SCHOOL_PHYSICAL") or TEXT.PHYSICAL, COLOR.RED[1], COLOR.RED[2], COLOR.RED[3] }
local CONTROL = { TEXT.CC, CC[1], CC[2], CC[3] }
local UTILITY = { TEXT.UTILITY } -- no colour of its own

-- What a spell is, from its description: the first school it names; else healing (or a shield),
-- crowd control (a stun, a fear, ...), physical (it hurts), or utility. Found once for each spell
-- and kept, for at most HELD spells: then they are forgotten together.
local HELD = 400
local known, knownCount = {}, 0 -- [spell] = one of the above
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
    if description then
        if knownCount >= HELD then
            wipe(known)
            knownCount = 0
        end
        known[id], knownCount = found, knownCount + 1
    end
    return found
end

local MEMO = { cost = "factCost", range = "factRange", cast = "factCast", cooldown = "factCooldown" }
local facts = {} -- what the tooltip states, for one read: [key] = value; power = a cost's caption

-- The fact one side of a line states (Texts.lua, FACTS): its key and value, and for a cost its
-- power's name. Nil when it states none.
local function Fact(text)
    for index = 1, #FACTS do
        local fact = FACTS[index]
        local found = text:match(fact.pattern)
        if found then
            local value = fact.shown or fact.unit and Read.Memo(MEMO[fact.key], fact.unit, found) or found
            if fact.key == "range" then value = SaneUI.Core.DistanceText(value) end
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

-- Whether a line says what the spell asks of you: a stance, a form, a weapon (the game's sentences for
-- them), its reagents or its tools.
local function Requirement(text)
    if text:find(LINES.REAGENTS, 1, true) == 1 or text:find(LINES.TOOLS, 1, true) == 1 then return true end
    for _, pattern in ipairs(PATTERN.SPELL_REQUIRES) do
        if text:match(pattern) then return true end
    end
    return false
end
local asks = {} -- the lines that do, for one read

-- The name of your own power ("Rage"), where a spell states no cost to name it by.
local function YourPower()
    local _, token = Ask(UnitPowerType, "player")
    return type(token) == "string" and ns.Global(token) or TEXT.MANA
end

-- A cell of the table: its caption over its value, "---" where the value is not known.
local function Cell(row, caption, value)
    Read.Cell(row, caption, value or TEXT.NONE)
end

local function Spell(ctx)
    local L, head, id = ctx.L, ctx.head, ctx.id
    -- The lines before the description that state facts or what it asks of you; what the description says.
    wipe(facts)
    wipe(asks)
    local passive, description
    for index = 2, ctx.count do
        local line = L[index]
        if Read.IsProse(line) then
            description = description or line.left
        elseif line.type == PASSIVE and not passive then
            passive, line.used = line.left, true
        elseif not description and not line.blank and Facts(line) then
            line.used = true
        elseif not line.blank and line.right == "" and not Read.Added(line, index) and Requirement(line.left) then
            asks[#asks + 1], line.used = line, true
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
    if head.icon then ns.Figures.Spell(head, id) end -- a mount's, in the icon's place

    -- Under the name: what it is, in its colour, and its rank; under that what it asks of you, each in a
    -- row of its own, red where the game has it red (you do not have it now)
    local rank = L[1].right
    if rank == "" then rank = passive or "" end
    local hex = school[2] and ns.Hex(school[2], school[3], school[4]) or DETAIL_HEX
    if rank ~= "" then
        Read.Text("sub", Read.Memo("school", "|cff%s%s|r  \194\183  %s", hex, school[1], rank), DETAIL[1], DETAIL[2], DETAIL[3])
    else
        Read.Text("sub", Read.Memo("school", "|cff%s%s|r", hex, school[1]), DETAIL[1], DETAIL[2], DETAIL[3])
    end
    for _, line in ipairs(asks) do
        local color = ns.Like(line.lr, line.lg, line.lb, COLOR.RED) and COLOR.RED or DETAIL
        Read.Text("sub", line.left, color[1], color[2], color[3])
    end

    -- Its cost, also as a share of all your mana
    local power = facts.power or (numbers and numbers.power) or YourPower()
    local cost = facts.cost
    if cost then
        local share = id and ns.Numbers.Share(id)
        if share then cost = Read.Memo("cost", "%s (%d%%)", cost, math.floor(share + 0.5)) end
    end
    -- The table, in the section Info. A spell that hurts or heals: what one cast does, its cost, its cast
    -- (a swing: its speed), its range; per second, per point of its cost, its cooldown, your chance of a
    -- critical strike (one that lasts: how long). Any other: its cost, cast, cooldown and range.
    if numbers then
        Read.Section(TEXT.INFO)
        local first = Read.Row()
        first.kind = "strip"
        Cell(first, numbers.heal and TEXT.HEAL or TEXT.HIT, Read.Memo("amount", "%d", math.floor(numbers.amount + 0.5)))
        Cell(first, power, cost)
        if numbers.speed then
            Cell(first, TEXT.SPEED, Read.Memo("speed", "%.2f", numbers.speed))
        else
            Cell(first, TEXT.CAST, facts.cast)
        end
        Cell(first, TEXT.RANGE, facts.range)
        local second = Read.Row()
        second.kind = "strip"
        Cell(second, numbers.heal and TEXT.HPS or TEXT.DPS, Read.Memo("perSecond", "%.1f", numbers.perSecond))
        Cell(second, Read.Memo("per", TEXT.PER, power), numbers.perPower
            and Read.Memo("perPower", numbers.perPower < 10 and "%.2f" or "%.1f", numbers.perPower))
        Cell(second, TEXT.CD, facts.cooldown)
        if numbers.lasting then
            Cell(second, TEXT.DURATION, Read.Memo("lasting", TEXT.SECONDS, numbers.lasting))
        else
            Cell(second, TEXT.CRIT, numbers.crit and Read.Memo("crit", "%.1f%%", numbers.crit))
        end
    elseif facts.cost or facts.cast or facts.cooldown or facts.range then
        Read.Section(TEXT.INFO)
        local row = Read.Row()
        row.kind = "strip"
        Cell(row, power, cost)
        Cell(row, TEXT.CAST, facts.cast)
        Cell(row, TEXT.CD, facts.cooldown)
        Cell(row, TEXT.RANGE, facts.range)
    end
    -- The description, a little apart from the table
    ctx.gap = true
    ctx.each = Read.Prose
    Read.Rest()
end

if TYPE.Spell then ns.KINDS[TYPE.Spell] = Spell end
if TYPE.PetAction then ns.KINDS[TYPE.PetAction] = Spell end
