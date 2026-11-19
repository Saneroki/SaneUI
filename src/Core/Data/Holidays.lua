local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Holidays
--  Which holidays of the set Holidays run now, as the game's calendar tells it (C_Calendar), for every view that
--  shows something only while one runs: a quest the set Quests offers in a holiday alone (its field holiday), as the
--  map's quest offers ask it (Navigation).
--
--      Holidays.Running(key)   whether the holiday of that key runs now: true, else false (also while the calendar
--                              has not answered yet, and in a game without one)
--      Holidays.OnChange(fn)   fn() once the holidays running are others (a holiday began or ended)
--
--  The calendar is asked for its days once at the login (OpenCalendar) and on a new day; today's holiday events are
--  read when it answers (CALENDAR_UPDATE_EVENT_LIST) and again every Holidays.AGAIN seconds, a holiday starting and
--  ending at its hour. One runs from its start to its end time. A holiday is known by the calendar's event ID (the
--  set's key) or by its title (the set's name: the client is English): the set has the Darkmoon Faire under two keys.
--  Nothing is kept: what runs is the game's word of the moment.
-------------------------------------------------------------------------------
local Data = Core.Data

local Holidays = {}
Data.Holidays = Holidays
Holidays.AGAIN = 600 -- seconds between two reads of today's holidays

local Set = Data.Set("Holidays")
local Plain = Core.Plain

local ids, titles = {}, {} -- the holidays running: [the calendar's event ID] = true, [its title] = true
local told = ""             -- what ran at the last read, as one text: a change is told
local day                   -- the day of the month of the last read: a new one asks the calendar again
local listeners = {}

-- A time of the calendar as one number that sorts as it does: year, month, day, hour, minute.
local function Stamp(time)
    if type(time) ~= "table" then return nil end
    local year, month, monthDay = tonumber(Plain(time.year)), tonumber(Plain(time.month)), tonumber(Plain(time.monthDay))
    if not (year and month and monthDay) then return nil end
    return (((year * 100 + month) * 100 + monthDay) * 100 + (tonumber(Plain(time.hour)) or 0)) * 100
        + (tonumber(Plain(time.minute)) or 0)
end

-- Today's holiday events in the calendar, those running now.
local function Read()
    local calendar, clock = rawget(_G, "C_Calendar"), rawget(_G, "C_DateAndTime")
    if not (calendar and clock) then return end
    local now = Core.Ask(clock.GetCurrentCalendarTime)
    local shown = Core.Ask(calendar.GetMonthInfo, 0) -- the month the calendar stands at (the player may have turned it)
    local at = Stamp(now)
    if not at or type(shown) ~= "table" then return end
    local monthDay = tonumber(Plain(now.monthDay))
    if day and day ~= monthDay then Core.Ask(calendar.OpenCalendar) end
    day = monthDay
    local offset = ((tonumber(Plain(now.year)) or 0) - (tonumber(Plain(shown.year)) or 0)) * 12
        + (tonumber(Plain(now.month)) or 0) - (tonumber(Plain(shown.month)) or 0)
    wipe(ids)
    wipe(titles)
    local names = {}
    for index = 1, tonumber(Core.Ask(calendar.GetNumDayEvents, offset, monthDay)) or 0 do
        local event = Core.Ask(calendar.GetDayEvent, offset, monthDay, index)
        if type(event) == "table" and Plain(event.calendarType) == "HOLIDAY" then
            local from, to = Stamp(event.startTime), Stamp(event.endTime)
            if (not from or from <= at) and (not to or at <= to) then
                local id, title = tonumber(Plain(event.eventID)), Plain(event.title)
                if id then ids[id] = true end
                if type(title) == "string" and title ~= "" then
                    titles[title] = true
                    names[#names + 1] = title
                end
            end
        end
    end
    table.sort(names)
    local running = table.concat(names, "\031")
    if running == told then return end
    told = running
    for _, fn in ipairs(listeners) do fn() end
end

-- Whether the holiday of the set Holidays with that key runs now.
function Holidays.Running(key)
    if ids[key] then return true end
    local name = Set:Get(key, "name")
    return name ~= nil and titles[name] == true
end

-- fn() once the holidays running are others.
function Holidays.OnChange(fn)
    listeners[#listeners + 1] = fn
end

local again
again = Core.Later(function()
    Read()
    again()
end, Holidays.AGAIN, "holidays")

Core.On("CALENDAR_UPDATE_EVENT_LIST", Read)
Core.On("PLAYER_ENTERING_WORLD", function()
    local calendar = rawget(_G, "C_Calendar")
    if calendar and not day then Core.Ask(calendar.OpenCalendar) end
    Read()
    again()
end)
