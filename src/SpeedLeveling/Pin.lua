local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Speed Leveling - Pin
--  The game's own map pin on the place the guide sends you to, as soon as that
--  place comes up (Saneroki, 2026-10-30; the switch Map pin on the guide's
--  place). The game's pin, not one of ours: Navigation's golden line follows it
--  by itself, as it follows any pin, and the game's own map shows it without
--  Navigation too.
--
--  Set once for each place: a pin you put there or took away yourself stays
--  until the guide goes on to its next place, which then has the pin. Once the
--  guide has no place to go to, or stops, the pin goes, if it is still where the
--  guide put it. A place the game takes no pin on (a dungeon) has none.
--
--      Pin.Update(shown)   as the guide is now (shown or not)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Pin = {}
ns.Pin = Pin

Pin.ASK = 1        -- seconds between asks of where the guide sends you: a place passed on the way tells no one else
Pin.CLOSE = 0.0001 -- the game's pin this close to where the guide put it is still the guide's

local following = false -- the guide is shown and the switch on (Update)
local place             -- the guide's place the pin was last set for
local put               -- the pin as the guide put it: { map, x, y }, nil once there is none of the guide's
local ticker

-- The game's pin there; false where it takes none.
local function Put(map, x, y)
    if not map then return false end
    local maps, points = rawget(_G, "C_Map"), rawget(_G, "UiMapPoint")
    if not (maps and points) or not Core.Ask(maps.CanSetUserWaypointOnMap, map) then return false end
    local point = Core.Ask(points.CreateFromCoordinates, map, x, y)
    if not point then return false end
    local asked, set = pcall(maps.SetUserWaypoint, point)
    if not asked or set == false then return false end
    put = { map = map, x = x, y = y }
    return true
end

-- Whether the game's pin stands where the guide put it.
local function Ours()
    local maps = rawget(_G, "C_Map")
    if not (put and maps and Core.Ask(maps.HasUserWaypoint)) then return false end
    local point = Core.Ask(maps.GetUserWaypoint)
    local position = type(point) == "table" and point.position
    return position and point.uiMapID == put.map and math.abs(position.x - put.x) < Pin.CLOSE
        and math.abs(position.y - put.y) < Pin.CLOSE
end

-- The guide's pin away; one you put yourself stays.
local function Take()
    if Ours() then Core.Ask(C_Map.ClearUserWaypoint) end
    put = nil
end

-- Where the guide sends you now, the pin there once that is a new place.
local function Look()
    local now = following and ns.Run.Target() or nil
    if now == place or ns.Run.SamePlace(now, place) then return end
    place = now
    if not (now and Put(ns.Run.Point(now))) then Take() end
end

function Pin.Update(shown)
    following = (shown and not ns.off and ns.options.mapPin) and true or false
    if following and not ticker then
        ticker = C_Timer.NewTicker(Pin.ASK, ns.Guard(Look))
    elseif not following and ticker then
        ticker:Cancel()
        ticker = nil
    end
    Look()
end
