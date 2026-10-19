local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation
--  The module's own table (ns in all its files), its settings, the command, and
--  giving the game's minimap and map back.
--
--  An addon of its own (SaneUI_Navigation): it needs Core and nothing else, and is
--  switched on and off in the game's addon list. The plan is Doc/ideas/Navigation.md.
--
--  One window takes the place of the game's minimap and world map: small in the
--  screen's top right corner it is the minimap, filling the screen it is the map,
--  the same map drawn and handled the same way, each view with its own camera.
--  Drawn three ways at every zoom (Blizzard's map art, the terrain of the game's
--  own minimap textures, or the art over the terrain), from a zone out to the
--  whole world; the game's minimap lies over it for its live dots. The game's map
--  stays closed: its keys and every way to it open ours.
--
--      Coords (the spaces, the map tree) . Camera . Live (what the game tells)   know no frames
--      Canvas (the frame, its layers, the mouse) . Terrain . Art . Marks
--      Hybrid (the game's minimap over ours) . Native (the game's map kept closed) . Window
--
--  The terrain's textures are Core's data (the set Tiles, pack World) and the
--  module's overview (Art/Terrain); the art and every position come from the
--  game's map API. The pins of the game's data and Core's come later.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Navigation", ns)

-- The module's texts, in one place.
ns.TEXT = {
    title = Core.Word("WORLD_MAP", "World Map"),
    view = "Map view",
    viewTip = "How the map is drawn, small and full screen, at every zoom. Parchment: the old maps, drawn by hand. Scrying: the land as it truly lies. Overlay: the land with the old maps laid over it, half see-through.",
    views = { sketches = "Parchment", terrain = "Scrying", overlay = "Overlay" },
    viewTips = {
        sketches = "The old maps, drawn by hand on parchment: every zone's map, in full, joined into one map of both continents.",
        terrain = "The land as it truly lies, as a scrying glass shows it: both continents, from close up out to the whole world.",
        overlay = "The land as it truly lies, with the old maps laid over it, half see-through.",
    },
    nativeMinimap = "Show the game's minimap",
    nativeMinimapTip = "The game's own minimap in its place, next to this map. Off: its live dots (players, tracked herbs and ore, quest areas) show on this map while it follows you, and the game's minimap is out of sight.",
    nativeMap = "Show the game's map",
    nativeMapTip = "The game's own map and quest log open as before: its key, the quest log's button, a click on a quest. Off: all of them open this map.",
    followAgain = "Follow again after",
    followAgainTip = "After you dragged the map away, it centres on you again once the mouse has been off it for so long. 0: only when you zoom it with the mouse wheel close in.",
    seconds = "seconds",
    classicMinimap = "Minimap",
    classicMap = Core.Word("WORLD_MAP", "World Map"),
    noPin = Core.Word("MAP_PIN_INVALID_MAP", "A map pin cannot be placed here."),
    mapInFight = "the game's map opens only by its own key in a fight.",
    about = "the map full screen and back (/sane map reset: the window's first place and size)",
    stopped = "the map is closed until the next /reload; the game's own minimap and map are back.",
    reset = "the map window is back at its first place and size.",
}
-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the map window is closed, the game's own minimap and map are back"

-- The three ways to draw the map, in the order of their buttons (shown as Parchment, Scrying, Overlay; Overlay gives
-- way to the painted Atlas once its art is made).
ns.VIEWS = { "sketches", "terrain", "overlay" }

local OPTIONS = {
    { key = "view", default = "overlay", text = ns.TEXT.view, header = ns.TEXT.title, tip = ns.TEXT.viewTip,
      choices = { { "sketches", ns.TEXT.views.sketches }, { "terrain", ns.TEXT.views.terrain }, { "overlay", ns.TEXT.views.overlay } } },
    { key = "followAgain", default = 10, min = 0, max = 60, step = 5, unit = ns.TEXT.seconds, text = ns.TEXT.followAgain,
      tip = ns.TEXT.followAgainTip },
    { key = "nativeMinimap", default = false, text = ns.TEXT.nativeMinimap, tip = ns.TEXT.nativeMinimapTip },
    { key = "nativeMap", default = false, text = ns.TEXT.nativeMap, tip = ns.TEXT.nativeMapTip },
}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, #OPTIONS + 1)

Core.Options(ns.name, OPTIONS, { changed = function(key)
    -- The section Expand window: Core's window takes it in by itself (Edge.lua).
    if Core.Edge.KEYS[key] then return end
    if key == "view" then return ns.Guarded(ns.Window.Restyle) end
    if key == "nativeMinimap" then
        ns.Guarded(ns.Hybrid.Update)
        return ns.Guarded(ns.Native.Update)
    end
    if key == "nativeMap" then return ns.Guarded(ns.Native.Update) end
end })

-- One step of giving back. Each runs by itself, so one that fails does not keep the next from its work.
local function Back(step)
    local ok, problem = xpcall(step, Core.Trace)
    if not ok then Core.NoteError(ns.name .. ": giving back", problem) end
end

-- Something failed (Core's StandDown calls this once): the keys back to the game's, the game's minimap back
-- where it was, the window gone. What must wait for the end of a fight waits for it.
function ns.GiveBack()
    Back(ns.Native.GiveBack)
    Back(ns.Hybrid.GiveBack)
    Back(ns.Window.Hide)
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    -- The terrain's textures, soon after the loading screen: the map shows from login.
    Core.Data.Prepare("Tiles")
    ns.Window.Build()
    ns.Hybrid.Start(ns.Canvas.frame)
    ns.Native.Start()
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
