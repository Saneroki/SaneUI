local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Buttons
--  Every action button there is, and where it stands on the screen.
--
--  The buttons are found by what they are, not by their names: a button that
--  carries an action slot (ns.ActionOf). That is the game's own, and any a bar
--  addon makes for itself. Looked for once and kept; looked for again when a drag starts, so a
--  bar made or rebuilt since is known then.
--
--  A bar may hide its empty buttons ("always show buttons" off). The game then
--  does not always keep a hidden frame's place up to date, so Rect works it out
--  from the button's first anchor when the frame itself has none to give.
-------------------------------------------------------------------------------
local Buttons = {}
ns.Buttons = Buttons

local list -- the buttons found, once there has been a search

local KINDS = { Button = true, CheckButton = true }

local function IsButton(frame)
    local ok, yes = pcall(function()
        if frame.IsForbidden and frame:IsForbidden() then return false end
        return KINDS[frame:GetObjectType()] and ns.ActionOf(frame) ~= nil
    end)
    return ok and yes or false
end

-- Where there is no way to walk every frame: the game's buttons by name.
local function ByName(found)
    for _, bar in ipairs(ns.BARS) do
        for i = 1, ns.NUM_BUTTONS do found[#found + 1] = _G[bar.prefix .. i] end
    end
end

-- fresh: look again (a drag starts); otherwise the buttons found last time.
function Buttons.All(fresh)
    if list and not fresh then return list end
    local found = {}
    if EnumerateFrames then
        local frame = EnumerateFrames()
        while frame do
            if IsButton(frame) then found[#found + 1] = frame end
            frame = EnumerateFrames(frame)
        end
    else
        ByName(found)
    end
    list = found
    return list
end

-- Where a frame's anchor point sits on it: 0 to 1 across, 0 to 1 up.
local POINT = {
    TOPLEFT = { 0, 1 }, TOP = { 0.5, 1 }, TOPRIGHT = { 1, 1 },
    LEFT = { 0, 0.5 }, CENTER = { 0.5, 0.5 }, RIGHT = { 1, 0.5 },
    BOTTOMLEFT = { 0, 0 }, BOTTOM = { 0.5, 0 }, BOTTOMRIGHT = { 1, 0 },
}

local function Plain(...)
    local out = { ... }
    for index = 1, select("#", ...) do
        out[index] = ns.Plain(out[index])
        if type(out[index]) ~= "number" then return nil end
    end
    return unpack(out, 1, select("#", ...))
end

-- The frame's place on the screen in screen pixels (the measure of GetCursorPosition):
-- left, bottom, width, height; nil when it cannot be told.
local function Rect(frame, depth)
    local scale = Plain(frame:GetEffectiveScale())
    if not scale then return nil end
    local left, bottom, width, height = Plain(frame:GetRect())
    if left and width > 0 and height > 0 then
        return left * scale, bottom * scale, width * scale, height * scale
    end
    -- No place of its own: from its first anchor, the frame it hangs on, and its size.
    if depth > 4 or (frame:GetNumPoints() or 0) < 1 then return nil end
    width, height = Plain(frame:GetWidth(), frame:GetHeight())
    if not width or width <= 0 or height <= 0 then return nil end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    relativeTo = relativeTo or frame:GetParent()
    local mine, theirs = POINT[point], POINT[relativePoint or point]
    if not (relativeTo and mine and theirs) then return nil end
    local rl, rb, rw, rh = Rect(relativeTo, depth + 1)
    if not rl then return nil end
    local ax = rl + theirs[1] * rw + (Plain(x) or 0) * scale
    local ay = rb + theirs[2] * rh + (Plain(y) or 0) * scale
    return ax - mine[1] * width * scale, ay - mine[2] * height * scale, width * scale, height * scale
end

function Buttons.Rect(frame)
    local ok, left, bottom, width, height = pcall(Rect, frame, 0)
    if ok and left then return left, bottom, width, height end
    return nil
end

-- Is the mouse over this button? A shown one is asked; a hidden one is measured by its place.
function Buttons.Under(button)
    if ns.Plain(button:IsVisible()) then return ns.Plain(button:IsMouseOver()) and true or false end
    local left, bottom, width, height = Buttons.Rect(button)
    if not left then return false end
    local x, y = GetCursorPosition()
    return x >= left and x <= left + width and y >= bottom and y <= bottom + height
end

-- A bar you can see: the button's parent is on show (a bar addon hides the game's own bars
-- by giving their buttons a hidden parent).
function Buttons.OnVisibleBar(button)
    local bar = button:GetParent()
    return not bar or ns.Plain(bar:IsVisible()) and true or false
end
