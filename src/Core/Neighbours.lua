local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Neighbours
--  The other addons Sane UI knows, and adapts to when they are installed
--  (Saneroki, 2026-10-20: the known addons). This is the one file of Sane UI
--  that names them: each is described here by what a module needs of it, its
--  folder and its window with the ways to open and close it. A module asks for
--  one by its key and never names the addon itself; the answer is nil while
--  the addon is not loaded, so without it everything works as before.
--
--  Nothing of theirs is written: their window is lent for a while (Core.Lend,
--  Core.Seat) and given back, their own functions open and close it, and a hook
--  after their function follows its opening. Each call into them runs behind
--  a guard: an addon whose ways changed (a function gone, an error) counts as
--  not there.
--
--      local planner = Core.Neighbours.Window("talents") -- nil: not installed, not loaded, or changed
--      planner.key, planner.title       -- its key here; its name, as it calls itself
--      planner:Frame()                  -- its window, once made (it may make it the first time it opens)
--      planner:Shown()                  -- open now
--      planner:Open(), planner:Close()  -- by its own functions
--      planner:Follow(fn)               -- fn() after each opening of it, whatever opened it
--
--  A leveling guide is asked what its step at hand wants, by name (Saneroki,
--  2026-10-25: Speed Leveling's key finds it around you):
--
--      local foes, friends = Core.Neighbours.Targets("guide") -- nil: not installed, not loaded, or changed
--      foes, friends                    -- the creatures, the NPCs: lists of names in the guide's order, copies
--      local items, spells = Core.Neighbours.Uses("guide")    -- what the step wants used: item and spell IDs
--
--  And its loaded guide, as it stands, for Speed Leveling's own view of it; and
--  the words of its text format, for guides pasted as text (Saneroki,
--  2026-10-25):
--
--      local book = Core.Neighbours.Book("guide", 8) -- nil: not loaded, no guide in it, or its ways changed
--      book.title, book.at, book.total  -- the guide's name, the step it is at, how many steps it has
--      book.hand                        -- the steps at hand: { { number, lines = { { text, done, count } } } }
--                                       -- (count: a line of something to do, ticked when done)
--      book.ahead                       -- up to that many steps after: { { number, text } }
--      book.colours                     -- the colours its words give names, by our kinds: { friend = "ff00ff25" }
--      book.shown                       -- whether its own window is shown
--      book.place                       -- where its arrow points, while it points: { continent, x, y } (the
--                                       -- world's yards, as its text format writes them) or { map, x, y } (a
--                                       -- uiMapID, hundredths); a line's what: our word for its command
--      Core.Neighbours.Pointing("guide")          -- book.place alone, for an arrow asked often
--      Core.Neighbours.Menu("guide")              -- its own menu (its guides, its options), by its own function
--      Core.Neighbours.Arrow("guide")             -- its arrow's frame, or nil
--      Core.Neighbours.Boxes("guide")             -- its boxes of targets and items: a list of frames
--      Core.Neighbours.GoTo("guide", 12)          -- its step 12, by its own function
--      Core.Neighbours.Frame("guide")             -- its window's frame, or nil
--      local words = Core.Neighbours.Format("guide") -- its text format's words, by ours (copies):
--      words.commands, words.marks      -- [its word] = ours; words.modes: [its mark] = true (a game mode not ours)
--      words.colours                    -- [our kind] = its colour word in a guide's text
-------------------------------------------------------------------------------
local Neighbours = {}
Core.Neighbours = Neighbours

-- The known addons, by the key a module asks with.
Neighbours.KNOWN = {
    -- A talent planner: its window is the Talents panel on Combat's full screen. It makes the window the
    -- first time it opens; its table's UI opens (Show) and closes (Hide) it.
    talents = { addon = "TalentsForeverBook", title = "Talents Forever", window = "TalentsForeverBookFrame",
                api = "TalentsForeverBook", open = "Show", close = "Hide" },
    -- A leveling guide: what its step at hand wants killed, talked to or used, for Speed Leveling's key. Its addon
    -- object is found by its name through the library it was made with (library, from the global stub); its part
    -- targeting has a function (lists) that answers three lists of names: the NPCs, the creatures to kill, the creatures
    -- to look out for. The object's tables items and spells hold what its steps at hand want used, by ID (its hearth step
    -- puts the Hearthstone there).
    -- Its loaded guide: the object's guide table (current: its name or display name, its steps, each with its
    -- lines, elements: each with text and whether completed or skipped, textOnly for words only), the step it is at
    -- (progress, a function), its function that goes to a step (go), its window (window, a global frame) with the
    -- steps at hand on it (hand), and the colours it gives the colour words of its texts (colourTable).
    guide = { addon = "RXPGuides", title = "RestedXP", stub = "LibStub", library = "AceAddon-3.0", part = "targeting",
              lists = "GetCurrentTargets", items = "activeItems", spells = "activeSpells",
              current = "currentGuide", progress = "GetGuideProgress", go = "SetStep", window = "RXPFrame",
              hand = "activeSteps", colourTable = "guideTextColors",
              -- Its arrow: a frame of the object's (arrow), shown while it points, its target element (element: the
              -- world's yards wx, wy on the continent instance, or a map zone and x, y in hundredths); the function of
              -- its window that opens its menu (menu); its boxes of targets and items, global frames (boxes).
              arrow = "arrowFrame", menu = "DropDownMenu", boxes = { "RXPTargetFrame", "RXPItemFrame" },
              -- Its text format: each command word and step mark by ours, the marks of game modes Sane UI's games do
              -- not play, and its colour words by our kinds.
              commands = { accept = "take", turnin = "handin", complete = "goal", collect = "carry", xp = "level",
                           train = "learn", hs = "hearth", home = "bind", fp = "flightpath", fly = "fly", zone = "zone",
                           subzone = "area", deathskip = "revive", cast = "cast", usespell = "cast", vendor = "shop",
                           trainer = "trainer", target = "friend", mob = "foe", unitscan = "foe", use = "use",
                           isOnQuest = "onQuest", isQuestComplete = "questReady", isQuestTurnedIn = "handedIn",
                           isQuestAvailable = "open", money = "money", itemcount = "count", zoneskip = "inZone",
                           subzoneskip = "inArea", ["goto"] = "place", waypoint = "waypoint" },
              marks = { name = "name", displayname = "title", next = "after", group = "group", version = "version",
                        defaultfor = "defaultFor", completewith = "together", label = "label", sticky = "stays",
                        requires = "needs", optional = "aside" },
              modes = { "hardcore", "som", "season", "ssf" },
              colours = { friend = "RXP_FRIENDLY_", foe = "RXP_ENEMY_", loot = "RXP_LOOT_", warn = "RXP_WARN_",
                          pick = "RXP_PICK_", buy = "RXP_BUY_" } },
}

local handles = {} -- [key] = the handle made for it
local methods = {}

-- Whether that addon is installed, switched on and loaded now.
local function Loaded(addon)
    local addons = rawget(_G, "C_AddOns")
    local loaded = addons and addons.IsAddOnLoaded
    return loaded and Core.Ask(loaded, addon) == true or false
end

-- The table of its functions that open and close its window, if it has it now.
local function Calls(known)
    local api = rawget(_G, known.api)
    local ui = type(api) == "table" and rawget(api, "UI")
    if type(ui) ~= "table" or type(ui[known.open]) ~= "function" or type(ui[known.close]) ~= "function" then return nil end
    return ui
end

function methods:Frame()
    local frame = rawget(_G, self.known.window)
    if type(frame) == "table" and type(frame.GetObjectType) == "function" and frame.IsShown then return frame end
end

function methods:Shown()
    local frame = self:Frame()
    return frame and frame:IsShown() and true or false
end

function methods:Open()
    local ui = Calls(self.known)
    if ui then Core.Safe("neighbours: " .. self.key, ui[self.known.open]) end
end

function methods:Close()
    local ui = Calls(self.known)
    if ui then Core.Safe("neighbours: " .. self.key, ui[self.known.close]) end
end

-- fn after each opening, by a hook after its own opening function (all its ways to open pass there). Once:
-- a second Follow replaces the first fn.
function methods:Follow(fn)
    self.follow = fn
    if self.hooked then return end
    local ui = Calls(self.known)
    if not ui then return end
    self.hooked = true
    hooksecurefunc(ui, self.known.open, Core.Guard("neighbours: " .. self.key, function()
        if self.follow then self.follow() end
    end))
end

-- The addon object of a known addon made with a library that finds addons by their name (known.library, from the
-- global known.stub).
local function Object(known)
    local stub = rawget(_G, known.stub)
    local get = type(stub) == "table" and rawget(stub, "GetLibrary")
    local library = Core.Ask(get, stub, known.library, true)
    local object = type(library) == "table" and Core.Ask(library.GetAddon, library, known.addon, true)
    return type(object) == "table" and object or nil
end

-- Each name of a list, plain and once (seen), into a list of ours: nothing of theirs is kept.
local function Names(list, into, seen)
    if type(list) ~= "table" then return end
    for _, name in ipairs(list) do
        name = Core.Plain(name)
        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true
            into[#into + 1] = name
        end
    end
end

-- What a known guide's step at hand wants: the creatures (those to kill, then those to look out for) and the NPCs,
-- each a list of names; nil while it is not loaded or its ways changed.
function Neighbours.Targets(key)
    local known = Neighbours.KNOWN[key]
    if not known or not known.lists or not Loaded(known.addon) then return nil end
    local object = Object(known)
    local part = object and rawget(object, known.part)
    local lists = type(part) == "table" and rawget(part, known.lists)
    if type(lists) ~= "function" then return nil end
    local ok, friends, kill, look = pcall(lists)
    if not ok then return nil end
    local foes, wanted, seen = {}, {}, {}
    Names(kill, foes, seen)
    Names(look, foes, seen)
    Names(friends, wanted, seen)
    return foes, wanted
end

-- The IDs of a table's keys that are whole numbers above 0, in order: nothing of theirs is kept.
local function Ids(list)
    local ids = {}
    if type(list) ~= "table" then return ids end
    for id, wanted in pairs(list) do
        id = Core.Plain(id)
        if type(id) == "number" and id > 0 and id == math.floor(id) and Core.Plain(wanted) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids
end

-- What a known guide's steps at hand want used: two lists of IDs, the items and the spells; nil while it is not loaded
-- or its ways changed.
function Neighbours.Uses(key)
    local known = Neighbours.KNOWN[key]
    if not known or not known.items or not Loaded(known.addon) then return nil end
    local object = Object(known)
    local items = object and rawget(object, known.items)
    if type(items) ~= "table" then return nil end
    return Ids(items), Ids(rawget(object, known.spells))
end

-- A known guide's text format: its words by ours, copies (nothing of theirs is kept); nil for one with none.
function Neighbours.Format(key)
    local known = Neighbours.KNOWN[key]
    if not known or not known.commands then return nil end
    local words = { commands = {}, marks = {}, modes = {}, colours = {} }
    for theirs, ours in pairs(known.commands) do words.commands[theirs] = ours end
    for theirs, ours in pairs(known.marks) do words.marks[theirs] = ours end
    for _, mark in ipairs(known.modes) do words.modes[mark] = true end
    for ours, theirs in pairs(known.colours) do words.colours[ours] = theirs end
    return words
end

-- A known guide's addon object and its loaded guide table, while it is loaded and has one.
local function LoadedGuide(known)
    if not known or not known.current or not Loaded(known.addon) then return nil end
    local object = Object(known)
    local guide = object and rawget(object, known.current)
    if type(guide) ~= "table" or type(rawget(guide, "steps")) ~= "table" then return nil end
    return object, guide
end

-- A step's lines as plain copies: the words of each element that has any, whether it is done, whether it is a
-- thing to do (count) or words only.
local function Lines(step, commands)
    local lines = {}
    for _, element in ipairs(type(step.elements) == "table" and step.elements or {}) do
        local text = type(element) == "table" and Core.Plain(element.text)
        if type(text) == "string" and text:find("%S") then
            local tag = Core.Plain(element.tag)
            lines[#lines + 1] = { text = text, done = (element.completed or element.skip) and true or false,
                                  count = not element.textOnly, what = type(tag) == "string" and commands
                                  and commands[tag] or nil }
        end
    end
    return lines
end

-- A step's first words: what the window lists for a step ahead.
local function FirstWords(step)
    local lines = Lines(step)
    return lines[1] and lines[1].text or nil
end

-- Where a known guide's arrow points, while it is shown: a place of ours, plain numbers.
local function ArrowPlace(object, known)
    local arrow = rawget(object, known.arrow)
    if type(arrow) ~= "table" or not (arrow.IsShown and arrow:IsShown()) or arrow.wrongContinent then return nil end
    local element = rawget(arrow, "element")
    if type(element) ~= "table" then return nil end
    local wx, wy, continent = Core.Plain(element.wx), Core.Plain(element.wy), Core.Plain(element.instance)
    if type(wx) == "number" and type(wy) == "number" and type(continent) == "number" then
        return { continent = continent, x = wx, y = wy }
    end
    local map, x, y = Core.Plain(element.zone), Core.Plain(element.x), Core.Plain(element.y)
    if type(map) == "number" and type(x) == "number" and type(y) == "number" then return { map = map, x = x, y = y } end
    return nil
end

function Neighbours.Book(key, ahead)
    local known = Neighbours.KNOWN[key]
    local object, guide = LoadedGuide(known)
    if not object then return nil end
    local steps = guide.steps
    local ok, at = pcall(rawget(object, known.progress) or error, guide)
    at = ok and tonumber(Core.Plain(at)) or nil
    if not at then return nil end
    local window = rawget(_G, known.window)
    local book = { title = Core.Plain(guide.displayname) or Core.Plain(guide.name), at = at, total = #steps,
                   hand = {}, ahead = {}, colours = {},
                   shown = type(window) == "table" and window.IsShown and window:IsShown() and true or false }
    if type(book.title) ~= "string" then book.title = "" end
    local hand = type(window) == "table" and rawget(window, known.hand)
    for _, step in ipairs(type(hand) == "table" and hand or {}) do
        local number = type(step) == "table" and tonumber(Core.Plain(step.index))
        if number and not step.hidewindow and not step.tip then
            book.hand[#book.hand + 1] = { number = number, lines = Lines(step, known.commands) }
        end
    end
    table.sort(book.hand, function(a, b) return a.number < b.number end)
    local last = book.hand[#book.hand] and book.hand[#book.hand].number or at
    local number = math.max(at, last) + 1
    while #book.ahead < (ahead or 0) and steps[number] do
        local step = steps[number]
        if type(step) == "table" and not step.optional and not step.hidewindow and not step.tip then
            local text = FirstWords(step)
            if text then book.ahead[#book.ahead + 1] = { number = number, text = text } end
        end
        number = number + 1
    end
    book.place = ArrowPlace(object, known)
    local colours = rawget(object, known.colourTable)
    for ours, theirs in pairs(known.colours) do
        local colour = type(colours) == "table" and Core.Plain(colours[theirs])
        if type(colour) == "string" then book.colours[ours] = colour:lower() end
    end
    return book
end

-- To a step of a known guide's loaded guide, by its own function.
function Neighbours.GoTo(key, number)
    local known = Neighbours.KNOWN[key]
    local object = LoadedGuide(known)
    local go = object and rawget(object, known.go)
    if type(go) == "function" and type(number) == "number" then Core.Safe("neighbours: " .. key, go, number) end
end

-- Where a known guide's arrow points now (as book.place), without the rest of its book.
function Neighbours.Pointing(key)
    local known = Neighbours.KNOWN[key]
    local object = known and known.arrow and LoadedGuide(known)
    return object and ArrowPlace(object, known) or nil
end

-- A known guide's own menu, opened by its window's own function.
function Neighbours.Menu(key)
    local frame = Neighbours.Frame(key)
    local known = Neighbours.KNOWN[key]
    local open = frame and known.menu and rawget(frame, known.menu)
    if type(open) == "function" then Core.Safe("neighbours: " .. key, open) end
end

-- A known guide's arrow frame, while it is loaded.
function Neighbours.Arrow(key)
    local known = Neighbours.KNOWN[key]
    local object = known and known.arrow and Loaded(known.addon) and Object(known)
    local arrow = object and rawget(object, known.arrow)
    if type(arrow) == "table" and type(arrow.GetObjectType) == "function" then return arrow end
    return nil
end

-- A known addon's boxes, by their global names, those made so far, while it is loaded.
function Neighbours.Boxes(key)
    local known = Neighbours.KNOWN[key]
    local boxes = {}
    if not known or not known.boxes or not Loaded(known.addon) then return boxes end
    for _, name in ipairs(known.boxes) do
        local frame = rawget(_G, name)
        if type(frame) == "table" and type(frame.GetObjectType) == "function" then boxes[#boxes + 1] = frame end
    end
    return boxes
end

-- A known addon's window, by its global name, while it is loaded.
function Neighbours.Frame(key)
    local known = Neighbours.KNOWN[key]
    if not known or not known.window or not Loaded(known.addon) then return nil end
    local frame = rawget(_G, known.window)
    if type(frame) == "table" and type(frame.GetObjectType) == "function" then return frame end
    return nil
end

-- The handle of a known addon by its key, while that addon is loaded and has what is used of it; nil otherwise.
function Neighbours.Window(key)
    local known = Neighbours.KNOWN[key]
    if not known or not Loaded(known.addon) or not Calls(known) then return nil end
    local handle = handles[key]
    if not handle then
        handle = setmetatable({ key = key, title = known.title, known = known }, { __index = methods })
        handles[key] = handle
    end
    return handle
end
