local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Onboarding
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
--      Core.Onboarding.Done(name)        -- whether this account went through it (or chose its defaults) as it is now
--      Core.Onboarding.Due()             -- the setups still to go through, in their order
--      Core.Onboarding.Start(quiet, all) -- the run: its first page, then those still to go through (all: every
--                                         -- setup again, from its first step: /sane setup)
--      Core.Onboarding.Defaults(name, after) -- a setup's switches back to their defaults, kept as done
--      /sane setup <module>              -- the same, typed; /sane setup alone: the whole onboarding again
--                                         -- (Saneroki, 2026-11-18: "/sane setup does not restart the onboarding")
--
--  All setups together (Saneroki, 2026-11-18: "it should remember which
--  onboardings the user went through and which onboardings still has to be
--  gone through"): a few seconds after the login (Onboarding.WAIT), out of a
--  fight, after the game's own What's new, the setups of the modules that are
--  on and not gone through yet open one after another in one window, the run
--  (Navigation's, then Tooltips' when both are new; "setup 1 of 2"), after a
--  first page that lists them (Saneroki, 2026-11-18: "a very first page where
--  all the onboardings that still need to go through is listed"). A setup is
--  gone through once its last step is done; closed before that it stays to go
--  through and opens again at the next login, at the step where it was left,
--  the others after it. Choose defaults, on the first page's rows and in each
--  setup (Saneroki, 2026-11-18: "instead of skip it says Choose Defaults on
--  each of the onboardings"), sets the setup's switches back to their defaults
--  (asked first where some differ) and keeps it as done: it no longer opens by
--  itself. Kept in the module Onboarding's store, for the account and outside
--  the profiles (SaneUIDB.modules.Onboarding: done[name] = { version, day,
--  defaults }, left[name] = the step): a profile loaded never brings one back
--  by itself; /sane setup and the button Set up step by step on the module's
--  options page (key setup, the window's words point there) do.
--
--  Its version (Saneroki, 2026-11-18: "a way to invalidate the old settings
--  so when we make big changes the user can go through the onboarding again
--  to setup its new settings"): a module that changes its setup a lot raises
--  the guide's version, and every account that went through (or chose the
--  defaults of) an older one goes through it again at its next login, told
--  what changed (changed). The settings the player chose stay: the setup shows the values
--  in use.
--
--  A guide:
--      { title = "Combat",                -- the window's title
--        steps = { step, ... },           -- in their order
--        version = 2,                     -- raised after a big change (1 when it has none): gone through again
--        changed = "...",                 -- what that change is, said on its first step to whoever went
--                                         -- through an older version
--        aliases = { nameplates = "size" }, -- other words /sane setup takes for it, each opening it at that step
--                                         -- (Combat's: the nameplates were a module of their own until 2026-11-18)
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
    command = "a module's setup, step by step: what it shows and how you want it (/sane setup combat)",
    later = "the setup opens after the fight.",
    missing = "the setup needs the addon Onboarding: tick it under SaneUI in the addon list.",
    none = "no module that is on has a setup yet.",
    unknown = "no setup called %s. Setups: %s.",
    defaults = "%s: set the choices of its setup back to SaneUI's defaults?",
    defaultsYes = "Choose defaults",
}

local guides, order = {}, {} -- [module name] = its guide; the names in the order they came
local run                    -- the setups opened by themselves at the login, one after another; nil for none
local again                  -- a run asked for again (/sane setup): [name] = true once passed in it; nil otherwise

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

-- Whether this account went through a module's setup as it is now (its version, or a newer one), or chose its
-- defaults: it no longer opens by itself.
function Onboarding.Done(name)
    local record = Records().done[name]
    return type(record) == "table" and (tonumber(record.version) or 0) >= Version(name)
end

-- Whether it went through an older version of it (or chose its defaults): the setup changed since (the window says
-- what, guide.changed).
function Onboarding.Changed(name)
    return type(Records().done[name]) == "table" and not Onboarding.Done(name)
end

-- Whether it chose the defaults of the setup as it is now, and has not gone through it since.
function Onboarding.Defaulted(name)
    return Onboarding.Done(name) and Records().done[name].defaults == true
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

-- Whether a setup is still to go through: in a run asked for again, not passed in it yet (gone through before or
-- not); else not gone through as it is now.
function Onboarding.Pending(name)
    if again and Onboarding.Place(name) then return not again[name] end
    return not Onboarding.Done(name)
end

-- The setup the run goes on to after this one (the next in it still to go through); nil out of a run or at its end.
function Onboarding.Following(name)
    if not run then return nil end
    local after = false
    for _, other in ipairs(run) do
        if after and Showable(other) and Onboarding.Pending(other) then return other end
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

-- The window on a module's setup (name nil: the run's first page). Out of a fight (Go waits for its end). Whether
-- it shows.
local function Show(name, step, quiet)
    if not Load() then
        if not quiet then Core.Print(Onboarding.TEXT.missing) end
        return false
    end
    local window = rawget(SaneUI, "Onboarding")
    if type(window) ~= "table" or window.off or type(window.Show) ~= "function" then return false end
    if name == nil then return type(window.First) == "function" and window.First() == true end
    return window.Show(name, step) == true
end

-- quiet: opened by itself (the run), so nothing is said if it cannot be. name nil: the run's first page.
local function Go(name, step, quiet)
    if name ~= nil and not Usable(name) then return false end
    if not Core.AfterCombat("onboarding", Show, name, step, quiet) and not quiet then Core.Print(Onboarding.TEXT.later) end
    return true
end

-- Asked for (the options page's button, /sane setup <module>): that setup alone, at that step (the first).
function Onboarding.Open(name, step, quiet)
    run, again = nil, nil
    return Go(name, step, quiet)
end

-- The setups still to go through, one after another in one window: first the page that lists them, then each at
-- the step where it was left. all (/sane setup): the whole onboarding again, every setup of a module that is on,
-- gone through before or not, each from its first step; what is kept of them changes only as each is done again.
function Onboarding.Start(quiet, all)
    local names = {}
    if all then
        for _, name in ipairs(order) do
            if Showable(name) then names[#names + 1] = name end
        end
    else
        names = Onboarding.Due()
    end
    if #names == 0 then return false end
    run, again = names, all and {} or nil
    return Go(nil, nil, quiet)
end

-- The setups of the run, in their order (gone through or not); nil out of a run.
function Onboarding.Run()
    if not run then return nil end
    local names = {}
    for index, name in ipairs(run) do names[index] = name end
    return names
end

-- On from the run's first page: the first setup of the run still to go through, at the step where it was left.
-- Whether one shows (none left: false).
function Onboarding.Continue()
    for _, name in ipairs(run or {}) do
        if Showable(name) and Onboarding.Pending(name) then
            return Go(name, not again and Records().left[name] or nil, true)
        end
    end
    return false
end

-- Kept as gone through (or its defaults chosen, defaults), with its version and the day; passed in a run asked for
-- again.
local function Mark(name, defaults)
    if again then again[name] = true end
    local store = Records()
    store.done[name] = { version = Version(name), day = date("%Y-%m-%d"), defaults = defaults and true or nil }
    store.left[name] = nil
end

-- The window tells Core a setup was gone through to its end: kept with its version, and the run goes on to the next
-- one in the same window. Whether one follows (the window closes otherwise).
function Onboarding.Finished(name)
    if not guides[name] then return false end
    local following = Onboarding.Following(name)
    Mark(name)
    if not following then return false end
    return Go(following, not again and Records().left[following] or nil, true)
end

-- Whether two values are the same (tables by their contents).
local function Same(one, other)
    if type(one) ~= "table" or type(other) ~= "table" then return one == other end
    for key, value in pairs(one) do
        if not Same(value, other[key]) then return false end
    end
    for key in pairs(other) do
        if one[key] == nil then return false end
    end
    return true
end

-- The module's switches a setup shows (its steps' settings: a key, or a step's own wording of one; keys of the game's
-- key bindings are not among them).
local function Switches(name)
    local keys = {}
    for _, step in ipairs(guides[name] and guides[name].steps or {}) do
        for _, entry in ipairs(type(step.settings) == "table" and step.settings or {}) do
            local key = type(entry) == "string" and entry or type(entry) == "table" and type(entry.key) == "string"
                and entry.key
            if key then keys[key] = true end
        end
    end
    return keys
end

-- Choose defaults (Saneroki, 2026-11-18: "instead of skip it says Choose Defaults on each of the onboardings"): the
-- setup's switches back to their defaults (Core.Reset; the game's key bindings stay), kept as done with its defaults
-- chosen, then after(). Where some of them differ from their defaults (chosen before, a setup of a new version), the
-- game's yes or no asks first; no: nothing changes. Whether it was done at once.
function Onboarding.Defaults(name, after)
    if not guides[name] then return false end
    local keys, options, differ = Switches(name), Core.Settings(name) or {}, false
    for key in pairs(keys) do
        local option = Core.Described(name, key)
        if option and option.default ~= nil and not Same(options[key], option.default) then differ = true end
    end
    local function Chosen()
        Core.Reset(name, function(option) return keys[option.key] == true end)
        Mark(name, true)
        if type(after) == "function" then Core.Safe("onboarding", after) end
    end
    if not differ then
        Chosen()
        return true
    end
    Core.Confirm(Onboarding.TEXT.defaults, guides[name].title or name, Chosen, false, Onboarding.TEXT.defaultsYes)
    return false
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

-- A setup's name as typed ("combat", "Combat"): the module's name, and the step a word of its aliases opens it at
-- ("nameplates": Combat's at its first step of the nameplates); nil for none.
local function Named(typed)
    typed = (typed or ""):lower()
    for _, name in ipairs(order) do
        local guide = guides[name]
        if name:lower() == typed or (guide.title or ""):lower() == typed then return name end
        local key = type(guide.aliases) == "table" and guide.aliases[typed]
        if key then
            for index, step in ipairs(guide.steps) do
                if step.key == key then return name, index end
            end
            return name
        end
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
    -- Alone: the whole onboarding again, its first page and every setup (Saneroki, 2026-11-18: "/sane setup does not
    -- restart the onboarding": it opened only those still to go through, and listed them once all were done).
    if rest == "" then return Onboarding.Start(false, true) end
    local name, step = Named(rest)
    if not name or not Usable(name) then
        return Core.Print(Onboarding.TEXT.unknown:format(rest, table.concat(usable, ", ")))
    end
    Onboarding.Open(name, step)
end)
