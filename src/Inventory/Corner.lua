local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Corner
--  The mouse pushed into the screen's bottom right corner opens the game's own
--  bags and character sheet, as their keys do (all bags, then the character);
--  pushed there again, it closes them: whenever either is open, a push closes
--  what is open, and only when neither is does it open both. In a fight the
--  game opens and closes its panels by its own keys only, so there the corner
--  opens and closes the bags alone and leaves the sheet as it is.
--
--  The corner is a square of a few of the screen's pixels (Core's Edge.CORNER,
--  as large as a docked window's corner), above the game's bars and windows,
--  that only takes the mouse's coming: clicks and the wheel go on to what is
--  under it. As at a window's corner, one push is one change: the corner counts
--  again only once the mouse has gone some way from it (Edge.AWAY), seen by a
--  look a few times a second that stops then. No push while a mouse button is
--  held (a drag), in Edit Mode, a moment after the square came under a mouse
--  that was there already, or while one of Sane UI's windows fills the screen
--  (the bags would open behind it). A window of Sane UI's docked in this same
--  corner keeps it for filling the screen: its square lies above this one.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Corner = {}
ns.Corner = Corner

local Edge = Core.Edge
local square        -- the corner, made at the first On
local pushed = false -- pushed, and the mouse not gone from the corner since
local quiet = 0     -- GetTime() before which the mouse's coming counts for nothing

-- A function of the game's by its name, called if this client has it.
local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Sheet()
    return rawget(_G, "CharacterFrame")
end

-- Whether anything the corner opens is open: the bags, or the sheet unless a fight keeps it as it is.
local function Open(fight)
    if Game("IsAnyBagOpen") then return true end
    local sheet = Sheet()
    return not fight and sheet and sheet:IsShown() or false
end

-- Closes what is open, or opens both when neither is.
function Corner.Toggle()
    local fight, sheet = InCombatLockdown(), Sheet()
    if Open(fight) then
        Game("CloseAllBags")
        if not fight and sheet then Game("HideUIPanel", sheet) end
    else
        Game("OpenAllBags")
        if not fight and sheet then Game("ToggleCharacter", "PaperDollFrame") end
    end
end

-- Whether one of Sane UI's windows fills the screen (Core's Edge.lua).
local function Covered()
    for _, window in ipairs(Core.Window.All()) do
        if window.edge and window.edge.full then return true end
    end
    return false
end

-- Whether the mouse is still within Edge.AWAY of the screen's pixels from the corner.
local function Near()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local room = Core.Pixels(UIParent, Edge.AWAY)
    return x / scale >= UIParent:GetWidth() - room and y / scale <= room
end

-- A look whether the mouse has gone from the corner: gone, a push counts again; else another look soon.
local looking
local function Look()
    if not pushed then return end
    if Near() then return C_Timer.After(Edge.LOOK, looking) end
    pushed = false
end
looking = ns.Guard(Look)

local function Pushed()
    if pushed or GetTime() < quiet or IsMouseButtonDown() or Core.EditMode.active or Covered() then return end
    pushed = true
    C_Timer.After(Edge.LOOK, looking)
    Corner.Toggle()
end

-- Shown again (the interface back after Alt-Z, a cinematic): a mouse already in the corner pushes nothing.
local function Quiet()
    quiet = GetTime() + Edge.QUIET
end

-- A few of the screen's pixels, at the UI's scale of now.
local function Size()
    if square then
        local side = Core.Pixels(square, Edge.CORNER)
        square:SetSize(side, side)
    end
end

function Corner.On()
    if not square then
        square = CreateFrame("Frame", nil, UIParent)
        -- Above the game's bars, bags and windows; below a docked window's own corner (a higher level).
        square:SetFrameStrata("DIALOG")
        square:SetFrameLevel(1)
        square:SetPoint("BOTTOMRIGHT")
        if square.SetMouseMotionEnabled then square:SetMouseMotionEnabled(true) else square:EnableMouse(true) end
        square:SetScript("OnEnter", ns.Guard(Pushed))
        square:SetScript("OnShow", ns.Guard(Quiet))
        Core.On("UI_SCALE_CHANGED", Size)
        Core.On("DISPLAY_SIZE_CHANGED", Size)
    end
    Size()
    Quiet()
    square:Show()
end

-- The corner put away (Inventory's GiveBack): what is open stays open.
function Corner.Off()
    pushed = false
    if square then square:Hide() end
end
