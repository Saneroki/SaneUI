local ADDON = ...
local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Saved settings
--  What Core and every module keep between sessions.
--
--  All of it is one table, SaneUIDB, which the game writes to
--  WTF/Account/<account>/SavedVariables/SaneUI.lua:
--      SaneUIDB.modules.<Module>            what that module keeps besides its settings (Store)
--      SaneUIDB.modules.<Module>.chars      its notes per character (Character)
--      SaneUIDB.profiles.<Profile>.<Module> its settings, in a profile (Profiles.lua)
--      SaneUIDB.errors                      what went wrong (Core.errors)
--      SaneUIDB.log                         the same, every time it happened (Core.log)
--  and SaneUICharDB for the character played (its own settings, while Accountwide is off).
--
--  It is kept here, in the addon every module depends on, so that a module
--  finds its settings whichever other modules are switched on, and keeps them
--  while it is switched off itself.
--
--  A module describes its settings once (Options). Where they live is Profiles.lua's
--  business: the module holds one table of them for the whole session (Core.Settings,
--  also store.options), its values made right here (Settle) whenever they come into
--  use: brought up to date by the module's upgrade, every one of the right kind, the
--  ones no description has any more taken out. The options (Settings/) show them in
--  the game's options; a module may show or set them elsewhere too (Core.Set).
-------------------------------------------------------------------------------
local db -- SaneUIDB, once the game has read it

Core.described = {}   -- [module name] = { list = { option, ... }, keys, changed, capture, version, upgrade, ... }
Core.optionOrder = {} -- module names, in the order they described their switches

-- t[key] as a table: what is there if it is one, a new one if not. Saved data comes from older
-- versions and from hand edits, so a value of the wrong kind is replaced, not trusted.
local function Table(t, key)
    if type(t[key]) ~= "table" then t[key] = {} end
    return t[key]
end

-- store.options: the module's settings in use (Core.Settings). Found through the store, but not kept in
-- it: they are kept where Profiles.lua keeps them, and the game writes a table only once.
local function Alias(store, name)
    if getmetatable(store) == nil then
        setmetatable(store, { __index = function(_, key)
            if key == "options" then return Core.Settings(name) end
        end })
    end
    return store
end

-- What a module keeps between sessions. From OnLoad on.
function Core.Store(name)
    return Alias(Table(db.modules, name), name)
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

-- Whether two values are the same, tables by what they hold (a profile's copy is never the same table).
local function Same(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for key, value in pairs(a) do
        if not Same(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end
Core.Same = Same

-- Whether an option keeps a value: a button (an action) keeps none.
local function Keeps(option)
    return option.default ~= nil and not option.button
end

-- One switch made right: its default when it has none, one of the wrong kind, no choice of its own or
-- one its check (validate) refuses; a number within its ends. A table's default is copied: what is kept
-- in it later must not change the description.
local function Check(option, options)
    if not Keeps(option) then return end
    local value = options[option.key]
    local wrong = type(value) ~= type(option.default) or (option.choices and not option.multi and not Chosen(option, value))
    if not wrong and option.validate then
        local ok, fine = pcall(option.validate, value)
        wrong = not ok or not fine
    end
    if wrong then
        options[option.key] = Copy(option.default)
    elseif option.max and type(value) == "number" and (value < (option.min or value) or value > option.max) then
        options[option.key] = math.min(math.max(value, option.min or value), option.max)
    end
end

-- A module's settings made right for this version, wherever they come from (a profile, a character's
-- own, an older version, a hand edit): first the module's upgrade for a copy of an older shape (each copy
-- carries the version it was made right for, _version), then every switch checked (Check); what no
-- description has any more goes (the keys beginning with _ are Core's). Returns the values.
function Core.Settle(name, values)
    local described = Core.described[name]
    if not described or type(values) ~= "table" then return values end
    if described.version then
        local from = tonumber(values._version) or 0
        if from < described.version and described.upgrade then
            Core.Safe(name .. ": upgrade", described.upgrade, values, from)
        end
        values._version = described.version
    end
    for key in pairs(values) do
        if not (described.keys[key] or (type(key) == "string" and key:sub(1, 1) == "_")) then values[key] = nil end
    end
    for _, option in ipairs(described.list) do Check(option, values) end
    return values
end

-- What a description can get wrong, said once in the error log (not in chat: nothing the player can mend).
local function Described(name, list)
    local keys, seen = {}, {}
    for index, option in ipairs(list) do
        local problem
        if type(option.key) ~= "string" then
            problem = "an option without a key (#" .. index .. ")"
        elseif seen[option.key] then
            problem = "two options called " .. option.key
        elseif option.max and not option.min then
            problem = option.key .. " has an end but no start"
        elseif option.parent and type(option.parent) == "string" and not seen[option.parent] then
            problem = option.key .. " is under " .. option.parent .. ", which does not come before it"
        end
        if problem then Core.NoteError(name .. ": options", problem) end
        if type(option.key) == "string" then keys[option.key], seen[option.key] = true, true end
    end
    return keys
end

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
-- validate = function(value) return ok end: a value it refuses gets the default (at the load, Core.Set).
-- reload = true: the game shows a change only after a /reload, which is offered.
-- button = function() end: an action on the options page (no default, nothing kept).
-- multi = true (with choices, a table as default): several of the choices at once, [value] = true.
-- Call it while the files are read. Its third argument is a function, changed(key, value), or a table
-- of hooks:
--      changed(key, value)   a switch was changed: on the options page, by Core.Set, by another profile
--      replaced()            instead of changed: once, after the settings in use came from elsewhere
--                            (another profile, Accountwide switched), if any of them differs
--      moved()               after the settings in use came from elsewhere, changed or not
--      capture()             before the settings in use are copied or saved anywhere (a new profile, the
--                            logout): for settings that hold something of the game's own, to bring it up
--                            to date (Sync)
--      version, upgrade      the shape of the settings now (a number), and upgrade(values, from) that
--                            brings a copy of an older shape (from: 0 for none) up to it; it runs before
--                            the switches are checked, so a value whose kind changed can still be read
--      game = true           the settings are the game's own (Sync): kept in profiles only; while
--                            Accountwide is off they are no one's and not used
-- The fourth argument may still be capture. Returns the settings in use, once Core's are loaded.
function Core.Options(name, list, hooks, capture)
    if type(hooks) ~= "table" then hooks = { changed = hooks, capture = capture } end
    local described = { list = list, keys = Described(name, list) }
    for hook, value in pairs(hooks) do described[hook] = value end
    if not Core.described[name] then Core.optionOrder[#Core.optionOrder + 1] = name end
    Core.described[name] = described
    -- A module: its files are read after our settings are there, and its settings come into use at once.
    if db and Core.Profiles then return Core.Profiles.Arrive(name) end
    return nil
end

-- One of a module's switches as described; nil if it describes none of that key.
function Core.Described(name, key)
    local described = Core.described[name]
    if not described then return nil end
    for _, option in ipairs(described.list) do
        if option.key == key then return option end
    end
    return nil
end

-- The settings in use of a module: the table it holds for the whole session (from its OnLoad on).
function Core.Settings(name)
    return Core.Profiles and Core.Profiles.Live(name) or nil
end

-- The options page shows what changed elsewhere, a frame later (Settings.lua).
local Shown = Core.Later(function()
    if Core.Config and Core.Config.Refresh then Core.Config.Refresh() end
end)

-- Sets one of a module's switches from elsewhere than its options page (a menu, a command, a button):
-- written, made right as at the load (Check), the module told (changed) if it changed, a /reload
-- offered for a switch that needs one (reload = true), and the options page shows it. Returns the
-- value the switch has now.
function Core.Set(name, key, value)
    local option, options = Core.Described(name, key), Core.Settings(name)
    if not (option and options and Keeps(option)) then return nil end
    local before = Copy(options[key])
    options[key] = value
    Check(option, options)
    local now = options[key]
    if not Same(before, now) then
        local changed = Core.described[name].changed
        if changed then Core.Safe(name .. ": option", changed, key, now) end
        if option.reload and Core.AskReload then Core.AskReload({ option.text or key }) end
    end
    Shown()
    return now
end

-- Every switch of a module back to its default, as Core.Set does one: told, shown.
function Core.Reset(name)
    local described = Core.described[name]
    if not described then return end
    for _, option in ipairs(described.list) do
        if Keeps(option) then Core.Set(name, option.key, Copy(option.default)) end
    end
end

-- The general switches (Core.general): described here like a module's, shown on Sane UI's own pages
-- General and Appearance.
Core.Options(Core.name, {
    { key = "errors", default = true, text = "Errors in chat",
      tip = "Says in chat when something of Sane UI goes wrong: one line for each kind of problem. Switched off, the problems are still kept: type /sane errors." },
    { key = "animations", default = true, text = "Animations", page = "Appearance",
      header = "Windows", headerTip = "How Sane UI's windows move.",
      tip = "Sane UI's windows move, fade and slide. Off: everything is at once where it goes, in every module, whatever its own settings say." },
    { key = "motion", default = Core.Motion.DEFAULT, text = "Animation type", choices = Core.Motion.Choices(), page = "Appearance", parent = "animations",
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
    Move(db.perCharacter) -- (of the first shape of the settings: Profiles.lua takes them over)
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
    -- From before the settings were there: added to what was kept, a count to the count kept.
    for label, problem in pairs(Core.errors) do
        local kept = db.errors[label]
        if type(kept) == "table" and type(problem) == "table" then
            problem.count = (tonumber(problem.count) or 1) + (tonumber(kept.count) or 0)
        end
        db.errors[label] = problem
    end
    Core.errors = db.errors
    Table(db, "log")
    for _, entry in ipairs(Core.log) do db.log[#db.log + 1] = entry end -- likewise
    Core.log = db.log
    for name, store in pairs(db.modules) do
        if type(store) == "table" then Alias(store, name) else db.modules[name] = nil end
    end
    -- Profiles.lua listens after this (TOC order): it puts the settings of every module described so far
    -- (Core's, Sync's) in use, and Core.general with them.
end)
