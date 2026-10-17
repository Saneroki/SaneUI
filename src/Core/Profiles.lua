local ADDON = ...
local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Profiles
--  Whose settings are in use, and where they live (Saneroki, 2026-10-17).
--
--  Accountwide (on at first): every character uses a profile, a named set of
--  the settings of every module and of the game's own settings Sync keeps
--  (CVars, Edit Mode layout, chat windows, ...). At first there is one,
--  Accountwide, used by every character, so all of them have the same
--  settings: the game's are set from it when a character comes into the world,
--  and read back into it when the character leaves. More profiles can be made
--  and given to characters, each to its own.
--  Accountwide off: no profile is in use. Each character keeps its own Sane UI
--  settings, which start as a copy of its profile's; the game's settings are
--  left to the game.
--
--  Each module's settings live in one place only, the one in use: a profile,
--  or the character's own. The module holds that table for the whole session
--  (Core.Settings). Changing the place (another profile, Accountwide switched)
--  leaves a copy of the settings in the old place and fills the table from the
--  new one, then tells each module what changed (its changed or replaced).
--  Nothing is put back at the logout: the game writes the saved settings as
--  they are, after the modules that hold something of the game's (Sync) have
--  brought it up to date (their capture).
--
--      SaneUIDB.version      the shape of these settings (Profiles.VERSION)
--      SaneUIDB.accountwide  false: switched off (nil: on)
--      SaneUIDB.profiles     [name] = { [module] = its settings }; Accountwide is always there
--      SaneUIDB.characters   [key] = { name, realm, class, profile }: every character seen;
--                            profile nil: Accountwide
--      SaneUIDB.newProfile   the profile a character not seen yet starts with (nil: Accountwide)
--      SaneUIDB.ownSince     when Accountwide was last switched off: a character's own settings
--                            from before then start anew from its profile's
--      SaneUICharDB.settings [module] = this character's own settings (Accountwide off)
--      SaneUICharDB.since    the ownSince its settings were made under
--      SaneUICharDB.key      this character's key, to find its line before the game names it
--
--  Every step that can be refused returns true, or false and why not (a line for chat).
-------------------------------------------------------------------------------
local Profiles = {}
Core.Profiles = Profiles

Profiles.VERSION = 2       -- 1: the account's settings, a character's own, profiles copied in and out
Profiles.ACCOUNTWIDE = "Accountwide"
Profiles.NEW = "new"       -- the line of the characters not seen yet (Character, SetCharacter)
Profiles.MAX_NAME = 32     -- letters in a profile's name
Profiles.EXPORT = "Sane UI profile" -- what an exported text says it is

local ACCOUNTWIDE, NEW = Profiles.ACCOUNTWIDE, Profiles.NEW

local TEXT = {
    noName = "a profile needs a name.",
    taken = "there is already a profile called %s.",
    missing = "there is no profile called %s.",
    fixed = "the profile Accountwide is always there: it cannot be renamed or deleted.",
    about = "the profiles: /sane profile lists them, /sane profile <name> is this character's from now on",
    list = "profiles: %s. This character uses %s.",
    listOff = "profiles: %s. Accountwide settings are off: each character keeps its own settings.",
    using = "this character uses the profile %s.",
    off = "Accountwide is switched off: each character keeps its own settings, and no profile is in use.",
    current = "that is the character you are playing.",
    unknown = "Sane UI has not seen that character.",
    notProfile = "that is no Sane UI profile.",
    old = "%s (old)",
    older = "%s (old %d)",
}

local Copy, Same = Core.Copy, Core.Same

local db, char       -- SaneUIDB and SaneUICharDB, once the game has read them
local live = {}      -- [module] = the table of its settings it holds this session
local session = {}   -- [module] = the game's settings while Accountwide is off: no one's, never saved
local source         -- where the settings in use live: a profile's name; nil: the character's own
local key            -- this character's key (its GUID)

local function Table(t, name)
    if type(t[name]) ~= "table" then t[name] = {} end
    return t[name]
end

-- The options page shows what changed, a frame later.
local Shown = Core.Later(function()
    if Core.Config and Core.Config.Refresh then Core.Safe("profiles: the options", Core.Config.Refresh) end
end)

-- Whether a module's settings are the game's own (Sync's): those live in profiles only.
local function Game(name)
    local described = Core.described[name]
    return described and described.game and true or false
end

-- A saved profile; nil if there is none of that name.
local function Saved(name)
    local profile = type(name) == "string" and db.profiles[name]
    return type(profile) == "table" and profile or nil
end

-- A profile's name as typed, without the spaces around it; nil if nothing is left.
local function Name(text)
    if type(text) ~= "string" then return nil end
    text = strtrim(text)
    if text == "" then return nil end
    return text
end

-------------------------------------------------------------------------------
--  Characters
-------------------------------------------------------------------------------
-- A character's line (this character's when which is not given); nil if it was never seen.
local function Line(which)
    which = which or key
    local line = which and db.characters[which]
    return type(line) == "table" and line or nil
end

-- The profile a line names, if it is still there; else Accountwide.
local function Assigned(line)
    local name = line and line.profile
    if Saved(name) then return name end
    return ACCOUNTWIDE
end

-- A character not seen before gets its line, with the profile for new characters. Returns whether it was new.
local function Register(which)
    if not which or Line(which) then return false end
    db.characters[which] = { profile = Saved(db.newProfile) and db.newProfile or nil }
    return true
end

-------------------------------------------------------------------------------
--  Where the settings live
-------------------------------------------------------------------------------
function Profiles.On()
    return db == nil or db.accountwide ~= false
end

-- Where this character's settings should live now: its profile, or (Accountwide off) its own.
local function Want()
    if not Profiles.On() then return nil end
    return Assigned(Line())
end

-- This character's own settings, made anew from its profile's when they are from before Accountwide
-- was last switched off (or there are none).
local function Own()
    if char.since ~= db.ownSince or type(char.settings) ~= "table" then
        char.settings, char.since = {}, db.ownSince
        for name, values in pairs(Saved(Assigned(Line())) or {}) do
            if type(values) == "table" and not Game(name) then char.settings[name] = Copy(values) end
        end
    end
    return char.settings
end

-- The table that holds every module's settings in a place (a profile's name; nil: this character's
-- own) for that module: the game's own, while Accountwide is off, are kept nowhere.
local function Holder(place, name)
    if place then return Table(db.profiles, place) end
    if Game(name) then return session end
    return Own()
end

-- A module's settings kept in a place; nil if it has none there. A character's own that lack a module
-- (installed since) take a copy of its profile's.
local function Kept(place, name)
    local values = Holder(place, name)[name]
    if type(values) ~= "table" and not place and not Game(name) then
        values = Copy(Saved(Assigned(Line())) and Saved(Assigned(Line()))[name])
    end
    return type(values) == "table" and values or nil
end

-- A module's settings come into use: from where they live now, made right for this version, held by
-- the module from now on (Saved.lua: Core.Options).
local function Bind(name)
    if live[name] then return live[name] end
    local values = Kept(source, name) or {}
    Holder(source, name)[name] = values
    Core.Settle(name, values)
    live[name] = values
    return values
end

-- The modules that keep something of the game's own (Sync) bring it up to date.
local function Capture()
    for _, name in ipairs(Core.optionOrder) do
        local described = Core.described[name]
        if live[name] and described.capture then Core.Safe(name .. ": saving", described.capture) end
    end
end
Profiles.Capture = Capture

-- Each module is told what differs between before and the settings it holds now.
local function Tell(name, before)
    local described, values = Core.described[name], live[name]
    if described.replaced then
        if not Same(before, values) then Core.Safe(name .. ": settings", described.replaced) end
    elseif described.changed then
        for _, option in ipairs(described.list) do
            if option.key and not Same(before[option.key], values[option.key]) then
                Core.Safe(name .. ": option", described.changed, option.key, values[option.key])
            end
        end
    end
end

-- Puts the settings of every module in use into a table: each module's from values (a copy), made
-- right, the modules told; each module told it moved (moved) once all have theirs.
local function Fill(fill)
    local before = {}
    for _, name in ipairs(Core.optionOrder) do
        local values = live[name]
        if values then
            local new = fill(name)
            if new ~= false then
                before[name] = Copy(values)
                wipe(values)
                for k, v in pairs(new or {}) do values[k] = Copy(v) end
                Core.Settle(name, values)
            end
        end
    end
    for _, name in ipairs(Core.optionOrder) do
        if before[name] then Tell(name, before[name]) end
    end
    for _, name in ipairs(Core.optionOrder) do
        local moved = live[name] and Core.described[name].moved
        if moved then Core.Safe(name .. ": settings", moved) end
    end
    Shown()
end

-- The settings in use move to another place: what the modules hold now stays in the old place as a
-- copy of its own, and the tables they hold take what the new place has.
local function Move(to)
    if to == source then return end
    Capture()
    for name, values in pairs(live) do Holder(source, name)[name] = Copy(values) end
    source = to
    Fill(function(name)
        local new = Kept(to, name)
        Holder(to, name)[name] = live[name]
        return new
    end)
end

-------------------------------------------------------------------------------
--  The first shape of these settings, brought over once (an earlier version of Sane UI)
-------------------------------------------------------------------------------
-- Before: the account's settings in modules.<Module>.options (or kept aside in account while a
-- character used other ones), profiles copied in at login and out at logout where a character's line
-- said so (autoLoad, autoSave), All settings accountwide (separate: unticked) and each module's own
-- switch (perCharacter, which has no place now: what a character kept that way goes).
local function Free(name)
    if db.profiles[name] == nil then return name end
    local free, count = TEXT.old:format(name), 1
    while db.profiles[free] ~= nil do
        count = count + 1
        free = TEXT.older:format(name, count)
    end
    return free
end

local function Stamp(values, version)
    if type(values) == "table" and values._version == nil and type(version) == "number" then values._version = version end
end

local function Upgrade()
    if db.version == Profiles.VERSION then return end
    local profiles = Table(db, "profiles")
    local account = {}
    for name, store in pairs(db.modules) do
        local values = type(store) == "table" and rawget(store, "options")
        if type(values) == "table" then account[name] = values end
        if type(store) == "table" then rawset(store, "options", nil) end
    end
    if type(db.account) == "table" then
        for name, values in pairs(db.account) do
            if type(values) == "table" then account[name] = values end
        end
    end
    if profiles[ACCOUNTWIDE] ~= nil then profiles[Free(ACCOUNTWIDE)] = profiles[ACCOUNTWIDE] end
    profiles[ACCOUNTWIDE] = account
    -- A module that counted the shape of its settings itself (store.version): its copies carry it now.
    for name, store in pairs(db.modules) do
        local version = type(store) == "table" and rawget(store, "version")
        Stamp(account[name], version)
        for _, profile in pairs(profiles) do Stamp(type(profile) == "table" and profile[name], version) end
    end
    for which, line in pairs(type(db.characters) == "table" and db.characters or {}) do
        if type(line) == "table" then
            if not (line.autoLoad and line.profile ~= ACCOUNTWIDE and Saved(line.profile)) then line.profile = nil end
            line.autoLoad, line.autoSave = nil, nil
        else
            db.characters[which] = nil
        end
    end
    local new = db.newCharacters
    db.newProfile = type(new) == "table" and new.autoLoad and Saved(new.profile) and new.profile or nil
    if db.separate == true then db.accountwide, db.ownSince = false, 1 end
    db.separate, db.perCharacter, db.account, db.newCharacters = nil, nil, nil, nil
    db.version = Profiles.VERSION
end

-- This character's file of the first shape: its own settings count only if no setting was account
-- wide then (they were all its own: the first Accountwide off, ownSince 1).
local function UpgradeCharacter()
    if char.version == Profiles.VERSION then return end
    if type(char.settings) == "table" and db.ownSince == 1 then
        char.since = 1
        for name, values in pairs(char.settings) do
            local store = db.modules[name]
            Stamp(values, type(store) == "table" and rawget(store, "version"))
        end
    else
        char.settings = nil
    end
    char.profile, char.own, char.autoLoad, char.autoSave = nil, nil, nil, nil
    char.version = Profiles.VERSION
end

-- What the saved file holds made right (an older version, a hand edit).
local function Mend()
    Table(db, "profiles")
    Table(db, "characters")
    for name, profile in pairs(db.profiles) do
        if type(name) ~= "string" or type(profile) ~= "table" then db.profiles[name] = nil end
    end
    Table(db.profiles, ACCOUNTWIDE)
    if db.accountwide ~= false then db.accountwide = nil end
    if type(db.ownSince) ~= "number" then db.ownSince = nil end
    if db.accountwide == false and not db.ownSince then db.ownSince = 1 end
    if not Saved(db.newProfile) or db.newProfile == ACCOUNTWIDE then db.newProfile = nil end
    if type(char.settings) ~= "table" then char.settings = nil end
    if type(char.since) ~= "number" then char.since = nil end
    if type(char.key) ~= "string" then char.key = nil end
end

-------------------------------------------------------------------------------
--  The session
-------------------------------------------------------------------------------
-- Our own addon is loaded: the game has read both files (Saved.lua made SaneUIDB right just before).
-- Before any module reads its settings, they come from where this character's should.
Core.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    db = SaneUIDB
    if type(SaneUICharDB) ~= "table" then SaneUICharDB = {} end
    char = SaneUICharDB
    Upgrade()
    UpgradeCharacter()
    Mend()
    key = Core.Plain(UnitGUID("player")) or char.key
    Register(key)
    wipe(live)
    wipe(session)
    source = Want()
    for _, module in ipairs(Core.optionOrder) do Bind(module) end
    Core.general = live[Core.name]
end)

-- The game names the character: one it did not know at the load (no GUID yet), or another than the
-- key last seen, uses its own profile from here on.
Core.On("PLAYER_LOGIN", function()
    if not db then return end
    if Core.charKey and Core.charKey ~= key then
        key = Core.charKey
        Register(key)
        Move(Want())
    end
    char.key = key
    local line = Line()
    if line then line.name, line.realm, line.class = Core.charName, Core.realm, Core.class end
end)

-- The game writes the saved settings after this (a logout or a /reload): they are where they live
-- already, only what the modules keep of the game's is brought up to date.
Core.On("PLAYER_LOGOUT", function()
    if db then Capture() end
end)

-- A module's settings come into use (Core.Options, once our own are loaded).
function Profiles.Arrive(name)
    if not db then return nil end
    return Bind(name)
end

-- The settings in use of a module (Core.Settings).
function Profiles.Live(name)
    return live[name]
end

-------------------------------------------------------------------------------
--  Accountwide
-------------------------------------------------------------------------------
-- Switched on, this character uses its profile again (its settings and the game's change to the
-- profile's); off, it keeps a copy of what it uses now as its own, and so does every other character
-- from its profile's at its next login.
function Profiles.SetOn(on)
    on = on and true or false
    if on == Profiles.On() then return true end
    if not on then
        Capture() -- the game's settings into the profile, while Sync still reads them
        local clock = rawget(_G, "time")
        db.ownSince = math.max(clock and clock() or 0, (db.ownSince or 0) + 1)
        db.accountwide = false
    else
        db.accountwide = nil
    end
    Move(Want())
    return true
end

-- The profile in use; nil while Accountwide is off.
function Profiles.InUse()
    return source
end

-------------------------------------------------------------------------------
--  Profiles
-------------------------------------------------------------------------------
-- Their names: Accountwide first, the others in alphabetical order.
function Profiles.List()
    local names = {}
    for name in pairs(db.profiles) do
        if name ~= ACCOUNTWIDE and Saved(name) then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        local x, y = a:lower(), b:lower()
        if x ~= y then return x < y end
        return a < b
    end)
    table.insert(names, 1, ACCOUNTWIDE)
    return names
end

function Profiles.Exists(name)
    return Saved(name) ~= nil
end

-- Whether a profile is always there: Accountwide, which cannot be renamed or deleted.
function Profiles.Fixed(name)
    return name == ACCOUNTWIDE
end

-- The settings of every module where they live now, as they are this moment (a copy), the modules not
-- switched on today too.
local function Snapshot()
    Capture()
    local copy = {}
    for name, values in pairs(source and Saved(source) or Own()) do copy[name] = Copy(values) end
    for name, values in pairs(live) do
        if source or not Game(name) then copy[name] = Copy(values) end
    end
    return copy
end

-- The profile that has that name, in any letter case (Quiet and quiet would be two names for one).
local function Taken(name, except)
    local low = name:lower()
    for known in pairs(db.profiles) do
        if known ~= except and type(known) == "string" and known:lower() == low then return known end
    end
    return nil
end

-- A name for a new profile; nil and why not.
local function Fresh(name, except)
    name = Name(name)
    if not name then return nil, TEXT.noName end
    local taken = Taken(name, except)
    if taken then return nil, TEXT.taken:format(taken) end
    return name
end

-- A new profile: a copy of the settings in use (from nil), or of another profile.
function Profiles.Create(name, from)
    local fresh, why = Fresh(name)
    if not fresh then return false, why end
    if from ~= nil and not Saved(from) then return false, TEXT.missing:format(tostring(from)) end
    db.profiles[fresh] = from and Copy(Saved(from)) or Snapshot()
    return true, fresh
end

-- This character uses that profile from now on.
function Profiles.Use(name)
    if not Profiles.On() then return false, TEXT.off end
    if not Saved(name) then return false, TEXT.missing:format(tostring(name)) end
    local line = Line()
    if not line then return false, TEXT.unknown end
    line.profile = name ~= ACCOUNTWIDE and name or nil
    Move(Want())
    return true
end

-- Renamed, it stays every character's profile that had it, and in use where it was.
function Profiles.Rename(name, as)
    if Profiles.Fixed(name) then return false, TEXT.fixed end
    if not Saved(name) then return false, TEXT.missing:format(tostring(name)) end
    if Name(as) == name then return true end
    local new, why = Fresh(as, name)
    if not new then return false, why end
    db.profiles[new], db.profiles[name] = db.profiles[name], nil
    for _, line in pairs(db.characters) do
        if type(line) == "table" and line.profile == name then line.profile = new end
    end
    if db.newProfile == name then db.newProfile = new end
    if source == name then source = new end
    Shown()
    return true
end

-- Deleted, the characters that had it use Accountwide; this one at once.
function Profiles.Delete(name)
    if Profiles.Fixed(name) then return false, TEXT.fixed end
    if not Saved(name) then return false, TEXT.missing:format(tostring(name)) end
    for _, line in pairs(db.characters) do
        if type(line) == "table" and line.profile == name then line.profile = nil end
    end
    if db.newProfile == name then db.newProfile = nil end
    Move(Want())
    db.profiles[name] = nil
    Shown()
    return true
end

-- The settings in use take another profile's: Sane UI's and, with Accountwide on, the game's too.
function Profiles.CopyFrom(name)
    local from = Saved(name)
    if not from then return false, TEXT.missing:format(tostring(name)) end
    if name == source then return true end
    local holder = source and Saved(source) or Own()
    for module, values in pairs(from) do
        if not live[module] and (source or not Game(module)) and type(values) == "table" then holder[module] = Copy(values) end
    end
    Fill(function(module)
        if not source and Game(module) then return false end
        return from[module]
    end)
    return true
end

-- Every setting of Sane UI's in use back to its default; the game's settings stay as they are.
function Profiles.Reset()
    local holder = source and Saved(source) or Own()
    for module in pairs(holder) do
        if not live[module] and not Game(module) then holder[module] = nil end
    end
    Fill(function(module)
        if Game(module) then return false end
        return {}
    end)
    return true
end

-- A profile as one line of text to copy (Core.Serial); nil and why not.
function Profiles.Export(name)
    name = name or source or Assigned(Line())
    local profile = Saved(name)
    if not profile then return nil, TEXT.missing:format(tostring(name)) end
    if name == source then Capture() end
    return Core.Serial.Write({ kind = Profiles.EXPORT, version = Profiles.VERSION, name = name, settings = profile })
end

-- A profile from a text made by Export, under its own name or as; true and its name, or false and why.
function Profiles.Import(text, as)
    local value, why = Core.Serial.Read(text)
    if type(value) ~= "table" then return false, why or TEXT.notProfile end
    if value.kind ~= Profiles.EXPORT or type(value.settings) ~= "table" then return false, TEXT.notProfile end
    local fresh, refused = Fresh(as or value.name)
    if not fresh then return false, refused end
    local settings = {}
    for module, values in pairs(value.settings) do
        if type(module) == "string" and type(values) == "table" then settings[module] = values end
    end
    db.profiles[fresh] = settings
    Shown()
    return true, fresh
end

-------------------------------------------------------------------------------
--  The characters and their profiles
-------------------------------------------------------------------------------
-- A character's line as it counts: { key, name, realm, class, profile, current }; nil if never seen.
-- NEW: the line for characters not seen yet ({ key, profile }).
function Profiles.Character(which)
    if which == NEW then
        return { key = NEW, profile = Saved(db.newProfile) and db.newProfile or ACCOUNTWIDE, new = true }
    end
    local line = Line(which)
    if not (line and type(line.name) == "string") then return nil end
    return { key = which, name = line.name, realm = line.realm, class = line.class, profile = Assigned(line),
        current = which == key }
end

-- Every character seen on the account, by name.
function Profiles.Characters()
    local list = {}
    for which in pairs(db.characters) do list[#list + 1] = Profiles.Character(which) end
    table.sort(list, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return tostring(a.realm) < tostring(b.realm)
    end)
    return list
end

-- Gives a character a profile (NEW: every character not seen yet); this one uses it at once.
function Profiles.SetCharacter(which, name)
    if not Saved(name) then return false, TEXT.missing:format(tostring(name)) end
    local value = name ~= ACCOUNTWIDE and name or nil
    if which == NEW then
        db.newProfile = value
        return true
    end
    local line = Line(which)
    if not line then return false, TEXT.unknown end
    line.profile = value
    if which == key then Move(Want()) end
    return true
end

-- Forgets a character: its line, and what every module kept for it (a deleted character, one moved
-- to another account). Not the one played.
function Profiles.Forget(which)
    if which == key then return false, TEXT.current end
    if not Line(which) then return false, TEXT.unknown end
    db.characters[which] = nil
    for _, store in pairs(db.modules) do
        local chars = type(store) == "table" and rawget(store, "chars")
        if type(chars) == "table" then chars[which] = nil end
    end
    Shown()
    return true
end

-- Every kept copy of a module's settings: in use, each profile's, this character's own. (For an
-- upgrade of the first kind: a module's own version, now Core.Options' version and upgrade.)
function Profiles.Copies(name)
    local list, seen = {}, {}
    local function Add(copy)
        if type(copy) == "table" and not seen[copy] then
            seen[copy] = true
            list[#list + 1] = copy
        end
    end
    Add(live[name])
    for _, profile in pairs(db.profiles) do Add(type(profile) == "table" and profile[name]) end
    Add(char.settings and char.settings[name])
    return list
end

-- /sane profile: the profiles, and one used by name (in any letter case), without the options window.
Core.Command("profile", TEXT.about, function(rest)
    local wanted = Name(rest)
    if not wanted then
        local names = table.concat(Profiles.List(), ", ")
        if Profiles.On() then Core.Print(TEXT.list:format(names, tostring(source))) else Core.Print(TEXT.listOff:format(names)) end
        return
    end
    local name = Taken(wanted) or wanted
    local ok, why = Profiles.Use(name)
    Core.Print(ok and TEXT.using:format(name) or why)
end, "profiles")
