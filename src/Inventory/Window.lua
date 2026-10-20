local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Window
--  The module's window, one of Core's (kind screen): docked in the screen's
--  bottom right corner at first, empty and see-through while small (nothing in
--  it takes the mouse; in Edit Mode it shows its box, to be docked elsewhere).
--  Docked in a corner it has Core's square there (Edge.lua, four of the
--  screen's pixels): the mouse pushed all the way into the corner fills the
--  screen with it; pushed there again, or Esc, it goes back. Full, it holds the
--  module's windows on Core's board (Board.lua): laid out once it stands
--  (docked), gone as soon as it starts back.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Window = {}
ns.Window = Window

Window.WIDTH, Window.HEIGHT = 64, 64 -- small: an empty square over the corner, its box in Edit Mode

local frame, handle

-- It stands, full or small: the board laid out on the full screen under the title bar, or gone.
local function Placed()
    if handle.edge and handle.edge.full then
        ns.Board.Show(handle.inside, frame:GetWidth(), frame:GetHeight() - (handle.top or 0))
    else
        ns.Board.Hide()
    end
end

-- On its way back: the windows go at once.
local function Filled(full)
    if not full then ns.Board.Hide() end
end

-- What is typed into the full window's search box goes to every window on the board.
local function Search(text)
    ns.Board.Search(text)
end

-- The game's own character sheet and bags, in Core's dropdown Classic windows; on them the button Sane UI: ours,
-- filling the screen (Core's Classic.lua). Our code never opens the game's character sheet (README, *Never the
-- game's panels*): its key is said instead. The bags are no panel: they open and close by our code.
local CHARACTER = Core.Word("CHARACTER", "Character")
local function Bags()
    local open = rawget(_G, "OpenAllBags")
    if open then open() end
end
local function CloseBags()
    local close = rawget(_G, "CloseAllBags")
    if close then close() end
end
local function Running() return not ns.off end
local CLASSIC = {
    { text = CHARACTER, show = function() Core.Classic.Press(CHARACTER, "TOGGLECHARACTER0") end,
      frame = "CharacterFrame", full = true, ready = Running },
    { text = Core.Word("BAGSLOTTEXT", "Bags"), show = function() ns.Safe("classic bags", Bags) end,
      frame = { "ContainerFrameCombinedBags", "ContainerFrame1" }, plain = true, full = true, ready = Running, hide = CloseBags },
}

function Window.Build()
    if frame then return end
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Window.WIDTH, Window.HEIGHT) -- not sizable: its size is ours, not kept
    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options,
        first = { dock = "BOTTOMRIGHT" }, sizable = false, classic = CLASSIC,
        search = function(text) ns.Guarded(Search, text) end,
        filled = function(full) ns.Guarded(Filled, full) end,
        docked = function() ns.Guarded(Placed) end,
    })
    Window.handle = handle
    ns.Board.Take(handle) -- its full screen: the module's windows on Core's board
    handle:Place()
end

-- Whether it fills the screen now (or is on its way there).
function Window.Full()
    return handle and handle.edge and handle.edge.full or false
end

-- The windows wished on the full screen changed (a layout, a part's window that came or went): laid out
-- anew, if it stands full now.
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
