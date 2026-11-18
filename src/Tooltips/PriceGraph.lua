local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Tooltips - PriceGraph
--  How an item's price went at the auction house, at the end of its Gold section
--  while Alt is held (Kinds/Gold.lua asks for the row, Panel.lua gives it a place):
--
--      [24h] [1w] [2w] [1m] [All]         3s 20c    the ranges, the one on show lit; the highest price in it
--      ---------------------------------------
--                 /\        ___
--      __________/  \______/   \___                 the lowest price in gold, the market's in grey, over the time
--      ---------------------------------------
--      24 Oct                             1s 98c    where the range begins; the lowest price in it
--      Lowest  Market          Ctrl: next range
--
--  The points are Core's (Prices:Range): each stretch of time from whichever of the
--  account's auction file and the database is most current, last what the auction
--  house lists right now. Each is at its true place on the time line, so a stretch
--  without a scan is a straight line.
--
--  A tooltip goes as soon as the mouse leaves what it stands for, so the mouse can
--  never get to a button on it. So a tap of Ctrl while the graph is on show moves
--  the lit range on: a key that does nothing in the game by itself, told by an
--  ordinary event, so that it also works in a fight and takes no key from a binding.
--  Only the tooltip of a chat link stays: there the buttons are clicked as well.
--
--  Which range is on show is the option priceRange; a read of the tooltip costs a
--  look at Prices:Last, and the points are asked for only when the panel is drawn.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local PRICES = Core.Data.Series("Prices")
local Pools, Panel, COLOR, TEXT = ns.Pools or {}, ns.Panel or {}, ns.COLOR, ns.TEXT
local Text, Width, Place, Line, Rule, Stroke = Pools.Text, Pools.Width, Pools.Place, Pools.Line, Pools.Rule, Pools.Stroke
local FONTS = Panel.FONTS
local Graph = {}
ns.Graph = Graph

local DAY = 86400
-- The ranges in their order: how far back each goes. All: from the first price kept.
local RANGES = { { key = "24h", back = DAY }, { key = "1w", back = 7 * DAY }, { key = "2w", back = 14 * DAY },
    { key = "1m", back = 30 * DAY }, { key = "All" } }

Graph.WIDE = 240       -- the least a panel with a graph is wide: room for the buttons and a price beside them
local HIGH = 52        -- how high the lines' room is
local GAP = 3          -- between the graph's parts
local INSET = 5        -- a button's room at each side of its word
local BETWEEN = 2      -- between two buttons
local STEP = 3         -- a mark per so much of the width: what the eye can tell apart
local LOW_LINE, MARKET_LINE = 2, 1 -- how thick the two lines are
local MARGIN = 0.08    -- of the height left free above and under the prices
local LIT, UNLIT = 0.2, 0.08 -- how strongly a button's colour shows behind its word
local DATE = "%d %b"   -- where a range of days begins
local NONE = {}

local LOW, MARKET = COLOR.GOLD, COLOR.ASIDE
local xs, lows, markets = {}, {}, {} -- the marks of one draw: where each stands of the width, its prices
local redraw           -- reads the shown panels anew (Tooltips.lua)

-- A press of a button, or a tap of Ctrl: kept as the option, the shown panels read anew.
local function Choose(key)
    Core.Set(ns.name, "priceRange", key)
    if redraw then redraw() end
end

local function Back(key)
    for _, range in ipairs(RANGES) do
        if range.key == key then return range.back end
    end
    return nil
end

local function After(key)
    for index, range in ipairs(RANGES) do
        if range.key == key then return RANGES[index % #RANGES + 1].key end
    end
    return RANGES[1].key
end

-- The row, at the Gold section's end, of an item (its link or ID).
function Graph.Row(item)
    local row = ns.Reader.Row()
    row.kind, row.graph, row.range, row.stamp = "graph", item, ns.options.priceRange, PRICES:Stamp()
end

local function ButtonHeight()
    return FONTS.small.size + 4
end

-- How much room the graph takes, at this draw's sizes.
function Graph.Height()
    return ButtonHeight() + GAP + HIGH + GAP + FONTS.small.size + 2 + GAP + FONTS.hint.size + 2
end

local Clicked = ns.Guard(function(hit) Choose(hit.key) end)

-- What the mouse can press, on a tooltip the mouse can get to; made the first time one shows a graph.
local function Hit(panel, index, x, y, wide)
    panel.hits = panel.hits or {}
    local hit = panel.hits[index]
    if not hit then
        hit = CreateFrame("Button", nil, panel.front)
        hit.key = RANGES[index].key
        hit:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        hit:GetHighlightTexture():SetAlpha(UNLIT)
        hit:SetScript("OnClick", Clicked)
        panel.hits[index] = hit
    end
    hit:ClearAllPoints()
    hit:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
    hit:SetSize(wide, ButtonHeight())
    hit:Show()
end

local function Buttons(panel, row, x, y)
    local mouse = Plain(panel.tooltip:IsMouseEnabled())
    for index, range in ipairs(RANGES) do
        local on = range.key == row.range
        local color = on and LOW or MARKET
        local word = Text(panel, FONTS.small, range.key, color[1], color[2], color[3], "CENTER")
        local wide = Width(word) + 2 * INSET
        local plate = Line(panel, color[1], color[2], color[3], on and LIT or UNLIT)
        plate:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
        plate:SetSize(wide, ButtonHeight())
        Place(panel, word, x, y + 2, wide)
        if mouse then Hit(panel, index, x, y, wide) end
        x = x + wide + BETWEEN
    end
end

-- The prices of a range as marks, at most one per STEP of the width: where it stands, the lowest price and the last
-- market price that fall there. Returns how many, and the lowest and highest price of them all.
local function Marks(points, from, to, columns)
    local count, column, lowest, highest = 0, nil, nil, nil
    local span = math.max(to - from, 1)
    for _, point in ipairs(points) do
        local low, market = point.low, point.market
        if low > 0 or market > 0 then
            local at = math.floor((point.at - from) / span * columns)
            if at ~= column then
                column, count = at, count + 1
                xs[count], lows[count], markets[count] = at / columns, 0, 0
            end
            if low > 0 then
                if lows[count] == 0 or low < lows[count] then lows[count] = low end
                lowest, highest = math.min(lowest or low, low), math.max(highest or low, low)
            end
            if market > 0 then
                markets[count] = market
                lowest, highest = math.min(lowest or market, market), math.max(highest or market, market)
            end
        end
    end
    return count, lowest, highest
end

-- One of the two lines through its marks; a mark without that price is passed over.
local function Trace(panel, values, count, x, y, width, lowest, highest, thickness, color)
    local room = HIGH * (1 - 2 * MARGIN)
    local lastX, lastY
    for index = 1, count do
        local value = values[index]
        if value > 0 then
            local share = highest > lowest and (value - lowest) / (highest - lowest) or 0.5
            local markX, markY = x + xs[index] * width, y + HIGH * (1 - MARGIN) - share * room
            if lastX then Stroke(panel, lastX, lastY, markX, markY, thickness, color[1], color[2], color[3]) end
            lastX, lastY = markX, markY
        end
    end
end

-- A text in the graph's small words at the right of a row, as wide as it is; its left at the left.
local function Right(panel, kind, words, color, x, y, width)
    local label = Text(panel, kind, words, color[1], color[2], color[3], "RIGHT")
    local wide = math.min(Width(label), width)
    Place(panel, label, x + width - wide, y, wide)
end

-- Draws the graph at the place Panel.lua's laying gave it, if the panel has one.
function Graph.Draw(panel, width, hairline)
    for _, hit in ipairs(panel.hits or NONE) do hit:Hide() end
    local row = panel.graphRow
    if not row then return end
    local x, y = panel.graphX, panel.graphY
    Buttons(panel, row, x, y)
    local top = y + ButtonHeight() + GAP
    Rule(panel, x, top, width, hairline)
    Rule(panel, x, top + HIGH, width, hairline)

    local to = Ask(rawget(_G, "GetServerTime")) or 0
    local back = Back(row.range)
    local points = PRICES:Range(row.graph, back and to - back or nil, to)
    local from = back and to - back or (points[1] and points[1].at) or to
    local count, lowest, highest = Marks(points, from, to, math.floor(width / STEP))
    if count > 1 then
        Trace(panel, markets, count, x, top, width, lowest, highest, MARKET_LINE, MARKET)
        Trace(panel, lows, count, x, top, width, lowest, highest, LOW_LINE, LOW)
    else
        local note = COLOR.NOTE
        local words = Text(panel, FONTS.small, count == 1 and TEXT.GRAPH_ONE or TEXT.GRAPH_NONE, note[1], note[2], note[3], "CENTER")
        Place(panel, words, x, top + (HIGH - FONTS.small.size) / 2, width)
    end
    local detail = COLOR.ASIDE
    if highest then Right(panel, FONTS.small, ns.Gold.Money(highest), detail, x, y + 2, width) end

    local under = top + HIGH + GAP
    local start = points[1] and (back == DAY and Core.ClockAt(from) or date(DATE, from)) or ""
    Place(panel, Text(panel, FONTS.small, start, detail[1], detail[2], detail[3]), x, under, width / 2)
    if lowest then Right(panel, FONTS.small, ns.Gold.Money(lowest), detail, x, under, width) end

    local foot = under + FONTS.small.size + 2 + GAP
    local low = Text(panel, FONTS.hint, TEXT.GRAPH_LOW, LOW[1], LOW[2], LOW[3])
    local wide = Width(low)
    Place(panel, low, x, foot, wide)
    local market = Text(panel, FONTS.hint, TEXT.GRAPH_MARKET, MARKET[1], MARKET[2], MARKET[3])
    Place(panel, market, x + wide + 2 * BETWEEN + INSET, foot, Width(market))
    Right(panel, FONTS.hint, TEXT.GRAPH_KEY, COLOR.NOTE, x, foot, width)
end

-- A key went down (MODIFIER_STATE_CHANGED): Ctrl, with a graph in sight, moves the range on.
function Graph.Key(key, down)
    if down ~= 1 or (key ~= "LCTRL" and key ~= "RCTRL") or not ns.Allowed() then return end
    for _, panel in pairs(Panel.All()) do
        if panel.graphRow and panel:IsShown() then return Choose(After(ns.options.priceRange)) end
    end
end

function Graph.Start(arrived)
    redraw = arrived
end
