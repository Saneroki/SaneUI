local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Format
--  Reads a leveling guide written as text into a guide of our own shape, for
--  one character: what is not for its side, race or class is left out as it
--  is read. The text is in the format of the leveling guide Sane UI knows, so
--  its guides, and guides written for it, can be pasted (Saneroki,
--  2026-10-25). That guide's own words for its commands, step marks and
--  colours are Core's to know (Core.Neighbours.Format): here every command and
--  mark has a word of ours. Knows no frames and asks the game nothing.
--
--  A guide's text: its head (lines of #mark value) before its first step; each
--  step begins with a line "step" and holds lines of these kinds:
--      #mark value             about the step (its name, with which it ends, ...)
--      .command a,b >> words   a thing to do, to know or to check, and its words
--      +words                  a thing to do that only the player can tick off
--      >>words, *words         words only
--  "<< words" at a line's end keeps the line for some characters only: each
--  part (spaces between) must hold; a part holds when one of its names (a
--  slash between) does: a side, a race, a class, or "!" before one, all but it.
--  "<< words" alone in the head keeps the whole guide so. A text given in long
--  brackets ([[ ]], as a Lua file holds it) is read between them, each pair
--  one guide; else the whole text is one guide (Format.Parts).
--
--      local texts = Format.Parts(text)          -- each guide's own text
--      local guide, problems = Format.Read(text, who)  -- one guide's; nil while Core knows no such format
--      who     { side = "Horde", race = "Orc", class = "WARRIOR" } (the game's own tokens)
--      guide   { name, title, group, after = { names }, version, defaultFor = { names }, mine,
--                steps = { step }, labels = { [label] = index } }   -- mine: it is for this character
--      step    { lines = { line }, label, together ("next" or a label), stays, needs (a label), aside,
--                unless = { test }, friends, foes, items }
--      line    { what = a word of Format.DOING or Format.WORDS, words, ... what the command gave }
--      test    { what = a word of Format.TESTS, ... }: the step is passed by while it holds
--  problems: "line N: what: the line" for each line that could not be read; that line is left out.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Format = {}
ns.Format = Format

-- What a line can be: done when the game says so (DOING), or only words or a place (WORDS).
Format.DOING = { take = true, handin = true, goal = true, carry = true, level = true, learn = true, hearth = true,
                 bind = true, flightpath = true, fly = true, zone = true, area = true, revive = true, cast = true,
                 shop = true, trainer = true, arrive = true, manual = true }
Format.WORDS = { say = true, note = true, place = true }
-- What passes a step by while it holds: the step is not for now.
Format.TESTS = { onQuest = true, questReady = true, handedIn = true, open = true, money = true, count = true,
                 inZone = true, inArea = true, reached = true }
Format.FAR = 5 -- yards: how near a place counts as reached when its line names no reach

-- Names a guide may use for a race, as the game's token has it.
local RACES = { undead = "scourge" }

local function Trim(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end

-- A value with a comment after it ("--", spaces or not before it): the comment cut off.
local function Uncommented(text) return Trim((text:gsub("%s*%-%-.*$", ""))) end

-- The numbers of a list of values, in order.
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
local function Is(who, name)
    name = name:lower()
    name = RACES[name] or name
    return name == (who.side or ""):lower() or name == (who.race or ""):lower() or name == (who.class or ""):lower()
end

-- Whether the words after "<<" hold for the character.
function Format.For(who, words)
    for part in words:gmatch("%S+") do
        local holds = false
        for name in part:gmatch("[^/]+") do
            local negated, plain = name:match("^(!?)(.+)$")
            if (negated == "!") ~= Is(who, (plain:gsub("[%(%)]", ""))) then
                holds = true
                break
            end
        end
        if not holds then return false end
    end
    return true
end

-------------------------------------------------------------------------------
--  The commands, by our word for each
-------------------------------------------------------------------------------
-- A place: "Zone,x,y", "uiMapID,x,y" (shares of 100 of that map), or "uiMapID/continent,a,b" (the world's yards on
-- that continent, as the format writes them), then how near counts as reached; with a fifth value it is a point on
-- the way, never a thing to do. Without a map the last one named stands.
local function Place(values, last)
    local map = values[1] ~= "" and values[1] or last
    local x, y = tonumber(values[2]), tonumber(values[3])
    if not (map and x and y) then return nil end
    local place = { x = x, y = y, near = tonumber(values[4]), way = values[5] ~= nil }
    local id, continent = map:match("^(%d+)/(%d+)$")
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
local function Quests(what)
    return function(v)
        local quests = Numbers(v)
        return quests[1] and { test = { what = what, quests = quests } }
    end
end
local function Words(what) return function(v) return { what = what, to = v[1] ~= "" and v[1] or nil } end end

-- Each command makes of its values (strings, split at commas) a line (what), a test of the step (test), or names
-- and items for the key (friends, foes, items); nil for values it cannot read. A place also gives its map.
local COMMANDS = {
    take = function(v) return Quest(v) and { what = "take", quest = Quest(v) } end,
    handin = function(v) return Quest(v) and { what = "handin", quest = Quest(v) } end,
    goal = function(v) return Quest(v) and { what = "goal", quest = Quest(v), goal = tonumber(v[2]) or 1 } end,
    carry = function(v)
        local item = tonumber(v[1])
        return item and { what = "carry", item = item, count = tonumber(v[2]) or 1, quest = tonumber(v[3]) }
    end,
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
    learn = function(v) local spell = tonumber(v[1]) return spell and { what = "learn", spell = spell } end,
    hearth = Words("hearth"),
    bind = Words("bind"),
    flightpath = Words("flightpath"),
    fly = Words("fly"),
    zone = function(v) return v[1] and v[1] ~= "" and { what = "zone", to = tonumber(v[1]) or v[1] } end,
    area = function(v) local area = tonumber(v[1]) return area and { what = "area", area = area } end,
    revive = function() return { what = "revive" } end,
    cast = function(v) local spell = tonumber(v[1]) return spell and { what = "cast", spell = spell } end,
    shop = function() return { what = "shop" } end,
    trainer = function() return { what = "trainer" } end,
    friend = function(v) return { friends = v } end,
    foe = function(v) return { foes = v } end,
    use = function(v) local item = tonumber(v[1]) return item and { items = { item } } end,
    onQuest = Quests("onQuest"),
    questReady = Quests("questReady"),
    handedIn = Quests("handedIn"),
    open = Quests("open"),
    money = function(v)
        local gold, sign = Compared(v[1])
        if not gold or (sign ~= ">" and sign ~= "<") then return nil end
        return { test = { what = "money", copper = gold * 10000, more = sign == ">" } }
    end,
    count = function(v)
        local total, sign = Compared(v[#v])
        local items = {}
        for index = 1, #v - 1 do items[#items + 1] = tonumber(v[index]) end
        if not (total and items[1]) then return nil end
        return { test = { what = "count", items = items, total = total, sign = sign } }
    end,
    inZone = function(v)
        local maps = {}
        for name in (v[1] or ""):gmatch("[^%+/]+") do maps[#maps + 1] = tonumber(name) or name end
        return maps[1] and { test = { what = "inZone", maps = maps, away = (tonumber(v[2]) or 0) % 2 == 1 } }
    end,
    inArea = function(v)
        local areas = {}
        for name in (v[1] or ""):gmatch("[^%+/]+") do areas[#areas + 1] = tonumber(name) end
        return areas[1] and { test = { what = "inArea", areas = areas, away = (tonumber(v[2]) or 0) % 2 == 1 } }
    end,
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
local words -- Core's words of the format: { commands, marks, modes }, once asked

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
        if value ~= "" then step[field][#step[field] + 1] = value end
    end
end

-- What a command line gives, into the step.
local function Command(step, made, said)
    if made.what then
        made.words = said
        step.lines[#step.lines + 1] = made
        return
    end
    if made.test then
        step.unless = step.unless or {}
        step.unless[#step.unless + 1] = made.test
    end
    if made.friends then Append(step, "friends", made.friends) end
    if made.foes then Append(step, "foes", made.foes) end
    if made.items then Append(step, "items", made.items) end
    if said then step.lines[#step.lines + 1] = { what = "say", words = said } end
end

-- A mark of the head, into the guide.
local function Head(guide, mark, value)
    if mark == "name" then guide.name = value
    elseif mark == "title" then guide.title = value
    elseif mark == "group" then guide.group = value
    elseif mark == "version" then guide.version = tonumber(value)
    elseif mark == "after" then
        -- One guide to go on with, or several (";" between): the first one there is.
        for name in value:gmatch("[^;]+") do guide.after[#guide.after + 1] = Trim(name) end
    elseif mark == "defaultFor" then
        for name in value:gmatch("[^/%s]+") do guide.defaultFor[#guide.defaultFor + 1] = name end
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

-- One guide's text, read for that character.
function Format.Read(text, who)
    words = words or Core.Neighbours.Format("guide")
    if not words then return nil, {} end
    local guide = { steps = {}, labels = {}, defaultFor = {}, after = {}, mine = true }
    local problems = {}
    local step, skipping, lastMap
    local number = 0
    for raw in (tostring(text) .. "\n"):gmatch("(.-)\r?\n") do
        number = number + 1
        local line = Trim(raw)
        if line ~= "" and not line:find("^%-%-") then
            local body, only = line:match("^(.-)%s*<<%s*(.-)$")
            body = body or line
            local mine = not only or Format.For(who, only)
            if body == "" and only and not step then
                guide.mine = guide.mine and mine
            elseif body:lower() == "step" then
                -- A new step; one not for this character is read past.
                step, skipping = { lines = {} }, not mine
                if mine then guide.steps[#guide.steps + 1] = step end
            elseif mine and not skipping then
                local mark, value = body:match("^#(%S+)%s*(.-)$")
                if mark then
                    value = Uncommented(value)
                    if not step then
                        Head(guide, words.marks[mark], value)
                    elseif words.modes[mark] then
                        -- A step for a game mode Sane UI's games do not play: out again, its name too.
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
                        local made, map
                        if read then made, map = read(Values(rest), lastMap) end
                        if map then lastMap = map end
                        if made then
                            Command(step, made, said)
                        elseif read then
                            problems[#problems + 1] = ("line %d: .%s cannot be read: %s"):format(number, command, line)
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
    return guide, problems
end
