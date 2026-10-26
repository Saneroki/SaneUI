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
