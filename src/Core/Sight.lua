local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Sight
--  The herbs and ore in sight right now, between the module that finds them on
--  the game's minimap and one that leads the player (Saneroki, 2026-10-31: the
--  guide's detours go by Navigation's Found), so neither needs the other. With
--  nobody to find them, none are in sight: a place from Core's data says where a
--  node can stand, this one says that it stands there now.
--
--      Core.Sight.Serve(finder)   finder = fn() -> nodes
--      Core.Sight.Nodes()         what is in sight, an array (never nil); each one:
--          node        its record of Core's set Objects, with its key
--          map, x, y   where it stands: the game's map of its zone, x and y 0 to 1
--          seen        the game's time it was last found
-------------------------------------------------------------------------------
local Sight = {}
Core.Sight = Sight

local EMPTY = {}
local finder

function Sight.Serve(found)
    finder = found
end

function Sight.Nodes()
    if finder then return Core.Safe("sight", finder) or EMPTY end
    return EMPTY
end
