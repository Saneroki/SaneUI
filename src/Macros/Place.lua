local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros - Place
--  Choosing a bar button with the mouse: for a moment a plain square lies over
--  every button of every bar that shows, also over the empty ones and bars at
--  rest, and the one clicked, or under the mouse when a drag ends, is the place.
--  Esc, a right click, closing the window or a fight ends it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Place = {}
ns.Place = Place

local squares = {}
Place.squares = squares
local wanted        -- what to do with the place chosen
local owner         -- what Esc goes by

local function Stop()
    wanted = nil
    for _, square in ipairs(squares) do square:Hide() end
    if owner then Core.Escape(owner, nil) end
end
Place.Stop = Stop

local function Choose(square)
    local chosen = wanted
    Stop()
    if chosen then chosen(square.place) end
end

local function Click(square, mouse)
    if mouse == "RightButton" then return Stop() end
    Choose(square)
end

local function Square(index)
    local square = squares[index]
    if square then return square end
    square = CreateFrame("Button", nil, UIParent)
    square:SetFrameStrata("FULLSCREEN_DIALOG")
    square:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local wash = square:CreateTexture(nil, "ARTWORK")
    wash:SetAllPoints()
    wash:SetColorTexture(0.95, 0.75, 0.2, 0.25)
    local lit = square:CreateTexture(nil, "HIGHLIGHT")
    lit:SetAllPoints()
    lit:SetColorTexture(1, 1, 1, 0.45)
    square:SetScript("OnClick", ns.Guard(Click))
    squares[index] = square
    return square
end

-- Squares over every button of the bars that show.
local function Lay()
    local index = 0
    local page = ns.Reach.Page()
    for _, bar in ipairs(ns.Reach.BARS) do
        for button = 1, ns.Reach.BUTTONS do
            local slot = rawget(_G, bar.prefix .. button)
            local parent = slot and slot:GetParent()
            if parent and Core.Plain(parent:IsVisible()) then
                index = index + 1
                local square = Square(index)
                square:ClearAllPoints()
                square:SetAllPoints(slot)
                square.place = ns.Reach.PlaceOf(bar, button, page)
                square:Show()
            end
        end
    end
    return index > 0
end

-- Begins choosing; done(place) once one is chosen. Out of a fight.
function Place.Start(done)
    if InCombatLockdown() then return ns.Print(ns.TEXT.noCombat) end
    Stop()
    if not Lay() then return end
    wanted = done
    owner = owner or CreateFrame("Frame")
    Core.Escape(owner, Stop)
end

-- A drag ended: the square under the mouse, if any.
function Place.Drop()
    if not wanted then return end
    for _, square in ipairs(squares) do
        if square:IsShown() and Core.Plain(square:IsMouseOver()) then return Choose(square) end
    end
    Stop()
end

ns.On("PLAYER_REGEN_DISABLED", Stop)
