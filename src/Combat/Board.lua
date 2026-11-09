local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Board
--  The full screen's windows, while the window stands full: on Core's board
--  (Core.Board), so they share the screen as you arrange them, in layouts
--  behind tabs in the full window's title bar (drag a window's head to move
--  it, the gap between two to share their room anew, its X to take it off;
--  the dropdown Windows adds one). The module's windows, in this order:
--      talents    your talents: our own window, as the game's (Talents/)
--      spellbook  your spellbook: our own window, as the game's (Book/)
--      game       in a game without those two (Retail): the game's own window of
--                 both, seated in its panel (GameWindow.lua)
--      trainer    the game's trainer window, seated in its panel while it is open
--      profession the game's Profession window, likewise (Trainer.lua)
--      planner    the window of a talent planner Sane UI knows (Core.Neighbours),
--                 while that addon is installed: seated in its panel (Core.Seat:
--                 its place, scale and layer lent), opened with its panel and
--                 closed when the panel goes
--      bars       the game's wide action bars, seated in their panel (BarsWindow.lua)
--      sidebars   its tall ones, while there are any, in a narrow panel of their own
--      macros     Sane Macros (Macros/)
--  Each is a part, in files of its own listed after this one in the TOC, that
--  registers itself (Board.Part); the board lists the parts that are there.
--  The first layout puts the talents and the spellbook side by side, each as
--  wide as its share of the two windows' own widths, Sane Macros beside them
--  with the wide action bars under it, stacked as on the screen (Saneroki,
--  2026-11-04; without Sane Macros in a strip along the foot), the tall ones
--  down the right. At a trainer the full screen comes with a layout of its own
--  for that talk (Trainer.lua: Core's board's occasions, Board.Occasion).
--
--  A panel is Core's (a plate in Sane UI's look, a head with its title and the
--  X, the body under it); what is in it is its part's. A part runs apart from
--  the rest (ns.Safe): one that fails is noted and the others go on.
--
--  A part is a table with:
--      Part.Build(panel)      makes what it holds in panel.body (panel.title, panel.head are there)
--      Part.Show(on)          its panel is shown (on) or hidden: listen to the game only while shown
--      Part.Size(w, h)        its panel's body is that wide and high now (a part may lack it)
--      Part.Search(text)      what is typed into the search box ("": nothing; a part may lack it)
--      Part.Present()         it has something to show now (a part may lack it: always)
--      Part.Fit()             as large as what it holds: { width, height } of its panel in UIParent's units (a part
--                             may lack it: as the layout gives; Core.Board, spec.fit)
--      Part.Leave()           the module stands down: all it lent or made protected given back
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board = {}
ns.Board = Board

-- The game's own icons for what each window stands for, for its tab in the full window's title bar.
Board.ICONS = {
    talents = "Interface/ICONS/Ability_Marksmanship",
    spellbook = "Interface/ICONS/INV_Misc_Book_09",
    game = "Interface/ICONS/INV_Misc_Book_09",
    bars = "Interface/ICONS/INV_Misc_Gear_01",
    sidebars = "Interface/ICONS/INV_Misc_Gear_02",
    macros = "Interface/ICONS/INV_Misc_Note_06",
}
Board.ORDER = { "talents", "spellbook", "game", "trainer", "profession", "planner", "macros", "bars", "sidebars" }
Board.FIRST = { "talents", "spellbook", "game" }

local layouts    -- Core's board, once the window is there (Board.Take)
local parts = {} -- [key] = { part, spec }: registered by the parts' files
local occasions = {} -- [name] = { title, default }: the talks the full screen has a layout for (Board.Occasion)

-- A part's steps, each by itself under the part's key.
local function Step(key, part, name)
    return function(_, ...)
        if part[name] then ns.Safe(key, part[name], ...) end
    end
end

-- A part's file registers it: its window's key (one of Board.ORDER), title, least size ({ width, height }, or
-- a function giving it), its own size for the first layout's shares (or none: its least) and the part itself.
function Board.Part(key, title, least, part, wants)
    parts[key] = { part = part, wants = wants, spec = {
        key = key, title = title, least = least, icon = part.icon or Board.ICONS[key], coords = part.coords,
        build = function(panel) ns.Safe(key, part.Build, panel) end,
        show = Step(key, part, "Show"), size = Step(key, part, "Size"), search = Step(key, part, "Search"),
        fit = part.Fit and function() return ns.Safe(key, part.Fit) end,
    } }
end

-- A talk the full screen has a layout of its own for (Trainer.lua): its name, its tab's title and its layout until the
-- player changes it (function(width, height) returning a node of Core's board).
function Board.Occasion(name, title, default)
    occasions[name] = { title = title, default = function(width, height) return ns.Safe("board", default, width, height) end }
end

-- A talk began (its name) or ended (nil): its layout stands on the full screen while it is on.
function Board.Talk(name)
    if layouts then layouts:Occasion(name) end
end

-- Whether a part is registered and has something to show now (the planner: while its addon is there).
function Board.Present(key)
    local entry = parts[key]
    if not entry then return false end
    return not entry.part.Present or ns.Safe(key, entry.part.Present) == true
end

-- The windows there are now, in their order (the dropdown Windows lists them).
local function Windows()
    local list = {}
    for _, key in ipairs(Board.ORDER) do
        if Board.Present(key) then list[#list + 1] = parts[key].spec end
    end
    return list
end

local function Least(spec)
    local least = spec.least
    if type(least) == "function" then least = least() end
    return least
end

-- Sane Macros beside the row of nodes (node: it with what stands under it): its least width of that row, the others
-- sharing the rest as they did.
local function Macros(nodes, shares, width, node)
    if not Board.Present("macros") then return end
    local wanted = Least(parts.macros.spec)[1]
    local others = 0
    for _, share in ipairs(shares) do others = others + share end
    if others > 0 and width and width > wanted then
        local rest = (width - wanted) / others
        for index, share in ipairs(shares) do shares[index] = share * rest end
    end
    nodes[#nodes + 1] = node or { key = "macros" }
    shares[#shares + 1] = wanted
end

-- The first layout: the talents and the spellbook side by side, each as wide as its share of their own widths (those
-- of the two this game has: Combat.lua, ns.Serves); Sane Macros beside them, the action bars under it (without it,
-- along the foot).
local function Default(width, height)
    local nodes, shares = {}, {}
    local side = Board.Present("sidebars") and ns.BarsWindow.Side() or nil
    if width and side then width = width - side end
    for _, key in ipairs(Board.FIRST) do
        local entry = parts[key]
        if entry and Board.Present(key) then
            nodes[#nodes + 1] = { key = key }
            shares[#shares + 1] = (entry.wants or Least(entry.spec))[1]
        end
    end
    local high = height or 700
    local column
    if Board.Present("macros") then
        local strip = ns.BarsWindow.Wants(width, height, high - Least(parts.macros.spec)[2])
        column = { split = "y", parts = { { key = "macros" }, { key = "bars" } }, shares = { math.max(high - strip, strip), strip } }
    end
    Macros(nodes, shares, width, column)
    local row = #nodes > 1 and { split = "x", parts = nodes, shares = shares } or nodes[1]
    local left = row or { key = "bars" }
    if not column then
        local strip = ns.BarsWindow.Wants(width, height)
        left = row and { split = "y", parts = { row, { key = "bars" } }, shares = { math.max(high - strip, strip), strip } } or left
    end
    if not side then return left end
    return { split = "x", parts = { left, { key = "sidebars" } }, shares = { width or 1000, side } }
end

-- Core's window is made (Window.lua): its full screen is Core's board.
function Board.Take(window)
    layouts = Core.Board.New(window, {
        store = ns.store, key = "board", label = ns.name,
        windows = Windows,
        default = function(width, height) return ns.Safe("board", Default, width, height) end,
        changed = function() ns.Guarded(ns.Window.Reboard) end,
        occasions = occasions,
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

-- Whether a window is in the layout laid out last.
function Board.Has(key)
    return layouts and layouts:Has(key) or false
end

-- A window put on the layout shown (a key asked for it), as the dropdown Windows does; only while it stands.
function Board.Add(key)
    if layouts and layouts.standing and Board.Present(key) and not layouts:Has(key) then layouts:Toggle(key) end
end

-- The module stood down (GiveBack): every panel goes, and each part gives back what it lent or made, the board
-- failing or not.
function Board.Leave()
    ns.Safe("board", Board.Hide)
    for key, entry in pairs(parts) do
        if entry.part.Leave then ns.Safe(key, entry.part.Leave) end
    end
end

-------------------------------------------------------------------------------
--  The talent planner: a window of its own while its addon is there
-------------------------------------------------------------------------------
local Planner = {}
local seat, shown, body -- its seat, once made; its panel is shown; that panel's body

local function Handle()
    return Core.Neighbours.Window("talents")
end

-- The planner's window seated in the panel's body (opened first if it is closed), or given back.
local function Seat()
    local planner = Handle()
    if not (shown and planner and body) then
        if seat then seat:Free() end
        return
    end
    if not planner:Shown() then planner:Open() end
    local frame = planner:Frame()
    if not frame then return end
    seat = seat or Core.Seat.New(frame, { label = "Combat: planner", sized = Seat, gone = function() end })
    local left, top = body:GetLeft(), body:GetTop()
    if not (left and top) then return end
    local ratio = body:GetEffectiveScale() / UIParent:GetEffectiveScale()
    seat:Hold(left * ratio, top * ratio, body:GetWidth() * ratio, body:GetHeight() * ratio,
              body:GetFrameStrata(), body:GetFrameLevel() + 30)
end
local Reseat = Core.Later(function() ns.Safe("planner", Seat) end) -- once the panel stands where it goes

function Planner.Build(panel)
    body = panel.body
end

function Planner.Show(on)
    shown = on
    if on then return Reseat() end
    if seat then seat:Free() end
    local planner = Handle()
    if planner and planner:Shown() then planner:Close() end
end

function Planner.Size()
    Reseat()
end

function Planner.Present()
    return Handle() ~= nil
end

function Planner.Leave()
    shown = false
    if seat then seat:Free() end
end

Board.Part("planner", ns.TEXT.planner, { 400, 300 }, Planner)

-- The planner opened by any way while its panel is on the layout but not shown: the full screen comes and holds
-- it. Followed once (Neighbours.lua): from the login, or from when its addon is first there.
local followed = false
local function Follow()
    local planner = Handle()
    if followed or not planner then return end
    followed = true
    planner:Follow(ns.Guard(function()
        if shown then return Reseat() end
        if Board.Has("planner") and not ns.Window.Full() then ns.Window.Fill() end
    end))
end
Board.Follow = Follow

local present = Planner.Present
function Planner.Present()
    local there = present()
    if there then Follow() end
    return there
end
