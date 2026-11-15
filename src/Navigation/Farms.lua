local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Farms
--  Where to farm a thing (Saneroki, 2026-11-15: "where to farm Silk cloth" or "peaceblossom" ... "show dense areas
--  were you could farm them on the map or put custom map pins there that are not tied to the routing but just shows
--  where a lot of enemies are dense clustered that drop those things or zones where these nodes are plenty in"): the
--  places where what gives it stands thickest, for the map's search (Find.lua), and their glow on the full map.
--
--      Farms.Of(find, zone)    its places to farm, the best first (kept while Core's data stays; zone: only there):
--                              each { plane, u, v
--                              (its middle), radius (yards), map, x, y (its zone and the point there), worth (what a
--                              round of it gives), count (spawns), sources ({ key, name, count, worth }, the most
--                              first), low, high (the creatures' levels), nodes (all of them gathered), inside (a
--                              dungeon's map: there, not drawn) }
--      Farms.Draw(list)        their glow on the full map (the canvas' layer farms); Farms.Clear() away
--      Farms.Build(holder), Farms.Place(view, small), Farms.Hide()   the canvas' layer
--
--  What gives a thing: an item's creatures (looted, skinned, picked from pockets) and objects (gathered, opened) by
--  Core's drop counts (Data.Drops: From), each weighted by how often it gives it (a chance unknown: Farms.UNKNOWN; a
--  node always gives its herb or ore); a creature or an object asked for itself weighs 1. Their spawns (Core's Spawns,
--  CreatureSpawns) fall into square cells of Farms.CELL yards on their plane, and a cell's heat is its worth with its
--  eight neighbours'. The hottest cell makes a place: the spawns of its three by three cells, their middle weighed by
--  worth, a radius that holds them (Farms.SPREAD times their weighed spread, between Farms.SMALL and Farms.LARGE);
--  the cells round it are spent, the next hottest makes the next place, while a cell has at least Farms.LEAST of the
--  hottest's heat and holds Farms.FEW spawns or more, Farms.MOST places at most. Spawns inside a dungeon (the game's map type) make one place a dungeon, listed after those outside (a whole dungeon's
--  worth is not weighed against a few cells'), its map shown when chosen.
--
--  The glow: Navigation's soft round mark (Art/mark-soft), in Sane UI's gold, as wide as the place in yards (so it
--  grows as the map zooms in), the hottest the strongest. Only on the full map: the small one stays clear.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Farms = {}
ns.Farms = Farms

Farms.CELL = 120        -- yards on a cell's side
Farms.SOURCES = 120     -- an item's sources looked at at most, the likeliest first (Linen Cloth: hundreds of creatures)
Farms.UNKNOWN = 0.05    -- what a creature counts for whose chance to give it is not known (only that it does)
Farms.LEAST = 0.15      -- a place's heat, at least, of the hottest's
Farms.FEW = 3           -- spawns a place holds at least
Farms.MOST = 10         -- places at most
Farms.SPREAD = 1.6      -- the radius, in the weighed spread of its spawns round its middle
Farms.SMALL, Farms.LARGE = 50, 320 -- yards the radius is at least and at most
Farms.GLOW = { Core.GOLD[1], Core.GOLD[2], Core.GOLD[3] }
Farms.ALPHA = { 0.22, 0.5 } -- the glow's alpha, the faintest place's and the hottest's
Farms.SOFT = "Interface\\AddOns\\SaneUI_Navigation\\Art\\mark-soft"
Farms.TEXT = {
    round = "%d to kill, about %s a round", nodes = "%d to gather", spawns = "%d spawns", inside = "Inside %s",
    sides = { "north west", "north", "north east", "west", "middle", "east", "south west", "south", "south east" },
    named = "%s (%s)", levels = "Level %d-%d", level = "Level %d", source = "%s %d",
}

local DROPS = Core.Data.Drops and Core.Data.Drops()
local NONE = {}
local kept = {}   -- [find's key] = its places, until Core's data changes (Farms.Forget)
local Dungeon
local shown       -- the places glowing on the map now
local layer, pool

-- What gives a find, each { key, name, weight, how }: an item's sources by Core's drop counts, else the thing itself.
local function Givers(entry)
    if entry.kind == "npc" or entry.kind == "object" then
        return { { key = entry.key, id = entry.id, name = entry.name, weight = 1, node = entry.kind == "object" } }
    end
    if entry.kind ~= "item" or not DROPS then return NONE end
    local list = {}
    for _, source in ipairs(DROPS:From(entry.id)) do
        local kind, id = source.key:match("^(%a+):(%d+)$")
        local quest = tonumber(source.quest) or 0
        if (kind == "npc" or kind == "object") and quest == 0 and source.how ~= "fish" then
            local rate = tonumber(source.rate) or 0
            local node = kind == "object"
            local weight = rate > 0 and rate / 100 or (node and 1 or Farms.UNKNOWN)
            local find = ns.Find.Known(source.key)
            list[#list + 1] = { key = source.key, id = tonumber(id), name = find and find.name or source.key,
                                weight = weight, node = node, low = find and find.low, high = find and find.high }
            if #list >= Farms.SOURCES then break end
        end
    end
    return list
end

-- A place's name: its zone, and where in it (its ninth of the zone's map), or the dungeon it is in.
local function Named(place)
    if place.inside then return Farms.TEXT.inside:format(ns.Find.MapName(place.inside) or "?") end
    local zone = place.map and ns.Find.MapName(place.map)
    if not zone then return "?" end
    local column = math.min(2, math.max(0, math.floor((place.x or 0.5) * 3)))
    local row = math.min(2, math.max(0, math.floor((place.y or 0.5) * 3)))
    return Farms.TEXT.named:format(zone, Farms.TEXT.sides[row * 3 + column + 1])
end
Farms.Named = Named

-- What a place is, in a line: its main givers and their spawns, what a round gives (or the nodes), its levels.
function Farms.About(place)
    local parts, names = {}, {}
    for index = 1, math.min(2, #place.sources) do
        local source = place.sources[index]
        names[#names + 1] = Farms.TEXT.source:format(source.name, source.count)
    end
    if #names > 0 then parts[#parts + 1] = table.concat(names, ", ") end
    if place.nodes then
        parts[#parts + 1] = Farms.TEXT.nodes:format(place.count)
    elseif place.weighed then
        local worth = place.worth
        local said = worth >= 10 and tostring(math.floor(worth + 0.5)) or ("%.1f"):format(worth)
        parts[#parts + 1] = Farms.TEXT.round:format(place.count, said)
    else
        parts[#parts + 1] = Farms.TEXT.spawns:format(place.count)
    end
    if place.low and place.low > 0 then
        local high = place.high or place.low
        parts[#parts + 1] = high ~= place.low and Farms.TEXT.levels:format(place.low, high) or Farms.TEXT.level:format(high)
    end
    return table.concat(parts, "  ·  ")
end

-- A place from the spawns gathered for it: its middle, its radius, its zone and point there, its givers.
local function Made(spawns, plane)
    local total, su, sv = 0, 0, 0
    for _, spawn in ipairs(spawns) do
        total = total + spawn.weight
        su, sv = su + spawn.u * spawn.weight, sv + spawn.v * spawn.weight
    end
    if total <= 0 then return nil end
    local u, v = su / total, sv / total
    local spread = 0
    for _, spawn in ipairs(spawns) do spread = spread + spawn.weight * ((spawn.u - u) ^ 2 + (spawn.v - v) ^ 2) end
    local radius = math.min(Farms.LARGE, math.max(Farms.SMALL, Farms.SPREAD * math.sqrt(spread / total)))
    local place = { plane = plane, u = u, v = v, radius = radius, worth = total, count = #spawns, nodes = true }
    local byKey, sources = {}, {}
    for _, spawn in ipairs(spawns) do
        local giver = spawn.giver
        local source = byKey[giver.key]
        if not source then
            source = { key = giver.key, name = giver.name, count = 0, worth = 0 }
            byKey[giver.key], sources[#sources + 1] = source, source
        end
        source.count, source.worth = source.count + 1, source.worth + spawn.weight
        if not giver.node then place.nodes = nil end
        if giver.weight ~= 1 then place.weighed = true end
        if giver.low and giver.low > 0 then
            place.low = math.min(place.low or giver.low, giver.low)
            place.high = math.max(place.high or 0, giver.high or giver.low)
        end
    end
    table.sort(sources, function(a, b)
        if a.worth ~= b.worth then return a.worth > b.worth end
        return a.key < b.key
    end)
    place.sources = sources
    if not plane then return place end -- (inside a dungeon: no point on a plane)
    local zone = Coords.ZoneAt(plane, u, v)
    local box = zone and Coords.Box(zone)
    if box and Coords.PlaneOf(zone) == plane then
        place.map = zone
        place.x, place.y = Coords.ToMap(box, u, v)
    else
        local planeBox = Coords.Box(plane)
        if planeBox then place.map, place.x, place.y = plane, Coords.ToMap(planeBox, u, v) end
    end
    return place
end

-- Whether a map is a dungeon's or a raid's (the game's map type), asked once a map.
local dungeons = {}
function Dungeon(map) -- (declared local above)
    local known = dungeons[map]
    if known ~= nil then return known end
    local info = Core.Ask(C_Map.GetMapInfo, map)
    local kinds = rawget(_G, "Enum") and Enum.UIMapType
    known = type(info) == "table" and kinds ~= nil and info.mapType == kinds.Dungeon or false
    dungeons[map] = known
    return known
end

-- The places to farm a find, the best first (see the file's head); zone: only its spawns on that map ("in elwynn").
function Farms.Of(entry, zone)
    if not entry or not entry.key then return NONE end
    local name = zone and entry.key .. "@" .. zone or entry.key
    if kept[name] then return kept[name] end
    local cells, inside = {}, {}
    local cell = Farms.CELL
    for _, giver in ipairs(Givers(entry)) do
        local creature = giver.key:match("^npc:") and giver.id or nil
        for _, point in ipairs(ns.Find.Points(giver.key, creature)) do
            local plane = (not zone or point.map == zone) and Coords.PlaneOf(point.map)
            local u, v
            if plane then u, v = Coords.MapToPlane(point.map, point.x, point.y, plane) end
            if u then
                local cx, cy = math.floor(u / cell), math.floor(v / cell)
                local key = plane .. ":" .. cx .. ":" .. cy
                local spot = cells[key]
                if not spot then
                    spot = { plane = plane, cx = cx, cy = cy, worth = 0, spawns = {} }
                    cells[key] = spot
                end
                spot.worth = spot.worth + giver.weight
                spot.spawns[#spot.spawns + 1] = { u = u, v = v, weight = giver.weight, giver = giver }
            elseif not zone and Dungeon(point.map) then
                -- inside a dungeon: one place a dungeon's map
                local here = inside[point.map]
                if not here then
                    here = {}
                    inside[point.map] = here
                end
                here[#here + 1] = { u = 0, v = 0, weight = giver.weight, giver = giver }
            end
        end
    end
    -- Each cell's heat: its worth and its eight neighbours'.
    local list = {}
    for _, spot in pairs(cells) do
        local heat = 0
        for dx = -1, 1 do
            for dy = -1, 1 do
                local other = cells[spot.plane .. ":" .. (spot.cx + dx) .. ":" .. (spot.cy + dy)]
                if other then heat = heat + other.worth end
            end
        end
        spot.heat = heat
        list[#list + 1] = spot
    end
    table.sort(list, function(a, b)
        if a.heat ~= b.heat then return a.heat > b.heat end
        if a.plane ~= b.plane then return a.plane < b.plane end
        if a.cx ~= b.cx then return a.cx < b.cx end
        return a.cy < b.cy
    end)
    local places, spent = {}, {}
    local hottest = list[1] and list[1].heat or 0
    for _, spot in ipairs(list) do
        if #places >= Farms.MOST or spot.heat < hottest * Farms.LEAST then break end
        if not spent[spot] then
            local spawns = {}
            for dx = -1, 1 do
                for dy = -1, 1 do
                    local other = cells[spot.plane .. ":" .. (spot.cx + dx) .. ":" .. (spot.cy + dy)]
                    if other and not spent[other] then
                        for _, spawn in ipairs(other.spawns) do spawns[#spawns + 1] = spawn end
                    end
                end
            end
            if #spawns >= Farms.FEW then
                local place = Made(spawns, spot.plane)
                if place then
                    place.heat = spot.heat
                    places[#places + 1] = place
                end
                -- the cells round it spent: the next place stands apart from it
                for dx = -2, 2 do
                    for dy = -2, 2 do
                        local other = cells[spot.plane .. ":" .. (spot.cx + dx) .. ":" .. (spot.cy + dy)]
                        if other then spent[other] = true end
                    end
                end
            end
        end
    end
    for map, spawns in pairs(inside) do
        if #spawns >= Farms.FEW then
            local place = Made(spawns, nil) or {}
            place.plane, place.u, place.v, place.radius = nil, nil, nil, nil
            place.inside, place.map, place.x, place.y = map, nil, nil, nil
            local worth = 0
            for _, spawn in ipairs(spawns) do worth = worth + spawn.weight end
            place.worth, place.heat = worth, worth
            places[#places + 1] = place
        end
    end
    -- the places outside first, by their heat; then the dungeons, a whole one's worth not to be weighed against a few
    -- cells', by theirs
    table.sort(places, function(a, b)
        if (a.inside ~= nil) ~= (b.inside ~= nil) then return a.inside == nil end
        return a.heat > b.heat
    end)
    for _, place in ipairs(places) do place.name = Named(place) end
    kept[name] = places
    return places
end

-- Core's data changed: worked out anew when next asked.
function Farms.Forget()
    wipe(kept)
end

-------------------------------------------------------------------------------
--  The glow on the map
-------------------------------------------------------------------------------
function Farms.Build(canvasHolder)
    layer = CreateFrame("Frame", nil, canvasHolder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    pool = ns.Canvas.Pool(layer, "ARTWORK")
    return layer
end

-- The places glowing on the full map (nil: none); the map drawn anew.
function Farms.Draw(list)
    shown = list and #list > 0 and list or nil
    if ns.Canvas.Refresh then ns.Canvas.Refresh() end
end

function Farms.Shown()
    return shown
end

function Farms.Clear()
    if not shown then return end
    Farms.Draw(nil)
end

-- Out of sight, kept (the small view in an instance: Canvas.Empty).
function Farms.Hide()
    if not pool then return end
    pool:Begin()
    pool:End()
end

-- Each place in view as a glow, as wide as it is (the canvas' laying out; small: none).
function Farms.Place(view, small)
    if not pool then return end
    pool:Begin()
    if shown and not small then
        local best = shown[1] and shown[1].heat or 1
        for index, place in ipairs(shown) do
            local link = place.plane and Coords.Link(place.plane, view.map)
            if link then
                local u, v = link.du + link.su * place.u, link.dv + link.sv * place.v
                local r = place.radius * math.abs(link.su)
                if u + r >= view.left and u - r <= view.right and v - r <= view.top and v + r >= view.bottom then
                    local texture = pool:Get("farm:" .. index, Farms.SOFT)
                    local share = best > 0 and math.min(1, (place.heat or 0) / best) or 1
                    local alpha = Farms.ALPHA[1] + (Farms.ALPHA[2] - Farms.ALPHA[1]) * share
                    texture:SetVertexColor(Farms.GLOW[1], Farms.GLOW[2], Farms.GLOW[3], alpha)
                    texture:SetBlendMode("ADD")
                    ns.Canvas.Put(texture, u - r, v + r, 2 * r, 2 * r)
                end
            end
        end
    end
    pool:End()
end
