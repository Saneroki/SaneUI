local ADDON = ...

-------------------------------------------------------------------------------
--  Sane UI - Core - Sync
--  The game keeps much of what a player sets for each character alone. Sync
--  keeps it with Sane UI's settings instead, in the profile in use
--  (Core/Profiles.lua): every character that uses a profile has the game's
--  settings of that profile, the same for all of them. On Character specific
--  Sync does nothing: the game keeps its settings for each character, as it does
--  without Sane UI; turning to it, they go back to the game's defaults (Sync.Moved).
--  While the profiles are off (a fresh install) Sync does nothing at all: it
--  writes nothing, gives no defaults, and turning them off leaves the game's
--  settings as they are. Turned on, the profile Accountwide takes the game's as
--  they are that moment (Sync.Take), with nothing written into the game.
--
--  What it keeps comes in parts, laid out as the game lays out its own options
--  (Esc > Options): a part per options page of the game, in the game's groups
--  Gameplay, Accessibility and System, and a few parts for what is on none of
--  its pages (Edit Mode layout, chat windows, own channels, what it keeps per
--  character, the addons switched on, the key bindings). Each part has a checkbox in the tab Game settings of the page
--  Profiles (Settings/Synced.lua), ticked at first. A ticked part is read from
--  the game whenever Sane UI's settings are saved (Core's capture: a new
--  profile, another one used, the logout) and written back into the game when a
--  character is in the world (a moment after it entered, never in a fight) and
--  when another profile came into use. Nothing is read before it was written
--  once this session, so a character that leaves at once does not spread its own.
--
--  Only the game's stored settings are touched (CVars, its chat window and
--  action bar settings, C_EditMode, the modifier keys), never its frames. Where
--  the game shows a change only after a /reload, one is offered once; for the
--  same thing at the next login too, it is not offered again: that /reload
--  settled nothing, which goes to the error log (Sync.OfferReload). A CVar a
--  module lends (Sync.Lend, Game.lua) is left to it: kept as the player's own.
--
--  Files: Data/Pages.lua (what each options page sets, made from Blizzard's
--  code), Layout.lua (Edit Mode), Chat.lua (chat windows, own channels),
--  Game.lua (the CVar parts), Addons.lua (the addon list), Keys.lua (the key
--  bindings). Settings/CVars.lua keeps single CVars by name
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

-- A word of the game's own (the name of one of its strings), or ours where this client has none (Kit.lua).
Sync.Word = Core.Word

-- The boxes of the tab Game settings (page Profiles), in order: the game's own groups of options pages,
-- named in its words, then what is on none of its pages.
Sync.GROUPS = {
    { id = "SETTING_GROUP_GAMEPLAY", fallback = "Gameplay" },
    { id = "SETTING_GROUP_ACCESSIBILITY", fallback = "Accessibility" },
    { id = "SETTING_GROUP_SYSTEM", fallback = "System" },
    { id = "elsewhere", fallback = TEXT.elsewhere },
}

-- The parts that are one player's own, never taken from another player's text (Profiles.Import): which addons
-- are switched on, the key bindings.
Sync.PERSONAL = { addons = true, keyBindings = true }

-- The parts, in the order they are written into the game; by id too. A part:
--      id, group   its key in the settings, and the box it is shown in (Sync.GROUPS)
--      text, tip   its checkbox's words
--      Default()   with no profile any more: the game's own again, where a CVar's default does not do it
--      Read()      what the game holds now, as plain data (nil: nothing to keep)
--      Write(data) gives it back, setting only what differs; true when the game shows it only after a
--                  /reload, then named by reload ("the chat windows")
--      Prepare()   gets ready to be read, whatever the profile holds: the logout leaves no time for that
--      Outside(data, before, now)  what the player changed on the game's screens before the world (the addon list
--                  at the character screen) put into data, the profile's, so that the login does not undo it:
--                  before is what Read gave at this character's last logout, now what it gives at the login
--      Has(name)   whether a CVar is one of the part's (nil while the game is still asked which it has): unticked,
--                  the part takes those kept by name with it (Sync.Unname)
Sync.parts = {}
Sync.part = {}

function Sync.Part(id, group, part)
    part.id, part.group = id, group
    Sync.part[id] = part
    Sync.parts[#Sync.parts + 1] = part
end

-- Whether the kept settings were read in this game. Each game has options, CVars, layouts and chat windows
-- of its own: what one kept is never written into the other (a game folder's saved settings copied into the
-- other's), and that game's own take its place at the next capture.
local function Ours()
    return Sync.options.from == Core.GAME
end

local AGAIN = "Sync: a /reload settled nothing" -- in the error log (Sync.OfferReload)

-- What a part took last (to keep when the game cannot say now); nothing of another game's.
function Sync.Taken(id)
    if not Ours() then return nil end
    return Sync.options.taken[id]
end

-- Whether a part is kept, and keeping it or leaving it to the game (the tab Game settings).
function Sync.PartKept(id)
    return Sync.options.off[id] == nil
end

-- Unticked, a part takes the CVars kept by name that are its own with it, once (Saneroki, 2026-11-10: Graphics
-- unticked unticks its CVars in the tab CVars too, our recommended ones among them); one ticked there afterwards is
-- kept all the same, the latest word. Ticked again, the part itself keeps them.
function Sync.KeepPart(id, on)
    Sync.options.off[id] = (not on) or nil
    if not on then Sync.Unname(id) end
end

-- The CVars kept by name that a part holds, unticked as in the tab CVars (Sync.Keep). A part that asks the game
-- which CVars it has, still waiting for the answer, does it once that is in (Game.lua).
function Sync.Unname(id)
    local part = Sync.part[id]
    if not (part and part.Has) then return end
    local names = {}
    for name in pairs(Sync.options.named) do
        if type(name) == "string" then
            local has = part.Has(name)
            if has == nil then
                part.unname = true
                return
            end
            if has then names[#names + 1] = name end
        end
    end
    for _, name in ipairs(names) do Sync.Keep(name, false) end
end

local given   -- written into the game this session: from now on the parts may be read
local waiting -- a fight held the writing up: it follows when the fight is over
local offered -- a /reload was offered for this writing
local left    -- what the last capture read: the game's settings the character may be turning away from
local leftNamed -- and the CVars kept by name then
local arrived   -- the settings in use just came from elsewhere: a part they hold nothing of goes to the game's own
local last      -- what the session before offered a /reload for (Sync.Began)
local turned    -- another profile came into use this session: what that changes is new, whatever was offered before

-------------------------------------------------------------------------------
--  Single CVars kept by name (Settings/CVars.lua)
-------------------------------------------------------------------------------
-- named: [CVar] = its value, false until it could be read. dropped: [CVar] = true, unticked by the player, so a
-- standard profile's presets do not tick it again (Profiles.lua); ticked again, it is the player's to keep.
function Sync.Kept(name)
    return Sync.options.named[name] ~= nil
end

function Sync.Keep(name, on)
    local named, dropped = Sync.options.named, Sync.options.dropped
    if on and Sync.Barred(name) then return end
    local lower = name:lower()
    for key in pairs(dropped) do
        if type(key) == "string" and key:lower() == lower then dropped[key] = nil end
    end
    if on then
        named[name] = Sync.Value(name) or named[name] or false
        return
    end
    for key in pairs(named) do -- the presets' own spelling of it too
        if type(key) == "string" and key:lower() == lower then named[key] = nil end
    end
    dropped[name] = true
end

-- A name that is no text (a hand-edited file) is left as it is, and one left to another part (Sync.Leave) too.
-- A barred one (Game.lua) goes: it is never saved.
local function ReadNamed(named)
    for name in pairs(named) do
        local value = type(name) == "string" and not Sync.Left(name) and Core.Ask(Sync.Value, name)
        if Sync.Barred(name) then
            named[name] = nil
        elseif type(value) == "string" then
            named[name] = value
        end
    end
end

-- Each through Sync.SetCVar (Game.lua): only one that differs and that the game lets us set; one it does
-- not take is noted once, and the others are written all the same.
local function WriteNamed(named)
    for name, value in pairs(named) do Sync.SetCVar(name, value) end
end

-------------------------------------------------------------------------------
--  The bug hunt (card #377, Saneroki, 2026-11-06; temporary): which of what Sync writes crashes Forever's client
--  in the Ruins of Lordaeron. SaneUIDB.hunt, set by hand in the saved file while the game is closed:
--      true        Sync writes nothing into the game and reads nothing back: the profile stays as it is
--      { names }   those CVars alone are held (Sync.Leave, at the first writing): neither written nor read,
--                  the rest as always
--  Told in chat at the login, so it is not left on by mistake.
-------------------------------------------------------------------------------
local function Hunt()
    local hunt = type(SaneUIDB) == "table" and SaneUIDB.hunt
    return (hunt == true or type(hunt) == "table") and hunt or nil
end

-------------------------------------------------------------------------------
--  Reading and writing
-------------------------------------------------------------------------------
-- Whether Sync keeps the game's settings at all: not for a character on Character specific, nor while the profiles are
-- off (Profiles.lua).
local function On()
    return Core.Profiles.On()
end

-- Reads the kept parts into the settings in use; what is not kept, or no part of this version, is
-- dropped. Core calls it before Sane UI's settings are saved anywhere. Not while a writing waits for
-- a fight to end: the game still holds the old settings then (a profile just loaded would be lost).
-- The server's clock, whole seconds (0 when the game cannot say).
local function Now()
    return tonumber(Plain(Core.Ask(rawget(_G, "GetServerTime")))) or 0
end

-- When the profile's value of each key of such a part (one with Outside: the addons) last changed: what a character
-- changed outside the world since its own logout counts only where the profile's is older (Sync.Outside).
local function Stamp(id, old, new)
    if type(old) ~= "table" or type(new) ~= "table" then return end
    local stamps = Sync.options.stamps
    if type(stamps[id]) ~= "table" then stamps[id] = {} end
    local now, at = Now(), stamps[id]
    for key, value in pairs(new) do
        if old[key] ~= value then at[key] = now end
    end
    for key in pairs(old) do
        if new[key] == nil then at[key] = now end
    end
end

function Sync.Capture()
    if not On() or not given or waiting or Hunt() == true then return end
    local options, taken = Sync.options, {}
    for _, part in ipairs(Sync.parts) do
        if Sync.PartKept(part.id) then
            local ok, data = xpcall(part.Read, Core.Trace)
            if not ok then
                Core.NoteError(Sync.name .. ": reading " .. part.id, data)
                data = options.taken[part.id]
            end
            if part.Outside then Stamp(part.id, options.taken[part.id], data) end
            taken[part.id] = data
        end
    end
    options.taken, options.from = taken, Core.GAME
    ReadNamed(options.named)
    left, leftNamed = taken, Core.Copy(options.named)
end

-- The profiles turned on (Profiles.lua): the settings in use, Accountwide made from this character's, take the game's
-- as they are this moment, read as a capture reads them, and are read and written as any profile's from then on.
-- Nothing is written into the game, no /reload offered, no part given its defaults: the game holds what the profile
-- does. The parts that find their CVars in the game find them at once (Game.lua), so that they are read now too.
function Sync.Take()
    if Hunt() == true then return end
    if Sync.FindNow then Sync.Safe("finding the game's CVars", Sync.FindNow) end
    given = true
    Sync.Capture()
end

-- Offers a /reload for what the game shows only after one: once per writing (a layout set later
-- by Layout.lua shares it), so a profile loaded afterwards gets its own. The same as the session before
-- is not offered: that /reload settled nothing, and another would not either. It is noted, with what
-- Sync.said (Layout.lua: what the game said then).
function Sync.OfferReload(names)
    if offered or #names == 0 or not Core.AskReload then return end
    offered = true
    local what = table.concat(names, ", ")
    Core.Character(Sync.name).asked = what
    if what == last and not turned then
        Core.NoteError(AGAIN, Sync.said and (what .. ": " .. Sync.said) or what)
        return
    end
    Core.AskReload(names)
end

-- A session's first writing: what the session before offered counts now, and no more after this one. A session
-- that offers nothing so leaves nothing, and the next time is new.
function Sync.Began()
    local character = Core.Character(Sync.name)
    last, character.asked, turned = character.asked, nil, false
end

-- What the game holds of the parts that look for changes made outside the world (part.Outside), kept for this
-- character at its logout (Core.Character(Sync.name).logout, at: when); none on Character specific, where Sync keeps
-- nothing. A session that wrote nothing yet (a /reload within the first seconds, a fight) leaves the record of the
-- logout before: what changed outside the world since is still to be taken at the next login.
local function Remember()
    local character, held = Core.Character(Sync.name), nil
    if On() and Hunt() ~= true then
        if not given then return end
        for _, part in ipairs(Sync.parts) do
            if part.Outside and Sync.PartKept(part.id) then
                local ok, data = xpcall(part.Read, Core.Trace)
                if ok and data ~= nil then
                    held = held or { at = Now() }
                    held[part.id] = data
                end
            end
        end
    end
    character.logout = held
end

-- A session's first writing: what the player changed since this character's last logout while no character was in
-- the world (the addon list at the character screen) goes into the profile first, so that the writing keeps it.
-- A key the profile changed after that logout (on another character: Stamp) is the profile's word, newer than anything
-- this character can bring: it is left out of what the character had then, so Outside passes it over.
function Sync.Outside()
    local logout = Core.Character(Sync.name).logout
    if type(logout) ~= "table" or not On() or not Ours() or Hunt() == true then return end
    local taken, stamps, at = Sync.options.taken, Sync.options.stamps, tonumber(logout.at)
    for _, part in ipairs(Sync.parts) do
        local before, data = logout[part.id], taken[part.id]
        if part.Outside and Sync.PartKept(part.id) and type(before) == "table" and type(data) == "table" then
            local ok, now = xpcall(part.Read, Core.Trace)
            if ok and type(now) == "table" then
                local seen, newer = Core.Copy(before), type(stamps[part.id]) == "table" and stamps[part.id] or {}
                for key, when in pairs(newer) do
                    if at and type(when) == "number" and when > at then seen[key] = nil end
                end
                local was = Core.Copy(data)
                part.Outside(data, seen, now)
                Stamp(part.id, was, data)
            end
        end
    end
end

-- Writes the kept parts of the settings in use into the game; in a fight, once it is over. Another game's are
-- not written: from now on this game's are read in their place.
function Sync.Give()
    local hunt = Hunt()
    if not On() or hunt == true then return end
    for _, cvar in ipairs(hunt or {}) do Sync.Leave(cvar) end
    for _, part in ipairs(Sync.parts) do
        if part.Prepare and Sync.PartKept(part.id) then Sync.Safe("preparing " .. part.id, part.Prepare) end
    end
    if not Ours() then
        given = true
        return
    end
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
        elseif arrived and data == nil and part.Default and Sync.PartKept(part.id) then
            Sync.Safe("defaults of " .. part.id, part.Default)
        end
    end
    Sync.Safe("writing CVars kept by name", WriteNamed, Sync.options.named)
    given, arrived = true, false
    Sync.OfferReload(later)
end

-- /sane hunt (the bug hunt, temporary): writes what it names of the profile's game settings into the game at once,
-- where the player stands, while SaneUIDB.hunt = true holds Sync's own writing back. A word is a CVar kept by name,
-- a part's id (Sync.part), named (every CVar kept by name) or parts (every kept part). Without one: the CVars kept
-- by name that differ from the game's. What it writes is not read back into the profile (Capture waits).
local HUNT = {
    about = "the bug hunt: /sane hunt shadowMode writes that CVar of the profile at once (also named, parts, a part's id)",
    differs = "Bug hunt: %s is %s, the profile has %s.",
    none = "Bug hunt: every CVar kept by name is as the profile has it.",
    set = "Bug hunt: %s set to %s (was %s).",
    same = "Bug hunt: %s is %s already.",
    refused = "Bug hunt: the game did not take %s = %s.",
    held = "Bug hunt: %s is held back by the list in SaneUIDB.hunt.",
    part = "Bug hunt: the part %s written.",
    unknown = "Bug hunt: %s is neither kept by name nor a part.",
}

local function HuntCVar(name, value)
    local before = Plain(Core.Ask(C_CVar.GetCVar, name))
    if before == value then return Core.Print(HUNT.same:format(name, value)) end
    if Sync.Left(name) then return Core.Print(HUNT.held:format(name)) end
    Core.Print((Sync.SetCVar(name, value) and HUNT.set or HUNT.refused):format(name, value, tostring(before)))
end

local function HuntPart(part)
    local data = Sync.options.taken[part.id]
    if type(data) ~= "table" then return end
    if part.Prepare then Sync.Safe("preparing " .. part.id, part.Prepare) end
    Sync.Safe("writing " .. part.id, part.Write, data)
    Core.Print(HUNT.part:format(part.id))
end

Core.Command("hunt", HUNT.about, function(rest)
    local named, names, byLower = Sync.options.named, {}, {}
    for name, value in pairs(named) do
        if type(name) == "string" and type(value) == "string" then
            names[#names + 1], byLower[name:lower()] = name, name
        end
    end
    table.sort(names)
    if rest == "" then
        local any = false
        for _, name in ipairs(names) do
            local now = Plain(Core.Ask(C_CVar.GetCVar, name))
            if now ~= named[name] then
                any = true
                Core.Print(HUNT.differs:format(name, tostring(now), named[name]))
            end
        end
        if not any then Core.Print(HUNT.none) end
        return
    end
    for word in rest:gmatch("%S+") do
        local lower = word:lower()
        if lower == "named" then
            for _, name in ipairs(names) do HuntCVar(name, named[name]) end
        elseif lower == "parts" then
            for _, part in ipairs(Sync.parts) do
                if Sync.PartKept(part.id) then HuntPart(part) end
            end
        elseif byLower[lower] then
            HuntCVar(byLower[lower], named[byLower[lower]])
        elseif Sync.part[word] then
            HuntPart(Sync.part[word])
        else
            Core.Print(HUNT.unknown:format(word))
        end
    end
end)

local settled -- the character is in the world, and its first writing came due (GiveSoon)

local function ToDefault(name)
    local default = Plain(Core.Ask(C_CVar.GetCVarDefault, name))
    if type(default) == "string" then Sync.SetCVar(name, default) end
end

-- A character turned to Character specific: the CVars its profile held are the game's defaults again, as on a fresh
-- install. Nothing is lost: they stay in the profile it left.
local function ToDefaults()
    if not left then return end
    if InCombatLockdown() then return Core.AfterCombat("Sync: defaults", ToDefaults) end
    for _, data in pairs(left) do
        for name in pairs(type(data) == "table" and type(data.cvars) == "table" and data.cvars or {}) do ToDefault(name) end
    end
    for name in pairs(leftNamed) do ToDefault(name) end
    -- Only a part the profile held and kept (an unticked one was not read, as in Give): one it held nothing of
    -- changes nothing.
    for _, part in ipairs(Sync.parts) do
        if part.Default and left[part.id] ~= nil then Sync.Safe("defaults of " .. part.id, part.Default) end
    end
    left = nil
end

-- The settings in use came from elsewhere (another profile, Character specific): what they hold goes into the game at
-- once, if the character is in the world already (otherwise that happens anyway). A part they hold nothing of goes
-- to the game's own (Give) only when they differ from what the last capture read: the same settings again (a copy
-- of this profile) leave the game as it is. With the profiles off nothing goes to its defaults: the game's settings stay as
-- the game has them.
function Sync.Moved()
    if not On() then
        if not Core.Profiles.Enabled() then return end
        return Sync.Safe("defaults", ToDefaults)
    end
    if not settled then return end
    turned = true
    local options = Sync.options
    arrived = left == nil or not Core.Same(left, options.taken) or not Core.Same(leftNamed, options.named)
    Sync.Safe("writing", Sync.Give)
end

-- Kept with the settings like a module's switches, in the profile in use (never a character's own), none with a
-- control of the game's options:
--      off     [part id] = true: left to the game, which keeps it per character
--      taken   [part id] = what the part read last
--      named   [CVar] = its value: single CVars kept by name
--      dropped [CVar] = true: one the player unticked, which the presets pass over (Sync.Keep)
--      from    the game taken and named were read in ("forever", "retail"; Ours): those kept before Sane UI
--              served two games are Forever's
--      stamps  [part id] = { [key] = the server's time it last changed in the profile }: of a part with Outside
Core.Options(Sync.name, {
    { key = "off", default = {} },
    { key = "taken", default = {} },
    { key = "named", default = {} },
    { key = "dropped", default = {} },
    { key = "from", default = "forever" },
    { key = "stamps", default = {} },
}, { capture = function() Sync.Capture() end, moved = function() Sync.Moved() end, game = true })

-- Core's saved settings are there, and in use where they should come from (Saved.lua and
-- Profiles.lua listen before this file: they come first in the TOC).
Core.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    Sync.options = Core.Settings(Sync.name)
    local hunt = Hunt()
    if hunt == true then
        Core.Print("Bug hunt: Sync writes none of the game's settings this session.")
    elseif hunt then
        local held = {}
        for _, cvar in ipairs(hunt) do held[#held + 1] = tostring(cvar) end
        Core.Print("Bug hunt: Sync holds back " .. (#held > 0 and table.concat(held, ", ") or "nothing") .. ".")
    end
end)

local SETTLE = 2 -- seconds after the character is in the world and the game has its own settings

local entered, late
local function GiveSoon()
    C_Timer.After(SETTLE, Core.Guard("sync", function()
        settled = true
        Sync.Safe("beginning", Sync.Began)
        Sync.Safe("changes made before the login", Sync.Outside)
        Sync.Safe("writing", Sync.Give)
    end))
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
-- The game writes the saved settings after this: what the next login compares with (Sync.Outside).
Core.On("PLAYER_LOGOUT", function()
    Sync.Safe("remembering the logout", Remember)
end)
