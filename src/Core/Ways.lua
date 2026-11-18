local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Ways
--  The way to a place, between a module that leads the player and the one that
--  finds ways (Saneroki, 2026-10-31, for the guide's arrow, which points
--  straight at its place again since 2026-11-07: nobody asks now), so neither
--  needs the other. With nobody to find it there is no way: the one who asked
--  points as the crow flies.
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
--
--  And the map's search, between a module that knows someone and the one whose map searches (Saneroki,
--  2026-11-18: Social's "show on map" on a player): the full map, searching for those words.
--
--      Core.Ways.Lookout(fn)      fn(text): the map's search for those words (the module whose map searches)
--      Core.Ways.CanLook()        whether a map searches now
--      Core.Ways.Look(text)       the full map, searching for text (a character's name: where they stand, their zone)
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

local looker
function Ways.Lookout(fn)
    looker = fn
end
function Ways.CanLook()
    return type(looker) == "function"
end
function Ways.Look(text)
    if looker and type(text) == "string" and text ~= "" then Core.Safe("map search", looker, text) end
end
