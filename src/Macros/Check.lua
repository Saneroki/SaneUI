local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros - Check
--  What would not work as it stands, found out of a fight, when a macro changes
--  or the character learns something. It says what can be known ahead: whether
--  a spell is ready at a given moment stays the game's to say on the press.
--
--  Check.Macro gives { macro = { words }, [step] = { words }, count }.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Check = {}
ns.Check = Check

Check.MOST_LETTERS = 255

local function Spell(step, out)
    local words = ns.TEXT.check
    local name = step.what
    if rawget(_G, "C_Spell") and C_Spell.DoesSpellExist and not Core.Ask(C_Spell.DoesSpellExist, name) then
        out[#out + 1] = words.noSpell
        return
    end
    local info = rawget(_G, "C_Spell") and C_Spell.GetSpellInfo and Core.Ask(C_Spell.GetSpellInfo, name)
    local known = rawget(_G, "C_SpellBook") and C_SpellBook.IsSpellKnown
    if type(info) == "table" and info.spellID and known and Core.Ask(known, info.spellID) == false then
        out[#out + 1] = words.notKnown
    end
end

local function Item(step, out)
    local words = ns.TEXT.check
    local items = rawget(_G, "C_Item")
    if not items then return end
    local wanted = step.id or step.what
    if not step.id and not Core.Ask(items.GetItemInfo, wanted) then
        out[#out + 1] = words.noItem
        return
    end
    if Core.Ask(items.GetItemCount, wanted, true) == 0 then out[#out + 1] = words.noneHeld end
end

-- Conditions that can never hold together.
local function Conditions(step, out)
    local words = ns.TEXT.check
    for first, one in ipairs(step.when) do
        for second = first + 1, #step.when do
            local other = step.when[second]
            if one.word == other.word and one.value == other.value and (one.no and true) ~= (other.no and true) then
                out[#out + 1] = words.contradiction:format(ns.Conditions.Words(one), (ns.Conditions.Words(other)))
            end
        end
        for _, apart in ipairs(ns.Conditions.APART) do
            for _, other in ipairs(step.when) do
                if one.word == apart[1] and other.word == apart[2] and not one.no and not other.no then
                    out[#out + 1] = words.contradiction:format(ns.Conditions.Words(one), (ns.Conditions.Words(other)))
                end
            end
        end
    end
end

-- The words between one line's brackets, each known to the game or told.
local function Brackets(line, out)
    local words = ns.TEXT.check
    local open, shut = select(2, line:gsub("%[", "")), select(2, line:gsub("%]", ""))
    if open ~= shut then out[#out + 1] = words.brackets:format(line) end
    for inner in line:gmatch("%[(.-)%]") do
        for word in inner:gmatch("[^,]+") do
            local trimmed = word:match("^%s*(.-)%s*$")
            local target = trimmed:sub(1, 1) == "@" or trimmed:lower():sub(1, 7) == "target="
            if trimmed ~= "" and not target and not ns.Conditions.WORDS[(ns.Conditions.Stem(trimmed))] then
                out[#out + 1] = words.unknownWord:format(trimmed)
            end
        end
    end
end

-- A clause with no condition ends a /cast line: what follows a ; after it is never picked.
local function Clauses(line, out)
    if not (line:match("^/cast%s") or line:match("^/use%s")) then return end
    local rest = line:gsub("^/%a+%s+", "")
    local open = false
    for clause in (rest .. ";"):gmatch("([^;]*);") do
        local trimmed = clause:match("^%s*(.-)%s*$")
        if open and trimmed ~= "" then
            out[#out + 1] = ns.TEXT.check.afterOpen:format(line)
            return
        end
        if trimmed:sub(1, 1) ~= "[" then open = true end
    end
end

local function Text(step, out)
    local words = ns.TEXT.check
    if #step.what > Check.MOST_LETTERS then out[#out + 1] = words.tooLong end
    local casts = 0
    for raw in step.what:gmatch("[^\n]+") do
        local line = raw:match("^%s*(.-)%s*$")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            if line:sub(1, 1) ~= "/" then
                out[#out + 1] = words.notCommand:format(line)
            else
                Brackets(line, out)
                Clauses(line, out)
                if line:match("^/cast%s") or line:match("^/use%s") then
                    casts = casts + 1
                    if casts == 2 then out[#out + 1] = words.secondCast:format(line) end
                end
            end
        end
    end
end

-- What is wrong with one step, as a list of words.
function Check.Step(step)
    local out = {}
    if step.what == "" then
        out[1] = ns.TEXT.check.empty
        return out
    end
    if step.kind == "spell" then
        Spell(step, out)
    elseif step.kind == "item" then
        Item(step, out)
    else
        Text(step, out)
    end
    Conditions(step, out)
    return out
end

function Check.Macro(macro)
    local found = { macro = {}, count = 0 }
    local words = ns.TEXT.check
    if not macro.steps[1] then found.macro[1] = words.noSteps end
    local live, ended = false, false
    for _, step in ipairs(macro.steps) do
        if not step.off then
            live = true
            local problems = Check.Step(step)
            if macro.top and ended then problems[#problems + 1] = words.unreachable end
            if ns.Write.When(step) == nil then ended = true end
            if problems[1] then
                found[step] = problems
                found.count = found.count + #problems
            end
        end
    end
    if macro.steps[1] and not live then found.macro[1] = words.allOff end
    found.count = found.count + #found.macro
    return found
end
