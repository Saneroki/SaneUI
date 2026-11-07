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
--  Once per target: the game's own cast sequence (CastSequenceManager.lua) goes
--  on to its next name only when the cast went off, and starts over when the
--  target changes or the fight ends, in a fight too. So the step is written as
--  "/castsequence reset=target/combat Rend, null": Rend, then a name the game
--  casts nothing for (no global cooldown, no rage) until it starts over. Only in
--  a sequence: from the top every press would stop at it (Check.lua says so).
-------------------------------------------------------------------------------
local Write = {}
Macros.Write = Write

Write.RESET = "reset=target/combat" -- when the game's cast sequence starts over
Write.REST = "null"                 -- a name the game casts nothing for: the sequence waits on it

-- The step's conditions the game judges: Sane Macros' own (Once per target) never stand between the brackets.
local function Game(step)
    local list = {}
    for _, condition in ipairs(step.when) do
        if not Macros.Conditions.OURS[condition.word] then list[#list + 1] = condition end
    end
    return list
end

-- Whether the step carries Once per target, whatever its kind.
function Write.Marked(step)
    for _, condition in ipairs(step.when) do
        if condition.word == "once" then return true end
    end
    return false
end

-- Whether the step is cast once a target: a spell's or an item's, marked so, in a sequence (top: from the top).
function Write.Once(step, top)
    return not top and step.kind ~= "text" and Write.Marked(step)
end

-- The words between a step's brackets: who it is for, then its conditions. "" when there are none.
function Write.Words(step)
    local words = {}
    if step.unit then words[1] = "@" .. step.unit end
    for _, condition in ipairs(Game(step)) do words[#words + 1] = Macros.Conditions.Text(condition) end
    return table.concat(words, ",")
end

-- A step's spell or item as the game's commands name it.
local function Thing(step)
    if step.kind == "item" then return step.id and "item:" .. step.id or step.what end
    return step.what
end

-- The game's cast sequence of a step cast once a target, as the game keeps it (without the brackets).
function Write.Sequence(step)
    return Write.RESET .. " " .. Thing(step) .. ", " .. Write.REST
end

-- The step as a line of a macro; top: the macro starts at the top on every press.
function Write.Line(step, top)
    if step.kind == "text" then return step.what end
    local words = Write.Words(step)
    local bracket = words ~= "" and "[" .. words .. "] " or ""
    if Write.Once(step, top) then return "/castsequence " .. bracket .. Write.Sequence(step) end
    return (step.kind == "item" and "/use " or "/cast ") .. bracket .. Thing(step)
end

-- What the press asks the game before it takes the step; nil: nothing to ask.
function Write.When(step)
    if not Game(step)[1] and (step.kind ~= "text" or not step.unit) then return nil end
    local words = Write.Words(step)
    return words ~= "" and "[" .. words .. "] 1" or nil
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
