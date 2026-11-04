local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Audio
--  Sound profiles (Saneroki, 2026-11-04): the game's five sounds, each on or
--  off with its volume (All sound, Music, SFX, Dialogue, Ambience), kept under
--  a name; choosing a profile sets it at once. The game keeps these settings in
--  one file for the whole installation (WTF/Config.wtf), written by whichever
--  client closes last, and two clients running at once each hold their own
--  until then. So each game account keeps its profiles and the one it used last
--  in its own saved settings (SaneUIDB.modules.Core.audio) and sets that one
--  again at each login (not at a /reload: the client still holds its own): two
--  accounts on one computer sit on different profiles at the same time. The
--  login screen comes before any addon and sounds as the file says. Sync keeps
--  none of these settings (Sync.Leave): they are the profiles'.
--
--  A profile is the game's settings as they were saved. The game's settings may
--  move away from it (the sliders, the game's own options, its key that switches
--  all sound) until the profile is saved or loaded again.
--
--      Core.Audio.KINDS                 { key, text, on = CVar, volume = CVar }, in the order shown
--      Core.Audio.Kinds()               those this client has
--      Core.Audio.Names()               the profiles' names, in their order
--      Core.Audio.Current()             the profile in use: its name
--      Core.Audio.Use(name)             that profile set, and kept as the account's
--      Core.Audio.Get(key)              on, volume (0 to 1): the game's now; nil where this client lacks it
--      Core.Audio.Set(key, on, volume)  the game's now (nil: left as it is), not the profile
--      Core.Audio.Changed()             whether the game's now differs from the profile in use
--      Core.Audio.Save()                the game's now into the profile in use
--      Core.Audio.Load()                the profile in use set again
--      Core.Audio.New(name)             a profile of the game's now, in use; false, why when not
--      Core.Audio.Delete()              the profile in use gone, the first one in use; false, why for the last
--      Core.Audio.Watch(fn)             fn() on the next frame after a change: a profile, the game's settings
-------------------------------------------------------------------------------
local Audio = {}
Core.Audio = Audio

Audio.KINDS = {
    { key = "all", text = "All sound", on = "Sound_EnableAllSound", volume = "Sound_MasterVolume" },
    { key = "music", text = "Music", on = "Sound_EnableMusic", volume = "Sound_MusicVolume" },
    { key = "sfx", text = "SFX", on = "Sound_EnableSFX", volume = "Sound_SFXVolume" },
    { key = "dialog", text = "Dialogue", on = "Sound_EnableDialog", volume = "Sound_DialogVolume" },
    { key = "ambience", text = "Ambience", on = "Sound_EnableAmbience", volume = "Sound_AmbienceVolume" },
}
-- The profiles every account starts with (Saneroki, 2026-11-04): every sound on but those named off, at the volumes
-- the game had then.
Audio.DEFAULTS = {
    { name = "All sound on" },
    { name = "Music off", off = { music = true } },
    { name = "Music and Ambience off", off = { music = true, ambience = true } },
}
Audio.LETTERS = 32    -- a profile's name at most
Audio.EXACT = 0.005   -- two volumes this close are the same (the game's slider steps by 0.05)
Audio.TEXT = {
    empty = "a sound profile needs a name.",
    taken = "there is a sound profile called %s already.",
    last = "the last sound profile cannot be deleted.",
}

local byKey, ours = {}, {} -- [key] = its kind; [lower-case CVar] = true: the profiles' CVars
for _, kind in ipairs(Audio.KINDS) do
    byKey[kind.key] = kind
    ours[kind.on:lower()], ours[kind.volume:lower()] = true, true
    Core.Sync.Leave(kind.on)
    Core.Sync.Leave(kind.volume)
end
local listeners = {}
local kept -- the account's profiles, made right once a session (Kept)

local Tell = Core.Later(function()
    for _, fn in ipairs(listeners) do Core.Safe("audio", fn) end
end, 0, "audio")

function Audio.Watch(fn) listeners[#listeners + 1] = fn end

-------------------------------------------------------------------------------
--  The game's settings
-------------------------------------------------------------------------------
-- A CVar's value as text; nil where this client has none.
local function Value(name)
    local value = Core.Ask(C_CVar.GetCVar, name)
    return type(value) == "string" and value or nil
end

-- A volume between 0 and 1, to the hundredth.
local function Volume(value)
    value = tonumber(value)
    if not value then return nil end
    return math.floor(math.min(math.max(value, 0), 1) * 100 + 0.5) / 100
end

function Audio.Kinds()
    local list = {}
    for _, kind in ipairs(Audio.KINDS) do
        if Value(kind.on) and Value(kind.volume) then list[#list + 1] = kind end
    end
    return list
end

function Audio.Get(key)
    local kind = byKey[key]
    local on, volume = kind and Value(kind.on), kind and Volume(Value(kind.volume))
    if not (on and volume) then return nil end
    return on ~= "0", volume
end

-- Through C_CVar itself, not Sync.SetCVar: Sync leaves these to the profiles. Only what differs; the views told
-- (whether or not the game sends its CVAR_UPDATE for it).
function Audio.Set(key, on, volume)
    local kind = byKey[key]
    if not (kind and Audio.Get(key) ~= nil) then return end
    if on ~= nil and (Value(kind.on) ~= "0") ~= (on and true or false) then
        Core.Ask(C_CVar.SetCVar, kind.on, on and "1" or "0")
        Tell()
    end
    volume = Volume(volume)
    local now = Volume(Value(kind.volume))
    if volume and now and math.abs(now - volume) > Audio.EXACT then
        Core.Ask(C_CVar.SetCVar, kind.volume, tostring(volume))
        Tell()
    end
end

-- [key] = { on, volume }: the game's now; a sound this client lacks on, at full volume.
local function Now()
    local sounds = {}
    for _, kind in ipairs(Audio.KINDS) do
        local on, volume = Audio.Get(kind.key)
        if on == nil then on, volume = true, 1 end
        sounds[kind.key] = { on = on, volume = volume }
    end
    return sounds
end

-------------------------------------------------------------------------------
--  The profiles
-------------------------------------------------------------------------------
-- A name as it is kept: without spaces at its ends, at most Audio.LETTERS long; nil for none.
local function Clean(name)
    if type(name) ~= "string" then return nil end
    name = name:match("^%s*(.-)%s*$"):sub(1, Audio.LETTERS)
    return name ~= "" and name or nil
end

local function Find(name)
    for index, profile in ipairs(kept.profiles) do
        if profile.name == name then return profile, index end
    end
    return nil
end

local function Taken(name)
    for _, profile in ipairs(kept.profiles) do
        if profile.name:lower() == name:lower() then return true end
    end
    return false
end

-- A profile's sounds of the right kind: one missing or spoiled (an older shape, a hand edit) is the game's now.
local function Settle(sounds)
    local now, settled = Now(), {}
    for _, kind in ipairs(Audio.KINDS) do
        local entry = type(sounds) == "table" and sounds[kind.key]
        local volume = type(entry) == "table" and type(entry.volume) == "number" and Volume(entry.volume)
        if type(entry) == "table" and type(entry.on) == "boolean" and volume then
            settled[kind.key] = { on = entry.on, volume = volume }
        else
            settled[kind.key] = now[kind.key]
        end
    end
    return settled
end

-- The account's: { profiles = { { name, sounds = { [key] = { on, volume } } } }, current = name }, made right the
-- first time it is asked in a session; an account without any gets Audio.DEFAULTS.
local function Kept()
    local store = Core.Store(Core.name)
    if kept and store.audio == kept then return kept end
    if type(store.audio) ~= "table" then store.audio = {} end
    kept = store.audio
    local profiles = {}
    for _, profile in ipairs(type(kept.profiles) == "table" and kept.profiles or {}) do
        local name = type(profile) == "table" and Clean(profile.name)
        local double = false
        for _, other in ipairs(profiles) do double = double or (name and other.name:lower() == name:lower()) end
        if name and not double then profiles[#profiles + 1] = { name = name, sounds = Settle(profile.sounds) } end
    end
    if #profiles == 0 then
        local now = Now()
        for _, default in ipairs(Audio.DEFAULTS) do
            local sounds = {}
            for key, entry in pairs(now) do
                sounds[key] = { on = not (default.off and default.off[key]), volume = entry.volume }
            end
            profiles[#profiles + 1] = { name = default.name, sounds = sounds }
        end
    end
    kept.profiles = profiles
    if not Find(kept.current) then kept.current = profiles[1].name end
    return kept
end

function Audio.Names()
    local names = {}
    for _, profile in ipairs(Kept().profiles) do names[#names + 1] = profile.name end
    return names
end

function Audio.Current()
    return Kept().current
end

-- The game set to a profile's sounds, those this client has.
local function Apply(profile)
    for _, kind in ipairs(Audio.Kinds()) do
        local entry = profile.sounds[kind.key]
        Audio.Set(kind.key, entry.on, entry.volume)
    end
end

function Audio.Use(name)
    Kept()
    local profile = Find(name)
    if not profile then return false end
    kept.current = profile.name
    Apply(profile)
    Tell()
    return true
end

function Audio.Changed()
    local profile = Find(Kept().current)
    for _, kind in ipairs(Audio.Kinds()) do
        local on, volume = Audio.Get(kind.key)
        local entry = profile.sounds[kind.key]
        if on ~= entry.on or math.abs(volume - entry.volume) > Audio.EXACT then return true end
    end
    return false
end

function Audio.Save()
    Find(Kept().current).sounds = Now()
    Tell()
end

function Audio.Load()
    return Audio.Use(Kept().current)
end

function Audio.New(name)
    Kept()
    name = Clean(name)
    if not name then return false, Audio.TEXT.empty end
    if Taken(name) then return false, Audio.TEXT.taken:format(name) end
    kept.profiles[#kept.profiles + 1] = { name = name, sounds = Now() }
    kept.current = name
    Tell()
    return true
end

function Audio.Delete()
    local _, index = Find(Kept().current)
    if #kept.profiles < 2 then return false, Audio.TEXT.last end
    table.remove(kept.profiles, index)
    return Audio.Use(kept.profiles[1].name)
end

-------------------------------------------------------------------------------
--  The game's events
-------------------------------------------------------------------------------
-- One of the profiles' settings changed (ours, the game's options, its keys): the views told.
Core.On("CVAR_UPDATE", function(name)
    if type(name) == "string" and ours[name:lower()] then Tell() end
end)

-- A login, not a /reload nor another loading screen: the account's profile set again.
Core.On("PLAYER_ENTERING_WORLD", function(initial)
    if initial then Audio.Load() end
end)
