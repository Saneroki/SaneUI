local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation
--  The module's own table (ns in all its files), its settings and the command.
--
--  An addon of its own (SaneUI_Navigation): it needs Core and nothing else, and is
--  switched on and off in the game's addon list. The plan is Doc/ideas/Navigation.md.
--
--  Built so far, the first step: a window docked in the screen's top right corner
--  that fills the screen when the mouse goes into that corner (Core's window and
--  Edge), and shows the map there: the player's continent, dragged and zoomed,
--  drawn one of three ways (Blizzard's map art, the terrain of the game's own
--  minimap textures, or the art laid over the terrain). Small, the window shows
--  nothing yet; the game's own minimap and map stay as they are.
--
--      Coords (map, world, plane) . Camera (where the view looks)     know no frames
--      Canvas (the frame, its layers, the mouse) . Terrain . Art . Window
--
--  The terrain's textures are Core's data (the set Tiles, pack World); the art and
--  every position come from the game's map API.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Navigation", ns)

-- The module's texts, in one place.
ns.TEXT = {
    title = Core.Word("WORLD_MAP", "World Map"),
    view = "Map view",
    viewTip = "How the map is drawn. Blizzard maps: the game's own map art. Terrain: the land as the minimap shows it. Overlay: the terrain with Blizzard's maps laid over it, half see-through.",
    views = { blizzard = "Blizzard maps", terrain = "Terrain", overlay = "Overlay" },
    viewTips = {
        blizzard = "The game's own map art: the continent, and up close the zone in the middle.",
        terrain = "The land as the minimap shows it. Far out, where it would be too much to draw, Blizzard's map.",
        overlay = "The terrain, with Blizzard's maps laid over it, half see-through.",
    },
    about = "the map full screen and back (/sane map reset: the window's first place and size)",
    stopped = "the map is closed until the next /reload.",
    reset = "the map window is back at its first place and size.",
}
-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the map window is closed"

-- The three ways to draw the map, in the order of their buttons.
ns.VIEWS = { "blizzard", "terrain", "overlay" }

local OPTIONS = {
    { key = "view", default = "overlay", text = ns.TEXT.view, header = ns.TEXT.title, tip = ns.TEXT.viewTip,
      choices = { { "blizzard", ns.TEXT.views.blizzard }, { "terrain", ns.TEXT.views.terrain }, { "overlay", ns.TEXT.views.overlay } } },
}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, #OPTIONS + 1)

Core.Options(ns.name, OPTIONS, { changed = function(key)
    -- The section Expand window: Core's window takes it in by itself (Edge.lua).
    if Core.Edge.KEYS[key] then return end
    if key == "view" then return ns.Guarded(ns.Window.Restyle) end
end })

-- Something failed (Core's StandDown calls this once): the window goes, so a map that broke never covers the
-- screen. Nothing of the game's is taken yet, so nothing else is given back.
function ns.GiveBack()
    ns.Window.Hide()
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    -- The terrain's textures, soon after the loading screen: the map can open at any time.
    Core.Data.Prepare("Tiles")
    ns.Window.Build()
end

Core.Command("map", ns.TEXT.about, function(rest)
    if ns.off then
        ns.Print(ns.TEXT.stopped)
    elseif rest == "reset" then
        ns.Guarded(ns.Window.Reset)
        ns.Print(ns.TEXT.reset)
    else
        ns.Guarded(ns.Window.Toggle)
    end
end)
