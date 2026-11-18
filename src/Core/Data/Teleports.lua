local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Teleports
--  Where the teleports of Core's set Travel bring one (its kind teleport: a mage's or a druid's spell, an engineer's
--  transporter, the Crumbling Hearthstone), learnt in play: a watcher of Core's (Doc/guides/data.md, *Learned*).
--  The game's tables hold no place for them (the server's own), so where a teleport brought the player is its place:
--  a game fact, the same for every player, learnt (Data.Learn) and read over the set's at once.
--
--      the cast     the game says the player cast the spell of a teleport of the set (UNIT_SPELLCAST_SUCCEEDED; an
--                   item's: the spell it casts)
--      the arrival  the player's place in the world (UnitPosition: x, y, the world's map) looked at every
--                   Teleports.LOOK seconds and after a loading screen, for Teleports.WAIT seconds: a leap of
--                   Teleports.LEAP yards or more between two looks, or onto another map, is the teleport (no step,
--                   charge or blink goes so far so fast), and where it ends its place
--      learnt       that place to a hundredth of a yard, with its map (no height: the game tells none), as the way's
--                   path; a place within Teleports.SAME yards of the one the set has teaches nothing new
--
--  Nothing of the player's goes with it: the place is the teleport's, never where the player came from or when.
-------------------------------------------------------------------------------
local Data = Core.Data

local Teleports = {}
Data.Teleports = Teleports
Teleports.LOOK = 0.25    -- seconds between two looks at the player's place after a cast
Teleports.WAIT = 60      -- seconds after the cast within which the teleport comes
Teleports.LEAP = 50      -- yards between two looks that only a teleport goes
Teleports.SAME = 2       -- yards from the set's place within which a landing is that place

local Travel = Data.Set("Travel")
local spells             -- [spell] = the key of its teleport in the set, while the set stays as it is
local cast               -- the teleport cast: { key, at (GetTime), x, y, world (the place at the last look) }

local sqrt, floor = math.sqrt, math.floor

-- The player's place in the world: x, y and the world's map; nil where the game does not tell it (an instance, a
-- loading screen). Its fourth answer is the map: past what Core.Ask gives.
local function Place()
    local position = rawget(_G, "UnitPosition")
    if not position then return nil end
    local ok, x, y, _, world = pcall(position, "player")
    if not ok then return nil end
    x, y, world = Core.Plain(x), Core.Plain(y), Core.Plain(world)
    if type(x) ~= "number" or type(y) ~= "number" or type(world) ~= "number" then return nil end
    return x, y, world
end

local function Hundredth(value)
    return floor(value * 100 + 0.5) / 100
end

-- The teleports of the set by their spells, made once the set is there (again when it changes).
local function Spells()
    if spells then return spells end
    if not Travel:Ready() then return nil end
    spells = {}
    for _, key in ipairs(Travel:Keys("byKind", "teleport")) do
        local spell = Travel:Get(key, "spell")
        if spell then spells[spell] = key end
    end
    return spells
end
Travel:OnStamp(function() spells = nil end)

-- Where a teleport brought the player, learnt: the set's record with that place as its path, unless the set has it.
local function Learn(key, x, y, world)
    local way = Travel:Get(key)
    if not way then return end
    x, y = Hundredth(x), Hundredth(y)
    local known = type(way.path) == "table" and way.path[1]
    if type(known) == "table" and known.map == world and type(known.x) == "number" and type(known.y) == "number"
        and sqrt((known.x - x) ^ 2 + (known.y - y) ^ 2) <= Teleports.SAME then
        return
    end
    local record = {}
    for field, value in pairs(way) do record[field] = value end
    record.path = { { x = x, y = y, map = world } }
    if Data.Learn("Travel", key, record) then Data.Discovered("Travel", key, "changed", { "path" }) end
end

-- A look after the cast: a leap since the last one is the teleport, its end learnt; else looked at again, until
-- Teleports.WAIT seconds have gone by.
local look
local function Arrive()
    if not cast then return end
    if GetTime() - cast.at > Teleports.WAIT then
        cast = nil
        return
    end
    local x, y, world = Place()
    if x then
        if cast.x and (world ~= cast.world or sqrt((x - cast.x) ^ 2 + (y - cast.y) ^ 2) >= Teleports.LEAP) then
            local key = cast.key
            cast = nil
            return Learn(key, x, y, world)
        end
        cast.x, cast.y, cast.world = x, y, world
    end
    look()
end
look = Core.Later(Arrive, Teleports.LOOK)
local soon = Core.Later(Arrive)

Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spell)
    spell = Core.Plain(spell)
    local list = type(spell) == "number" and Spells()
    local key = list and list[spell]
    if not key then return end
    local x, y, world = Place()
    cast = { key = key, at = GetTime(), x = x, y = y, world = world }
    look()
end)
-- A loading screen over: the teleport's end is where the player stands now.
Core.On("PLAYER_ENTERING_WORLD", function()
    if cast then soon() end
end)
