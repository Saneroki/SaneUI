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
--  own minimap textures), from a zone out to the whole world; the game's minimap
--  lies over it for its live dots. The game's map stays closed: its keys and every
--  way to it open ours.
--
--      Coords (the spaces, the map tree) . Camera . Live (what the game tells)   know no frames
--      Canvas (the frame, its layers, the mouse) . Terrain . Art . Marks
--      Hybrid (the game's minimap over ours) . Native (the game's map kept closed) . Window
--
--  The terrain's textures are Core's data (the set Tiles) and the
--  module's overview (Art/Terrain); the art and every position come from the
--  game's map API. The pins of the game's data and Core's come later.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Navigation", ns)

-- The module's texts, in one place.
ns.TEXT = {
    title = Core.Word("WORLD_MAP", "World Map"),
    view = "Map view",
    viewTip = "How the map is drawn, small and full screen, at every zoom. Parchment: the old maps, drawn by hand. Blended: the old maps far out, the land as it truly lies up close. Scrying: the land as it truly lies.",
    views = { sketches = "Parchment", blend = "Blended", terrain = "Scrying" },
    viewTips = {
        sketches = "The old maps, drawn by hand on parchment: every zone's map, in full, joined into one map of both continents.",
        blend = "The old maps far out, the land as it truly lies up close: the one fades into the other as you zoom in.",
        terrain = "The land as it truly lies, as a scrying glass shows it: both continents, from close up out to the whole world.",
    },
    -- The zone under the mouse (Label.lua): the fishing skill its waters ask, from the first catch to every cast's.
    fishing = "Fishing %d-%d",
    -- A flight point at a flight master (Taxi.lua).
    taxiHere = "You are here",
    taxiFly = "Click to fly there",
    taxiFar = "No flight there from here",
    nativeMinimap = "Show the game's minimap",
    nativeMinimapTip = "The game's own minimap in the top right corner instead of this map's small window; the mouse pushed into that corner still fills the screen with this map. Off: its live dots (players, tracked herbs and ore, quest areas) show on this map while it follows you, and the game's minimap is out of sight.",
    nativeMap = "Show the game's map",
    nativeMapTip = "The game's own map and quest log open as before: its key, the quest log's button, a click on a quest; the mouse pushed into the top right corner still fills the screen with this map. Off: all of them open this map.",
    questLogRest = "Hide the quest log at rest",
    questLogRestTip = "The quest log on the screen alone is out of sight while nothing goes on. It shows while the mouse is on it, while your health or your resource is not full (rage and combo points: while you have any), in a fight, in a group (unless In a group too) and in Edit Mode. Out of sight its words, title bar and items still take the mouse. Over the full map it always shows. Off: always in sight.",
    questLogRestGroup = "In a group too",
    questLogRestGroupTip = "The quest log on the screen rests out of sight in a party or raid as well: there too only the mouse, your health or your resource, a fight and Edit Mode bring it. Off: always in sight in a group.",
    pins = "Pins on the map",
    pinsTip = "What the map shows on it, small and full screen: the same as the pin filter on the full map's bar and the satchel on the small map. Route to the map pin: a golden line leads from you to the game's map pin (a double click on the map or a pin), around what cannot be walked, with the flights you know where they are quicker; planned again when you leave it. On foot it turns orange where enemies a few levels above you spawn near it, red where they are far above you. Drag it on the full map to put a waypoint there: the line goes there first, then on to the pin. Minimap dots: what the game's minimap shows around you (players, tracked herbs and ore, quest areas), on the full map too. Possible herbs and ore: where they grow. Found herbs and ore: those the game's minimap shows now, each in its own picture (grey while your skill is too low); each switches Find Herbs or Find Minerals on and off. Found fishing pools: switches Find Fish on and off (the game's minimap dots show the pools). Your finders come back on by themselves once you are alive again after dying. Books and treasures only full screen; services on the small map only near you.",
    route = "Route to the map pin",
    -- A waypoint of the golden line (Planner.Via, Marks.Vias).
    via = "Waypoint",
    viaTip = "The golden line goes here first, then on to the map pin. Drag it to move it; right click: away. Gone once you pass it, or when the map pin moves.",
    minimap = "Minimap dots",
    log = "Quests in your log",
    offers = "Quest offers",
    low = "Low-level quests",
    later = "Quests for later",
    done = "Done quests",
    tripView = "Your trip on screen",
    tripViewTip = "On a flight, a boat, a zeppelin or the tram, high up the screen: where it began and where it goes at the ends of a golden line that fills as you go, each flight point on it, the time to the end, the next stop and the time to it, and the zone below you. The button to get out stands here too, in place of the game's at the action bars: on a flight it lands you at the next flight point, in a vehicle it lets you out.",
    dockTimes = "Ship times at a dock",
    dockTimesTip = "At the dock of a boat or a zeppelin and at a station of the tram, high up the screen: where the next to come goes, a golden line that fills as it nears, when it arrives (board now) and when it leaves; the others there below. Its times show once you have ridden it on this realm (the game tells no timetable: Sane UI learns it on the ride), until then how often it sails.",
    nodes = "Herbs and ore",
    nodeSparkles = "Sparkles on herbs and ore",
    nodeSparklesTip = "Gold sparkles in the world on the herb or ore your interact key would gather, so you see it among the grass and rocks. Sets the game's Enable Interact Key on and lets it find herbs and ore all around you up to " .. Core.Distance(20) .. "; switched off, those settings are as they were.",
    nodeGlints = "Far herbs and ore on the screen",
    nodeGlintsTip = "Each herb and ore the minimap found farther away shows on the screen in its direction: the picture of what it gives in a ring of stitched leather that runs out into a point the way to it (up: ahead, down: behind you), and how far away it is under it; one outside your view at the screen's edge, on the side you would turn to. Placed roughly: the game tells no addon where its camera looks, so they take it to be behind you, and while you turn the camera with the left mouse button they wait until you ride on or turn with the right one.",
    nodeYards = "Switch finders every",
    nodeYardsTip = "How far you move before the next finder comes on. With two or more of Found herbs, Found ore and Found fishing pools on in the pin filter and their spells known (Find Herbs, Find Minerals, Find Fish), they take turns, round and round, without a sound, so the map finds them all; those you do not know are left out. As fast as the global cooldown lets it. 0: they do not switch.",
    followMap = "Follow me",
    followMapTip = "The map keeps you in its middle as you move. Dragged away, the minimap snaps back to you the moment you walk; the full map opens on you and comes back as you walk once you left it alone for 10 seconds (also after a quest or a map chosen). Off: the full map stays where you leave it, and so does the minimap once you moved it, until the middle mouse button brings it back to you.",
    classicMinimap = "Minimap",
    classicMap = Core.Word("WORLD_MAP", "World Map"),
    noPin = Core.Word("MAP_PIN_INVALID_MAP", "A map pin cannot be placed here."),
    about = "the map full screen and back (/sane map reset: the window's first place and size; /sane map find <words>: the map's search)",
    -- The Sane Rare tracker (RareTracker.lua).
    rareTracker = "Sane Rare tracker",
    rareOn = "Tell of finds near you",
    rareOnTip = "A rare, a treasure, a book you still need or an event near you is told the moment the game shows it: a horn, and a notice at the screen's right edge under the minimap: the rare's own 3D model, its name, what it is and its level, how far it is and which way. The mouse on it: its tooltip as on the map, with its abilities and its loot. A double click puts the map pin on it and the golden line leads there; a right click sends it away; drag it with the left mouse button to put the notices where you like (/sane testraretracker reset: under the minimap again). It stays until you right click it, the rare is dead, the treasure taken or the book gathered, or you are " .. Core.Distance(400) .. " away (RareTracker.FAR); a /reload clears them too. Seen again while it shows, it stays as it is, without a sound; told again after 5 minutes at the earliest; never inside a dungeon or raid. /sane testraretracker shows one (chest, book, event: theirs).",
    rareKinds = "What it tells of",
    rareKindsTip = "Rares: the game's mark of one near you, or the rare itself as soon as you see it (its nameplate, your target, the mouse on it). Treasures: the game's mark of a chest near you, or a chest your interact key picks. Books: a book a librarian asks for, as you come within " .. Core.Distance(100) .. " of it or your interact key picks it, while you still need it (not in your bags or bank, its quest not done). Events: the game's other marks near you. Forever's world has no marks: there rares are found in person, chests by the interact key, books by where they stand.",
    rareSound = "Its sound",
    rareSoundTip = "What plays when the Sane Rare tracker tells of something: one of the game's own sounds, at the game's master volume. Chosen here, it plays once.",
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
-- (ns.PIN_SECTIONS); one without a known section in the last. A kind only Core's data has (data: its sets) is in
-- the filter only while one of them is there (ns.KindOffered): not in Retail, until its data comes.
local SPAWNS, SERVICES = { "Spawns" }, { "Spawns", "Places" }
ns.KINDS = {
    { "route", ns.TEXT.route, section = "around", on = true, small = true, icon = "poi-traveldirections-arrow" },
    { "minimap", ns.TEXT.minimap, section = "around", on = true, small = true, icon = "monsterneutral" },
    { "log", ns.TEXT.log, section = "quests", on = true, small = true, icon = "questturnin" },
    { "quest", ns.TEXT.offers, section = "quests", on = true, small = true, icon = "questnormal", data = SPAWNS },
    { "low", ns.TEXT.low, section = "quests", on = true, small = true, icon = "trivialquests", grey = true,
      data = SPAWNS },
    { "later", ns.TEXT.later, section = "quests", on = true, small = true, icon = "questturnin", tint = { 255, 51, 38 },
      data = SPAWNS },
    { "done", ns.TEXT.done, section = "quests", on = false, small = true, icon = "islands-questbangdisable", grey = true,
      data = SPAWNS },
    { "area", "Quest areas", section = "quests", on = true, small = true, icon = "questblob" },
    -- The quest areas on the minimap too, ours and the game's minimap's own with the ring round its edge: off at first
    -- (Saneroki, 2026-11-09), the opacity Quest areas' slider.
    { "minimapArea", "Quest areas on the minimap", section = "quests", on = false, small = true, icon = "questblob" },
    { "goal", "Quest objectives", section = "quests", on = true, small = true, texture = "Interface\\CURSOR\\Attack",
      data = SPAWNS },
    { "flight", "Flight points", section = "travel", on = true, small = true, icon = "flightmaster" },
    { "travel", "Boats, zeppelins and portals", section = "travel", on = true, small = true, icon = "flightmasterferry" },
    { "entrance", "Dungeons and raids", section = "travel", on = true, small = true, icon = "dungeon" },
    { "place", "Places", section = "towns", on = true, small = true, icon = "poi-town" },
    { "service", "Services", section = "towns", on = true, small = true, icon = "innkeeper", data = SERVICES },
    { "rare", "Rares", section = "finds", on = true, small = true, icon = "dungeonskull" },
    { "treasure", "Treasures", section = "finds", on = true, icon = "vignetteloot" },
    { "herb", "Possible herbs", section = "gathering", on = true, small = true, icon = "professions_tracking_herb",
      data = SPAWNS },
    { "ore", "Possible ore", section = "gathering", on = true, small = true, icon = "professions_tracking_ore",
      data = SPAWNS },
    -- What the game's minimap shows now (Found.lua); each switches its finder (Nodes.lua). Their icons: the
    -- finders' own, Find Herbs, Find Minerals and Find Fish. The fishing pools are drawn by the game's minimap
    -- alone (Minimap dots): no pin of ours, no size.
    { "foundHerb", "Found herbs", section = "gathering", on = true, small = true, texture = 133939 },
    { "foundOre", "Found ore", section = "gathering", on = true, small = true, texture = 136025 },
    { "foundFish", "Found fishing pools", section = "gathering", on = true, small = true, texture = 133888 },
    { "book", "Books", section = "finds", on = false, icon = "lorewalking-map-icon", data = SPAWNS },
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

-- Whether one of Core's sets can be had: ready, or still being read with Core. Not where Core refuses it or holds
-- none (Retail, until its data comes): what needs it stands down there, with no view, no switch and no word.
function ns.Has(name)
    local state = Core.Data.Set(name):State()
    return state == "ready" or state == "loading"
end

-- Whether a kind of pin can show anything here: one only Core's data has while one of its sets is there.
function ns.KindOffered(kind)
    if not kind.data then return true end
    for _, name in ipairs(kind.data) do
        if ns.Has(name) then return true end
    end
    return false
end

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
-- One kind of pin on or off, kept in the setting Pins on the map (the pin filter, the satchel).
function ns.SwitchPin(key)
    local chosen = {}
    for name, on in pairs(type(ns.options.pins) == "table" and ns.options.pins or {}) do chosen[name] = on end
    chosen[key] = not ns.Pins.Shows(key) or nil
    Core.Set(ns.name, "pins", chosen)
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

-- The ways to draw the map, in the order of their buttons (shown as Parchment, Blended, Scrying). Scrying and
-- Blended only while Core's terrain is (Terrain.Possible: not in Retail, until its data comes). The map starts as
-- Scrying; a view not offered (a saved one that is gone) falls back to Scrying, and where that is not offered either
-- to Parchment, the game's own map art (ns.Fallback).
ns.VIEWS = { "sketches", "blend", "terrain" }
ns.FALLBACK = "terrain"
local CHOICES = { { "sketches", ns.TEXT.views.sketches }, { "blend", ns.TEXT.views.blend },
                  { "terrain", ns.TEXT.views.terrain } }

-- The switches of what this game cannot have stand down (hidden): the trip and the docks need Core's set Travel; the
-- sparkles Core's herbs and ore (Nodes.Known), the far ones also the game's minimap's answers (Found.Works), the turns
-- a game whose finders take turns (Nodes.TOGETHER: Retail's tracking holds them all at once).
local function NoTravel() return not ns.Has("Travel") end
local SPARKLES = { key = "nodeSparkles", default = true, text = ns.TEXT.nodeSparkles, tip = ns.TEXT.nodeSparklesTip,
                   header = ns.TEXT.nodes, hidden = function() return not ns.Nodes.Known() end }
local GLINTS = { key = "nodeGlints", default = true, text = ns.TEXT.nodeGlints, tip = ns.TEXT.nodeGlintsTip,
                 hidden = function() return not (ns.Nodes.Known() and ns.Found.Works()) end }
local TURNS = { key = "nodeYards", default = 15, min = 0, max = 50, step = 1, distance = true,
                text = ns.TEXT.nodeYards, tip = ns.TEXT.nodeYardsTip, hidden = function() return ns.Nodes.TOGETHER end }

-- The Sane Rare tracker's: what it tells of (RareTracker.Kind), and its sounds (RareTracker.SOUNDS; none: silent).
local RARE_KINDS = { { "rare", "|A:dungeonskull:16:16|a Rares" }, { "treasure", "|A:vignetteloot:16:16|a Treasures" },
                     { "book", "|A:lorewalking-map-icon:16:16|a Books" }, { "event", "|A:vignetteevent:16:16|a Events" } }
local RARE_SOUNDS = { { "horn", "War horn" }, { "chime", "Find chime" }, { "warning", "Raid warning" }, { "none", "None" } }

local OPTIONS = {
    -- Every view a choice while the settings are first read; at login only those offered, and the view the map
    -- starts in here the default (Offer). One view alone: no setting (ns.Several).
    { key = "view", default = ns.FALLBACK, text = ns.TEXT.view, header = ns.TEXT.title, tip = ns.TEXT.viewTip,
      choices = { CHOICES[1], CHOICES[2], CHOICES[3] }, hidden = function() return not ns.Several() end },
    { key = "pins", default = PIN_DEFAULT, multi = true, choices = PIN_CHOICES, text = ns.TEXT.pins, tip = ns.TEXT.pinsTip },
    -- Each kind's size in percent, [kind] = percent, set by its slider in the pin filter (TopBar.lua): no
    -- control on the options page.
    { key = "pinSizes", default = {} },
    -- The views keep the player in their middle and come back to the player (Canvas.lua, Again); also the box beside
    -- the pin filter on the full map's bar (TopBar.lua).
    { key = "followMap", default = true, text = ns.TEXT.followMap, tip = ns.TEXT.followMapTip },
    { key = "tripView", default = true, text = ns.TEXT.tripView, tip = ns.TEXT.tripViewTip, hidden = NoTravel },
    { key = "dockTimes", default = true, text = ns.TEXT.dockTimes, tip = ns.TEXT.dockTimesTip, hidden = NoTravel },
    { key = "nativeMinimap", default = false, text = ns.TEXT.nativeMinimap, tip = ns.TEXT.nativeMinimapTip },
    { key = "nativeMap", default = false, text = ns.TEXT.nativeMap, tip = ns.TEXT.nativeMapTip },
    { key = "questLogRest", default = true, text = ns.TEXT.questLogRest, tip = ns.TEXT.questLogRestTip },
    { key = "questLogRestGroup", default = false, text = ns.TEXT.questLogRestGroup, tip = ns.TEXT.questLogRestGroupTip,
      parent = "questLogRest" },
    SPARKLES, GLINTS, TURNS,
    { key = "rareTracker", default = true, text = ns.TEXT.rareOn, tip = ns.TEXT.rareOnTip, header = ns.TEXT.rareTracker },
    { key = "rareKinds", default = { rare = true, treasure = true, book = true, event = true }, multi = true,
      choices = RARE_KINDS, text = ns.TEXT.rareKinds, tip = ns.TEXT.rareKindsTip, parent = "rareTracker" },
    { key = "rareSound", default = "horn", choices = RARE_SOUNDS, text = ns.TEXT.rareSound, tip = ns.TEXT.rareSoundTip,
      parent = "rareTracker" },
}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, #OPTIONS + 1)

-- Settings of an older shape: 1, the switch Route to the map pin became a kind of the pin filter, as the game's
-- minimap's dots did (both on, but a route switched off); 2, the quests split: those in the log as Quests were,
-- the low and later ones on; 3, the found herbs and ore came, on; 4, the found fishing pools came, on, and the
-- finders' turns went from seconds to yards (the seconds let go: the yards at first); 5, the quests' objectives
-- came, on.
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
        if from < 4 then values.pins.foundFish = true end
        if from < 5 then values.pins.goal = true end
    end
    values.route = nil
    values.nodeTurns = nil
end

local routed -- whether the pin filter let the route through when it last changed
local found -- the found kinds the pin filter let through when it last changed (Nodes.Wanted: "herb ore fish")
Core.Options(ns.name, OPTIONS, { version = 5, upgrade = Upgrade, changed = function(key)
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
        -- The finders switched only when Found herbs, Found ore or Found fishing pools changed.
        local now = ns.Nodes.Wanted()
        if found and now ~= found then ns.Guarded(ns.Nodes.Apply) end
        found = now
        ns.Guarded(ns.Nodes.Update)
        ns.Guarded(ns.Found.Update)
        ns.Guarded(ns.Satchel.Fill)
        return ns.Guarded(ns.Canvas.Refresh)
    end
    if key == "nativeMinimap" then
        ns.Guarded(ns.Hybrid.Update)
        ns.Guarded(ns.Window.Update)
        return ns.Guarded(ns.Native.Update)
    end
    if key == "nativeMap" then
        ns.Guarded(ns.QuestLog.Tracker)
        return ns.Guarded(ns.Native.Update)
    end
    if key:match("^questLogRest") then return ns.Guarded(ns.QuestLog.Rested) end
    if key == "followMap" then
        ns.Guarded(ns.Canvas.Following)
        return ns.Guarded(ns.TopBar.Update)
    end
    if key == "dockTimes" then return ns.Guarded(ns.DockWatch.Update) end
    if key == "tripView" then return ns.Guarded(ns.TripView.Update) end
    if key == "nodeSparkles" then return ns.Guarded(ns.Sparkles.Settings) end
    if key == "rareTracker" then
        if ns.options.rareTracker == false then ns.Guarded(ns.RareTracker.Hide) end
        return
    end
    if key == "rareSound" then return ns.Guarded(ns.RareTracker.Sound) end
    if key == "nodeGlints" then return ns.Guarded(ns.Glints.Update) end
    if key == "nodeYards" then return ns.Guarded(ns.Nodes.Update) end
end })

-- Whether a view can be drawn: Scrying and Blended only while Core's terrain is; a key that is no view, never.
function ns.Offered(key)
    if key == "blend" or key == "terrain" then return ns.Terrain.Possible() end
    return key == "sketches"
end

-- The view a view not offered falls back to: Scrying, else Parchment.
function ns.Fallback()
    if ns.Offered(ns.FALLBACK) then return ns.FALLBACK end
    return "sketches"
end

-- The view the map is drawn in: the one chosen, if it is offered, else the fallback.
function ns.View()
    local chosen = ns.options.view
    if ns.Offered(chosen) then return chosen end
    return ns.Fallback()
end

-- Whether there is a choice of views: one alone (Retail's Parchment, until its data comes) simply is the map, with
-- no buttons on the full map's bar and no setting.
function ns.Several()
    local count = 0
    for _, key in ipairs(ns.VIEWS) do
        if ns.Offered(key) then count = count + 1 end
    end
    return count > 1
end

-- Whether a switch is on the options page here (its hidden says not).
local function Shows(option)
    return not (option.hidden and option.hidden())
end

-- The views offered, in the settings' dropdown and on the full map's buttons; the default the view the map starts
-- in here, and a saved view not offered (one that is gone; Scrying without Core's terrain) becomes it. The kinds of
-- pin that can show anything here in the setting's list (TopBar's filter asks ns.KindOffered itself), and the
-- section Herbs and ore only while one of its switches is there. At login.
function ns.Offer()
    local option = OPTIONS[1]
    wipe(option.choices)
    for _, choice in ipairs(CHOICES) do
        if ns.Offered(choice[1]) then option.choices[#option.choices + 1] = choice end
    end
    option.default = ns.Fallback()
    if not ns.Offered(ns.options.view) then Core.Set(ns.name, "view", option.default) end
    wipe(PIN_CHOICES)
    for _, kind in ipairs(ns.KINDS) do
        if ns.KindOffered(kind) then PIN_CHOICES[#PIN_CHOICES + 1] = { kind[1], ns.KindLabel(kind) } end
    end
    SPARKLES.header = (Shows(SPARKLES) or Shows(GLINTS) or Shows(TURNS)) and ns.TEXT.nodes or nil
    ns.Window.Arrange()
end

-- Something failed (Core's StandDown calls this once): the game's map and its keys, and the game's minimap,
-- back first, where they were; then the window gone. Each step runs by itself (Safe), so one that fails does
-- not keep the next from its work. What must wait for the end of a fight waits for it.
function ns.GiveBack()
    ns.Safe("giving back", ns.Native.GiveBack)
    ns.Safe("giving back", ns.Satchel.Hide)
    ns.Safe("giving back", ns.Strays.GiveBack)
    ns.Safe("giving back", ns.Hybrid.GiveBack)
    ns.Safe("giving back", ns.Window.Hide)
    ns.Safe("giving back", ns.TripView.Hide)
    ns.Safe("giving back", ns.Found.Hide)
    ns.Safe("giving back", ns.Nodes.GiveBack)
    ns.Safe("giving back", ns.Sparkles.GiveBack)
    ns.Safe("giving back", ns.Glints.Hide)
    ns.Safe("giving back", ns.Corpse.GiveBack)
    ns.Safe("giving back", ns.Taxi.GiveBack)
    ns.Safe("giving back", ns.RareTracker.Hide)
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    -- The terrain's textures, soon after the loading screen: the map shows from login.
    Core.Data.Prepare("Tiles")
    -- A map pin kept from the last session: its route (the walking data is asked for then).
    Core.Later(function() ns.Guarded(ns.Planner.Update) end, 2)()
    ns.Offer()
    ns.Window.Build()
    ns.Hybrid.Start(ns.Canvas.frame)
    ns.Strays.Start()
    ns.Native.Start()
    found = ns.Nodes.Wanted()
    ns.Nodes.Start()
    ns.Found.Start()
    ns.Sparkles.Start()
    ns.Glints.Start()
    ns.Corpse.Start()
    ns.Taxi.Start()
    ns.RareTracker.Start()
end

Core.Command("map", ns.TEXT.about, function(rest)
    if ns.off then
        ns.Print(ns.TEXT.stopped)
    elseif rest == "reset" then
        ns.Guarded(ns.Window.Reset)
        ns.Print(ns.TEXT.reset)
    elseif rest and rest:match("^find%f[%A]") then
        ns.Guarded(ns.FindBox.Search, (rest:match("^find%s+(.+)$")))
    else
        ns.Guarded(ns.Window.Toggle)
    end
end)
