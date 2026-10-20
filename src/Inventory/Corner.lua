local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Corner
--  The mouse pushed into the screen's bottom right corner opens the game's own
--  bags, all of them, as their key does; pushed there again, it closes them:
--  whenever a bag is open, however it was opened, a push closes them. The game
--  made its bags to be opened by addons: a bag's buttons keep their bag in a
--  secure attribute (ContainerFrame.lua), so using an item from them stays the
--  game's own, in a fight too.
--
--  Not the character sheet, opened nor closed: the game's panels are placed by
--  its window manager (UIParentPanelManager.lua), and a panel an addon's code
--  shows or hides leaves the manager tainted until a /reload. The sheet's own
--  OnShow and OnHide read the player frame's health and mana, secret values to
--  tainted code, and fail: at once when an addon opens it, and later when the
--  game's own key or close button does. Only the game's key and its micro
--  button open it cleanly.
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

-- Closes the bags when one is open, else opens them all.
function Corner.Toggle()
    if Game("IsAnyBagOpen") then Game("CloseAllBags") else Game("OpenAllBags") end
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
