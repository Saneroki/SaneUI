local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Pins
--  The map's pins as plain records, from what the game tells (Live.lua) and from
--  Core's data (Data.Map), one pin per thing, as the pin filter lets them through.
--  Knows no frames: PinView.lua draws what For gives.
--
--      Pins.For(view, small)   the pins in view: every zone the view shows at a zone's level, the
--                              continents' travel and places further out, none at the world; one map at
--                              a time (Retail), the map shown's
--      Pins.Gather(list, k)    pins that would cover each other on the screen, gathered (Gather below)
--      Pins.Standing(quest, id) where a quest of Core's data stands for this character, and why (offered, low,
--                              later, log, done, never)
--      Pins.Offered(quest)     whether this character can take a quest of Core's data now
--
--  A pin: kind (the filter's, Pins.KINDS), key (one per pin: a thing of Core's data with several points on a
--  map has a pin at each, its key the thing's and the point's), thing (a pin of Core's data: the thing's key,
--  "npc:69", as the game's pins are keyed: the game's word hides every one of Core's for the same thing, *One
--  pin per thing*), home (the plane u, v are in: Coords.PlaneOf), u, v, map, x, y (on its own map, 0 to 1),
--  atlas or texture, size, name, role (an NPC's: what it is, its tooltip's heading in place of its name: Bowyer,
--  Warrior Trainer), doubt (the thing is not yet confirmed by the game: the red ! before its name), unverified (its
--  tooltip shows something not yet confirmed: it, or one of its quests), lines (its tooltip's further lines; one of an
--  objective: { quest, index }, its words asked of the game when the tooltip shows), goals (a pin of what a quest of
--  yours asks for, Goals.lua: { { quest, index }, ... }), and by kind: quest (its ID), complete,
--  focused (the quest the game's arrow leads to), to (a map it opens), dim (a flight point not yet found), taxi (at a
--  flight master: the flight point's node, Taxi.lua; here: the one you stand at, size its size there), grey
--  (a quest too low), tint (its icon's colour: a quest for later, a flight point not yet found), order (drawn over
--  a lower one).
--
--  What the game tells is read per map when it said it changed (the message LIVE), Core's places when they
--  change (Data.Map's OnChange); each map's pins are kept until then, so a layout only places them. Both are
--  kept in parts: of the game's, the quests', the flight points', the vignettes' and the points' each read again
--  when the game said that changed (Pins.Changed); of Core's, the NPCs' are read again when the log or the level
--  changed (what this character can take), the objects' and the places' and ways' only when Core's places change.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live = ns.Coords, ns.Live
local Pins = {}
ns.Pins = Pins

-- The filter's kinds (Navigation.lua: they are its setting's choices).
Pins.KINDS = ns.KINDS
Pins.CONTINENT = { flight = true, travel = true, entrance = true, place = true } -- kinds shown past a zone
Pins.NEAR = 300       -- yards: services on the small view only so near the player
Pins.GATHER = 18      -- units: pins nearer each other than this on the screen are gathered into one marker
Pins.SIZE = { log = 24, quest = 22, low = 18, later = 18, done = 18, goal = 16, flight = 18, travel = 22, entrance = 22,
              place = 22, service = 20, rare = 20, treasure = 18, herb = 16, ore = 16, book = 18,
              foundHerb = 14, foundOre = 14 } -- (the found ones are drawn by Found.lua)

-- The order pins are drawn in: a higher one over a lower one, and the first in a gathered marker (its icon).
local ORDER = { log = 10, quest = 9, rare = 8, goal = 8, entrance = 7, flight = 6, travel = 5, place = 4, treasure = 3, service = 2,
                later = 1, low = 1, done = 1, herb = 1, ore = 1, book = 0 }

-- Every kind of thing its own icon, from the game's map icons (ObjectIconsAtlas): no discs, no numbers.
-- The quests as the game marks them: in your log the yellow question mark, to take the yellow exclamation mark, too
-- low the grey one, for later the question mark in red (Pins.RED).
Pins.ICONS = {
    log = "questturnin", offer = "questnormal", grey = "trivialquests", later = "questturnin",
    done = "islands-questbangdisable", rare = "dungeonskull", treasure = "vignetteloot",
}
Pins.RED = { 1, 0.2, 0.15 } -- over the yellow mark: the game's red
-- Core's services: an NPC's first service with an icon gives its pin's (a trainer: Trainer below).
local SERVICES = {
    repair = "repair", innkeeper = "innkeeper", banker = "banker", auctioneer = "auctioneer",
    stablemaster = "stablemaster", battlemaster = "battlemaster", trainer = "profession", weaponmaster = "upgradeitem-32x32",
    vendor = "repair", guildmaster = "crossedflags", tabard = "crossedflags", spirithealer = "poi-soulspiritghost",
}
-- A merchant: the game's anvil, as its own minimap shows merchants (Saneroki, 2026-10-20); one of a kind of goods
-- the game's minimap tracks: by the first of them with an icon.
local GOODS = { food = "food", reagents = "reagents", poisons = "poisons", ammunition = "ammunition", potions = "greencross",
                tradegoods = "gear" }
-- A trainer of a class (its title names one of the game's classes) is the class book; of a profession, the scroll.
local CLASS_TRAINER = "class"
-- A service's words in the tooltip.
Pins.SERVICE_WORDS = {
    repair = "Repairs", innkeeper = "Innkeeper", banker = "Banker", auctioneer = "Auctioneer",
    stablemaster = "Stable master", battlemaster = "Battlemaster", trainer = "Trainer", weaponmaster = "Weapon master",
    vendor = "Vendor", guildmaster = "Guild master", tabard = "Tabard vendor", spirithealer = "Spirit healer",
    flightmaster = "Flight master", questgiver = "Quests", guard = "Guard",
}
-- Core's places and ways: the filter's kind and the game's atlas for each.
local PLACES = {
    crossing = { "place", "poi-door-arrow-up" }, cave = { "place", "caveunderground-down" },
    dungeon = { "entrance", "dungeon" }, raid = { "entrance", "raid" }, pier = { "travel", "flightmasterferry" },
    mailbox = { "service", "mailbox" }, meetingstone = { "place", "teleportationnetwork-32x32" },
    spirithealer = { "service", "poi-soulspiritghost" },
}
local WAYS = { boat = "flightmasterferry", zeppelin = "vehicle-air-horde", tram = "vehicle-alliancecart",
               lift = "poi-door-up", portal = "mageportalalliance" }
Pins.WAY_ICONS = WAYS
local OBJECTS = { herb = { "herb", "professions_tracking_herb" }, ore = { "ore", "professions_tracking_ore" },
                  chest = { "treasure", Pins.ICONS.treasure }, mailbox = { "service", "mailbox" },
                  book = { "book", "lorewalking-map-icon" } }
Pins.TEXT = {
    turnIn = Core.Word("QUEST_WATCH_QUEST_READY", "Ready for turn-in"),
    offered = "A quest to take",
    done = "Quests you have done",
    quest = "%s (level %d)",
    low = "Too low to give you experience",
    later = "Not yet for you",
    needsLevel = Core.Word("ITEM_MIN_LEVEL", "Requires Level %d"),
    needsFirst = "First: %s",
    needsOne = "First one of: %s",
    preview = "Click on the full map: its quests in the quest log",
    undiscovered = "Not discovered yet",
    open = "Click on the full map: the quest in the quest log",
    openMap = "Shift-click: open its map",
    unverified = Core.UNCONFIRMED, -- (Core.Unconfirmed)
    questGiver = "Quest giver",
    level = "Level %d to %d",
    towards = "To %s",
    ports = "Its ports, in the order it travels to them:",
    port = "%d. %s",
    thisPort = "%d. %s (this port)",
    -- What a thing gives, on its pin's tooltip (PinView.Drops)
    dropsCorpse = "Drops, per corpse looted",
    dropsNode = "Gives, per gather",
    dropsChest = "Holds, each time opened",
    dropChance = "%s%%",
    dropCounted = "%s%% (%d of %d)",
    dropCount = "%d of %d",
    dropUnder = "under 1%",
    dropSkinned = " (skinned)",
    dropPicked = " (pickpocket)",
}
-- A way's kind in the tooltip.
Pins.WAY_WORDS = { boat = "Boat", zeppelin = "Zeppelin", tram = "Tram", lift = "Lift", portal = "Portal" }

local Map = Core.Data.Map()
local Ships = Core.Data.Ships()

-------------------------------------------------------------------------------
--  What the game tells, per map
-------------------------------------------------------------------------------
-- [part][uiMapID] = its live pins of that part, until the game says that part changed: the quests', the flight points',
-- the vignettes' (rares, treasures), the game's own points'.
local live = { quests = {}, flights = {}, vignettes = {}, points = {} }
local joined = {} -- [uiMapID] = its live pins of every part in one list (For reads one a map), until a part was read anew
-- [part][uiMapID] = its pins of Core's data of that part, until what they follow changes: the NPCs' (their quests),
-- the objects' (herbs, ore, chests...), the places' and ways', the spawns of your quests' open objectives.
local data = { npc = {}, object = {}, way = {}, goal = {} }
local PARTS = { npc = "npc", object = "object", place = "way", travel = "way" } -- a place's part, by its kind
local faction    -- the player's side, asked once

-- The pin's place in its plane (a continent's, or Zephras Isle's), from a point on its map (0 to 1); false when the
-- map has none.
local function Placed(pin, map, x, y)
    local home = Coords.PlaneOf(map)
    if not home then return false end
    local u, v = Coords.MapToPlane(map, x, y, home)
    if not u then return false end
    pin.home, pin.u, pin.v, pin.map, pin.x, pin.y = home, u, v, map, x, y
    return true
end

local function Add(list, pin, map, x, y)
    if type(x) == "number" and type(y) == "number" and Placed(pin, map, x, y) then list[#list + 1] = pin end
end

local function Vector(position)
    if type(position) ~= "table" then return nil end
    return Core.Plain(position.x), Core.Plain(position.y)
end

-- The creature or object a game's GUID names: "npc:<id>" or "object:<id>", as Core's keys are.
local function Thing(guid)
    if type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind == "Creature" or kind == "Vehicle" then return "npc:" .. id end
    if kind == "GameObject" then return "object:" .. id end
    return nil
end

-- The quests the game puts on a map: in progress, ready to turn in, and the next way of the quest it leads to.
local function Quests(list, map)
    local focused = Core.Plain(Core.Ask(C_SuperTrack.GetSuperTrackedQuestID))
    local seen = {}
    for _, info in ipairs(Live.Quests(map)) do
        local quest = info.questID
        if quest and not info.isMapIndicatorQuest and not seen[quest] then
            seen[quest] = true
            local complete = Core.Ask(C_QuestLog.IsComplete, quest) and true or false
            Add(list, { kind = "log", key = "quest:" .. quest, quest = quest, complete = complete, focused = quest == focused,
                        atlas = Pins.ICONS.log,
                        name = Core.Ask(C_QuestLog.GetTitleForQuestID, quest), click = "quest" }, map, info.x, info.y)
        end
    end
    if focused and focused > 0 and not seen[focused] then
        local x, y = Core.Ask(C_QuestLog.GetNextWaypointForMap, focused, map)
        if x then
            local complete = Core.Ask(C_QuestLog.IsComplete, focused) and true or false
            Add(list, { kind = "log", key = "quest:" .. focused, quest = focused, focused = true, way = true,
                        complete = complete, atlas = Pins.ICONS.log,
                        name = Core.Ask(C_QuestLog.GetTitleForQuestID, focused), click = "quest" }, map, x, y)
        end
    end
end

-- The flight points of the player's side and the neutral ones, as the game's map shows them; one this character has
-- not found (Planner.Knows: learnt at a flight master, as the routes fly) red, and its tooltip says so.
local function Flights(list, map)
    faction = faction or Core.Plain(UnitFactionGroup("player"))
    local sides = rawget(_G, "Enum") and Enum.FlightPathFaction or {}
    for _, info in ipairs(Live.Flights(map)) do
        local side = info.faction
        if not ((side == sides.Horde and faction ~= "Horde") or (side == sides.Alliance and faction ~= "Alliance")) then
            local atlas = info.atlasName
            if atlas and info.textureKit then atlas = info.textureKit .. "-" .. atlas end
            local x, y = Vector(info.position)
            local found = ns.Planner and ns.Planner.Knows(info.nodeID)
            local pin = { kind = "flight", key = "flight:" .. tostring(info.nodeID), id = info.nodeID, name = info.name,
                          atlas = atlas or "TaxiNode_Neutral", dim = not found or nil, tint = not found and Pins.RED or nil,
                          lines = not found and { Pins.TEXT.undiscovered } or nil }
            -- At a flight master (Taxi.lua): large, as the master tells it, a click flies there.
            local taxi = ns.Taxi.Node(info.nodeID)
            if taxi then
                pin.taxi, pin.size, pin.here = info.nodeID, ns.Taxi.SIZE, taxi.current or nil
                pin.dim, pin.tint = not (taxi.current or taxi.reachable) or nil, nil
                pin.lines = ns.Taxi.Lines(info.nodeID)
            end
            Add(list, pin, map, x, y)
        end
    end
end

-- Rares, treasures and the game's other marks nearby: rares and treasures in their kind's icon, the rest in the
-- game's own atlas.
local function Vignettes(list, map)
    for _, entry in ipairs(Live.Vignettes(map)) do
        local info = entry.info
        if info.onWorldMap ~= false or info.onMinimap then
            local atlas = info.atlasName or "VignetteKill"
            local kind = atlas:find("Loot") and "treasure" or (atlas:find("Kill") and "rare") or "place"
            if kind ~= "place" then atlas = Pins.ICONS[kind] end
            local key = Thing(info.objectGUID) or ("vignette:" .. tostring(entry.guid))
            Add(list, { kind = kind, key = key, name = info.name, atlas = atlas, live = true }, map, entry.x, entry.y)
        end
    end
end

-- The game's own points (towns, events), the ways into another map, and dungeon entrances where it has them.
local function Points(list, map)
    for _, info in ipairs(Live.Points(map)) do
        local x, y = Vector(info.position)
        local atlas = info.atlasName
        if atlas and info.textureKit then atlas = info.textureKit .. "-" .. atlas end
        Add(list, { kind = "place", key = "poi:" .. tostring(info.areaPoiID), name = info.name, atlas = atlas or "poi-town",
                    lines = info.description and info.description ~= "" and { info.description } or nil }, map, x, y)
    end
    for _, info in ipairs(Live.Links(map)) do
        local x, y = Vector(info.position)
        Add(list, { kind = "travel", key = "link:" .. tostring(info.linkedUiMapID), name = info.name,
                    atlas = info.atlasName or "poi-door-arrow-up", to = info.linkedUiMapID, click = "map",
                    lines = { Pins.TEXT.openMap } }, map, x, y)
    end
    for _, info in ipairs(Live.Entrances(map)) do
        local x, y = Vector(info.position)
        Add(list, { kind = "entrance", key = "entrance:" .. tostring(info.journalInstanceID or info.name), name = info.name,
                    atlas = info.atlasName or "Dungeon",
                    lines = info.description and info.description ~= "" and { info.description } or nil }, map, x, y)
    end
end

local READERS = { { "quests", Quests }, { "flights", Flights }, { "vignettes", Vignettes }, { "points", Points } }

local function LiveOn(map)
    local list = joined[map]
    if list then return list end
    list = {}
    for _, reader in ipairs(READERS) do
        local part, pins = reader[1], live[reader[1]][map]
        if not pins then
            pins = {}
            reader[2](pins, map)
            live[part][map] = pins
        end
        for _, pin in ipairs(pins) do list[#list + 1] = pin end
    end
    joined[map] = list
    return list
end

-------------------------------------------------------------------------------
--  Core's data, per map
-------------------------------------------------------------------------------
local me -- { level, side, race, class }: asked at each layout's first question

local function Me()
    local side = Core.Plain(UnitFactionGroup("player"))
    me = { level = Core.Plain(UnitLevel("player")) or 1, side = side and side:lower(),
           race = select(3, UnitRace("player")), class = select(3, UnitClass("player")) }
end

local QUESTS = Core.Data.Set("Quests")
-- The sets a place of Core's data comes from, for whether the game has confirmed it (Unverified).
local SPAWNS, NPC_FACTS, OBJECT_FACTS = Core.Data.Set("Spawns"), Core.Data.Set("NPCs"), Core.Data.Set("Objects")
local CREATURES = Core.Data.Set("CreatureSpawns")
local PLACE_FACTS, WAYS_SET = Core.Data.Set("Places"), Core.Data.Set("Travel")
local function QuestName(id)
    return QUESTS:Get(id, "name") or ("#" .. tostring(id))
end

local function Has(list, value)
    if not list then return true end
    for _, entry in ipairs(list) do if entry == value then return true end end
    return false
end

-- Whether a quest is too low to give this character experience: the game's quest colour grey (its level more than
-- the game's trivial range below the character's, as its own quest colours ask it; the older green range where
-- the client has only that).
local function Trivial(quest)
    local level = quest.level
    if not level or level <= 0 then return false end
    local range = Core.Plain(Core.Ask(rawget(_G, "UnitQuestTrivialLevelRange"), "player"))
    if type(range) ~= "number" then range = Core.Plain(Core.Ask(rawget(_G, "GetQuestGreenRange"), "player")) end
    if type(range) ~= "number" then range = 8 end
    return me.level - level > range
end

-- Where a quest of Core's data stands for this character, and why: "offered" (it may take it now), "low" (it may,
-- but it gives no experience), "later" (once it meets what it asks: its level, a quest first; the reason in words),
-- "log" (in its log), "done", or "never" (not for its side, race or class, past its level, retired, closed).
function Pins.Standing(quest, id)
    if not me then Me() end
    if type(quest) ~= "table" or quest.retired then return "never" end
    if Core.Ask(C_QuestLog.IsQuestFlaggedCompleted, id) then return "done" end
    local index = Core.Ask(C_QuestLog.GetLogIndexForQuestID, id)
    if index and index > 0 then return "log" end
    if quest.side and quest.side ~= me.side then return "never" end
    if not Has(quest.races, me.race) or not Has(quest.classes, me.class) then return "never" end
    if quest.maxLevel and quest.maxLevel > 0 and me.level > quest.maxLevel then return "never" end
    local missing, ones, oneDone
    for _, need in ipairs(quest.requires or {}) do
        if not need.side or need.side == me.side then
            local done = Core.Ask(C_QuestLog.IsQuestFlaggedCompleted, need.quest) and true or false
            if need.kind == "closed" and done then return "never" end
            if need.kind == "done" and not done then missing = missing or need.quest end
            if need.kind == "one" then
                ones = ones or {}
                ones[#ones + 1] = QuestName(need.quest)
                oneDone = oneDone or done
            end
        end
    end
    if (quest.minLevel or 0) > me.level then return "later", Pins.TEXT.needsLevel:format(quest.minLevel) end
    if missing then return "later", Pins.TEXT.needsFirst:format(QuestName(missing)) end
    if ones and not oneDone then return "later", Pins.TEXT.needsOne:format(table.concat(ones, ", ")) end
    if Trivial(quest) then return "low", Pins.TEXT.low end
    return "offered"
end

-- Whether this character can take a quest of Core's data now, and it gives experience.
function Pins.Offered(quest, id)
    return Pins.Standing(quest, id) == "offered"
end

-- Where a dock's boat or zeppelin goes, in the game's words: the area there, and its zone where that is another.
local function Towards(there)
    local info = Core.Ask(C_Map.GetMapInfo, there.map)
    local zone = type(info) == "table" and Core.Plain(info.name) or nil
    local area = there.area and Core.Ask(C_Map.GetAreaInfo, there.area)
    if area == "" then area = nil end
    if area and zone and area ~= zone then return area .. ", " .. zone end
    return area or zone or "?"
end
Pins.Towards = Towards

-- A boat's or zeppelin's ports from its dock number dock, in the order it sails to them, that one last: { { map,
-- area, here } }, by its timetable's stops (Core's Data.Ships: each stop's dock, its number in the record's docks), a
-- port it stops at twice in a row once; nil without a timetable (the tram) or a stop at that dock.
function Pins.Ports(record, timetable, dock)
    if type(record) ~= "table" or type(record.docks) ~= "table" or not timetable then return nil end
    local stops, first = timetable.stops, nil
    for number, stop in ipairs(stops) do
        if stop.dock == dock then first = number break end
    end
    if not first then return nil end
    local areas = type(record.dockAreas) == "table" and record.dockAreas or {}
    local ports, last = {}, dock
    for step = 1, #stops do
        local at = stops[(first - 1 + step) % #stops + 1].dock
        local there = record.docks[at]
        if at ~= last and type(there) == "table" then
            local area = areas[at]
            ports[#ports + 1] = { map = there.map, area = area and area > 0 and area or nil, here = at == dock }
        end
        last = at
    end
    return #ports > 1 and ports or nil
end

-- A trainer's icon: the class book where its title names one of the game's classes, else the profession's scroll.
local classNames -- the game's class names, asked once
local function Trainer(title)
    if not classNames then
        classNames = {}
        for _, list in ipairs({ rawget(_G, "LOCALIZED_CLASS_NAMES_MALE"), rawget(_G, "LOCALIZED_CLASS_NAMES_FEMALE") }) do
            if type(list) == "table" then for _, name in pairs(list) do classNames[#classNames + 1] = name end end
        end
    end
    for _, name in ipairs(classNames) do
        if type(title) == "string" and title:find(name, 1, true) then return CLASS_TRAINER end
    end
    return SERVICES.trainer
end

-- A quest's lines in a pin's tooltip: its name and level, and why it is grey (tables: words and their colour).
-- A quest not yet confirmed by the game has the red ! before its name (Core.UNCONFIRMED_MARK); true then.
local function QuestLines(lines, id, reason, grey)
    local level = QUESTS:Get(id, "level")
    local name = level and Pins.TEXT.quest:format(QuestName(id), level) or QuestName(id)
    local doubt = QUESTS:Unverified(id)
    if doubt then name = Core.UNCONFIRMED_MARK .. name end
    lines[#lines + 1] = grey and { name, 0.6, 0.6, 0.6 } or { name, 1, 0.82, 0 }
    if reason then lines[#lines + 1] = { "  " .. reason, 0.6, 0.6, 0.6 } end
    return doubt
end

-- Whether the game has not confirmed a place of Core's data yet: its spawn or what it is (Core's marks, and what was
-- confirmed in play since, here or by the guild or the group: Data.Confirm).
local function Unverified(place)
    local kind = place.kind
    if kind == "npc" then
        return SPAWNS:Unverified(place.key) or CREATURES:Unverified(place.id) or NPC_FACTS:Unverified(place.id)
    end
    if kind == "object" then return SPAWNS:Unverified(place.key) or OBJECT_FACTS:Unverified(place.id) end
    if kind == "place" then return PLACE_FACTS:Unverified(place.id) end
    if kind == "travel" then return WAYS_SET:Unverified(place.id) end
    return false
end
Pins.Unverified = Unverified

-- A place of Core's data as a pin: what it is says its kind and its look; nil for what the map does not show.
local function FromData(place)
    local what, kind = place.what, place.kind
    -- doubt: the thing itself is not yet confirmed (the red ! before its name); unverified: something its tooltip
    -- shows is not (it, or a quest of it), so the tooltip ends with Unconfirmed Data
    local doubt = Unverified(place) or nil
    local pin = { key = place.key, name = place.name, unverified = doubt, doubt = doubt }
    if kind == "npc" then
        -- Its quests by where they stand for this character: offered, too low or for later (its pin red while one
        -- is for later), done.
        local offers, greys, done, grey = {}, {}, {}, nil
        for _, quest in ipairs(type(what) == "table" and what.quests or {}) do
            local standing, reason = Pins.Standing(QUESTS:Get(quest), quest)
            if standing == "offered" then
                offers[#offers + 1] = quest
            elseif standing == "low" or standing == "later" then
                greys[#greys + 1] = { quest, reason }
                grey = (grey == "later" or standing == "later") and "later" or "low"
            elseif standing == "done" then
                done[#done + 1] = quest
            end
        end
        local services = what.services or {}
        local service
        for _, each in ipairs(services) do
            if SERVICES[each] then service = each break end
        end
        -- Named by what it is, never by its own name (Saneroki, 2026-10-23): its title (Bowyer, Warrior Trainer), else
        -- its first service (Innkeeper), else a quest giver; only a rare keeps its name (it is what is hunted).
        local role = what.title
        if not role then
            for _, each in ipairs(services) do
                if each ~= "repair" and each ~= "questgiver" and Pins.SERVICE_WORDS[each] then role = each break end
            end
        end
        local lines = {}
        if #offers > 0 then
            pin.kind, pin.atlas, pin.offer = "quest", Pins.ICONS.offer, true
        elseif what.rare then
            pin.kind, pin.atlas = "rare", Pins.ICONS.rare
        elseif service then
            -- The game's flight points stand for the flight masters (One pin per thing, point 6).
            local atlas = SERVICES[service]
            if service == "trainer" then atlas = Trainer(what.title) end
            if service == "vendor" then
                for _, goods in ipairs(what.goods or {}) do
                    if GOODS[goods] then atlas = GOODS[goods] break end
                end
            end
            pin.kind, pin.atlas, pin.service = "service", atlas, true
            local words = {}
            for _, each in ipairs(services) do
                -- A trainer's title says what it trains (Warrior Trainer): the word Trainer only without one.
                if Pins.SERVICE_WORDS[each] and each ~= role and not (each == "trainer" and what.title) then
                    words[#words + 1] = Pins.SERVICE_WORDS[each]
                end
            end
            if #words > 0 then lines[#lines + 1] = table.concat(words, ", ") end
        elseif grey == "later" then
            pin.kind, pin.atlas, pin.tint = "later", Pins.ICONS.later, Pins.RED
        elseif grey then
            pin.kind, pin.atlas, pin.grey = "low", Pins.ICONS.grey, true
        elseif #done > 0 then
            -- Only quests this character has done: a pin of the kind Done quests (off at first), grey.
            pin.kind, pin.atlas, pin.grey = "done", Pins.ICONS.done, true
            lines[#lines + 1] = Pins.TEXT.done
            for _, quest in ipairs(done) do
                if QuestLines(lines, quest, nil, true) then pin.unverified = true end
            end
        else
            return nil
        end
        -- What it offers, and what it will offer: a click shows them in the quest log.
        pin.quests = {}
        for _, quest in ipairs(offers) do
            if QuestLines(lines, quest, nil, false) then pin.unverified = true end
            pin.quests[#pin.quests + 1] = quest
        end
        for _, entry in ipairs(greys) do
            if QuestLines(lines, entry[1], entry[2], true) then pin.unverified = true end
            pin.quests[#pin.quests + 1] = entry[1]
        end
        if #pin.quests > 0 then
            pin.click = "preview"
            lines[#lines + 1] = { Pins.TEXT.preview, 0.5, 0.5, 0.5 }
        end
        pin.lines = #lines > 0 and lines or nil
        pin.roles = services
        pin.rare = what.rare -- also one that offers a quest: what it gives is told all the same
        if not what.rare then pin.role = Pins.SERVICE_WORDS[role] or role or Pins.TEXT.questGiver end
    elseif kind == "object" then
        local look = OBJECTS[what]
        if not look then return nil end
        pin.kind, pin.atlas = look[1], look[2]
        pin.service = look[1] == "service" -- a mailbox: on the small map only near the player, as every service
    elseif kind == "place" then
        local look = PLACES[what]
        if not look then return nil end
        pin.kind, pin.atlas = look[1], look[2]
        pin.service = look[1] == "service"
        if place.to then pin.to, pin.click = place.to, "map" end
        if place.levelMin and place.levelMax then pin.lines = { Pins.TEXT.level:format(place.levelMin, place.levelMax) } end
        -- A dungeon's entrance whose map Core's set Dungeons has: Shift and a click opens it.
        local inside = not pin.to and place.instance and ns.Dungeons.Key(place.instance)
        if inside then
            pin.to, pin.click = inside, "map"
            pin.lines = pin.lines or {}
            pin.lines[#pin.lines + 1] = Pins.TEXT.openMap
        end
    elseif kind == "travel" then
        -- Named by its kind where it has no name of its own (a lift).
        pin.kind, pin.atlas, pin.name = "travel", WAYS[what] or WAYS.boat, pin.name or Pins.WAY_WORDS[what]
        if place.towards then
            -- A dock: the game's own way (its TaxiPath tables), where it goes from here.
            pin.unverified, pin.doubt, pin.lines = nil, nil, {}
            pin.way, pin.dock = place.id, place.dock -- its timer in its tooltip (PinView.lua, DockWatch.Timer)
            -- A boat's or zeppelin's every port, in the order it travels to them from here (Saneroki, 2026-11-09);
            -- the tram's other station.
            local ports = place.dock and Pins.Ports(WAYS_SET:Get(place.id), Ships:Table(place.id), place.dock)
            if ports then
                pin.lines[1] = { Pins.TEXT.ports, 1, 0.82, 0 }
                for number, port in ipairs(ports) do
                    pin.lines[#pin.lines + 1] = port.here and { Pins.TEXT.thisPort:format(number, Towards(port)), 0.6, 0.6, 0.6 }
                        or Pins.TEXT.port:format(number, Towards(port))
                end
            else
                for _, there in ipairs(place.towards) do
                    pin.lines[#pin.lines + 1] = Pins.TEXT.towards:format(Towards(there))
                end
            end
            if place.to then
                pin.to, pin.click = place.to, "map"
                pin.lines[#pin.lines + 1] = Pins.TEXT.openMap
            end
        end
    else
        return nil
    end
    return pin
end

-- A map's pins of what your quests still ask for (Goals.lua): one at each point a thing stands, in the picture of what
-- to do there, the quests it is for in its tooltip. A click leads to its first quest, as a click on the quest's own pin.
local function GoalsOn(map)
    local list = {}
    for thing, wanted in pairs(ns.Goals.Wanted()) do
        local points = ns.Goals.Spots(thing)[map]
        if points then
            local kind, id = thing:match("^(%a+):(%d+)$")
            id = tonumber(id)
            local doubt = Unverified({ kind = kind, key = thing, id = id }) or nil
            local lines, unverified = {}, doubt
            for _, goal in ipairs(wanted.goals) do
                if QuestLines(lines, goal.quest) then unverified = true end
                lines[#lines + 1] = goal
            end
            local name = (kind == "npc" and NPC_FACTS or OBJECT_FACTS):Get(id, "name")
            for index, point in ipairs(points) do
                Add(list, { kind = "goal", key = "goal:" .. thing .. "@" .. map .. ":" .. index, thing = thing, name = name,
                            texture = wanted.texture, goals = wanted.goals, quest = wanted.goals[1].quest, click = "quest",
                            lines = lines, doubt = doubt, unverified = unverified }, map, point.x / 100, point.y / 100)
            end
        end
    end
    return list
end

-- A map's pins of Core's data of one part (PARTS, and the objectives'). A thing with several points there (a herb's
-- every spawn, a wanderer's places) has a pin at each: its key the thing's and its point's, the thing's own kept as its
-- thing.
local function DataOn(map, part)
    local list = data[part][map]
    if list then return list end
    if part == "goal" then
        list = GoalsOn(map)
        data.goal[map] = list
        return list
    end
    local places = Map:On(map)
    if not places then return {} end -- being read: asked again once they are (OnChange)
    list = {}
    for index, place in ipairs(places) do
        local pin = PARTS[place.kind] == part and FromData(place)
        if pin then
            pin.thing, pin.key = pin.key, pin.key .. "@" .. map .. ":" .. index
            Add(list, pin, map, place.x, place.y)
        end
    end
    data[part][map] = list
    return list
end

-------------------------------------------------------------------------------
--  The pins in view
-------------------------------------------------------------------------------
local found = {}    -- For's answer, made anew each time
local hidden = {}   -- things the game's own pins hide, by their keys (scratch)
local taken = {}    -- keys drawn already: a thing two maps tell of is drawn once (scratch)
local shown = {}    -- [kind] = whether the view shows it, as the filter says (scratch)
local NONE = {}

-- The maps whose pins the view shows: each zone in view (and the zone in the middle, should it have none of
-- its own), further out the continent itself too (its flight points, as the game's continent map has them);
-- at the world none. One map at a time (Retail): the map shown, as the game's own map asks for its pins.
local function Maps(view)
    local maps = {}
    if view.level == "world" then return maps end
    if view.shown then
        maps[1] = view.shown
        return maps
    end
    if view.level ~= "zone" then maps[1] = view.map end
    for _, zone in ipairs(Coords.Zones(view.map)) do
        local box = zone.box
        if box.u <= view.right and box.u + box.width >= view.left and box.v >= view.bottom and box.v - box.height <= view.top then
            maps[#maps + 1] = zone.map
        end
    end
    if #maps == 0 and view.zone then maps[1] = view.zone end
    return maps
end

-- The filter's switches: on unless switched off (a kind added later is on as it is at first).
local function Shows(kind)
    local chosen = ns.options and ns.options.pins
    if type(chosen) ~= "table" then return true end
    return chosen[kind] and true or false
end
Pins.Shows = Shows

local SMALL = {}
for _, entry in ipairs(Pins.KINDS) do SMALL[entry[1]] = entry.small end

-- The parts of Core's pins a view reads: at a zone's level all, further out the places' and ways' alone (no NPC or
-- object is of a kind shown past a zone, Pins.CONTINENT).
local ZONE_PARTS, FAR_PARTS = { "npc", "object", "way", "goal" }, { "way" }

-- The gather's grid (Gather): a cell's number, its column times ROW plus its row (no plane's rows reach ROW at any
-- zoom). Herbs and ore are a zone's thousands of places: of each kind, at most one in a cell of it goes on to be
-- sorted and gathered, the others there ride with it (its with), so its marker still counts and names them all. So
-- too a creature's many spawns.
local ROW = 2 ^ 20
local MANY = { herb = 1, ore = 2, goal = 3 }
local firsts = {}           -- [cell and kind] = the first herb or ore in it (scratch)
local rides, rode = {}, 0   -- the lists of those that ride with one, used again

-- The pins in view, as the filter lets them through, for the view as the canvas laid it out (Canvas.view);
-- small: the small window (its fewer kinds, services only near the player at pu, pv).
function Pins.For(view, small, pu, pv)
    wipe(found)
    wipe(hidden)
    wipe(taken)
    wipe(firsts)
    wipe(shown)
    rode = 0
    Me()
    if ns.Goals.Read() then wipe(data.goal) end
    local continentLevel = view.level ~= "zone"
    -- What a quest of yours asks for stands as that, not as what else it is (a rare, a herb); a quest it offers aside.
    local goals = not continentLevel and Shows("goal") and ns.Goals.Wanted() or NONE
    local parts = continentLevel and FAR_PARTS or ZONE_PARTS
    local floor, k, size = math.floor, view.k, Pins.GATHER
    local left, right, top, bottom = view.left, view.right, view.top, view.bottom
    local maps = Maps(view)
    for _, map in ipairs(maps) do
        for _, pin in ipairs(LiveOn(map)) do hidden[pin.key] = true end
    end
    for _, map in ipairs(maps) do
        for pass = 0, #parts do
            local list = pass == 0 and LiveOn(map) or DataOn(map, parts[pass])
            -- A map's pins all stand in its plane: one link into the view's for them all.
            local link = list[1] and Coords.Link(list[1].home, view.map)
            for _, pin in ipairs(link and list or NONE) do
                local kind = pin.kind
                local wanted = shown[kind]
                if wanted == nil then
                    -- (at a flight master the flight points always: Taxi.lua)
                    wanted = (Shows(kind) or kind == "flight" and ns.Taxi.On()) and (not small or SMALL[kind])
                        and (not continentLevel or Pins.CONTINENT[kind]) and true or false
                    shown[kind] = wanted
                end
                -- (a pin of Core's data stands on one map's list alone: only the game's may come twice)
                if wanted and (pass == 0 and not taken[pin.key] or pass > 0 and not hidden[pin.thing]
                               and (kind == "goal" or kind == "quest" or not goals[pin.thing])) then
                    local u, v = link.du + link.su * pin.u, link.dv + link.sv * pin.v
                    local near = not (small and pin.service) or (pu and (u - pu) ^ 2 + (v - pv) ^ 2 <= Pins.NEAR ^ 2)
                    if near and u >= left and u <= right and v <= top and v >= bottom then
                        if pass == 0 then taken[pin.key] = true end
                        pin.pu, pin.pv = u, v -- in the view's plane, for this layout
                        pin.order = ORDER[kind] or 0
                        local many = pass > 0 and MANY[kind]
                        local cell = many and (floor(u * k / size) * ROW + floor(v * k / size)) * 4 + many
                        local first = cell and firsts[cell]
                        if first then
                            local with = first.with
                            if not with then
                                rode = rode + 1
                                with = rides[rode] or {}
                                wipe(with)
                                rides[rode], first.with = with, with
                            end
                            with[#with + 1] = pin
                        else
                            if cell then firsts[cell] = pin end
                            pin.with = nil
                            found[#found + 1] = pin
                        end
                    end
                end
            end
        end
    end
    table.sort(found, function(a, b)
        if a.order ~= b.order then return a.order > b.order end
        return a.key < b.key
    end)
    return found
end

-- Pins nearer each other on the screen than Pins.GATHER units become one marker, at the first one (the one
-- drawn highest), in its icon; quests in the log and offered are never gathered, nor what the game tells is near,
-- nor the flight points at a flight master (Taxi.lua);
-- the quests' objectives only among themselves (goalCells), so none vanishes into a marker of other things.
-- list: For's, sorted; k: the zoom (units a yard). Gives a list of pins and markers ({ gathered = { pins },
-- pu, pv, key }); a herb or ore with others riding with it (For) is a marker of them all.
-- The grid's cells by number (ROW), each a list of the spots { x, y, pin, index } that stand in it, n of them; the
-- lists and the spots are kept to be used again.
local cells, goalCells, lists, spots = {}, {}, {}, {}

-- A pin into a spot's marker, made at the spot's first pin, each with what rides with it.
local function Join(spot, pin, out)
    local gathered = spot.gathered
    if not gathered then
        local first = spot.pin
        gathered = { first }
        for _, rider in ipairs(first.with or NONE) do gathered[#gathered + 1] = rider end
        spot.gathered = gathered
        spot.marker = { gathered = gathered, pu = first.pu, pv = first.pv, key = "gathered:" .. first.key,
                        kind = "gathered", order = first.order }
        out[spot.index] = spot.marker
    end
    if pin == spot.pin then return end
    gathered[#gathered + 1] = pin
    for _, rider in ipairs(pin.with or NONE) do gathered[#gathered + 1] = rider end
end

function Pins.Gather(list, k)
    wipe(cells)
    wipe(goalCells)
    local out, used, made = {}, 0, 0
    local size = Pins.GATHER
    for _, pin in ipairs(list) do
        if pin.kind == "log" or pin.kind == "quest" or pin.live or pin.taxi then
            out[#out + 1] = pin
        else
            local x, y = pin.pu * k, pin.pv * k
            local cx, cy = math.floor(x / size), math.floor(y / size)
            local grid = pin.kind == "goal" and goalCells or cells
            local into
            for dx = -1, 1 do
                for dy = -1, 1 do
                    local cell = not into and grid[(cx + dx) * ROW + cy + dy]
                    if cell then
                        for index = 1, cell.n do
                            local spot = cell[index]
                            if (spot.x - x) ^ 2 + (spot.y - y) ^ 2 < size * size then into = spot break end
                        end
                    end
                end
            end
            if into then
                Join(into, pin, out)
            else
                out[#out + 1] = pin
                local key = cx * ROW + cy
                local cell = grid[key]
                if not cell then
                    used = used + 1
                    cell = lists[used] or {}
                    lists[used], cell.n = cell, 0
                    grid[key] = cell
                end
                made = made + 1
                local spot = spots[made] or {}
                spots[made] = spot
                spot.x, spot.y, spot.pin, spot.index, spot.gathered, spot.marker = x, y, pin, #out, nil, nil
                cell.n = cell.n + 1
                cell[cell.n] = spot
                if pin.with then Join(spot, pin, out) end -- others ride with it: they cover each other already
            end
        end
    end
    return out
end

-------------------------------------------------------------------------------
--  Kept until the game or the data says they changed
-------------------------------------------------------------------------------
-- What the game tells changed, and the live part read again for it: the quests ("waypoint": the quest the game's
-- arrow leads to, theirs alone), the flight points, the vignettes ("zone": a rare or treasure the zone shows), the
-- game's own points; the level: every part.
local LIVE = { quests = "quests", waypoint = "quests", flights = "flights", vignettes = "vignettes", zone = "vignettes",
               points = "points", level = true }

-- What the game tells changed: that part of every map's live pins is read again at the next layout, the other parts
-- kept (a continent's level asks the game for some twenty maps, several questions each); the quests or the level
-- changed, the NPCs' of Core's data too (what this character can take follows its quests and level), and what the
-- quests ask for is looked at again, not its objects', places' and ways'.
function Pins.Changed(what)
    local part = what == nil and true or LIVE[what]
    if not part then return false end
    if part == true then
        for _, lists in pairs(live) do wipe(lists) end
    else
        wipe(live[part])
    end
    wipe(joined)
    if what == nil then
        for _, lists in pairs(data) do wipe(lists) end
        ns.Goals.Stale()
    elseif what == "quests" or what == "level" then
        wipe(data.npc)
        ns.Goals.Stale()
    end
    return true
end

-- Core's places changed: every map's data pins are read again.
function Pins.DataChanged()
    for _, part in pairs(data) do wipe(part) end
    ns.Goals.Forget()
end

Map:OnChange(function()
    Pins.DataChanged()
    if ns.Canvas and ns.Canvas.Refresh then ns.Guarded(ns.Canvas.Refresh) end
end)
-- Something of Core's data confirmed in play: the pins say so no more.
if Core.Data.OnConfirm then
    Core.Data.OnConfirm(function()
        Pins.DataChanged()
        if ns.Canvas and ns.Canvas.Refresh then ns.Guarded(ns.Canvas.Refresh) end
    end)
end
