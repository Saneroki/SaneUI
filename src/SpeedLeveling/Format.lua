local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Format
--  Reads a leveling guide written as text into a guide of our own shape, for
--  one character: what is not for its side, race, class or level is left out as
--  it is read, and a step for a game mode Sane UI's games do not play (hardcore,
--  a season) is dropped. The text is in the format the leveling guide Sane UI
--  knows uses, so guides written for it, and the guides you bought (Unlock.lua),
--  can be read (Saneroki, 2026-10-25). That format's own words for its commands,
--  step marks, colours and game tags are Core's to know (Core.Neighbours.Format):
--  here every one has a word of ours, and the engine (Run.lua) is ours. Knows no
--  frames and asks the game nothing but its own name.
--
--  A guide's text: its head (lines of "#mark value", and a line "<< who" that
--  keeps the whole guide for some characters only, and lines "#forever" that
--  name the games it is for) before its first step; then steps, each beginning
--  with a line "step" and holding lines of these kinds:
--      #mark value             about the step (its name, with which it ends, ...)
--      .command a,b >> words   a thing to do, to know or to check, and its words
--      +words                  a thing to do that only the player can tick off
--      >>words, *words         words only
--  "<< who" at a line's end keeps the line for some characters only: OR between
--  slashes, AND between spaces, "!" before a name for all but it; a name is a
--  side, a race, a class, a level (reached), or a game.
--
--      local head = Format.Head(text)                  -- the head alone: name, group, games, ... (the list needs no read)
--      local plays = Format.Plays(who, head.games)     -- whether its games include the one played
--      local guide, problems = Format.Read(text, who)  -- one guide's, for that character; nil while Core knows no format
--      who     { side = "Horde", race = "Orc", class = "WARRIOR", level = 7, game = "forever" }
--  A step marked for a dungeon stands only in a guide of a dungeon group
--  (Format.DungeonStep), one marked for doing without it only in the others.
--  Format.NoDungeonQuests(guide, inDungeon) then takes out of a normal guide
--  the quests the caller's test names, also those its text does not mark.
--      guide   { name, title, group, subgroup, after = { { name, only } }, defaultFor, only, games = { game },
--                part, divider, mine, steps = { step }, labels = { [label] = index } }
--                -- mine: it is for this character; part: reached only as another's next; divider: no guide
--      step    { lines = { line }, label, together ("next" or a label), stays, needs (a label), aside, loop, hidden,
--                map, arrowText, unless = { test }, friends, foes, items, spells, uses = { { item, words } } }
--      line    { what = a word of Format.DOING or Format.WORDS, words, ... what the command gave }
--      test    { what = a word of Format.TESTS, ... }: the step is passed by while it holds
--  problems: "line N: ..." for each command line that could not be read; that line is left out.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Format = {}
ns.Format = Format

-- What a line can be: done when the game says so (DOING), or only words or a place (WORDS).
Format.DOING = { take = true, handin = true, goal = true, carry = true, destroy = true, level = true, learn = true,
                 skill = true, hearth = true, bind = true, flightpath = true, fly = true, zone = true, area = true,
                 revive = true, cast = true, shop = true, trainer = true, stable = true, tame = true, equip = true,
                 standing = true, bankIn = true, bankOut = true, aura = true, arrive = true, manual = true }
Format.WORDS = { say = true, note = true, brief = true, place = true, pin = true, line = true, link = true, timer = true }
-- What passes a step by while it holds: the step is not for now.
Format.TESTS = { onQuest = true, notOnQuest = true, questReady = true, questOpen = true, handedIn = true, open = true,
                 skipOnQuest = true, money = true, count = true, inZone = true, inArea = true, reached = true,
                 grouped = true, solo = true, stat = true, maxLevel = true, ready = true, atHome = true, hasAura = true,
                 hasSkill = true, hasSpell = true, worn = true }
Format.FAR = 5 -- yards: how near a place counts as reached when its line names no reach

-- Names a guide may use for a race, as the game's token has it.
local RACES = { undead = "scourge", skyborne = "skyborne" }

local function Trim(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end

-- A value with a comment after it ("--", spaces or not before it): the comment cut off.
local function Uncommented(text) return Trim((text:gsub("%s*%-%-.*$", ""))) end

local function Numbers(values)
    local found = {}
    for _, value in ipairs(values) do
        local number = tonumber(value)
        if number then found[#found + 1] = number end
    end
    return found
end

-------------------------------------------------------------------------------
--  Who a line is for
-------------------------------------------------------------------------------
-- Whether one AND-group of names (spaces between) holds: every name must, a name that is a number by the level, the
-- rest by the side, race, class or game; "!" before a name turns it round.
local function Group(who, group)
    local level = tonumber(who.level) or 1
    for raw in group:gmatch("%S+") do
        local negated, name = raw:match("^(!?)(.+)$")
        name = (name or ""):gsub("[%(%)]", "")
        local holds
        local number = tonumber(name)
        if number then
            holds = level >= number
        else
            local low = name:lower()
            low = RACES[low] or low
            holds = low == (who.side or ""):lower() or low == (who.race or ""):lower()
                or low == (who.class or ""):lower() or low == (who.game or ""):lower()
            -- A neutral character counts as both sides.
            if not holds and (who.side or ""):lower() == "neutral" and (low == "alliance" or low == "horde") then
                holds = true
            end
        end
        if (negated == "!") == holds then return false end
    end
    return true
end

-- Whether the words after "<<" hold for the character: any OR-group (slashes between) holds.
function Format.For(who, words)
    for group in words:gmatch("[^/]+") do
        if Trim(group) ~= "" and Group(who, group) then return true end
    end
    return false
end

-- Whether a guide's games include the one played ("classic" is Forever's fallback); a guide naming none plays anywhere.
function Format.Plays(who, games)
    if type(games) ~= "table" or not games[1] then return true end
    local game = (who.game or ""):lower()
    for _, named in ipairs(games) do
        if named == game or (game == "forever" and named == "classic") then return true end
    end
    return false
end

-------------------------------------------------------------------------------
--  The commands, by our word for each
-------------------------------------------------------------------------------
-- A coordinate: the number its value starts with, so a slip of the pen after it ("-623.92.00", "39.43s") costs no place.
local function Coordinate(value)
    return tonumber(value) or tonumber((tostring(value or ""):match("^%-?%d+%.?%d*")))
end

-- A place: "Zone,x,y", "uiMapID,x,y" (shares of 100 of that map), or "uiMapID/continent,a,b" (the world's yards on
-- that continent, west first then north, as the format writes them), then how near counts as reached; a further value
-- makes it a point on the way, never a thing to do. Without a map the last one named stands.
local function Place(values, last)
    local map = values[1] and values[1] ~= "" and values[1] or last
    local x, y = Coordinate(values[2]), Coordinate(values[3])
    if not (map and x and y) then return nil end
    local place = { x = x, y = y, near = tonumber(values[4]), way = values[5] ~= nil }
    local id, continent = tostring(map):match("^(%d+)/(%d+)$")
    if id then
        place.map, place.continent = tonumber(id), tonumber(continent)
    else
        place.map = tonumber(map) or map
    end
    return place, map
end

-- A level as the format writes it: "10" (reached), "10-1475" (so many points short of it), "10+300" (so many into
-- it), "10.5" (that share into it); "<" before it turns the question round.
local function Level(text)
    local below, level, rest = (text or ""):gsub("%s", ""):match("^([<>]?)(%d+)(.*)$")
    if not level then return nil end
    local line = { level = tonumber(level), below = below == "<" }
    local sign, amount = rest:match("^([%+%-])(%d+)$")
    if sign then
        line.points = tonumber(amount) * (sign == "-" and -1 or 1)
    elseif rest:match("^%.%d+$") then
        line.share = tonumber("0" .. rest)
    end
    return line
end

-- An amount compared: "<1.5", ">0.01", "=3", "5" (at least so many); the number and the comparison.
local function Compared(text)
    local sign, number = (text or ""):gsub("%s", ""):match("^([<>]?=?)([%d%.]+)$")
    return tonumber(number), sign
end

local function Quest(v) return tonumber(v[1]) end
-- A test over a list of quest IDs.
local function Quests(what)
    return function(v)
        local quests = Numbers(v)
        return quests[1] and { test = { what = what, quests = quests } } or nil
    end
end
-- A thing to do whose words name a place (hearth, bind, flightpath, fly): the place's name, where it gives one.
local function Named(what)
    return function(v) return { what = what, to = v[1] and v[1] ~= "" and v[1] or nil } end
end

-- Each command makes of its values (strings, split at commas) and its words (said) a line (what), a test of the step
-- (test), a thing to do or know whose kind depends on its words, or names and items for the key. nil for values it
-- cannot read. A place also gives its map.
local COMMANDS = {
    take = function(v) return Quest(v) and { what = "take", quest = Quest(v) } or nil end,
    handin = function(v)
        local quest = Quest(v)
        if not quest then return nil end
        -- A reward to choose (its number), where the step names one; a quest of its own, so the key knows to hand in.
        return { what = "handin", quest = math.abs(quest), reward = tonumber(v[2]) }
    end,
    goal = function(v) return Quest(v) and { what = "goal", quest = Quest(v), goal = tonumber(v[2]) or 1 } or nil end,
    carry = function(v)
        local item = tonumber((tostring(v[1] or ""):match("%d+")))
        return item and { what = "carry", item = item, count = tonumber(v[2]) or 1, quest = tonumber(v[3]) } or nil
    end,
    destroy = function(v) local item = tonumber(v[1]) return item and { what = "destroy", item = item } or nil end,
    level = function(v)
        local line = Level(v[1])
        if not line then return nil end
        -- With a second value it does not ask to level: it passes the step by once the level is there.
        if v[2] then
            line.what = "reached"
            return { test = line }
        end
        line.what = "level"
        return line
    end,
    learn = function(v)
        local spell = tonumber(v[1])
        if not spell then return nil end
        -- With a second value it is a test (is the spell trained): the step is passed by while it is.
        if v[2] then return { test = { what = "hasSpell", spell = spell } } end
        return { what = "learn", spell = spell }
    end,
    skill = function(v, said)
        local name = v[1]
        local level, sign = Compared(v[2])
        if not (name and name ~= "" and level) then return nil end
        -- With words it is a thing to do; without, a test the step is passed by while met.
        if said then return { what = "skill", skill = name, level = level, sign = sign } end
        return { test = { what = "hasSkill", skill = name, level = level, sign = sign } }
    end,
    hearth = Named("hearth"),
    bind = Named("bind"),
    atHome = function(v) return { test = { what = "atHome", area = tonumber(v[1]) } } end,
    flightpath = Named("flightpath"),
    fly = Named("fly"),
    zone = function(v) return v[1] and v[1] ~= "" and { what = "zone", to = tonumber(v[1]) or v[1] } or nil end,
    area = function(v) local area = tonumber(v[1]) return area and { what = "area", area = area } or nil end,
    revive = function() return { what = "revive", friends = { "Spirit Healer" } } end,
    cast = function(v)
        -- A word before the spell names who casts it ("vehicle,52362"): the spell is the first number.
        local spell = tonumber(v[1]) or tonumber(v[2])
        return spell and { what = "cast", spell = spell } or nil
    end,
    shop = function() return { what = "shop" } end,
    trainer = function() return { what = "trainer" } end,
    stable = function() return { what = "stable" } end,
    tame = function() return { what = "tame" } end,
    equip = function(v, said)
        local slot = tonumber(v[1])
        if not slot then return nil end
        local item = tonumber(v[2])
        if said then return { what = "equip", slot = math.abs(slot), item = item } end
        return { test = { what = "worn", slot = math.abs(slot), item = item, below = slot < 0 } }
    end,
    friend = function(v) return { friends = v } end,
    foe = function(v) return { foes = v } end,
    use = function(v)
        local item = tonumber((tostring(v[1] or ""):match("%d+")))
        -- Kept with the line's words too: they say what the item is used on (a corpse, a creature by its name).
        return item and { items = { item }, uses = { { item = item } } } or nil
    end,
    bankIn = function(v, said) return said and { what = "manual" } or nil end,
    bankOut = function(v, said) return said and { what = "manual" } or nil end,
    note = function() return nil end, -- a macro or the like: only its words, kept by Command below
    link = function(v, said) return said and { what = "link", url = v[1] } or nil end,
    timer = function() return nil end,
    pin = function() return nil end,
    line = function() return nil end,
    map = function() return nil end,
    onQuest = Quests("onQuest"),
    notOnQuest = Quests("notOnQuest"),
    questReady = Quests("questReady"),
    questOpen = Quests("questOpen"),
    handedIn = Quests("handedIn"),
    open = Quests("open"),
    skipOnQuest = function(v) local quest = tonumber(v[1]) return quest and { test = { what = "notOnQuest", quests = { quest } } } or nil end,
    money = function(v)
        local gold, sign = Compared(v[1])
        if not gold or (sign ~= ">" and sign ~= "<") then return nil end
        return { test = { what = "money", copper = math.floor(gold * 10000 + 0.5), more = sign == ">" } }
    end,
    count = function(v)
        local total, sign = Compared(v[#v])
        local items = {}
        for index = 1, #v - 1 do
            local id = tonumber((tostring(v[index]):match("%d+")))
            if id then items[#items + 1] = id end
        end
        if not (total and items[1]) then return nil end
        return { test = { what = "count", items = items, total = total, sign = sign } }
    end,
    aura = function(v, said)
        local spell = tonumber(v[1])
        if not spell then return nil end
        if said then return { what = "aura", spell = math.abs(spell) } end
        return { test = { what = "hasAura", spell = math.abs(spell), below = spell < 0 } }
    end,
    stat = function(v)
        local slot, stat, amount = tonumber(v[1]), v[2], Compared(v[3])
        if not (slot and stat and amount) then return nil end
        local _, sign = Compared(v[3])
        return { test = { what = "stat", slot = slot, stat = stat, amount = amount, sign = sign } }
    end,
    inZone = function(v)
        local maps = {}
        for name in (v[1] or ""):gmatch("[^%+/]+") do maps[#maps + 1] = tonumber(name) or name end
        return maps[1] and { test = { what = "inZone", maps = maps, away = (tonumber(v[2]) or 0) % 2 == 1 } } or nil
    end,
    inArea = function(v)
        local areas = {}
        for name in (v[1] or ""):gmatch("[^%+/]+") do areas[#areas + 1] = tonumber(name) end
        return areas[1] and { test = { what = "inArea", areas = areas, away = (tonumber(v[2]) or 0) % 2 == 1 } } or nil
    end,
    ready = function(v)
        local kind, id = v[1], tonumber(v[2])
        local left, sign = Compared(v[3])
        if not (kind and id and left) then return nil end
        return { test = { what = "ready", kind = kind, id = id, left = left, under = sign == "<" } }
    end,
    grouped = function() return { test = { what = "grouped" } } end,
    solo = function() return { test = { what = "solo" } } end,
    maxLevel = function(v) local level = tonumber(v[1]) return level and { test = { what = "maxLevel", level = level } } or nil end,
    dungeon = function() return nil end,     -- whether the step is for this guide: Format.Read, by Format.DungeonStep
    manualOnly = function() return nil end,  -- turns the line before it into one to tick by hand (Command)
    place = function(v, last)
        local place, map = Place(v, last)
        if not place then return nil end
        -- With a reach and nothing after it, getting there is the thing to do.
        place.what = (place.near and place.near > 0 and not place.way) and "arrive" or "place"
        return place, map
    end,
    waypoint = function(v, last)
        local place, map = Place(v, last)
        if not place then return nil end
        place.what, place.way = "place", true
        return place, map
    end,
}

-------------------------------------------------------------------------------
--  Reading
-------------------------------------------------------------------------------
local words -- Core's words of the format: { commands, marks, modes, gameTags }, once asked

-- A command line's values: the comment cut off, split at commas, each trimmed.
local function Values(text)
    local values = {}
    text = Uncommented(text)
    if text == "" then return values end
    for value in (text .. ","):gmatch("(.-),") do values[#values + 1] = Trim(value) end
    return values
end

local function Append(step, field, values)
    step[field] = step[field] or {}
    for _, value in ipairs(values) do
        -- A leading "*" lowers a name's priority (the far herbs' own mark): dropped here, the name kept.
        value = type(value) == "string" and (value:gsub("^%*", "")) or value
        if value ~= "" then step[field][#step[field] + 1] = value end
    end
end

-- What a command line gives, into the step. made.what: a thing to do or words (a line). made.test: a test of the
-- step. made.friends/foes/items: names and items for the key. manualOnly after a thing to do makes it one to tick.
local function Command(step, made, said, manualOnly)
    if made.what then
        made.words = said
        if manualOnly then made.what = "manual" end
        step.lines[#step.lines + 1] = made
        return true
    end
    if made.test then
        step.unless = step.unless or {}
        step.unless[#step.unless + 1] = made.test
    end
    if made.friends then Append(step, "friends", made.friends) end
    if made.foes then Append(step, "foes", made.foes) end
    if made.items then Append(step, "items", made.items) end
    if made.uses then
        step.uses = step.uses or {}
        for _, use in ipairs(made.uses) do step.uses[#step.uses + 1] = { item = use.item, words = said } end
    end
    if said then step.lines[#step.lines + 1] = { what = "say", words = said } end
    return made.test ~= nil or made.friends ~= nil or made.foes ~= nil or made.items ~= nil or said ~= nil
end

-- A mark of the head, into the guide (its words already Core's).
local function Head(guide, mark, value)
    if mark == "name" then guide.name = value
    elseif mark == "title" then guide.title = value
    elseif mark == "group" then guide.group = value
    elseif mark == "subgroup" then guide.subgroup = value
    elseif mark == "version" then guide.version = tonumber(value)
    elseif mark == "after" then
        -- One guide to go on with, or several (";" between), each kept for some characters only ("<<").
        for part in value:gmatch("[^;]+") do
            local name, only = Trim(part):match("^(.-)%s*<<%s*(.-)$")
            guide.after[#guide.after + 1] = { name = Trim(name or part), only = only and Trim(only) or nil }
        end
    elseif mark == "defaultFor" then
        guide.defaultFor = value
    elseif mark == "part" then
        guide.part = true    -- a part of a longer way: reached as another guide's next, not chosen from the list
    elseif mark == "divider" then
        guide.divider = true -- a divider in a list of guides: no guide at all
    end
end

-- A mark of a step, into it.
local function Mark(guide, step, mark, value)
    if mark == "together" then step.together = value ~= "" and value or "next"
    elseif mark == "label" then
        step.label = value
        guide.labels[value] = #guide.steps
    elseif mark == "stays" then step.stays = true
    elseif mark == "needs" then step.needs = value
    elseif mark == "aside" then step.aside = true
    elseif mark == "loop" then step.loop = true
    elseif mark == "hidden" then step.hidden = true
    elseif mark == "arrowText" then step.arrowText = (value:gsub("\\n", "\n"))
    elseif mark == "map" then step.map = tonumber(value)
    end
end

-- The guides of a text: what is between each pair of long brackets, or the whole text.
function Format.Parts(text)
    local parts = {}
    if type(text) ~= "string" then return parts end
    for inside in text:gmatch("%[%[(.-)%]%]") do parts[#parts + 1] = inside end
    if #parts == 0 and text:find("%S") then parts[1] = text end
    return parts
end

-- A guide's head alone (before its first step): enough for the list and to choose, without reading its steps.
function Format.Head(text)
    words = words or Core.Neighbours.Format("guide")
    if not words or type(text) ~= "string" then return nil end
    local head = { games = {}, after = {}, defaultFor = nil }
    for raw in (text .. "\n"):gmatch("(.-)\r?\n") do
        local line = Trim(raw)
        if line ~= "" and not line:find("^%-%-") then
            -- A mark that lists guides keeps its own "<<" per alternative; every other line's "<<" is a line filter.
            local rawMark, rawValue = line:match("^#(%S+)%s*(.-)$")
            if rawMark and words.marks[rawMark] == "after" then
                Head(head, "after", Uncommented(rawValue))
            else
                local body, only = line:match("^(.-)%s*<<%s*(.-)$")
                body = body or line
                if body:lower() == "step" then break end
                if body == "" and only then
                    head.only = Trim(only)
                else
                    local mark, value = body:match("^#(%S+)%s*(.-)$")
                    value = value and Uncommented(value) or value
                    if mark and words.gameTags[mark:lower()] then
                        head.games[#head.games + 1] = words.gameTags[mark:lower()]
                    elseif mark and words.marks[mark] then
                        Head(head, words.marks[mark], value)
                    end
                end
            end
        end
    end
    head.name = head.name or ns.TEXT.unnamed
    return head
end

-- The quests a guide's text takes and hands in, by a quick look at its command lines (no step read, nobody's lines
-- left out): what a guide further on sees to. { take = { [quest] = true }, handin = { [quest] = true } }
function Format.Quests(text)
    words = words or Core.Neighbours.Format("guide")
    local found = { take = {}, handin = {} }
    if not words or type(text) ~= "string" then return found end
    for command, quest in ("\n" .. text):gmatch("\n%s*%.(%S+)%s+(%d+)") do
        local ours = words.commands[command]
        if found[ours] then found[ours][tonumber(quest)] = true end
    end
    return found
end

-- One guide's text, read for that character.
function Format.Read(text, who)
    words = words or Core.Neighbours.Format("guide")
    if not words then return nil, {} end
    local guide = { steps = {}, labels = {}, after = {}, games = {}, mine = true }
    local problems = {}
    local step, skipping, lastMap, manualOnly
    local number = 0
    for raw in (tostring(text) .. "\n"):gmatch("(.-)\r?\n") do
        number = number + 1
        local line = Trim(raw)
        local rawMark = line:match("^#(%S+)")
        if not step and rawMark and words.marks[rawMark] == "after" then
            -- A guides-to-follow mark: its own "<<" per alternative, kept whole.
            Head(guide, "after", Uncommented((line:match("^#%S+%s*(.-)$"))))
        elseif line ~= "" and not line:find("^%-%-") then
            local body, only = line:match("^(.-)%s*<<%s*(.-)$")
            body = body or line
            local mine = not only or Format.For(who, only)
            if body == "" and only and not step then
                guide.only = Trim(only)
                guide.mine = guide.mine and mine
            elseif body:lower() == "step" then
                -- A new step; one not for this character is read past.
                step, skipping, manualOnly = { lines = {} }, not mine, nil
                if mine then guide.steps[#guide.steps + 1] = step end
            elseif mine and not skipping then
                local mark, value = body:match("^#(%S+)%s*(.-)$")
                if mark then
                    value = Uncommented(value)
                    if words.gameTags[mark:lower()] then
                        if not step then guide.games[#guide.games + 1] = words.gameTags[mark:lower()] end
                    elseif not step then
                        Head(guide, words.marks[mark], value)
                    elseif words.modes[mark] or Format.Dropped(mark, value, who) then
                        -- A step for a game mode or a phase Sane UI's games do not play: out again, its name too.
                        guide.steps[#guide.steps] = nil
                        if step.label then guide.labels[step.label] = nil end
                        skipping = true
                    else
                        Mark(guide, step, words.marks[mark], value)
                    end
                elseif step then
                    local command, rest = body:match("^%.(%S+)%s*(.-)$")
                    local head, said = (rest or body):match("^(.-)%s*>>%s*(.*)$")
                    if head then rest = head end
                    said = said ~= "" and said or nil
                    if command then
                        local ours = words.commands[command]
                        local read = ours and COMMANDS[ours]
                        if ours == "dungeon" and not Format.DungeonStep(guide, rest) then
                            -- A step of a dungeon in a normal guide, or for those who skip one in a dungeon guide: out.
                            guide.steps[#guide.steps] = nil
                            if step.label then guide.labels[step.label] = nil end
                            skipping = true
                            read = nil
                        end
                        local made, map
                        if read and not skipping then made, map = read(Values(rest), said, lastMap) end
                        if map then lastMap = map end
                        if made then
                            if not Command(step, made, said, manualOnly) and said == nil then
                                -- Nothing of it could be used and it had no words: let it go.
                            end
                            manualOnly = ours == "manualOnly" or manualOnly
                        elseif ours == "manualOnly" then
                            manualOnly = true
                        elseif skipping then
                            said = nil
                        elseif ours == "dungeon" or ours == "note" or ours == "timer" or ours == "pin"
                            or ours == "line" or ours == "map" then
                            if said then step.lines[#step.lines + 1] = { what = "say", words = said } end
                        elseif read then
                            problems[#problems + 1] = ("line %d: .%s could not be read"):format(number, command)
                            if said then step.lines[#step.lines + 1] = { what = "say", words = said } end
                        elseif said then
                            -- A command Sane UI does not know: its words still stand.
                            step.lines[#step.lines + 1] = { what = "say", words = said }
                        end
                    elseif body:find("^%+") then
                        step.lines[#step.lines + 1] = { what = "manual", words = Trim(body:sub(2)) }
                    elseif body:find("^%*") then
                        step.lines[#step.lines + 1] = { what = "note", words = Trim((body:sub(2):gsub("\\n", "\n"))) }
                    elseif said then
                        step.lines[#step.lines + 1] = { what = "say", words = said }
                    end
                end
            end
        end
    end
    guide.name = guide.name or ns.TEXT.unnamed
    guide.mine = guide.mine and Format.Plays(who, guide.games)
    return guide, problems
end

-- Whether a guide is one of a dungeon group: the one kind that runs dungeons.
local function OfDungeons(guide)
    return tostring(guide.group or ""):lower():find("dungeon", 1, true) ~= nil
end

-- Whether a step marked for a dungeon ("WC") or for doing without it ("!WC") is for this guide (Saneroki, 2026-10-31: "i
-- don't want to have dungeon quests in the normal guide. For that there is the dungeon guide."): a guide of a dungeon
-- group runs them all, every other guide none.
function Format.DungeonStep(guide, value)
    local without = tostring(value or ""):find("^%s*!") ~= nil
    return OfDungeons(guide) ~= without
end

-- The lines that name a quest of their own: to take, to work on, to carry for, to hand in.
local QUEST_LINES = { take = true, goal = true, carry = true, handin = true }

-- A normal guide without dungeon quests, also where its text does not mark them (Saneroki, 2026-11-03: the guides'
-- newer texts take some in a normal guide, to hand in if you happen to do the dungeon): each line about a quest
-- inDungeon(quest) names is left out, and so is a step that had such lines and keeps no quest line of its own (a walk
-- to that quest's place, its words). Names follow their steps. A guide of a dungeon group keeps them all.
function Format.NoDungeonQuests(guide, inDungeon)
    if type(guide) ~= "table" or type(inDungeon) ~= "function" or OfDungeons(guide) then return guide end
    local steps, labels = {}, {}
    for _, step in ipairs(guide.steps) do
        local lines, named, kept = {}, false, false
        for _, line in ipairs(step.lines) do
            local quest = QUEST_LINES[line.what] and line.quest or nil
            if quest and inDungeon(quest) then
                named = true
            else
                lines[#lines + 1] = line
                kept = kept or quest ~= nil
            end
        end
        if kept or not named then
            step.lines = lines
            steps[#steps + 1] = step
            if step.label then labels[step.label] = #steps end
        end
    end
    guide.steps, guide.labels = steps, labels
    return guide
end

-- Whether a step mark drops the step for the game played: a phase or an experience rate Sane UI's games are not at.
-- Forever is at phase 6 and rate 1; a mark that rules those out drops the step.
function Format.Dropped(mark, value, who)
    local ours = words and words.marks[mark]
    if ours == "phase" then
        local from, to = tostring(value):match("^(%d+)%-?(%d*)$")
        from, to = tonumber(from), tonumber(to)
        if not from then return false end
        local phase = 6
        return phase < from or (to and phase > to)
    elseif ours == "xprate" then
        local number, sign = Compared(value)
        if not number then return false end
        local rate = 1
        if sign == "<" then return not (rate < number)
        elseif sign == ">" then return not (rate > number) end
        local from, to = tostring(value):match("^(%d+)%-(%d+)$")
        if from then return rate < tonumber(from) or rate > tonumber(to) end
        return not (rate >= number)
    end
    return false
end
