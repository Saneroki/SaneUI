local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Tally
--  What play counts rather than tells (Doc/guides/data.md, *Counted in play*): how often a creature, a node or a
--  fishing water gave each item, and where things were seen, a few yards off. One loot or one sighting is no fact;
--  the harvest (dev/tools/data harvest) adds every player's counts together, and only what enough of them agree on
--  goes into the master: a chance from enough loots, a place seen on more than one visit.
--
--      Tally.Loot("npc:69", "loot", 0)                   one corpse looted (how: loot, skin, pickpocket, gather, fish;
--                                                        quest: counted for those on this quest, 0 for everybody)
--      Tally.Drop("npc:69", "loot", 769, 0, 2)           an item it gave, and how many
--      Tally.Point("npc:69", map, x, y)                  seen from up close (talked to, gathered): merged by yards
--      Tally.Cell("npc:69", map, x, y)                   looted here: a cell of the map (100 by 100)
--      Tally.Here()                                      the player's map and place (percent), or nil
--
--  Kept in SaneUIData_Learned[game].tally[build] = { id = random, drops = {}, points = {}, cells = {} }, a packed row
--  per key, one block per build (the build period), at most Tally.BUILDS: the harvest reads the blocks, and takes of
--  each only what it did not take before (by the block's random id: the same saved file read twice counts once). The
--  maps' sizes in yards beside them (maps[map]), so the harvest can measure. Nothing in it is about a player: no time
--  finer than the build, no name, no trail (a sighting is the thing's place, merged into the places seen before).
-------------------------------------------------------------------------------
local Data = Core.Data
local Codec = Data.Codec

local Tally = {}
Data.Tally = Tally
Tally.MERGE = 8        -- yards within which a sighting is a place seen before (a player stands a few yards off, lag adds)
Tally.VISIT = 900      -- seconds within which a place seen again is the same visit
Tally.BUILDS = 4       -- build periods kept; the oldest dropped first
Tally.KEYS = 20000     -- keys of a kind in one build period at most
Tally.RECORDS = { drops = 400, points = 60, cells = 500 } -- records of one key at most

local LIST, PART = "\030", "\031"
local floor, sqrt = math.floor, math.sqrt

local part      -- this client's part of SaneUIData_Learned, once Core's saved variables are read
local block     -- the build's block
local rows = { drops = {}, points = {}, cells = {} } -- [kind][key] = the key's records, taken apart (this build's)
local counts = { drops = 0, points = 0, cells = 0 }  -- keys of each kind in the block
local visited = {} -- [key .. "\031" .. record] = GetTime() of the last visit counted

local function Build()
    local _, number = Core.Ask(rawget(_G, "GetBuildInfo"))
    return tonumber(number) or 0
end

local function Id()
    local parts = {}
    for index = 1, 4 do parts[index] = ("%04x"):format(math.random(0, 0xffff)) end
    return table.concat(parts)
end

-- The build's block, made where it is missing; the oldest dropped beyond Tally.BUILDS.
local function Block()
    if block then return block end
    if not part then return nil end
    if type(part.tally) ~= "table" then part.tally = {} end
    local build = Build()
    local found = part.tally[build]
    if type(found) ~= "table" or type(found.id) ~= "string" then
        found = { id = Id() }
        part.tally[build] = found
        Data.NoteBuild()
    end
    for _, kind in ipairs({ "drops", "points", "cells" }) do
        if type(found[kind]) ~= "table" then found[kind] = {} end
        local n = 0
        for _ in pairs(found[kind]) do n = n + 1 end
        counts[kind] = n
    end
    local builds = {}
    for each in pairs(part.tally) do builds[#builds + 1] = each end
    table.sort(builds)
    for index = 1, #builds - Tally.BUILDS do part.tally[builds[index]] = nil end
    block = found
    return block
end

-- A key's records, taken apart: an array of arrays of parts (numbers where they read as one).
local function Records(kind, key)
    local list = rows[kind][key]
    if list then return list end
    local here = Block()
    if not here then return nil end
    local row = here[kind][key]
    if row == nil and counts[kind] >= Tally.KEYS then return nil end
    list = {}
    if type(row) == "string" and row ~= "" then
        for _, record in ipairs(Codec.Cut(row, LIST)) do
            local fields = Codec.Cut(record, PART)
            for index, value in ipairs(fields) do fields[index] = tonumber(value) or value end
            list[#list + 1] = fields
        end
    end
    rows[kind][key] = list
    return list
end

local function Number(value)
    if floor(value) == value then return tostring(value) end
    return (("%.2f"):format(value):gsub("0+$", ""))
end

-- A key's records written back, packed.
local function Keep(kind, key, list)
    local here = Block()
    if not here then return end
    if here[kind][key] == nil then counts[kind] = counts[kind] + 1 end
    local packed = {}
    for index, record in ipairs(list) do
        local fields = {}
        for at, value in ipairs(record) do fields[at] = type(value) == "number" and Number(value) or tostring(value) end
        packed[index] = table.concat(fields, PART)
    end
    here[kind][key] = table.concat(packed, LIST)
end

local function Valid(key)
    return type(key) == "string" and key ~= "" and not key:find("[\030\031]")
end

-- One loot of a key: a corpse looted, a node gathered, a cast fished; quest 0 for everybody.
function Tally.Loot(key, how, quest)
    if not Valid(key) or type(how) ~= "string" then return false end
    local list = Records("drops", key)
    if not list then return false end
    quest = tonumber(quest) or 0
    for _, record in ipairs(list) do
        if record[1] == "c" and record[2] == how and record[3] == quest then
            record[4] = (tonumber(record[4]) or 0) + 1
            Keep("drops", key, list)
            return true
        end
    end
    if #list >= Tally.RECORDS.drops then return false end
    list[#list + 1] = { "c", how, quest, 1 }
    Keep("drops", key, list)
    return true
end

-- An item one loot of a key gave, and how many.
function Tally.Drop(key, how, item, quest, units)
    if not Valid(key) or type(how) ~= "string" or type(item) ~= "number" then return false end
    local list = Records("drops", key)
    if not list then return false end
    quest, units = tonumber(quest) or 0, math.max(1, tonumber(units) or 1)
    for _, record in ipairs(list) do
        if record[1] == "d" and record[2] == how and record[3] == item and record[4] == quest then
            record[5] = (tonumber(record[5]) or 0) + 1
            record[6] = (tonumber(record[6]) or 0) + units
            Keep("drops", key, list)
            return true
        end
    end
    if #list >= Tally.RECORDS.drops then return false end
    list[#list + 1] = { "d", how, item, quest, 1, units }
    Keep("drops", key, list)
    return true
end

-- A map's size in yards, noted once for the harvest; nil where the game does not tell.
local function Size(map)
    local maps = rawget(_G, "C_Map")
    local width, height = Core.Ask(maps and maps.GetMapWorldSize, map)
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then return nil end
    if part then
        if type(part.maps) ~= "table" then part.maps = {} end
        if part.maps[map] == nil then part.maps[map] = Number(width) .. PART .. Number(height) end
    end
    return width, height
end

-- The player's map and place on it, in percent; nil inside an instance and wherever the game does not tell.
function Tally.Here()
    local maps = rawget(_G, "C_Map")
    if not maps then return nil end
    local map = Core.Ask(maps.GetBestMapForUnit, "player")
    if type(map) ~= "number" then return nil end
    local position = Core.Ask(maps.GetPlayerMapPosition, map, "player")
    if type(position) ~= "table" or not position.GetXY then return nil end
    local ok, x, y = pcall(position.GetXY, position)
    x, y = ok and Core.Plain(x), ok and Core.Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return nil end
    return map, x * 100, y * 100
end

-- A thing seen from up close: a place seen before within Tally.MERGE yards counts one visit more (its place the mean
-- of what was seen), farther off a new one; the same place again within Tally.VISIT seconds is the same visit.
function Tally.Point(key, map, x, y)
    if not Valid(key) or type(map) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return false end
    local width, height = Size(map)
    if not width then return false end
    local list = Records("points", key)
    if not list then return false end
    local best, near
    for index, record in ipairs(list) do
        if record[1] == map then
            local far = sqrt(((record[2] - x) / 100 * width) ^ 2 + ((record[3] - y) / 100 * height) ^ 2)
            if far <= Tally.MERGE and (not near or far < near) then best, near = index, far end
        end
    end
    local now = GetTime()
    if best then
        local seen = key .. PART .. best
        if visited[seen] and now - visited[seen] < Tally.VISIT then return false end
        visited[seen] = now
        local record = list[best]
        local visits = (tonumber(record[4]) or 1) + 1
        record[2] = floor((record[2] * (visits - 1) + x) / visits * 100 + 0.5) / 100
        record[3] = floor((record[3] * (visits - 1) + y) / visits * 100 + 0.5) / 100
        record[4] = visits
    else
        if #list >= Tally.RECORDS.points then return false end
        list[#list + 1] = { map, floor(x * 100 + 0.5) / 100, floor(y * 100 + 0.5) / 100, 1 }
        visited[key .. PART .. #list] = now
    end
    Keep("points", key, list)
    return true
end

-- A thing looted, or an objective's count gone up, here: one more in the map's cell (rows and columns of a percent).
function Tally.Cell(key, map, x, y)
    if not Valid(key) or type(map) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return false end
    if x < 0 or y < 0 or x >= 100 or y >= 100 then return false end
    Size(map)
    local list = Records("cells", key)
    if not list then return false end
    local cell = floor(y) * 100 + floor(x)
    for _, record in ipairs(list) do
        if record[1] == map and record[2] == cell then
            record[3] = (tonumber(record[3]) or 0) + 1
            Keep("cells", key, list)
            return true
        end
    end
    if #list >= Tally.RECORDS.cells then return false end
    list[#list + 1] = { map, cell, 1 }
    Keep("cells", key, list)
    return true
end

-- What a key holds this build period (the tests, /sane data): its records, taken apart; nil when none.
function Tally.Of(kind, key)
    if not rows[kind] then return nil end
    local list = Records(kind, key)
    return list and #list > 0 and list or nil
end

-- /sane data: what this build period counted so far, and whether the game names the source of a loot.
local SAY = {
    counted = "counted in play this build: %d things looted or gathered, %d places seen, %d with cells.",
    blind = "loot is not counted: this client names no corpse or thing per loot slot (GetLootSourceInfo).",
}
Data.reports[#Data.reports + 1] = function()
    if not part then return end
    if block then Core.Print(SAY.counted:format(counts.drops, counts.points, counts.cells)) end
    if not rawget(_G, "GetLootSourceInfo") then Core.Print(SAY.blind) end
end

Data.Saved("Learned", function(saved)
    part = saved
    if type(part.maps) ~= "table" then part.maps = {} end
end)
