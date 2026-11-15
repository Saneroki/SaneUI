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
--  (docked), gone as soon as it starts back. The bag keys fill it too, with the
--  bags on it (Keys.lua: Window.Toggle).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Window = {}
ns.Window = Window

Window.WIDTH, Window.HEIGHT = 64, 64 -- small: an empty square over the corner, its box in Edit Mode

local frame, handle
local wanted -- a window a key asked for while the full screen was on its way

-- It stands, full or small: the board laid out on the full screen under the title bar, or gone. A window a key
-- asked for comes on the layout once it stands (Core's board adds one only then).
local function Placed()
    if handle.edge and handle.edge.full then
        ns.Board.Show(handle.inside, frame:GetWidth(), frame:GetHeight() - (handle.top or 0))
        if wanted then
            local key = wanted
            wanted = nil
            ns.Board.Add(key)
        end
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
-- game's panels*): its key is said instead. The bags are no panel: they open and close by our code; chosen, they
-- show (Keys.GameBags: else they stand hidden while the bag keys open ours).
local CHARACTER = Core.Word("CHARACTER", "Character")
local function Bags()
    ns.Keys.GameBags(true)
    local open = rawget(_G, "OpenAllBags")
    if open then open() end
end
local function CloseBags()
    local close = rawget(_G, "CloseAllBags")
    if close then close() end
    ns.Keys.GameBags(false)
end
-- The button Sane UI is there only while ours can come: the module running, Can expand to fullscreen on.
local function Running() return not ns.off and (ns.options or {}).expand ~= false end
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

-- The full screen, asked for by a talk (Talks.lua): true if it fills the screen now or is on its way. Not in Edit Mode,
-- nor with Can expand to fullscreen off (Edge.lua).
function Window.Fill()
    local edge = handle and handle.edge
    if not edge or not frame:IsShown() then return false end
    if not edge.full then edge:Fill(true) end
    return edge.full
end

-- Back to its size, if it fills the screen.
function Window.Back()
    local edge = handle and handle.edge
    if edge and edge.full then edge:Fill(false) end
end

-- The full screen with that window on it: put on the layout now if the screen stands full, else once it does.
-- Not in Edit Mode, nor with Can expand to fullscreen off (Edge.lua).
function Window.Open(key)
    local edge = handle and handle.edge
    if not edge or not frame:IsShown() then return end
    if edge.full and not (edge.clock and edge.clock:IsRunning()) then return ns.Board.Add(key) end
    wanted = key
    if not edge.full then edge:Fill(true) end
    -- It did not fill after all (Edit Mode, Can expand to fullscreen off): nothing waits to be put on later.
    if not edge.full then wanted = nil end
end

-- A key (Keys.lua): as Open, or, pressed again while the screen stands full with that window, back to its size, as
-- the game's keys toggle its windows. A window made its own (the button beside its X) opens or closes by itself
-- instead (Core's board: Board.Key).
function Window.Toggle(key)
    if Core.Board.Key(ns.name, key) then return end
    local edge = handle and handle.edge
    if edge and edge.full and not (edge.clock and edge.clock:IsRunning()) and ns.Board.Has(key) then
        return edge:Fill(false)
    end
    Window.Open(key)
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
