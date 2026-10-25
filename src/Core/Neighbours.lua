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
    guide = { addon = "RXPGuides", title = "RestedXP", stub = "LibStub", library = "AceAddon-3.0", part = "targeting",
              lists = "GetCurrentTargets", items = "activeItems", spells = "activeSpells" },
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
