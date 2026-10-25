local ADDON = ...
local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data
--  Sane UI's own databases, as a module reads them (Doc/guides/data.md, *In the game*). The data is part of
--  Core: one file per set (Sets/<Set>.lua), compiled from the master in assets/data and listed at the end of
--  Core's TOC, so the game reads every set with Core, in the loading screen (Saneroki, 2026-10-21: the data is
--  wanted in the game anyway, and a second of loading screen and some memory are a fair price for it). A
--  module asks for a set by its name and gets a handle, which works whatever became of the set:
--
--      local Items = SaneUI.Core.Data.Set("Items")   -- cheap, never nil
--      local item = Items:Get(16801)                 -- the record, or nil: not known, gone, or no such set
--      Items:OnStamp(Redraw)                         -- told when the set changes (later: learned data)
--      SaneUI.Core.Data.WhenReady(Items, Draw)       -- once it is there: at once, as a rule
--      Items:Changes(16801)                          -- its history: also History, At, Versions; Keys, Each
--      Bosses:Unverified(1144, "l17076")             -- not yet confirmed by the game (the entry, or a part of it)
--
--  A set is ready once its file handed it over (Data.Add), which is before any module loads; Prepare and
--  WhenReady stay for the readers that ask before that, and for sets that come late (the tests). A set's
--  listeners are told on the next frame. Records are shared and read-only, made for an entry when first
--  asked for, and kept while anybody holds them.
--
--  A set file of another format or game version is refused, and so is every set on a client whose game
--  version cannot be told. A failure is said once, and the modules fall back.
--
--  What Core keeps in the game of the data is in saved variables of Core's TOC, SaneUIData_<Name> (Data.SAVED;
--  Characters is one). Core's own readers ask for one with Data.Saved(name, fn) and get its part of this
--  client's game version. What Core learns in play (Data.Learn) is kept in SaneUIData_Learned and read over
--  the sets while it is newer than they are.
-------------------------------------------------------------------------------
local Data = Core.Data -- made by Codec.lua
local Codec, Steps = Data.Codec, Core.Steps

Data.FORMAT = 1
Data.reports = {} -- what else /sane data prints: fn() each, after the sets (Tally.lua: what play counted)
Data.frozen = false -- the tests' switch: records handed out read-only, changes found by Data.Tampered()
-- The saved variables of Core's data, SaneUIData_<name>, as Core's TOC declares them.
Data.SAVED = { Characters = true, Guild = true, Learned = true }
local WEAK = { __mode = "v" }
local LIST, VERSION = "\030", "\028"

local TEXT = {
    missing = "Sane UI holds no set %s",
    noSaved = "%s is no saved variable of Sane UI's data",
    refused = "%s is not used: %s",
    noGame = "this client's game version cannot be told, so Sane UI's data is not used",
    format = "of format %s, this Sane UI reads %d",
    otherGame = "made for %s, this client is %s",
    unreadable = "its fields cannot be read",
    badRow = "a row of %s cannot be read",
    -- /sane data
    about = "Sane UI's databases: the sets and what they hold (/sane data show <set> <key>)",
    client = "data of %s, build %s (project %s; beta: %s; test: %s); %s.",
    unknown = "this client's game version cannot be told (project %s; beta: %s; test: %s): Sane UI's data is not used.",
    surnames = "players by first name and surname (regional names: %s)",
    realms = "players by name and realm (regional names: %s)",
    none = "no set is there.",
    states = { ready = "ready", loading = "loading", refused = "not used", missing = "missing" },
    set = "%s %s",
    setBuild = "%s %s (build %d)",
    setState = "%s (%s: %s)",
    sets = "sets: %s.",
    savedPart = "%s %d values",
    saved = "kept in the game: %s.",
    jobs = "jobs running: %s.",
    jobsPaused = "jobs running: %s; they wait while a fight or a restriction of the game's lasts.",
    job = "%s (%.1f ms in %d frames)",
    jobOne = "%s (%.1f ms in one frame)",
    noJobs = "none",
    show = "%s %s: %s.",
    change = "  %s: %s %s -> %s.",
    goneChange = "  %s: %s.",
    gone = "gone",
    back = "back again",
    empty = "empty",
    noEntry = "%s has no %s.",
    notReady = "%s is %s; try again in a moment.",
    notThere = "%s is %s (%s).",
    usage = "/sane data show <set> <key>",
}

local sets = {}       -- [set name] = what Core knows of it (made by Add, or when something is said of it)
local handles = {}    -- [set name] = its handle
local listeners = {}  -- [set name] = { fn, ... } told when its stamp moves
local waiting = {}    -- [set name] = { fn, ... } told once, when it is ready (WhenReady)
local owed = {}       -- the sets whose listeners are still to be told, in the order their stamps moved
local parts = {}      -- [saved name] = this client's part of SaneUIData_<name>, once a reader asked for it
local keepers = {}    -- [saved name] = { fn, ... }: handed its part once Core's saved variables are read
local said = {}       -- [label] = true: a failure is said once
local handed = {}     -- the records handed out while Data.frozen: { record, copy }
local arrived = false -- Core's files have run, the sets with them, and its saved variables are read
local holds = false   -- a set of this game version was taken: without any, its data is not made yet (Retail's)
local game, told      -- the client's game version, once told
local build           -- the client's build
local stamps = 0
local walks = 0       -- Each's jobs, numbered so that two walks over one set can run at once
local NONE = {}

local function Say(label, text, loud)
    if said[label] then return end
    said[label] = true
    if loud then Core.Report(label, text) else Core.NoteError(label, text) end
end

-- A set's answers made so far, kept while anybody holds them: records, histories, changes.
local function Forget(set)
    set.records, set.histories, set.changes = setmetatable({}, WEAK), setmetatable({}, WEAK), setmetatable({}, WEAK)
end

local function Internal(name)
    local set = sets[name]
    if not set then
        set = { name = name, stamp = 0 }
        Forget(set)
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

-- The client's game version: its game (Core.GAME: forever or retail), -beta or -ptr on a test client; nil
-- when it cannot be told.
local function Tell()
    local game = Core.GAME
    if not game then return nil end
    if Answer("IsBetaBuild") then return game .. "-beta" end
    if Answer("IsPublicTestClient") or Answer("IsTestBuild") then return game .. "-ptr" end
    return game
end

function Data.Game()
    if not told then game, told = Tell(), true end
    return game
end

-- Tells the client's game version and build anew, and forgets the answers made from them if either changed.
-- Done by /sane data and by the tests.
function Data.Retell()
    local wasGame, wasBuild = game, build
    told, build = false, nil
    Core.TellGame()
    if Data.Game() ~= wasGame or ClientBuild() ~= wasBuild then
        for _, set in pairs(sets) do Forget(set) end
    end
end

-- The listeners of the sets whose stamps moved: told on the next frame, outside the file that handed the set
-- over (a listener may start a job, or run a job's Check, which could not yield there). Those that wait for a
-- set to be ready (WhenReady) are told first, once.
local function TellListeners()
    local moved = owed
    owed = {}
    for _, set in ipairs(moved) do
        set.owed = nil
        local handle, label = Data.Set(set.name), "data: " .. set.name .. " listener"
        local once = set.ready and waiting[set.name]
        if once then
            waiting[set.name] = nil
            for _, fn in ipairs(once) do Core.Safe(label, fn, handle) end
        end
        for _, fn in ipairs(listeners[set.name] or NONE) do Core.Safe(label, fn, handle) end
    end
end
local TellSoon = Core.Later(TellListeners)

local function Moved(set)
    stamps = stamps + 1
    set.stamp = stamps
    if not set.owed then
        set.owed = true
        owed[#owed + 1] = set
    end
    TellSoon()
end

-- A saved variable of the data, SaneUIData_<name>, handed to its readers: keyed by game version first; this
-- client's part is made where it is missing, and one of a format this Core does not read is set aside under
-- broken, never wiped. Other game versions' parts (a copied WTF) are left as they are.
local function Keep(name)
    local client = Data.Game()
    if not client then
        Say("data: game", TEXT.noGame, true)
        return
    end
    local global = "SaneUIData_" .. name
    local all = rawget(_G, global)
    if type(all) ~= "table" then
        all = {}
        _G[global] = all
    end
    local part = all[client]
    if type(part) ~= "table" then
        part = {}
    elseif part.format ~= nil and part.format ~= Data.FORMAT then
        part = { broken = { part } }
    end
    all[client], part.format, parts[name] = part, Data.FORMAT, part
    local list = keepers[name] or NONE
    keepers[name] = nil
    for _, fn in ipairs(list) do Core.Safe("data: " .. name, fn, part) end
end

-- A set that cannot be had: said once, and remembered on the set, so that each Get after it costs one look
-- and makes no text.
local function Fail(name, label, text, loud)
    if type(name) == "string" then Internal(name).failed = true end
    Say(label, text, loud)
end

-- For a reader that asks before Core's files have all run: nothing to do then. Afterwards a set that is not
-- there is said once, quietly; not at all where this game version has no data yet (no set of it was taken):
-- the views that need it stand down without a word.
function Data.Prepare(name)
    if not arrived then return end
    local set = sets[name]
    if set and (set.ready or set.refused or set.failed) then return end
    if not holds then
        if type(name) == "string" then Internal(name).failed = true end
        return
    end
    Fail(name, "data: " .. tostring(name), TEXT.missing:format(tostring(name)))
end

-- For Core's own readers of the data's saved variables (Characters.lua): fn(part) with this client's part of
-- SaneUIData_<name>[game] (format checked), once Core's saved variables are read; at once when they are. A
-- name that is no saved variable of the data (Data.SAVED) is noted, and fn is never called.
function Data.Saved(name, fn)
    if not Data.SAVED[name] then
        Say("data: saved " .. tostring(name), TEXT.noSaved:format("SaneUIData_" .. tostring(name)))
        return
    end
    if parts[name] then
        Core.Safe("data: " .. name, fn, parts[name])
        return
    end
    local list = keepers[name] or {}
    keepers[name] = list
    list[#list + 1] = fn
    if arrived then Keep(name) end
end

-------------------------------------------------------------------------------
--  Learned
-------------------------------------------------------------------------------
-- What the game showed in play that a set does not hold yet (Doc/guides/data.md, *Learned*): kept in Core's saved
-- variable SaneUIData_Learned until a release takes it in, its part's learned[set][key] a whole row in the set's
-- format, of the client's build and the server's day. Read over the set's own newest version while it is newer;
-- dropped once the set has a version of that entry at its build and day or later (the release has seen that build
-- and decided, whether it agrees or not), so a wrong fact cannot stand over the sets for ever. Only Core learns
-- (Data.Learn, its watchers); the modules read the sets as ever.
local learned -- this client's learned rows ({ [set name] = { [key] = row } }), once Core's saved variables are read
local learnedPart -- its saved part: also builds[build] = the patch, for the harvest (dev/tools/data harvest)

-- Notes the client's build with its patch (GetBuildInfo), so the harvest can name the build of what was kept.
function Data.NoteBuild()
    if not learnedPart then return end
    if type(learnedPart.builds) ~= "table" then learnedPart.builds = {} end
    local patch, number = Core.Ask(rawget(_G, "GetBuildInfo"))
    number = tonumber(number)
    if number and type(patch) == "string" then learnedPart.builds[number] = patch end
end

-- A row's build and day (0 where it has none); nil for what is no row.
local function Stamped(row)
    if type(row) ~= "string" then return nil end
    local built, day = string.match(row, "^(%d+)\t(%d*)")
    return tonumber(built), tonumber(day) or 0
end

-- Whether a set's own row of an entry is as new as a learned one, or newer.
local function AsNew(own, row)
    local ownBuild, ownDay = Stamped(own)
    local build, day = Stamped(row)
    return ownBuild ~= nil and (ownBuild > build or (ownBuild == build and ownDay >= day))
end

-- A learned row laid over the set's own: the set's newest version goes into the entry's history, the learned one is
-- its newest (one learned again takes the place of the one before).
local function Lay(set, key, row)
    if not set.laid[key] and set.rows[key] then
        local before = set.history[key]
        set.history[key] = (type(before) == "string" and before .. VERSION or "") .. set.rows[key]
    end
    set.rows[key], set.laid[key] = row, true
end

-- A set's learned rows laid over its own; those the set is as new as, and what is no row, dropped.
local function Overlay(set)
    local rows = learned and learned[set.name]
    if rows == nil then return end
    if type(rows) ~= "table" then
        learned[set.name] = nil
        return
    end
    local laid = false
    for key, row in pairs(rows) do
        if not Stamped(row) or (set.rows[key] and AsNew(set.rows[key], row)) then
            rows[key] = nil
        else
            Lay(set, key, row)
            laid = true
        end
    end
    if next(rows) == nil then learned[set.name] = nil end
    if laid then
        Forget(set)
        Moved(set)
    end
end

-- The server's day, as days since 1970.
local function Today()
    local now = Core.Plain(Core.Ask(rawget(_G, "GetServerTime"))) or Core.Ask(rawget(_G, "time")) or 0
    return math.floor(now / 86400)
end

-- Learns an entry of a set from play (Core's watchers only): record, a whole record in the set's fields (the set's own
-- with what the game showed put in), kept as a row of this client's build and the server's day and read over the set's
-- at once; its listeners are told on the next frame. False when it cannot be kept: the set not ready, Core's saved
-- variables not read yet, a value its fields cannot hold, or no field at all.
function Data.Learn(name, key, record)
    local set = sets[name]
    if not (learned and set and set.ready and set.encode) or key == nil or type(record) ~= "table" then return false end
    local ok, body = pcall(set.encode, record)
    if not ok or body == "" then return false end
    local row = ClientBuild() .. "\t" .. Today() .. body
    Data.NoteBuild()
    if type(learned[name]) ~= "table" then learned[name] = {} end
    learned[name][key] = row
    Lay(set, key, row)
    Forget(set)
    Moved(set)
    return true
end

-- A row learned by somebody else's Sane UI (Confirm.lua, a guild or group member's): kept and read over the set's as one
-- learned here, when it can be read and accept(record, current) says so (current: the entry as this client has it, or
-- nil). False when it is not taken.
function Data.LearnRow(name, key, row, accept)
    local set = sets[name]
    if not (learned and set and set.ready and set.decode) or key == nil or not Stamped(row) then return false end
    local ok, record = pcall(set.decode, row)
    if not ok or type(record) ~= "table" or record.gone then return false end
    if set.rows[key] and AsNew(set.rows[key], row) then return false end
    if type(accept) ~= "function" or not accept(record, Data.Set(name):Get(key)) then return false end
    if type(learned[name]) ~= "table" then learned[name] = {} end
    learned[name][key] = row
    Lay(set, key, row)
    Forget(set)
    Moved(set)
    return true
end

-- The row Core learned of an entry here, or nil (Confirm.lua shares it).
function Data.Learned(name, key)
    local rows = learned and learned[name]
    return type(rows) == "table" and rows[key] or nil
end

-- Core's saved variables read: what was learned before laid over the sets there (as a rule all of them: their files
-- run with Core's).
Data.Saved("Learned", function(part)
    if type(part.learned) ~= "table" then part.learned = {} end
    learned, learnedPart = part.learned, part
    for _, set in pairs(sets) do
        if set.ready then Overlay(set) end
    end
end)

-- Called by a set's file as it is read (Doc/guides/data.md, *A set's file*): nil for a format, set or game
-- version this Core does not take (the file stops there); else the table its rows, history and indexes go
-- into. The set is ready from then on (nobody reads it before its file has run to its end), and its
-- listeners are told on the next frame.
function Data.Add(format, name, header)
    if type(name) ~= "string" then return nil end
    local set = Internal(name)
    if set.added then return nil end -- handed over once already: the first stays
    local why
    local client = Data.Game()
    if format ~= Data.FORMAT then
        why = TEXT.format:format(tostring(format), Data.FORMAT)
    elseif not client then
        set.refused, set.why = true, TEXT.noGame
        Say("data: game", TEXT.noGame, true)
        return nil
    elseif type(header) ~= "table" or header.game ~= client then
        -- A copy of Sane UI made for another game folder: every set of it is another game version's, said once.
        set.refused = true
        set.why = TEXT.otherGame:format(tostring(type(header) == "table" and header.game), client)
        Say("data: game", TEXT.refused:format("Sane UI's data", set.why), true)
        return nil
    end
    local ok, decode
    if not why then
        ok, decode = pcall(Codec.Decoder, header.fields, header.types)
        if not ok then why = TEXT.unreadable end
    end
    if why then
        set.refused, set.why = true, why
        Say("data: " .. name, TEXT.refused:format(name, why), true)
        return nil
    end
    set.decode, set.fields, set.key = decode, header.fields, header.key
    set.named = {}
    for index, field in ipairs(header.fields) do set.named[field] = index end
    -- The fields play can tell (the schema's play): an entry is confirmed whole once the game told each it holds.
    set.play = type(header.play) == "table" and header.play or nil
    local writes, encode = pcall(Codec.Encoder, header.fields, header.types)
    set.encode = writes and encode or nil -- without, nothing of it is learned; it is read all the same
    set.patches = type(header.patches) == "table" and header.patches or {}
    set.rows, set.history, set.index, set.laid = {}, {}, {}, {}
    Forget(set)
    set.added, set.ready, set.refused, set.failed, set.why = true, true, nil, nil, nil
    holds = true
    local handle = Data.Set(name)
    handle.hash, handle.build = header.hash, header.build
    Moved(set)
    -- Its rows are filled once its file has run to its end: what was learned of it is laid over them then.
    if learned then Core.Later(function() Overlay(set) end)() end
    return set
end

-------------------------------------------------------------------------------
--  Records
-------------------------------------------------------------------------------
local FROZEN = { __newindex = function() error("a record of Sane UI's data is read-only", 2) end }
local Copy, Same = Core.Copy, Core.Same

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

-- Hands a record or an array out. While Data.frozen (the tests) it is made read-only and kept with a copy,
-- so a change is found.
local function Hand(value)
    if Data.frozen then
        handed[#handed + 1] = { record = value, copy = Copy(value) }
        Freeze(value)
    end
    return value
end

-- A row taken apart, with the patch its build is (builds.toml, through the set's file); nil for a row that cannot
-- be read (said once).
local function Decode(set, row)
    local ok, record = pcall(set.decode, row)
    if not ok or type(record) ~= "table" then
        Say("data: " .. set.name .. " rows", TEXT.badRow:format(set.name), true)
        return nil
    end
    record.patch = set.patches[record.since]
    return record
end

-- The row of the newest version this client has reached: a set made for a later patch answers with
-- the version the client has.
local function Reached(set, key)
    local row = set.rows[key]
    if type(row) ~= "string" then return nil end
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
    record = Decode(set, row)
    if not record or record.gone then return nil end
    set.records[key] = Hand(record)
    return record
end

-- Every version of an entry this client has reached, oldest first; the newest is the record Get gives.
local function History(set, key)
    local list = set.histories[key]
    if list then return list end
    local row = set.rows[key]
    if type(row) ~= "string" then return nil end
    local rows = Codec.Versions(set.history[key])
    rows[#rows + 1] = row
    local client = ClientBuild()
    while rows[1] and (Codec.Build(rows[#rows]) or 0) > client do rows[#rows] = nil end
    if not rows[1] then return nil end
    list = {}
    for index, version in ipairs(rows) do
        local record = index == #rows and Record(set, key) or Decode(set, version)
        if record then list[#list + 1] = record end
    end
    set.histories[key] = Hand(list)
    return list
end

-- What changed from each version to the next, oldest first: one change per field, in the set's order;
-- an entry gone or back is the field "gone", from false to true or from true to false.
local function Changes(set, key)
    local list = set.changes[key]
    if list then return list end
    local history = History(set, key)
    if not history then return nil end
    list = {}
    for index = 2, #history do
        local before, after = history[index - 1], history[index]
        if before.gone or after.gone then
            list[#list + 1] = { since = after.since, day = after.day, patch = after.patch, field = TEXT.gone,
                                from = before.gone or false, to = after.gone or false }
        else
            for _, field in ipairs(set.fields) do
                if not Same(before[field], after[field]) then
                    list[#list + 1] = { since = after.since, day = after.day, patch = after.patch, field = field,
                                        from = before[field], to = after[field] }
                end
            end
        end
    end
    set.changes[key] = Hand(list)
    return list
end

-------------------------------------------------------------------------------
--  Handles
-------------------------------------------------------------------------------
local Handle = {}
Handle.__index = Handle

-- A set's handle: cheap, never nil; one per name.
function Data.Set(name)
    local handle = handles[name]
    if not handle then
        handle = setmetatable({ name = name }, Handle)
        handles[name] = handle
    end
    return handle
end

-- The set when it is ready; else nil (a set not there is said once).
local function Ready(handle)
    local set = sets[handle.name]
    if set and set.ready then return set end
    Data.Prepare(handle.name)
    return nil
end

-- The record of the newest version this client has reached, or one of its fields; nil when not known,
-- not there, no such entry, or gone.
function Handle:Get(key, field)
    local set = Ready(self)
    if not set then return nil end
    local record = Record(set, key)
    if record == nil or field == nil then return record end
    return record[field]
end

-- The record as it was at a build (of this client's game version), or nil: not known, not yet there, gone.
function Handle:At(key, at)
    local set = Ready(self)
    local list = set and type(at) == "number" and History(set, key)
    if not list then return nil end
    for index = #list, 1, -1 do
        local record = list[index]
        if (record.since or 0) <= at then
            if record.gone then return nil end
            return record
        end
    end
    return nil
end

-- Every version this client has reached, oldest first, each with since, day, patch, and gone = true for a
-- gone one; nil when not known.
function Handle:History(key)
    local set = Ready(self)
    return set and History(set, key) or nil
end

-- The last n versions of History, oldest first.
function Handle:Versions(key, n)
    local list = self:History(key)
    if not list then return nil end
    local first = math.max(1, #list - (tonumber(n) or #list) + 1)
    local last = {}
    for index = first, #list do last[#last + 1] = list[index] end
    return Hand(last)
end

-- { since, day, patch, field, from, to } for every change, oldest first (an empty array for an entry that
-- never changed); nil when not known.
function Handle:Changes(key)
    local set = Ready(self)
    return set and Changes(set, key) or nil
end

-- The keys an index of the set lists for a value (the schema's indexes, replaces and replacedBy), from the
-- entries' newest versions; an empty array when none.
function Handle:Keys(index, value)
    local set = Ready(self)
    local keys = {}
    local list = set and set.index[index]
    local joined = type(list) == "table" and list[value]
    if type(joined) == "string" then
        for _, key in ipairs(Codec.Cut(joined, LIST)) do keys[#keys + 1] = set.key == "int" and tonumber(key) or key end
    end
    return Hand(keys)
end

-- A job of the scheduler: fn(key, record) for every entry this client has (gone ones left out), out of
-- combat and within the frame's budget; then done(problem): nil after the last entry, the error's text when
-- fn failed (the walk stops there). Gives the job's handle (job:Stop()); false when the set is not ready (it
-- is asked for). A failing fn is noted under one label per set, however often the set is walked.
function Handle:Each(fn, done)
    local set = Ready(self)
    if not set or type(fn) ~= "function" then return false end
    walks = walks + 1
    return Steps.Run({ name = ("Each %s %d"):format(self.name, walks), label = "data job Each " .. self.name,
        done = type(done) == "function" and done or nil }, function()
        local keys = {}
        for key in pairs(set.rows) do keys[#keys + 1] = key end
        for _, key in ipairs(keys) do
            local record = Record(set, key)
            if record then fn(key, record) end
            Steps.Check()
        end
    end)
end

-- Whether an entry (or a part of it: a boss's item "l17076", an ability "a8269") is not yet confirmed by the game:
-- its newest version came from a batch alone (the set's file lists those, S.unverified; Doc/guides/data.md,
-- *Verified*), and nothing confirmed it since in play, here or by a guild or group member (Data.Confirmed,
-- Confirm.lua). An entry learned in play is the game's. False for a set that is not ready, or an entry it lacks.
function Handle:Unverified(key, part)
    local set = sets[self.name]
    if not (set and set.ready) or key == nil or set.laid[key] then return false end
    local marks = set.marks
    if not marks then
        marks = {}
        if type(set.unverified) == "string" then
            for _, each in ipairs(Codec.Cut(set.unverified, LIST)) do
                marks[set.key == "int" and tonumber(each) or each] = true
            end
        end
        set.marks = marks
    end
    if not marks[key] then return false end
    local confirmed = Data.Confirmed
    return not (confirmed and confirmed(self.name, key, part))
end

-- Whether the set has a field of that name; false while it is not ready.
function Handle:HasField(field)
    local set = sets[self.name]
    return set ~= nil and set.ready == true and set.named[field] ~= nil
end

-- The fields play can tell of the set's entries (the schema's play), or every field where it names none; an empty
-- array while the set is not ready.
function Handle:PlayFields()
    local set = sets[self.name]
    if not (set and set.ready) then return NONE end
    return set.play or set.fields
end

-- Whether an entry is one Core learned in play (its row the game's, laid over the set's).
function Handle:Learned(key)
    local set = sets[self.name]
    return set ~= nil and set.ready == true and set.laid[key] == true
end

-- A number that moves when the set arrives (and later when learned or accepted data changes it).
function Handle:Stamp()
    local set = sets[self.name]
    return set and set.stamp or 0
end

-- A list of listeners is never changed while it is walked: one added or taken away makes a new list.
local function Without(list, fn)
    local rest = {}
    for _, known in ipairs(list or NONE) do
        if known ~= fn then rest[#rest + 1] = known end
    end
    return rest
end

-- fn(handle) on the frame after the stamp moved: a view redraws then instead of looking every frame. A fn
-- given twice is told once.
function Handle:OnStamp(fn)
    local list = Without(listeners[self.name], fn)
    list[#list + 1] = fn
    listeners[self.name] = list
end

-- Stops telling fn: one given to OnStamp, or one that waits for the set (WhenReady).
function Handle:OffStamp(fn)
    local list, once = Without(listeners[self.name], fn), Without(waiting[self.name], fn)
    listeners[self.name], waiting[self.name] = list[1] and list or nil, once[1] and once or nil
end

-- ready; refused or missing, and a few words why; loading while Core's files are still being read.
function Handle:State()
    local set = sets[self.name]
    if set and set.ready then return "ready" end
    if set and set.refused then return "refused", set.why end
    if not arrived then return "loading" end
    return "missing", TEXT.missing:format(self.name)
end

function Handle:Ready()
    return (self:State()) == "ready"
end

-- fn(handle) once the set (its handle or its name) is ready: at once if it is, in the caller's own call;
-- else on the frame after it arrived, once. OffStamp takes it back meanwhile.
function Data.WhenReady(set, fn)
    local handle = getmetatable(set) == Handle and set or Data.Set(set)
    if handle:Ready() then
        fn(handle)
        return
    end
    local list = Without(waiting[handle.name], fn)
    list[#list + 1] = fn
    waiting[handle.name] = list
    Data.Prepare(handle.name)
end

-------------------------------------------------------------------------------
--  Events and /sane data
-------------------------------------------------------------------------------
-- Core's files have run, the set files at their end, and its saved variables are read: the readers of those
-- are handed their parts, and a set asked for from now on that is not there is missing.
Core.On("ADDON_LOADED", function(name)
    if name ~= ADDON or arrived then return end
    arrived = true
    for saved in pairs(keepers) do Core.Safe("data: " .. saved, Keep, saved) end
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
        if state == "loading" then
            Core.Print(TEXT.notReady:format(name, TEXT.states[state]))
        else
            Core.Print(TEXT.notThere:format(name, TEXT.states[state] or state, tostring(why)))
        end
        return
    end
    local set = sets[name]
    key = set and set.key == "int" and tonumber(key) or key -- a text key may look like a number ("7")
    local record = handle:Get(key)
    if not record then
        Core.Print(TEXT.noEntry:format(name, tostring(key)))
        return
    end
    Core.Print(TEXT.show:format(name, tostring(key), Show(record)))
    for _, change in ipairs(handle:Changes(key) or NONE) do
        local when = change.patch or tostring(change.since)
        if change.field == TEXT.gone then
            Core.Print(TEXT.goneChange:format(when, change.to and TEXT.gone or TEXT.back))
        else
            Core.Print(TEXT.change:format(when, change.field, change.from == nil and TEXT.empty or Show(change.from),
                change.to == nil and TEXT.empty or Show(change.to)))
        end
    end
end

local function YesNo(name)
    local fn = rawget(_G, name)
    if type(fn) ~= "function" then return "?" end
    return Answer(name) and "yes" or "no"
end

-- Sets and parts in the order of their names: what /sane data lists.
local function Sorted(list)
    local names = {}
    for name in pairs(list) do names[#names + 1] = name end
    table.sort(names)
    return names
end

-- How much a saved part holds: its values, and those of the tables in it.
local function Size(part)
    local size = 0
    for key, value in pairs(part) do
        if key ~= "format" then
            if type(value) == "table" then
                for _ in pairs(value) do size = size + 1 end
            else
                size = size + 1
            end
        end
    end
    return size
end

Core.Command("data", TEXT.about, function(rest)
    local word, name, key = (rest or ""):match("^(%S*)%s*(%S*)%s*(.-)$")
    if word == "show" then
        if name == "" or key == "" then Core.Print(TEXT.usage) else ShowEntry(name, key) end
        return
    end
    Data.Retell()
    local project = tostring(rawget(_G, "WOW_PROJECT_ID"))
    local client = Data.Game()
    if client then
        local names = (Core.Surnames() and TEXT.surnames or TEXT.realms):format(YesNo("RegionalUniqueNamesEnabled"))
        Core.Print(TEXT.client:format(client, ClientBuild(), project, YesNo("IsBetaBuild"), YesNo("IsTestBuild"), names))
    else
        Core.Print(TEXT.unknown:format(project, YesNo("IsBetaBuild"), YesNo("IsTestBuild")))
    end
    local names = {}
    for _, each in ipairs(Sorted(sets)) do
        local handle = Data.Set(each)
        local state, why = handle:State()
        if state == "ready" then
            local built = tonumber(handle.build) or 0
            names[#names + 1] = built > 0 and TEXT.setBuild:format(each, tostring(handle.hash), built) or TEXT.set:format(each, tostring(handle.hash))
        else
            names[#names + 1] = TEXT.setState:format(each, TEXT.states[state] or state, tostring(why))
        end
    end
    Core.Print(#names > 0 and TEXT.sets:format(table.concat(names, ", ")) or TEXT.none)
    local kept = {}
    for _, each in ipairs(Sorted(parts)) do kept[#kept + 1] = TEXT.savedPart:format(each, Size(parts[each])) end
    if #kept > 0 then Core.Print(TEXT.saved:format(table.concat(kept, ", "))) end
    local jobs = {}
    for index, job in ipairs(Steps.Jobs()) do
        jobs[index] = (job.frames == 1 and TEXT.jobOne or TEXT.job):format(tostring(job.name), job.ms, job.frames)
    end
    local line = #jobs > 0 and Steps.Paused() and TEXT.jobsPaused or TEXT.jobs
    Core.Print(line:format(#jobs > 0 and table.concat(jobs, ", ") or TEXT.noJobs))
    for _, fn in ipairs(Data.reports) do Core.Safe("data: /sane data", fn) end
end)
