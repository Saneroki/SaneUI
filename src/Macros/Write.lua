local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros - Write
--  A macro written out into what one press may do: a list of turns, each with
--  its macro line and the condition that lets it run. Plain text, nothing here
--  knows a frame, and only out of a fight does it reach a button (Press.lua).
--
--  How often a step comes up: every turn of a step gets a mark on one round,
--  half a share in from its start (a step that comes up twice stands at a
--  quarter and three quarters), and the marks are read in order. So the steps
--  stay spread out whatever the numbers are.
-------------------------------------------------------------------------------
local Write = {}
ns.Write = Write

-- The words between a step's brackets: who it is for, then its conditions. "" when there are none.
function Write.Words(step)
    local words = {}
    if step.unit then words[1] = "@" .. step.unit end
    for _, condition in ipairs(step.when) do words[#words + 1] = ns.Conditions.Text(condition) end
    return table.concat(words, ",")
end

-- The step as a line of a macro.
function Write.Line(step)
    if step.kind == "text" then return step.what end
    local words = Write.Words(step)
    local bracket = words ~= "" and "[" .. words .. "] " or ""
    if step.kind == "item" then
        return "/use " .. bracket .. (step.id and "item:" .. step.id or step.what)
    end
    return "/cast " .. bracket .. step.what
end

-- What the press asks the game before it takes the step; nil: nothing to ask.
function Write.When(step)
    if not step.when[1] and (step.kind ~= "text" or not step.unit) then return nil end
    local words = Write.Words(step)
    return words ~= "" and "[" .. words .. "] 1" or nil
end

-- Whether a step has anything to do.
local function Ready(step)
    return not step.off and step.what ~= ""
end

local function Turn(step)
    return { line = Write.Line(step), when = Write.When(step), step = step }
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
    for index, mark in ipairs(marks) do turns[index] = Turn(mark.step) end
    return turns
end
