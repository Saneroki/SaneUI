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
-------------------------------------------------------------------------------
local Neighbours = {}
Core.Neighbours = Neighbours

-- The known addons, by the key a module asks with.
Neighbours.KNOWN = {
    -- A talent planner: its window is the Talents panel on Combat's full screen. It makes the window the
    -- first time it opens; its table's UI opens (Show) and closes (Hide) it.
    talents = { addon = "TalentsForeverBook", title = "Talents Forever", window = "TalentsForeverBookFrame",
                api = "TalentsForeverBook", open = "Show", close = "Hide" },
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
