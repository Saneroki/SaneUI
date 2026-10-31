local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Ways
--  The way to a place, between a module that leads the player and the one that
--  finds ways (Saneroki, 2026-10-31: the guide's arrow goes by Navigation's
--  routes), so neither needs the other. With nobody to find it there is no way:
--  the one who asked points as the crow flies.
--
--      Core.Ways.Serve(finder)    finder = { Aim = fn(map, x, y), Ahead = fn() -> ahead }
--      Core.Ways.Aim(map, x, y)   lead there from now on (a map of the game's, x and y 0 to 1); no map: nowhere
--      Core.Ways.Ahead()          where to go now, as often as one likes (the table is reused); nil while no way is
--                                 known:
--          way     radians from the north, turning to the left as the game's facing does: the line a little ahead
--          yards   along the line to the ride it comes to, or to where it ends
--          ride    the ride next: "flight", "boat", "zeppelin", "tram", "lift", "portal", "hearth", "teleport"; nil: only
--                  a walk is left
--          to      where that ride brings one, its name
--          here    true: the player is at that ride, which starts here: nothing to point at, it is to be taken
-------------------------------------------------------------------------------
local Ways = {}
Core.Ways = Ways

local finder

function Ways.Serve(found)
    finder = found
end

function Ways.Aim(map, x, y)
    if finder then Core.Safe("ways", finder.Aim, map, x, y) end
end

function Ways.Ahead()
    if finder then return Core.Safe("ways", finder.Ahead) end
    return nil
end
