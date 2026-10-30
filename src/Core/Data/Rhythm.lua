local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Rhythm
--  How an item's price goes at an auction house, in one short line per item: what it usually costs, where that is
--  heading, how it swings with the time of day and the day of the week, how much of it sells. Each full scan moves the
--  lines of a house (Scan.lua), and a view reads one through Prices:Outlook, so a forecast opens no history.
--
--      house.rhythm[key] = "at,since,seen,fast,slow,dev, n,mean ×8, n,mean ×7, soldAt,units,money"
--      house.stretch     the stretch of the day last sampled; samples: how many were; watched, watchedAt: Rhythm.Watched
--
--      at, since, seen   the last sample, the first, how many
--      fast, slow        the usual price: the samples averaged over about a day and a half, and over about a week
--      dev               how far a sample stands from fast, on average, in parts of a thousand
--      n,mean ×8         each stretch of the day (0-3, 3-6, ... 21-24 by the player's clock), its samples: how many, and
--                        how they stood against fast, in parts of a thousand (1000: the usual price)
--      n,mean ×7         the same per weekday (1: Sunday), against slow
--      soldAt, units, money   what was seen selling, fading over a week: when last, how many, for how much
--
--  A sample is an item's lowest price at the first scan of a stretch, so the eight scans of a day in which it was seen
--  count, not the ninety that mostly repeat each other. A price more than twice off the usual one counts as twice, and
--  the usual prices are averaged by ratios (geometric), so one wild listing moves them little, even the very first.
--
--  A swing only counts once it stands clear of the item's own noise (Swing), and then less what it may be off by:
--  the highest of many stretches is too high by chance alone. So a new item, or a steady one, has no time to name,
--  and the forecast grows out of what the scans have shown. It never guesses from other items.
--
--      Rhythm.Seen(line, at, low)              the line with a sample more
--      Rhythm.Sold(line, at, units, money)     the line with what sold since the last scan
--      Rhythm.Watched(house, at, seconds)      the house's scans watched that long: what selling is told against
--      Rhythm.Stretch(at)                      which stretch of which day at is: a new one takes a new sample
--      Rhythm.Read(line, now, watched, watchedAt)
--          { at, days, usual, drift, high, highAt, low, lowAt, allDay, daily, each }, nil for no line of this shape:
--          at       when this was read
--          days     how long the item has been watched
--          usual    what it usually costs now
--          drift    where that is heading, a share a day (0.02: 2% up); 0: steady, as far as can be told
--          high, low     the highest and lowest price to expect within a week: the usual one if nothing swings
--          highAt, lowAt where those stretches begin (at or before at, if it is the stretch now), the soonest that
--                        comes near; nil if no stretch stands out
--          allDay   true if the time of day makes no difference: only the day counts
--          daily    how many sell a day; nil while too little was watched to tell
--          each     what one went for; nil if none sold
-------------------------------------------------------------------------------
local Rhythm = {}
Core.Data.Rhythm = Rhythm

local DAY = 86400
local HOURS = 3         -- how long a stretch of the day is
local STRETCH = HOURS * 3600
local PARTS, WEEKDAYS = 24 / HOURS, 7
local FAST_SPAN, SLOW_SPAN = 1.5 * DAY, 7 * DAY -- how far back the two usual prices look
local SOLD_SPAN = 7 * DAY -- how fast sales fade
local LAG = (SLOW_SPAN - FAST_SPAN) / DAY       -- how many days of a steady climb the two usual prices stand apart by
local CLIP = 2          -- how far off the usual price a sample counts
local SETTLE = 8        -- samples before that: a day's, as the first is no usual price to measure by
local PART_MOST, WEEK_MOST, DEV_MOST = 28, 40, 64 -- samples a mean remembers: four weeks of a stretch, five of a weekday
local LEAST_DAYS = 3    -- days a stretch or weekday must have been seen for its swing to count
local FLAT = 15         -- a swing under this, of a thousand, is no swing
local TREND_DAYS = 5    -- days before a drift can be told from a swing
local DRIFT_MOST, DRIFT_DAYS = 0.05, 3 -- the most a drift counts for, a share a day, and how many days ahead it holds
local AHEAD = 7 * PARTS -- stretches looked ahead: a week's
local NEAR = 0.99       -- what comes this near to the best is as good, if it comes sooner
local STANDS_OUT = 1.01 -- how far the highest must stand over the lowest for a stretch to be named
local LEAST_WATCHED = 12 * 3600 -- seconds of pairs of scans before selling can be told

local AT, SINCE, SEEN, FAST, SLOW, DEV = 1, 2, 3, 4, 5, 6
local PART = DEV + 1                    -- PARTS pairs from here
local WEEK = PART + 2 * PARTS           -- WEEKDAYS pairs from here
local SOLD_AT = WEEK + 2 * WEEKDAYS
local UNITS, MONEY = SOLD_AT + 1, SOLD_AT + 2
local FIELDS = MONEY
local LINE = "%.0f,%.0f,%d,%.7g,%.7g,%.4g" .. (",%d,%.6g"):rep(PARTS + WEEKDAYS) .. ",%.0f,%.5g,%.7g"

local function Clock(at)
    local clock = date("*t", at)
    return math.floor(clock.hour / HOURS), clock.wday - 1, clock
end

-- The fields of a line; nil for no line of this shape, as a saved line can be from an older form.
local function Parse(line)
    local fields, count = {}, 0
    for word in line:gmatch("[^,]+") do
        count = count + 1
        fields[count] = tonumber(word) or 0
    end
    return count == FIELDS and fields or nil
end

local function Fields(line)
    local fields = type(line) == "string" and Parse(line)
    if fields then return fields end
    fields = {}
    for index = 1, FIELDS do fields[index] = 0 end
    return fields
end

local function Line(fields)
    return LINE:format(unpack(fields, 1, FIELDS))
end

local function Slot(fields, index, share, most)
    local count = math.min(fields[index] + 1, most)
    fields[index] = count
    fields[index + 1] = fields[index + 1] + (share - fields[index + 1]) / count
end

-- The first samples are a plain average, then the span takes over.
local function Toward(value, price, gone, span, seen)
    return value * (price / value) ^ math.max(1 / seen, 1 - math.exp(-gone / span))
end

function Rhythm.Seen(line, at, low)
    local fields = Fields(line)
    if fields[AT] == 0 then
        fields[AT], fields[SINCE], fields[SEEN], fields[FAST], fields[SLOW] = at, at, 1, low, low
        return Line(fields)
    end
    if at <= fields[AT] then return line end
    local fast, slow = fields[FAST], fields[SLOW]
    local price = low
    if fields[SEEN] >= SETTLE then price = math.max(fast / CLIP, math.min(low, fast * CLIP)) end
    local part, weekday = Clock(at)
    local share = price / fast * 1000
    Slot(fields, PART + 2 * part, share, PART_MOST)
    Slot(fields, WEEK + 2 * weekday, price / slow * 1000, WEEK_MOST)
    local seen = fields[SEEN] + 1
    fields[DEV] = fields[DEV] + (math.abs(share - 1000) - fields[DEV]) / math.min(seen, DEV_MOST)
    local gone = at - fields[AT]
    fields[FAST], fields[SLOW] = Toward(fast, price, gone, FAST_SPAN, seen), Toward(slow, price, gone, SLOW_SPAN, seen)
    fields[AT], fields[SEEN] = at, seen
    return Line(fields)
end

function Rhythm.Sold(line, at, units, money)
    local fields = Fields(line)
    local fade = fields[SOLD_AT] > 0 and math.exp((fields[SOLD_AT] - at) / SOLD_SPAN) or 0
    fields[SOLD_AT], fields[UNITS], fields[MONEY] = at, fields[UNITS] * fade + units, fields[MONEY] * fade + money
    return Line(fields)
end

function Rhythm.Watched(house, at, seconds)
    local since = tonumber(house.watchedAt) or 0
    local fade = since > 0 and math.exp((since - at) / SOLD_SPAN) or 0
    house.watched, house.watchedAt = (tonumber(house.watched) or 0) * fade + seconds, at
end

function Rhythm.Stretch(at)
    local part, _, clock = Clock(at)
    return clock.yday * PARTS + part
end

-- The middle of a row of means: an item that rises stands over its usual prices at every hour, and only what differs
-- between them is a swing.
local function Middle(fields, index, slots)
    local sum, count = 0, 0
    for slot = 0, slots - 1 do
        if fields[index + 2 * slot] > 0 then sum, count = sum + fields[index + 2 * slot + 1], count + 1 end
    end
    return count > 0 and sum / count or 1000
end

-- What a stretch or weekday is worth against the usual price: 1 where it does not stand clear of the item's noise, and
-- never all of what was seen. perDay: its samples a day; middle: of its row.
local function Swing(fields, index, perDay, middle)
    local days = fields[index] / perDay
    if days < LEAST_DAYS then return 1 end
    local off, err = fields[index + 1] - middle, 1.25 * fields[DEV] / math.sqrt(days)
    if math.abs(off) < math.max(2 * err, FLAT) then return 1 end
    return 1 + (off > 0 and off - err or off + err) / 1000
end

local function Drift(fields, days)
    if days < TREND_DAYS then return 0 end
    local gap = fields[FAST] / fields[SLOW] - 1
    if math.abs(gap) * 1000 < math.max(2 * fields[DEV] / math.sqrt(days), FLAT) then return 0 end
    return math.max(-DRIFT_MOST, math.min(gap / LAG, DRIFT_MOST))
end

-- The prices to expect from now on, a stretch at a time: 0 is the one now. True if the time of day counts in them.
local prices, times = {}, {}
local function Ahead(fields, usual, drift, now)
    local _, _, clock = Clock(now)
    local start = now - (clock.hour % HOURS) * 3600 - clock.min * 60 - clock.sec
    local parts, weekdays = Middle(fields, PART, PARTS), Middle(fields, WEEK, WEEKDAYS)
    local timed = false
    for step = 0, AHEAD do
        local at = start + step * STRETCH
        local part, weekday = Clock(at)
        local swing = Swing(fields, PART + 2 * part, 1, parts)
        timed = timed or swing ~= 1
        times[step] = at
        prices[step] = usual * swing * Swing(fields, WEEK + 2 * weekday, PARTS, weekdays)
            * (1 + drift * math.max(0, math.min((at - now) / DAY, DRIFT_DAYS)))
    end
    return timed
end

function Rhythm.Read(line, now, watched, watchedAt)
    local fields = type(line) == "string" and Parse(line)
    if not fields or fields[AT] == 0 then return nil end
    local days = (now - fields[SINCE]) / DAY
    local drift = Drift(fields, days)
    local usual = drift ~= 0 and fields[FAST] or fields[SLOW]
    local timed = Ahead(fields, usual, drift, now)
    local high, low = prices[0], prices[0]
    for step = 1, AHEAD do
        high, low = math.max(high, prices[step]), math.min(low, prices[step])
    end
    local outlook = { at = now, days = days, usual = usual, drift = drift, high = high, low = low, allDay = not timed }
    if high > low * STANDS_OUT then
        for step = AHEAD, 0, -1 do
            if prices[step] >= high * NEAR then outlook.highAt = times[step] end
            if prices[step] * NEAR <= low then outlook.lowAt = times[step] end
        end
    end
    local seen = (watched or 0) * math.exp(((watchedAt or now) - now) / SOLD_SPAN)
    if seen >= LEAST_WATCHED then
        local fade = fields[SOLD_AT] > 0 and math.exp((fields[SOLD_AT] - now) / SOLD_SPAN) or 0
        local units = fields[UNITS] * fade
        outlook.daily = units / seen * DAY
        if units > 0 then outlook.each = fields[MONEY] / fields[UNITS] end
    end
    return outlook
end
