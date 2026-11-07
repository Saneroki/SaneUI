local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Write
--  A macro written out into what one press may do: a list of turns, each with
--  its macro line and the condition that lets it run. Plain text, nothing here
--  knows a frame, and only out of a fight does it reach a button (Press.lua).
--
--  How often a step comes up: every turn of a step gets a mark on one round,
--  half a share in from its start (a step that comes up twice stands at a
--  quarter and three quarters), and the marks are read in order. So the steps
--  stay spread out whatever the numbers are.
--
--  The cast sequence conditions (Once per target, Once per fight, again at a new
--  target, with Shift, Ctrl or Alt, after a pause): the game's own cast sequence
--  (CastSequenceManager.lua) goes on to its next name only when the cast went off,
--  and starts over at what its reset names, in a fight too: target
--  (PLAYER_TARGET_CHANGED), combat (PLAYER_REGEN_ENABLED), shift, ctrl or alt held
--  as it is pressed, a number of seconds since it was last pressed; and at death.
--  So the step is written as "/castsequence reset=target/combat Rend, null": Rend,
--  then a name the game casts nothing for (no global cooldown, no rage) until it
--  starts over. Only in a sequence: from the top every press would stop at it
--  (Check.lua says so).
--
--  Cast on, several in order (Saneroki, 2026-11-07: "if we have @mouseover as 1
--  and @Target as 2 fx it will try to cast it on mouseover first and if it
--  doesn't have that condition it will do it on the target"): a bracket a unit,
--  "[@mouseover,exists,harm][@target]". Each but the last asks that its unit be
--  there and, for a spell or item the game calls harmful or helpful, be a foe or
--  a friend, so the game goes on to the next; the last takes it as it is. The
--  step's own conditions stand in every bracket.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Write = {}
Macros.Write = Write

Write.RESETS = { "target", "combat", "shift", "ctrl", "alt" } -- the game's words for a cast sequence's resets
Write.REST = "null" -- a name the game casts nothing for: the sequence waits on it

-- The step's conditions the game judges: Sane Macros' own (Once per target) never stand between the brackets.
local function Game(step)
    local list = {}
    for _, condition in ipairs(step.when) do
        if not Macros.Conditions.OURS[condition.word] then list[#list + 1] = condition end
    end
    return list
end

-- The resets the step's cast sequence conditions ask for, in the game's words ("target/combat/10"; "" for none of
-- them, death alone); nil where the step carries none of those conditions.
function Write.Resets(step)
    local wanted, seconds, marked = {}, nil, false
    for _, condition in ipairs(step.when) do
        local word = condition.word
        local kind = word:match("^reset:(%a+)$")
        if word == "once" then
            wanted.target, wanted.combat, marked = true, true, true
        elseif word == "reset" then
            seconds, marked = tonumber(condition.value), true
        elseif kind and Macros.Conditions.OURS[word] then
            wanted[kind], marked = true, true
        end
    end
    if not marked then return nil end
    local parts = {}
    for _, kind in ipairs(Write.RESETS) do
        if wanted[kind] then parts[#parts + 1] = kind end
    end
    if seconds and seconds > 0 then parts[#parts + 1] = tostring(math.floor(seconds)) end
    return table.concat(parts, "/")
end

-- Whether the step carries a cast sequence condition, whatever its kind.
function Write.Marked(step)
    return Write.Resets(step) ~= nil
end

-- Whether the step is a cast sequence: a spell's or an item's, with such a condition, in a sequence (top: from the top).
function Write.Once(step, top)
    return not top and step.kind ~= "text" and Write.Marked(step)
end

-- Who the step is cast on, in order ("": your target, as the game takes it); none: your target. A step as saved holds
-- units (Book), one another code made may still hold its unit alone.
function Write.Units(step)
    if type(step.units) == "table" and step.units[1] then return step.units end
    if type(step.unit) == "string" then return { step.unit } end
    return {}
end

-- Whether the game calls the step's spell or item harmful ("harm") or helpful ("help"); nil where it says neither.
function Write.Side(step)
    local thing = step.id or step.what
    local harmful, helpful
    if step.kind == "spell" then
        local spells = rawget(_G, "C_Spell")
        harmful = spells and Core.Ask(spells.IsSpellHarmful, thing)
        helpful = spells and Core.Ask(spells.IsSpellHelpful, thing)
    elseif step.kind == "item" then
        local items = rawget(_G, "C_Item")
        harmful = items and Core.Ask(items.IsHarmfulItem, thing)
        helpful = items and Core.Ask(items.IsHelpfulItem, thing)
    end
    if harmful == true then return "harm" end
    if helpful == true then return "help" end
    return nil
end

-- The words of each of the step's brackets, one a unit in its order; { "" } where there is nothing to say.
function Write.Clauses(step)
    local game, units = {}, Write.Units(step)
    for _, condition in ipairs(Game(step)) do game[#game + 1] = Macros.Conditions.Text(condition) end
    if not units[1] then return { table.concat(game, ",") } end
    local clauses, side = {}, nil
    for index, unit in ipairs(units) do
        local words = {}
        if unit ~= "" then words[1] = "@" .. unit end
        if index < #units and unit ~= "cursor" then -- the place under the mouse is always there
            words[#words + 1] = "exists"
            if side == nil then side = Write.Side(step) or false end
            if side then words[#words + 1] = side end
        end
        for _, word in ipairs(game) do words[#words + 1] = word end
        clauses[index] = table.concat(words, ",")
    end
    return clauses
end

-- The step's brackets as a line holds them, with a space after: "[@mouseover,exists][] "; "" with nothing to say.
function Write.Bracket(step)
    local clauses = Write.Clauses(step)
    if #clauses == 1 and clauses[1] == "" then return "" end
    return "[" .. table.concat(clauses, "][") .. "] "
end

-- A step's spell or item as the game's commands name it.
local function Thing(step)
    if step.kind == "item" then return step.id and "item:" .. step.id or step.what end
    return step.what
end

-- The game's cast sequence of a step with cast sequence conditions, as the game keeps it (without the brackets).
function Write.Sequence(step)
    local resets = Write.Resets(step) or ""
    return (resets ~= "" and "reset=" .. resets .. " " or "") .. Thing(step) .. ", " .. Write.REST
end

-- The step as a line of a macro; top: the macro starts at the top on every press.
function Write.Line(step, top)
    if step.kind == "text" then return step.what end
    local bracket = Write.Bracket(step)
    if Write.Once(step, top) then return "/castsequence " .. bracket .. Write.Sequence(step) end
    return (step.kind == "item" and "/use " or "/cast ") .. bracket .. Thing(step)
end

-- What the press asks the game before it takes the step; nil: nothing to ask. Without a condition of the game's a
-- spell's or an item's step is always taken: its last unit takes it whoever is there.
function Write.When(step)
    if not Game(step)[1] and (step.kind ~= "text" or not Write.Units(step)[1]) then return nil end
    local bracket = Write.Bracket(step)
    return bracket ~= "" and bracket .. "1" or nil
end

-- Whether a step has anything to do.
local function Ready(step)
    return not step.off and step.what ~= ""
end

-- A turn: its line, its condition, its step; sequence, where the game's cast sequence holds it (Press.Waits).
local function Turn(step, top)
    local sequence = Write.Once(step, top) and Write.Sequence(step) or nil
    return { line = Write.Line(step, top), when = Write.When(step), step = step, sequence = sequence }
end

-- The turns of a macro, in the order presses take them.
function Write.Turns(macro)
    local turns, marks = {}, {}
    for order, step in ipairs(macro.steps) do
        if Ready(step) then
            local count = macro.top and 1 or step.often
            for turn = 1, count do
                marks[#marks + 1] = { at = (turn - 0.5) / count, order = order, step = step }
            end
        end
    end
    if not macro.top then
        table.sort(marks, function(a, b)
            if a.at ~= b.at then return a.at < b.at end
            return a.order < b.order
        end)
    end
    for index, mark in ipairs(marks) do turns[index] = Turn(mark.step, macro.top) end
    return turns
end
