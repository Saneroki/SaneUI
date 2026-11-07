local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Picker
--  The list behind the + button: the game's conditions by group, each with its
--  explanation. The same list serves a step's conditions and macro text. A
--  condition that needs a word more asks for it: a number from a short list, a
--  spell's or an item's name in a box.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Picker = {}
Macros.Picker = Picker

Picker.NUMBERS = { stance = { 0, 1, 2, 3, 4, 5, 6 }, spec = { 1, 2, 3, 4 }, bar = { 1, 2, 3, 4, 5, 6 },
                   reset = { 3, 5, 10, 15, 20, 30, 60 } } -- reset: the cast sequence's pause, in seconds

-- A number from a short list, as a menu under the line.
local function Numbers(line, item, chosen)
    for _, number in ipairs(Picker.NUMBERS[item.word] or { 1, 2, 3 }) do
        line:CreateButton(tostring(number), ns.Guard(function() chosen(item.word, tostring(number)) end))
    end
end

-- A word in a box, once the line is clicked.
local function Ask(item, chosen)
    Core.AskText(Macros.TEXT.whenAsk, item.on, nil, nil, function(text)
        local value = text and text:match("^%s*(.-)%s*$")
        if value and value ~= "" then chosen(item.word, value) end
    end)
end

local function Line(group, item, chosen)
    local line
    if item.ask == "number" then
        line = group:CreateButton(item.on)
        Numbers(line, item, chosen)
    elseif item.ask then
        line = group:CreateButton(item.on, ns.Guard(function() Ask(item, chosen) end))
    else
        line = group:CreateButton(item.on, ns.Guard(function() chosen(item.word) end))
    end
    line:SetTooltip(ns.Guard(function(tooltip)
        GameTooltip_SetTitle(tooltip, item.on)
        GameTooltip_AddNormalLine(tooltip, item.tip)
    end))
end

-- Opens the list at owner; chosen(word, value) with what was picked. ours: Sane Macros' own words too (Once per
-- target), for a spell's or an item's step; never in macro text, which goes to the game as written.
function Picker.Open(owner, chosen, ours)
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        root:CreateTitle(Macros.TEXT.whenAdd)
        for _, group in ipairs(Macros.Conditions.Groups(ours)) do
            local line = root:CreateButton(group.name)
            for _, item in ipairs(group.items) do Line(line, item, chosen) end
        end
    end))
end
