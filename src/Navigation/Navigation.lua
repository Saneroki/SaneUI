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
--  Drawn two ways at every zoom (Blizzard's map art, or the terrain of the game's
--  own minimap textures), from a zone out to the whole world, and a third, the
--  painted map, while the module Atlas (SaneUI_Atlas) is there; the game's minimap
--  lies over it for its live dots. The game's map stays closed: its keys and every
--  way to it open ours.
--
--      Coords (the spaces, the map tree) . Camera . Live (what the game tells)   know no frames
--      Canvas (the frame, its layers, the mouse) . Terrain . Art . Painted . Marks
--      Hybrid (the game's minimap over ours) . Native (the game's map kept closed) . Window
--
--  The terrain's textures are Core's data (the set Tiles, pack World) and the
--  module's overview (Art/Terrain); the art and every position come from the
--  game's map API; the painted map is the module Atlas', loaded when its view is
--  first drawn (Painted.lua). The pins of the game's data and Core's come later.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Navigation", ns)

-- The module's texts, in one place.
ns.TEXT = {
    title = Core.Word("WORLD_MAP", "World Map"),
    view = "Map view",
    viewTip = "How the map is drawn, small and full screen, at every zoom. Parchment: the old maps, drawn by hand. Blended: the old maps far out, the land as it truly lies up close. Scrying: the land as it truly lies. Atlas: the whole world painted as one map (while the module Atlas is switched on in the addon list).",
    views = { sketches = "Parchment", blend = "Blended", terrain = "Scrying", atlas = "Atlas" },
    viewTips = {
        sketches = "The old maps, drawn by hand on parchment: every zone's map, in full, joined into one map of both continents.",
        blend = "The old maps far out, the land as it truly lies up close: the one fades into the other as you zoom in.",
        terrain = "The land as it truly lies, as a scrying glass shows it: both continents, from close up out to the whole world.",
        atlas = "The whole world painted as one map, every road and building where it stands: from a single house up close out to both continents.",
    },
    atlasFailed = "the map view Atlas could not be loaded (%s); the map shows Scrying.",
    atlasEmpty = "the module Atlas holds no painted map",
    atlasBroken = "the module Atlas did not start",
    nativeMinimap = "Show the game's minimap",
    nativeMinimapTip = "The game's own minimap in the top right corner instead of this map's small window; the mouse pushed into that corner still fills the screen with this map. Off: its live dots (players, tracked herbs and ore, quest areas) show on this map while it follows you, and the game's minimap is out of sight.",
    nativeMap = "Show the game's map",
    nativeMapTip = "The game's own map and quest log open as before: its key, the quest log's button, a click on a quest; the mouse pushed into the top right corner still fills the screen with this map. Off: all of them open this map.",
    pins = "Pins on the map",
    pinsTip = "What the map shows on it, small and full screen: the same as the pin filter on the full map's bar. Route to the map pin: a golden line leads from you to the game's map pin (Ctrl and a click on the map), around what cannot be walked, with the flights you know where they are quicker; planned again when you leave it. Minimap dots: what the game's minimap shows around you (players, tracked herbs and ore, quest areas), on the full map too. Possible herbs and ore: where they grow. Found herbs and ore: those the game's minimap shows now, each in its own picture (grey while your skill is too low); each switches Find Herbs or Find Minerals on and off. Books and treasures only full screen; services on the small map only near you.",
    route = "Route to the map pin",
    minimap = "Minimap dots",
    log = "Quests in your log",
    offers = "Quest offers",
    low = "Low-level quests",
    later = "Quests for later",
    done = "Done quests",
    tripView = "Your trip on screen",
    tripViewTip = "On a flight, a boat, a zeppelin or the tram, at the top of the screen: where it goes, a bar of the way behind you with each flight point on it, the next stop and the time to it, the time to the end, and the zone below you. On a flight with a stop before its end, the game's Request Stop button lands you at the next flight point.",
    dockTimes = "Ship times at a dock",
    dockTimesTip = "At the dock of a boat or a zeppelin, at the top of the screen: where each that stops there goes, and when it arrives and leaves; aboard, when it lands. Its times show once you have ridden it on this realm (the game tells no timetable: Sane UI learns it on the ride), until then how often it sails.",
    nodes = "Herbs and ore",
    nodeSparkles = "Sparkles on herbs and ore",
    nodeSparklesTip = "Gold sparkles in the world on the herb or ore your interact key would gather, so you see it among the grass and rocks. Sets the game's Enable Interact Key on and lets it find herbs and ore all around you up to 20 yards; switched off, those settings are as they were.",
    nodeTurns = "Find Herbs and Find Minerals in turn",
    nodeTurnsTip = "With Found herbs and Found ore both on in the pin filter and both spells known: the other one every so many seconds while you move, without a sound, so the map finds both. 0: never.",
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

-- The pin filter's kinds, in its dropdown's order (Pins.lua): its words, whether it is on at first, whether the
-- small view shows it (Doc/ideas/Navigation.md, open question 5: no books or chests on the minimap), and its icon
-- (the game's map icons, ObjectIconsAtlas; shown before its words in the filter). The first two are no pins: the
-- golden line (Planner.lua, Route.lua) and the game's minimap's dots (Hybrid.lua). The quests by where they stand
-- for this character: in its log (the game's), offered to it now, offered but too low to give it experience,
-- offered once it meets what they ask (its level, a quest first), done. Each kind in a section of the filter
-- (ns.PIN_SECTIONS); one without a known section in the last.
ns.KINDS = {
    { "route", ns.TEXT.route, section = "around", on = true, small = true, icon = "poi-traveldirections-arrow" },
    { "minimap", ns.TEXT.minimap, section = "around", on = true, small = true, icon = "monsterneutral" },
    { "log", ns.TEXT.log, section = "quests", on = true, small = true, icon = "questturnin" },
    { "quest", ns.TEXT.offers, section = "quests", on = true, small = true, icon = "questnormal" },
    { "low", ns.TEXT.low, section = "quests", on = true, small = true, icon = "trivialquests", grey = true },
    { "later", ns.TEXT.later, section = "quests", on = true, small = true, icon = "questturnin", tint = { 255, 51, 38 } },
    { "done", ns.TEXT.done, section = "quests", on = false, small = true, icon = "islands-questbangdisable", grey = true },
    { "area", "Quest areas", section = "quests", on = true, small = true, icon = "questblob" },
    { "flight", "Flight points", section = "travel", on = true, small = true, icon = "flightmaster" },
    { "travel", "Boats, zeppelins and portals", section = "travel", on = true, small = true, icon = "flightmasterferry" },
    { "entrance", "Dungeons and raids", section = "travel", on = true, small = true, icon = "dungeon" },
    { "place", "Places", section = "towns", on = true, small = true, icon = "poi-town" },
    { "service", "Services", section = "towns", on = true, small = true, icon = "innkeeper" },
    { "rare", "Rares", section = "finds", on = true, small = true, icon = "dungeonskull" },
    { "treasure", "Treasures", section = "finds", on = true, icon = "vignetteloot" },
    { "herb", "Possible herbs", section = "gathering", on = true, small = true, icon = "professions_tracking_herb" },
    { "ore", "Possible ore", section = "gathering", on = true, small = true, icon = "professions_tracking_ore" },
    -- What the game's minimap shows now (Found.lua); each switches its finder (Nodes.lua). Their icons: the
    -- finders' own, Find Herbs and Find Minerals.
    { "foundHerb", "Found herbs", section = "gathering", on = true, small = true, texture = 133939 },
    { "foundOre", "Found ore", section = "gathering", on = true, small = true, texture = 136025 },
    { "book", "Books", section = "finds", on = false, icon = "lorewalking-map-icon" },
    { "group", "Party and raid", section = "around", on = true, small = true, icon = "partymember" },
}
-- The pin filter's sections, in its order: their key (the kinds' section) and their title.
ns.PIN_SECTIONS = {
    { "around", "Around you" },
    { "quests", Core.Word("QUESTS_LABEL", "Quests") },
    { "travel", "Travel" },
    { "towns", "Towns and services" },
    { "finds", "Rares and treasures" },
    { "gathering", "Gathering" },
}
-- A kind's words with its icon before them (size: the icon's, 16 at first), for the pin filter and the setting's list.
function ns.KindLabel(kind, size)
    size = size or 16
    if kind.texture then return ("|T%s:%d:%d|t %s"):format(kind.texture, size, size, kind[2]) end
    if not kind.icon then return kind[2] end
    -- A tinted icon in its colour (0 to 255), as the game's atlas markup takes it.
    local tint = kind.tint
    if tint then
        return ("|A:%s:%d:%d:0:0:%d:%d:%d|a %s"):format(kind.icon, size, size, tint[1], tint[2], tint[3], kind[2])
    end
    return ("|A:%s:%d:%d|a %s"):format(kind.icon, size, size, kind[2])
end
-- A kind's size, by its slider in the pin filter: from low to high percent in steps (100: as drawn at first). The
-- quest areas' slider is their opacity instead (PIN_OPACITY).
ns.PIN_SIZES = { low = 50, high = 200, step = 10 }
ns.PIN_OPACITY = { low = 10, high = 100, step = 10 }
function ns.PinRange(kind)
    return kind == "area" and ns.PIN_OPACITY or ns.PIN_SIZES
end
function ns.PinPercent(kind)
    local sizes = ns.options and ns.options.pinSizes
    local percent = type(sizes) == "table" and tonumber(sizes[kind])
    if not percent then return 100 end
    local range = ns.PinRange(kind)
    return math.min(math.max(percent, range.low), range.high)
end
function ns.PinScale(kind)
    return ns.PinPercent(kind) / 100
end

local PIN_CHOICES, PIN_DEFAULT = {}, {}
for _, kind in ipairs(ns.KINDS) do
    PIN_CHOICES[#PIN_CHOICES + 1] = { kind[1], ns.KindLabel(kind) }
    if kind.on then PIN_DEFAULT[kind[1]] = true end
end

-- The ways to draw the map, in the order of their buttons (shown as Parchment, Blended, Scrying, Atlas). Atlas only
-- while the module Atlas is there (Painted.lua); a view not offered falls back to Scrying, the default.
ns.VIEWS = { "sketches", "blend", "terrain", "atlas" }
ns.FALLBACK = "terrain"
local CHOICES = { { "sketches", ns.TEXT.views.sketches }, { "blend", ns.TEXT.views.blend },
                  { "terrain", ns.TEXT.views.terrain }, { "atlas", ns.TEXT.views.atlas } }

local OPTIONS = {
    -- Every view a choice while the settings are first read, so a saved Atlas is kept; at login only those
    -- offered (Offer).
    { key = "view", default = ns.FALLBACK, text = ns.TEXT.view, header = ns.TEXT.title, tip = ns.TEXT.viewTip,
      choices = { CHOICES[1], CHOICES[2], CHOICES[3], CHOICES[4] } },
    { key = "pins", default = PIN_DEFAULT, multi = true, choices = PIN_CHOICES, text = ns.TEXT.pins, tip = ns.TEXT.pinsTip },
    -- Each kind's size in percent, [kind] = percent, set by its slider in the pin filter (TopBar.lua): no
    -- control on the options page.
    { key = "pinSizes", default = {} },
    { key = "followAgain", default = 10, min = 0, max = 60, step = 5, unit = ns.TEXT.seconds, text = ns.TEXT.followAgain,
      tip = ns.TEXT.followAgainTip },
    { key = "tripView", default = true, text = ns.TEXT.tripView, tip = ns.TEXT.tripViewTip },
    { key = "dockTimes", default = true, text = ns.TEXT.dockTimes, tip = ns.TEXT.dockTimesTip },
    { key = "nativeMinimap", default = false, text = ns.TEXT.nativeMinimap, tip = ns.TEXT.nativeMinimapTip },
    { key = "nativeMap", default = false, text = ns.TEXT.nativeMap, tip = ns.TEXT.nativeMapTip },
    { key = "nodeSparkles", default = true, text = ns.TEXT.nodeSparkles, tip = ns.TEXT.nodeSparklesTip, header = ns.TEXT.nodes },
    { key = "nodeTurns", default = 6, min = 0, max = 30, step = 1, unit = ns.TEXT.seconds, text = ns.TEXT.nodeTurns,
      tip = ns.TEXT.nodeTurnsTip },
}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, #OPTIONS + 1)

-- Settings of an older shape: 1, the switch Route to the map pin became a kind of the pin filter, as the game's
-- minimap's dots did (both on, but a route switched off); 2, the quests split: those in the log as Quests were,
-- the low and later ones on; 3, the found herbs and ore came, on.
local function Upgrade(values, from)
    if type(values.pins) == "table" then
        if from < 1 then
            values.pins.route = values.route ~= false or nil
            values.pins.minimap = true
        end
        if from < 2 then
            values.pins.log = values.pins.quest
            values.pins.low, values.pins.later = true, true
        end
        if from < 3 then values.pins.foundHerb, values.pins.foundOre = true, true end
    end
    values.route = nil
end

local routed -- whether the pin filter let the route through when it last changed
local found -- whether the pin filter let the found herbs and ore through when it last changed ("herb ore")
Core.Options(ns.name, OPTIONS, { version = 3, upgrade = Upgrade, changed = function(key)
    -- The section Expand window: Core's window takes it in by itself (Edge.lua).
    if Core.Edge.KEYS[key] then return end
    if key == "view" then return ns.Guarded(ns.Window.Restyle) end
    if key == "pinSizes" then
        ns.Guarded(ns.Found.Update)
        return ns.Guarded(ns.Canvas.Refresh)
    end
    if key == "pins" then
        -- The route planned anew (or let go) only when its own switch changed.
        local route = ns.Pins.Shows("route")
        if route ~= routed then
            routed = route
            ns.Guarded(ns.Planner.Update)
        end
        -- The finders switched only when Found herbs or Found ore changed.
        local now = tostring(ns.Pins.Shows("foundHerb")) .. " " .. tostring(ns.Pins.Shows("foundOre"))
        if found and now ~= found then ns.Guarded(ns.Nodes.Apply) end
        found = now
        ns.Guarded(ns.Nodes.Update)
        ns.Guarded(ns.Found.Update)
        return ns.Guarded(ns.Canvas.Refresh)
    end
    if key == "nativeMinimap" then
        ns.Guarded(ns.Hybrid.Update)
        ns.Guarded(ns.Window.Update)
        return ns.Guarded(ns.Native.Update)
    end
    if key == "nativeMap" then return ns.Guarded(ns.Native.Update) end
    if key == "dockTimes" then return ns.Guarded(ns.DockWatch.Update) end
    if key == "tripView" then return ns.Guarded(ns.TripView.Update) end
    if key == "nodeSparkles" then return ns.Guarded(ns.Sparkles.Settings) end
    if key == "nodeTurns" then return ns.Guarded(ns.Nodes.Update) end
end })

-- Whether a view can be drawn: Atlas only while its module is there and has not failed.
function ns.Offered(key)
    if key == "atlas" then return ns.Painted.Offered() end
    return key == "sketches" or key == "blend" or key == "terrain"
end

-- The view the map is drawn in: the one chosen, if it is offered, else Scrying.
function ns.View()
    local chosen = ns.options.view
    if ns.Offered(chosen) then return chosen end
    return ns.FALLBACK
end

-- The views offered, in the settings' dropdown and on the full map's buttons; a saved view not offered (the
-- module Atlas switched off, or failed) becomes Scrying. At login, and when the Atlas failed.
function ns.Offer()
    local choices = OPTIONS[1].choices
    wipe(choices)
    for _, choice in ipairs(CHOICES) do
        if ns.Offered(choice[1]) then choices[#choices + 1] = choice end
    end
    if not ns.Offered(ns.options.view) then Core.Set(ns.name, "view", ns.FALLBACK) end
    ns.Window.Arrange()
end

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
    Back(ns.DockWatch.Hide)
    Back(ns.TripView.Hide)
    Back(ns.Found.Hide)
    Back(ns.Nodes.GiveBack)
    Back(ns.Sparkles.GiveBack)
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    -- The terrain's textures, soon after the loading screen: the map shows from login.
    Core.Data.Prepare("Tiles")
    -- A map pin kept from the last session: its route (the walking data is asked for then).
    Core.Later(function() ns.Guarded(ns.Planner.Update) end, 2)()
    ns.Painted.Find()
    ns.Offer()
    ns.Window.Build()
    ns.Hybrid.Start(ns.Canvas.frame)
    ns.Native.Start()
    found = tostring(ns.Pins.Shows("foundHerb")) .. " " .. tostring(ns.Pins.Shows("foundOre"))
    ns.Nodes.Start()
    ns.Found.Start()
    ns.Sparkles.Start()
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
