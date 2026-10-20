local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Board
--  The full screen's windows, while the window stands full: on Core's board
--  (Core.Board), so they share the screen as you arrange them, in layouts
--  behind tabs in the full window's title bar (drag a window's head to move
--  it, the gap between two to share their room anew, its X to take it off;
--  the dropdown Windows adds one). The module's windows, in this order:
--      character  the character sheet
--      bags       the bags
--      alts       the other characters' snapshots
--  Each is a part in files of its own, listed after this one in the TOC, that
--  registers itself (Board.Part); the board lists the parts that are there.
--  The first layout puts them side by side, left to right, each as wide as it
--  asks (its least width), the last one taking what is left.
--
--  A panel is Core's (Board.lua: a plate in Sane UI's look, a head with its
--  title and the X, the body under it); what is in it is its part's. A part
--  runs apart from the rest (ns.Safe): one that fails is noted and the others
--  go on; only the window's own work stands the module down.
--
--  A part is a table with:
--      Part.Build(panel)      makes what it holds in panel.body (panel.title, panel.head are there)
--      Part.Show(on)          its panel is shown (on) or hidden: listen to the game only while shown
--      Part.Size(w, h)        its panel's body is that wide and high now (a part may lack it)
--      Part.Search(text)      what is typed into the search box ("": nothing; a part may lack it)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board = {}
ns.Board = Board

Board.ORDER = { "character", "bags", "alts" } -- the windows in the dropdown's order and the first layout's

local layouts  -- Core's board, once the window is there (Board.Take)
local parts = {} -- [key] = { part, spec }: registered by the parts' files

-- A part's steps, each by itself under the part's title.
local function Step(key, part, name)
    return function(_, ...)
        if part[name] then ns.Safe(key, part[name], ...) end
    end
end

-- A part's file registers it: its window's key (one of Board.ORDER), title, least size (width, height) and
-- the part itself.
function Board.Part(key, title, least, part)
    parts[key] = { part = part, spec = {
        key = key, title = title, least = least,
        build = function(panel) ns.Safe(key, part.Build, panel) end,
        show = Step(key, part, "Show"), size = Step(key, part, "Size"), search = Step(key, part, "Search"),
    } }
end

-- The windows there are, in their order.
local function Windows()
    local list = {}
    for _, key in ipairs(Board.ORDER) do
        if parts[key] then list[#list + 1] = parts[key].spec end
    end
    return list
end

-- The first layout: the windows side by side, each as wide as its least width, the last taking the rest of
-- the room the board lays out in (the screen less Core's pads round and between the windows).
local function Default(width)
    local list = Windows()
    if #list == 0 then return nil end
    if #list == 1 then return { key = list[1].key } end
    local pad = Core.Board.PAD
    local rest = width - pad * (#list + 1)
    local nodes, shares = {}, {}
    for index, spec in ipairs(list) do
        nodes[index] = { key = spec.key }
        shares[index] = spec.least[1]
        if index < #list then rest = rest - spec.least[1] end
    end
    shares[#list] = math.max(shares[#list], rest)
    return { split = "x", parts = nodes, shares = shares }
end

-- Core's window is made (Window.lua): its full screen is Core's board.
function Board.Take(window)
    layouts = Core.Board.New(window, {
        store = ns.store, key = "board", label = ns.name,
        windows = Windows,
        default = function(width, height) return ns.Safe("board", Default, width, height) end,
        changed = function() ns.Guarded(ns.Window.Reboard) end,
    })
    Board.layouts = layouts
end

-- The window stands full: what it holds (inside) is that wide and high.
function Board.Show(inside, width, height)
    if layouts then return layouts:Show(inside, width, height) end
end

-- The window is at its size, or on its way there: every panel out of sight.
function Board.Hide()
    if layouts then layouts:Hide() end
end

function Board.Search(text)
    if layouts then layouts:Search(text) end
end

-- A part's panel, once made (Core's board's).
function Board.Panel(key)
    return layouts and layouts.panels[key]
end
