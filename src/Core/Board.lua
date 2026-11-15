local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Board
--  A module's full screen of windows (Doc/guides/windows.md, section 8: the
--  board), laid out as the player arranges them, in layouts behind tabs in
--  the full window's title bar.
--
--  The windows share the screen and never overlap: a layout is a tree of
--  splits, each dividing its room side by side ("x") or one over the other
--  ("y") into shares, its leaves the windows (Board.Lay). The gap between two
--  neighbours is a line to drag: they share their room anew, neither smaller
--  than it may be (least). A window's head (its title, its own buttons, an X)
--  is dragged onto another window: near a side of that one, the two share its
--  room, the dropped one at that side; in its middle, the two swap places;
--  near a side of the whole screen, it takes a strip along that side. The X
--  takes the window off the layout, and the others take its room.
--
--  While a line or a head is held only a line or a tinted shape of where it
--  would go follows the mouse; let go, the layout is kept and laid out anew
--  once, so a window is told its new size once, not at every step.
--
--  Layouts, behind tabs in the title bar after its title: the first is the
--  module's own (its default, laid out for the screen as it is until it is
--  changed; then it is kept as changed, and Reset makes it the module's
--  again). The + after the tabs makes an empty one; a right click on a tab
--  renames it, resets the first, deletes any while another is left. The dropdown Windows lists
--  what the module can show, ticked where it is in the layout: a tick adds it
--  (it shares the room of the largest window there), an untick takes it off as
--  its X does. A window that has an icon (spec.icon) has a tab of its own too,
--  after the layouts' tabs and the +: its icon in place of words, lit while
--  the window is in the layout; a click puts it in or takes it off, as its tick
--  in the dropdown does, and its tooltip says its title. A window the module
--  cannot hold right now (present: false; the game's guild window, closed)
--  stays in the layout but is left out of the laying out, the others sharing
--  its room until it is back. Its tick then does nothing to see, so a window
--  of the module's own stands instead and says why it is empty.
--
--  A talk's layout (Saneroki, 2026-11-09: at a vendor, a banker, a trainer the
--  full screen comes with what that talk is for): while the module says a
--  talk is on (board:Occasion(name), one of options.occasions), its layout
--  stands instead of the tab chosen: the module's own for it until it is
--  changed, then kept as changed. Its tab, first in the title bar while the
--  talk is on, says its name; a right click resets it. Another tab chosen
--  meanwhile sets it aside until the talk is over; its own tab brings it back.
--
--  Kept in the module's store, account-wide as windows' places are:
--      store[key] = { chosen = 2, tabs = { { name = "Default", tree = nil }, { name = "Raid", tree = node } },
--                     occasions = { vendor = { tree = node } } }   -- a talk's layout, once changed
--      node = { key = "talks" }                                         a window
--           | { split = "x" or "y", parts = { node, ... }, shares = { 0.6, 0.4 } }
--  The first tab without a tree is the module's default; another without one is empty.
--
--      local board = Core.Board.New(window, {  -- Core's window (Window.New, with edge) whose full screen it is
--          store = ns.store, key = "board",    -- where its layouts are kept
--          label = "Social",                   -- its name in the error log
--          windows = function() return { spec, ... } end,      -- what can stand on it now, in the dropdown's order
--          default = function(width, height) return node end,  -- the first tab's layout until it is changed
--          changed = function() end,           -- a layout changed: the module lays out anew (board:Show)
--          occasions = { vendor = { title = "Vendor",        -- the talks it has a layout for (or none)
--                                   default = function(width, height) return node end } },
--      })
--      spec = { key = "talks", title = "Conversations",
--               least = { 460, 200 },          -- its least width and height (or a function giving both)
--               build = function(panel) end,   -- panel.head, panel.title, panel.body: made when first shown
--               show = function(panel, on) end,
--               size = function(panel, width, height) end,  -- placed that large (once a change stands)
--               search = function(panel, text) end,
--               present = function() return true end,       -- it has something to show now
--               fit = function() return { width, height } end,  -- as large as what it holds (the panel's size in
--                                              -- UIParent's units; nil: as the layout gives): along its split it
--                                              -- takes that, its neighbours share the rest and the line between
--                                              -- them stays; across, the room beside it stays empty
--               dress = "bare",                -- no frame: the module draws its own (its head, title, X there);
--                                              -- nil: the kit's heavy bronze (Core.Look.Frame)
--               icon = "Interface/ICONS/...",  -- its tab of its own after the layouts' tabs: a texture or file ID
--                                              -- (coords: its texture coordinates), or function(texture) that
--                                              -- draws it (a portrait); none: only the dropdown lists it
--               coords = { left, right, top, bottom } }
--      local rects = board:Show(inside, width, height)  -- full and standing: [key] = { left, top, width, height }
--      board:Hide()                       -- the window starts back
--      board:Search(text)                 -- what is typed into the search box
--      board:Has(key)                     -- in the layout laid out last
--      board:Forget(key)                  -- a window that is no more (a chat view removed): out of every layout
--      board:Occasion(name)               -- a talk began (its name in options.occasions) or ended (nil)
--      board:Talking()                    -- the talk whose layout stands now, or nil
--      board.panels[key]                  -- its panel, once made
--      board.made[spec]                   -- every panel made, by the spec it was built for: one back under its
--                                         -- key (Board.Offer, Withdraw) is its own again, not built anew
-------------------------------------------------------------------------------
local Board = {}
Core.Board = Board

Board.PAD = 12          -- between the windows, and from the screen's edges
Board.BAND = 10         -- the kit's bronze band round a panel (Core.Look.BAND): its head and its body inside it
Board.HEAD = 40         -- a window's head: the band and a row of 30 for its title and its X
Board.EDGE = 12         -- from a panel's border to what is in it: the band and a little room
Board.RADIUS = 8        -- of a round plate's corners (Core.Skin; the options' screen)
Board.LEAST = 160       -- a window's least width and height, unless it says
Board.SIDE = 0.3        -- dropped within this share of a window's side, it goes there; nearer the middle, they swap
Board.SCREEN = 36       -- dropped this near a side of the whole screen, it takes a strip along it
Board.STRIP = 0.3       -- that strip's share of the screen
Board.LEVEL = 5         -- the panels above what the window holds
Board.FADE = 0.3        -- seconds a panel takes to come in
Board.TAB_PAD = 32      -- a tab's room around its words
Board.TAB_OVER = 19     -- how far the top bar's ends reach past its first and last tab (Core.Look.TAB_OVER, at its height)
Board.MENU_WIDTH = 120  -- the dropdown Windows
Board.ICON = 20         -- a window's icon in its tab
Board.ICON_PAD = 22     -- the tab's room around it
Board.ICON_GAP = 10     -- between the layouts' tabs and the windows' icon tabs

Board.TEXT = {
    default = Core.Word("DEFAULT", "Default"),
    new = "Layout %d",
    add = "New layout",
    addTip = "An empty layout: add windows to it from the dropdown Windows.",
    windows = "Windows",
    empty = "Add windows to this layout from the dropdown Windows.",
    remove = "Remove from this layout",
    rename = "Rename",
    renameAsk = "Name of the layout:",
    reset = Core.Word("RESET", "Reset"),
    resetAsk = "Lay out %s as at first again?",
    delete = Core.Word("DELETE", "Delete"),
    deleteAsk = "Delete the layout %s?",
    tabTip = "Right-click to rename or delete it.",
    talkTip = "The layout while you talk to them: arrange it as you like. Right-click to reset it.",
    accept = Core.Word("ACCEPT", "Accept"),
}

-------------------------------------------------------------------------------
--  A layout: plain tables, no frames
-------------------------------------------------------------------------------
-- A copy, to change: the kept one is changed only by being replaced. What a hand or an old version left
-- unusable in it is left out (a part that is no table, a key that is no word) or none (a share that is no number).
local function Copy(node)
    if type(node) ~= "table" then return nil end
    if node.key ~= nil then return type(node.key) == "string" and { key = node.key } or nil end
    local given = type(node.parts) == "table" and node.parts or {}
    local kept = type(node.shares) == "table" and node.shares or {}
    local parts, shares = {}, {}
    for index, part in ipairs(given) do
        local copy = Copy(part)
        if copy then parts[#parts + 1], shares[#shares + 1] = copy, tonumber(kept[index]) or 0 end
    end
    return { split = node.split, parts = parts, shares = shares }
end
Board.Copy = Copy

-- Whether a window is in a layout.
function Board.Holds(node, key)
    if type(node) ~= "table" then return false end
    if node.key then return node.key == key end
    for _, part in ipairs(node.parts or {}) do
        if Board.Holds(part, key) then return true end
    end
    return false
end

-- Shares that make one together, each in proportion to what it was.
local function Even(shares)
    local total = 0
    for _, share in ipairs(shares) do total = total + math.max(tonumber(share) or 0, 0) end
    for index, share in ipairs(shares) do
        shares[index] = total > 0 and math.max(tonumber(share) or 0, 0) / total or 1 / #shares
    end
end

-- A split left with one part is that part, and one that holds a split the same way takes that one's parts in.
local function Tidy(node)
    if not node or node.key then return node end
    local parts, shares = {}, {}
    for index, part in ipairs(node.parts) do
        part = Tidy(part)
        if part then
            local share = node.shares[index] or 0
            if part.split == node.split then
                for inner, sub in ipairs(part.parts) do
                    parts[#parts + 1], shares[#shares + 1] = sub, share * part.shares[inner]
                end
            else
                parts[#parts + 1], shares[#shares + 1] = part, share
            end
        end
    end
    if #parts == 0 then return nil end
    if #parts == 1 then return parts[1] end
    Even(shares)
    node.parts, node.shares = parts, shares
    return node
end

-- The layout without a window: nil once nothing is left.
function Board.Without(node, key)
    if not node then return nil end
    if node.key then return node.key ~= key and node or nil end
    for index = #node.parts, 1, -1 do
        local part = Board.Without(node.parts[index], key)
        if part then
            node.parts[index] = part
        else
            table.remove(node.parts, index)
            table.remove(node.shares, index)
        end
    end
    return Tidy(node)
end

local AXIS = { left = "x", right = "x", top = "y", bottom = "y" }
local FIRST = { left = true, top = true }

-- The layout with a window at a side (left, right, top, bottom) of another (target: its key): the two share that
-- one's room, half each. Without target: at that side of the whole, a strip of Board.STRIP.
function Board.Beside(node, key, target, side)
    local leaf = { key = key }
    if not node then return leaf end
    local function Pair(other, share)
        local parts = FIRST[side] and { leaf, other } or { other, leaf }
        local shares = FIRST[side] and { share, 1 - share } or { 1 - share, share }
        return { split = AXIS[side], parts = parts, shares = shares }
    end
    if not target then return Tidy(Pair(node, Board.STRIP)) end
    local function Into(current)
        if current.key then return current.key == target and Pair(current, 0.5) or current end
        for index, part in ipairs(current.parts) do current.parts[index] = Into(part) end
        return current
    end
    return Tidy(Into(node))
end

-- The layout with two windows in each other's place.
function Board.Swap(node, one, other)
    if not node then return nil end
    if node.key == one then
        node.key = other
    elseif node.key == other then
        node.key = one
    else
        for _, part in ipairs(node.parts or {}) do Board.Swap(part, one, other) end
    end
    return node
end

-- Where each window of a layout stands in a room (left and top from the inside's top left, down; whole pixels),
-- gap between neighbours. rects[key] = { left, top, width, height }; lines: one for each pair of neighbours,
-- { node, index (of the part before it), left, top, width, height (the gap), before, after (the two parts' sizes) }.
-- fit(key), where given: a window's own size ({ width, height }, the layout's units) when it is as large as what it
-- holds (spec.fit), else nil.
function Board.Lay(node, left, top, width, height, gap, rects, lines, fit)
    rects, lines = rects or {}, lines or {}
    if not node then return rects, lines end
    local function Own(key)
        local size = fit and key and fit(key)
        return type(size) == "table" and size or nil
    end
    if node.key then
        local own = Own(node.key)
        if own then
            -- Its own size where the room allows, along the room's top, in its middle across.
            local wide, high = math.min(own[1], width), math.min(own[2], height)
            rects[node.key] = { left + math.floor((width - wide) / 2), top, wide, high }
        else
            rects[node.key] = { left, top, width, height }
        end
        return rects, lines
    end
    local across, count = node.split == "x", #node.parts
    local room = (across and width or height) - gap * (count - 1)
    -- A window as large as what it holds takes its size along the split; the others share what is left as they share.
    local fixed, rest, shared, last = {}, room, 0, nil
    for index, part in ipairs(node.parts) do
        local own = Own(part.key)
        if own then
            fixed[index] = math.max(math.min(math.floor((across and own[1] or own[2]) + 0.5), rest), 0)
            rest = rest - fixed[index]
        else
            shared, last = shared + node.shares[index], index
        end
    end
    local sizes, used = {}, 0
    for index = 1, count do
        if fixed[index] then
            sizes[index] = fixed[index]
        else
            local share = shared > 0 and node.shares[index] / shared or 0
            sizes[index] = index == last and rest - used or math.floor(rest * share + 0.5)
            used = used + sizes[index]
        end
    end
    local at = across and left or top
    for index, part in ipairs(node.parts) do
        if across then
            Board.Lay(part, at, top, sizes[index], height, gap, rects, lines, fit)
        else
            Board.Lay(part, left, at, width, sizes[index], gap, rects, lines, fit)
        end
        at = at + sizes[index]
        if index < count then
            -- No line to drag beside a window as large as what it holds.
            if not (fixed[index] or fixed[index + 1]) then
                local line = across and { node, index, at, top, gap, height } or { node, index, left, at, width, gap }
                line[7], line[8] = sizes[index], sizes[index + 1]
                lines[#lines + 1] = line
            end
            at = at + gap
        end
    end
    return rects, lines
end

-- The least a part of a layout may be along a split's way (across: its width; else its height): least(key) gives
-- a window's least width and height.
function Board.Least(node, across, least, gap)
    if node.key then
        local width, height = least(node.key)
        return across and width or height
    end
    local along, total = (node.split == "x") == across, 0
    for _, part in ipairs(node.parts) do
        local size = Board.Least(part, across, least, gap)
        total = along and total + size or math.max(total, size)
    end
    return along and total + gap * (#node.parts - 1) or total
end

-- The layout as it is laid out now: without the windows that have nothing to show (here(key) false). A split of it
-- that lost parts is a new one that remembers the kept split it stands for (of) and its parts' places there (from),
-- so a share dragged there is written back (Back).
local function Present(node, here)
    if node.key then return here(node.key) and node or nil end
    local parts, shares, from = {}, {}, {}
    for index, part in ipairs(node.parts) do
        local kept = Present(part, here)
        if kept then parts[#parts + 1], shares[#shares + 1], from[#from + 1] = kept, node.shares[index], index end
    end
    if #parts == 0 then return nil end
    if #parts == 1 then return parts[1] end
    if #parts == #node.parts and parts[1] == node.parts[1] then
        local same = true
        for index, part in ipairs(parts) do same = same and part == node.parts[index] end
        if same then return node end
    end
    Even(shares)
    return { split = node.split, parts = parts, shares = shares, of = node, from = from }
end
Board.Present = Present

-- A split laid out with shares changed: those of the kept split it stands for, the missing parts' as they were.
local function Back(shown)
    local kept = shown.of
    if not kept then return end
    local total = 0
    for _, index in ipairs(shown.from) do total = total + kept.shares[index] end
    for at, index in ipairs(shown.from) do kept.shares[index] = shown.shares[at] * total end
end

-- A line between two parts moved by that much (pixels; to the right or down): their shares anew, neither smaller
-- than its least (lessBefore, lessAfter). Returns how far it moved.
function Board.Move(line, by, lessBefore, lessAfter)
    local node, index, before, after = line[1], line[2], line[7], line[8]
    local both = before + after
    local now = math.min(math.max(before + by, lessBefore), both - lessAfter)
    if both - lessAfter < lessBefore then now = before end -- no room to move at all
    local share = node.shares[index] + node.shares[index + 1]
    node.shares[index] = share * now / math.max(both, 1)
    node.shares[index + 1] = share - node.shares[index]
    Back(node)
    return now - before
end

-------------------------------------------------------------------------------
--  The board
-------------------------------------------------------------------------------
local methods = {}
local meta = { __index = methods }

local function Label(board) return board.options.label or "board" end

-- What is kept: made, and mended where a hand or an old version left it unusable.
local function Kept(board)
    local options = board.options
    local kept = options.store[options.key or "board"]
    if type(kept) ~= "table" or type(kept.tabs) ~= "table" or #kept.tabs == 0 then
        kept = { chosen = 1, tabs = { {} } }
        options.store[options.key or "board"] = kept
    end
    for index, tab in ipairs(kept.tabs) do
        if type(tab) ~= "table" then kept.tabs[index] = {} end -- the first: the module's own again; another: empty
    end
    if type(kept.chosen) ~= "number" or not kept.tabs[kept.chosen] then kept.chosen = 1 end
    if kept.occasions ~= nil and type(kept.occasions) ~= "table" then kept.occasions = nil end
    return kept
end

-- The talk whose layout stands now: one the module has a layout for, not set aside by another tab chosen.
local function Occasion(board)
    local name = board.occasion
    local occasions = board.options.occasions
    if name == nil or board.aside or type(occasions) ~= "table" or type(occasions[name]) ~= "table" then return nil end
    return name, occasions[name]
end

local function Name(index, tab)
    return type(tab.name) == "string" and tab.name ~= "" and tab.name or (index == 1 and Board.TEXT.default or Board.TEXT.new:format(index))
end

-- Windows other modules offer a module's board (Board.Offer): [label] = { spec, ... }.
local offered = {}

-- What can stand on the board now, by key: the module's own, then those offered to it; one offered with the key of
-- one of the module's own stands in its place.
local function Specs(board)
    local own = Core.Safe(Label(board), board.options.windows) or {}
    local extra = offered[board.options.label]
    local list, byKey = {}, {}
    for _, spec in ipairs(extra or {}) do byKey[spec.key] = spec end
    for _, spec in ipairs(own) do
        local instead = byKey[spec.key]
        list[#list + 1] = instead or spec
        if not instead then byKey[spec.key] = spec end
    end
    for _, spec in ipairs(extra or {}) do
        local listed = false
        for _, other in ipairs(list) do listed = listed or other == spec end
        if not listed then list[#list + 1] = spec end
    end
    return list, byKey
end

local function Least(board, key)
    local spec = board.specs and board.specs[key]
    local least = spec and spec.least
    if type(least) == "function" then least = Core.Safe(Label(board), least) end
    local width = type(least) == "table" and tonumber(least[1]) or Board.LEAST
    local height = type(least) == "table" and tonumber(least[2]) or Board.LEAST
    return width, height + Board.HEAD
end

-- A window's own size in the board's units while it is as large as what it holds (spec.fit), else nil.
local function Fitted(board, key)
    local spec = board.specs and board.specs[key]
    if not (spec and spec.fit) then return nil end
    local size = Core.Safe(Label(board), spec.fit)
    local width, height = type(size) == "table" and tonumber(size[1]), type(size) == "table" and tonumber(size[2])
    if not (width and height and width > 0 and height > 0) then return nil end
    local inside = board.inside
    local ratio = inside and inside.GetEffectiveScale and inside:GetEffectiveScale() / UIParent:GetEffectiveScale() or 1
    if not (ratio > 0) then ratio = 1 end
    return { width / ratio, height / ratio }
end

-- The layout chosen, as it is kept: tree (nil for the first tab: the module's default); during a talk, the talk's
-- (nil: the module's for it) and what the module says of it (title, default).
local function Chosen(board)
    local kept = Kept(board)
    local name, occasion = Occasion(board)
    if name then
        kept.occasions = kept.occasions or {}
        local tab = kept.occasions[name]
        if type(tab) ~= "table" then
            tab = {}
            kept.occasions[name] = tab
        end
        return tab, nil, occasion
    end
    return kept.tabs[kept.chosen], kept.chosen
end

-- The layout chosen changed: kept as it is now (the first tab too, from now on), and laid out anew.
local function Keep(board, tree)
    local tab = Chosen(board)
    tab.tree = Copy(tree) or false -- false: emptied (the first tab, too, is then not the module's default)
    if board.options.changed then Core.Safe(Label(board), board.options.changed) end
end

-------------------------------------------------------------------------------
--  Holding a line or a head
-------------------------------------------------------------------------------
local held       -- what is held: { board, line = ..., strip = ... } or { board, panel = ..., onto = ..., side = ... }
local watcher    -- runs while something is held
local ghost      -- the tinted shape of where a window would go
local room = {}  -- the room a held window would take: one table, filled anew at every look (Target)

-- The mouse in the board's room: from the inside's top left, down.
local function Pointer(board)
    local inside = board.inside
    local scale, left, top = inside:GetEffectiveScale(), inside:GetLeft(), inside:GetTop()
    local x, y = GetCursorPosition()
    return x / scale - (left or 0), (top or 0) - y / scale
end

local function Shape(board, rect)
    if not ghost then
        ghost = CreateFrame("Frame", nil, UIParent)
        local tint = ghost:CreateTexture(nil, "OVERLAY")
        tint:SetAllPoints()
        tint:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.35)
    end
    if not rect then return ghost:Hide() end
    ghost:SetParent(board.inside)
    ghost:SetFrameLevel(board.inside:GetFrameLevel() + Board.LEVEL + 30)
    ghost:ClearAllPoints()
    ghost:SetPoint("TOPLEFT", board.inside, "TOPLEFT", rect[1], -rect[2])
    ghost:SetSize(math.max(rect[3], 1), math.max(rect[4], 1))
    ghost:Show()
end

local function Room(left, top, width, height)
    room[1], room[2], room[3], room[4] = left, top, width, height
    return room
end

-- Where a window held by its head would go: the window it is over (its key; nil at a side of the whole screen),
-- the side of that one it would take (or "swap", in its middle) and the room it would take; nothing: nowhere (on
-- itself, between windows). It runs every frame while a head is held: no table is made here but the one room.
local function Target(board, key)
    local x, y = Pointer(board)
    local width, height = board.width, board.height
    local side, distance = nil, Board.SCREEN
    if x < distance then side, distance = "left", x end
    if width - x < distance then side, distance = "right", width - x end
    if y < distance then side, distance = "top", y end
    if height - y < distance then side, distance = "bottom", height - y end
    if side then
        local strip = math.floor((AXIS[side] == "x" and width or height) * Board.STRIP)
        if side == "left" then return nil, side, Room(0, 0, strip, height) end
        if side == "right" then return nil, side, Room(width - strip, 0, strip, height) end
        if side == "top" then return nil, side, Room(0, 0, width, strip) end
        return nil, side, Room(0, height - strip, width, strip)
    end
    for other, rect in pairs(board.rects) do
        if other ~= key and x >= rect[1] and x <= rect[1] + rect[3] and y >= rect[2] and y <= rect[2] + rect[4] then
            local fx, fy = (x - rect[1]) / rect[3], (y - rect[2]) / rect[4]
            local best, least = nil, Board.SIDE
            if fx < least then best, least = "left", fx end
            if 1 - fx < least then best, least = "right", 1 - fx end
            if fy < least then best, least = "top", fy end
            if 1 - fy < least then best, least = "bottom", 1 - fy end
            if not best then return other, "swap", rect end
            local l, t, w, h = rect[1], rect[2], rect[3], rect[4]
            if best == "left" then return other, best, Room(l, t, w / 2, h) end
            if best == "right" then return other, best, Room(l + w / 2, t, w / 2, h) end
            if best == "top" then return other, best, Room(l, t, w, h / 2) end
            return other, best, Room(l, t + h / 2, w, h / 2)
        end
    end
    return nil
end

local function Watch()
    local board = held.board
    if held.line then
        local line, x, y = held.line, Pointer(board)
        local across = line[1].split == "x"
        local by = (across and x - (line[3] + line[5] / 2) or y - (line[4] + line[6] / 2))
        held.by = by
        local strip = held.strip
        strip:ClearAllPoints()
        if across then
            strip:SetPoint("TOPLEFT", board.inside, "TOPLEFT", line[3] + by, -line[4])
        else
            strip:SetPoint("TOPLEFT", board.inside, "TOPLEFT", line[3], -(line[4] + by))
        end
    else
        local onto, side, rect = Target(board, held.panel.key)
        if held.looked and onto == held.onto and side == held.side then return end -- the same as at the last look: the shape stays
        held.onto, held.side, held.looked = onto, side, true
        Shape(board, rect)
    end
end

local function Watching(on)
    if not watcher then
        watcher = CreateFrame("Frame")
        -- An error here would come again every frame: the watcher stops, the shape goes, and what is held goes
        -- back where it was when it is let go.
        watcher:SetScript("OnUpdate", Core.Guard("board", function()
            local ok, problem = xpcall(Watch, Core.Trace)
            if ok then return end
            watcher:Hide()
            if held then held.onto, held.side, held.by = nil, nil, nil end
            Shape(nil, nil)
            Core.Report("board", problem)
        end))
    end
    watcher:SetShown(on)
end

-- Let go of what is held (cancel: as it was).
local function Release(cancel)
    local hand = held
    if not hand then return end
    held = nil
    Watching(false)
    Shape(hand.board, nil)
    local board = hand.board
    if hand.line then
        local strip = hand.strip
        strip.lit = false
        strip.line:SetAlpha(strip:IsMouseOver() and 0.9 or 0)
        if strip:IsMouseOver() then SetCursor("UI_RESIZE_CURSOR") else SetCursor(nil) end
        local line = hand.line
        if cancel or not hand.by or hand.by == 0 or not board.standing then
            -- Nothing changes: only the strip followed the mouse, and it goes back over its gap.
            strip:ClearAllPoints()
            strip:SetPoint("TOPLEFT", board.inside, "TOPLEFT", line[3], -line[4])
            return
        end
        local across = line[1].split == "x"
        local before, after = line[1].parts[line[2]], line[1].parts[line[2] + 1]
        local function least(key) return Least(board, key) end
        Board.Move(line, hand.by, Board.Least(before, across, least, Board.PAD), Board.Least(after, across, least, Board.PAD))
        Keep(board, board.tree)
        return
    end
    hand.panel:SetAlpha(1)
    local onto, side = hand.onto, hand.side
    if cancel or not side or not board.standing then return end
    local key, tree = hand.panel.key, Copy(board.tree)
    if side == "swap" then
        tree = Board.Swap(tree, key, onto)
    else
        tree = Board.Beside(Board.Without(tree, key), key, onto, side)
    end
    Keep(board, tree)
end
Board.Release = Release

-------------------------------------------------------------------------------
--  The panels
-------------------------------------------------------------------------------
-- A head along a panel's top to drag it by, inside its band (Board.BAND) and as high as the head's row.
local function Head(board, panel, right)
    local row = Board.HEAD - Board.BAND
    panel.head = CreateFrame("Frame", nil, panel)
    panel.head:SetPoint("TOPLEFT", Board.BAND, -Board.BAND)
    if right then panel.head:SetPoint("RIGHT", right, "LEFT") else panel.head:SetPoint("RIGHT", -Board.BAND, 0) end
    panel.head:SetHeight(row)
    panel.head:EnableMouse(true)
    panel.head:RegisterForDrag("LeftButton")
    panel.head:SetScript("OnDragStart", function() Core.Safe(Label(board), board.Lift, board, panel) end)
    panel.head:SetScript("OnDragStop", function() Core.Safe(Label(board), Release, false) end)
end

-- The kit's panel (Core.Look, the character list's heavy bronze): inside its band a head with its title at the
-- left (the game's gold words), the X at its right (the game's own close button), the thin golden line under it;
-- under that, its body. Its body from the panel's top Board.HEAD down, its sides as the panel's: what a module
-- puts there keeps Board.EDGE from the panel's border, inside the band.
local function Plate(board, panel, spec)
    panel.skin = Core.Look.Frame(panel)
    local row = Board.HEAD - Board.BAND
    panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButtonNoScripts")
    panel.close:SetPoint("TOPRIGHT", -Board.BAND + 2, -Board.BAND - (row - 24) / 2)
    panel.close:SetScript("OnClick", function() Core.Safe(Label(board), board.Remove, board, panel.key) end)
    Core.Tip(panel.close, Board.TEXT.remove, nil, "ANCHOR_TOP")
    Head(board, panel, panel.close)
    panel.title = panel.head:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    panel.title:SetPoint("LEFT", Board.EDGE - Board.BAND + 4, 0)
    panel.title:SetText(spec.title or "")
    local line = Core.Look.Line(panel, 0.5)
    line:SetPoint("TOPLEFT", Board.EDGE, -Board.HEAD)
    line:SetPoint("TOPRIGHT", -Board.EDGE, -Board.HEAD)
    panel.body = CreateFrame("Frame", nil, panel)
    panel.body:SetPoint("TOPLEFT", 0, -Board.HEAD)
    panel.body:SetPoint("BOTTOMRIGHT")
    panel.close:SetFrameLevel(panel.body:GetFrameLevel() + 20) -- over what the module puts in its body, as the doll's
end

-- Bare (spec.dress = "bare"): no frame, the module draws its own window. A head along its top to drag it by, its
-- title in the game's gold and the game's own X at its right, which the module may move onto what it draws; its
-- body the whole panel.
local function Bare(board, panel, spec)
    panel.skin = { Rest = function() end }
    panel.body = CreateFrame("Frame", nil, panel)
    panel.body:SetAllPoints()
    panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButtonNoScripts")
    panel.close:SetPoint("TOPRIGHT")
    panel.close:SetFrameLevel(panel.body:GetFrameLevel() + 21)
    panel.close:SetScript("OnClick", function() Core.Safe(Label(board), board.Remove, board, panel.key) end)
    Core.Tip(panel.close, Board.TEXT.remove, nil, "ANCHOR_TOP")
    Head(board, panel, panel.close)
    panel.head:ClearAllPoints()
    panel.head:SetPoint("TOPLEFT")
    panel.head:SetPoint("RIGHT", panel.close, "LEFT")
    panel.head:SetFrameLevel(panel.body:GetFrameLevel() + 20)
    panel.title = panel.head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("CENTER")
    panel.title:SetText(spec.title or "")
end

-- A window's panel in what the window holds: the kit's bronze, or none when its spec asks for that (spec.dress
-- "bare"); a head with its title and the X; under that, its body. Built once for a spec (board.made).
local function Panel(board, spec)
    local panel = board.panels[spec.key]
    if panel and panel.spec == spec then return panel end
    -- Another window took that key (Board.Offer, Withdraw): the one before is told it is hidden, and what it built
    -- goes out of sight with its panel; the new one has its own panel again if it had one, else one built for it.
    if panel and panel:IsShown() then
        panel:Hide()
        if panel.spec.show then Core.Safe(Label(board), panel.spec.show, panel, false) end
    end
    panel = board.made[spec]
    if panel then
        board.panels[spec.key] = panel
        return panel
    end
    local inside = board.inside
    panel = CreateFrame("Frame", nil, inside)
    panel:SetFrameLevel(inside:GetFrameLevel() + Board.LEVEL)
    panel.key, panel.spec, panel.board = spec.key, spec, board
    if spec.dress == "bare" then
        Bare(board, panel, spec)
    else
        Plate(board, panel, spec)
    end
    panel.fade = Core.Motion.Fade(panel)
    panel:Hide()
    board.panels[spec.key], board.made[spec] = panel, panel
    if spec.build then Core.Safe(Label(board), spec.build, panel) end
    return panel
end

-- One panel at its place (a rect of Board.Lay), shown; or hidden (nil).
local function Put(board, panel, rect)
    local spec = panel.spec
    if not rect then
        if panel:IsShown() then
            panel:Hide()
            if spec.show then Core.Safe(Label(board), spec.show, panel, false) end
        end
        return
    end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", board.inside, "TOPLEFT", rect[1], -rect[2])
    panel:SetSize(rect[3], rect[4])
    panel.skin:Rest()
    if spec.size then Core.Safe(Label(board), spec.size, panel, rect[3], rect[4]) end
    if panel:IsShown() then return end
    panel:Show()
    local animations = not (Core.general and Core.general.animations == false)
    panel.fade:To(1, animations and Board.FADE or 0, 0)
    if spec.show then Core.Safe(Label(board), spec.show, panel, true) end
    if spec.search then Core.Safe(Label(board), spec.search, panel, board.search or "") end
end

-- A strip over the gap between two neighbours that takes the mouse, a line in its middle while the mouse is on it.
local function Strip(board)
    local strip = CreateFrame("Frame", nil, board.inside)
    strip:SetFrameLevel(board.inside:GetFrameLevel() + Board.LEVEL + 20)
    strip:EnableMouse(true)
    strip.line = strip:CreateTexture(nil, "OVERLAY")
    strip.line:SetColorTexture(Core.Look.LINE[1], Core.Look.LINE[2], Core.Look.LINE[3], 1)
    strip.line:SetAlpha(0)
    strip:SetScript("OnEnter", Core.Guard("board", function(self)
        SetCursor("UI_RESIZE_CURSOR")
        self.line:SetAlpha(0.9)
    end))
    strip:SetScript("OnLeave", Core.Guard("board", function(self)
        if held and held.strip == self then return end
        SetCursor(nil)
        self.line:SetAlpha(0)
    end))
    strip:SetScript("OnMouseDown", Core.Guard("board", function(self, button)
        if button ~= "LeftButton" or held or not self.of then return end
        held = { board = board, line = self.of, strip = self }
        Watching(true)
    end))
    strip:SetScript("OnMouseUp", function() Core.Safe("board", Release, false) end)
    strip:SetScript("OnHide", Core.Guard("board", function(self)
        if held and held.strip == self then Release(true) end
    end))
    return strip
end

local function Lines(board)
    board.strips = board.strips or Core.Pool(function() return Strip(board) end)
    local strips = board.strips
    strips:Begin()
    for _, line in ipairs(board.lines) do
        local strip = strips:Take()
        strip.of = line
        strip:ClearAllPoints()
        strip:SetPoint("TOPLEFT", board.inside, "TOPLEFT", line[3], -line[4])
        strip:SetSize(line[5], line[6])
        strip.line:ClearAllPoints()
        if line[1].split == "x" then
            strip.line:SetPoint("TOP")
            strip.line:SetPoint("BOTTOM")
            strip.line:SetWidth(2)
        else
            strip.line:SetPoint("LEFT")
            strip.line:SetPoint("RIGHT")
            strip.line:SetHeight(2)
        end
        strip:Show()
    end
    strips:Done()
end

-------------------------------------------------------------------------------
--  The tabs and the dropdown, in the window's title bar
-------------------------------------------------------------------------------
-- A layout's tab chosen; during a talk, the talk's layout set aside for it (even the tab chosen before).
local function Choose(board, index)
    local kept = Kept(board)
    local talking = Occasion(board) ~= nil
    if not kept.tabs[index] or (index == kept.chosen and not talking) then return end
    if talking then board.aside = true end
    kept.chosen = index
    Core.Sound("IG_CHARACTER_INFO_TAB")
    if board.options.changed then Core.Safe(Label(board), board.options.changed) end
end

local function New(board)
    local kept = Kept(board)
    kept.tabs[#kept.tabs + 1] = { name = Board.TEXT.new:format(#kept.tabs + 1), tree = false }
    Choose(board, #kept.tabs)
end

-- A right click on a tab: rename it, reset the first, delete any while another is left.
local function TabMenu(board, owner, index)
    local kept = Kept(board)
    local tab = kept.tabs[index]
    if not tab then return end
    MenuUtil.CreateContextMenu(owner, Core.Guard("board", function(_, root)
        root:CreateTitle(Name(index, tab))
        root:CreateButton(Board.TEXT.rename, Core.Guard("board", function()
            Core.AskText(Board.TEXT.renameAsk, nil, Board.TEXT.accept, Name(index, tab), function(text)
                text = type(text) == "string" and text:match("^%s*(.-)%s*$") or ""
                if text ~= "" then tab.name = text end
                if board.standing then board:Show(board.inside, board.width, board.height) end
            end, 32)
        end))
        if index == 1 then
            root:CreateButton(Board.TEXT.reset, Core.Guard("board", function()
                Core.Confirm(Board.TEXT.resetAsk, Name(index, tab), function()
                    tab.tree = nil
                    if board.options.changed then Core.Safe(Label(board), board.options.changed) end
                end)
            end))
        end
        if #kept.tabs > 1 then
            root:CreateButton(Board.TEXT.delete, Core.Guard("board", function()
                Core.Confirm(Board.TEXT.deleteAsk, Name(index, tab), function()
                    table.remove(kept.tabs, index)
                    if kept.chosen >= index then kept.chosen = math.max(kept.chosen - 1, 1) end
                    if board.options.changed then Core.Safe(Label(board), board.options.changed) end
                end, true)
            end))
        end
    end))
end

-- The talk's tab: a click brings its layout back while it was set aside; a right click resets it.
local function Talk(board, owner, button)
    local name = board.occasion
    local occasion = name and board.options.occasions and board.options.occasions[name]
    if not occasion then return end
    if button ~= "RightButton" then
        if not board.aside then return end
        board.aside = false
        Core.Sound("IG_CHARACTER_INFO_TAB")
        if board.options.changed then Core.Safe(Label(board), board.options.changed) end
        return
    end
    MenuUtil.CreateContextMenu(owner, Core.Guard("board", function(_, root)
        root:CreateTitle(occasion.title or name)
        root:CreateButton(Board.TEXT.reset, Core.Guard("board", function()
            Core.Confirm(Board.TEXT.resetAsk, occasion.title or name, function()
                local kept = Kept(board)
                if kept.occasions then kept.occasions[name] = nil end
                if board.options.changed then Core.Safe(Label(board), board.options.changed) end
            end)
        end))
    end))
end

-- A tab of the top bar (Core.Look.Tab: the character screen's), as high as the title bar.
local function Tab(board, strip)
    local tab = Core.Look.Tab(strip, strip:GetHeight())
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tab:SetScript("OnClick", Core.Guard("board", function(self, button)
        if self.talk then return Talk(board, self, button) end
        if self.plus then return New(board) end
        if button == "RightButton" then return TabMenu(board, self, self.index) end
        Choose(board, self.index)
    end))
    Core.Tip(tab, function() return not tab.plus and tab.Text:GetText() or nil end,
        function()
            if tab.talk then return Board.TEXT.talkTip end
            return not tab.plus and Board.TEXT.tabTip or nil
        end, "ANCHOR_BOTTOM")
    return tab
end

-- A window's tab of its own: its icon, lit while the window is in the layout; a click puts it in or takes it off.
local function IconTab(board, strip)
    local tab = Core.Look.Tab(strip, strip:GetHeight())
    tab:SetWidth(Board.ICON + Board.ICON_PAD)
    tab.Text:SetText("")
    tab.icon = tab:CreateTexture(nil, "ARTWORK")
    tab.icon:SetSize(Board.ICON, Board.ICON)
    tab:SetScript("OnClick", Core.Guard("board", function(self)
        Core.Sound("IG_CHARACTER_INFO_TAB")
        board:Toggle(self.key)
    end))
    Core.Tip(tab, function() return tab.spec and (tab.spec.title or tab.spec.key) end, nil, "ANCHOR_BOTTOM")
    return tab
end

-- A window's icon drawn in its tab: a texture or file ID (with its coordinates), or the window's own drawing.
local function Icon(tab, spec)
    local icon = tab.icon
    icon:SetTexCoord(0, 1, 0, 1)
    if type(spec.icon) == "function" then
        Core.Safe("board", spec.icon, icon)
    else
        icon:SetTexture(spec.icon)
        if spec.coords then icon:SetTexCoord(unpack(spec.coords)) end
    end
end

-- The tabs after the title: one for each layout, the chosen one marked, then +, then a tab for each window that
-- has an icon, lit while it is in the layout. Out of sight while the search box lies over the title bar.
local function Tabs(board, on)
    local window, strip = board.window, board.strip
    if not on then
        if strip then strip:Hide() end
        return
    end
    local bar = window.bar
    if not bar then return end
    if not strip then
        strip = CreateFrame("Frame", nil, bar)
        strip:SetFrameLevel(bar:GetFrameLevel() + 2)
        strip:SetPoint("TOPLEFT", bar.find, "TOPRIGHT", Board.TAB_OVER, 0)
        strip:SetPoint("BOTTOMLEFT", bar.find, "BOTTOMRIGHT", Board.TAB_OVER, 0)
        strip:SetHeight(bar:GetHeight())
        strip.tabs = Core.Pool(function() return Tab(board, strip) end)
        board.strip = strip
        if bar.box then
            bar.box:HookScript("OnShow", Core.Guard("board", function() strip:Hide() end))
            bar.box:HookScript("OnHide", Core.Guard("board", function() strip:SetShown(board.standing or false) end))
        end
    end
    local kept, tabs = Kept(board), strip.tabs
    local talking = Occasion(board) ~= nil
    local high = bar:GetHeight()
    tabs:Begin()
    local previous, width, placed = nil, 0, {}
    local function Place(tab, text, index, talk)
        tab.index, tab.talk, tab.plus = index, talk, index == nil and not talk
        tab.Text:SetWidth(0)
        tab.Text:SetText(text)
        tab:SetWidth((tab.Text:GetStringWidth() or 0) + Board.TAB_PAD)
        if tab.SetSelected then
            if talk then tab:SetSelected(talking) else tab:SetSelected(not talking and index == kept.chosen) end
        end
        tab:SetHeight(high)
        tab:ClearAllPoints()
        if previous then tab:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT") else tab:SetPoint("BOTTOMLEFT") end
        tab:Show()
        width = width + tab:GetWidth()
        previous = tab
        placed[#placed + 1] = tab
    end
    -- One bar of them, as the character screen's: the first's and the last's pictures its ends.
    local function Ends(list)
        for index, tab in ipairs(list) do tab:SetEnd(index == 1, index == #list) end
    end
    -- A talk on (set aside or not): its tab first.
    local name = board.occasion
    local occasion = name and type(board.options.occasions) == "table" and board.options.occasions[name]
    if type(occasion) == "table" then Place(tabs:Take(), occasion.title or name, nil, name) end
    for index, layout in ipairs(kept.tabs) do Place(tabs:Take(), Name(index, layout), index) end
    local plus = tabs:Take()
    Place(plus, "+", nil)
    if not plus.tipped then
        plus.tipped = true
        Core.Tip(plus, function() return plus.plus and Board.TEXT.add or nil end, function() return plus.plus and Board.TEXT.addTip or nil end, "ANCHOR_BOTTOM")
    end
    tabs:Done()
    Ends(placed)
    strip.icons = strip.icons or Core.Pool(function() return IconTab(board, strip) end)
    local icons = strip.icons
    icons:Begin()
    local gap, lit = Board.ICON_GAP + 2 * Board.TAB_OVER, {}
    for _, spec in ipairs((Specs(board))) do
        if spec.icon then
            local tab = icons:Take()
            tab.key, tab.spec = spec.key, spec
            Icon(tab, spec)
            local on = Board.Holds(board.tree, spec.key)
            tab:SetHeight(high)
            tab:SetSelected(on)
            tab.icon:ClearAllPoints()
            tab.icon:SetPoint("CENTER", 0, on and 2 or 1)
            tab.icon:SetDesaturation(on and 0 or 0.6)
            tab:ClearAllPoints()
            tab:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT", gap, 0)
            tab:Show()
            width = width + gap + tab:GetWidth()
            previous, gap = tab, 0
            lit[#lit + 1] = tab
        end
    end
    icons:Done()
    Ends(lit)
    if #lit > 0 then width = width + Board.TAB_OVER end
    strip:SetWidth(math.max(width, 1))
    strip:SetShown(not (bar.box and bar.box:IsShown()))
end

-- The dropdown Windows: a tick for each window the module can show, ticked where it is in the layout chosen.
local function Menu(board, on)
    local window, menu = board.window, board.menu
    if not on then
        if menu then
            if menu.CloseMenu then menu:CloseMenu() end
            menu:Hide()
        end
        return
    end
    if not menu then
        menu = CreateFrame("DropdownButton", nil, window.frame, "WowStyle1DropdownTemplate")
        menu:SetWidth(Board.MENU_WIDTH)
        menu:SetFrameLevel(window.frame:GetFrameLevel() + 50)
        menu:OverrideText(Board.TEXT.windows)
        menu:SetupMenu(Core.Guard("board", function(_, root)
            local list = Specs(board)
            for _, spec in ipairs(list) do
                root:CreateCheckbox(spec.title or spec.key,
                    Core.Guard("board", function() return Board.Holds(board.tree, spec.key) end),
                    Core.Guard("board", function() board:Toggle(spec.key) end))
            end
        end))
        board.menu = menu
    end
    local classic, buttons = window.edge and window.edge.classic, window.buttons
    menu:ClearAllPoints()
    if classic and classic:IsShown() then
        menu:SetPoint("RIGHT", classic, "LEFT", -Board.EDGE, 0)
    elseif buttons and buttons:IsShown() and buttons.first then
        menu:SetPoint("RIGHT", buttons.first, "LEFT", -10, 0)
    else
        menu:SetPoint("TOPRIGHT", -10, -4)
    end
    menu:Show()
end

-------------------------------------------------------------------------------
--  What a module calls
-------------------------------------------------------------------------------
local boards = {} -- [label] = the board made under that label

function Board.New(window, options)
    local board = setmetatable({ window = window, options = options, panels = {}, rects = {}, lines = {},
        made = {} }, meta) -- made[spec] = its panel, kept for the session: a spec that returns gets its panel back
    window.board = board -- the title bar ends its search box left of the dropdown (Window.lua)
    if type(options.label) == "string" then boards[options.label] = board end
    return board
end

-- What a board is offered changed, or what a window offered to it wants: one that stands lays out anew.
function Board.Told(label)
    local board = boards[label]
    if board and board.standing and board.options.changed then Core.Safe(Label(board), board.options.changed) end
end

-- A window of one module on another module's board (a module depends on Core only: the guild's window, the module
-- Guild's, on Social's full screen). label: the board's (Board.New's label, "Social"); spec as a module's own. One
-- with the key of a window of the board's module stands in its place: that module asks Offered and leaves its own
-- be. Offered again with the same key, it is replaced. A board that stands lays out anew.
function Board.Offer(label, spec)
    if type(label) ~= "string" or type(spec) ~= "table" or type(spec.key) ~= "string" then return end
    local list = offered[label] or {}
    offered[label] = list
    for index, other in ipairs(list) do
        if other.key == spec.key then
            if other == spec then return end
            list[index] = spec
            return Board.Told(label)
        end
    end
    list[#list + 1] = spec
    Board.Told(label)
end

-- That window offered no more (its module stood down, or its window stands elsewhere now): the board's own of that
-- key, if it has one, stands in its place again.
function Board.Withdraw(label, key)
    local list = offered[label]
    if not list then return end
    for index, spec in ipairs(list) do
        if spec.key == key then
            table.remove(list, index)
            return Board.Told(label)
        end
    end
end

-- The window another module offers that board under that key, or nil.
function Board.Offered(label, key)
    for _, spec in ipairs(offered[label] or {}) do
        if spec.key == key then return spec end
    end
    return nil
end

-- That board's full screen, with that window in its layout: true when it stands or is on its way. Its window fills
-- the screen (its edge, Edge.lua), only while it is shown; a window the layout chosen lacks is put in beside the
-- largest once it stands. False when there is no such board, or its full screen cannot come now (its window
-- closed, Edit Mode, Can expand to fullscreen off): the caller shows that window elsewhere.
function Board.Open(label, key)
    local board = boards[label]
    if not board then return false end
    if board.standing then
        if key and not board:Has(key) then board:Toggle(key) end
        return true
    end
    local window = board.window
    local edge, frame = window and window.edge, window and window.frame
    if not (edge and edge.Fill) or (frame and not frame:IsShown()) then return false end
    board.wanted = key
    Core.Safe(Label(board), edge.Fill, edge, true)
    if edge.full then return true end
    board.wanted = nil
    return false
end

-- Whether that board's full screen stands now.
function Board.Standing(label)
    local board = boards[label]
    return board ~= nil and board.standing == true
end

-- That board's full screen goes back.
function Board.Close(label)
    local board = boards[label]
    local edge = board and board.window and board.window.edge
    if board and board.standing and edge and edge.Fill then Core.Safe(Label(board), edge.Fill, edge, false) end
end

-- The window stands full: what it holds (inside) is that wide and high. Each window of the layout chosen that has
-- something to show is put at its place, the others hidden; the lines between them, the tabs and the dropdown
-- come. Returns where each stands: [key] = { left, top, width, height } from inside's top left.
function methods:Show(inside, width, height)
    if held then Release(true) end
    self.inside, self.width, self.height, self.standing = inside, math.floor(width), math.floor(height), true
    local list, specs = Specs(self)
    self.specs = specs
    local tab, index, occasion = Chosen(self)
    local tree = tab.tree
    if tree == nil and occasion then
        tree = type(occasion.default) == "function" and Core.Safe(Label(self), occasion.default, self.width, self.height) or nil
    elseif tree == nil and index == 1 then
        tree = Core.Safe(Label(self), self.options.default, self.width, self.height)
    end
    self.tree = Tidy(Copy(tree)) -- its shares each a part of one (a module's default may give sizes); false: empty
    local function here(key)
        local spec = specs[key]
        if not spec then return false end
        return not spec.present or Core.Safe(Label(self), spec.present) == true
    end
    local shown = self.tree and Present(self.tree, here)
    local pad = Board.PAD
    self.rects, self.lines = Board.Lay(shown, pad, pad, self.width - 2 * pad, self.height - 2 * pad, pad, nil, nil,
                                       function(key) return Fitted(self, key) end)
    for key, panel in pairs(self.panels) do
        if not self.rects[key] then Put(self, panel, nil) end
    end
    for _, spec in ipairs(list) do
        local rect = self.rects[spec.key]
        if rect then Put(self, Panel(self, spec), rect) end
    end
    Lines(self)
    if not self.hint then
        self.hint = inside:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
        self.hint:SetPoint("CENTER")
        self.hint:SetText(Board.TEXT.empty)
    end
    self.hint:SetShown(shown == nil)
    Tabs(self, true)
    Menu(self, true)
    self.window:Refresh() -- the search box ends left of the dropdown
    -- Opened for a window the layout lacks (Board.Open): put in, once this laying out is over.
    local wanted = self.wanted
    if wanted then
        self.wanted = nil
        if specs[wanted] and not Board.Holds(self.tree, wanted) then
            Core.Later(function() if self.standing and not Board.Holds(self.tree, wanted) then self:Toggle(wanted) end end)()
        end
    end
    return self.rects
end

-- The window starts back: every panel out of sight, nothing held, the tabs and the dropdown gone.
function methods:Hide()
    if held and held.board == self then Release(true) end
    self.standing = false
    for _, panel in pairs(self.panels) do Put(self, panel, nil) end
    if self.strips then self.strips:Reset() end
    if self.hint then self.hint:Hide() end
    Tabs(self, false)
    Menu(self, false)
end

function methods:Search(text)
    self.search = text or ""
    for _, panel in pairs(self.panels) do
        if panel:IsShown() and panel.spec.search then Core.Safe(Label(self), panel.spec.search, panel, self.search) end
    end
end

function methods:Has(key)
    return Board.Holds(self.tree, key)
end

-- Held by its head: the panel is lifted (see-through), and a tinted shape shows where it would go.
function methods:Lift(panel)
    if held or not self.standing then return end
    held = { board = self, panel = panel }
    panel:SetAlpha(0.6)
    Watching(true)
end

-- Its X: off the layout, the others take its room.
function methods:Remove(key)
    if not self.standing then return end
    Keep(self, Board.Without(Copy(self.tree), key))
end

-- Ticked in the dropdown: into the layout chosen, sharing the room of the largest window there (side by side where
-- that one is wider than high); unticked: off it.
function methods:Toggle(key)
    if not self.standing then return end
    if Board.Holds(self.tree, key) then return self:Remove(key) end
    local largest, area
    for other, rect in pairs(self.rects) do
        if not area or rect[3] * rect[4] > area then largest, area = other, rect[3] * rect[4] end
    end
    local rect = largest and self.rects[largest]
    Keep(self, Board.Beside(Copy(self.tree), key, largest, rect and (rect[3] >= rect[4] and "right" or "bottom") or "right"))
end

-- A talk began (name: one of options.occasions; an unknown one counts as none) or ended (nil): its layout stands while
-- it is on, not set aside. A board that stands lays out anew.
function methods:Occasion(name)
    local occasions = self.options.occasions
    if name ~= nil and not (type(occasions) == "table" and type(occasions[name]) == "table") then name = nil end
    if name == self.occasion then return end
    self.occasion, self.aside = name, false
    if self.standing and self.options.changed then Core.Safe(Label(self), self.options.changed) end
end

-- The talk whose layout stands now, or nil (none, or set aside by another tab).
function methods:Talking()
    return (Occasion(self))
end

-- A window that is no more: out of every layout.
function methods:Forget(key)
    local kept = Kept(self)
    for _, tab in ipairs(kept.tabs) do
        if type(tab.tree) == "table" then tab.tree = Board.Without(Copy(tab.tree), key) or false end
    end
    for _, tab in pairs(kept.occasions or {}) do
        if type(tab) == "table" and type(tab.tree) == "table" then tab.tree = Board.Without(Copy(tab.tree), key) or false end
    end
    local panel = self.panels[key]
    if panel then Put(self, panel, nil) end
end
