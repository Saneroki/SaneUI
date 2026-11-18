local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Macros - Place
--  Choosing a bar button with the mouse: for a moment an unseen square lies over
--  every button of every bar that shows, also over the empty ones and bars at
--  rest, so a click there casts nothing; the one clicked, or under the mouse when
--  a drag ends, is the place. The bars stay as clear as ever (Saneroki,
--  2026-11-04: the gold wash over every button hid them): the macro's picture
--  follows the mouse, and only the button under it gets a gold frame, as a spell
--  carried from the spellbook does. Esc, a right click, closing the window or a
--  fight ends it.
--
--  The button under the mouse is read from the frames the game says are under it
--  (GetMouseFoci), and only then by asking each square: a square hangs on the
--  game's button, and in Retail the game may keep where that stands to itself, so
--  its IsMouseOver answers no.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Place = {}
Macros.Place = Place

Place.GLOW = { 1, 0.82, 0.3 } -- the gold frame round the button under the mouse, the game's colour
Place.CARRIED = 34             -- the picture that follows the mouse

local squares = {}
Place.squares = squares
local mine = {}     -- [square] = true: the squares, to know them among the frames under the mouse
local wanted        -- what to do with the place chosen
local owner         -- what Esc goes by
local carried       -- the picture that follows the mouse, and the gold frame
local over          -- the square the gold frame is round now

local function Stop()
    wanted, over = nil, nil
    for _, square in ipairs(squares) do square:Hide() end
    if carried then carried:Hide() end
    if owner then Core.Escape(owner, nil) end
end
Place.Stop = Stop

local function Choose(square)
    local chosen = wanted
    Stop()
    if chosen and square then chosen(square.place) end
end

local function Click(square, mouse)
    if mouse == "RightButton" then return Stop() end
    Choose(square)
end

-- The square under the mouse, if any.
local function Under()
    local foci = (GetMouseFoci and GetMouseFoci()) or (GetMouseFocus and { GetMouseFocus() }) or {}
    for _, frame in ipairs(foci) do
        if mine[frame] and frame:IsShown() then return frame end
    end
    for _, square in ipairs(squares) do
        if square:IsShown() and Core.Plain(square:IsMouseOver()) then return square end
    end
    return nil
end

local function Square(index)
    local square = squares[index]
    if square then return square end
    square = CreateFrame("Button", nil, UIParent)
    square:SetFrameStrata("FULLSCREEN_DIALOG")
    square:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    square:SetScript("OnClick", ns.Guard(Click))
    squares[index], mine[square] = square, true
    return square
end

-- The picture at the mouse, the gold frame round the square under it.
local function Follow(self)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    local square = Under()
    if square == over then return end
    over = square
    local hint = self.hint
    hint:SetShown(square ~= nil)
    if not square then return end
    hint:ClearAllPoints()
    hint:SetAllPoints(square)
end

local function Carried()
    if carried then return carried end
    carried = CreateFrame("Frame", nil, UIParent)
    carried:SetSize(Place.CARRIED, Place.CARRIED)
    carried:SetFrameStrata("TOOLTIP")
    carried.icon = carried:CreateTexture(nil, "ARTWORK")
    carried.icon:SetAllPoints()
    carried.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    carried.icon:SetAlpha(0.85)
    -- The game's own border of an action button, lit, on a frame of its own: the picture moves with the mouse.
    local hint = CreateFrame("Frame", nil, UIParent)
    hint:SetFrameStrata("TOOLTIP")
    local glow = hint:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(Place.GLOW[1], Place.GLOW[2], Place.GLOW[3])
    glow:SetPoint("TOPLEFT", -14, 14)
    glow:SetPoint("BOTTOMRIGHT", 14, -14)
    hint:Hide()
    carried.hint = hint
    carried:SetScript("OnUpdate", ns.Guard(Follow))
    carried:SetScript("OnHide", ns.Guard(function(self)
        over = nil
        self.hint:Hide()
    end))
    carried:Hide()
    return carried
end

-- Squares over every button of the bars that show.
local function Lay()
    local index = 0
    local page = Macros.Reach.Page()
    for _, bar in ipairs(Macros.Reach.BARS) do
        for button = 1, Macros.Reach.BUTTONS do
            local slot = rawget(_G, bar.prefix .. button)
            local parent = slot and slot:GetParent()
            if parent and Core.Plain(parent:IsVisible()) then
                index = index + 1
                local square = Square(index)
                square:ClearAllPoints()
                square:SetAllPoints(slot)
                square.place = Macros.Reach.PlaceOf(bar, button, bar.paged and page or Macros.Reach.Row(slot))
                square:Show()
            end
        end
    end
    return index > 0
end

-- Begins choosing, the picture given following the mouse; done(place) once one is chosen. Out of a fight.
function Place.Start(done, picture)
    if InCombatLockdown() then return ns.Print(Macros.TEXT.noCombat) end
    Stop()
    if not Lay() then return end
    wanted = done
    local shown = Carried()
    shown.icon:SetTexture(picture or Macros.Press.ICON)
    shown:Show()
    owner = owner or CreateFrame("Frame")
    Core.Escape(owner, Stop)
end

-- A drag ended: the square under the mouse, if any. True when one was chosen, false when the drag ended on none; nil when
-- nothing was being placed (it was ended before: Esc, a right click, a fight).
function Place.Drop()
    if not wanted then return nil end
    local square = Under()
    if square then
        Choose(square)
        return true
    end
    Stop()
    return false
end

-- For the test: the square the gold frame is round; the picture at the mouse.
function Place.Over()
    return over
end

function Place.Carried()
    return carried
end

ns.On("PLAYER_REGEN_DISABLED", Stop)
