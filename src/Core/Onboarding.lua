local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Onboarding
--  What each module hands in for its setup, step by step, and opening it.
--  The window is an addon of its own, SaneUI_Onboarding (src/Onboarding),
--  loaded on demand and shipped with Core (Saneroki, 2026-11-16: "both
--  onboarding and core always ships together"): its files are read only when
--  a setup opens. Each module keeps its own words (Saneroki, 2026-11-16): its
--  steps and the sample that shows them are the module's, handed in here
--  while its files are read; the window only draws them.
--
--      Core.Onboarding.Add(name, guide)  -- a module's setup (below)
--      Core.Onboarding.Open(name, step)  -- its window at that step (the first); after the fight in one
--      Core.Onboarding.Guide(name)       -- the setup a module handed in; nil for none
--      Core.Onboarding.Names()           -- the modules that handed one in, in that order
--      Core.Onboarding.Done(name)        -- whether this account went through it as it is now
--      Core.Onboarding.Due()             -- the setups still to go through, in their order
--      /sane setup <module>              -- the same, typed; /sane setup alone: those still to go through
--
--  All setups together (Saneroki, 2026-11-18: "it should remember which
--  onboardings the user went through and which onboardings still has to be
--  gone through"): a few seconds after the login (Onboarding.WAIT), out of a
--  fight, after the game's own What's new, the setups of the modules that are
--  on and not gone through yet open one after another in one window, the run
--  (Navigation's, then Tooltips' when both are new; "setup 1 of 2"). A setup
--  is gone through once its last step is done; closed before that it stays to
--  go through and opens again at the next login, at the step where it was
--  left, the others after it. Kept in the module Onboarding's store, for the
--  account and outside the profiles (SaneUIDB.modules.Onboarding: done[name] =
--  { version, day }, left[name] = the step): a profile loaded never brings
--  one back by itself; /sane setup and the button Set up step by step on the
--  module's options page (key setup, the window's words point there) do.
--
--  Its version (Saneroki, 2026-11-18: "a way to invalidate the old settings
--  so when we make big changes the user can go through the onboarding again
--  to setup its new settings"): a module that changes its setup a lot raises
--  the guide's version, and every account that went through an older one
--  goes through it again at its next login, told what changed (changed). The
--  settings the player chose stay: the setup shows the values in use.
--
--  A guide:
--      { title = "Nameplates",            -- the window's title
--        steps = { step, ... },           -- in their order
--        version = 2,                     -- raised after a big change (1 when it has none): gone through again
--        changed = "...",                 -- what that change is, said on its first step to whoever went
--                                         -- through an older version
--        Stage = function(stage, step, index) end }
--                                         -- draws the step's sample into stage (a frame of the window's),
--                                         -- when the step shows and again after each change of a setting
--  A step:
--      { key = "look", title = "...", text = "...", settings = { "style", "dot" } }
--                                         -- its head, its words, and the module's switches it shows by their
--                                         -- keys: each control has the switch's own words and tip (Core.Options)
-------------------------------------------------------------------------------
local Onboarding = {}
Core.Onboarding = Onboarding

Onboarding.ADDON = "SaneUI_Onboarding"
Onboarding.STORE = "Onboarding" -- the module's name: its store is SaneUIDB.modules.Onboarding
Onboarding.WAIT = 4             -- seconds after the loading screen before a setup opens by itself
Onboarding.TEXT = {
    command = "a module's setup, step by step: what it shows and how you want it (/sane setup nameplates)",
    later = "the setup opens after the fight.",
    missing = "the setup needs the addon Onboarding: tick it under Sane UI in the addon list.",
    none = "no module that is on has a setup yet.",
    list = "setups: %s. Type /sane setup and its name.",
    unknown = "no setup called %s. Setups: %s.",
}

local guides, order = {}, {} -- [module name] = its guide; the names in the order they came
local run                    -- the setups opened by themselves at the login, one after another; nil for none

function Onboarding.Add(name, guide)
    if type(name) ~= "string" or type(guide) ~= "table" or type(guide.steps) ~= "table" then
        Core.NoteError("onboarding", "a setup without a name or steps: " .. tostring(name))
        return
    end
    if not guides[name] then order[#order + 1] = name end
    guides[name] = guide
end

function Onboarding.Guide(name)
    return guides[name]
end

function Onboarding.Names()
    local names = {}
    for _, name in ipairs(order) do names[#names + 1] = name end
    return names
end

-- Whether a module's setup can show: handed in, and its module on (not stood down, not made for the other game).
local function Usable(name)
    local module = rawget(SaneUI, name)
    return guides[name] ~= nil and type(module) == "table" and not module.off
end

-- A setup's version: the guide's (whole, at least 1), raised by its module after a big change.
local function Version(name)
    local version = guides[name] and tonumber(guides[name].version)
    return version and math.max(math.floor(version), 1) or 1
end

-- What this account went through (done[name] = { version, day }) and where a setup not gone through yet was left
-- (left[name] = its step). The store of before (shown[name] = the day it first opened) counts as gone through, at 1.
local function Records()
    local store = Core.Store(Onboarding.STORE)
    if type(store.done) ~= "table" then store.done = {} end
    if type(store.left) ~= "table" then store.left = {} end
    if type(store.shown) == "table" then
        for name, day in pairs(store.shown) do
            if store.done[name] == nil then store.done[name] = { version = 1, day = type(day) == "string" and day or nil } end
        end
        store.shown = nil
    end
    return store
end

-- Whether this account went through a module's setup as it is now (its version, or a newer one).
function Onboarding.Done(name)
    local record = Records().done[name]
    return type(record) == "table" and (tonumber(record.version) or 0) >= Version(name)
end

-- Whether it went through an older version of it: the setup changed since (the window says what, guide.changed).
function Onboarding.Changed(name)
    return type(Records().done[name]) == "table" and not Onboarding.Done(name)
end

-- Whether a module's setup has something to show: usable, with steps.
local function Showable(name)
    return Usable(name) and type(guides[name].steps) == "table" and #guides[name].steps > 0
end

-- The setups still to go through, in their order: of modules that are on, not gone through as they are now.
function Onboarding.Due()
    local due = {}
    for _, name in ipairs(order) do
        if Showable(name) and not Onboarding.Done(name) then due[#due + 1] = name end
    end
    return due
end

-- The window tells Core each step it shows: kept for a setup not gone through yet, which opens there again.
function Onboarding.Reached(name, step)
    if guides[name] and not Onboarding.Done(name) then Records().left[name] = tonumber(step) end
end

-- The setup the run goes on to after this one (the next in it still to go through); nil out of a run or at its end.
function Onboarding.Following(name)
    if not run then return nil end
    local after = false
    for _, other in ipairs(run) do
        if after and Showable(other) and not Onboarding.Done(other) then return other end
        if other == name then after = true end
    end
    return nil
end

-- Where a setup stands in the run: its place and the run's length; nil out of one.
function Onboarding.Place(name)
    if not run then return nil end
    for index, other in ipairs(run) do
        if other == name then return index, #run end
    end
    return nil
end

-- The window's addon read (once); false where it cannot be (switched off in the addon list, not there).
local function Load()
    local addons = rawget(_G, "C_AddOns")
    if type(addons) ~= "table" then return false end
    if Core.Ask(addons.IsAddOnLoaded, Onboarding.ADDON) then return true end
    local loaded = Core.Ask(addons.LoadAddOn, Onboarding.ADDON)
    return loaded == true
end

-- The window on a module's setup. Out of a fight (Go waits for its end). Whether it shows.
local function Show(name, step, quiet)
    if not Load() then
        if not quiet then Core.Print(Onboarding.TEXT.missing) end
        return false
    end
    local window = rawget(SaneUI, "Onboarding")
    if type(window) ~= "table" or window.off or type(window.Show) ~= "function" then return false end
    return window.Show(name, step) == true
end

-- quiet: opened by itself (the run), so nothing is said if it cannot be.
local function Go(name, step, quiet)
    if not Usable(name) then return false end
    if not Core.AfterCombat("onboarding", Show, name, step, quiet) and not quiet then Core.Print(Onboarding.TEXT.later) end
    return true
end

-- Asked for (the options page's button, /sane setup <module>): that setup alone, at that step (the first).
function Onboarding.Open(name, step, quiet)
    run = nil
    return Go(name, step, quiet)
end

-- The setups still to go through, one after another in one window, each at the step where it was left.
function Onboarding.Start(quiet)
    local due = Onboarding.Due()
    if #due == 0 then return false end
    run = due
    return Go(due[1], Records().left[due[1]], quiet)
end

-- The window tells Core a setup was gone through to its end: kept with its version, and the run goes on to the
-- next one in the same window. Whether one follows (the window closes otherwise).
function Onboarding.Finished(name)
    if not guides[name] then return false end
    local following = Onboarding.Following(name)
    local store = Records()
    store.done[name] = { version = Version(name), day = date("%Y-%m-%d") }
    store.left[name] = nil
    if not following then return false end
    return Go(following, Records().left[following], true)
end

-- The run, a few seconds after the first loading screen; again a little later while the game's own What's new is
-- open. Once a session.
local Begin
local begin = Core.Later(function() Begin() end, Onboarding.WAIT, "onboarding")
function Begin()
    local splash = rawget(_G, "SplashFrame")
    if type(splash) == "table" and splash.IsShown and Core.Ask(splash.IsShown, splash) then return begin() end
    Onboarding.Start(true)
end

local looked = false
Core.On("PLAYER_ENTERING_WORLD", function()
    if looked then return end
    looked = true
    begin()
end)

-- A setup's name as typed ("nameplates", "Nameplates"): the module's name; nil for none.
local function Named(typed)
    typed = (typed or ""):lower()
    for _, name in ipairs(order) do
        if name:lower() == typed or (guides[name].title or ""):lower() == typed then return name end
    end
    return nil
end

Core.Command("setup", Onboarding.TEXT.command, function(rest)
    local usable = {}
    for _, name in ipairs(order) do
        if Usable(name) then usable[#usable + 1] = name end
    end
    if #usable == 0 then return Core.Print(Onboarding.TEXT.none) end
    rest = strtrim(rest or "")
    if rest == "" then
        -- Those still to go through, one after another; else the only one; else the list.
        if #Onboarding.Due() > 0 then return Onboarding.Start() end
        if #usable == 1 then return Onboarding.Open(usable[1]) end
        return Core.Print(Onboarding.TEXT.list:format(table.concat(usable, ", ")))
    end
    local name = Named(rest)
    if not name or not Usable(name) then
        return Core.Print(Onboarding.TEXT.unknown:format(rest, table.concat(usable, ", ")))
    end
    Onboarding.Open(name)
end)
