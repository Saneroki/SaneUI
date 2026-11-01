local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Watchers
--  Core's watchers that confirm what our data has not had confirmed yet (Data.Confirm, Confirm.lua), and learn what
--  play shows that the data lacks (Data.Learn): Doc/guides/data.md, *Verified*. Each only looks and compares; nothing
--  is asked of the game in a fight or while it restricts addons, and a value it hides is passed over.
--
--      seen         a creature under the mouse, the target or a nameplate: the spawn point (the set Spawns) it stands
--                   within Watchers.NEAR yards of, the whole spawn once each of its points was; the creature itself
--                   (NPCs) when it offers nothing to talk to (a vendor, a trainer is only confirmed by talking to it)
--      talked to    an NPC or a thing one talks to or uses (a vendor, a trainer, a flight master, a quest giver, a
--                   banker, a mailbox: the game's unit "npc"): the creature or object and its spawn, near one of its
--                   points; and where the player stands, a sighting of its place (Tally.Point, for the harvest)
--      a mailbox    opened: the set Places' mailbox within Watchers.MAILBOX yards
--      a crossing   a zone left near the set Places' crossing (within Watchers.CROSSING yards)
--      a quest      offered, taken, worked on, handed in: field by field, in Quests.lua
--      a boss       its loot: within Watchers.LOOT seconds after the game said the boss was killed (ENCOUNTER_END)
--                   and in its instance, an item the set Bosses names for it; any item of a corpse of the boss's
--                   name (the target, dead): the game tells no place inside an instance, nor whose corpse a loot is,
--                   so the boss's own corpse is known by its name, and the time and the instance hold its items to
--                   it. Its abilities: a spell its unit casts (the boss frames' units in its fight, else a creature of
--                   its name), a buff it carries of those the set names, wherever the game lets them be read
--      an item      every item the character has (bags, worn, bank: Data.Items): its stats, armour, damage and speed as
--                   the game gives them (GetItemStats, its tooltip's lines) compared with the set Items; where they
--                   differ, or the set has none (many items' are hidden from the game's tables), learned and shared
--                   with the guild and the group (Data.Share)
-------------------------------------------------------------------------------
local Data, Steps = Core.Data, Core.Steps

local Watchers = {}
Data.Watchers = Watchers
Watchers.NEAR = 30       -- yards from a spawn point within which a creature or object stands at it (points are a few yards off)
Watchers.MAILBOX = 12    -- yards from a mailbox of the set within which the one opened is it
Watchers.CROSSING = 40   -- yards from a crossing of the set within which a zone left was left by it
Watchers.LOOT = 300      -- seconds after a boss's kill within which loot in its instance is its
Watchers.AGAIN = 5       -- seconds before a creature seen is looked at again (it may come nearer its point)
Watchers.AURAS = 40      -- a boss's buffs looked at, at most

local Spawns, NPCs, Objects, Places = Data.Set("Spawns"), Data.Set("NPCs"), Data.Set("Objects"), Data.Set("Places")
local Bosses, Encounters, Items = Data.Set("Bosses"), Data.Set("Encounters"), Data.Set("Items")

local sqrt, floor = math.sqrt, math.floor

-- The creature or object a unit is: "npc" or "object" and its ID, from its GUID; nil for a player or what is hidden.
local function Thing(unit)
    local guid = Core.Ask(rawget(_G, "UnitGUID"), unit)
    if type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind == "Creature" or kind == "Vehicle" then return "npc", tonumber(id) end
    if kind == "GameObject" then return "object", tonumber(id) end
    return nil
end
Watchers.Thing = Thing

-- How many yards the player stands from a point of the data ({ map, x, y }, x and y in percent of the map); nil where
-- the game does not tell (another map, an instance).
local function Yards(point)
    local maps = rawget(_G, "C_Map")
    if not (maps and type(point) == "table" and type(point.map) == "number") then return nil end
    local position = Core.Ask(maps.GetPlayerMapPosition, point.map, "player")
    if type(position) ~= "table" or not position.GetXY then return nil end
    local ok, x, y = pcall(position.GetXY, position)
    x, y = ok and Core.Plain(x), ok and Core.Plain(y)
    local width, height = Core.Ask(maps.GetMapWorldSize, point.map)
    if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" or width <= 0 then
        return nil
    end
    return sqrt(((x - point.x / 100) * width) ^ 2 + ((y - point.y / 100) * height) ^ 2)
end
Watchers.Yards = Yards

local function Near(points, yards)
    if type(points) ~= "table" then return false end
    for _, point in pairs(points) do
        local far = Yards(point)
        if far and far <= yards then return true end
    end
    return false
end

-- A spawn point as a part of its entry: "p" and a number made of its map and place to a tenth of a percent (the
-- harvest makes the same: dev/data/harvest.py).
local function Code(point)
    return ("p%d"):format((point.map * 1001 + floor(point.x * 10 + 0.5)) * 1001 + floor(point.y * 10 + 0.5))
end
Watchers.Code = Code

-- A thing of the data with spawn points (Spawns: "npc:69", "object:1617"): the point the player stands near confirmed,
-- and the whole entry once every point of it is. The watchers ask what the game confirmed here (Unverified's own):
-- what members told never stands in for the game's word here.
local function Spawn(key)
    if not Spawns:Unverified(key, nil, true) then return end
    local points = Spawns:Get(key, "points")
    if type(points) ~= "table" or #points == 0 then return end
    local all = true
    for _, point in ipairs(points) do
        if type(point) == "table" and type(point.map) == "number" then
            local code = Code(point)
            if Spawns:Unverified(key, code, true) then
                local far = Yards(point)
                if far and far <= Watchers.NEAR then Data.Confirm("Spawns", key, code) else all = false end
            end
        end
    end
    if all then Data.Confirm("Spawns", key) end
end

-------------------------------------------------------------------------------
--  Bosses: their abilities and loot
-------------------------------------------------------------------------------
local fighting           -- the encounter the game says is on (ENCOUNTER_START), nil after it
local kill               -- the last boss killed: { encounter, name, at, instance }
local names, naming      -- [an encounter's name] = its ID, made once from the set Encounters

-- The instance the player is in: its map ID (GetInstanceInfo's eighth answer); nil where the game does not tell.
local function Instance()
    local get = rawget(_G, "GetInstanceInfo")
    if not get then return nil end
    local ok, _, _, _, _, _, _, _, id = pcall(get)
    return ok and Core.Plain(id) or nil
end

-- The encounter a unit is the boss of: the fight's own for the boss frames' units, else by the creature's name.
local function Encounter(unit)
    if fighting and unit:match("^boss%d$") then return fighting end
    local name = Core.Ask(rawget(_G, "UnitName"), unit)
    if type(name) ~= "string" then return nil end
    if not names then
        if not naming and Encounters:Ready() and Bosses:Ready() then
            naming = true
            local made = {}
            Encounters:Each(function(key, record)
                if type(record.name) == "string" and Bosses:Get(key) then made[record.name] = key end
            end, function() names = made end)
        end
        return nil
    end
    return names[name]
end

-- A spell a boss cast or carries: its ability confirmed, or one the set does not name (a fact of its own: cast only).
local function Ability(encounter, spell, cast)
    if not (encounter and type(spell) == "number" and Bosses:Ready()) then return end
    local part = "a" .. spell
    if not cast then
        local known = false
        for _, id in ipairs(Bosses:Get(encounter, "abilities") or {}) do
            if id == spell then known = true end
        end
        if not known then return end
    end
    Data.Confirm("Bosses", encounter, part)
end

-- Whether a unit is somebody the watchers look at: a creature about, never a player, the party or a pet.
local WATCHED = { target = true, focus = true, mouseover = true, softenemy = true }
local function Watched(unit)
    if type(unit) ~= "string" then return false end
    if not (WATCHED[unit] or unit:match("^nameplate%d+$") or unit:match("^boss%d$")) then return false end
    return not Core.Ask(rawget(_G, "UnitIsPlayer"), unit)
end

local function Cast(unit, _, spell)
    if not Watched(unit) then return end
    spell = Core.Plain(spell)
    if type(spell) ~= "number" then return end -- hidden in the fight: nothing to confirm
    Ability(Encounter(unit), spell, true)
end
-- Their casts are asked of the game for the units watched alone (Core.OnUnit), never for every unit about, which a fight
-- sends hundreds of times a second: the target, the focus, the mouse, the boss frames' from the start, a nameplate's
-- unit once the game shows it (below).
local CASTS = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_SUCCEEDED" }
local listening = {} -- [unit] = true: its casts are heard
local function Listen(unit)
    if listening[unit] then return end
    listening[unit] = true
    for _, event in ipairs(CASTS) do Core.OnUnit(event, unit, Cast) end
end
for unit in pairs(WATCHED) do Listen(unit) end
for index = 1, rawget(_G, "MAX_BOSS_FRAMES") or 5 do Listen("boss" .. index) end

-- The buffs a boss carries: those of its abilities the set names.
local function Buffs(unit, encounter)
    local auras = rawget(_G, "C_UnitAuras")
    if not (auras and auras.GetAuraDataByIndex and encounter) then return end
    for index = 1, Watchers.AURAS do
        local aura = Core.Ask(auras.GetAuraDataByIndex, unit, index, "HELPFUL")
        if type(aura) ~= "table" then break end
        Ability(encounter, Core.Plain(aura.spellId), false)
    end
end

Core.On("ENCOUNTER_START", function(id)
    fighting = Core.Plain(id)
end)
Core.On("ENCOUNTER_END", function(id, name, _, _, success)
    id, success = Core.Plain(id), Core.Plain(success)
    fighting = nil
    if success == 1 and type(id) == "number" then
        kill = { encounter = id, name = Core.Plain(name), at = GetTime(), instance = Instance() }
    end
end)

-- A loot window open soon after a boss's kill, in its instance: the boss's items confirmed (see the top).
local function Loot()
    if not kill or not Bosses:Ready() or GetTime() - kill.at > Watchers.LOOT or Instance() ~= kill.instance then return end
    local named = {}
    for _, id in ipairs(Bosses:Get(kill.encounter, "loot") or {}) do named[id] = true end
    local name = Core.Ask(rawget(_G, "UnitName"), "target")
    local corpse = kill.name ~= nil and name == kill.name and Core.Ask(rawget(_G, "UnitIsDead"), "target") == true
    for slot = 1, Core.Ask(rawget(_G, "GetNumLootItems")) or 0 do
        local link = Core.Ask(rawget(_G, "GetLootSlotLink"), slot)
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id and (named[id] or corpse) then Data.Confirm("Bosses", kill.encounter, "l" .. id) end
    end
end
Core.On("LOOT_OPENED", Loot)

-------------------------------------------------------------------------------
--  Creatures, things and places
-------------------------------------------------------------------------------
local looked = {} -- [creature ID] = GetTime() it was last looked at, or true: nothing of it is unverified any more

-- A creature seen (spoke: talked to): its spawn near a point, the creature itself, a boss's buffs.
local function Creature(id, spoke, unit)
    if not id then return end
    local key = "npc:" .. id
    Spawn(key)
    if NPCs:Unverified(id, nil, true) then
        local services = NPCs:Get(id, "services")
        if spoke or type(services) ~= "table" or #services == 0 then Data.Confirm("NPCs", id) end
    end
    if unit then Buffs(unit, Encounter(unit)) end
    if not Spawns:Unverified(key, nil, true) and not NPCs:Unverified(id, nil, true) then looked[id] = true end
end

local function Seen(unit)
    if Core.Restricted() or not Watched(unit) then return end
    local kind, id = Thing(unit)
    if kind ~= "npc" or looked[id] == true then return end
    local now = GetTime()
    if looked[id] and now - looked[id] < Watchers.AGAIN then return end
    looked[id] = now
    Creature(id, false, unit)
end
Core.On("UPDATE_MOUSEOVER_UNIT", function() Seen("mouseover") end)
Core.On("PLAYER_TARGET_CHANGED", function() Seen("target") end)
Core.On("NAME_PLATE_UNIT_ADDED", function(unit)
    if type(unit) == "string" and unit:match("^nameplate%d+$") then Listen(unit) end -- its casts from now on
    Seen(unit)
end)

-- An NPC or a thing talked to or used (the game's unit "npc"): the creature or the object, and its spawn; where the
-- player stands, within reach of it, a sighting of its place (Tally.Point).
local function Spoke()
    local kind, id = Thing("npc")
    if kind == "npc" then
        Creature(id, true)
    elseif kind == "object" then
        Spawn("object:" .. id)
        if Objects:Unverified(id, nil, true) then Data.Confirm("Objects", id) end
    end
    if kind and not Core.Ask(rawget(_G, "IsInInstance")) then
        local map, x, y = Data.Tally.Here()
        if map then Data.Tally.Point(kind .. ":" .. id, map, x, y) end
    end
end
Watchers.Spoke = Spoke
for _, event in ipairs({ "GOSSIP_SHOW", "MERCHANT_SHOW", "TRAINER_SHOW", "TAXIMAP_OPENED", "BANKFRAME_OPENED",
    "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "PET_STABLE_SHOW", "AUCTION_HOUSE_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" }) do
    Core.On(event, Spoke)
end

-- The set Places' places of a kind within so many yards of the player, confirmed.
local function PlacesNear(kind, yards)
    if not Places:Ready() then return end
    for _, key in ipairs(Places:Keys("byKind", kind)) do
        if Places:Unverified(key, nil, true) then
            local far = Yards(Places:Get(key, "point"))
            if far and far <= yards then Data.Confirm("Places", key) end
        end
    end
end

Core.On("MAIL_SHOW", function()
    Spoke()
    PlacesNear("mailbox", Watchers.MAILBOX)
end)
-- A zone left: where it was left, by a crossing of the set's. The player's place is still the old zone's an instant.
Core.On("ZONE_CHANGED_NEW_AREA", function()
    if not Core.Restricted() then PlacesNear("crossing", Watchers.CROSSING) end
end)

-------------------------------------------------------------------------------
--  Items: their stats as the game gives them
-------------------------------------------------------------------------------
local checked = {}  -- [item ID] = true: compared this session
local asked = {}    -- [item ID] = true: asked of the game, waiting for it
-- The game's numbers that are no stat of the set's: the armour (its own field) and a weapon's damage per second.
local NO_STAT = { RESISTANCE0_NAME = true, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = true }

-- A sentence of the game's ("%s - %s Damage") as a pattern that finds its numbers; english where it has none.
local function Pattern(name, english)
    local words = rawget(_G, name)
    words = type(words) == "string" and words or english
    words = words:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0"):gsub("%%%d?%$?[%d%.]*[sdfg]", "([%%d%%.,]+)")
    return "^" .. words .. "$"
end

local function Number(text)
    return tonumber((tostring(text or ""):gsub(",", "")))
end

-- An item's damage and speed from its tooltip's lines (the game's own C_TooltipInfo): nil where it has none.
local function Damage(id)
    local tips = rawget(_G, "C_TooltipInfo")
    local data = tips and Core.Ask(tips.GetItemByID, id)
    if type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local range, single = Pattern("DAMAGE_TEMPLATE", "%s - %s Damage"), Pattern("SINGLE_DAMAGE_TEMPLATE", "%s Damage")
    local speedWord = rawget(_G, "SPEED")
    speedWord = type(speedWord) == "string" and speedWord or "Speed"
    local low, high, speed
    for _, line in ipairs(data.lines) do
        local left, right = Core.Plain(line.leftText), Core.Plain(line.rightText)
        if type(left) == "string" and not low then
            local a, b = left:match(range)
            if a then low, high = Number(a), Number(b) else
                a = left:match(single)
                if a then low, high = Number(a), Number(a) end
            end
        end
        if type(right) == "string" and not speed then
            speed = Number(right:match("^" .. speedWord .. " ([%d%.,]+)$"))
        end
    end
    return low, high, speed
end

-- What the game says of an item now, as the set's fields; nil while the game has not loaded it (asked for then).
local function Facts(id)
    local info = rawget(_G, "C_Item")
    local get = info and info.GetItemInfo or rawget(_G, "GetItemInfo")
    if not get then return nil end
    local ok, name, link, quality, level, minLevel, _, _, stack, slot, icon, sell, class, subclass, bind = pcall(get, id)
    if not ok or type(Core.Plain(name)) ~= "string" or type(Core.Plain(link)) ~= "string" then
        if not asked[id] and info and info.RequestLoadItemDataByID then
            asked[id] = true
            Core.Ask(info.RequestLoadItemDataByID, id)
        end
        return nil
    end
    local statsOf = info and info.GetItemStats or rawget(_G, "GetItemStats")
    local raw = statsOf and Core.Ask(statsOf, link)
    local stats, armor = nil, nil
    if type(raw) == "table" then
        for key, value in pairs(raw) do
            value = Core.Plain(value)
            if key == "RESISTANCE0_NAME" and type(value) == "number" and value > 0 then
                armor = floor(value + 0.5)
            elseif not NO_STAT[key] and type(key) == "string" and type(value) == "number" and value ~= 0 then
                stats = stats or {}
                stats[key] = floor(value + 0.5)
            end
        end
    end
    local low, high, speed = Damage(id)
    return {
        name = name, quality = Core.Plain(quality), itemLevel = Core.Plain(level), minLevel = Core.Plain(minLevel),
        class = Core.Plain(class), subclass = Core.Plain(subclass), slot = Core.Plain(slot) ~= "" and Core.Plain(slot) or nil,
        stack = Core.Plain(stack), bind = Core.Plain(bind), icon = Core.Plain(icon), sell = Core.Plain(sell),
    }, { stats = stats, armor = armor, damageMin = low and floor(low + 0.5), damageMax = high and floor(high + 0.5),
         speed = speed and floor(speed * 100 + 0.5) / 100 }
end

-- An item compared with the set: learned (and shared) where the game's stats differ, or the set does not have it (only
-- on an English client then: the set names its items in English).
local ENGLISH = { enUS = true, enGB = true }
local PLAY = { "stats", "armor", "damageMin", "damageMax", "speed" }
local function Item(id)
    if checked[id] or not Items:Ready() then return end
    local base, play = Facts(id)
    if not base then return end
    checked[id], asked[id] = true, nil
    local known = Items:Get(id)
    if not known and not ENGLISH[Core.Ask(rawget(_G, "GetLocale")) or ""] then return end -- the set's names are English
    local record, differs = {}, known == nil
    if known then
        for field, value in pairs(known) do record[field] = value end
        record.since, record.day, record.patch = nil, nil, nil
    else
        for field, value in pairs(base) do record[field] = value end
    end
    for _, field in ipairs(PLAY) do
        if not Core.Same(record[field], play[field]) then
            record[field] = play[field]
            differs = true
        end
    end
    if differs and Data.Learn("Items", id, record) then
        Data.Discovered("Items", id, base and "changed" or "new", PLAY)
        Data.Share("Items", id)
    end
end
Watchers.Item = Item

-- Every item the character has, compared once a session, a few each frame (the scheduler).
local function Have()
    local mine = Core.charKey
    if not mine then return end
    local list, seen = {}, {}
    for _, place in ipairs({ "worn", "bags", "bank" }) do
        for _, entry in ipairs(Data.Items(mine, place) or {}) do
            local id = entry.item
            if type(id) == "number" and not checked[id] and not seen[id] then
                seen[id] = true
                list[#list + 1] = id
            end
        end
    end
    if #list == 0 or Steps.Running("watch: items") then return end
    Steps.Run({ name = "watch: items", label = "data: items" }, function()
        for _, id in ipairs(list) do
            Item(id)
            Steps.Check()
        end
    end)
end
Data.OnCharacters(Have)
-- An item the game loaded after it was asked for: compared a moment later, if the character has it.
local haveSoon = Core.Later(Have, 1)
Core.On("ITEM_DATA_LOAD_RESULT", function(id, success)
    id = Core.Plain(id)
    if asked[id] and Core.Plain(success) then haveSoon() end
end)
