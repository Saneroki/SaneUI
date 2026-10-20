local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Window
--  The module's window, one of Core's (kind screen): docked in the screen's
--  bottom middle, empty and see-through while small (nothing in it takes the
--  mouse; in Edit Mode it shows its box, to be put elsewhere). The mouse pushed
--  against the middle half of the screen's bottom edge (Core's option strip:
--  half the screen's width, however wide the window is) fills the screen with
--  it; pushed there again, or Esc, it goes back. Full, it holds your talents and
--  your spellbook on Core's board (Board.lua): laid out once it stands
--  (docked), gone as soon as it starts back.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Window = {}
ns.Window = Window

Window.WIDTH, Window.HEIGHT = 400, 32 -- small: an empty strip over the bottom middle, its box in Edit Mode
Window.STRIP = 0.5                    -- the share of the bottom edge, in its middle, that fills the screen

local frame, handle

-- It stands, full or small: the board laid out on the full screen under the title bar, or gone.
local function Placed()
    if handle.edge and handle.edge.full then
        ns.Board.Show(handle.inside, frame:GetWidth(), frame:GetHeight() - (handle.top or 0))
    else
        ns.Board.Hide()
    end
end

-- On its way back: the board goes at once, and what is seated there is given back.
local function Filled(full)
    if not full then ns.Board.Hide() end
end

function Window.Build()
    if frame then return end
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Window.WIDTH, Window.HEIGHT) -- not sizable: its size is ours, not kept
    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options,
        first = { dock = "BOTTOM" }, sizable = false,
        strip = Window.STRIP,
        filled = function(full) ns.Guarded(Filled, full) end,
        docked = function() ns.Guarded(Placed) end,
    })
    Window.handle = handle
    ns.Board.Take(handle) -- its full screen: the talents and the spellbook on Core's board
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

-- What the board holds changed (a layout, a window that opened, closed or took another size): laid out anew,
-- if it stands full now.
function Window.Reboard()
    local edge = handle and handle.edge
    if edge and edge.full and not (edge.clock and edge.clock:IsRunning()) then Placed() end
end

-- The module stood down (GiveBack): the window goes.
function Window.Hide()
    if not frame then return end
    if handle.edge and handle.edge.away then handle:Place() end
    frame:Hide()
end
