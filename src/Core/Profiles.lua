local ADDON = ...
local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Profiles
--  Where the settings in use come from, and named copies of them.
--
--  The settings in use are the switches of every module, the general ones too
--  (SaneUIDB.modules.<Module>.options, Saved.lua). The modules hold on to those
--  tables for the whole session, so they are never replaced: other settings are
--  copied into them. For each module they come from
--      the account's          by default: every character shares them
--      the character's own    when "All settings accountwide" is unticked (for
--                             every character), or that module is not ticked as
--                             account wide
--      a profile              when the character has one, with Load at login, in
--                             the list of characters: for that character only
--  Arrange moves each module from where its settings came from to where they
--  should come from: at login (before any module reads them), when one of the
--  switches above changes, and at the logout, which puts the account's back
--  where every character finds them.
--
--      SaneUIDB.separate      true: no settings are account wide
--      SaneUIDB.perCharacter  [module] = true: that module's settings are each character's own
--      SaneUIDB.characters    [key] = { name, realm, class, profile, autoLoad, autoSave }:
--                             every character seen, and the profile it uses
--      SaneUIDB.newCharacters { profile, autoLoad, autoSave }: what a character not seen
--                             yet starts with, at its first login with Sane UI
--      SaneUIDB.profiles      [name] = { [module] = its switches }: for every character
--      SaneUIDB.account       [module] = its switches: the account's, kept aside while
--                             this character uses other ones
--      SaneUICharDB.settings  [module] = its switches: this character's own
--      SaneUICharDB.profile   the profile chosen in the options, for their buttons
--      SaneUICharDB.key       this character's key, to find its line before the login
--
--  A profile holds the switches of every module there are saved settings for,
--  also of those switched off for this character. Loading one sets those it has
--  and tells each module of what changed, as a tick on its options page does.
--  Before settings are saved anywhere, a module whose settings hold something of
--  the game's own brings it up to date (the capture it gave Core.Options).
--
--  Two profiles are always there and never saved, neither saved over, renamed nor
--  deleted; both can be loaded and duplicated:
--      Empty            (EMPTY) no profile: the settings as they are kept, the
--                       account's or the character's own, loaded at every login and
--                       saved at every logout and /reload. What every character has
--                       until it is given another (its line's profile is nil).
--      SaneUI Defaults  (DEFAULTS) every switch of Sane UI's own at the default its
--                       module describes; not the game's settings Sync keeps (nor
--                       which of them it keeps), which stay as they are. Being made
--                       from the descriptions, it follows every new version.
-------------------------------------------------------------------------------
local Profiles = {}
Core.Profiles = Profiles

Profiles.MAX_NAME = 32 -- letters in a profile's name
Profiles.DEFAULTS = "SaneUI Defaults"
local DEFAULTS = Profiles.DEFAULTS
Profiles.EMPTY = "Empty"
local EMPTY = Profiles.EMPTY
Profiles.NEW = "new" -- the line of the characters not seen yet, for Character and SetCharacter
local NEW = Profiles.NEW

local TEXT = {
    noName = "a profile needs a name.",
    taken = "there is already a profile called %s.",
    missing = "there is no profile called %s.",
    fixed = "%s stays as it is: it can be loaded and duplicated, not saved over, renamed or deleted.",
}

local char         -- SaneUICharDB, once the game has read it
local using = {}   -- [module] = "own" or "profile:<name>": where its settings in use come from; nil: the account's

local Copy = Core.Copy -- a copy that shares no table with the original (Saved.lua)

local function Table(t, key)
    if type(t[key]) ~= "table" then t[key] = {} end
    return t[key]
end

-- The settings in use: [module] = its switches, the tables the modules hold.
local function InUse()
    local list = {}
    for name, store in pairs(SaneUIDB.modules) do
        if type(store) == "table" and type(store.options) == "table" then list[name] = store.options end
    end
    return list
end

-- Copies saved switches ([module] = { key = value }) into the settings in use. A switch of the
-- wrong kind gets its default (Saved.lua). tell: each module is told of the switches that changed.
-- fresh: what is in use is emptied first, so every switch gets its default (SaneUI Defaults); a
-- module whose addon is still to be read gets them when it describes its switches.
local function Put(values, tell, fresh)
    for name, saved in pairs(values) do
        if type(name) == "string" and type(saved) == "table" then
            local described = Core.described[name]
            local store = Core.Store(name)
            if type(store.options) ~= "table" then store.options = {} end
            local options = store.options
            local before = tell and described and described.changed and Copy(options)
            if fresh then wipe(options) end
            for key, value in pairs(saved) do options[key] = Copy(value) end
            if described then Core.CheckOptions(name) end
            if before then
                for _, option in ipairs(described.list) do
                    local value = options[option.key]
                    if value ~= before[option.key] then
                        Core.Safe(name .. ": option", described.changed, option.key, value)
                    end
                end
            end
        end
    end
end

-- A profile's name as typed, without the spaces around it; nil if nothing is left.
local function Name(text)
    if type(text) ~= "string" then return nil end
    text = strtrim(text)
    if text == "" then return nil end
    return text
end

-- A saved profile; nil if there is none of that name, and for Empty and SaneUI Defaults, which are
-- never saved.
local function Saved(name)
    local profile = type(name) == "string" and SaneUIDB.profiles[name]
    return type(profile) == "table" and profile or nil
end

-- Whether there is a profile of that name: a saved one, Empty or SaneUI Defaults.
local function Exists(name)
    return name == EMPTY or name == DEFAULTS or Saved(name) ~= nil
end

-- Whether a module's settings are the game's own that Sync keeps: not in SaneUI Defaults.
local function GameSettings(name)
    return Core.Sync ~= nil and name == Core.Sync.name
end

-- SaneUI Defaults as a profile: every switch of the modules switched on at its default.
local function Defaults()
    local profile = {}
    for name, described in pairs(Core.described) do
        if not GameSettings(name) then
            local values = {}
            for _, option in ipairs(described.list) do values[option.key] = Copy(option.default) end
            profile[name] = values
        end
    end
    return profile
end

-- The modules that keep something of the game's own (Sync) bring it up to date.
local function Capture()
    for _, name in ipairs(Core.optionOrder) do
        local capture = Core.described[name].capture
        if capture then Core.Safe(name .. ": saving", capture) end
    end
end

-- The settings in use, as they are this moment.
local function Snapshot()
    Capture()
    return Copy(InUse())
end

-------------------------------------------------------------------------------
--  Characters
-------------------------------------------------------------------------------
-- This character's key: as last seen at its login, or its GUID.
local function Key()
    return char and (char.key or Core.Plain(UnitGUID("player")))
end

-- A character's line (this character's when key is not given; NEW: the one for characters not
-- seen yet); nil if it was never seen.
local function Line(key)
    key = key or Key()
    if key == NEW then return Table(SaneUIDB, "newCharacters") end
    local line = key and SaneUIDB.characters[key]
    return type(line) == "table" and line or nil
end

-- Every character's line, and the one for characters not seen yet.
local function Lines()
    local list = { SaneUIDB.newCharacters }
    for _, line in pairs(SaneUIDB.characters) do list[#list + 1] = line end
    return list
end

-- A character not seen before gets its line, a copy of the one for new characters: its profile,
-- Load at login and Save at logout. Returns whether it was new.
local function Register(key)
    if not key or Line(key) then return false end
    SaneUIDB.characters[key] = Copy(SaneUIDB.newCharacters) or {}
    return true
end

-------------------------------------------------------------------------------
--  Where the settings in use come from
-------------------------------------------------------------------------------
-- Where a module's settings come from without a profile (Empty): "own", or nil (the account's).
local function Home(name)
    if SaneUIDB.separate or SaneUIDB.perCharacter[name] then return "own" end
    return nil
end

-- Where a module's settings should come from now: "profile:<name>", "own", or nil (the account's).
-- SaneUI Defaults does not take the game's settings Sync keeps: they stay where they were.
local function Wanted(name)
    local line = Line()
    -- Empty is no profile: the kept settings (a line may still name it, from an older version).
    if line and line.autoLoad and line.profile ~= EMPTY and Exists(line.profile)
        and not (line.profile == DEFAULTS and GameSettings(name)) then
        return "profile:" .. line.profile
    end
    return Home(name)
end

-- A module's settings as kept without a profile (Empty): the account's, or this character's own;
-- nil while those are the ones in use.
local function Kept(name)
    local home = Home(name)
    if using[name] == home then return nil end
    if home == "own" then return char.settings and char.settings[name] end
    return SaneUIDB.account and SaneUIDB.account[name]
end

-- Moves every module to where its settings should come from (to the account's when leaving).
-- What it used is kept where it came from first: the character's own in its file, a profile's
-- (with Save at logout; never SaneUI Defaults) in the profile, the account's aside. tell: the
-- modules are told of what changed. captured: the modules have just brought what they keep of the
-- game's up to date (Capture).
local function Arrange(tell, leaving, captured)
    local db = SaneUIDB
    for name, options in pairs(InUse()) do
        local now, want = using[name], not leaving and Wanted(name) or nil
        if now ~= want then
            if not captured then
                Capture()
                captured = true
            end
            if now == "own" then
                Table(char, "settings")[name] = Copy(options)
            elseif now then
                local line, profile = Line(), Saved(now:sub(9))
                if profile and line and line.autoSave and not leaving then profile[name] = Copy(options) end
            else
                Table(db, "account")[name] = Copy(options)
            end
            local values, fresh
            if want == "own" then
                values = char.settings and char.settings[name]
            elseif want == "profile:" .. DEFAULTS then
                values, fresh = {}, true -- every switch at its default
            elseif want then
                values = Saved(want:sub(9))
                values = values and values[name]
            else
                values = db.account and db.account[name]
                if db.account then db.account[name] = nil end
            end
            if values then Put({ [name] = values }, tell, fresh) end
            using[name] = want
        end
    end
    if db.account and next(db.account) == nil then db.account = nil end
end

-- Our own addon is loaded: the game has read SaneUICharDB. Saved.lua has made SaneUIDB right just before.
Core.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    if type(SaneUICharDB) ~= "table" then SaneUICharDB = {} end
    char = SaneUICharDB
    if type(char.settings) ~= "table" then char.settings = nil end
    if type(char.profile) ~= "string" then char.profile = nil end
    char.own, char.autoLoad, char.autoSave = nil, nil, nil -- of an earlier version
    local db = SaneUIDB
    for _, key in ipairs({ "profiles", "perCharacter", "characters" }) do Table(db, key) end
    if db.separate ~= true then db.separate = nil end
    if type(db.newCharacters) ~= "table" then db.newCharacters = nil end
    -- A profile of the player's called so before Empty or SaneUI Defaults was there keeps its settings
    -- under another name, one that is free.
    for _, fixed in ipairs({ EMPTY, DEFAULTS }) do
        local mine = db.profiles[fixed]
        db.profiles[fixed] = nil
        if type(mine) == "table" then
            local moved, count = fixed .. " (old)", 1
            while db.profiles[moved] ~= nil do
                count = count + 1
                moved = ("%s (old %d)"):format(fixed, count)
            end
            db.profiles[moved] = mine
        end
    end
    -- The account's settings, still kept aside: the last logout did not finish.
    if type(db.account) == "table" then Put(db.account) end
    db.account = nil
    wipe(using)
    -- Before any module reads its settings: a character not seen yet with the profile for new ones.
    Register(Key())
    Arrange(false)
end)

-- This character is learned, for the list of characters. One the game did not know at the load
-- (no GUID yet) is new only now: its profile counts from here.
Core.On("PLAYER_LOGIN", function()
    if not char then return end
    char.key = Core.charKey
    if Register(Core.charKey) then Arrange(true) end
    local line = Line(Core.charKey)
    line.name, line.realm, line.class = Core.charName, Core.realm, Core.class
end)

-- The game writes the saved settings after this (a logout or a /reload). The settings in use are
-- brought up to date and, with Save at logout, saved into this character's profile (never into
-- SaneUI Defaults, which is not saved); the character's own go to its file, and the account's are
-- back where every character finds them.
Core.On("PLAYER_LOGOUT", function()
    if not char then return end
    Capture()
    local line = Line()
    if line and line.autoSave and Saved(line.profile) then SaneUIDB.profiles[line.profile] = Copy(InUse()) end
    Arrange(false, true, true)
end)

-- Whether all settings are account wide (by default), and making them so or each character's own.
function Profiles.AccountWide()
    return SaneUIDB.separate ~= true
end

function Profiles.SetAccountWide(on)
    SaneUIDB.separate = not on or nil
    Arrange(true)
end

-- Whether a module's settings are account wide (by default), and making them so or each character's own.
function Profiles.Shared(name)
    return not SaneUIDB.perCharacter[name]
end

function Profiles.SetShared(name, on)
    SaneUIDB.perCharacter[name] = not on or nil
    Arrange(true)
end

-- A character's line as it counts: { key, name, realm, class, profile (one that is there; Empty when
-- none), autoLoad, autoSave (Empty: both, it is the kept settings; never into SaneUI Defaults),
-- current }; nil if it was never seen. NEW: the line for characters not seen yet (without name).
function Profiles.Character(key)
    local line = Line(key)
    if not (line and (key == NEW or type(line.name) == "string")) then return nil end
    local profile = line.profile ~= EMPTY and Exists(line.profile) and line.profile or EMPTY
    return { key = key, name = line.name, realm = line.realm, class = line.class, profile = profile,
        autoLoad = profile == EMPTY or line.autoLoad == true,
        autoSave = profile == EMPTY or (line.autoSave == true and profile ~= DEFAULTS), current = key == Key() }
end

-- Every character seen on the account, by name (Profiles.Character).
function Profiles.Characters()
    local list = {}
    for key in pairs(SaneUIDB.characters) do list[#list + 1] = Profiles.Character(key) end
    table.sort(list, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return tostring(a.realm) < tostring(b.realm)
    end)
    return list
end

-- Sets a character's profile (field "profile": a name; Empty or nil for none) or its Load at login,
-- Save at logout ("autoLoad", "autoSave": true or false). For this character it counts at once;
-- for NEW, at the first login of each character not seen yet.
function Profiles.SetCharacter(key, field, value)
    local line = Line(key)
    if not line then return end
    if field == "profile" then
        line.profile = value ~= EMPTY and Exists(value) and value or nil
    else
        line[field] = value and true or nil
    end
    if key == Key() then Arrange(true) end
end

-- Every saved copy of a module's switches this character can reach: those in use, the account's
-- kept aside, each profile's, this character's own. For a module to bring the switches an earlier
-- version saved up to date, from its OnLoad on.
function Profiles.Copies(name)
    local list = {}
    local function Add(copy)
        if type(copy) == "table" then list[#list + 1] = copy end
    end
    local store = SaneUIDB.modules[name]
    Add(type(store) == "table" and store.options)
    Add(SaneUIDB.account and SaneUIDB.account[name])
    for _, profile in pairs(SaneUIDB.profiles) do Add(type(profile) == "table" and profile[name]) end
    Add(char.settings and char.settings[name])
    return list
end

-------------------------------------------------------------------------------
--  Profiles. Each step returns true, or false and why not (a line for chat).
-------------------------------------------------------------------------------
-- The names of the profiles: Empty, SaneUI Defaults, then the saved ones in alphabetical order.
function Profiles.List()
    local names = {}
    for name, profile in pairs(SaneUIDB.profiles) do
        if type(name) == "string" and type(profile) == "table" then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        local x, y = a:lower(), b:lower()
        if x ~= y then return x < y end
        return a < b
    end)
    table.insert(names, 1, DEFAULTS)
    table.insert(names, 1, EMPTY)
    return names
end

-- Whether a profile stays as it is (Empty, SaneUI Defaults): it cannot be saved over, renamed or deleted.
function Profiles.Fixed(name)
    return name == EMPTY or name == DEFAULTS
end

-- The profile chosen in the options, for their buttons: the one last chosen, loaded or saved
-- here, or else Empty (another character may have deleted it).
function Profiles.Chosen()
    local name = char and char.profile
    if Exists(name) then return name end
    return EMPTY
end

function Profiles.Choose(name)
    if char and Exists(name) then char.profile = name end
end

-- Keeps the settings in use as a profile. One of that name is replaced; Empty and SaneUI Defaults are not.
function Profiles.Save(name)
    name = Name(name)
    if not name then return false, TEXT.noName end
    if Profiles.Fixed(name) then return false, TEXT.fixed:format(name) end
    SaneUIDB.profiles[name] = Snapshot()
    char.profile = name
    return true
end

-- Puts a profile's settings in use, wherever those come from now. Empty puts the kept settings
-- (the account's, or this character's own) back where a profile is in use. SaneUI Defaults puts
-- every switch of Sane UI's modules switched on back to its default; those switched off keep theirs,
-- and so do the game's settings Sync keeps.
function Profiles.Load(name)
    if name == EMPTY then
        local kept = {}
        for module in pairs(InUse()) do kept[module] = Kept(module) end
        Put(kept, true)
    elseif name == DEFAULTS then
        local fresh = {}
        for module in pairs(Core.described) do
            if not GameSettings(module) then fresh[module] = {} end
        end
        Put(fresh, true, true)
    else
        local profile = Saved(name)
        if not profile then return false, TEXT.missing:format(tostring(name)) end
        Put(profile, true)
    end
    char.profile = name
    return true
end

-- The settings Empty stands for, as a profile: the kept ones (Kept), or those in use where they are
-- the kept ones, brought up to date.
local function KeptProfile()
    local profile = Snapshot()
    for name in pairs(profile) do profile[name] = Copy(Kept(name)) or profile[name] end
    return profile
end

-- A profile (Empty and SaneUI Defaults made for the purpose) and the new name typed for it; nil
-- and why not when either is missing.
local function Renaming(name, as)
    local profile = name == EMPTY and KeptProfile() or name == DEFAULTS and Defaults() or Saved(name)
    if not profile then return nil, TEXT.missing:format(tostring(name)) end
    as = Name(as)
    if not as then return nil, TEXT.noName end
    return profile, as
end

function Profiles.Duplicate(name, as)
    local profile, new = Renaming(name, as)
    if not profile then return false, new end
    if Exists(new) then return false, TEXT.taken:format(new) end
    SaneUIDB.profiles[new] = Copy(profile)
    char.profile = new
    return true
end

-- Renamed, it stays every character's profile that had it, and in use where it was.
function Profiles.Rename(name, as)
    if Profiles.Fixed(name) then return false, TEXT.fixed:format(name) end
    local profile, new = Renaming(name, as)
    if not profile then return false, new end
    if new ~= name and Exists(new) then return false, TEXT.taken:format(new) end
    SaneUIDB.profiles[name] = nil
    SaneUIDB.profiles[new] = profile
    for _, line in ipairs(Lines()) do
        if type(line) == "table" and line.profile == name then line.profile = new end
    end
    for module, from in pairs(using) do
        if from == "profile:" .. name then using[module] = "profile:" .. new end
    end
    char.profile = new
    return true
end

-- Deleted, no character uses it any more: this one's settings come from where they would without it.
function Profiles.Delete(name)
    if Profiles.Fixed(name) then return false, TEXT.fixed:format(name) end
    if not Saved(name) then return false, TEXT.missing:format(tostring(name)) end
    SaneUIDB.profiles[name] = nil
    for _, line in ipairs(Lines()) do
        if type(line) == "table" and line.profile == name then line.profile = nil end
    end
    if char.profile == name then char.profile = nil end
    Arrange(true)
    return true
end
