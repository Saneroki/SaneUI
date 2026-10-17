local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data
--  Sane UI's own databases, as a module reads them (Doc/guides/data.md, *In the game*). The data lives in
--  packs, load-on-demand addons (SaneUI_Data_<Pack>) compiled from the master in assets/data; each holds
--  one or more sets. A module asks for a set by its name and gets a handle, which works whether the set is
--  there or not:
--
--      local Items = SaneUI.Core.Data.Set("Items")   -- cheap, loads nothing, never nil
--      SaneUI.Core.Data.Prepare("Items")             -- load soon: after the loading screen, out of combat
--      local item = Items:Get(16801)                 -- the record, or nil: not known, not loaded yet, gone
--      Items:OnStamp(Redraw)                         -- told when the set arrives (or changes)
--
--  Get never loads a pack: it answers nil and asks for Prepare. Loading is a job of the scheduler
--  (Steps.lua): one pack a frame, alone in its frame, never in combat. Records are shared and read-only,
--  made for an entry when first asked for, and kept while anybody holds them.
--
--  Packs are found by their TOC lines (X-SaneUI-Sets, -Format, -Game), without loading them. A pack of
--  another format or game version is refused, and so is every pack on a client whose game version cannot
--  be told; a pack the player switched off stays off. A failure is said once, and the modules fall back.
-------------------------------------------------------------------------------
local Data = Core.Data -- made by Codec.lua
local Codec, Steps = Data.Codec, Core.Steps

Data.FORMAT = 1
Data.frozen = false -- the tests' switch: records handed out read-only, changes found by Data.Tampered()
local PREFIX = "SaneUI_Data_"
local CAMELOT = 18 -- WOW_PROJECT_CAMELOT, WoW: Forever's project number, should the global be missing
local LOADER = "data: packs"
local WEAK = { __mode = "v" }

local TEXT = {
    missing = "no data pack holds the set %s",
    off = "switched off in the addon list",
    refused = "%s is not used: %s",
    noGame = "this client's game version cannot be told, so no data pack is used",
    format = "of format %s, this Sane UI reads %d",
    otherGame = "made for %s, this client is %s",
    noSets = "it names no set",
    cannot = "the game cannot load it (%s)",
    notLoaded = "it did not load (%s)",
    noFile = "its file did not run",
    unreadable = "its fields cannot be read",
    twice = "two data packs hold the set %s; %s is used",
    badRow = "a row of %s cannot be read",
    -- /sane data
    about = "Sane UI's databases: the data packs, loaded or not (/sane data show <set> <key>)",
    client = "data of %s, build %s (project %s; beta: %s; test: %s).",
    unknown = "this client's game version cannot be told (project %s; beta: %s; test: %s): no data pack is used.",
    none = "no data pack is installed.",
    states = { ready = "loaded", loading = "loading", idle = "not loaded", off = "switched off", refused = "not used", missing = "missing" },
    pack = "%s: %s%s%s.",
    sets = " - %s",
    set = "%s %s",
    setBuild = "%s %s (build %d)",
    setState = "%s (%s: %s)",
    jobs = "jobs running: %s.",
    noJobs = "none",
    show = "%s %s: %s.",
    noEntry = "%s has no %s.",
    notReady = "%s is %s; asked for it: try again in a moment.",
    notThere = "%s is %s (%s).",
    usage = "/sane data show <set> <key>",
}

local packs = {}      -- [addon name] = { name, title, sets, format, game, state, why }
local packList = {}   -- the packs in the addon list's order
local owner = {}      -- [set name] = its pack
local sets = {}       -- [set name] = what Core knows of it (made by Add, or when something is said of it)
local handles = {}    -- [set name] = its handle
local listeners = {}  -- [set name] = { fn, ... } told when its stamp moves
local queue = {}      -- packs waiting to load
local said = {}       -- [label] = true: a failure is said once
local handed = {}     -- the records handed out while Data.frozen: { record, copy }
local found = false   -- the packs were looked for
local game, told      -- the client's game version, once told
local build           -- the client's build
local stamps = 0
local screen = true   -- the loading screen is up (Core is read during the login's)

local function Say(label, text, loud)
    if said[label] then return end
    said[label] = true
    if loud then Core.Report(label, text) else Core.NoteError(label, text) end
end

local function Internal(name)
    local set = sets[name]
    if not set then
        set = { name = name, stamp = 0, records = setmetatable({}, WEAK) }
        sets[name] = set
    end
    return set
end

local function ClientBuild()
    if not build then
        local _, number = Core.Ask(GetBuildInfo)
        build = tonumber(number) or 0
    end
    return build
end

local function Answer(name)
    return Core.Ask(rawget(_G, name)) and true or false
end

-- The client's game version: forever, forever-ptr or forever-beta; nil when it cannot be told.
local function Tell()
    local project = rawget(_G, "WOW_PROJECT_ID")
    if project == nil or project ~= (rawget(_G, "WOW_PROJECT_CAMELOT") or CAMELOT) then return nil end
    if Answer("IsBetaBuild") then return "forever-beta" end
    if Answer("IsPublicTestClient") or Answer("IsTestBuild") then return "forever-ptr" end
    return "forever"
end

function Data.Game()
    if not told then game, told = Tell(), true end
    return game
end

-------------------------------------------------------------------------------
--  Finding the packs
-------------------------------------------------------------------------------
local function Meta(name, field)
    local value = Core.Ask(C_AddOns.GetAddOnMetadata, name, field)
    return type(value) == "string" and value or nil
end

local function SetNames(text)
    local names = {}
    for name in (text or ""):gmatch("[^,%s]+") do names[#names + 1] = name end
    return names
end

local function Judge(pack, client, loadable, reason)
    if not client then return "refused", TEXT.noGame end
    if pack.format ~= tostring(Data.FORMAT) then return "refused", TEXT.format:format(tostring(pack.format), Data.FORMAT) end
    if pack.game ~= client then return "refused", TEXT.otherGame:format(tostring(pack.game), client) end
    if #pack.sets == 0 then return "refused", TEXT.noSets end
    local enabled = Core.Ask(C_AddOns.GetAddOnEnableState, pack.name, Core.Plain(UnitGUID("player")))
    if reason == "DISABLED" or enabled == 0 then return "off", TEXT.off end
    if loadable or reason == "DEMAND_LOADED" or reason == "DEP_DEMAND_LOADED" then return "idle" end
    return "refused", TEXT.cannot:format(tostring(reason))
end

-- Looks for the packs in the addon list, by their TOC lines; tells the client's game version anew. Done
-- once at first need (and by the tests): a pack added while the game runs is found after a restart.
function Data.Find()
    found, told = true, false
    local client = Data.Game()
    local old, api = packs, C_AddOns
    packs, packList, owner = {}, {}, {}
    for index = 1, Core.Ask(api.GetNumAddOns) or 0 do
        local ok, name, title, _, loadable, reason = pcall(api.GetAddOnInfo, index)
        name = ok and Core.Plain(name)
        if type(name) == "string" and name:sub(1, #PREFIX) == PREFIX then
            local pack = old[name] or { name = name }
            pack.title = Core.Plain(title) or name
            pack.sets, pack.format, pack.game = SetNames(Meta(name, "X-SaneUI-Sets")), Meta(name, "X-SaneUI-Format"), Meta(name, "X-SaneUI-Game")
            if pack.state ~= "ready" and pack.state ~= "loading" and not pack.failed then
                pack.state, pack.why = Judge(pack, client, Core.Plain(loadable), Core.Plain(reason))
            end
            packs[name], packList[#packList + 1] = pack, pack
            for _, set in ipairs(pack.sets) do
                if owner[set] then
                    Say("data: " .. set, TEXT.twice:format(set, owner[set].title), true)
                else
                    owner[set] = pack
                end
            end
        end
    end
end

local function Moved(set)
    stamps = stamps + 1
    set.stamp = stamps
    local handle = Data.Set(set.name)
    for _, fn in ipairs(listeners[set.name] or {}) do Core.Safe("data: " .. set.name, fn, handle) end
end

-- A pack's files have run (loaded by our loader, or by anybody): its sets that the files handed over are
-- ready, the others refused. A pack refused before keeps its state; its files refused their sets too.
local function Finish(pack)
    if pack.state == "ready" then return end
    if pack.state ~= "refused" then pack.state, pack.why = "ready", nil end
    for _, name in ipairs(pack.sets) do
        local set = Internal(name)
        if set.added and not set.ready then
            set.ready = true
            Moved(set)
        elseif not set.ready then
            set.refused, set.why = true, set.why or TEXT.noFile
            Say("data: " .. name, TEXT.refused:format(name, set.why), true)
        end
    end
end

local function Load(pack)
    local ok, loaded, reason = pcall(C_AddOns.LoadAddOn, pack.name)
    if not (ok and Core.Plain(loaded)) then
        pack.state, pack.why, pack.failed = "refused", TEXT.notLoaded:format(tostring(ok and Core.Plain(reason) or loaded)), true
        Say("data: " .. pack.name, TEXT.refused:format(pack.title, pack.why), true)
        return
    end
    Finish(pack)
end

-- The loader: one pack a frame, alone in its frame, once the loading screen is gone; never in combat
-- (the scheduler waits then). It ends while a loading screen is up and starts again after it.
local function Loader()
    while queue[1] do
        if screen then return end
        Steps.Fresh()
        if screen then return end
        Load(table.remove(queue, 1))
        Steps.Spend()
    end
end

local function Start()
    if not screen and queue[1] then Steps.Run(LOADER, Loader) end
end

-- Asks for a set's pack to be loaded soon. A pack missing, switched off or refused is said once.
function Data.Prepare(name)
    if not found then Data.Find() end
    local set = sets[name]
    if set and set.ready then return end
    local pack = owner[name]
    if not pack then
        Say("data: " .. tostring(name), TEXT.missing:format(tostring(name)))
    elseif pack.state == "idle" then
        pack.state = "loading"
        queue[#queue + 1] = pack
        Start()
    elseif pack.state == "off" then
        Say("data: " .. pack.name, TEXT.refused:format(pack.title, pack.why))
    elseif pack.state == "refused" then
        Say("data: " .. pack.name, TEXT.refused:format(pack.title, pack.why), true)
    end
end

-- Called by a pack's set file as it is read (Doc/guides/data.md, *A set's file*): nil for a format, set or
-- game version this Core does not take (the file stops there); else the table its rows, history and
-- indexes go into.
function Data.Add(format, name, header)
    if type(name) ~= "string" then return nil end
    local set = Internal(name)
    if set.added then return nil end -- handed over once already: the first stays
    if format ~= Data.FORMAT then
        set.refused, set.why = true, TEXT.format:format(tostring(format), Data.FORMAT)
        return nil
    end
    if type(header) ~= "table" or header.game ~= Data.Game() then
        set.refused, set.why = true, TEXT.otherGame:format(tostring(type(header) == "table" and header.game), tostring(Data.Game()))
        return nil
    end
    local ok, decode = pcall(Codec.Decoder, header.fields, header.types)
    if not ok then
        set.refused, set.why = true, TEXT.unreadable
        return nil
    end
    set.decode, set.fields = decode, header.fields
    set.patches = type(header.patches) == "table" and header.patches or {}
    set.rows, set.history, set.index = {}, {}, {}
    set.records = setmetatable({}, WEAK)
    set.added, set.refused, set.why = true, nil, nil
    local handle = Data.Set(name)
    handle.hash, handle.build = header.hash, header.build
    return set
end

-------------------------------------------------------------------------------
--  Records
-------------------------------------------------------------------------------
local FROZEN = { __newindex = function() error("a record of Sane UI's data is read-only", 2) end }

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = Copy(inner) end
    return copy
end

local function Same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not Same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function Freeze(value)
    for _, inner in pairs(value) do
        if type(inner) == "table" then Freeze(inner) end
    end
    setmetatable(value, FROZEN)
end

-- The first record handed out (while Data.frozen) that somebody changed since, or nil.
function Data.Tampered()
    for _, item in ipairs(handed) do
        if not Same(item.record, item.copy) then return item.record end
    end
    return nil
end

-- The row of the newest version this client has reached: a pack made for a later patch answers with
-- the version the client has.
local function Reached(set, key)
    local row = set.rows[key]
    if not row then return nil end
    local client = ClientBuild()
    if (Codec.Build(row) or 0) <= client then return row end
    local history = set.history[key]
    if not history then return nil end
    local versions = Codec.Versions(history)
    for index = #versions, 1, -1 do
        if (Codec.Build(versions[index]) or 0) <= client then return versions[index] end
    end
    return nil
end

local function Record(set, key)
    local record = set.records[key]
    if record then return record end
    local row = Reached(set, key)
    if not row then return nil end
    local ok, decoded = pcall(set.decode, row)
    if not ok then
        Say("data: " .. set.name .. " rows", TEXT.badRow:format(set.name), true)
        return nil
    end
    if decoded.gone then return nil end
    if Data.frozen then
        handed[#handed + 1] = { record = decoded, copy = Copy(decoded) }
        Freeze(decoded)
    end
    set.records[key] = decoded
    return decoded
end

-------------------------------------------------------------------------------
--  Handles
-------------------------------------------------------------------------------
local Handle = {}
Handle.__index = Handle

-- A set's handle: cheap, loads nothing, never nil; one per name.
function Data.Set(name)
    local handle = handles[name]
    if not handle then
        handle = setmetatable({ name = name }, Handle)
        handles[name] = handle
    end
    return handle
end

-- The record of the newest version this client has reached, or one of its fields; nil when not known,
-- not loaded (then the set's pack is asked for), no such entry, or gone. Never loads a pack.
function Handle:Get(key, field)
    local set = sets[self.name]
    if not (set and set.ready) then
        Data.Prepare(self.name)
        return nil
    end
    local record = Record(set, key)
    if record == nil or field == nil then return record end
    return record[field]
end

-- A number that moves when the set arrives (and later when learned or accepted data changes it).
function Handle:Stamp()
    local set = sets[self.name]
    return set and set.stamp or 0
end

-- fn(handle) after the stamp moved: a view redraws then instead of looking every frame.
function Handle:OnStamp(fn)
    local list = listeners[self.name] or {}
    listeners[self.name] = list
    list[#list + 1] = fn
end

-- ready, loading, idle (can be loaded, not asked for), missing, off or refused; and a few words why.
function Handle:State()
    if not found then Data.Find() end
    local set = sets[self.name]
    if set and set.ready then return "ready" end
    if set and set.refused then return "refused", set.why end
    local pack = owner[self.name]
    if not pack then return "missing", TEXT.missing:format(self.name) end
    if pack.state == "ready" then return "refused", TEXT.noFile end
    return pack.state, pack.why
end

function Handle:Ready()
    return (self:State()) == "ready"
end

-------------------------------------------------------------------------------
--  Events and /sane data
-------------------------------------------------------------------------------
Core.On("LOADING_SCREEN_ENABLED", function() screen = true end)
Core.On("LOADING_SCREEN_DISABLED", function()
    screen = false
    Start()
end)

-- A pack loaded, by our loader or by anybody: its sets are ready.
Core.On("ADDON_LOADED", function(name)
    if type(name) ~= "string" or name:sub(1, #PREFIX) ~= PREFIX then return end
    Core.Safe("data: " .. name, function()
        if not packs[name] then Data.Find() end
        if packs[name] then Finish(packs[name]) end
    end)
end)

local function Show(value)
    if type(value) ~= "table" then return tostring(value) end
    local parts = {}
    if #value > 0 then
        for _, inner in ipairs(value) do parts[#parts + 1] = Show(inner) end
    else
        for key, inner in pairs(value) do parts[#parts + 1] = tostring(key) .. " = " .. Show(inner) end
        table.sort(parts)
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

local function ShowEntry(name, key)
    local handle = Data.Set(name)
    if not handle:Ready() then
        local state, why = handle:State()
        if state == "idle" or state == "loading" then
            Data.Prepare(name)
            Core.Print(TEXT.notReady:format(name, TEXT.states[state]))
        else
            Core.Print(TEXT.notThere:format(name, TEXT.states[state] or state, tostring(why)))
        end
        return
    end
    local record = handle:Get(tonumber(key) or key)
    if not record then
        Core.Print(TEXT.noEntry:format(name, tostring(key)))
        return
    end
    Core.Print(TEXT.show:format(name, tostring(key), Show(record)))
end

local function YesNo(name)
    local fn = rawget(_G, name)
    if type(fn) ~= "function" then return "?" end
    return Answer(name) and "yes" or "no"
end

Core.Command("data", TEXT.about, function(rest)
    local word, name, key = (rest or ""):match("^(%S*)%s*(%S*)%s*(.-)$")
    if word == "show" then
        if name == "" or key == "" then Core.Print(TEXT.usage) else ShowEntry(name, key) end
        return
    end
    Data.Find()
    local project = tostring(rawget(_G, "WOW_PROJECT_ID"))
    local client = Data.Game()
    if client then
        Core.Print(TEXT.client:format(client, ClientBuild(), project, YesNo("IsBetaBuild"), YesNo("IsTestBuild")))
    else
        Core.Print(TEXT.unknown:format(project, YesNo("IsBetaBuild"), YesNo("IsTestBuild")))
    end
    if #packList == 0 then Core.Print(TEXT.none) end
    for _, pack in ipairs(packList) do
        local names = {}
        for _, set in ipairs(pack.sets) do
            local handle = Data.Set(set)
            local state, why = handle:State()
            if handle.hash and state == "ready" then
                local built = tonumber(handle.build) or 0
                names[#names + 1] = built > 0 and TEXT.setBuild:format(set, handle.hash, built) or TEXT.set:format(set, handle.hash)
            elseif pack.state == "ready" then
                names[#names + 1] = TEXT.setState:format(set, TEXT.states[state] or state, tostring(why))
            else
                names[#names + 1] = set
            end
        end
        local why = pack.state == "refused" and pack.why and " (" .. pack.why .. ")" or ""
        Core.Print(TEXT.pack:format(pack.title, TEXT.states[pack.state] or pack.state, why,
            #names > 0 and TEXT.sets:format(table.concat(names, ", ")) or ""))
    end
    local jobs = Steps.Jobs()
    Core.Print(TEXT.jobs:format(#jobs > 0 and table.concat(jobs, ", ") or TEXT.noJobs))
end)
