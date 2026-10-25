local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Guide
--  The guide shown and followed (Saneroki, 2026-10-25): the leveling guide
--  Sane UI knows while it is loaded (the guide it has loaded, which it unlocks
--  for the player's own account itself; Core.Neighbours.Book), else a guide
--  pasted as text, kept here and run by Run.lua. One picture of it for the
--  view, the player's ways through it, and what its steps at hand want for the
--  key (Wanted.lua, Key.lua).
--
--      Guide.Picture()    nil (no guide), or { title, levels, at, total, known, hand = { step }, ahead = { line } }
--                         step = { number, lines = { { text, done, have, need, count } } }, line = { number, text }
--                         (text in our colours; count: a thing to do, its have and need when it has a number)
--      Guide.Skip(number), Guide.Back(), Guide.Go(number)
--      Guide.Targets(), Guide.Uses()  what the steps at hand want found and used; nil without a guide
--      Guide.Kept()       the guides kept as text: { { name, group, mine } }, by group and name
--      Guide.Add(text)    the guides of a pasted text kept (one of the same name replaced): their names, problems
--      Guide.Remove(name), Guide.Choose(name), Guide.Chosen()
--      Guide.Watch(fn)    fn() whenever the picture may have changed (once a frame at most)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Guide = {}
ns.Guide = Guide

Guide.AHEAD = 6   -- the steps after those at hand the picture lists, at most (the view may show fewer)
Guide.LOOK = 0.5  -- seconds between looks at the known guide while the view shows it

local EMPTY = {}
-- Our colours for names in a guide's words, by kind: the game's own font colours, these where it lacks one.
local COLOURS = {
    friend = { "GREEN_FONT_COLOR", "19FF19" }, foe = { "RED_FONT_COLOR", "FF2020" },
    loot = { "LIGHTBLUE_FONT_COLOR", "88AAFF" }, warn = { "NORMAL_FONT_COLOR", "FFD100" },
    pick = { "ORANGE_FONT_COLOR", "FF8040" }, buy = { "LIGHTYELLOW_FONT_COLOR", "FFFF9B" },
}

local watchers = {}
local Changed
local ticker

local function Store()
    local store = Core.Store(ns.name)
    if type(store.guides) ~= "table" then store.guides = {} end
    return store.guides
end

local function Who()
    local _, race = Core.Ask(UnitRace, "player")
    local _, class = Core.Ask(UnitClass, "player")
    return { side = Plain(Core.Ask(UnitFactionGroup, "player")), race = Plain(race), class = Plain(class) }
end

-------------------------------------------------------------------------------
--  Colours
-------------------------------------------------------------------------------
local hexes -- [kind] = our colour as eight hex digits, once made

local function Hex(kind)
    if not hexes then
        hexes = {}
        for name, colour in pairs(COLOURS) do
            local given = rawget(_G, colour[1])
            local r, g, b
            if type(given) == "table" and given.GetRGB then r, g, b = given:GetRGB() end
            if not r then r, g, b = Core.RGB(colour[2]) end
            hexes[name] = "ff" .. Core.Hex(r, g, b):lower()
        end
    end
    return hexes[kind]
end

-- Our warning colour, as a text's colour code has it ("ffffd100").
function Guide.WarnHex() return Hex("warn") end

-- A guide's words in our colours: its colour words (a pasted text's), and the colours the known guide gave them.
local function Paint(text, given)
    if type(text) ~= "string" then return "" end
    local words = Core.Neighbours.Format("guide")
    for kind, word in pairs(words and words.colours or EMPTY) do
        text = text:gsub("|c" .. word:gsub("%p", "%%%0"), "|c" .. Hex(kind))
    end
    for kind, colour in pairs(given or EMPTY) do
        text = text:gsub("|c" .. colour, "|c" .. Hex(kind)):gsub("|c" .. colour:upper(), "|c" .. Hex(kind))
    end
    return (text:gsub("\\n", "\n"))
end

-- "1-6 Durotar": the levels and the zone, split; a name without levels is all title.
local function Split(name)
    local levels, rest = (name or ""):match("^(%d+%s*%-%s*%d+)%s+(.+)$")
    return rest or name or "", levels
end

-- "3/10" at a line's end: how many there are and are wanted.
local function Counted(text)
    local have, need = text:match("(%d+)%s*/%s*(%d+)%s*|?r?%s*$")
    return tonumber(have), tonumber(need)
end

-------------------------------------------------------------------------------
--  The two places a guide comes from
-------------------------------------------------------------------------------
local function Book()
    if not ns.options.knownGuide then return nil end
    return Core.Neighbours.Book("guide", Guide.AHEAD)
end

-- The known guide's book, as our picture.
local function FromBook(book)
    local title, levels = Split(Paint(book.title))
    local picture = { title = title, levels = levels, at = book.at, total = book.total, known = true, hand = {},
                      ahead = {} }
    for _, step in ipairs(book.hand) do
        local lines = {}
        for _, line in ipairs(step.lines) do
            local text = Paint(line.text, book.colours)
            local have, need = Counted(text)
            lines[#lines + 1] = { text = text, done = line.done, count = line.count, have = have, need = need }
        end
        picture.hand[#picture.hand + 1] = { number = step.number, lines = lines }
    end
    for _, line in ipairs(book.ahead) do
        picture.ahead[#picture.ahead + 1] = { number = line.number, text = Paint(line.text, book.colours) }
    end
    return picture
end

-- A step of the guide run here: its lines with words, places without words left out.
local function OurLines(index)
    local lines = {}
    for _, state in ipairs(ns.Run.Lines(index)) do
        local line = state.line
        local words = ns.Run.Words(line)
        if words and (line.what ~= "place" or line.words) then
            lines[#lines + 1] = { text = Paint(words), done = state.done, count = ns.Format.DOING[line.what] or false,
                                  have = state.have, need = state.need }
        end
    end
    return lines
end

local function FromRun()
    local guide = ns.Run.Guide()
    if not guide then return nil end
    local title, levels = Split(Paint(guide.title or guide.name))
    local at = ns.Run.At()
    local picture = { title = title, levels = levels, at = math.min(at, #guide.steps), total = #guide.steps,
                      hand = {}, ahead = {} }
    local last = at
    for _, index in ipairs(ns.Run.Hand()) do
        picture.hand[#picture.hand + 1] = { number = index, lines = OurLines(index) }
        last = math.max(last, index)
    end
    local index = last + 1
    while #picture.ahead < Guide.AHEAD and guide.steps[index] do
        if not guide.steps[index].aside then
            local lines = OurLines(index)
            if lines[1] then picture.ahead[#picture.ahead + 1] = { number = index, text = lines[1].text } end
        end
        index = index + 1
    end
    return picture
end

function Guide.Picture()
    local book = Book()
    if book then return FromBook(book) end
    return FromRun()
end

function Guide.Known() return Book() ~= nil end

-------------------------------------------------------------------------------
--  The player's ways through it
-------------------------------------------------------------------------------
function Guide.Go(number)
    if Book() then
        Core.Neighbours.GoTo("guide", number)
    else
        ns.Run.Go(number)
    end
    Changed()
end

function Guide.Back()
    local book = Book()
    if book then
        if book.at > 1 then Core.Neighbours.GoTo("guide", book.at - 1) end
    else
        ns.Run.Back()
    end
    Changed()
end

-- A step at hand skipped: the one it is at, past it; another (one that stays at hand), out of the way. The known
-- guide goes on only past the step it is at.
function Guide.Skip(number)
    local book = Book()
    if book then
        if number == book.at then Core.Neighbours.GoTo("guide", book.at + 1) end
    else
        ns.Run.Skip(number)
    end
    Changed()
end

-- The known guide's while it is loaded (and its switch is on), else the guide run here.
function Guide.Targets()
    if not ns.options.guide then return nil end
    if ns.options.knownGuide then
        local foes, friends = Core.Neighbours.Targets("guide")
        if foes then return foes, friends end
    end
    if ns.Run.Guide() then return ns.Run.Targets() end
    return nil
end

function Guide.Uses()
    if ns.options.knownGuide then
        local items, spells = Core.Neighbours.Uses("guide")
        if items then return items, spells end
    end
    if ns.Run.Guide() then return ns.Run.Uses() end
    return nil
end

-------------------------------------------------------------------------------
--  The guides kept as text
-------------------------------------------------------------------------------
-- A kept guide read for this character; nil for one not kept or that cannot be read.
local function Read(name)
    local kept = Store()[name]
    if type(kept) ~= "table" or type(kept.text) ~= "string" then return nil end
    return (ns.Format.Read(kept.text, Who()))
end

function Guide.Kept()
    local list = {}
    for name, kept in pairs(Store()) do
        if type(kept) == "table" then
            list[#list + 1] = { name = name, group = kept.group or "", mine = kept.mine ~= false }
        end
    end
    table.sort(list, function(a, b)
        if a.group ~= b.group then return a.group < b.group end
        return a.name < b.name
    end)
    return list
end

function Guide.Chosen()
    local guide = ns.Run.Guide()
    return guide and guide.name or nil
end

function Guide.Choose(name)
    local guide = name and Read(name)
    ns.Run.Use(guide and guide.mine and guide or nil)
    Changed()
end

-- Each guide of a pasted text kept by its name, for every character (what is for whom is read again for each).
function Guide.Add(text)
    local names, problems = {}, {}
    local who = Who()
    for _, part in ipairs(ns.Format.Parts(text)) do
        local guide, found = ns.Format.Read(part, who)
        if guide then
            Store()[guide.name] = { text = part, group = guide.group, mine = guide.mine }
            names[#names + 1] = guide.name
            for _, problem in ipairs(found) do problems[#problems + 1] = guide.name .. ", " .. problem end
        end
    end
    -- A character without a guide yet takes the first one for it.
    if not ns.Run.Guide() then
        for _, name in ipairs(names) do
            local guide = Read(name)
            if guide and guide.mine then
                Guide.Choose(name)
                break
            end
        end
    end
    Changed()
    return names, problems
end

function Guide.Remove(name)
    Store()[name] = nil
    if Guide.Chosen() == name then ns.Run.Use(nil) end
    Changed()
end

-- The guide a character starts with: the one it ran, else the first kept one its head names for its race or class.
local function Start()
    local notes = Core.Character(ns.name)
    local guide = type(notes.guide) == "string" and Read(notes.guide)
    if guide and guide.mine then
        ns.Run.Use(guide)
        return
    end
    local who = Who()
    for _, kept in ipairs(Guide.Kept()) do
        local read = Read(kept.name)
        if read and read.mine then
            for _, name in ipairs(read.defaultFor) do
                if ns.Format.For(who, name) then
                    ns.Run.Use(read)
                    return
                end
            end
        end
    end
end

-- The guide run here is through: on to the one it names after it, the first kept one that is for this character.
local function Onward()
    local guide = ns.Run.Guide()
    if not guide or ns.Run.At() <= #guide.steps then return end
    for _, after in ipairs(guide.after) do
        local name = after:match("[^\\]+$")
        local next = name and Read(name)
        if next and next.mine then
            ns.Run.Use(next)
            return
        end
    end
end

-------------------------------------------------------------------------------
--  Changes
-------------------------------------------------------------------------------
function Guide.Watch(fn) watchers[#watchers + 1] = fn end

local function Tell()
    for _, fn in ipairs(watchers) do ns.Safe("guide", fn) end
end
Changed = Core.Later(Tell)

-- The game changed: the guide run here moves on as far as done steps go.
local function Check()
    if Book() or not ns.Run.Guide() then return end
    if ns.Run.Check() then Onward() end
    ns.Run.Watch(Changed)
    Changed()
end
local checkSoon = Core.Later(Check, 0.2)

-- Things the game tells only as they happen, for the guide run here.
local function Saw(what)
    return function()
        if Book() or not ns.Run.Guide() then return end
        ns.Run.Saw(what)
        checkSoon()
    end
end

-- What the known guide's book holds now, as one string: changed, it is told.
local function Sign(book)
    if not book then return nil end
    local parts = { book.title, book.at, book.total, book.shown and "shown" or "closed" }
    for _, step in ipairs(book.hand) do
        parts[#parts + 1] = step.number
        for _, line in ipairs(step.lines) do parts[#parts + 1] = (line.done and "+" or "-") .. line.text end
    end
    for _, line in ipairs(book.ahead) do parts[#parts + 1] = line.number end
    return table.concat(parts, "\n")
end

local CHECKS = { "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "QUEST_ACCEPTED", "BAG_UPDATE_DELAYED", "PLAYER_LEVEL_UP",
                 "PLAYER_XP_UPDATE", "PLAYER_MONEY", "SPELLS_CHANGED", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA",
                 "ZONE_CHANGED_INDOORS", "PLAYER_ENTERING_WORLD" }

function Guide.Start()
    Start()
    for _, event in ipairs(CHECKS) do ns.On(event, checkSoon) end
    ns.On("HEARTHSTONE_BOUND", Saw("bind"))
    ns.On("TAXIMAP_OPENED", Saw("flightpath"))
    ns.On("MERCHANT_SHOW", Saw("shop"))
    ns.On("TRAINER_SHOW", Saw("trainer"))
    ns.On("PLAYER_UNGHOST", Saw("revive"))
    ns.On("PLAYER_CONTROL_LOST", Core.Later(function()
        if Core.Ask(rawget(_G, "UnitOnTaxi"), "player") then Saw("fly")() end
    end, 1))
    ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spell)
        if unit ~= "player" or Book() or not ns.Run.Guide() then return end
        spell = Plain(spell)
        if spell == ns.Run.HEARTH_SPELL or spell == ns.Run.RECALL then ns.Run.Saw("hearth") end
        if type(spell) == "number" then ns.Run.Saw("cast" .. spell) end
        checkSoon()
    end)
    -- The known guide changes by itself: while it is loaded, looked at every Guide.LOOK seconds, told when it changed.
    if not Core.Neighbours.Frame("guide") then return Check() end
    local last
    ticker = C_Timer.NewTicker(Guide.LOOK, ns.Guard(function()
        local state = Sign(Book())
        if state ~= last then
            last = state
            Tell()
        end
    end))
    Check()
end

function Guide.Stop()
    if ticker then ticker:Cancel() end
    ticker = nil
    ns.Run.Stop()
end
