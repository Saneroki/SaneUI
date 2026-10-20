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
local wanted, tab -- a window a key asked for while the full screen was on its way (and the book's tab with it)

-- It stands, full or small: the board laid out on the full screen under the title bar, or gone. A window a
-- key asked for comes on the layout once it stands (Core's board adds one only then).
local function Placed()
    if handle.edge and handle.edge.full then
        ns.Board.Show(handle.inside, frame:GetWidth(), frame:GetHeight() - (handle.top or 0))
        if wanted then
            local key = wanted
            wanted = nil
            ns.Board.Add(key)
        end
        if tab and ns.Book then
            ns.Book.Choose(tab)
            tab = nil
        end
    else
        ns.Board.Hide()
    end
end

-- On its way back: the board goes at once, and what is seated there is given back.
local function Filled(full)
    if not full then ns.Board.Hide() end
end

-- The game's own spellbook and talents (one window of the game's, PlayerSpellsFrame, loaded on demand), in Core's
-- dropdown Classic windows: the full screen goes back and what opens the game's is said (our code opens none of
-- the game's panels: its OnShow sets the action bars' grids): its key, or, while our keys are on the game's
-- (Keys.lua), its button in the micro menu. On it the button Sane UI: ours, filling the screen with our spellbook
-- or talents on it (Core's Classic.lua).
local SPELLBOOK, TALENTS = Core.Word("SPELLBOOK", "Spellbook"), Core.Word("TALENTS", "Talents")
local function Running() return not ns.off end
local function Binding(name) return not ns.Keys.Taken() and name or nil end
local CLASSIC = {
    { text = SPELLBOOK, show = function() Core.Classic.Press(SPELLBOOK, Binding("TOGGLESPELLBOOK")) end,
      ours = function() ns.Safe("classic", Window.Open, "spellbook") end,
      frame = "PlayerSpellsFrame", addon = "Blizzard_PlayerSpells", full = true, ready = Running },
    { text = TALENTS, show = function() Core.Classic.Press(TALENTS, Binding("TOGGLETALENTS")) end,
      ours = function() ns.Safe("classic", Window.Open, "talents") end,
      frame = "PlayerSpellsFrame", addon = "Blizzard_PlayerSpells", full = true, ready = Running },
}

function Window.Build()
    if frame then return end
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Window.WIDTH, Window.HEIGHT) -- not sizable: its size is ours, not kept
    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options,
        first = { dock = "BOTTOM" }, sizable = false, classic = CLASSIC,
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

-- The full screen with that window on it (and the book at that tab: "pet"): put on the layout now if the screen
-- stands full, else once it does.
function Window.Open(key, bookTab)
    local edge = handle and handle.edge
    if not edge then return end
    if edge.full and not (edge.clock and edge.clock:IsRunning()) then
        ns.Board.Add(key)
        if bookTab and ns.Book then ns.Book.Choose(bookTab) end
        return
    end
    wanted, tab = key, bookTab
    Window.Fill()
end

-- One of Combat's keys (Keys.lua): as Open, or, pressed again while the screen stands full with that window,
-- back to its size, as the game's keys toggle its window.
function Window.Toggle(key, bookTab)
    local edge = handle and handle.edge
    if edge and edge.full and not (edge.clock and edge.clock:IsRunning()) and ns.Board.Has(key) and not bookTab then
        return edge:Fill(false)
    end
    Window.Open(key, bookTab)
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
