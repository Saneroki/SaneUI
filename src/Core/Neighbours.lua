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
--  A leveling guide is not adapted to at runtime: Sane UI only reads the words
--  of its text format, so Speed Leveling can run guides written in it with an
--  engine of its own (Saneroki, 2026-10-25). The words are given as copies, so
--  nothing of the addon is kept or called:
--
--      local words = Core.Neighbours.Format("guide")  -- nil for a guide with no format
--      words.commands, words.marks      -- [its word] = ours; words.modes: [its mark] = true (a game mode not ours)
--      words.colours                    -- [our kind] = its colour word in a guide's text
--      words.gameTags                   -- [its game tag] = our word for the game (which games a guide is for)
--
--  And the recipe its bought guides are locked by, so Speed Leveling can open
--  the ones bought for the player's own account (Unlock.lua):
--
--      local lock = Core.Neighbours.Lock("guide")     -- a copy: { account, tag, width, taps, mark, close, version }
--
--  A dungeon map addon is not adapted to either: Sane UI only speaks its way of
--  sharing map drawings, so Navigation's sketches go both ways with its players
--  (Saneroki, 2026-11-16): its share strings pasted, its shares heard on its own
--  addon messages, ours sent in its format as well. The words of that format,
--  its dungeons' keys and how its dungeon maps lie on ours are given as a copy:
--
--      local words = Core.Neighbours.Sketches("dungeonMaps")  -- nil for an addon whose drawings are not known
-------------------------------------------------------------------------------
local Neighbours = {}
Core.Neighbours = Neighbours

-- The known addons, by the key a module asks with.
Neighbours.KNOWN = {
    -- A talent planner: its window is the Talents panel on Combat's full screen. It makes the window the
    -- first time it opens; its table's UI opens (Show) and closes (Hide) it.
    talents = { addon = "TalentsForeverBook", title = "Talents Forever", window = "TalentsForeverBookFrame",
                api = "TalentsForeverBook", open = "Show", close = "Hide" },
    -- A leveling guide whose text format Sane UI reads (Saneroki, 2026-10-25): Speed Leveling runs guides written
    -- in it (the guides you bought, opened for your own account, and guides pasted as text) with an engine of its
    -- own, needing nothing of the addon at runtime. Named here only to read its format: each command word and step
    -- mark by a word of ours, the marks of game modes Sane UI's games do not play, the game tags that say which games
    -- a guide is for, the colour words its texts give names, and the recipe its bought guides are locked by (lock).
    guide = {
              -- Its text format: each command word and step mark by ours, the marks of game modes Sane UI's games do
              -- not play, and its colour words by our kinds.
              commands = { accept = "take", daily = "take", acceptmultiple = "take", turnin = "handin",
                           dailyturnin = "handin", turninmultiple = "handin", complete = "goal", collect = "carry",
                           collectmultiple = "carry", questitemcount = "carry", destroy = "destroy", xp = "level",
                           xpto = "level", train = "learn", hastyhearth = "learn", istrained = "learn", skill = "skill",
                           hs = "hearth", hsbatching = "hearth", home = "bind", bindlocation = "atHome", fp = "flightpath",
                           fly = "fly", zone = "zone", subzone = "area", explore = "area", deathskip = "revive",
                           cast = "cast", usespell = "cast", vendor = "shop", trainer = "trainer", stable = "stable",
                           tame = "tame", equip = "equip", reputation = "note", target = "friend", mob = "foe",
                           unitscan = "foe", rare = "foe", use = "use", openitem = "use", macro = "note",
                           bankdeposit = "bankIn", bankwithdraw = "bankOut", retrieveitem = "bankOut",
                           isOnQuest = "onQuest", isNotOnQuest = "notOnQuest", isQuestComplete = "questReady",
                           isQuestNotComplete = "questOpen", isQuestTurnedIn = "handedIn", isQuestAvailable = "open",
                           skipOnQuest = "skipOnQuest", money = "money", itemcount = "count",
                           aura = "aura", itemStat = "stat", bronzetube = "note", zoneskip = "inZone", subzoneskip = "inArea",
                           group = "grouped", solo = "solo", dungeon = "dungeon", enabledungeon = "dungeon",
                           maxlevel = "maxLevel", disablecheckbox = "manualOnly", ["goto"] = "place",
                           groundgoto = "place", flygoto = "place", questgoto = "place", waypoint = "waypoint",
                           questwaypoint = "waypoint", line = "line", pin = "pin", link = "link", timer = "timer",
                           countdown = "timer", cooldown = "ready", blastedLands = "note" },
              marks = { name = "name", displayname = "title", next = "after", group = "group", subgroup = "subgroup",
                        version = "version", defaultfor = "defaultFor", completewith = "together", label = "label",
                        sticky = "stays", requires = "needs", optional = "aside", loop = "loop", hidewindow = "hidden",
                        map = "map", arrowtext = "arrowText", xprate = "xprate", phase = "phase", internal = "part",
                        disabled = "divider" },
              modes = { "hardcore", "hardcoreserver", "som", "season", "ssf", "questguide", "speedrunguide", "beta",
                        "fresh", "aldor", "scryer" },
              -- Which games a guide's head marks it for (its first step onwards is read only for a game it names):
              -- our word for each, "classic" the older one Forever falls back to.
              gameTags = { forever = "forever", retail = "retail", df = "retail", classic = "classic" },
              colours = { friend = "RXP_FRIENDLY_", foe = "RXP_ENEMY_", loot = "RXP_LOOT_", warn = "RXP_WARN_",
                          pick = "RXP_PICK_", buy = "RXP_BUY_" },
              -- How its import strings of bought guides are locked to the buyer's account (Saneroki, 2026-10-25:
              -- Speed Leveling opens them for the account played): the account's name is the given answer of the
              -- game's function (account, tag: the BattleTag), its last width bytes in small letters set to the
              -- right of width bytes (zeros before), each then stirred from the bytes taps behind it; that key
              -- locks each piece (the stream cipher RC4) of zlib-packed text. A piece is its Adler-32 sum, the
              -- mark, the base64 text and the close; the string ends in "|" and its format's version, at least
              -- version.
              lock = { account = "BNGetInfo", tag = 2, width = 16, taps = { 15, 13, 12, 10 }, mark = ":",
                       close = "%", version = 40000 } },
    -- A dungeon map addon whose map drawings Navigation's sketches share both ways (Saneroki, 2026-11-16: "Yes, build
    -- it"; "make the map sharing as compatible as possible"). Named here only for its way of sharing; read by
    -- src/Navigation/Exchange.lua.
    dungeonMaps = {
        addon = "FojjiCore_DungeonJournal", title = "FojjiCore",
        -- Its addon messages: on its prefix, "<kind><cut><share's number><cut><part><cut><parts><cut><piece>" (the
        -- three numbers hexadecimal), a piece of at most piece letters, at most most parts, all parts within hold
        -- seconds of the first; a drawing shared is of kind share.
        prefix = "FojjiDJ", cut = "~", piece = 200, most = 400, hold = 120, share = "RT",
        -- A share string: "<head>.<kind>.<packing>.<sum>.<body>", kind route (one) or backup (all of a player's);
        -- packed (deflate) or plain; the body its table written as text, then in the letters (six bits each, no
        -- padding); the sum of the body: two rolling sums (seed, step, modulus each; the second adds each byte
        -- times its place), each five hexadecimal digits.
        head = "FDJ", route = "route", backup = "backup", packed = "z", plain = "p",
        letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
        sums = { { 7919, 31, 1000003 }, { 104729, 17, 999983 } },
        -- A table written as text: a text as tags.text, its length, tags.long, the text; a whole number as
        -- tags.whole, the number, tags.stop; any other number as tags.number (six figures), tags.stop; true and
        -- false as tags.yes and tags.no; a table as tags.open, its list, tags.split, its keys and values, tags.close.
        tags = { text = "s", long = ":", whole = "i", number = "f", stop = ";", yes = "y", no = "n", open = "(",
                 split = "|", close = ")" },
        deepest = 24,
        -- A drawing shared (kind route): its fields, version 1 or 2; the stops a list of map, x, y; the strokes and
        -- marks lists of their fields in that order; places as whole numbers of scale.
        version = 2, versions = { 1, 2 }, scale = 10000,
        fields = { version = "v", scope = "s", key = "k", name = "n", colour = "c", author = "a", stops = "p",
                   labels = "l", strokes = "d", marks = "x" },
        stroke = { "map", "width", "colour", "points" },
        mark = { "map", "x", "y", "kind", "colour", "label", "size" },
        -- A backup (kind backup): its routes by their id, each as the addon keeps it.
        saved = { routes = "routes", id = "id", name = "name", scope = "scope", key = "key", colour = "color",
                  author = "author", stops = "points", strokes = "strokes", marks = "marks", map = "m", x = "x",
                  y = "y", label = "label", width = "w", colourOf = "c", points = "p", kind = "k", size = "s" },
        -- Its scopes: on a dungeon's map (its key; the maps its charts) or on the game's maps.
        chart = "chart", world = "world",
        limits = { stops = 300, strokes = 200, points = 400, marks = 150, label = 80, name = 60, author = 48 },
        widths = { 2, 4, 7 },
        colours = { { 0.40, 0.70, 1.00 }, { 1.0, 0.72, 0.30 }, { 0.95, 0.40, 0.55 }, { 0.50, 0.90, 0.40 },
                    { 0.75, 0.55, 1.0 }, { 0.95, 0.95, 0.95 }, { 0.98, 0.30, 0.25 }, { 0.30, 0.90, 0.85 } },
        -- Its colours as ours, one to one in its order (Saneroki, 2026-11-16: "expand to 8 colours and 3 lines and other
        -- stuff so we are as compatible as possible"); its widths are our three (thin, medium, thick) in turn; its words'
        -- four sizes (2 its usual) are our four (0 small to 3 huge: "add a fourth text size so their smallest matches
        -- too"), and ours its.
        colourKeys = { "blue", "gold", "pink", "green", "purple", "white", "red", "teal" },
        textSizes = { 0, 1, 2, 3 }, ourTextSizes = { [0] = 1, 2, 3, 4 }, textSize = 2,
        -- Its marks: words (text), and the rest by the key of our markers' icon nearest in meaning.
        text = "text",
        marks = { skull = "boss", swords = "attack", shield = "shield", heal = "heal", aoe = "danger", warn = "warning",
                  eye = "lookout", patrol = "watch", sleep = "sleep", chest = "chest", stairs = "up", door = "door",
                  flag = "rally", finish = "finish", arrow = "arrow", cross = "no", star = "elite",
                  question = "unknown", rt1 = "star", rt2 = "circle", rt3 = "diamond", rt4 = "triangle", rt5 = "moon",
                  rt6 = "square", rt7 = "cross", rt8 = "skull", c_warrior = "warrior", c_paladin = "paladin",
                  c_hunter = "hunter", c_rogue = "rogue", c_priest = "priest", c_shaman = "shaman", c_mage = "mage",
                  c_warlock = "warlock", c_druid = "druid", r_tank = "tank", r_healer = "healer",
                  r_damage = "damage" },
        -- Ours by its mark (where two of its marks are one icon of ours, the one meant); an icon not here: unknown.
        icons = { boss = "skull", attack = "swords", shield = "shield", heal = "heal", tank = "r_tank",
                  healer = "r_healer", damage = "r_damage",
                  danger = "aoe", threat = "aoe", warning = "warn", trap = "warn", lookout = "eye", watch = "patrol",
                  sleep = "sleep", sheep = "sleep", chest = "chest", key = "chest", up = "stairs", down = "stairs",
                  door = "door", locked = "door", portal = "door", rally = "flag", safe = "flag", finish = "finish",
                  arrow = "arrow", turn = "arrow", onmyway = "arrow", jump = "arrow", no = "cross", elite = "star",
                  unknown = "question", star = "rt1", circle = "rt2", diamond = "rt3", triangle = "rt4",
                  moon = "rt5", square = "rt6", cross = "rt7", skull = "rt8", warrior = "c_warrior",
                  paladin = "c_paladin", hunter = "c_hunter", rogue = "c_rogue", priest = "c_priest",
                  shaman = "c_shaman", mage = "c_mage", warlock = "c_warlock", druid = "c_druid" },
        unknown = "question",
        -- Its dungeons' maps (its charts) as our floors (Core's set Dungeons, "<instance>:<floor>"), each with its
        -- dungeon's key; the map's 0 to 1 is the floor's, but where fit says x' = a x + b y + c, y' = d x + e y + f
        -- (a map cut from the game's terrain, laid by the tiles' places in Core's set DungeonGround). Matched by the
        -- game's map art files (the same tiles laid out alike); its maps of pictures of its own (Excavation Site,
        -- City of Dalaran, its Wailing Caverns) and the Hall of Thanes (its tiles placed nowhere we know) left out.
        -- Where two of its dungeons share charts (the Blackrock Spire's two), the first.
        charts = {
            [213] = { floor = "389:1", key = "ragefire" },
            [219] = { floor = "209:1", key = "zulfarrak" },
            [220] = { floor = "109:1", key = "sunken" },
            [221] = { floor = "48:1", key = "blackfathom" },
            [222] = { floor = "48:2", key = "blackfathom" },
            [223] = { floor = "48:3", key = "blackfathom" },
            [225] = { floor = "34:1", key = "stockade" },
            [226] = { floor = "90:1", key = "gnomeregan" },
            [227] = { floor = "90:2", key = "gnomeregan" },
            [228] = { floor = "90:3", key = "gnomeregan" },
            [229] = { floor = "90:4", key = "gnomeregan" },
            [230] = { floor = "70:1", key = "uldaman" },
            [231] = { floor = "70:2", key = "uldaman" },
            [235] = { floor = "429:1", key = "dm_north" },
            [236] = { floor = "429:2", key = "dm_west" },
            [237] = { floor = "429:3", key = "dm_west" },
            [238] = { floor = "429:4", key = "dm_west" },
            [239] = { floor = "429:5", key = "dm_east" },
            [240] = { floor = "429:6", key = "dm_east" },
            [242] = { floor = "230:1", key = "brd" },
            [243] = { floor = "230:2", key = "brd" },
            [250] = { floor = "229:1", key = "lbrs" },
            [251] = { floor = "229:2", key = "lbrs" },
            [252] = { floor = "229:3", key = "lbrs" },
            [253] = { floor = "229:4", key = "lbrs" },
            [254] = { floor = "229:5", key = "lbrs" },
            [255] = { floor = "229:6", key = "lbrs" },
            [280] = { floor = "349:1", key = "maraudon" },
            [281] = { floor = "349:2", key = "maraudon" },
            [291] = { floor = "36:1", key = "deadmines" },
            [292] = { floor = "36:2", key = "deadmines" },
            [300] = { floor = "129:1", key = "downs" },
            [301] = { floor = "47:1", key = "kraul" },
            [302] = { floor = "189:1", key = "sm_graveyard" },
            [303] = { floor = "189:2", key = "sm_library" },
            [304] = { floor = "189:3", key = "sm_armory" },
            [305] = { floor = "189:4", key = "sm_cathedral" },
            [306] = { floor = "289:1", key = "scholomance" },
            [307] = { floor = "289:2", key = "scholomance" },
            [308] = { floor = "289:3", key = "scholomance" },
            [309] = { floor = "289:4", key = "scholomance" },
            [310] = { floor = "33:1", key = "shadowfang" },
            [311] = { floor = "33:2", key = "shadowfang" },
            [312] = { floor = "33:3", key = "shadowfang" },
            [313] = { floor = "33:4", key = "shadowfang" },
            [314] = { floor = "33:5", key = "shadowfang" },
            [315] = { floor = "33:6", key = "shadowfang" },
            [316] = { floor = "33:7", key = "shadowfang" },
            [317] = { floor = "329:1", key = "stratholme" },
            [318] = { floor = "329:2", key = "stratholme" },
            [2999] = { floor = "2999:1", key = "lordaeron", fit = { 1.74532, 0, -0.4065, 0, 1.01811, -0.02728 } },
        } },
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

-- A known guide's text format: its words by ours, copies (nothing of theirs is kept); nil for one with none.
function Neighbours.Format(key)
    local known = Neighbours.KNOWN[key]
    if not known or not known.commands then return nil end
    local words = { commands = {}, marks = {}, modes = {}, colours = {} }
    for theirs, ours in pairs(known.commands) do words.commands[theirs] = ours end
    for theirs, ours in pairs(known.marks) do words.marks[theirs] = ours end
    for _, mark in ipairs(known.modes) do words.modes[mark] = true end
    for ours, theirs in pairs(known.colours) do words.colours[ours] = theirs end
    words.gameTags = {}
    for tag, game in pairs(known.gameTags or {}) do words.gameTags[tag] = game end
    return words
end

-- How a known guide's import strings are locked to the buyer's account: a copy of its recipe; nil for one with none.
function Neighbours.Lock(key)
    local known = Neighbours.KNOWN[key]
    if not known or not known.lock then return nil end
    local recipe = {}
    for name, value in pairs(known.lock) do recipe[name] = value end
    recipe.taps = { unpack(known.lock.taps) }
    return recipe
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, each in pairs(value) do copy[key] = Copy(each) end
    return copy
end

-- A known addon's way of sharing map drawings: a copy of its words; nil for one with none.
function Neighbours.Sketches(key)
    local known = Neighbours.KNOWN[key]
    if not known or not known.prefix or not known.charts then return nil end
    return Copy(known)
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
