local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Window
--  The module's window, one of Core's (kind screen): docked in the screen's
--  bottom middle, empty and see-through while small (nothing in it takes the
--  mouse; in Edit Mode it shows its box, to be put elsewhere). The mouse pushed
--  against the middle half of the screen's bottom edge (Core's option strip:
--  half the screen's width, however wide the window is) fills the screen with
--  it; pushed there again, or Esc, it goes back. Full, it holds your talents and
--  your spellbook as panels side by side (Board.lua).
--
--  What the window holds goes with Core's motion: the panels are laid out for
--  the full screen as the motion begins (filled), so the windows seated there
--  stand in their rooms at once, and go back as soon as it starts back; laid
--  out once more when the window stands (docked).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Window = {}
ns.Window = Window

Window.WIDTH, Window.HEIGHT = 400, 32 -- small: an empty strip over the bottom middle, its box in Edit Mode
Window.STRIP = 0.5                    -- the share of the bottom edge, in its middle, that fills the screen

local frame, handle, inside

-- The room the full window holds under its title bar, in UIParent's units: left and top from its bottom
-- left corner, width, height. The full window is the whole screen.
local function Room()
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    return 0, height - Core.Window.BAR, width, height - Core.Window.BAR
end

-- The panels laid out for the full window, on its layer (what is seated stands over it); moving: on its way.
local function Board(moving)
    local left, top, width, height = Room()
    ns.Board.Show(inside, frame:GetFrameStrata(), frame:GetFrameLevel(), left, top, width, height, moving)
end

-- On its way to the full screen (on) or back.
local function Filled(on)
    if on then Board(true) else ns.Board.Hide() end
end

-- It stands, full or small: the panels laid out for where it stands now.
local function Placed()
    if handle.edge and handle.edge.full then Board() else ns.Board.Hide() end
end

function Window.Build()
    if frame then return end
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Window.WIDTH, Window.HEIGHT) -- not sizable: its size is ours, not kept
    inside = CreateFrame("Frame", nil, frame) -- what it holds: the panels, out of sight while its size moves
    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options, content = inside,
        first = { dock = "BOTTOM" }, sizable = false,
        strip = Window.STRIP,
        filled = function(on) ns.Guarded(Filled, on) end,
        docked = function() ns.Guarded(Placed) end,
    })
    Window.handle = handle
    inside:SetAllPoints(handle.inside)
    handle:Place()
end

-- Whether it fills the screen now (or is on its way there).
function Window.Full()
    return handle and handle.edge and handle.edge.full or false
end

-- The full screen, asked for by a window that opened (the game's spellbook, the planner): true if it fills
-- the screen now or is on its way. Not in Edit Mode, nor with Can expand to fullscreen off (Edge.lua).
function Window.Fill()
    if not handle or not handle.edge or not frame:IsShown() then return false end
    if not handle.edge.full then handle.edge:Fill(true) end
    return handle.edge.full
end

-- The module stood down (GiveBack): the window goes.
function Window.Hide()
    if not frame then return end
    if handle.edge and handle.edge.away then handle:Place() end
    frame:Hide()
end
