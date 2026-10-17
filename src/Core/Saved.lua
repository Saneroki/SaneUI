local ADDON = ...
local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Saved settings
--  What Core and every module keep between sessions.
--
--  All of it is one table, SaneUIDB, which the game writes to
--  WTF/Account/<account>/SavedVariables/SaneUI.lua:
--      SaneUIDB.modules.<Module>            what that module keeps (Store)
--      SaneUIDB.modules.<Module>.options    its switches (Options)
--      SaneUIDB.modules.<Module>.chars      its notes per character (Character)
--      SaneUIDB.modules.Core.options        the general switches
--      SaneUIDB.errors                      what went wrong (Core.errors)
--      SaneUIDB.log                         the same, every time it happened (Core.log)
--      SaneUIDB.profiles, SaneUIDB.account  profiles, and the account's settings kept aside
--                                           while a character has its own (Profiles.lua)
--
--  It is kept here, in the addon every module depends on, so that a module
--  finds its settings whichever other modules are switched on, and keeps them
--  while it is switched off itself.
--
--  A module describes its switches once (Options). They get their default and
--  are kept. The options (Settings/) show them as checkboxes
--  in the game's options; a module may show them elsewhere too.
-------------------------------------------------------------------------------
local db -- SaneUIDB, once the game has read it

Core.described = {}   -- [module name] = { list = { option, ... }, changed = fn }
Core.optionOrder = {} -- module names, in the order they described their switches

-- t[key] as a table: what is there if it is one, a new one if not. Saved data comes from older
-- versions and from hand edits, so a value of the wrong kind is replaced, not trusted.
local function Table(t, key)
    if type(t[key]) ~= "table" then t[key] = {} end
    return t[key]
end

-- What a module keeps between sessions. From OnLoad on.
function Core.Store(name)
    return Table(db.modules, name)
end

-- What a module keeps for the character you play. From OnLogin on.
function Core.Character(name)
    local char = Table(Table(Core.Store(name), "chars"), Core.charKey)
    char.name, char.class = Core.charName, Core.class
    return char
end

-- Whether a value is one of an option's choices.
local function Chosen(option, value)
    for _, choice in ipairs(option.choices) do
        if choice[1] == value then return true end
    end
    return false
end

-- A copy that shares no table with the original.
local function Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = Copy(inner) end
    return copy
end
Core.Copy = Copy

-- Every switch gets its default when it has none, or one of the wrong kind or no choice of its
-- own; a number one within its ends. A table's default is copied: what is kept in it later must
-- not change the description (nor the profile SaneUI Defaults, which is made from it).
local function Defaults(name)
    local options = Table(Core.Store(name), "options")
    for _, option in ipairs(Core.described[name].list) do
        local value = options[option.key]
        if type(value) ~= type(option.default) or (option.choices and not Chosen(option, value)) then
            options[option.key] = Copy(option.default)
        elseif option.max and (value < option.min or value > option.max) then
            options[option.key] = math.min(math.max(value, option.min), option.max)
        end
    end
end
Core.CheckOptions = Defaults -- also for switches copied in from a profile (Profiles.lua)

-- Core.Options("Abilities", { { key = "ghosts", default = true, text = "...", tip = "..." } }, changed)
-- A number instead of a switch has its ends too: { key = "after", default = 60, min = 5, max = 300, step = 5, ... }
-- One of a few instead: its choices, each a value and its words:
-- { key = "show", default = "shift", choices = { { "shift", "While Shift is held" }, { "always", "Always" } }, ... }
-- One without text is kept with the settings (in profiles too) but has no control: { key = "kept", default = {} }.
-- header = "..." (and headerTip) starts a section of the options page above the switch.
-- tab = "Appearance": the module's page is one of our own with tabs (as Profiles), the switch in that
-- tab; the switches that name none are in a first tab, General. A header there starts a box.
-- parent = "key" puts it under that switch, which must come before it: greyed out while that one, or
-- one it is under, is off. A list of keys (in tabs): greyed out while any of them is off. inline = true (in tabs): a number drawn on the line of its parent switch.
-- parentValue = "solid": under one of a few instead, greyed out while that one is not set to it.
-- color = true (in tabs): a colour, six hex digits as default ("26262B"), chosen with the game's picker.
-- unit = "seconds", "%": written after a number's value.
-- page = "Appearance" (Core's own switches only): on that page of Sane UI's instead of General.
-- Call it while the files are read. changed(key, value) runs after a switch was flipped on the
-- options page, or a profile changed it. capture(), if given, runs before the settings in use are
-- saved anywhere (a profile, the logout): for a module whose settings hold something of the game's
-- own, to bring it up to date (Sync).
function Core.Options(name, list, changed, capture)
    Core.described[name] = { list = list, changed = changed, capture = capture }
    Core.optionOrder[#Core.optionOrder + 1] = name
    if db then Defaults(name) end -- a module: its files are read after our settings
end

-- The general switches (Core.general): described here like a module's, shown on Sane UI's own pages
-- General and Appearance.
Core.Options(Core.name, {
    { key = "errors", default = true, text = "Errors in chat",
      tip = "Says in chat when something of Sane UI goes wrong: one line for each kind of problem. Switched off, the problems are still kept: type /sane errors." },
    { key = "motion", default = Core.Motion.DEFAULT, text = "Animation type", choices = Core.Motion.Choices(), page = "Appearance",
      header = "Windows", headerTip = "How Sane UI's windows move.",
      tip = "How Sane UI's windows move when they fill the screen from a screen edge and go back, and when they open while the mouse rests on them. Glide is quick and settles softly, Swing goes a little past and comes back, Even starts and ends gently, Instant does not move at all. A window can have its own, in its section Expand window (Social: tab Appearance)." },
})

-- Modules that were called otherwise once: [old name] = new name.
local RENAMED = { Chat = "Social", Spellbook = "Abilities" }

-- What was kept under a module's old name moves to its new one, once, wherever a module's name is a
-- key: its store, its line in each profile, the account's settings kept aside, the character's own.
local function Move(place)
    if type(place) ~= "table" then return end
    for old, new in pairs(RENAMED) do
        if place[new] == nil then place[new] = place[old] end
        place[old] = nil
    end
end
local function Rename(char)
    Move(db.modules)
    Move(db.perCharacter)
    Move(db.account)
    if type(char) == "table" then Move(char.settings) end
    if type(db.profiles) == "table" then
        for _, profile in pairs(db.profiles) do Move(profile) end
    end
end

-- Our own addon is loaded: the game has read SaneUIDB. Every module's addon comes after this one.
Core.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    if type(SaneUIDB) ~= "table" then SaneUIDB = {} end
    db = SaneUIDB
    Table(db, "modules")
    Rename(rawget(_G, "SaneUICharDB"))
    Table(db, "errors")
    for label, problem in pairs(Core.errors) do db.errors[label] = problem end -- from before the settings were there
    Core.errors = db.errors
    Table(db, "log")
    for _, entry in ipairs(Core.log) do db.log[#db.log + 1] = entry end -- likewise
    Core.log = db.log
    for _, module in ipairs(Core.optionOrder) do Defaults(module) end -- ours: described before the settings were there
    Core.general = Core.Store(Core.name).options
end)
