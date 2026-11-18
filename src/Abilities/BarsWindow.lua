local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - BarsWindow
--  The game's action bars as windows of the full screen, so that no other window
--  lies over them and something can be dragged onto them there: the parts bars
--  (the wide ones) and sidebars (the tall ones, in a narrow window of their own: a
--  tall bar in a strip would be too small to drop on). Each bar that shows is
--  seated in its panel's body (Core.Seat: its place, scale and layer lent, given
--  back when the full screen goes): the bars stay the game's own, their keys and
--  buttons work as ever. The wide ones stand as they stand on the screen, stacked
--  as you put them (Saneroki, 2026-11-04: "directly stacked like they are in the
--  not fullscreen view"), the whole in the panel's middle; the tall ones side by
--  side, and the wide ones too where a bar's place on the screen is not known: in
--  lines from the left. Either at the largest scale, at most their own, at which
--  all of them fit.
--
--  Every bar switched on in the game's options stands there (Saneroki,
--  2026-11-09), one that Edit Mode shows only in a fight or never too, so it can
--  be filled: the game's own Show while it is seated (out of a fight), its own
--  Hide again when it goes, where the game's setting still hides it. What the
--  game or a module puts beside a bar, out of its layout (Bar 1's page number and
--  arrows, the checkbox of a paged bar: ignoreInLayout), has its room beside it.
--
--  Each window is as large as its bars (Saneroki, 2026-11-09: "its height and
--  width should always be the same height to just show the amount of content to
--  fit"): Part.Fit gives Core's board the bars' room at their own size, so the
--  window above or below takes the rest of the column and the room beside it
--  stays empty; a window that does not fit the screen makes them smaller as before.
--
--  While seated every button shows, an empty one too, and every icon at full
--  brightness (ActionBars.lua, Seated). In a fight nothing is moved: bars seated
--  stay, and go back when it is over.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
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
local homes = {}      -- [seat] = { left, top }: where its bar stands on the screen, read while it is not seated
local panels = {}     -- [the part's key] = { body, shown, tall, relay }
local shown = {}      -- [the game's bar] = true: switched on but hidden by the game's setting, shown while seated

local function SeatOf(frame, relay)
    local seat = seats[frame]
    if not seat then
        seat = Core.Seat.New(frame, { label = "Abilities: action bars", sized = function() relay() end,
                                      gone = function() relay() end })
        seats[frame] = seat
    end
    return seat
end

-- Where a bar stands on the screen, its top left in UIParent's units: read while it is not seated, kept while it is.
local function Home(seat)
    if seat.held then return homes[seat] end
    local frame = seat.frame
    local left, top = Plain(frame:GetLeft()), Plain(frame:GetTop())
    if not (left and top) then
        homes[seat] = nil
        return nil
    end
    local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    homes[seat] = { left * ratio, top * ratio }
    return homes[seat]
end

-- How far what stands beside a bar out of its layout reaches past its left, right, top and bottom edge, in the bar's
-- own units (the same seated or not: it scales with the bar).
local function Beyond(frame)
    local scale = Plain(frame:GetEffectiveScale()) or 1
    local left, right = Plain(frame:GetLeft()), Plain(frame:GetRight())
    local top, bottom = Plain(frame:GetTop()), Plain(frame:GetBottom())
    local reach = { 0, 0, 0, 0 }
    if not (left and right and top and bottom) or scale <= 0 then return reach end
    for _, child in ipairs({ frame:GetChildren() }) do
        if rawget(child, "ignoreInLayout") and Plain(child:IsShown()) then
            local own = Plain(child:GetEffectiveScale()) or scale
            local l, r, t, b = Plain(child:GetLeft()), Plain(child:GetRight()), Plain(child:GetTop()), Plain(child:GetBottom())
            if l and r and t and b then
                reach[1] = math.max(reach[1], left * scale - l * own)
                reach[2] = math.max(reach[2], r * own - right * scale)
                reach[3] = math.max(reach[3], t * own - top * scale)
                reach[4] = math.max(reach[4], bottom * scale - b * own)
            end
        end
    end
    for index = 1, 4 do reach[index] = reach[index] / scale end
    return reach
end

-- The room beside a bar in UIParent's units at its own size (width: its own, in those units).
local function Pad(frame, width)
    local own = Plain(frame:GetWidth())
    local reach = Beyond(frame)
    if not own or own <= 0 then return { 0, 0, 0, 0 } end
    local unit = width / own
    return { reach[1] * unit, reach[2] * unit, reach[3] * unit, reach[4] * unit }
end

local NONE = { 0, 0, 0, 0 }
local function PadOf(entry)
    return entry.pad or NONE
end

-- The bars that show of one kind (tall or wide), with their sizes and places on the screen in UIParent's units. A bar
-- counts while it is switched on: the game's IsShown says so even while its setting hides it (Edit Mode's visibility).
local function Entries(tall, relay)
    local list = {}
    for _, frame in ipairs(ns.ActionBars.Frames()) do
        if Plain(frame:IsShown()) then
            local seat = SeatOf(frame, relay)
            local width, height = seat:Size()
            if width > 0 and height > 0 and (height > width) == tall then
                list[#list + 1] = { seat = seat, width = width, height = height, home = Home(seat), pad = Pad(frame, width) }
            end
        end
    end
    return list
end

-- The room the bars take as they stand on the screen, with what stands beside them: its left and top, width and
-- height; nil where a bar's place is not known.
local function Box(list)
    local left, top, right, bottom
    for _, entry in ipairs(list) do
        local home, pad = entry.home, PadOf(entry)
        if not home then return nil end
        local l, t = home[1] - pad[1], home[2] + pad[3]
        local r, b = home[1] + entry.width + pad[2], home[2] - entry.height - pad[4]
        left, top = math.min(left or l, l), math.max(top or t, t)
        right, bottom = math.max(right or r, r), math.min(bottom or b, b)
    end
    if not left then return nil end
    return left, top, right - left, top - bottom
end

-- Where each bar stands as on the screen, the whole at the largest scale at which it fits (at most 1, at least the
-- least), in the room's middle: entry.x, entry.y from the room's top left. Returns the scale, or nil where a bar's
-- place on the screen is not known.
local function Arrange(list, across, high)
    local left, top, wide, tall = Box(list)
    if not left or wide <= 0 or tall <= 0 then return nil end
    local scale = math.max(math.min(1, across / wide, high / tall), Room.SMALLEST)
    local x, y = math.max((across - wide * scale) / 2, 0), math.max((high - tall * scale) / 2, 0)
    for _, entry in ipairs(list) do
        entry.x = x + (entry.home[1] - left) * scale
        entry.y = y + (top - entry.home[2]) * scale
    end
    return scale
end

-- Where each bar stands at that scale in a room that wide: entry.x, entry.y from its top left, in lines. Returns how
-- high they stand, whether every one fits across, and how wide the widest line is.
local function Flow(list, across, scale)
    local gap = Room.GAP
    local x, y, line, fits, widest = 0, 0, 0, true, 0
    for _, entry in ipairs(list) do
        local pad = PadOf(entry)
        local width = (pad[1] + entry.width + pad[2]) * scale
        if x > 0 and x + width > across then x, y, line = 0, y + line + gap, 0 end
        if width > across then fits = false end
        entry.x, entry.y = x + pad[1] * scale, y + pad[3] * scale
        widest = math.max(widest, x + width)
        x = x + width + gap
        line = math.max(line, (pad[3] + entry.height + pad[4]) * scale)
    end
    return y + line, fits, widest
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

-- How much room the bars take at their own size: as on the screen; else the tall ones side by side, the wide ones
-- one under the other. Nil without any.
local function Content(list, tall)
    if not list[1] then return nil end
    if not tall then
        local _, _, wide, high = Box(list)
        if wide then return wide, high end
    end
    local across = 0
    for _, entry in ipairs(list) do
        local pad = PadOf(entry)
        across = tall and across + pad[1] + entry.width + pad[2] + Room.GAP or math.max(across, pad[1] + entry.width + pad[2])
    end
    local high, _, wide = Flow(list, across, 1)
    return wide, high
end

-- A bar switched on that the game's setting hides (in a fight only, or never): the game's own Show while it is seated.
local function Reveal(frame)
    local isShown, show = rawget(frame, "IsShownBase"), rawget(frame, "ShowBase")
    if type(isShown) ~= "function" or type(show) ~= "function" or Core.Locked(frame) then return end
    if Plain(isShown(frame)) ~= false then return end
    show(frame)
    shown[frame] = true
    return true
end

-- Whether the game's setting hides that bar now, as its own UpdateVisibility asks (read only).
local function SettingHides(frame)
    local visibility = rawget(frame, "visibility")
    if not visibility or visibility == "Always" then return false end
    if (tonumber(rawget(frame, "showAllButtons")) or 0) > 0 or Core.EditMode.active then return false end
    if visibility == "Hidden" then return true end
    local fighting = Core.Ask(UnitAffectingCombat, "player") == true
    if visibility == "InCombat" then return not fighting end
    if visibility == "OutOfCombat" then return fighting end
    return false
end

-- Out of the full screen: hidden again where the game's setting still hides it (once a fight is over).
local function Conceal(frame)
    local isShown, hide = rawget(frame, "IsShownBase"), rawget(frame, "HideBase")
    if type(isShown) ~= "function" or type(hide) ~= "function" then return end
    if Plain(isShown(frame)) and SettingHides(frame) then hide(frame) end
end

local function Lay(panel)
    local body = panel.body
    if not (panel.shown and body) then return end
    local left, top = body:GetLeft(), body:GetTop()
    if not (left and top) then return end
    local ratio = body:GetEffectiveScale() / UIParent:GetEffectiveScale()
    left, top = left * ratio, top * ratio
    local list = Entries(panel.tall, panel.relay)
    local revealed = false
    for _, entry in ipairs(list) do revealed = Reveal(entry.seat.frame) or revealed end
    if revealed then list = Entries(panel.tall, panel.relay) end -- their places, now that they show
    local across, high = body:GetWidth() * ratio, body:GetHeight() * ratio
    local scale = not panel.tall and Arrange(list, across, high) or Fit(list, across, high)
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
    for frame in pairs(shown) do
        shown[frame] = nil
        Core.AfterCombat("Abilities: action bars, " .. tostring(frame:GetName() or frame), Conceal, frame)
    end
    return true
end

-- How high the wide bars' window wants to be on a screen that wide and high, for the first layout; at most most
-- (else its share of the screen's height).
function Room.Wants(width, height, most)
    local edge, head = Core.Board.EDGE, Core.Board.HEAD
    local list = Entries(false, panels.bars.relay)
    local _, _, _, tall = Box(list)
    local wanted = (tall or Flow(list, (width or 1000) - 2 * edge, 1)) + head + 2 * edge
    return math.max(math.min(wanted, most or (height or 700) * Room.MOST_SHARE), Room.FIRST)
end

-- How wide the tall bars' window wants to be, for the first layout.
function Room.Side()
    local across = 0
    for _, entry in ipairs(Entries(true, panels.sidebars.relay)) do
        local pad = PadOf(entry)
        across = across + pad[1] + entry.width + pad[2] + Room.GAP
    end
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
    -- Its panel as large as its bars at their own size, with its head and edges.
    function part.Fit()
        local wide, high = Content(Entries(tall, panel.relay), tall)
        if not wide then return nil end
        local edge = Core.Board.EDGE
        return { wide + 2 * edge, high + Core.Board.HEAD + 2 * edge }
    end
    if tall then
        function part.Present()
            return Entries(true, panel.relay)[1] ~= nil
        end
    end
    ns.Board.Part(key, title, least, part)
end

-- For the test.
Room.Fit, Room.Flow, Room.Arrange, Room.Content, Room.Beyond = Fit, Flow, Arrange, Content, Beyond

Part("bars", ns.TEXT.barsWindow, Room.LEAST, false)
Part("sidebars", ns.TEXT.sideBarsWindow, Room.LEAST_SIDE, true)
