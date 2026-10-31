local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Spacing
--  The buttons of every action bar touch (Saneroki, 2026-10-31): no space
--  between the icons, side by side or between the rows of a bar.
--
--  Edit Mode's Icon Padding stops at 2. A bar of the game's lays out one small
--  frame for each button, and the button sits in the middle of its frame. That
--  layout stays the game's: each button only moves out of the middle of its
--  frame, towards the middle of the bar, by as much as the padding keeps it
--  away. So the bar keeps its place and its size, in Edit Mode too, and all
--  that hangs on the button goes with it: its key, cooldown and tooltip, the
--  grey icon of a reservation, the clean look.
--
--  A button moves out of a fight only, and asks again when the game lays its
--  bar out anew (Edit Mode's orientation, rows, padding). Off, or standing
--  down, each button is back in the middle of its frame.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Spacing = {}
ns.Spacing = Spacing

-- The game's bars by their globals: the main bar, the extra bars, the stance, pet and possess bars.
Spacing.BARS = { "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
                 "MultiBar5", "MultiBar6", "MultiBar7", "StanceBar", "PetActionBar", "PossessActionBar" }

local placed = {} -- [the game's bar] = how it stood when its buttons were last moved
local hooked = {} -- [the game's bar] = its hook is placed (it stays)

-- A bar as the game lays it out, as one line: what the buttons' places depend on.
local function Shape(bar, count, padding)
    return ("%d %d %s %s %s %s"):format(count, bar.numRows or 1, tostring(padding), tostring(bar.isHorizontal),
        tostring(bar.addButtonsToRight), tostring(bar.addButtonsToTop))
end

local function Put(button, x, y)
    button:ClearAllPoints()
    button:SetPoint("CENTER", button.container, "CENTER", x, y)
end

-- How far the button at place (from 0) of a line of that many must move to close its padding, towards the middle.
local function Inwards(place, many, padding)
    return ((many - 1) / 2 - place) * padding
end

-- The game fills a line of `stride` buttons, then the next line: rows on a horizontal bar, columns on a vertical
-- one (ActionBarMixin:UpdateGridLayout). A button that is on no line stands in its frame.
local function Close(bar)
    local frames, buttons = rawget(bar, "shownButtonContainers"), rawget(bar, "actionButtons")
    if type(frames) ~= "table" or type(buttons) ~= "table" or #frames == 0 then return end
    local count = #frames
    local padding = math.max(bar.minButtonPadding or 0, bar.buttonPadding or 0)
    local shape = Shape(bar, count, padding)
    if placed[bar] == shape then return end
    placed[bar] = shape

    local index = {}
    for at, frame in ipairs(frames) do index[frame] = at - 1 end
    local stride = math.ceil(count / (bar.numRows or 1))
    local long, lines = math.min(count, stride), math.ceil(count / stride)
    local right, up = bar.addButtonsToRight and 1 or -1, bar.addButtonsToTop and 1 or -1
    for _, button in ipairs(buttons) do
        local at = index[button.container]
        if at then
            local along = Inwards(at % stride, long, padding)
            local across = Inwards(math.floor(at / stride), lines, padding)
            if bar.isHorizontal then
                Put(button, along * right, across * up)
            else
                Put(button, across * right, along * up)
            end
        else
            Put(button, 0, 0)
        end
    end
end

local function Open(bar)
    if not placed[bar] then return end
    placed[bar] = nil
    for _, button in ipairs(rawget(bar, "actionButtons") or {}) do Put(button, 0, 0) end
end

local Laid -- set below

local function Apply()
    local want = not ns.off and ns.options.tightBars
    for _, name in ipairs(Spacing.BARS) do
        local bar = rawget(_G, name)
        if type(bar) == "table" then
            if not hooked[bar] and type(bar.UpdateGridLayout) == "function" then
                hooked[bar] = true
                hooksecurefunc(bar, "UpdateGridLayout", Laid)
            end
            if want then Close(bar) else Open(bar) end
        end
    end
end

-- As the switch says, and the module not stood down; in a fight, once it is over.
function Spacing.Apply()
    Core.AfterCombat("Abilities: spacing", Apply)
end

Laid = ns.Guard(Spacing.Apply)
