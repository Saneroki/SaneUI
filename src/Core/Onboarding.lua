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
--      /sane setup <module>              -- the same, typed
--
--  The first time a module with a setup is on (on this account), its setup
--  opens by itself a few seconds after the login (Onboarding.WAIT), out of a
--  fight, after the game's own What's new, one a session. That it was shown is
--  kept in the module Onboarding's store, for the account and outside the
--  profiles (SaneUIDB.modules.Onboarding.shown[name], the day): a profile
--  loaded never brings it back by itself; /sane setup and the button on the
--  module's options page do.
--
--  A guide:
--      { title = "Nameplates",            -- the window's title
--        steps = { step, ... },           -- in their order
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

-- The setups shown so far on this account: [name] = the day.
local function Shown()
    local store = Core.Store(Onboarding.STORE)
    if type(store.shown) ~= "table" then store.shown = {} end
    return store.shown
end

-- The window's addon read (once); false where it cannot be (switched off in the addon list, not there).
local function Load()
    local addons = rawget(_G, "C_AddOns")
    if type(addons) ~= "table" then return false end
    if Core.Ask(addons.IsAddOnLoaded, Onboarding.ADDON) then return true end
    local loaded = Core.Ask(addons.LoadAddOn, Onboarding.ADDON)
    return loaded == true
end

-- The window on a module's setup; the setup kept as shown. Out of a fight (Open waits for its end).
local function Show(name, step, quiet)
    if not Load() then
        if not quiet then Core.Print(Onboarding.TEXT.missing) end
        return
    end
    local window = rawget(SaneUI, "Onboarding")
    if type(window) ~= "table" or window.off or type(window.Show) ~= "function" then return end
    if window.Show(name, step) then Shown()[name] = date("%Y-%m-%d") end
end

-- quiet: opened by itself (the first time), so nothing is said if it cannot be.
function Onboarding.Open(name, step, quiet)
    if not Usable(name) then return false end
    if not Core.AfterCombat("onboarding", Show, name, step, quiet) and not quiet then Core.Print(Onboarding.TEXT.later) end
    return true
end

-- The first setup not shown yet, a few seconds after the first loading screen; again a little later while the
-- game's own What's new is open.
local Due
local due = Core.Later(function() Due() end, Onboarding.WAIT, "onboarding")
function Due()
    local splash = rawget(_G, "SplashFrame")
    if type(splash) == "table" and splash.IsShown and Core.Ask(splash.IsShown, splash) then return due() end
    local shown = Shown()
    for _, name in ipairs(order) do
        if Usable(name) and not shown[name] then
            Onboarding.Open(name, 1, true)
            return
        end
    end
end

local looked = false
Core.On("PLAYER_ENTERING_WORLD", function()
    if looked then return end
    looked = true
    due()
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
        if #usable == 1 then return Onboarding.Open(usable[1]) end
        return Core.Print(Onboarding.TEXT.list:format(table.concat(usable, ", ")))
    end
    local name = Named(rest)
    if not name or not Usable(name) then
        return Core.Print(Onboarding.TEXT.unknown:format(rest, table.concat(usable, ", ")))
    end
    Onboarding.Open(name)
end)
