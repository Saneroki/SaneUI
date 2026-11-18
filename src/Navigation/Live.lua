local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Live
--  What the game tells while playing, read for the map. Knows no frames.
--
--      Live.Player()           the plane's map, the point in its plane, the facing (nil: not known; Coords.Player)
--      Live.Indoors()          inside a building or a cave: IsIndoors, or the game's minimap showing its indoor plan
--      Live.Waypoint()         the game's map pin: its map, x, y (nil: none)
--      Live.SetWaypoint(map, x, y), Live.ClearWaypoint(), Live.Tracked()
--      Live.Group(map)         party and raid members on a map: { unit, x, y } each
--      Live.Quests(map)        the game's quests on a map (C_QuestLog.GetQuestsOnMap)
--      Live.Flights(map)       the flight points of a map (C_TaxiMap.GetTaxiNodesForMap), not the retired ones
--      Live.Retired(name)      whether a flight point is one the game keeps but no longer uses (its name "zz...")
--      Live.Vignettes(map)     rares, chests and the like nearby: { guid, x, y, info } each
--      Live.Points(map)        the game's own points on a map: its area POIs, with their info
--      Live.Links(map)         the ways from a map into another (C_Map.GetMapLinksForMap)
--      Live.Entrances(map)     dungeon entrances, where the game has them (C_EncounterJournal)
--      Live.Explored(map)      the explored parts of a map's art (C_MapExplorationInfo)
--
--  When something changes the game says so by an event; a burst of them is told
--  once on the next frame, as the message LIVE with what changed ("waypoint", also for the quest the
--  game's arrow leads to; "explored", "quests", "group", "vignettes", "points", "flights", "zone", "level"):
--      ns.Listen("LIVE", function(what) ... end)
--  The views ask again then; nothing here asks the game on its own. The player is
--  asked by the canvas every frame while a view follows (two questions to the
--  game, nothing made).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Live = {}
ns.Live = Live

-- The game's events, and what each says changed.
Live.EVENTS = {
    USER_WAYPOINT_UPDATED = "waypoint", SUPER_TRACKING_CHANGED = "waypoint",
    MAP_EXPLORATION_UPDATED = "explored",
    QUEST_LOG_UPDATE = "quests", QUEST_POI_UPDATE = "quests",
    GROUP_ROSTER_UPDATE = "group",
    VIGNETTES_UPDATED = "vignettes", VIGNETTE_MINIMAP_UPDATED = "vignettes",
    AREA_POIS_UPDATED = "points",
    TAXIMAP_OPENED = "flights", TAXI_NODE_STATUS_CHANGED = "flights",
    PLAYER_LEVEL_UP = "level", QUEST_WATCH_LIST_CHANGED = "quests", QUEST_TURNED_IN = "quests",
    ZONE_CHANGED = "zone", ZONE_CHANGED_INDOORS = "zone", ZONE_CHANGED_NEW_AREA = "zone", NEW_WMO_CHUNK = "zone",
}

local due = {} -- [what] = true: told on the next frame

local tell = Core.Later(function()
    for what in pairs(due) do
        due[what] = nil
        ns.Fire("LIVE", what)
    end
end)

-- One listener per event, made once: it notes what changed and asks for the next frame.
for event, what in pairs(Live.EVENTS) do
    ns.On(event, function()
        if ns.off then return end
        due[what] = true
        tell()
    end)
end

-------------------------------------------------------------------------------
--  The player and the map pin
-------------------------------------------------------------------------------
function Live.Player()
    local map, u, v = Coords.Player()
    if not u then return map end
    local facing = Core.Plain(Core.Ask(GetPlayerFacing))
    return map, u, v, facing
end

-- The game's minimap's radius at each zoom step (0, its widest, first) while it shows the ground, yards. Where it
-- shows the indoor plan of a building or a cave instead, every step's is at most two thirds of that.
Live.OUTDOORS = { [0] = 233.33, 200, 166.67, 133.33, 100, 66.67 }
Live.PLAN = 0.7 -- a radius under this share of its step's: the minimap shows its indoor plan

-- Whether the player is inside a building or a cave, as the game has it: IsIndoors (no riding here), or its minimap
-- showing the indoor plan of the part they stand in (Saneroki, 2026-11-06). The game counts the halls one may ride
-- through as outdoors (its table WMOAreaTable: Ironforge's halls, the Undercity, Timbermaw Hold, Booty Bay's tunnel),
-- and IsIndoors says no there; its minimap goes by the part itself.
function Live.Indoors()
    if Core.Ask(IsIndoors) == true then return true end
    local minimap, map = rawget(_G, "Minimap"), rawget(_G, "C_Minimap")
    if not (minimap and minimap.GetZoom and map) then return false end
    local outdoors = Live.OUTDOORS[Core.Ask(minimap.GetZoom, minimap)]
    local radius = Core.Ask(map.GetViewRadius)
    return outdoors ~= nil and type(radius) == "number" and radius > 0 and radius < outdoors * Live.PLAN
end

function Live.Waypoint()
    if not Core.Ask(C_Map.HasUserWaypoint) then return nil end
    local point = Core.Ask(C_Map.GetUserWaypoint)
    local position = type(point) == "table" and point.position
    if not position or not point.uiMapID then return nil end
    return point.uiMapID, position.x, position.y
end

-- Whether the game's arrow on the screen leads to the map pin.
function Live.Tracked()
    return Core.Ask(C_SuperTrack.IsSuperTrackingUserWaypoint) and true or false
end

-- Whether a map's coordinate is one the game takes for its map pin: a number from 0 to 1 (not NaN).
local function OnMap(value)
    return type(value) == "number" and value >= 0 and value <= 1
end

-- Puts the game's map pin on a map, not yet followed by the game's arrow, as its map does; false where the
-- game allows none (an instance, the world map), off the map's edge, or where the game refused it.
function Live.SetWaypoint(map, x, y)
    if not OnMap(x) or not OnMap(y) then return false end
    if not Core.Ask(C_Map.CanSetUserWaypointOnMap, map) then return false end
    local point = Core.Ask(UiMapPoint.CreateFromCoordinates, map, x, y)
    if not point or not pcall(C_Map.SetUserWaypoint, point) then return false end
    C_SuperTrack.SetSuperTrackedUserWaypoint(false)
    return true
end

function Live.ClearWaypoint()
    C_Map.ClearUserWaypoint()
    C_SuperTrack.SetSuperTrackedUserWaypoint(false)
end

-------------------------------------------------------------------------------
--  On a map: each answer a new list, asked when the game said something changed
-------------------------------------------------------------------------------
local function List(value)
    return type(value) == "table" and value or {}
end

-- Party and raid: the game tells their places to its party and raid only.
function Live.Group(map)
    local list = {}
    local raid = IsInRaid()
    local count = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
    for index = 1, count do
        local unit = (raid and "raid" or "party") .. index
        if not UnitIsUnit(unit, "player") then
            local position = Core.Ask(C_Map.GetPlayerMapPosition, map, unit)
            local x, y = position and Core.Plain(position.x), position and Core.Plain(position.y)
            if x and y then list[#list + 1] = { unit = unit, x = x, y = y } end
        end
    end
    return list
end

function Live.Quests(map)
    return List(Core.Ask(C_QuestLog.GetQuestsOnMap, map))
end

-- Whether a flight point is one the game keeps but no longer uses: Blizzard marks such a record by a name that starts
-- with "zz" (Forever's "zzOLDBolder'ok, Riverglades", "zzOLDRiverglades, Farholde Keep" and "zzOLDPowderfuse Port,
-- Riverglades", nodes 3206 to 3208; Saneroki, 2026-11-15: "those are not used and should be removed from the map and
-- search databases").
function Live.Retired(name)
    return type(name) == "string" and name:sub(1, 2):lower() == "zz"
end

-- The flight points the game's map has, without the retired ones (Live.Retired): the map's pins, the search, the
-- flight master's map and the routes all read them here.
function Live.Flights(map)
    local list = {}
    for _, info in ipairs(List(Core.Ask(C_TaxiMap.GetTaxiNodesForMap, map))) do
        if type(info) == "table" and not Live.Retired(Core.Plain(info.name)) then list[#list + 1] = info end
    end
    return list
end

function Live.Vignettes(map)
    local list = {}
    for _, guid in ipairs(List(Core.Ask(C_VignetteInfo.GetVignettes))) do
        local info = Core.Ask(C_VignetteInfo.GetVignetteInfo, guid)
        local position = info and Core.Ask(C_VignetteInfo.GetVignettePosition, guid, map)
        if position then list[#list + 1] = { guid = guid, x = position.x, y = position.y, info = info } end
    end
    return list
end

function Live.Points(map)
    local list = {}
    for _, id in ipairs(List(Core.Ask(C_AreaPoiInfo.GetAreaPOIForMap, map))) do
        local info = Core.Ask(C_AreaPoiInfo.GetAreaPOIInfo, map, id)
        if type(info) == "table" then list[#list + 1] = info end
    end
    return list
end

function Live.Links(map)
    return List(Core.Ask(C_Map.GetMapLinksForMap, map))
end

-- This client may leave the game's dungeon entrances out (its encounter journal is not loaded): none then.
function Live.Entrances(map)
    local journal = rawget(_G, "C_EncounterJournal")
    if not journal or not journal.GetDungeonEntrancesForMap then return {} end
    return List(Core.Ask(journal.GetDungeonEntrancesForMap, map))
end

function Live.Explored(map)
    return List(Core.Ask(C_MapExplorationInfo.GetExploredMapTextures, map))
end
