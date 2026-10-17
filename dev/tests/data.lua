-- Runs Core's data framework against the stand-in client (wowstub.lua): the scheduler (Steps.lua), and from
-- step 1a.5 on the packs compiled from the sample master (dev/tests/data/sample) as the game loads them.
-- Usage, from the project folder:  lua5.1 dev/tests/data.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function printedMatch(pattern)
    for _, line in ipairs(W.printed) do if line:find(pattern) then return true end end
    return false
end

W.LoadCore(root)
local Core = SaneUI.Core
SaneUIDB = {}
W.Fire("ADDON_LOADED", "SaneUI")
W.Fire("PLAYER_LOGIN")

-------------------------------------------------------------------------------
--  The scheduler
-------------------------------------------------------------------------------
local Steps = Core.Steps
local frame = Steps.frame
check(frame and not frame:IsShown() and not frame._scripts.OnUpdate, "the scheduler's frame is hidden, with no OnUpdate, while there is no work")

-- One frame of the game: the scheduler's OnUpdate, if it has one; returns how many milliseconds of work it did.
local function Frame()
    W.ms = W.ms + 10 -- the game's own work between two frames
    local before = W.ms
    if frame:IsShown() and frame._scripts.OnUpdate then frame._scripts.OnUpdate(frame, 0.016) end
    return W.ms - before
end
local function Budget() return math.min(Steps.BUDGET, 1000 / W.fps * Steps.SHARE) end

-- A job of pieces of work, each `cost` milliseconds; done counts them.
local function Worker(pieces, cost, done)
    return function(extra)
        for _ = 1, pieces do
            W.ms = W.ms + cost
            done.n = done.n + 1 + (extra or 0)
            Steps.Check()
        end
        done.finished = true
    end
end

local one = { n = 0 }
check(Steps.Run("one", Worker(100, 0.1, one)) == true and frame:IsShown() and frame._scripts.OnUpdate, "a job started: the frame is shown, with its OnUpdate")
check(Steps.Run("one", Worker(1, 0.1, {})) == false, "a job of the same name is not started twice")
check(Steps.Running("one") and Steps.Jobs()[1] == "one", "it is known to be running, by its name")
check(one.n == 0, "nothing runs before the next frame")
local spent = Frame()
check(spent <= Budget() + 0.1 + 1e-9 and spent >= Budget() - 1e-9, "a frame at 60 frames a second spends a quarter of it, no more than a piece over")
for _ = 1, 30 do Frame() end
check(one.finished and not Steps.Running("one") and not frame:IsShown() and not frame._scripts.OnUpdate, "done: the job is gone, the frame hidden again")

-- The budget follows the frame rate, and never passes 5 ms
for _, fps in ipairs({ 20, 60, 144, 240 }) do
    W.fps = fps
    local done = { n = 0 }
    Steps.Run("rate", Worker(1000, 0.05, done))
    local most = 0
    for _ = 1, 200 do most = math.max(most, Frame()) end
    check(done.finished and most <= Budget() + 0.05 + 1e-9, ("at %d frames a second no frame works over %.2f ms"):format(fps, Budget()))
    check(Budget() <= Steps.BUDGET, "never over 5 ms")
end
W.fps = 60

-- Many jobs at once: still one budget, and every job goes on
local many = {}
for index = 1, 12 do
    many[index] = { n = 0 }
    Steps.Run("many" .. index, Worker(50, 0.2, many[index]))
end
local most, frames = 0, 0
repeat
    most, frames = math.max(most, Frame()), frames + 1
until not frame:IsShown() or frames > 1000
local all = true
for index = 1, 12 do all = all and many[index].finished end
check(all and most <= Budget() + 0.2 + 1e-9, "twelve jobs queued: no frame over the budget, and all of them finish")
local early = {}
for index = 1, 3 do
    early[index] = { n = 0 }
    Steps.Run("turn" .. index, Worker(100, 1, early[index]))
end
for _ = 1, 3 do Frame() end
check(early[1].n > 0 and early[2].n > 0 and early[3].n > 0, "each job gets its turn first in some frame")
for _ = 1, 200 do Frame() end

-- Arguments, and a job that ends at once
local got
Steps.Run("args", function(a, b, c) got = { a, b, c } end, 1, nil, "three")
Frame()
check(got and got[1] == 1 and got[2] == nil and got[3] == "three" and not frame:IsShown(), "a job gets its arguments, holes too, and ends")

-- Nothing in combat, and after it the jobs go on
local fight = { n = 0 }
Steps.Run("fight", Worker(200, 0.5, fight))
Frame()
local before = fight.n
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
check(not frame:IsShown() and not frame._scripts.OnUpdate, "a fight begins: the scheduler stops")
for _ = 1, 5 do Frame() end
check(fight.n == before, "nothing runs in a fight")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(frame:IsShown(), "the fight ends: it goes on")
Frame()
check(fight.n > before, "and the job does its next piece")

-- Combat known only from the game's answer, without the event first
W.combat = true
Frame()
check(not frame:IsShown(), "in a fight the frame stops itself even before the event")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")

-- Nothing while the game restricts addons (an encounter); chat's restriction does not stop it
W.restrictions[1] = true
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 2)
check(not frame:IsShown(), "an encounter's restriction stops the scheduler")
before = fight.n
Frame()
check(fight.n == before, "nothing runs under it")
W.restrictions[1] = nil
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 0)
check(frame:IsShown(), "it ends: the scheduler goes on")
W.restrictions[5] = true
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 5, 2)
check(frame:IsShown(), "chat's restriction does not stop it")
W.restrictions[5] = nil
for _ = 1, 400 do Frame() end
check(fight.finished, "the job finished after the pauses")

-- A job that fails is dropped and reported; the others go on
local fine = { n = 0 }
Steps.Run("broken", function()
    W.ms = W.ms + 0.1
    Steps.Check()
    error("a broken step")
end)
Steps.Run("fine", Worker(20, 0.5, fine))
W.printed = {}
for _ = 1, 20 do Frame() end
check(not Steps.Running("broken") and fine.finished, "a job that errors is dropped, the others finish")
check(printedMatch("problem in data job broken") and Core.errors["data job broken"]
    and Core.errors["data job broken"].text:find("a broken step"), "and it is reported, once, in the error log")

-- Check outside a job does nothing; Fresh and Spend
Steps.Check()
check(true, "Check outside a job returns at once")
local order = {}
Steps.Run("busy", function()
    for _ = 1, 3 do
        order[#order + 1] = "busy"
        W.ms = W.ms + 1
        Steps.Check()
    end
end)
Steps.Run("load", function()
    Steps.Fresh()
    order[#order + 1] = "load at " .. tostring(W.ms)
    W.ms = W.ms + 20 -- a step that cannot be cut
    Steps.Spend()
    order[#order + 1] = "after load"
end)
local frames = {}
for index = 1, 6 do
    local start = W.ms + 10
    local count = #order
    Frame()
    frames[index] = { start = start, from = count + 1, to = #order }
end
local loadFrame
for index, seen in ipairs(frames) do
    for at = seen.from, seen.to do if order[at]:match("^load at") then loadFrame = seen end end
end
check(loadFrame and order[loadFrame.from]:match("^load at") and loadFrame.to == loadFrame.from,
    "Fresh: the step that cannot be cut runs first in a frame of its own, and Spend lets nothing run after it")
check(order[#order] == "after load" or order[#order] == "busy", "and the job goes on in a later frame")
for _ = 1, 10 do Frame() end
check(not frame:IsShown(), "all done, the frame is hidden again")

-------------------------------------------------------------------------------
--  Packs: the sample master compiled by the tools (dev/tests/data/sample.py), read as the game reads them
-------------------------------------------------------------------------------
local Data, Codec = Core.Data, Core.Data.Codec
local folder = io.popen("mktemp -d -t saneui-data-XXXXXX"):read("*l")
check(folder and os.execute(("python3 -I '%s/dev/tests/data/sample.py' '%s'"):format(root, folder)) == 0,
    "the tools compiled the sample master into packs")
local expected = {
    forever = dofile(folder .. "/expected-forever.lua"),
    ["forever-beta"] = dofile(folder .. "/expected-forever-beta.lua"),
}
local PACKS = { { "Gear", { "Folk", "Gear" } }, { "Words", { "Labels" } } }

-- The first difference between what Lua read and what the tools meant, or nil when there is none.
local function Differ(got, want, where)
    where = where or "the record"
    if type(got) ~= "table" or type(want) ~= "table" then
        if got ~= want then return ("%s is %s, not %s"):format(where, tostring(got), tostring(want)) end
        return nil
    end
    for key, value in pairs(want) do
        local problem = Differ(got[key], value, where .. "." .. tostring(key))
        if problem then return problem end
    end
    for key, value in pairs(got) do
        if want[key] == nil then return ("%s.%s is %s, and should not be there"):format(where, tostring(key), tostring(value)) end
    end
    return nil
end

-- A compiled set file run with a stand-in Data.Add: what its header said and what it put into its tables.
local function Read(path)
    local add, got = Data.Add, {}
    Data.Add = function(format, name, header)
        got.format, got.name, got.header = format, name, header
        got.rows, got.history, got.index = {}, {}, {}
        return got
    end
    local ok, problem = pcall(dofile, path)
    Data.Add = add
    if not ok then error(problem, 2) end
    return got
end

-- The codec both ways: every row the tools wrote, of both game versions, read back as they meant it
local files = {}
for game, sets in pairs(expected) do
    for _, pack in ipairs(PACKS) do
        for _, name in ipairs(pack[2]) do
            local file = Read(("%s/%s/SaneUI_Data_%s/%s.lua"):format(folder, game, pack[1], name))
            files[game .. " " .. name] = file
            check(file.format == Data.FORMAT and file.name == name and file.header.game == game
                and file.header.hash:match("^%x%x%x%x%x%x%x%x$"), ("%s's file of %s: format, name, game and hash"):format(name, game))
            local decode = Codec.Decoder(file.header.fields, file.header.types)
            local problem, keys, rows = nil, 0, 0
            for key, versions in pairs(sets[name]) do
                keys = keys + 1
                local list = file.history[key] and Codec.Versions(file.history[key]) or {}
                list[#list + 1] = file.rows[key]
                if #list ~= #versions then
                    problem = problem or ("%s has %d versions, not %d"):format(tostring(key), #list, #versions)
                end
                for index, version in ipairs(versions) do
                    if list[index] then
                        local got = decode(list[index])
                        got.patch = file.header.patches[got.since] -- as Data.lua names it
                        problem = problem or Differ(got, version, ("%s's version %d"):format(tostring(key), index))
                        if Codec.Build(list[index]) ~= version.since then problem = problem or tostring(key) .. "'s build" end
                    end
                end
            end
            for _ in pairs(file.rows) do rows = rows + 1 end
            check(not problem and rows == keys, ("the codec reads every row of %s (%s) as the tools wrote it%s"):format(name, game,
                problem and ": " .. problem or rows ~= keys and (": %d rows for %d entries"):format(rows, keys) or ""))
        end
    end
end
local liveGear = files["forever Gear"]
check(liveGear.index.bySlot.hands == "100" and Codec.Cut(liveGear.index.byFrom[1], "\030")[2] == "102"
    and liveGear.index.replaces[102] == "101", "the indexes are there, keys joined by character 30")
check(files["forever-beta Gear"].header.build == 66000 and liveGear.header.build == 65100
    and liveGear.header.patches[65000] == "1.60.0", "the header's build and patch names")

-- Nothing hostile raises an error: a broken row is read as far as it goes
local gearDecode = Codec.Decoder(liveGear.header.fields, liveGear.header.types)
local hostile = {
    "", "\t", "x\ty", "65100\t\tname\tnot a number\tnowhere\t\031\031\030x\031\030\031", "1\t2\t3\t4\t5\t6\t7\t8\t9\t10\t11\t12\t13\t14\t15",
    "0\t\t\t\t\t\t\t\t\t\t\t1\0312\030\0301\031\031\031\031\t\031\030=\031x\030\031",
}
local calm = true
for _, row in ipairs(hostile) do calm = calm and pcall(gearDecode, row) end
check(calm, "no broken row makes the codec raise an error")
check(gearDecode("65100\t")["gone"] and gearDecode("65100\t\t\t1").quality == 1, "a build and a day is a gone version; an empty field no value")
check(not pcall(Codec.Decoder, { "a" }, { "wobbly" }) and not pcall(Codec.Decoder, { "a" }, { "map bool int" }),
    "a type the codec does not know is an error (the set is refused then)")

-- A pack written by hand into the test's folder: its TOC and its files.
local function MakePack(name, sets, files, lines)
    local path = folder .. "/hand/SaneUI_Data_" .. name
    os.execute(("mkdir -p '%s'"):format(path))
    local toc = { "## Title: Data: " .. name, "## LoadOnDemand: 1", "## X-SaneUI-Sets: " .. sets, "## X-SaneUI-Format: 1",
                  "## X-SaneUI-Game: forever" }
    for _, line in ipairs(lines or {}) do toc[#toc + 1] = line end
    local names = {}
    for file in pairs(files) do names[#names + 1] = file end
    table.sort(names)
    for _, file in ipairs(names) do
        toc[#toc + 1] = file
        local out = assert(io.open(path .. "/" .. file, "w"))
        out:write(files[file])
        out:close()
    end
    local out = assert(io.open(path .. "/SaneUI_Data_" .. name .. ".toc", "w"))
    out:write(table.concat(toc, "\n") .. "\n")
    out:close()
    return path
end

local function Loaded()
    local count = 0
    for name in pairs(W.loaded) do if name:match("^SaneUI_Data_") then count = count + 1 end end
    return count
end

-- No pack yet: a handle all the same, nil, and said once, quietly
Data.frozen = true
local Gear, Labels, Folk = Data.Set("Gear"), Data.Set("Labels"), Data.Set("Folk")
check(Gear == Data.Set("Gear") and Gear.name == "Gear", "a set's handle: one per name, never nil")
W.printed = {}
check(Gear:State() == "missing" and not Gear:Ready() and Gear:Get(100) == nil and Gear:Get(100, "name") == nil,
    "no pack holds the set: missing, and Get answers nil")
check(Core.errors["data: Gear"] and Core.errors["data: Gear"].count == 1 and #W.printed == 0,
    "a missing set is noted once in the error log, quietly")
check(Gear.hash == nil and Gear.build == nil and Gear:Stamp() == 0, "no hash, no build, no stamp before it is loaded")

-- The packs installed: found by their TOC lines, not loaded
local live = folder .. "/forever/"
W.AddPack(live .. "SaneUI_Data_Gear")
W.AddPack(live .. "SaneUI_Data_Words")
Data.Find()
check(Gear:State() == "idle" and Labels:State() == "idle" and Folk:State() == "idle" and Loaded() == 0,
    "the packs found by their TOC lines: idle, nothing loaded")
local told = {}
Gear:OnStamp(function(handle) told[#told + 1] = handle end)

-- Get never loads a pack: it asks for it, and nothing runs while the loading screen is up
for _ = 1, 3 do check(Gear:Get(100) == nil, "Get before the pack is loaded: nil") end
check(Gear:State() == "loading" and Loaded() == 0 and not Steps.Running("data: packs"),
    "Get asked for the pack and loaded nothing; no loading while the loading screen is up")
Data.Prepare("Labels")
check(Labels:State() == "loading" and Loaded() == 0, "Prepare loads nothing at once either")

-- The loading screen gone in a fight: nothing until the fight ends
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
W.Fire("LOADING_SCREEN_DISABLED")
check(Steps.Running("data: packs"), "the loading screen gone: the loader is a job of the scheduler")
for _ = 1, 5 do Frame() end
check(Loaded() == 0, "nothing loads in a fight")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
local most, last = 0, 0
for _ = 1, 6 do
    Frame()
    most, last = math.max(most, Loaded() - last), Loaded()
end
check(last == 2 and most == 1, "the fight over: the two packs load, one a frame")
check(not Steps.Running("data: packs") and not frame:IsShown(), "the loader ends when the line is empty")
check(#W.fileErrors == 0, "the packs' files ran without an error" .. (W.fileErrors[1] and ": " .. W.fileErrors[1] or ""))

-- Loaded: ready, its hash and build, the stamp moved and the listener told once
check(Gear:State() == "ready" and Gear:Ready() and Labels:Ready() and Folk:Ready(), "the sets are ready")
check(Gear.hash == liveGear.header.hash and Gear.build == 65100, "the handle names the set's hash and build")
check(Gear:Stamp() > 0 and #told == 1 and told[1] == Gear, "its stamp moved and its listener was told, once")

-- Get answers every entry as the tools meant its newest version; gone is nil
for _, pack in ipairs(PACKS) do
    for _, name in ipairs(pack[2]) do
        local handle, problem = Data.Set(name), nil
        for key, versions in pairs(expected.forever[name]) do
            local newest = versions[#versions]
            if newest.gone then
                if handle:Get(key) ~= nil then problem = problem or tostring(key) .. " is gone, yet answered" end
            else
                problem = problem or Differ(handle:Get(key), newest, tostring(key))
            end
        end
        check(not problem, ("Get gives every entry of %s as the tools meant it%s"):format(name, problem and ": " .. problem or ""))
    end
end
check(Gear:Get(100, "name") == "Plain Gloves" and Gear:Get(100, "nothing") == nil and Gear:Get(999) == nil
    and Gear:Get(999, "name") == nil, "Get of a field; nil for a field or an entry not there")
check(Labels:Get("end", "label") == "END_TEXT" and Labels:Get("with space", "label") == "SPACED", "text keys, a Lua word and a space among them")
check(Gear:Get(100) == Gear:Get(100), "a record is made once and shared")

-- Frozen records: a new key fails at once, a change is found
local gloves = Gear:Get(100)
check(not pcall(function() gloves.colour = "red" end) and gloves.colour == nil, "frozen: a new key cannot be written")
check(not pcall(function() gloves.stats.int = 3 end), "nor inside a table of it")
check(Data.Tampered() == nil, "nothing changed yet")
gloves.name = "Changed"
check(Data.Tampered() == gloves, "a changed field is found")
gloves.name = "Plain Gloves"
gloves.stats.agi = 9
check(Data.Tampered() == gloves, "and a change inside a table of it")
gloves.stats.agi = 1
check(Data.Tampered() == nil, "put back: nothing found")

-- Versions: History, At, Versions, Changes, with the patch names the pack carries
local history = Gear:History(100)
check(not Differ(history, expected.forever.Gear[100], "History(100)") and history[3] == Gear:Get(100),
    "History: every version, oldest first, the newest the record Get gives" .. (Differ(history, expected.forever.Gear[100], "") or ""))
check(history[1].patch == nil and history[2].patch == "1.60.0" and history[3].patch == "1.60.2" and history[2].day == 20697,
    "each version with its patch (none for since 0) and day")
check(Gear:History(100) == history and Gear:History(999) == nil, "History is made once and shared; nil for an entry not there")
local hester = Folk:History(3)
check(#hester == 2 and hester[2].gone and hester[2].since == 65100 and hester[2].patch == "1.60.2" and Folk:Get(3) == nil,
    "a gone entry: Get answers nil, History shows it gone")
check(Gear:At(100, 0).sell == 120 and Gear:At(100, 65050).sell == 110 and Gear:At(100, 65050).since == 65000
    and Gear:At(100, 99999) == Gear:Get(100), "At: the version at a build")
check(Folk:At(3, 65000).name == "Old Hester" and Folk:At(3, 65100) == nil and Gear:At(102, 65000) == nil
    and Gear:At(100) == nil, "At: nil when gone, not there yet, or no build given")
local last = Gear:Versions(100, 2)
check(#last == 2 and last[1] == history[2] and last[2] == history[3] and #Gear:Versions(100, 10) == 3 and #Gear:Versions(100) == 3,
    "Versions: the last n, oldest first")
local changes = Gear:Changes(100)
check(#changes == 4 and changes[1].field == "stats" and changes[1].from.agi == 2 and changes[1].to.agi == 1
    and changes[1].patch == "1.60.0" and changes[1].day == 20697 and changes[1].since == 65000
    and changes[2].field == "sell" and changes[2].from == 120 and changes[2].to == 110
    and changes[3].field == "weight" and changes[3].from == 1.5 and changes[3].to == nil
    and changes[4].field == "rare" and changes[4].from == nil and changes[4].to == true and changes[4].patch == "1.60.2",
    "Changes: one per field, in the pack's order, with since, day and patch")
local goneChange = Folk:Changes(3)
check(#goneChange == 1 and goneChange[1].field == "gone" and goneChange[1].from == false and goneChange[1].to == true,
    "Changes: an entry gone is the field gone")
check(#Folk:Changes(1) == 0 and Folk:Changes(9) == nil and Gear:Changes(100) == changes, "Changes: empty for one version, nil for none; shared")
check(not pcall(function() history[4] = {} end) and not pcall(function() changes[1].extra = 1 end), "histories and changes are frozen too")

-- Keys: the schema's indexes and the compiler's own, from the newest versions
local function Same(keys, want)
    local sorted = {}
    for index, key in ipairs(keys) do sorted[index] = key end
    table.sort(sorted, function(a, b) return tostring(a) < tostring(b) end)
    return not Differ(sorted, want)
end
check(Same(Gear:Keys("bySlot", "hands"), { 100 }) and Same(Gear:Keys("byFrom", 1), { 100, 102 }), "Keys by an index, numbers as numbers")
check(Same(Gear:Keys("replaces", 102), { 101 }) and Same(Gear:Keys("replacedBy", 101), { 102 }), "replaces and replacedBy")
check(#Gear:Keys("bySlot", "nowhere") == 0 and #Gear:Keys("nothing", 1) == 0 and #Labels:Keys("bySlot", "hands") == 0
    and #Data.Set("NoSuchSet"):Keys("bySlot", "hands") == 0, "an empty array when none")

-- Each: a job of the scheduler, every entry the client has, then done
local walked, finished = {}, false
check(Gear:Each(function(key, record) walked[#walked + 1] = key; check(record == Gear:Get(key), "Each hands the shared record") end,
    function() finished = true end), "Each starts a job")
check(#walked == 0, "nothing walked before the next frame")
local walkedFolk = {}
check(Folk:Each(function(key) walkedFolk[#walkedFolk + 1] = key end), "a second walk at the same time")
for _ = 1, 10 do Frame() end
check(finished and Same(walked, { 100, 101, 102 }) and Same(walkedFolk, { 1, 2 }), "every entry walked, gone ones left out; then done")
check(Data.Set("NoSuchSet"):Each(function() end) == false, "Each of a set that is not there: false")

-- A pack newer than the client: the versions this client has reached
W.build = 65050
Data.Find()
check(Gear:Get(100).since == 65000 and Gear:Get(100).sell == 110 and Gear:Get(100).rare == nil and Gear:Get(102) == nil
    and Folk:Get(3).name == "Old Hester", "an older client: Get answers what its build has")
check(#Gear:History(100) == 2 and #Gear:Changes(100) == 2 and Gear:At(100, 70000).since == 65000 and Gear:History(102) == nil,
    "and History, Changes and At stop at its build")
walked, finished = {}, false
Gear:Each(function(key) walked[#walked + 1] = key end, function() finished = true end)
for _ = 1, 10 do Frame() end
check(finished and Same(walked, { 100, 101 }), "Each leaves out what the client has not reached")
W.build = 70245
Data.Find()
check(Gear:Get(102) and Gear:Get(102).name == "Ünder Cap" and #Gear:History(100) == 3, "a newer client: all of it again")
check(Data.Tampered() == nil, "no record was changed by the answers")

-- A loading screen in the middle: the loader waits for its end
local extra = MakePack("Extra", "Extra", { ["Extra.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Extra", { game = "forever", hash = "0badf00d", build = 65000, key = "int", fields = { "name" }, types = { "text" }, patches = {} })\n'
    .. 'if not S then return end\nS.rows[1] = "65000\\t\\tOne"\n' })
W.AddPack(extra)
Data.Find()
W.Fire("LOADING_SCREEN_ENABLED")
Data.Prepare("Extra")
for _ = 1, 3 do Frame() end
check(not W.loaded.SaneUI_Data_Extra, "a loading screen up: nothing loads")
W.Fire("LOADING_SCREEN_DISABLED")
for _ = 1, 3 do Frame() end
check(W.loaded.SaneUI_Data_Extra and Data.Set("Extra"):Get(1, "name") == "One" and Data.Set("Extra").hash == "0badf00d",
    "after it the pack loads, a pack written by hand too")

-- Packs that are not used: switched off, of another format or game version, naming no set, not loadable
W.AddPack(live .. "SaneUI_Data_Gear", { name = "SaneUI_Data_Off", enabled = 0, metadata = { ["X-SaneUI-Sets"] = "Switched" } })
W.AddPack(live .. "SaneUI_Data_Gear", { name = "SaneUI_Data_Later", metadata = { ["X-SaneUI-Sets"] = "Later", ["X-SaneUI-Format"] = "2" } })
W.AddPack(live .. "SaneUI_Data_Gear", { name = "SaneUI_Data_Beta", metadata = { ["X-SaneUI-Sets"] = "Elsewhere", ["X-SaneUI-Game"] = "forever-beta" } })
W.AddPack(live .. "SaneUI_Data_Gear", { name = "SaneUI_Data_Empty", metadata = { ["X-SaneUI-Sets"] = false } })
W.AddPack(live .. "SaneUI_Data_Gear", { name = "SaneUI_Data_Old", reason = "INTERFACE_VERSION", metadata = { ["X-SaneUI-Sets"] = "Old" } })
W.AddPack(live .. "SaneUI_Data_Gear", { name = "SaneUI_Data_Gone", metadata = { ["X-SaneUI-Sets"] = "Vanished" } })
W.onDemand.SaneUI_Data_Gone = nil -- listed, but the game cannot load it after all
W.AddPack(MakePack("Broken", "Broken", { ["Broken.lua"] = "this is not Lua\n" }))
W.printed = {}
Data.Find()
local function StateOf(name)
    local state, why = Data.Set(name):State()
    return state, why or ""
end
local state, why = StateOf("Switched")
check(state == "off" and why:find("switched off"), "a pack switched off in the addon list: off")
Data.Prepare("Switched")
Data.Prepare("Switched")
check(Core.errors["data: SaneUI_Data_Off"] and Core.errors["data: SaneUI_Data_Off"].count == 1 and #W.printed == 0
    and not W.loaded.SaneUI_Data_Off, "asked for: noted once, quietly, and never loaded (the player's choice stands)")
state, why = StateOf("Later")
check(state == "refused" and why:find("of format 2"), "a pack of another format: refused")
state, why = StateOf("Elsewhere")
check(state == "refused" and why:find("made for forever%-beta, this client is forever"), "a pack of another game version: refused")
state, why = StateOf("Old")
check(state == "refused" and why:find("INTERFACE_VERSION"), "a pack the game cannot load: refused, with the game's reason")
W.printed = {}
Data.Prepare("Later")
Data.Prepare("Later")
Data.Prepare("Elsewhere")
check(printedMatch("problem in data: SaneUI_Data_Later") and printedMatch("problem in data: SaneUI_Data_Beta") and #W.printed == 2
    and Loaded() == 3, "asked for: each said once, loud, and never loaded")
Data.Prepare("Vanished")
Data.Prepare("Broken")
for _ = 1, 4 do Frame() end
state, why = StateOf("Vanished")
check(state == "refused" and why:find("did not load") and printedMatch("problem in data: SaneUI_Data_Gone"),
    "a pack that does not load when asked: refused and reported")
state, why = StateOf("Broken")
check(state == "refused" and why:find("its file did not run") and #W.fileErrors == 1 and printedMatch("problem in data: Broken"),
    "a pack whose file does not run: its set refused and reported")
check(Data.Set("Broken"):Get(1) == nil and Data.Set("Vanished"):Get(1) == nil, "and Get answers nil, no error")

-- Two packs naming one set: the first is used, and it is said
W.printed = {}
W.AddPack(live .. "SaneUI_Data_Words", { name = "SaneUI_Data_Twice" })
Data.Find()
check(printedMatch("problem in data: Labels") and Core.errors["data: Labels"].text:find("Data: Words is used")
    and Labels:Ready(), "two packs naming one set: said, the first stays")
W.RemoveAddon("SaneUI_Data_Twice")
Data.Find()

-- Set files that Data.Add does not take
local function Header(game, types) return { game = game, hash = "00000000", build = 0, key = "int", fields = { "a" }, types = types or { "int" } } end
check(Data.Add(2, "Newer", Header("forever")) == nil and select(2, Data.Set("Newer"):State()):find("of format 2"),
    "a set file of another format: nil, refused")
check(Data.Add(1, "Beta", Header("forever-beta")) == nil and select(2, Data.Set("Beta"):State()):find("made for forever%-beta"),
    "a set file of another game version: nil, refused")
check(Data.Add(1, "Odd", Header("forever", { "wobbly" })) == nil and select(2, Data.Set("Odd"):State()):find("cannot be read"),
    "a set file with a type the codec does not know: nil, refused")
check(Data.Add(1, "Gear", Header("forever")) == nil and Gear:Get(100, "name") == "Plain Gloves",
    "a set handed over a second time: nil, the first stays")

-- The client's game version: the project, then beta or test
local function Told()
    Data.Find()
    return Data.Game()
end
W.AddPack(live .. "SaneUI_Data_Words", { name = "SaneUI_Data_Live", metadata = { ["X-SaneUI-Sets"] = "LiveWords" } })
W.AddPack(folder .. "/forever-beta/SaneUI_Data_Words", { name = "SaneUI_Data_BetaWords", metadata = { ["X-SaneUI-Sets"] = "BetaWords" } })
check(Told() == "forever" and StateOf("LiveWords") == "idle" and StateOf("BetaWords") == "refused",
    "a Forever client: forever; live's packs used, the beta's refused")
W.beta = true
check(Told() == "forever-beta" and StateOf("BetaWords") == "idle" and StateOf("LiveWords") == "refused",
    "a beta client: forever-beta; the beta's packs used, live's refused")
check(Gear:Ready(), "a pack loaded stays loaded")
W.beta, W.test = false, true
check(Told() == "forever-ptr" and StateOf("BetaWords") == "refused" and StateOf("LiveWords") == "refused", "a test client: forever-ptr")
W.test = false
WOW_PROJECT_ID = 2
local client = Told()
state, why = StateOf("LiveWords")
check(client == nil and state == "refused" and why:find("cannot be told"), "a client of another project: no game version, every pack refused")
W.printed = {}
SlashCmdList.SANEUI("data")
check(printedMatch("cannot be told %(project 2; beta: no; test: no%)"), "/sane data says so, with what it was told")
WOW_PROJECT_ID = nil
check(Told() == nil and StateOf("BetaWords") == "refused", "a client without a project: the same")
WOW_PROJECT_ID = 18
check(Told() == "forever" and StateOf("LiveWords") == "idle", "back to Forever")

-- /sane data
W.printed = {}
SlashCmdList.SANEUI("data")
check(printedMatch("data of forever, build 70245 %(project 18; beta: no; test: no%)"), "/sane data: the game version, build and answers")
check(printedMatch("Data: Gear: loaded %- Folk %x+ %(build 65100%), Gear " .. Gear.hash .. " %(build 65100%)%."), "a pack loaded, with its sets' hashes")
check(printedMatch("Data: Words: not loaded %- LiveWords%.") and printedMatch("Data: Gear: switched off %- Switched%.")
    and printedMatch("not used %(of format 2") and printedMatch("Data: Gear: not used %(it names no set%)%.")
    and printedMatch("Data: Gear: not used %(it did not load %(CORRUPT%)%) %- Vanished%."), "the packs not loaded, off and not used, and why")
check(printedMatch("Data: Broken: loaded %- Broken %(not used: its file did not run%)%.") and printedMatch("Data: Words: loaded %- Labels %x+%."),
    "a set of a loaded pack that is not used, and why; no build for a set the game never changed")
check(printedMatch("jobs running: none%."), "and the scheduler's jobs")
W.printed = {}
SlashCmdList.SANEUI("data show Gear 100")
SlashCmdList.SANEUI("data show Labels with space")
SlashCmdList.SANEUI("data show Gear 999")
SlashCmdList.SANEUI("data show")
check(printedMatch("^|c%x+Sane UI:|r   1%.60%.0: sell 120 %-> 110%.$") and printedMatch("1%.60%.2: rare empty %-> true%.")
    and printedMatch("1%.60%.0: stats { agi = 2, sta = 3 } %-> { agi = 1, sta = 3 }%."), "/sane data show: what changed, by patch")
check(printedMatch("Gear 100: { from = { 1, 2 }, name = Plain Gloves,") and printedMatch("Labels with space: { label = SPACED, since = 0 }%.")
    and printedMatch("Gear has no 999%.") and printedMatch("/sane data show <set> <key>"), "/sane data show prints an entry")
W.printed = {}
SlashCmdList.SANEUI("data show LiveWords alpha")
check(printedMatch("LiveWords is not loaded; asked for it") and StateOf("LiveWords") == "loading", "an entry of a pack not loaded: asked for")
SlashCmdList.SANEUI("data show Nowhere 1")
check(printedMatch("Nowhere is missing %(no data pack holds the set Nowhere%)%.$"), "a set no pack holds")
for _ = 1, 4 do Frame() end
Data.frozen = false

os.execute(("rm -rf '%s'"):format(folder))

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Data in the game: all %d checks passed.\n"):format(passed))
