local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - BarsWindow
--  The game's action bars as windows of the full screen, so that no other window
--  lies over them and something can be dragged onto them there: the parts bars
--  (the wide ones) and sidebars (the tall ones, in a narrow window of their own: a
--  tall bar in a strip would be too small to drop on). Each bar that shows is
--  seated in its panel's body (Core.Seat: its place, scale and layer lent, given
--  back when the full screen goes): the bars stay the game's own, their keys and
--  buttons work as ever. They stand in lines from the left at the largest scale,
--  at most their own, at which all of them fit.
--
--  While seated every button shows, an empty one too (ActionBars.lua, Seated). In
--  a fight nothing is moved: bars seated stay, and go back when it is over.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Room = {}
ns.BarsWindow = Room

Room.GAP = 6           -- between bars
Room.LEVEL = 30        -- how far above its panel they stand (over Core's panels)
Room.STEP = 0.05       -- from one scale tried to the next
Room.SMALLEST = 0.4    -- the least scale
Room.MOST_SHARE = 0.25 -- of the screen's height, the most the first layout gives the wide ones
Room.FIRST = 130       -- the least height the first layout gives them
Room.LEAST = { 300, 100 }
Room.LEAST_SIDE = { 90, 240 }

local seats = {}      -- [the game's bar] = its seat, once made
local panels = {}     -- [the part's key] = { body, shown, tall, relay }

local function SeatOf(frame, relay)
    local seat = seats[frame]
    if not seat then
        seat = Core.Seat.New(frame, { label = "Combat: action bars", sized = function() relay() end,
                                      gone = function() relay() end })
        seats[frame] = seat
    end
    return seat
end

-- The bars that show of one kind (tall or wide), with their sizes in UIParent's units.
local function Entries(tall, relay)
    local list = {}
    for _, frame in ipairs(ns.ActionBars.Frames()) do
        if Core.Plain(frame:IsShown()) then
            local seat = SeatOf(frame, relay)
            local width, height = seat:Size()
            if width > 0 and height > 0 and (height > width) == tall then
                list[#list + 1] = { seat = seat, width = width, height = height }
            end
        end
    end
    return list
end

-- Where each bar stands at that scale in a room that wide: entry.x, entry.y from its top left, in lines. Returns how
-- high they stand, and whether every one fits across.
local function Flow(list, across, scale)
    local gap = Room.GAP
    local x, y, line, fits = 0, 0, 0, true
    for _, entry in ipairs(list) do
        local width = entry.width * scale
        if x > 0 and x + width > across then x, y, line = 0, y + line + gap, 0 end
        if width > across then fits = false end
        entry.x, entry.y = x, y
        x = x + width + gap
        line = math.max(line, entry.height * scale)
    end
    return y + line, fits
end

-- The largest scale at which they fit.
local function Fit(list, across, high)
    local scale = 1
    while scale > Room.SMALLEST do
        local height, fits = Flow(list, across, scale)
        if fits and height <= high then return scale end
        scale = scale - Room.STEP
    end
    Flow(list, across, Room.SMALLEST)
    return Room.SMALLEST
end

local function Lay(panel)
    local body = panel.body
    if not (panel.shown and body) then return end
    local left, top = body:GetLeft(), body:GetTop()
    if not (left and top) then return end
    local ratio = body:GetEffectiveScale() / UIParent:GetEffectiveScale()
    left, top = left * ratio, top * ratio
    local list = Entries(panel.tall, panel.relay)
    local scale = Fit(list, body:GetWidth() * ratio, body:GetHeight() * ratio)
    local strata, level = body:GetFrameStrata(), body:GetFrameLevel() + Room.LEVEL
    for _, entry in ipairs(list) do
        entry.seat:Hold(left + entry.x, top - entry.y, entry.width * scale, entry.height * scale, strata, level)
    end
end

-- Every bar given back when neither window shows: at once, or when the fight is over.
local function Freed()
    for _, panel in pairs(panels) do
        if panel.shown then return false end
    end
    for _, seat in pairs(seats) do seat:Free() end
    return true
end

-- How high the wide bars' window wants to be on a screen that wide and high, for the first layout.
function Room.Wants(width, height)
    local edge, head = Core.Board.EDGE, Core.Board.HEAD
    local wanted = Flow(Entries(false, panels.bars.relay), (width or 1000) - 2 * edge, 1) + head + 2 * edge
    return math.max(math.min(wanted, (height or 700) * Room.MOST_SHARE), Room.FIRST)
end

-- How wide the tall bars' window wants to be, for the first layout.
function Room.Side()
    local across = 0
    for _, entry in ipairs(Entries(true, panels.sidebars.relay)) do across = across + entry.width + Room.GAP end
    return math.max(across + 2 * Core.Board.EDGE, Room.LEAST_SIDE[1])
end

-- One of the two parts on the board (Board.lua).
local function Part(key, title, least, tall)
    local panel = { tall = tall }
    panel.relay = Core.Later(function() ns.Safe("action bars", Lay, panel) end) -- once the panel stands where it goes
    panels[key] = panel
    local part = {}
    function part.Build(frame)
        panel.body = frame.body
    end
    function part.Show(on)
        panel.shown = on
        if on then
            ns.ActionBars.Seated(true)
            return panel.relay()
        end
        if Freed() then ns.ActionBars.Seated(false) end
    end
    function part.Size()
        panel.relay()
    end
    function part.Leave()
        panel.shown = false
        Freed()
    end
    if tall then
        function part.Present()
            return Entries(true, panel.relay)[1] ~= nil
        end
    end
    ns.Board.Part(key, title, least, part)
end

-- For the test.
Room.Fit, Room.Flow = Fit, Flow

Part("bars", ns.TEXT.barsWindow, Room.LEAST, false)
Part("sidebars", ns.TEXT.sideBarsWindow, Room.LEAST_SIDE, true)
