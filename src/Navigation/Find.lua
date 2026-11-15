local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Find
--  What the full map's search finds in the world (Saneroki, 2026-11-15): FindBox.lua is the
--  field in the title bar and its list; this file reads what was typed, knows what there is
--  to find and where each thing stands. No frames.
--
--      Find.Ask(text, done)    what was typed, read and searched: done(answer), at once or once
--                              Core's sets are read (answer.reading meanwhile)
--      Find.Read(text)         what was typed, read: the words and what they ask (below)
--      Find.Spots(find)        where a find stands: its points { map, x, y } (0 to 1), nearest first
--      Find.Measure(find)      how far it is from you now (yards, its point), nil where it cannot be told
--      Find.Show(find)         its points drawn on the map (Find.Pins), the map at the nearest
--      Find.Pin(find)          the game's map pin at the nearest, so the golden line leads there
--      Find.Preview(find)      its points drawn, the map not moved (the mouse on its row)
--      Find.Farms(places, find) the places to farm a thing glowing on the map, a pin at each (Farms.lua)
--      Find.Clear()            no find on the map any more
--      Find.Pins()             the pins of the find shown, for Pins.For
--      Find.Look(find)         its icon on the map: an atlas or a texture
--
--  What it finds: Core's NPCs that stand somewhere (by name, by what they are: the line under
--  their name, their services and goods, the trade a trainer teaches), the objects players use
--  (mailboxes, chests, herbs, ore, books), the items that come from somewhere (from a vendor,
--  a creature, an object or a quest), the quests of Core's set and of your log, the places of
--  Core's set (entrances, caves, crossings, meeting stones), what a trainer teaches; and from
--  the game: the zones and continents, the dungeons' maps, the flight points of your side, the
--  members of your guild and group and your friends, your corpse, and a point typed as two
--  numbers.
--
--  How it reads (our own words, below): plain words find names and kinds forgivingly (Core's
--  Fuzzy: the whole word, its beginning, a word's beginning, inside; a short word also the
--  first letters of the words: "wt" a Warrior Trainer); every word must be found. Further:
--      nearest, closest, nearby          nearest first (one list); Enter puts the map pin there
--      who sells / where to buy X        the vendors of the item X; what drops / where does X drop:
--                                        what gives it to loot; where to get / how to get X: every
--                                        way (vendors, creatures, objects, quests)
--      who teaches / where to learn X    the trainers of the spell or trade X
--      in <zone>                         only what stands in that zone or city
--      level 20-30, lvl 25, level 30+    only so high (NPCs, quests, zones, dungeons)
--      where should I level, zones for level 30, dungeons for my level
--      my trainer, my corpse             your class's trainer; where you died
--      unknown flight points             the flight points you have not found
--      items ..., quests ..., zones ..., dungeons ..., raids ..., guild ..., party ..., friends ...
--                                        a first word that keeps one kind
--      not X, -X                         without X;  X or Y: either
--      "two words"                       those words together
--      45 60, elwynn 45.2 60.1           that point of the zone (the one shown, or the one named)
--
--  Ranking: a word in a name counts most, in what the thing is less, in its further words least;
--  a find you picked before a little more; between two alike the nearer first. NPCs hostile to
--  your side only where a word names them. The finds come in groups (FindBox.lua), nearest first
--  where nearness was asked for.
--
--  Read once, at the first search: Core's sets a part per frame, out of a fight (Data's jobs);
--  what the game tells (zones, flight points, the log, the guild, the group) at each search. A
--  search itself is one quick pass: a word is looked for whole in a find's lowered words first
--  (the game's own string search), only a short one as first letters too.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Data, Fuzzy, Plain = Core.Data, Core.Fuzzy, Core.Plain
local Coords = ns.Coords
local Find = {}
ns.Find = Find

Find.SHOWN = 40       -- finds handed to the list at most
Find.GROUP = 8        -- of one group at most, where several share the list
Find.PLACES = 40      -- a find's points drawn on the map at most, the nearest first
Find.SOURCES = 15     -- an item's sources of one way at most (vendors, creatures, objects, quests), the likeliest first
Find.SHORT = 4        -- a word so short may also be the first letters of a find's words ("wt", "brd")
Find.ROLE, Find.MORE = 0.5, 0.25 -- what a word found in what a thing is counts, and in its further words, of one in its name
Find.PICK, Find.PICKS = 40, 5    -- a find picked before: so much more per pick, up to so many picks
Find.HISTORY = 25     -- searches remembered (Up in the empty field)
Find.KEPT = 200       -- finds whose picks are remembered
Find.CLOSE = 8        -- finds offered as close to what was typed when nothing was found
Find.AROUND = 3       -- levels around yours that count as yours (where should I level)
Find.FARMS = 4        -- an item's best places to farm listed first among its sources
Find.MARKER = 30      -- a place to farm's pin on the map, its size
Find.RANKED = 300     -- finds measured at most (how far): the best by rank
Find.NEAR = 2000      -- the same where nearness was asked for: many alike (every vendor), the nearest among them

Find.TEXT = {
    groups = {
        people = "Guild, group and friends", npc = "NPCs", place = "Places", item = "Items", quest = "Quests",
        zone = "Zones and dungeons", spell = "Taught by trainers", near = "Nearest first", close = "Close to what you typed",
        get = "Where to get %s", sold = "Who sells %s", drop = "What drops %s", learn = "Who teaches %s",
        farm = "Where to farm %s", farmFirst = "The best places to farm it", marker = "Your markers",
        instead = "None that way. ",
    },
    sells = "Sells it", sellsFor = "Sells it for %s", drops = "Drops it", dropsAt = "Drops it (%s%%)", gives = "Gives it",
    reward = "A reward of %s", teaches = "Teaches %s", inLog = "In your log", done = "Done", quest = "Quest, level %d",
    questAny = "Quest", member = "Guild member", party = "In your group", friend = "Friend", offline = "Offline",
    corpse = "Your corpse", spot = "%.1f, %.1f", flight = "Flight point", unknownFlight = "Flight point not found yet",
    zone = "Zone", continent = "Continent", dungeon = "Dungeon", raid = "Raid", levels = "Levels %d-%d",
    foe = "Hostile to you", far = "Far away", inZone = "Somewhere in this zone", level = "Level %d", levelRange = "Level %d-%d",
    unconfirmed = Core.UNCONFIRMED,
    spelled = "Searched for: %s",
    marker = "Your marker",
}

local NPCS, SPAWNS, CREATURES = Data.Set("NPCs"), Data.Set("Spawns"), Data.Set("CreatureSpawns")
local OBJECTS, ITEMS, VENDORS = Data.Set("Objects"), Data.Set("Items"), Data.Set("Vendors")
local QUESTS, PLACES, TRAINERS = Data.Set("Quests"), Data.Set("Places"), Data.Set("Trainers")
local SPELLS, SKILLS, DROP_SET = Data.Set("Spells"), Data.Set("SkillLines"), Data.Set("Drops")
local NONE = {}
local find, lower, floor = string.find, string.lower, math.floor

-------------------------------------------------------------------------------
--  Our words
-------------------------------------------------------------------------------
-- The words a thing is known by beyond its name: each service, each kind of goods, each kind of object and place.
-- What a player types for it, in plain English: "inn" finds the innkeeper, "ah" the auction house (its first letters).
local SERVICE = {
    vendor = "vendor merchant shop", repair = "repair", innkeeper = "innkeeper inn hearthstone",
    trainer = "trainer", weaponmaster = "weapon master weapon trainer", flightmaster = "flight master",
    banker = "banker bank", auctioneer = "auctioneer auction house", stablemaster = "stable master",
    battlemaster = "battlemaster battleground", spirithealer = "spirit healer graveyard", guildmaster = "guild master",
    tabard = "tabard vendor", questgiver = "quest giver", guard = "guard",
}
local GOODS = {
    food = "food drink", reagents = "reagents", poisons = "poisons", ammunition = "ammunition arrows bullets",
    bags = "bags", tradegoods = "trade goods supplies", potions = "potions",
}
local OBJECT_WORDS = { chest = "chest treasure", herb = "herb herbalism", ore = "ore vein mining", mailbox = "mailbox mail",
                       book = "book", quest = "quest object" }
local PLACE_WORDS = {
    crossing = "crossing way", cave = "cave", dungeon = "dungeon entrance instance", raid = "raid entrance instance",
    pier = "pier dock boat", mailbox = "mailbox mail", meetingstone = "meeting stone summoning stone",
    spirithealer = "spirit healer graveyard",
}
-- The trades as their trainers are titled (Journeyman Blacksmith, Herbalist, Fisherman): a trainer whose title holds
-- one of a trade's words is known by all of them, so "blacksmithing trainer" and "smith" find the Journeyman
-- Blacksmith alike, and "miner" the Mining Trainer.
local TRADES = {
    { "alchemy", "alchemist" }, { "blacksmithing", "blacksmith", "smith", "armor crafter", "weapon crafter" },
    { "enchanting", "enchanter" }, { "engineering", "engineer" }, { "herbalism", "herbalist" },
    { "leatherworking", "leatherworker", "leathercrafter" }, { "mining", "miner" }, { "skinning", "skinner" },
    { "tailoring", "tailor" }, { "cooking", "cook", "chef", "butcher" }, { "first aid", "physician", "medic" },
    { "fishing", "fisherman", "angler" },
}
-- A weapon's word beside "trainer": the weapon masters teach it.
local WEAPONS = { sword = true, swords = true, axe = true, axes = true, mace = true, maces = true, dagger = true,
                  daggers = true, staff = true, staves = true, bow = true, bows = true, gun = true, guns = true,
                  crossbow = true, crossbows = true, polearm = true, polearms = true, fist = true, thrown = true,
                  wand = true, wands = true }
-- What a sentence asks for, by how it begins (the rest: the thing): an item's vendors, what drops it, every way to it;
-- the trainers of a spell or trade.
local ASKS = {
    { "^where to farm (.+)$", "farm" }, { "^where can i farm (.+)$", "farm" }, { "^where should i farm (.+)$", "farm" },
    { "^best places? to farm (.+)$", "farm" }, { "^farming (.+)$", "farm" }, { "^farm (.+)$", "farm" },
    { "^where to gather (.+)$", "farm" }, { "^where to mine (.+)$", "farm" }, { "^where to pick (.+)$", "farm" },
    { "^where to skin (.+)$", "farm" }, { "^(.+) farming$", "farm" }, { "^(.+) farm$", "farm" },
    { "^who sells (.+)$", "sold" }, { "^where can i buy (.+)$", "sold" }, { "^where to buy (.+)$", "sold" },
    { "^where do i buy (.+)$", "sold" }, { "^vendors? for (.+)$", "sold" }, { "^buy (.+)$", "sold" },
    { "^what drops (.+)$", "drop" }, { "^who drops (.+)$", "drop" }, { "^where does (.+) drop$", "drop" },
    { "^where do (.+) drop$", "drop" }, { "^drops? of (.+)$", "drop" },
    { "^where to get (.+)$", "get" }, { "^where do i get (.+)$", "get" }, { "^where can i get (.+)$", "get" },
    { "^how do i get (.+)$", "get" }, { "^how to get (.+)$", "get" }, { "^where to find (.+)$", "get" },
    { "^sources? of (.+)$", "get" }, { "^get (.+)$", "get" },
    { "^who teaches (.+)$", "learn" }, { "^who trains (.+)$", "learn" }, { "^where to learn (.+)$", "learn" },
    { "^where do i learn (.+)$", "learn" }, { "^where can i learn (.+)$", "learn" }, { "^learn (.+)$", "learn" },
}
-- Where to go at your level: zones (and dungeons) as high as you are, or as the number says.
local LEVELING = { "^where should i level", "^where to level", "^where should i quest", "^where to quest",
                   "^leveling zones", "^zones for ", "^zones at " }
local DUNGEONING = { "^what dungeon", "^which dungeon", "^dungeons for ", "^dungeons at ", "^what raid", "^raids for " }
-- A first word that keeps one kind of find.
local KINDS = {
    items = "item", quests = "quest", zones = "zone", zone = "zone", dungeons = "dungeon", dungeon = "dungeon",
    raids = "raid", raid = "raid", flights = "flight", flight = "flight", mailboxes = "mailbox", mailbox = "mailbox",
    npcs = "npc", guild = "member", members = "member", party = "party", group = "party", friends = "friend",
    markers = "marker", marks = "marker",
}
-- Words that ask nothing of their own: left out (where they are not all there is).
local FILLERS = { where = true, is = true, are = true, the = true, a = true, an = true, to = true, find = true,
                  show = true, me = true, please = true, i = true, can = true, ["where's"] = true, whats = true }
-- Nearness asked for: these words, and a slip of them ("nearset", "closets").
local function Nearness(word)
    return word == "nearby" or word == "near" or word:find("^neare?a?s") ~= nil or word:find("^clos[es]") ~= nil
end

-------------------------------------------------------------------------------
--  A find's words
-------------------------------------------------------------------------------
-- The first letters of a text's words, as Core's Fuzzy finds them: at its start, after anything but a letter or a
-- digit, and at a capital after a small letter.
local function Heads(text)
    if type(text) ~= "string" then return "" end
    local heads = text:gsub("(%l)(%u)", "%1 %2"):gsub("[%w']+", function(word) return word:sub(1, 1) end)
    return lower((heads:gsub("[^%w]", "")))
end

-- A find's words in lower case, each part apart (name, what it is, further words), and the first letters of its
-- name's and what-it-is's words; looked through by the search (Match).
local function Words(entry, name, role, more)
    entry.name, entry.role = name, role
    entry.lowName = lower(name or "")
    entry.lowRole = role and lower(role) or nil
    entry.lowMore = more and more ~= "" and lower(more) or nil
    entry.heads = Heads(name) .. " " .. Heads(role)
    return entry
end

-------------------------------------------------------------------------------
--  What there is to find: Core's sets, read once
-------------------------------------------------------------------------------
local index = {}       -- the finds of Core's sets, once read
local byKey = {}       -- the same by key (npc:69, item:2589)
local reading = nil    -- the jobs still to run, in order; nil: not started, false: done
local waiting          -- the search asked for while they read: { text, done }
local side             -- "alliance" or "horde"
local sourced = {}     -- [item] = true: it comes from somewhere (a vendor, a creature, an object, a quest)
local rewarded = {}    -- [item] = { quest, ... }: the quests it is a reward of
local taught = {}      -- [spell name lower] = the spell's find: what trainers teach, one per name and class or trade

local function Side()
    side = side or lower(Plain(UnitFactionGroup("player")) or "alliance")
    return side
end

local function Add(entry)
    index[#index + 1] = entry
    byKey[entry.key] = entry
end

-- The trade a trainer's title names (one of TRADES), as its words.
local function Trade(title)
    if type(title) ~= "string" then return nil end
    local low = lower(title)
    for _, trade in ipairs(TRADES) do
        for _, word in ipairs(trade) do
            if find(low, word, 1, true) then return trade end
        end
    end
    return nil
end

-- An NPC of Core's set as a find: its title is what it is; its services, goods and trade its further words.
local function Creature(id, record)
    local name = record.name
    if type(name) ~= "string" or name == "" then return end
    local more = {}
    for _, service in ipairs(type(record.services) == "table" and record.services or NONE) do
        more[#more + 1] = SERVICE[service]
    end
    for _, goods in ipairs(type(record.goods) == "table" and record.goods or NONE) do more[#more + 1] = GOODS[goods] end
    local trade = Trade(record.title)
    if trade then
        for _, word in ipairs(trade) do more[#more + 1] = word end
    end
    if record.rank == "rare" or record.rank == "rareelite" then more[#more + 1] = "rare" end
    local entry = Words({ kind = "npc", group = "npc", key = "npc:" .. id, id = id, thing = "npc:" .. id,
                          low = record.levelMin, high = record.levelMax, services = record.services,
                          goods = record.goods, title = record.title, rank = record.rank },
        name, record.title, table.concat(more, " "))
    local reaction = record[Side()]
    entry.foe = reaction == "hostile" or nil
    Add(entry)
end

local function Object(id, record)
    local name, kind = record.name, record.kind
    if type(name) ~= "string" or name == "" or kind == "door" then return end
    if not SPAWNS:Get("object:" .. id, "points") then return end -- (no place: nothing to show on the map)
    Add(Words({ kind = "object", group = "place", key = "object:" .. id, id = id, thing = "object:" .. id, what = kind },
        name, nil, OBJECT_WORDS[kind]))
end

local function Place(id, record)
    local kind, point = record.kind, record.point
    if type(point) ~= "table" or not point.map then return end
    local name = record.name or PLACE_WORDS[kind] and (PLACE_WORDS[kind]:match("^(%S+)")) or kind
    local role = kind == "raid" and Find.TEXT.raid or kind == "dungeon" and Find.TEXT.dungeon or nil
    local group = (kind == "dungeon" or kind == "raid") and "zone" or "place"
    Add(Words({ kind = "place", group = group, key = "place:" .. id, id = id, what = kind, low = record.levelMin,
                high = record.levelMax, instance = record.instance, to = record.to,
                spots = { { map = point.map, x = (point.x or 0) / 100, y = (point.y or 0) / 100 } } },
        name, role, PLACE_WORDS[kind]))
end

-- An item from somewhere, with its picture and its quality's colour.
local function Item(id)
    local record = ITEMS:Get(id)
    if type(record) ~= "table" or type(record.name) ~= "string" then return end
    Add(Words({ kind = "item", group = "item", key = "item:" .. id, id = id, icon = record.icon, quality = record.quality,
                low = record.minLevel }, record.name, nil, nil))
end

-- A quest of Core's set for your side.
local function Quest(id, record)
    local name = record.name
    if type(name) ~= "string" or name == "" then return end
    if record.side and record.side ~= Side() then return end
    Add(Words({ kind = "quest", group = "quest", key = "quest:" .. id, id = id, quest = id, low = record.level,
                high = record.level, minLevel = record.minLevel }, name, nil, "quest"))
end

-- What trainers teach: one find per spell's name and class or trade (its ranks are one); its trainers found by title.
local function Taught(id, record)
    local name = SPELLS:Get(id, "name")
    if type(name) ~= "string" or name == "" then return end
    local trainers -- the words a trainer's title has for it: its class's name, or its trade's
    if record.class then
        local creatures = rawget(_G, "C_CreatureInfo")
        local info = Core.Ask(creatures and creatures.GetClassInfo, record.class)
        local className = type(info) == "table" and info.className
        if not className then return end
        trainers = { lower(className) .. " trainer" }
    else
        local skill = record.skill and SKILLS:Get(record.skill, "name")
        local trade = skill and Trade(skill)
        if not trade then return end
        trainers = trade
    end
    local key = lower(name) .. "|" .. trainers[1]
    if taught[key] then return end
    local entry = Words({ kind = "spell", group = "spell", key = "spell:" .. id, id = id, spell = id, trainers = trainers,
                          low = record.level }, name, nil, trainers[1])
    taught[key] = entry
    Add(entry)
end

-- The items that come from somewhere: given to loot (Drops), sold (Vendors), a quest's reward (Quests).
local function Sourced(_, record)
    for _, entry in ipairs(type(record.items) == "table" and record.items or NONE) do
        if type(entry) == "table" and entry.item then sourced[entry.item] = true end
    end
end
local function Sold(_, record)
    for _, entry in ipairs(type(record.goods) == "table" and record.goods or NONE) do
        if type(entry) == "table" and entry.item then sourced[entry.item] = true end
    end
end
local REWARDS = { "rewardItems", "rewardChoices" }
local function Rewards(id, record)
    if record.side and record.side ~= Side() then return end
    for _, field in ipairs(REWARDS) do
        for _, entry in ipairs(type(record[field]) == "table" and record[field] or NONE) do
            local item = type(entry) == "table" and entry.item
            if item then
                sourced[item] = true
                local quests = rewarded[item] or {}
                rewarded[item] = quests
                quests[#quests + 1] = id
            end
        end
    end
    Quest(id, record)
end

-- The items from somewhere, one by one (a job of Core's scheduler: a part per frame).
local function Items()
    local list = {}
    for item in pairs(sourced) do list[#list + 1] = item end
    table.sort(list)
    for _, item in ipairs(list) do
        Item(item)
        Core.Steps.Check()
    end
end

-- The jobs, one after the other: each a set's walk (or the items'); a search asked for meanwhile runs at the end.
local NPC_JOB = { NPCS, function(id, record)
    if SPAWNS:Get("npc:" .. id, "points") or CREATURES:Get(id, "points") then Creature(id, record) end
end }
local JOBS = {
    NPC_JOB, { OBJECTS, Object }, { PLACES, Place }, { DROP_SET, Sourced }, { VENDORS, Sold },
    { QUESTS, Rewards }, { "items" }, { TRAINERS, Taught },
}

local Next
function Next()
    local job = reading and table.remove(reading, 1)
    if not job then
        reading = false
        local asked = waiting
        waiting = nil
        if asked then Find.Ask(asked[1], asked[2]) end
        return
    end
    if job[1] == "items" then
        if not (Core.Steps and Core.Steps.Run) then Items() return Next() end
        -- (done: told also where the job ran into an error, so the search goes on with the next set)
        Core.Steps.Run({ name = "map search: items", label = "Navigation: map search",
                         done = function() Core.Safe("map search", Next) end }, Items)
        return
    end
    local set, fn = job[1], job[2]
    if not set:Ready() then return Next() end -- (a set this game has not: passed over, Retail)
    local started = set:Each(fn, function() Core.Safe("map search", Next) end)
    if not started then return Next() end
end

-- Reads Core's sets, once: at the first search.
local function Read()
    if reading ~= nil then return end
    reading = {}
    for _, job in ipairs(JOBS) do reading[#reading + 1] = job end
    Next()
end
Find.Prepare = Read

-------------------------------------------------------------------------------
--  What the game tells: made at each search (cheap)
-------------------------------------------------------------------------------
local zones          -- the zones and continents, once: { find, ... }
local function MapName(map)
    local info = Core.Ask(C_Map.GetMapInfo, map)
    return type(info) == "table" and info.name or nil
end
Find.MapName = MapName

-- The zones and continents of the map tree, and the dungeons' maps, once (they do not change in play).
local function Zones()
    if zones then return zones end
    zones = {}
    local seen = {}
    for _, plane in ipairs(Coords.Planes()) do
        local name = MapName(plane)
        if name and not seen[plane] then
            seen[plane] = true
            zones[#zones + 1] = Words({ kind = "zone", group = "zone", key = "map:" .. plane, map = plane, plane = true },
                name, Find.TEXT.continent, "continent")
        end
        for _, zone in ipairs(Coords.Zones(plane)) do
            local zoneName = MapName(zone.map)
            if zoneName and not seen[zone.map] then
                seen[zone.map] = true
                zones[#zones + 1] = Words({ kind = "zone", group = "zone", key = "map:" .. zone.map, map = zone.map },
                    zoneName, Find.TEXT.zone, "zone")
            end
        end
    end
    -- The dungeons' maps (Dungeons.lua), where Core's places have no entrance of that name.
    for _, entry in ipairs(ns.Dungeons and ns.Dungeons.List() or NONE) do
        if entry.name and not seen[entry.map] then
            seen[entry.map] = true
            zones[#zones + 1] = Words({ kind = "dungeon", group = "zone", key = "dungeon:" .. tostring(entry.map),
                map = entry.map }, entry.name, Find.TEXT.dungeon, "dungeon instance")
        end
    end
    return zones
end

-- A zone's map by its name, as the game names it (a guild member's zone): the zone, else a continent.
local function ZoneNamed(name)
    if type(name) ~= "string" or name == "" then return nil end
    local low = lower(name)
    for _, zone in ipairs(Zones()) do
        if zone.kind == "zone" and zone.lowName == low then return zone.map end
    end
    return nil
end
Find.ZoneNamed = ZoneNamed

-- The flight points of your side and the neutral ones, on every continent, as the game's map tells them.
local function Flights(list)
    local sides = rawget(_G, "Enum") and Enum.FlightPathFaction or {}
    local faction = Plain(UnitFactionGroup("player"))
    for _, plane in ipairs(Coords.Planes()) do
        for _, info in ipairs(ns.Live.Flights(plane)) do
            local who = info.faction
            local x, y = info.position and Plain(info.position.x), info.position and Plain(info.position.y)
            if x and y and info.name and not ((who == sides.Horde and faction ~= "Horde")
                    or (who == sides.Alliance and faction ~= "Alliance")) then
                local known = ns.Planner and ns.Planner.Knows(info.nodeID)
                list[#list + 1] = Words({ kind = "flight", group = "place", key = "flight:" .. tostring(info.nodeID),
                    id = info.nodeID, unknown = not known or nil, atlas = "flightmaster",
                    spots = { { map = plane, x = x, y = y } } },
                    info.name, known and Find.TEXT.flight or Find.TEXT.unknownFlight, "flight point flight master taxi")
            end
        end
    end
end

-- The quests in your log, by their titles, objectives and zone.
local function Log(list)
    local zone
    for index = 1, Core.Ask(C_QuestLog.GetNumQuestLogEntries) or 0 do
        local info = Core.Ask(C_QuestLog.GetInfo, index)
        if type(info) == "table" and info.isHeader then zone = info.title end
        local quest = type(info) == "table" and not info.isHeader and not info.isHidden and Plain(info.questID)
        if quest and info.title then
            local words = { zone or "" }
            for _, objective in ipairs(Core.Ask(C_QuestLog.GetQuestObjectives, quest) or NONE) do
                if type(objective) == "table" and type(objective.text) == "string" then words[#words + 1] = objective.text end
            end
            list[#list + 1] = Words({ kind = "log", group = "quest", key = "quest:" .. quest, quest = quest,
                                      low = info.level, high = info.level }, info.title, Find.TEXT.inLog, table.concat(words, " "))
        end
    end
end

-- A class's file name to its round icon (the game's class circles).
local function ClassLook(entry, class)
    local coords = rawget(_G, "CLASS_ICON_TCOORDS")
    if class and coords and coords[class] then
        entry.icon, entry.coords = "Interface\\TargetingFrame\\UI-Classes-Circles", coords[class]
    end
    entry.class = class
end

-- Your guild's members (the online first, in the game's roster: Core's where the module Guild reads it, else asked of
-- the game here), your party or raid, and your friends: each where the game says it is.
local function People(list)
    local roster = Data.Guild and Data.Guild.Roster and Data.Guild.Roster()
    local mine = Core.FullName("player")
    if type(roster) == "table" and #roster > 0 then
        for _, member in ipairs(roster) do
            if member.name ~= mine then
                local entry = Words({ kind = "member", group = "people", key = "member:" .. member.key, who = member.name,
                    zone = member.zone, online = member.online, level = member.level },
                    member.name, member.online and (member.zone or Find.TEXT.member) or Find.TEXT.offline, "guild member")
                ClassLook(entry, member.class)
                list[#list + 1] = entry
            end
        end
    elseif Core.Ask(rawget(_G, "IsInGuild")) then
        local info = rawget(_G, "GetGuildRosterInfo")
        for index = 1, info and Core.Ask(rawget(_G, "GetNumGuildMembers")) or 0 do
            -- name, rank, rank index, level, class name, zone, note, officer note, online, status, class
            local ok, name, _, _, level, _, zone, _, _, online, _, class = pcall(info, index)
            name = ok and type(name) == "string" and Core.PlayerKeyOf(Plain(name)) or nil
            zone, online, class = Plain(zone), Plain(online), Plain(class)
            if type(name) == "string" and name ~= mine then
                local entry = Words({ kind = "member", group = "people", key = "member:" .. name, who = name, zone = zone,
                    online = online and true or false, level = level },
                    name, online and (zone or Find.TEXT.member) or Find.TEXT.offline, "guild member")
                ClassLook(entry, class)
                list[#list + 1] = entry
            end
        end
    end
    local raid = IsInRaid()
    for index = 1, raid and GetNumGroupMembers() or GetNumSubgroupMembers() do
        local unit = (raid and "raid" or "party") .. index
        local name = not UnitIsUnit(unit, "player") and Core.FullName(unit)
        if name then
            local entry = Words({ kind = "party", group = "people", key = "party:" .. name, who = name, unit = unit,
                online = true }, name, Find.TEXT.party, "party group raid")
            ClassLook(entry, select(2, UnitClass(unit)))
            list[#list + 1] = entry
        end
    end
    local friends = rawget(_G, "C_FriendList")
    for index = 1, friends and Core.Ask(friends.GetNumFriends) or 0 do
        local info = Core.Ask(friends.GetFriendInfoByIndex, index)
        if type(info) == "table" and type(info.name) == "string" then
            local entry = Words({ kind = "friend", group = "people", key = "friend:" .. info.name, who = info.name,
                zone = info.area, online = info.connected and true or false, level = info.level },
                info.name, info.connected and (info.area or Find.TEXT.friend) or Find.TEXT.offline, "friend")
            list[#list + 1] = entry
        end
    end
end

-- Your own markers (Markers.lua), by their titles and words.
local function Marked(list)
    local Markers = ns.Markers
    for _, marker in ipairs(Markers and Markers.List() or NONE) do
        local icon = Markers.Icon(marker.icon)
        local title = (marker.title and marker.title ~= "") and marker.title or Markers.TEXT.untitled
        list[#list + 1] = Words({ kind = "marker", group = "marker", key = "marker:" .. tostring(marker.id),
                                  marker = marker, atlas = icon.atlas, icon = icon.texture,
                                  coords = icon.cut and { icon.cut, 1 - icon.cut, icon.cut, 1 - icon.cut },
                                  spots = { { map = marker.map, x = marker.x, y = marker.y } } },
            title, Find.TEXT.marker, (marker.text or "") .. " marker " .. (marker.from or ""))
    end
end

-- Your corpse, while the game tells where it lies.
local function Corpse(list)
    local death = rawget(_G, "C_DeathInfo")
    if not death or not Core.Ask(rawget(_G, "UnitIsDeadOrGhost"), "player") then return end
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local point = map and Core.Ask(death.GetCorpseMapPosition, map)
    local x, y = point and Plain(point.x), point and Plain(point.y)
    if not (x and y) then return end
    list[#list + 1] = Words({ kind = "corpse", group = "place", key = "corpse", atlas = "poi-graveyard-neutral",
                              spots = { { map = map, x = x, y = y } } }, Find.TEXT.corpse, nil, "corpse body died")
end

-------------------------------------------------------------------------------
--  Where a find stands
-------------------------------------------------------------------------------
-- A thing's points of Core's data (0 to 100 there), as points 0 to 1.
local function Points(thing, creature)
    local points = SPAWNS:Get(thing, "points") or creature and CREATURES:Get(creature, "points")
    local list = {}
    for _, point in pairs(type(points) == "table" and points or NONE) do
        if type(point) == "table" and point.map and point.x and point.y then
            list[#list + 1] = { map = point.map, x = point.x / 100, y = point.y / 100 }
        end
    end
    return list
end

Find.Points = Points

-- The find of a key of Core's data (npc:69, object:1617, item:2589), once read; nil while not (yet) known.
function Find.Known(key)
    return byKey[key]
end

-- A quest's places of Core's data: where its givers stand.
local function Givers(quest)
    local record = QUESTS:Get(quest)
    local list = {}
    for _, giver in ipairs(type(record) == "table" and type(record.startNPCs) == "table" and record.startNPCs or NONE) do
        local npc = type(giver) == "table" and giver.npc or tonumber(giver)
        if npc then
            for _, point in ipairs(Points("npc:" .. npc, npc)) do list[#list + 1] = point end
        end
    end
    for _, giver in ipairs(type(record) == "table" and type(record.startObjects) == "table" and record.startObjects or NONE) do
        local object = type(giver) == "table" and giver.object or tonumber(giver)
        if object then
            for _, point in ipairs(Points("object:" .. object)) do list[#list + 1] = point end
        end
    end
    return list
end

-- A point's place in the plane you are in (yards), nil where it is not in it.
local function Yards(point, plane, pu, pv)
    if not plane then return nil end
    local u, v = Coords.MapToPlane(point.map, point.x, point.y, plane)
    if not u then return nil end
    return math.sqrt((u - pu) ^ 2 + (v - pv) ^ 2), u, v
end

-- A member's place: in your group where the game tells it, else the middle of the zone the roster names.
local function Someone(entry)
    local unit = entry.unit
    if not unit and entry.who then
        local raid = IsInRaid()
        for index = 1, raid and GetNumGroupMembers() or GetNumSubgroupMembers() do
            local each = (raid and "raid" or "party") .. index
            if Core.FullName(each) == entry.who then unit = each end
        end
    end
    if unit then
        local map = Core.Ask(C_Map.GetBestMapForUnit, unit)
        local position = map and Core.Ask(C_Map.GetPlayerMapPosition, map, unit)
        local x, y = position and Plain(position.x), position and Plain(position.y)
        if x and y then return { { map = map, x = x, y = y, exact = true } } end
    end
    local map = entry.online and ZoneNamed(entry.zone)
    if map then return { { map = map, x = 0.5, y = 0.5, zone = true } } end
    return {}
end

-- Where a find stands, each point { map, x, y } (0 to 1), not yet sorted: kept while it is shown (a member's and a
-- group's read anew each time).
local function Spots(entry)
    if entry.spots then return entry.spots end
    local kind, list = entry.kind, nil
    if kind == "npc" then
        list = Points(entry.thing, entry.id)
    elseif kind == "object" then
        list = Points(entry.thing)
    elseif kind == "quest" then
        list = Givers(entry.quest)
    elseif kind == "log" then
        local map, x, y
        if ns.QuestLog.Place then map, x, y = ns.QuestLog.Place(entry.quest) end
        list = map and x and { { map = map, x = x, y = y } } or {}
    elseif kind == "member" or kind == "party" or kind == "friend" then
        return Someone(entry)
    elseif kind == "zone" or kind == "dungeon" then
        return {}
    else
        list = {}
    end
    entry.spots = list
    return list
end

-- The points nearest first: how far each is in yards where it is in your plane (near), the others after in their
-- order (far).
function Find.Spots(entry)
    local list = Spots(entry)
    local plane, pu, pv = ns.Live.Player()
    local measured = {}
    for _, point in ipairs(list) do
        local yards = pu and Yards(point, plane, pu, pv)
        measured[#measured + 1] = { point = point, yards = yards }
    end
    table.sort(measured, function(a, b)
        if a.yards and b.yards then return a.yards < b.yards end
        return a.yards ~= nil and b.yards == nil
    end)
    return measured, plane, pu, pv
end

-- How far a find is now, in yards, and its nearest point; nil where it has none in your plane.
function Find.Measure(entry)
    local list = Spots(entry)
    local plane, pu, pv = ns.Live.Player()
    if not pu then return nil, list[1] end
    local best, bestPoint, bu, bv
    for _, point in ipairs(list) do
        local yards, u, v = Yards(point, plane, pu, pv)
        if yards and (not best or yards < best) then best, bestPoint, bu, bv = yards, point, u, v end
    end
    entry.yards, entry.nearest = best, bestPoint or list[1]
    entry.du, entry.dv = bu and bu - pu, bv and bv - pv
    return best, bestPoint or list[1]
end

-------------------------------------------------------------------------------
--  Reading what was typed
-------------------------------------------------------------------------------
-- The words of a text: lowered, a quoted part one word, "or" between two sets of words, "not"/"without"/"-" before a
-- word that must not be there.
local function Split(text)
    local sets, without, set = {}, {}, {}
    sets[1] = set
    local quoted = {}
    text = text:gsub('"([^"]+)"', function(phrase)
        quoted[#quoted + 1] = phrase
        return " \001" .. #quoted .. " "
    end)
    local negate = false
    for word in text:gmatch("%S+") do
        local phrase = word:match("^\001(%d+)$")
        if phrase then word = quoted[tonumber(phrase)] end
        if word == "or" and #set > 0 then
            set = {}
            sets[#sets + 1] = set
        elseif word == "not" or word == "without" then
            negate = true
        elseif word:sub(1, 1) == "-" and #word > 1 then
            without[#without + 1] = word:sub(2)
        elseif negate then
            without[#without + 1] = word
            negate = false
        else
            set[#set + 1] = word
        end
    end
    if #set == 0 and #sets > 1 then sets[#sets] = nil end
    return sets, without
end

-- A level or levels in the words, taken out: "level 30" (that level), "lvl 20-30", "levels 20 to 30", "level 30+"
-- (and higher), "for level 30" and "for my level" (around it, Find.AROUND).
local LEVEL = { "levels", "level", "lvls", "lvl", "lv" }
local function Levels(text, asked)
    local mine = Plain(UnitLevel("player")) or 1
    local function Took(low, high)
        asked.low, asked.high = tonumber(low), tonumber(high)
        return " "
    end
    local function Around(level)
        level = tonumber(level) or mine
        return Took(level - Find.AROUND, level + Find.AROUND)
    end
    text = text:gsub("%f[%w]for my level%f[%W]", function() return Around(mine) end)
    text = text:gsub("%f[%w]my level%f[%W]", function() return Around(mine) end)
    for _, word in ipairs(LEVEL) do
        text = text:gsub("%f[%w]for " .. word .. " (%d+)%f[%D]", Around)
        text = text:gsub("%f[%w]at " .. word .. " (%d+)%f[%D]", Around)
    end
    for _, word in ipairs(LEVEL) do
        text = text:gsub("%f[%w]" .. word .. " ?(%d+) ?%- ?(%d+)%f[%D]", Took)
        text = text:gsub("%f[%w]" .. word .. " (%d+) to (%d+)%f[%D]", Took)
        text = text:gsub("%f[%w]" .. word .. " ?(%d+)%+", function(low) return Took(low, 999) end)
        text = text:gsub("%f[%w]" .. word .. " ?(%d+)%f[%D]", function(level) return Took(level, level) end)
    end
    return text
end

-- "in <zone>" (or "at"): only what stands there. The zone whose name the words after it begin with (the longest of
-- them), else the first whose name begins with those words ("in elwynn"); the words of its name taken out.
local function Where(text, asked)
    local cut, place = text:match("()%f[%w]in (.+)$")
    if not cut then cut, place = text:match("()%f[%w]at (.+)$") end
    if not cut then return text end
    local best, length
    for _, zone in ipairs(Zones()) do
        if (zone.kind == "zone" or zone.plane) and find(place, zone.lowName, 1, true) == 1
            and (not length or #zone.lowName > length) then
            best, length = zone, #zone.lowName
        end
    end
    if not best and #place >= 3 then
        for _, zone in ipairs(Zones()) do
            if zone.kind == "zone" and find(zone.lowName, place, 1, true) == 1 then
                best, length = zone, #place
                break
            end
        end
    end
    if not best then return text end
    asked.zone = best.map
    return text:sub(1, cut - 1) .. " " .. place:sub(length + 1)
end

-- What was typed, read: { sets (words, one set per "or"), without, near, want ("sold", "drop", "get", "learn",
-- "level", "dungeon"), kind, zone (a map), low, high, spot = { map, x, y }, unknown, text }; nil for nothing.
function Find.Read(text)
    if type(text) ~= "string" then return nil end
    text = lower(text):gsub("[%?!]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    local asked = { text = text }
    -- A point typed as two numbers at the end (45 60, 45.2,60.1), after a zone's name or none.
    local before, x, y = text:match("^(.-)%s*(%d+%.?%d*)%s*[,%s]%s*(%d+%.?%d*)$")
    x, y = tonumber(x), tonumber(y)
    if x and y and x <= 100 and y <= 100 then
        local map = before ~= "" and ZoneNamed(before)
        if not map and before ~= "" then
            for _, zone in ipairs(Zones()) do
                if zone.kind == "zone" and find(zone.lowName, before, 1, true) == 1 then map = zone.map break end
            end
        end
        if map or before == "" then
            asked.spot = { map = map, x = x / 100, y = y / 100 }
            return asked
        end
    end
    for _, pattern in ipairs(LEVELING) do
        if text:find(pattern) then asked.want, asked.kind = "level", "zone" end
    end
    for _, pattern in ipairs(DUNGEONING) do
        if text:find(pattern) then asked.want, asked.kind = "level", text:find("raid") and "raid" or "dungeon" end
    end
    if asked.want == "level" then
        text = Levels(text, asked)
        if not asked.low then
            local mine = Plain(UnitLevel("player")) or 1
            asked.low, asked.high = mine - Find.AROUND, mine + Find.AROUND
        end
        asked.sets, asked.without = { {} }, {}
        return asked
    end
    for _, ask in ipairs(ASKS) do
        local thing = text:match(ask[1])
        if thing then
            asked.want, text = ask[2], thing
            break
        end
    end
    text = Where(text, asked)
    text = Levels(text, asked)
    -- Your class's trainer, your corpse.
    local className = Plain(UnitClass("player"))
    if className then
        text = text:gsub("%f[%w]my class trainer%f[%W]", lower(className) .. " trainer")
        text = text:gsub("%f[%w]my trainer%f[%W]", lower(className) .. " trainer")
        text = text:gsub("%f[%w]class trainer%f[%W]", lower(className) .. " trainer")
    end
    text = text:gsub("%f[%w]where did i die%f[%W]", "corpse"):gsub("%f[%w]my body%f[%W]", "corpse")
    text = text:gsub("%f[%w]my corpse%f[%W]", "corpse")
    -- The words, nearness and fillers taken out (not where they are all there is).
    local sets, without = Split(text)
    for number, set in ipairs(sets) do
        local kept = {}
        for _, word in ipairs(set) do
            if Nearness(word) then
                asked.near = true
            elseif word == "me" and asked.near then -- (near me)
            elseif not FILLERS[word] then
                kept[#kept + 1] = word
            end
        end
        if #kept == 0 and #set > 0 and not asked.near then kept = set end
        -- A first word that keeps one kind (items ..., dungeons ...); unknown or not found flight points.
        local kind = kept[1] and KINDS[kept[1]]
        if kind and not asked.kind then
            asked.kind = kind
            table.remove(kept, 1)
            if (kind == "flight") and kept[1] and (kept[1] == "points" or kept[1] == "paths" or kept[1] == "masters") then
                table.remove(kept, 1)
            end
        end
        for position = #kept, 1, -1 do
            local word = kept[position]
            if word == "unknown" or word == "unlearned" or word == "undiscovered" or word == "missing" or word == "new" then
                local nextWord = kept[position + 1]
                if asked.kind == "flight" or nextWord == "flight" or nextWord == "flights" then
                    asked.unknown, asked.kind = true, "flight"
                    table.remove(kept, position)
                end
            end
        end
        if asked.kind == "flight" then
            for position = #kept, 1, -1 do
                local word = kept[position]
                if word == "flight" or word == "flights" or word == "points" or word == "paths" then table.remove(kept, position) end
            end
        end
        -- A weapon's word beside "trainer": the weapon masters.
        local trainer, weapon
        for position, word in ipairs(kept) do
            if word == "trainer" or word == "trainers" then trainer = position end
            if WEAPONS[word] then weapon = position end
        end
        if trainer and weapon then
            table.remove(kept, math.max(trainer, weapon))
            table.remove(kept, math.min(trainer, weapon))
            kept[#kept + 1] = "weapon"
            kept[#kept + 1] = "master"
        end
        -- A plural typed finds the singular ("trainers", "vendors"): the last s taken off a longer word.
        for position, word in ipairs(kept) do
            if #word > 4 and word:sub(-1) == "s" and word:sub(-2) ~= "ss" then kept[position] = word:sub(1, -2) end
        end
        sets[number] = kept
    end
    asked.sets, asked.without = sets, without
    return asked
end

-------------------------------------------------------------------------------
--  The search
-------------------------------------------------------------------------------
-- How a find was picked before (FindBox: each pick kept for the character, Find.Picked).
local function Kept()
    local char = Core.Character(ns.name)
    if type(char.finds) ~= "table" then char.finds = {} end
    local kept = char.finds
    if type(kept.history) ~= "table" then kept.history = {} end
    if type(kept.picked) ~= "table" then kept.picked = {} end
    return kept
end
Find.Kept = Kept

-- A find picked: its key counted (the oldest let go past Find.KEPT), the words typed remembered.
function Find.Picked(entry, text)
    local kept = Kept()
    if entry and entry.key then
        local picked = kept.picked
        if not picked[entry.key] then
            local count = 0
            for _ in pairs(picked) do count = count + 1 end
            if count >= Find.KEPT then wipe(picked) end
        end
        picked[entry.key] = math.min((tonumber(picked[entry.key]) or 0) + 1, Find.PICKS)
    end
    Find.Remember(text)
end

-- Words searched, remembered (the newest first, each once).
function Find.Remember(text)
    if type(text) ~= "string" or text:match("^%s*$") then return end
    local history = Kept().history
    for position = #history, 1, -1 do
        if history[position] == text then table.remove(history, position) end
    end
    table.insert(history, 1, text)
    while #history > Find.HISTORY do history[#history] = nil end
end

function Find.History()
    return Kept().history
end

-- One word in a find: its rank where it is there (in its name whole, in what it is and its further words a share);
-- nil where it is not. A plain look through the lowered words first; a short word also as the first letters.
local Rank = Fuzzy.Rank
local function Word(entry, word, short)
    local inName = find(entry.lowName, word, 1, true)
    local inRole = entry.lowRole and find(entry.lowRole, word, 1, true)
    local inMore = entry.lowMore and find(entry.lowMore, word, 1, true)
    local inHeads = short and find(entry.heads, word, 1, true)
    if not (inName or inRole or inMore or inHeads) then return nil end
    local best = 0
    if inName or inHeads then
        local rank = Rank(word, entry.name, entry.lowName)
        if rank then best, entry.named = rank, true end
    end
    if (inRole or inHeads) and entry.role then
        local rank = Rank(word, entry.role, entry.lowRole)
        if rank and rank * Find.ROLE > best then best = rank * Find.ROLE end
    end
    if inMore and best == 0 then best = 200 * Find.MORE end
    if best == 0 then best = 100 * Find.MORE end
    return best
end

-- A find's rank by one set of words (all found), or nil; none may be in it of the words without.
local function Match(entry, set, without)
    entry.named = nil
    local total = 0
    for _, word in ipairs(set) do
        local rank = Word(entry, word, #word <= Find.SHORT and not word:find(" ", 1, true))
        if not rank then return nil end
        total = total + rank
    end
    for _, word in ipairs(without) do
        if find(entry.lowName, word, 1, true) or entry.lowRole and find(entry.lowRole, word, 1, true)
            or entry.lowMore and find(entry.lowMore, word, 1, true) then return nil end
    end
    return total
end

-- Whether a find is of the kind asked for (asked.kind).
local function OfKind(entry, kind)
    if not kind then return true end
    if kind == "item" or kind == "quest" or kind == "npc" or kind == "member" or kind == "party" or kind == "friend"
        or kind == "flight" then
        return entry.kind == kind or (kind == "quest" and entry.kind == "log")
    end
    if kind == "zone" then return entry.kind == "zone" end
    if kind == "dungeon" then return entry.kind == "dungeon" or entry.kind == "place" and entry.what == "dungeon" end
    if kind == "raid" then return entry.kind == "place" and entry.what == "raid" end
    if kind == "mailbox" then return entry.what == "mailbox" end
    if kind == "marker" then return entry.kind == "marker" end
    return true
end

-- Whether a find stands in the zone asked for (asked.zone): one of its points on that map.
local function InZone(entry, zone)
    if not zone then return true end
    if entry.kind == "zone" then return entry.map == zone end
    for _, point in ipairs(Spots(entry)) do
        if point.map == zone then return true end
    end
    return false
end

-- Whether a find is as high as asked (asked.low, asked.high): where it has levels.
local function AsHigh(entry, low, high)
    if not low then return true end
    local from, to = entry.low, entry.high or entry.low
    if entry.kind == "zone" and not from then from, to = ns.Label.Range(entry.map) end
    if not from then return entry.kind ~= "zone" and entry.kind ~= "place" end
    return from <= high and (to or from) >= low
end

-- Every find there is now: Core's (read once) and the game's (at each search).
local function Everything()
    local list = {}
    for _, entry in ipairs(Zones()) do list[#list + 1] = entry end
    Flights(list)
    Log(list)
    People(list)
    Corpse(list)
    Marked(list)
    return list
end

-- An item's sources as finds of their own: its vendors (and the price), what drops it (and how often), the objects that
-- give it, the quests it is a reward of; each the likeliest first, Find.SOURCES of a way at most.
local function Sources(item, want)
    local list, seen = {}, {}
    local function Source(key, role, way)
        local entry = byKey[key]
        if not entry or seen[key] then return end
        seen[key] = true
        list[#list + 1] = { entry = entry, role = role, way = way }
    end
    if want == "sold" or want == "get" then
        local count = 0
        for _, vendor in ipairs(VENDORS:Ready() and VENDORS:Keys("byItem", item) or NONE) do
            local price
            for _, goods in ipairs(VENDORS:Get(vendor, "goods") or NONE) do
                if goods.item == item then price = goods.price end
            end
            local entry = byKey["npc:" .. vendor]
            if entry and not entry.foe and count < Find.SOURCES then
                count = count + 1
                Source("npc:" .. vendor, price and Find.TEXT.sellsFor:format(Core.Coins(price)) or Find.TEXT.sells, "sold")
            end
        end
    end
    if want == "drop" or want == "get" then
        local creatures, objects = 0, 0
        for _, source in ipairs(Data.Drops and Data.Drops():From(item) or NONE) do
            local kind = source.key:match("^(%a+):")
            local rate = tonumber(source.rate) or 0
            local role = rate > 0 and Find.TEXT.dropsAt:format(rate >= 10 and floor(rate + 0.5) or floor(rate * 10 + 0.5) / 10)
                or Find.TEXT.drops
            if kind == "npc" and creatures < Find.SOURCES then
                creatures = creatures + 1
                Source(source.key, role, "drop")
            elseif kind == "object" and objects < Find.SOURCES then
                objects = objects + 1
                Source(source.key, rate > 0 and role or Find.TEXT.gives, "drop")
            end
        end
    end
    if want == "get" then
        local count = 0
        for _, quest in ipairs(rewarded[item] or NONE) do
            if count < Find.SOURCES and byKey["quest:" .. quest] then
                count = count + 1
                Source("quest:" .. quest, Find.TEXT.reward:format(byKey["quest:" .. quest].name), "reward")
            end
        end
    end
    return list
end

-- The trainers of a spell or a trade: the NPCs whose title is its class's trainer or names its trade, of your side.
local function Trainers(entry)
    local list = {}
    for _, each in ipairs(index) do
        if each.kind == "npc" and not each.foe and each.lowRole then
            for _, word in ipairs(entry.trainers) do
                if find(each.lowRole, word, 1, true) or (each.lowMore and find(each.lowMore, word, 1, true)
                        and find(each.lowMore, "trainer", 1, true)) then
                    list[#list + 1] = { entry = each, role = Find.TEXT.teaches:format(entry.name) }
                    break
                end
            end
        end
    end
    return list
end

-- The finds of a list of entries and ranks, nearest first where asked, else by rank (the nearer of two alike first);
-- each { entry, rank, role (in place of its own), yards }.
local function Sorted(rows, near)
    for _, row in ipairs(rows) do row.yards = Find.Measure(row.entry) end
    table.sort(rows, function(a, b)
        if near then
            if (a.yards ~= nil) ~= (b.yards ~= nil) then return a.yards ~= nil end
            if a.yards and b.yards and a.yards ~= b.yards then return a.yards < b.yards end
        end
        if a.rank ~= b.rank then return a.rank > b.rank end
        if a.yards and b.yards and a.yards ~= b.yards then return a.yards < b.yards end
        if (a.yards ~= nil) ~= (b.yards ~= nil) then return a.yards ~= nil end
        if a.entry.name ~= b.entry.name then return (a.entry.name or "") < (b.entry.name or "") end
        return a.entry.key < b.entry.key
    end)
    return rows
end

-- The best so many of the rows by rank, the rest let go before they are measured (a word of one letter finds
-- thousands; measuring is a look at each one's points).
local function Best(rows, most)
    if #rows <= most then return rows end
    table.sort(rows, function(a, b)
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.entry.key < b.entry.key
    end)
    for position = #rows, most + 1, -1 do rows[position] = nil end
    return rows
end

-- Groups for the list: by kind, each in its order, the groups by their best find; nearness asked: one list. At most
-- Find.SHOWN finds, Find.GROUP of a group where several share the list.
local GROUP_ORDER = { marker = 0, people = 1, npc = 2, place = 3, item = 4, quest = 5, zone = 6, spell = 7 }
local function Grouped(rows, near, title)
    local answer = { count = #rows }
    if near or title then
        local group = { title = title or Find.TEXT.groups.near, rows = {} }
        for position = 1, math.min(#rows, Find.SHOWN) do group.rows[position] = rows[position] end
        group.more = #rows - #group.rows
        answer[1] = group
        return answer
    end
    local groups = {}
    for _, row in ipairs(rows) do
        local key = row.entry.group or "place"
        local group = groups[key]
        if not group then
            group = { key = key, title = Find.TEXT.groups[key], rows = {}, best = row.rank, all = 0 }
            groups[key] = group
            answer[#answer + 1] = group
        end
        group.all = group.all + 1
        group.rows[#group.rows + 1] = row
    end
    table.sort(answer, function(a, b)
        if a.best ~= b.best then return a.best > b.best end
        return (GROUP_ORDER[a.key] or 9) < (GROUP_ORDER[b.key] or 9)
    end)
    local room = Find.SHOWN
    local each = #answer > 1 and Find.GROUP or Find.SHOWN
    for _, group in ipairs(answer) do
        local keep = math.max(0, math.min(#group.rows, each, room))
        for position = #group.rows, keep + 1, -1 do group.rows[position] = nil end
        group.more = group.all - keep
        room = room - keep
    end
    return answer
end

-- A place to farm as a find of its own (a row of the list): named by its zone and where in it, what it is in a line,
-- its middle its one point (or its dungeon's map); the thing farmed and all its places kept with it.
local function FarmFind(target, place, index, places)
    return Words({ kind = "farm", group = "farm", key = "farm:" .. target.key .. ":" .. index, place = place,
                   places = places, target = target, icon = target.kind == "item" and target.icon or nil,
                   low = place.low, high = place.high,
                   spots = place.map and place.x and { { map = place.map, x = place.x, y = place.y } } or {} },
        place.name, ns.Farms.About(place), nil)
end

-- What to farm of the rows found: the best item, else the best herb, ore or chest, else the best creature; the first
-- of them that has places to farm, with its places.
local FARMED = {
    function(entry) return entry.kind == "item" end,
    function(entry) return entry.kind == "object" and (entry.what == "herb" or entry.what == "ore" or entry.what == "chest") end,
    function(entry) return entry.kind == "npc" end,
}
local function Farmed(rows, zone)
    for _, wanted in ipairs(FARMED) do
        local best
        for _, row in ipairs(rows) do
            if wanted(row.entry) and (not best or row.rank > best.rank) then best = row end
        end
        local places = best and ns.Farms.Of(best.entry, zone)
        if places and #places > 0 then return best, places end
    end
    return nil
end

-- A group of the best places to farm a thing, its rows measured.
local function FarmGroup(target, places, title, most, zone)
    local group = { title = title, rows = {}, all = 0 }
    for index, place in ipairs(places) do
        local entry = FarmFind(target, place, index, places)
        if InZone(entry, zone) then
            group.all = group.all + 1
            if #group.rows < most then
                group.rows[#group.rows + 1] = { entry = entry, rank = place.heat or 0, yards = Find.Measure(entry) }
            end
        end
    end
    group.more = group.all - #group.rows
    return group
end

-- Searched now (the index read): the answer for the list.
local function Search(asked)
    local picked = Kept().picked
    if asked.spot then
        local map = asked.spot.map or (ns.Canvas.view and ns.Canvas.view.zone) or Core.Ask(C_Map.GetBestMapForUnit, "player")
        local name = map and MapName(map)
        local entry = Words({ kind = "spot", group = "place", key = "spot", atlas = "Waypoint-MapPin-Untracked",
            spots = map and { { map = map, x = asked.spot.x, y = asked.spot.y } } or {} },
            Find.TEXT.spot:format(asked.spot.x * 100, asked.spot.y * 100), name, nil)
        return Grouped({ { entry = entry, rank = 1 } }, false, Find.TEXT.groups.place)
    end
    local rows = {}
    local live = Everything()
    -- Where to go at your level: zones and dungeons as high as asked, the best fit first, then the nearest.
    if asked.want == "level" then
        local middle = (asked.low + asked.high) / 2
        local function Consider(entry)
            if OfKind(entry, asked.kind) and AsHigh(entry, asked.low, asked.high) then
                local from, to = entry.low, entry.high
                if entry.kind == "zone" then from, to = ns.Label.Range(entry.map) end
                if from then
                    rows[#rows + 1] = { entry = entry, rank = 1000 - math.abs((from + (to or from)) / 2 - middle) * 10,
                                        role = Find.TEXT.levels:format(from, to or from) }
                end
            end
        end
        for _, entry in ipairs(live) do Consider(entry) end
        for _, entry in ipairs(index) do Consider(entry) end
        return Grouped(Sorted(rows, false), false, Find.TEXT.groups.zone)
    end
    local function Look(entry)
        if not OfKind(entry, asked.kind) then return end
        if asked.unknown and not entry.unknown then return end
        local best
        for _, set in ipairs(asked.sets) do
            -- (no words: every find of the kind asked for, "nearest mailbox", "dungeons"; nothing without a kind)
            local rank = #set == 0 and (asked.kind and 1 or nil) or #set > 0 and Match(entry, set, asked.without)
            if rank and (not best or rank > best) then best = rank end
        end
        if not best then return end
        -- An NPC hostile to you only where a word named it (Hogger), never for what it is (a vendor of the other side).
        if entry.foe and not entry.named then return end
        -- (in a zone: what stands there; an item or a spell asked about stands nowhere, its sources do)
        local about = asked.want and (entry.kind == "item" or entry.kind == "spell")
        if not AsHigh(entry, asked.low, asked.high) or not (about or InZone(entry, asked.zone)) then return end
        local picks = tonumber(picked[entry.key])
        if picks then best = best + Find.PICK * picks end
        rows[#rows + 1] = { entry = entry, rank = best }
    end
    for _, entry in ipairs(live) do Look(entry) end
    for _, entry in ipairs(index) do Look(entry) end
    -- Where to farm it: the places thickest with what gives it, the best first (nearness asked: the nearest); a thing
    -- nothing gives to farm (only sold, a reward): where to get it.
    if asked.want == "farm" then
        local best, places = Farmed(rows, asked.zone)
        if best then
            local group = FarmGroup(best.entry, places, Find.TEXT.groups.farm:format(best.entry.name), Find.SHOWN, asked.zone)
            if asked.near then
                table.sort(group.rows, function(a, b)
                    if (a.yards ~= nil) ~= (b.yards ~= nil) then return a.yards ~= nil end
                    if a.yards and b.yards and a.yards ~= b.yards then return a.yards < b.yards end
                    return a.rank > b.rank
                end)
            end
            local answer = { group, count = #group.rows, about = best, farms = places }
            return answer
        end
        asked.want = "get"
    end
    -- An item's sources, or a spell's trainers: the best of the things named, with what it comes from under it.
    if asked.want and asked.want ~= "level" then
        local best
        for _, row in ipairs(rows) do
            local kind = row.entry.kind
            if (asked.want == "learn" and kind == "spell") or (asked.want ~= "learn" and kind == "item") then
                if not best or row.rank > best.rank then best = row end
            end
        end
        if best then
            local want = asked.want
            local sources = want == "learn" and Trainers(best.entry) or Sources(best.entry.id, want)
            if #sources == 0 and (want == "sold" or want == "drop") then
                -- nobody sells it, nothing drops it: every way there is (Linen Cloth is sold by nobody)
                want = "get"
                sources = Sources(best.entry.id, want)
            end
            local found = { }
            for _, source in ipairs(sources) do
                if InZone(source.entry, asked.zone) then
                    found[#found + 1] = { entry = source.entry, rank = 1, role = source.role }
                end
            end
            local title = Find.TEXT.groups[want] or Find.TEXT.groups.get
            if want ~= asked.want then title = Find.TEXT.groups.instead .. title end
            local answer = Grouped(Sorted(found, true), false, title:format(best.entry.name))
            answer.about = best -- the item or spell itself, first in the list
            -- what drops or gives it to gather: its best places to farm first
            if best.entry.kind == "item" and want ~= "sold" then
                local places = ns.Farms.Of(best.entry, asked.zone)
                if #places > 0 then
                    local group = FarmGroup(best.entry, places, Find.TEXT.groups.farmFirst, Find.FARMS, asked.zone)
                    if #group.rows > 0 then
                        table.insert(answer, 1, group)
                        answer.count = answer.count + #group.rows
                        answer.farms = places
                    end
                end
            end
            return answer
        end
    end
    return Grouped(Sorted(Best(rows, asked.near and Find.NEAR or Find.RANKED), asked.near), asked.near)
end

-- Nothing found: the finds whose names hold the words' letters in their order, the closest first (Core's Fuzzy, letters
-- spread out), Find.CLOSE at most; a part per frame.
local closeJob
local function Close(asked, done)
    if closeJob then closeJob:Stop() end
    local set = asked.sets and asked.sets[1]
    if not set or #set == 0 or not (Core.Steps and Core.Steps.Run) then return done(nil) end
    -- (an error in the job: the list says the search failed; ns.FindBox shows it)
    local function Ended(problem)
        if problem == nil then return end
        closeJob = nil
        Core.Safe("map search", done, { failed = true, count = 0 })
    end
    closeJob = Core.Steps.Run({ name = "map search: close", label = "Navigation: map search", done = Ended }, function()
        local rows = {}
        for _, entry in ipairs(index) do
            local total = 0
            for _, word in ipairs(set) do
                local rank = Rank(word, entry.name, entry.lowName)
                if not rank then total = nil break end
                total = total + rank
            end
            if total then rows[#rows + 1] = { entry = entry, rank = total } end
            Core.Steps.Check()
        end
        table.sort(rows, function(a, b) return a.rank > b.rank end)
        for position = #rows, Find.CLOSE + 1, -1 do rows[position] = nil end
        closeJob = nil
        Core.Safe("map search", done, #rows > 0 and Grouped(Sorted(rows, false), false, Find.TEXT.groups.close) or nil)
    end)
end

-- A word mistyped: the words of every find's name, what it is and its further words (lowered, by their first letter),
-- made once at the first need; a typed word none of them holds is put right by the nearest of them that begins with
-- the same letter and is within Find.SLIPS(word) edits (a letter left out, one too many, another, two swapped).
local vocabulary -- [first letter] = { word, ... }; nil until needed
Find.SLIPS = function(word) return #word <= 5 and 1 or #word <= 9 and 2 or 3 end

local function Vocabulary()
    if vocabulary then return vocabulary end
    vocabulary = {}
    local seen = {}
    local function Take(text)
        if not text then return end
        for word in text:gmatch("[%a']+") do
            if #word >= 3 and not seen[word] then
                seen[word] = true
                local first = word:sub(1, 1)
                local list = vocabulary[first] or {}
                vocabulary[first] = list
                list[#list + 1] = word
            end
        end
    end
    for _, entry in ipairs(index) do
        Take(entry.lowName)
        Take(entry.lowRole)
        Take(entry.lowMore)
    end
    for _, entry in ipairs(Zones()) do Take(entry.lowName) end
    return vocabulary
end

-- How many edits two words are apart (letters left out, added, changed, two side by side swapped), or nil past most.
local function Apart(a, b, most)
    local n, m = #a, #b
    if math.abs(n - m) > most then return nil end
    local before, last, row = {}, {}, {}
    for j = 0, m do last[j] = j end
    for i = 1, n do
        row[0] = i
        local least = i
        local ai = a:byte(i)
        for j = 1, m do
            local bj = b:byte(j)
            local cost = ai == bj and 0 or 1
            local best = math.min(last[j] + 1, row[j - 1] + 1, last[j - 1] + cost)
            if i > 1 and j > 1 and ai == b:byte(j - 1) and a:byte(i - 1) == bj then
                best = math.min(best, before[j - 2] + 1)
            end
            row[j] = best
            if best < least then least = best end
        end
        if least > most then return nil end
        before, last, row = last, row, before
    end
    return last[m] <= most and last[m] or nil
end

-- The words typed put right where one is in no find: true where any was (asked.spelled: the words now).
local function Respell(asked)
    local words = Vocabulary()
    local changed = false
    for _, set in ipairs(asked.sets or NONE) do
        for position, word in ipairs(set) do
            local first = word:sub(1, 1)
            local list = words[first]
            local known = false
            for _, each in ipairs(list or NONE) do
                if find(each, word, 1, true) then known = true break end
            end
            if not known and #word >= 4 and list then
                local most, best, bestApart = Find.SLIPS(word), nil, nil
                for _, each in ipairs(list) do
                    local apart = Apart(word, each, bestApart and bestApart - 1 or most)
                    if apart and (not bestApart or apart < bestApart) then best, bestApart = each, apart end
                end
                if best then
                    set[position] = best
                    changed = true
                end
            end
        end
    end
    if changed then
        local said = {}
        for _, word in ipairs(asked.sets[1] or NONE) do said[#said + 1] = word end
        asked.spelled = table.concat(said, " ")
    end
    return changed
end

-- What was typed, searched: done(answer) with the groups ({ title, rows = { { entry, rank, role, yards } }, more }),
-- answer.about (the item or spell whose sources are listed), answer.asked (what was read); answer.reading while
-- Core's sets are still being read (searched again once they are, done told again). nil: nothing typed.
function Find.Ask(text, done)
    local asked = Find.Read(text)
    if not asked then return done(nil) end
    Read()
    local wanted = asked.want -- (Search may turn a farm with nothing to farm into where to get it)
    local answer = Search(asked)
    answer.asked = asked
    if reading then
        answer.reading = true
        waiting = { text, done }
        return done(answer)
    end
    -- Nothing: a mistyped word put right, searched again ("peaceblossom": Peacebloom)
    if answer.count == 0 and not asked.spot and Respell(asked) then
        asked.want = wanted
        local again = Search(asked)
        if again.count > 0 then
            again.asked = asked
            return done(again)
        end
    end
    if answer.count == 0 and not asked.spot and not asked.want then
        return Close(asked, function(close)
            if close then close.asked, close.close = asked, true end
            done(close or answer)
        end)
    end
    return done(answer)
end

-------------------------------------------------------------------------------
--  On the map
-------------------------------------------------------------------------------
local shown        -- the find whose points the map shows
local pins = {}    -- their pins (Pins.For takes them in)
local farmed       -- the places to farm glowing on the map (Farms.Draw), and the thing farmed: { places, target }

-- A find's look on the map: its own icon (an NPC's as its pin's would be, Pins.LookOf), else the map pin's; a place to
-- farm the thing's (an item's picture: a number).
local function Look(entry)
    if entry.atlas then return entry.atlas end
    local kind = entry.kind
    if kind == "farm" then return entry.icon or Look(entry.target) end
    if kind == "marker" then return entry.icon or "Waypoint-MapPin-Untracked" end
    if kind == "npc" then return ns.Pins.LookOf(entry.services, entry.title, entry.goods, entry.rank, entry.foe) end
    if kind == "object" then return ns.Pins.ObjectLook(entry.what) end
    if kind == "place" then return ns.Pins.PlaceLook(entry.what) end
    if kind == "quest" then return "questnormal" end
    if kind == "log" then return "questturnin" end
    if kind == "member" or kind == "party" or kind == "friend" then return "PlayerPartyBlip" end
    return "Waypoint-MapPin-Untracked"
end

Find.Look = Look

-- What a find stands for on the map: itself, or an item's sources and a spell's trainers (each with its words). An
-- item with places to farm: those glow, so of its sources only the vendors and the quests stand as pins.
local function Standing(entry, role, farming)
    if entry.kind == "item" then
        local list = Sources(entry.id, "get")
        if farming then
            local kept = {}
            for _, source in ipairs(list) do
                if source.way ~= "drop" then kept[#kept + 1] = source end
            end
            return kept
        end
        return list
    end
    if entry.kind == "spell" then return Trainers(entry) end
    return { { entry = entry, role = role } }
end

-- A place to farm's pin, at its middle: the thing's picture in a ring (an item's) or its icon, its tooltip the place.
local function Marker(place, target, index)
    local look = target.kind == "item" and target.icon or Look(target)
    local home = place.plane
    local pin = { kind = "find", key = "farm:" .. target.key .. ":" .. index, name = target.name, role = place.name,
                  home = home, u = place.u, v = place.v, map = place.map, x = place.x, y = place.y, sought = true,
                  size = Find.MARKER, lines = { ns.Farms.About(place) } }
    if type(look) == "number" then pin.texture, pin.look = look, "found" else pin.atlas = look end
    return pin
end

-- The points of what a find stands for, as pins: the nearest Find.PLACES of them all, at least Find.EACH of each
-- (an item's every source in sight); a member's at the middle of its zone, said so; with places to farm (farming:
-- its places, the thing farmed) a pin at each place's middle too. Gives the nearest point.
Find.EACH = 3
local function Made(entry, role, farming)
    wipe(pins)
    local list = Standing(entry, role, farming)
    local each = math.max(Find.EACH, math.floor(Find.PLACES / math.max(#list, 1)))
    local nearest, best
    for _, wanted in ipairs(list) do
        local thing = wanted.entry
        local measured = Find.Spots(thing)
        local look = Look(thing)
        for position = 1, math.min(#measured, each) do
            local point, yards = measured[position].point, measured[position].yards
            local home = Coords.PlaneOf(point.map)
            local u, v
            if home then u, v = Coords.MapToPlane(point.map, point.x, point.y, home) end
            if u and #pins < Find.PLACES * 2 then
                local pin = { kind = "find", key = "find:" .. thing.key .. ":" .. position, thing = thing.thing,
                              name = thing.name, role = wanted.role or thing.role or thing.name, home = home, u = u, v = v,
                              map = point.map, x = point.x, y = point.y, sought = true,
                              lines = point.zone and { Find.TEXT.inZone } or nil }
                if type(look) == "number" then pin.texture = look else pin.atlas = look end
                pins[#pins + 1] = pin
                if not nearest or (yards and (not best or yards < best)) then nearest, best = point, yards end
            end
        end
    end
    for index, place in ipairs(farming and farming.places or NONE) do
        if place.plane then pins[#pins + 1] = Marker(place, farming.target, index) end
    end
    return nearest
end

local function Redraw()
    if ns.Canvas and ns.Canvas.Refresh then ns.Canvas.Refresh() end
end

-- Places to farm a thing glowing on the full map, a pin at each one's middle (the answer to "where to farm", an
-- item's list); the map not moved. nil: none (their glow goes; the pins of the find shown stay).
function Find.Farms(places, target)
    if not places or not target or #places == 0 then
        if farmed then
            farmed = nil
            ns.Farms.Draw(nil)
        end
        return
    end
    farmed = { places = places, target = target }
    shown = target
    wipe(pins)
    for index, place in ipairs(places) do
        if place.plane then pins[#pins + 1] = Marker(place, target, index) end
    end
    ns.Farms.Draw(places)
end

-- A find on the map: its points (or its sources' and trainers') as pins, the map at the nearest; a zone, a continent
-- or a dungeon's map shown whole; a place to farm: its glow with the others of the thing farmed, the map there (a
-- dungeon's: its map). False where it stands nowhere the map can show.
function Find.Show(entry, role)
    if not entry then return false end
    if entry.kind == "zone" then
        Find.Clear()
        return ns.Canvas.Show(entry.map)
    end
    if entry.kind == "dungeon" then
        Find.Clear()
        return ns.Dungeons.Show(entry.map)
    end
    if entry.kind == "farm" then
        local place = entry.place
        if place.inside then return ns.Dungeons.Show(place.inside) end
        if not (farmed and farmed.places == entry.places) then Find.Farms(entry.places, entry.target) end
        Redraw()
        return place.map ~= nil and ns.Canvas.LookAt(place.map, place.x, place.y)
    end
    if entry.kind == "log" and ns.QuestLog.Focus then ns.QuestLog.Focus(entry.quest) end
    if entry.kind == "marker" and ns.Markers then
        ns.Markers.Open(entry.marker) -- (its card too)
        -- one on a dungeon's floor: that floor's map
        if ns.Dungeons.Named(entry.marker.map) then return ns.Dungeons.Show(entry.marker.map) end
    end
    -- an item farmed: its places glow, the map at the best of them
    local places = entry.kind == "item" and ns.Farms.Of(entry) or NONE
    local farming = #places > 0 and { places = places, target = entry } or nil
    if farming then
        farmed = farming
        ns.Farms.Draw(places)
    elseif farmed then
        farmed = nil
        ns.Farms.Draw(nil)
    end
    shown = entry
    local nearest = Made(entry, role, farming)
    Redraw()
    local first = farming and places[1]
    if first and first.map then return ns.Canvas.LookAt(first.map, first.x, first.y) end
    if not nearest then return false end
    if nearest.zone then ns.Canvas.Show(nearest.map) end
    ns.Canvas.LookAt(nearest.map, nearest.x, nearest.y)
    return true
end

-- A find's points on the map while the mouse is on its row in the list (FindBox.lua): the map not moved. A place to
-- farm: its thing's places, as they glow already.
function Find.Preview(entry, role)
    if not entry or entry.kind == "zone" or entry.kind == "dungeon" then return end
    if entry.kind == "farm" then
        if not (farmed and farmed.places == entry.places) then Find.Farms(entry.places, entry.target) end
        return
    end
    Made(entry, role, farmed) -- (the places glowing keep their pins)
    Redraw()
end

-- The point the map pin goes to for a find: its nearest, or its nearest source's or trainer's; a place to farm's
-- middle.
function Find.Nearest(entry)
    if entry.kind == "farm" then return entry.spots[1] end
    local nearest, best
    for _, wanted in ipairs(Standing(entry)) do
        local measured = Find.Spots(wanted.entry)
        local first = measured[1]
        if first and (not nearest or (first.yards and (not best or first.yards < best))) then
            nearest, best = first.point, first.yards
        end
    end
    return nearest
end

-- The game's map pin at a find's nearest point (the golden line leads there); false where the game takes none there
-- (no point, only its zone known, an instance).
function Find.Pin(entry)
    local point = entry and Find.Nearest(entry)
    if not point or point.zone then return false end
    ns.PinView.Drop({ map = point.map, x = point.x, y = point.y })
    return true
end

function Find.Clear()
    if farmed then
        farmed = nil
        ns.Farms.Draw(nil)
    end
    if not shown and #pins == 0 then return end
    shown = nil
    wipe(pins)
    Redraw()
end

function Find.Pins()
    return pins
end

function Find.Shown()
    return shown
end

-- Core's data changed: read anew at the next search (what is shown stays until then).
function Find.Forget()
    if reading then return end
    wipe(index)
    wipe(byKey)
    wipe(sourced)
    wipe(rewarded)
    wipe(taught)
    zones, reading, vocabulary = nil, nil, nil
    ns.Farms.Forget()
end
