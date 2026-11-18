local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Spacing
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
--
--  Bars snapped together touch too (Saneroki, 2026-11-02). Edit Mode's snapping
--  counts a padding of 2 around each box, so it leaves 4 between two bars, and a
--  bar's own lines have closed towards its middle. A bar snapped to another
--  keeps the anchor the game gave it and only its offset changes, so that the
--  buttons of both stand against each other. That goes through SetPointBase,
--  the frame's own SetPoint: Edit Mode's override of it writes the game's fields
--  and runs its manager, which our taint must not reach. The layout keeps the
--  game's numbers, so off, or standing down, the bar stands as the game has it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Spacing = {}
ns.Spacing = Spacing

-- The game's bars by their globals: the main bar, the extra bars, the stance, pet and possess bars.
Spacing.BARS = { "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
                 "MultiBar5", "MultiBar6", "MultiBar7", "StanceBar", "PetActionBar", "PossessActionBar" }

-- What the game does that can change where a bar's buttons or the bar itself stand. The last two come after it took
-- a place into the layout, or a layout's place onto the bar: the bar is moved after them, so the layout stays the game's.
local LAYS = { "UpdateGridLayout", "OnSystemPositionChange", "ApplySystemAnchor" }

local placed = {} -- [the game's bar] = how it stood when its buttons were last moved
local hooked = {} -- [the game's bar] = its hooks are placed (they stay)

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
-- one (ActionBarMixin:UpdateGridLayout). The padding, the stride, the longest line, how many lines.
local function Lines(bar, count)
    local stride = math.ceil(count / (bar.numRows or 1))
    return math.max(bar.minButtonPadding or 0, bar.buttonPadding or 0), stride, math.min(count, stride), math.ceil(count / stride)
end

-- A button that is on no line stands in its frame.
local function Close(bar)
    local frames, buttons = rawget(bar, "shownButtonContainers"), rawget(bar, "actionButtons")
    if type(frames) ~= "table" or type(buttons) ~= "table" or #frames == 0 then return end
    local count = #frames
    local padding, stride, long, lines = Lines(bar, count)
    local shape = Shape(bar, count, padding)
    if placed[bar] == shape then return end
    placed[bar] = shape

    local index = {}
    for at, frame in ipairs(frames) do index[frame] = at - 1 end
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

-- How far the closed buttons stand inside the bar's box at either end: left and right, then top and bottom. In the
-- bar's own scale: Edit Mode's icon size is the scale of the small frames, the padding is in theirs.
local function Insets(bar)
    local frames = rawget(bar, "shownButtonContainers")
    if type(frames) ~= "table" or #frames == 0 then return 0, 0 end
    local padding, _, long, lines = Lines(bar, #frames)
    local half = padding * frames[1]:GetScale() / 2
    if bar.isHorizontal then return (long - 1) * half, (lines - 1) * half end
    return (lines - 1) * half, (long - 1) * half
end

-- From the side of a box that an anchor point names, the way into the box on one axis: 1 from `low`, -1 from `high`.
local function Into(point, low, high)
    if point:find(low) then return 1 end
    if point:find(high) then return -1 end
end

-- The offset on one axis that lets the buttons of both bars meet. On an axis where the anchor names no side (a bar on
-- top of another, sideways) the bar stays where the game put it.
local function Meeting(given, way, inset, scale, wayTo, insetTo, scaleTo)
    if not way or not wayTo then return given end
    return (wayTo * insetTo * scaleTo - way * inset * scale) / scale
end

-- The layout's anchor of a bar snapped to another bar, and that bar. Nil for any other, for a bar in the game's own
-- place, and for one that does not stand at its anchor now: it is in the mouse's hands, or the layout has not taken it yet.
local function Snapped(bar)
    local system = rawget(bar, "systemInfo")
    local anchor = type(system) == "table" and system.anchorInfo
    if type(anchor) ~= "table" or system.anchorInfo2 or system.isInDefaultPosition then return end
    local other = rawget(_G, anchor.relativeTo)
    local point, to, relative = bar:GetPoint(1)
    if hooked[other] and to == other and point == anchor.point and relative == anchor.relativePoint
        and type(bar.SetPointBase) == "function" then
        return anchor, other
    end
end

local function Stand(bar, touching)
    local anchor, other = Snapped(bar)
    if not anchor then return end
    local scale = bar:GetScale()
    local x, y = anchor.offsetX / scale, anchor.offsetY / scale
    if touching then
        local scaleTo = other:GetScale()
        local insetX, insetY = Insets(bar)
        local insetToX, insetToY = Insets(other)
        x = Meeting(x, Into(anchor.point, "LEFT", "RIGHT"), insetX, scale,
            Into(anchor.relativePoint, "LEFT", "RIGHT"), insetToX, scaleTo)
        y = Meeting(y, Into(anchor.point, "BOTTOM", "TOP"), insetY, scale,
            Into(anchor.relativePoint, "BOTTOM", "TOP"), insetToY, scaleTo)
    end
    local _, _, _, nowX, nowY = bar:GetPoint(1)
    if math.abs(nowX - x) + math.abs(nowY - y) > 0.01 then
        bar:SetPointBase(anchor.point, other, anchor.relativePoint, x, y)
    end
end

local Laid -- set below

local function Apply()
    local want = not ns.off and ns.options.tightBars
    for _, name in ipairs(Spacing.BARS) do
        local bar = rawget(_G, name)
        if type(bar) == "table" then
            if not hooked[bar] and type(bar.UpdateGridLayout) == "function" then
                hooked[bar] = true
                for _, step in ipairs(LAYS) do
                    if type(bar[step]) == "function" then hooksecurefunc(bar, step, Laid) end
                end
            end
            if want then Close(bar) else Open(bar) end
        end
    end
    for bar in pairs(hooked) do Stand(bar, want) end
end

-- As the switch says, and the module not stood down; in a fight, once it is over.
function Spacing.Apply()
    Core.AfterCombat("Abilities: spacing", Apply)
end

Laid = ns.Guard(Spacing.Apply)
