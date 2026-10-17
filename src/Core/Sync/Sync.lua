local ADDON = ...

-------------------------------------------------------------------------------
--  Sane UI - Core - Sync
--  The game keeps much of what a player sets for each character alone. Sync
--  keeps it with Sane UI's settings instead, so it goes where they go
--  (Core/Profiles.lua): to every character that uses the account's settings,
--  or stays with a character that has its own, and into every profile.
--
--  What it keeps comes in parts, laid out as the game lays out its own options
--  (Esc > Options): a part per options page of the game, in the game's groups
--  Gameplay, Accessibility and System, and a few parts for what is on none of
--  its pages (Edit Mode layout, chat windows, own channels, what it keeps per
--  character). Each part has a checkbox in the tab Accountwide of the page
--  Profiles (Settings/Synced.lua), ticked at first. A ticked part is read from
--  the game whenever Sane UI's settings are saved (Core's capture: a profile
--  saved, the logout) and written back into the game when a character is in
--  the world (a moment after it entered, never in a fight) and when a profile
--  was loaded. Nothing is read before it was written once this session, so a
--  character that leaves at once does not spread its own.
--
--  Only the game's stored settings are touched (CVars, its chat window and
--  action bar settings, C_EditMode, the modifier keys), never its frames. Where
--  the game shows a change only after a /reload, one is offered once.
--
--  Files: Data/Pages.lua (what each options page sets, made from Blizzard's
--  code), Layout.lua (Edit Mode), Chat.lua (chat windows, own channels),
--  Game.lua (the CVar parts). Settings/CVars.lua keeps single CVars by name
--  (Sync.Keep).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
-- Part of Core, not a module of its own: Core.Sync. Its settings are kept under the name Sync, as a
-- module's are, and shown on the page Profiles (Settings/Synced.lua), not on a page of their own.
local Sync = { name = "Sync" }
Core.Sync = Sync

function Sync.Safe(label, fn, ...)
    return Core.Safe(Sync.name .. ": " .. label, fn, ...)
end

local TEXT = {
    elsewhere = "Elsewhere in the game",
}

-- A word of the game's own (the name of one of its strings), or ours where this client has none.
function Sync.Word(name, fallback)
    local word = rawget(_G, name)
    return type(word) == "string" and word ~= "" and word or fallback
end

-- The boxes of the tab Accountwide, in order: the game's own groups of options pages, named in its
-- words, then what is on none of its pages.
Sync.GROUPS = {
    { id = "SETTING_GROUP_GAMEPLAY", fallback = "Gameplay" },
    { id = "SETTING_GROUP_ACCESSIBILITY", fallback = "Accessibility" },
    { id = "SETTING_GROUP_SYSTEM", fallback = "System" },
    { id = "elsewhere", fallback = TEXT.elsewhere },
}

-- The parts, in the order they are written into the game; by id too. A part:
--      id, group   its key in the settings, and the box it is shown in (Sync.GROUPS)
--      text, tip   its checkbox's words
--      Read()      what the game holds now, as plain data (nil: nothing to keep)
--      Write(data) gives it back, setting only what differs; true when the game shows it only after a
--                  /reload, then named by reload ("the chat windows")
Sync.parts = {}
Sync.part = {}

function Sync.Part(id, group, part)
    part.id, part.group = id, group
    Sync.part[id] = part
    Sync.parts[#Sync.parts + 1] = part
end

-- What a part took last (to keep when the game cannot say now).
function Sync.Taken(id)
    return Sync.options.taken[id]
end

-- Whether a part is kept, and keeping it or leaving it to the game (the tab Accountwide).
function Sync.PartKept(id)
    return Sync.options.off[id] == nil
end

function Sync.KeepPart(id, on)
    Sync.options.off[id] = (not on) or nil
end

local given   -- written into the game this session: from now on the parts may be read
local waiting -- a fight held the writing up: it follows when the fight is over
local offered -- a /reload was offered for this writing

-------------------------------------------------------------------------------
--  Single CVars kept by name (Settings/CVars.lua)
-------------------------------------------------------------------------------
-- named: [CVar] = its value, false until it could be read.
function Sync.Kept(name)
    return Sync.options.named[name] ~= nil
end

function Sync.Keep(name, on)
    local named = Sync.options.named
    if on then
        named[name] = Plain(C_CVar.GetCVar(name)) or named[name] or false
    else
        named[name] = nil
    end
end

local function ReadNamed(named)
    for name in pairs(named) do
        local value = Plain(C_CVar.GetCVar(name))
        if value ~= nil then named[name] = value end
    end
end

local function WriteNamed(named)
    for name, value in pairs(named) do
        local now = type(value) == "string" and Plain(C_CVar.GetCVar(name))
        if now and now ~= value then C_CVar.SetCVar(name, value) end
    end
end

-------------------------------------------------------------------------------
--  Reading and writing
-------------------------------------------------------------------------------
-- Reads the kept parts into the settings in use; what is not kept, or no part of this version, is
-- dropped. Core calls it before Sane UI's settings are saved anywhere. Not while a writing waits for
-- a fight to end: the game still holds the old settings then (a profile just loaded would be lost).
function Sync.Capture()
    if not given or waiting then return end
    local options, taken = Sync.options, {}
    for _, part in ipairs(Sync.parts) do
        if Sync.PartKept(part.id) then
            local ok, data = xpcall(part.Read, Core.Trace)
            if not ok then
                Core.NoteError(Sync.name .. ": reading " .. part.id, data)
                data = options.taken[part.id]
            end
            taken[part.id] = data
        end
    end
    options.taken = taken
    ReadNamed(options.named)
end

-- Offers a /reload for what the game shows only after one: once per writing (a layout set later
-- by Layout.lua shares it), so a profile loaded afterwards gets its own.
function Sync.OfferReload(names)
    if offered or #names == 0 or not Core.AskReload then return end
    offered = true
    Core.AskReload(names)
end

-- Writes the kept parts of the settings in use into the game; in a fight, once it is over.
function Sync.Give()
    if InCombatLockdown() then
        waiting = true
        return
    end
    waiting, offered = false, false
    local taken, later = Sync.options.taken, {}
    for _, part in ipairs(Sync.parts) do
        local data = taken[part.id]
        if type(data) == "table" and Sync.PartKept(part.id) and Sync.Safe("writing " .. part.id, part.Write, data)
            and part.reload and not tContains(later, part.reload) then
            later[#later + 1] = part.reload
        end
    end
    Sync.Safe("writing CVars kept by name", WriteNamed, Sync.options.named)
    given = true
    Sync.OfferReload(later)
end

-- A profile was loaded, or the character's own settings switched: what they hold goes into the game
-- at once, if the character is in the world already (otherwise that happens anyway).
function Sync.Changed(key)
    if key == "taken" and given then Sync.Safe("writing", Sync.Give) end
end

-- Kept with the settings like a module's switches (the account's, a character's own, a profile's),
-- none with a control of the game's options:
--      off     [part id] = true: left to the game, which keeps it per character
--      taken   [part id] = what the part read last
--      named   [CVar] = its value: single CVars kept by name
Core.Options(Sync.name, {
    { key = "off", default = {} },
    { key = "taken", default = {} },
    { key = "named", default = {} },
}, function(key) Sync.Changed(key) end, function() Sync.Capture() end)

-- Core's saved settings are there, and in use where they should come from (Saved.lua and
-- Profiles.lua listen before this file: they come first in the TOC).
Core.On("ADDON_LOADED", function(name)
    if name == ADDON then Sync.options = Core.Store(Sync.name).options end
end)

local SETTLE = 2 -- seconds after the character is in the world and the game has its own settings

local entered, late
local function GiveSoon()
    C_Timer.After(SETTLE, function() Sync.Safe("writing", Sync.Give) end)
end

-- Whether the game has its stored settings: on a slow login they come from the server after the
-- character entered the world, and would overwrite what was written before them.
local function Ready()
    local loaded = C_CVar and C_CVar.AreCVarsLoaded
    return not loaded or Core.Ask(loaded) ~= false
end

Core.On("PLAYER_ENTERING_WORLD", function()
    if entered then return end
    entered = true
    if Ready() then GiveSoon() else late = true end
end)
Core.On("VARIABLES_LOADED", function()
    if not late then return end
    late = false
    GiveSoon()
end)
Core.On("PLAYER_REGEN_ENABLED", function()
    if waiting then Sync.Safe("writing", Sync.Give) end
end)
