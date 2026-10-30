local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Units
--  Distances and the time of day as the setting Units says (Saneroki,
--  2026-10-30): Metric at first, meters and 24 hours (27 m, 23:59); Imperial,
--  yards and 12 hours (30 yd, 11:59 PM). The game counts in yards, so all of
--  Sane UI keeps yards; only what a player reads comes through here.
--
--      Core.Metric()               whether the setting is Metric
--      Core.Distance(yards)        "27 m" or "30 yd"
--      Core.DistanceNumber(yards)  the number alone, 27 or 30 (no string made)
--      Core.DistanceText(text)     a text of the game's with the yards it names
--                                  as the setting says ("within 30 yards" is
--                                  "within 27 m", "8-25 yd" is "7-23 m")
--      Core.Clock(hour, minute)    "23:59" or "11:59 PM"
--      Core.ClockAt(stamp)         the same for a moment; none: now
--      Core.GameClock()            the game's own clock says the same
-------------------------------------------------------------------------------

local METERS = 0.9144 -- to the yard, by definition

local function Round(number)
    return math.floor(number + 0.5)
end

function Core.Metric()
    return Core.general.units ~= "imperial"
end

function Core.DistanceNumber(yards)
    return Round(Core.Metric() and yards * METERS or yards)
end

function Core.Distance(yards)
    return (Core.Metric() and "%d m" or "%d yd"):format(Core.DistanceNumber(yards))
end

-- A number, then the game's word for yards after it: "30 yards", "30 yd", "a 10-yard radius".
local NUMBER = "(%d+%.?%d*)"
local YARDS = "[%s%-]*[Yy][Aa]?[Rr]?[Dd][Ss]?%f[%A]"

local function Meters(number)
    return Round(tonumber(number) * METERS)
end

local function Two(from, join, to)
    return Meters(from) .. join .. Meters(to) .. " m"
end

local function One(number)
    return Meters(number) .. " m"
end

function Core.DistanceText(text)
    if type(text) ~= "string" or not Core.Metric() or not text:find("[Yy]") then return text end
    text = text:gsub(NUMBER .. "(%s*%-%s*)" .. NUMBER .. YARDS, Two)
    text = text:gsub(NUMBER .. "(%s+to%s+)" .. NUMBER .. YARDS, Two)
    return (text:gsub(NUMBER .. YARDS, One))
end

function Core.Clock(hour, minute)
    if Core.Metric() then return ("%02d:%02d"):format(hour, minute) end
    local word = hour < 12 and Core.Word("TIMEMANAGER_AM", "AM") or Core.Word("TIMEMANAGER_PM", "PM")
    return ("%d:%02d %s"):format((hour + 11) % 12 + 1, minute, word)
end

-- A chat line asks this: no table for the 24 hours.
function Core.ClockAt(stamp)
    if Core.Metric() then return stamp and date("%H:%M", stamp) or date("%H:%M") end
    local at = date("*t", stamp)
    return Core.Clock(at.hour, at.min)
end

-- The game's own clock and calendar: its switch for 24 hours, at the login and when the setting changes.
function Core.GameClock()
    Core.Ask(rawget(_G, "SetCVar"), "timeMgrUseMilitaryTime", Core.Metric() and "1" or "0")
end
Core.On("PLAYER_LOGIN", Core.GameClock)
