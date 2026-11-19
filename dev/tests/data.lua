-- Runs Core's data framework against the stand-in client (wowstub.lua): the scheduler (Steps.lua), and from
-- step 1a.5 on the set files compiled from the sample master (dev/tests/data/sample) as the game reads them.
-- Usage, from the project folder:  lua5.1 dev/tests/data.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
Enum.BankType = { Character = 0, Account = 2 } -- the bank's kinds, which Characters.lua takes as its file is read

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function printedMatch(pattern)
    for _, line in ipairs(W.printed) do if line:find(pattern) then return true end end
    return false
end

-- The game's bags, bank, gear and gold as the test sets them (the characters' part, at the end); reading a slot
-- costs `cost` milliseconds
local bags, worn, cost, money = { [0] = { { itemID = 4500, stackCount = 3 } }, [1] = { { itemID = 4501, stackCount = 1 } } }, {}, 0, 1000
C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end,
    GetContainerItemInfo = function(bag, slot)
        W.ms = W.ms + cost
        local info = bags[bag] and bags[bag][slot]
        return info and info.itemID and info or nil
    end,
}
C_Bank = { CanViewBank = function() return true end,
           FetchPurchasedBankTabIDs = function(kind) return kind == Enum.BankType.Character and { 6, 7, 8 } or {} end }
GetInventoryItemID = function(_, slot) return worn[slot] end
GetMoney = function() return money end
-- The characters' saved variable as the game read it: an alt kept by an older version or by hand, its class and
-- level of the wrong kind
local ALT = "Player-70-0000BEEF"
SaneUIData_Characters = { forever = { format = 1, characters = { [ALT] = { name = "Droopy Fairwind", class = 5, level = "thirty", money = 10,
    bags = "4500\0312" } } } }
-- What Core learnt in play before (Data.Learn), as the game read it: rows of a set that comes with Core (Lore, its file
-- among Core's): one newer than the set's own, one the set is as new as (the same build, a later day), one that is no
-- row; and another game version's part
local lore = io.popen("mktemp -d -t saneui-learned-XXXXXX"):read("*l")
do
    local out = assert(io.open(lore .. "/Lore.lua", "w"))
    out:write('local S = SaneUI.Core.Data.Add(1, "Lore", { game = "forever", hash = "0000001e", build = 65100, key = "int", '
        .. 'fields = { "name", "path" }, types = { "text", "list tuple(x:number,y:number,map:int)" }, patches = {} })\n'
        .. 'if not S then return end\nS.rows[1] = "65000\\t\\tOld Road"\nS.rows[2] = "65100\\t20500\\tKept"\n'
        .. 'S.rows[5] = "65000\\t\\tStone"\n')
    out:close()
end
W.AddSets(lore)
SaneUIData_Learned = { forever = { format = 1, learned = { Lore = { [1] = "65100\t20000\tNew Road\t1\0312\0310",
    [2] = "65100\t20400\tStale", [3] = 7 } } }, ["forever-beta"] = { format = 1, learned = { Lore = { [1] = "beta's" } } } }

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
-- Core's reader of the characters' saved part started its jobs at the login: they finish first
for _ = 1, 10 do
    W.Wait(0)
    if frame:IsShown() and frame._scripts.OnUpdate then frame._scripts.OnUpdate(frame, 0.016) end
end
check(frame and not frame:IsShown() and not frame._scripts.OnUpdate, "the scheduler's frame is hidden, with no OnUpdate, while there is no work")

-- One frame of the game: the timers asked for in the frame before, then the scheduler's OnUpdate, if it has
-- one; returns how many milliseconds of work the scheduler did.
local function Frame()
    W.Wait(0)
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
local oneJob = Steps.Run("one", Worker(100, 0.1, one))
check(oneJob and oneJob.name == "one" and oneJob:Running() and frame:IsShown() and frame._scripts.OnUpdate,
    "a job started: its handle, and the frame is shown, with its OnUpdate")
check(Steps.Run("one", Worker(1, 0.1, {})) == false, "a job of the same name is not started twice")
check(Steps.Running("one") and Steps.Jobs()[1] == oneJob, "it is known to be running, by its name")
check(one.n == 0, "nothing runs before the next frame")
local spent = Frame()
check(spent <= Budget() + 0.1 + 1e-9 and spent >= Budget() - 1e-9, "a frame at 60 frames a second spends a quarter of it, no more than a piece over")
for _ = 1, 30 do Frame() end
check(one.finished and not Steps.Running("one") and not oneJob:Running() and not frame:IsShown() and not frame._scripts.OnUpdate,
    "done: the job is gone, the frame hidden again")
check(oneJob.frames > 1 and math.abs(oneJob.ms - 10) < 1e-6, "its handle counts the frames it worked in and the milliseconds it worked")

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

-- Nothing while the game restricts addons (an encounter); chat's restriction does not stop it. The game
-- answers false while it sends the event (W.restrictions stays empty): the event's own state counts.
local asked = 0
local isActive = C_RestrictedActions.IsAddOnRestrictionActive
C_RestrictedActions.IsAddOnRestrictionActive = function(...) asked = asked + 1 return isActive(...) end
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 2)
check(not frame:IsShown(), "an encounter's restriction stops the scheduler, by the event's state")
before = fight.n
Frame()
check(fight.n == before, "nothing runs under it")
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 0)
check(frame:IsShown(), "it ends: the scheduler goes on")
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 5, 2)
check(frame:IsShown(), "chat's restriction does not stop it")
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 5, 0)
for _ = 1, 400 do Frame() end
check(fight.finished, "the job finished after the pauses")
check(asked == 0, "the game is not asked for its restrictions in every frame")
C_RestrictedActions.IsAddOnRestrictionActive = isActive

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
local jobs = #Steps.Jobs()
Steps.Check()
check(#Steps.Jobs() == jobs and not Steps.Running("fine") and not Steps.Running("broken"),
    "Check outside a job returns at once: no job started or dropped")
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

-- A job stopped never goes on, from outside or from inside, and is told nothing
local stopped, stopTold = { n = 0 }, {}
local stopJob = Steps.Run({ name = "stopped", done = function() stopTold[#stopTold + 1] = "done" end }, Worker(100, 1, stopped))
Frame()
local pieces = stopped.n
check(pieces > 0 and stopJob:Stop() == true and not Steps.Running("stopped") and not stopJob:Running(), "a job stopped by its handle")
for _ = 1, 5 do Frame() end
check(stopped.n == pieces and #stopTold == 0 and stopJob:Stop() == false, "never goes on, is told nothing; stopped once")
check(Steps.Run("stopped", function() end) and Steps.Stop("stopped") == true and Steps.Stop("stopped") == false,
    "by its name, and its name is free again")
local selfStopped = 0
Steps.Run({ name = "itself", done = function() stopTold[#stopTold + 1] = "itself" end }, function()
    for _ = 1, 10 do
        selfStopped = selfStopped + 1
        if selfStopped == 2 then Steps.Stop("itself") end
        W.ms = W.ms + 3
        Steps.Check()
    end
end)
for _ = 1, 5 do Frame() end
check(selfStopped == 2 and #stopTold == 0 and not frame:IsShown(), "a job that stops itself runs to its next Check, never further")
do
    local cheap = 0
    Steps.Run("cheap", function()
        for piece = 1, 20 do
            cheap = piece
            if piece == 2 then Steps.Stop("cheap") end
            W.ms = W.ms + 0.1
            Steps.Check()
        end
    end)
    for _ = 1, 3 do Frame() end
    check(cheap == 2 and not frame:IsShown(), "also with the frame's time far from spent at that Check")
end

-- A job that holds waits, served in no frame, with no OnUpdate while every job waits so; released, it goes on
do
    local held = 0
    local holdJob = Steps.Run("held", function()
        held = 1
        Steps.Hold()
        held = 2
        Steps.Hold()
        held = 3
    end)
    Frame()
    check(held == 1 and Steps.Running("held") and holdJob:Running() and not frame:IsShown() and not frame._scripts.OnUpdate,
        "a job holds: still running, and the scheduler rests while it waits")
    for _ = 1, 5 do Frame() end
    check(held == 1, "served in no frame")
    check(Steps.Release("held") == true and frame:IsShown() and Steps.Release("held") == false,
        "released by its name: the scheduler goes on; released once")
    Frame()
    check(held == 2 and not frame:IsShown(), "it goes on, to its next hold")
    local beside = { n = 0 }
    Steps.Run("beside", Worker(5, 0.1, beside))
    check(frame:IsShown(), "another job started beside it: the scheduler goes on for that one")
    Frame()
    check(beside.finished and held == 2 and not frame:IsShown(), "that one finishes, the held one still waits, and the scheduler rests again")
    check(holdJob:Stop() == true and holdJob:Release() == false and not Steps.Running("held"), "a held job stopped: gone, nothing to release")
    for _ = 1, 3 do Frame() end
    check(held == 2, "and it never goes on")
end

-- Told when it ends: done(problem), and error(problem) after an error, outside its coroutine, after the report
local ended = {}
Steps.Run({ name = "ends", done = function(problem) ended.done, ended.inside = problem or "none", coroutine.running() end },
    function() W.ms = W.ms + 1 end)
Steps.Run({ name = "breaks", label = "a test's own job", error = function(problem) ended.error = problem end,
    done = function(problem) ended.broken = problem end }, function() error("it broke") end)
W.printed = {}
Frame()
check(ended.done == "none" and ended.inside == nil, "done() after the last step, outside the job's coroutine")
check(type(ended.error) == "string" and ended.error:find("it broke") and ended.broken == ended.error,
    "error(problem) and done(problem) after an error, with its text")
check(printedMatch("problem in a test's own job") and Core.errors["a test's own job"], "reported under the label it was given")

-- A job with priority is served first in every frame
local served = {}
local function Piece(name, pieces)
    return function()
        for _ = 1, pieces do
            served[#served + 1] = name
            W.ms = W.ms + 3
            Steps.Check()
        end
    end
end
Steps.Run("plain", Piece("plain", 4))
Steps.Run({ name = "urgent", priority = true }, Piece("urgent", 6))
for index = 1, 3 do
    local count = #served
    Frame()
    check(served[count + 1] == "urgent", ("frame %d: the job with priority goes first"):format(index))
end
for _ = 1, 10 do Frame() end
check(#served == 10 and served[#served] == "plain" and not frame:IsShown(), "and the other one gets its turns after it")

-- A job that Waits (for the game to answer) leaves the frame's time to the other jobs, and goes on in the next frame
local trace = {}
Steps.Run({ name = "waits", priority = true }, function()
    trace[#trace + 1] = "waits"
    Steps.Wait()
    trace[#trace + 1] = "waits again"
end)
Steps.Run("meanwhile", function() trace[#trace + 1] = "meanwhile" end)
Frame()
check(trace[1] == "waits" and trace[2] == "meanwhile" and #trace == 2, "a job that Waits lets another job run in the same frame")
Frame()
check(trace[3] == "waits again" and not Steps.Running("waits"), "and goes on in the next one")

-------------------------------------------------------------------------------
--  Sets: the sample master compiled by the tools (dev/tests/data/sample.py), read as the game reads them
-------------------------------------------------------------------------------
local Data, Codec = Core.Data, Core.Data.Codec
local folder = io.popen("mktemp -d -t saneui-data-XXXXXX"):read("*l")
check(folder and os.execute(("python3 -I '%s/dev/tests/data/sample.py' '%s'"):format(root, folder)) == 0,
    "the tools compiled the sample master into set files")
local expected = {
    forever = dofile(folder .. "/expected-forever.lua"),
    ["forever-beta"] = dofile(folder .. "/expected-forever-beta.lua"),
}
local SETS = { "Folk", "Gear", "Labels" }

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
    for _, name in ipairs(SETS) do
        do
            local file = Read(("%s/%s/Sets/%s.lua"):format(folder, game, name))
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
local holes = Codec.Decoder({ "ints", "words", "flags", "named" }, { "list int", "list text", "list bool", "map text bool" })(
    "1\t\t7\030\0309\tx\030\030z\t1\030\0301\tk\031\030m\0311\030n\031")
check(holes.ints[1] == 7 and holes.ints[2] == nil and holes.ints[3] == 9 and holes.words[1] == "x" and holes.words[2] == nil
    and holes.words[3] == "z" and holes.flags[1] == true and holes.flags[2] == nil and holes.flags[3] == true,
    "an empty element of a list is no value, of every type, and the elements after it keep their places")
check(holes.named.m == true and holes.named.k == nil and holes.named.n == nil, "an empty value of a map is no value too")
check(Codec.Build({}) == nil and Codec.Build(65100) == nil and #Codec.Versions(false) == 0, "a row that is no text: no build, no versions")
check(not pcall(Codec.Decoder, { "a" }, { "wobbly" }) and not pcall(Codec.Decoder, { "a" }, { "map bool int" }),
    "a type the codec does not know is an error (the set is refused then)")
do
    -- A map's whole-number keys: tonumber reads "nan" too, which is no table key at all
    local ok, odd = pcall(Codec.Decoder({ "counts" }, { "map int int" }), "1\t\tnan\0311\030inf\0312\0300x10\0313\030-4\0314\0307\0315")
    local keys = 0
    for _ in pairs(ok and odd.counts or {}) do keys = keys + 1 end
    check(ok and keys == 2 and odd.counts[7] == 5 and odd.counts[-4] == 4,
        "a map of whole-number keys takes whole numbers only: nan, inf and 0x10 are no value, and no error")
end
-- The codec the other way round (Data.Learn): a record written as a row of its set's fields and read back the same, of
-- every type; nothing at a row's end that holds no value
do
    local fields = { "kind", "count", "share", "seen", "at", "path", "words", "named", "counts", "none" }
    local types = { "text", "int", "number", "bool", "point", "list tuple(x:number,y:number,map:int,jump:bool)",
                    "list text", "map text bool", "map int int", "text" }
    local encode, decode = Codec.Encoder(fields, types), Codec.Decoder(fields, types)
    local back = decode("70245\t20746" .. encode({ kind = "teleport", count = 3000000, share = 0.125, seen = true,
        at = { map = 1429, x = 41.5, y = 7 }, path = { { x = -9003.46, y = 870.031, map = 0 }, nil, { x = 1, y = 2, jump = true } },
        words = { "a", nil, "c" }, named = { m = true }, counts = { [7] = 5, [-4] = 4 }, since = 1, day = 2 }))
    check(back.kind == "teleport" and back.count == 3000000 and back.share == 0.125 and back.seen == true and back.at.map == 1429
        and back.at.x == 41.5 and back.at.y == 7 and back.path[1].x == -9003.46 and back.path[1].y == 870.031
        and back.path[1].map == 0 and back.path[2] == nil and back.path[3].jump == true and back.words[1] == "a"
        and back.words[2] == nil and back.words[3] == "c" and back.named.m == true and back.counts[7] == 5
        and back.counts[-4] == 4 and back.none == nil and back.since == 70245 and back.day == 20746,
        "a record written as its set's row is read back the same, of every type (since and day are the row's, not the record's)")
    check(encode({ kind = "teleport" }) == "\tteleport" and encode({ count = 3 }) == "\t\t3" and encode({}) == "",
        "the empty fields at a row's end are left out, those before a value kept")
    check(not pcall(encode, { kind = "a\tb" }) and not pcall(encode, { count = "many" }) and not pcall(encode, { share = 0 / 0 }),
        "a text with a separator in it, or no number where one belongs: an error, no row")
end

-- Set files written by hand into the test's folder: a folder of its own for them, given to W.AddSets.
local function MakeSets(name, files)
    local path = folder .. "/hand/" .. name
    os.execute(("mkdir -p '%s'"):format(path))
    for file, text in pairs(files) do
        local out = assert(io.open(path .. "/" .. file, "w"))
        out:write(text)
        out:close()
    end
    return path
end

-- No set yet: a handle all the same, nil, and said once, quietly
Data.frozen = true
local Gear, Labels, Folk = Data.Set("Gear"), Data.Set("Labels"), Data.Set("Folk")
check(Gear == Data.Set("Gear") and Gear.name == "Gear", "a set's handle: one per name, never nil")
W.printed = {}
check(Gear:State() == "missing" and not Gear:Ready() and Gear:Get(100) == nil and Gear:Get(100, "name") == nil,
    "Core holds no such set: missing, and Get answers nil")
check(Core.errors["data: Gear"] and Core.errors["data: Gear"].count == 1 and #W.printed == 0,
    "a missing set is noted once in the error log, quietly")
local made, format, text = 0, string.format, tostring
string.format = function(...) made = made + 1 return format(...) end
tostring = function(...) made = made + 1 return text(...) end
for _ = 1, 100 do Gear:Get(100) end
string.format, tostring = format, text
check(made == 0, "after that a Get of it makes no text: the failure is remembered on the set")
check(Gear.hash == nil and Gear.build == nil and Gear:Stamp() == 0, "no hash, no build, no stamp before it is there")

-- The set files run (as they do at the end of Core's TOC, here once Core is there): ready at once, their
-- listeners told on the next frame
local live = folder .. "/forever/Sets"
local told = {}
Gear:OnStamp(function(handle) told[#told + 1] = handle end)
Gear:OnStamp(function() error("a listener's own problem") end)
-- A listener runs a job's Check past any budget: inside the file that hands the set over it would fail.
local outside
Gear:OnStamp(function()
    W.ms = W.ms + 100
    Steps.Check()
    outside = coroutine.running() == nil
end)
local readyNow = {}
Data.WhenReady(Labels, function(handle) readyNow[#readyNow + 1] = handle end)
check(#readyNow == 0, "WhenReady of a set not there yet: it waits")
W.AddSets(live)
check(#W.fileErrors == 0, "the set files ran without an error" .. (W.fileErrors[1] and ": " .. W.fileErrors[1] or ""))
check(Gear:State() == "ready" and Gear:Ready() and Labels:Ready() and Folk:Ready(), "the sets are ready once their files ran")
check(#told == 0 and #readyNow == 0, "their listeners are not told inside the files")
Frame()

-- There: its hash and build, the stamp moved and the listener told once
check(Gear.hash == liveGear.header.hash and Gear.build == 65100, "the handle names the set's hash and build")
check(Gear:Stamp() > 0 and #told == 1 and told[1] == Gear, "its stamp moved and its listener was told, once")
check(outside, "listeners are told on the frame after, outside the file: a job's Check returns at once there")
check(Core.errors["data: Gear listener"] and Core.errors["data: Gear listener"].text:find("a listener's own problem")
    and Core.errors["data: Gear"].text:find("holds no set"), "a listener's failure is noted under a label of its own, apart from the set's")
check(#readyNow == 1 and readyNow[1] == Labels, "WhenReady: told once the set arrived")
local atOnce
Data.WhenReady("Labels", function(handle) atOnce = handle end)
check(atOnce == Labels, "WhenReady of a set that is ready: at once")

-- Get answers every entry as the tools meant its newest version; gone is nil
for _, name in ipairs(SETS) do
    do
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
local kept = Gear:Get(100)
Data.Retell()
check(Gear:Get(100) == kept, "the client told again (/sane data), the same game version and build: the answers made are kept")

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

-- Versions: History, At, Versions, Changes, with the patch names the set carries
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
    "Changes: one per field, in the set's order, with since, day and patch")
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
check(Same(Gear:Keys("byTask", 2), { 101 }) and Same(Gear:Keys("byTask", 100), { 101 }), "Keys by a part of a list of tuples")
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
W.printed = {}
local broken = {}
for _ = 1, 2 do
    Gear:Each(function() error("a broken walk") end, function(problem) broken[#broken + 1] = problem end)
    for _ = 1, 3 do Frame() end
end
check(#broken == 2 and broken[1]:find("a broken walk") and Core.errors["data job Each Gear"]
    and Core.errors["data job Each Gear"].count == 2 and #W.printed == 1,
    "a walk that fails: done is told the error; noted under one label for the set however often it is walked, said once")
local walk = Gear:Each(function() end)
check(walk and walk:Stop() and not Steps.Running(walk.name), "a walk's handle stops it")

-- A set newer than the client: the versions this client has reached
W.build = 65050
Data.Retell()
check(Gear:Get(100).since == 65000 and Gear:Get(100).sell == 110 and Gear:Get(100).rare == nil and Gear:Get(102) == nil
    and Folk:Get(3).name == "Old Hester", "an older client: Get answers what its build has")
check(#Gear:History(100) == 2 and #Gear:Changes(100) == 2 and Gear:At(100, 70000).since == 65000 and Gear:History(102) == nil,
    "and History, Changes and At stop at its build")
walked, finished = {}, false
Gear:Each(function(key) walked[#walked + 1] = key end, function() finished = true end)
for _ = 1, 10 do Frame() end
check(finished and Same(walked, { 100, 101 }), "Each leaves out what the client has not reached")
W.build = 70245
Data.Retell()
check(Gear:Get(102) and Gear:Get(102).name == "Ünder Cap" and #Gear:History(100) == 3, "a newer client: all of it again")
check(Data.Tampered() == nil, "no record was changed by the answers")

-- A set that comes late, written by hand. Listeners taken back before it arrives are not told: one of OnStamp,
-- one waiting for it (WhenReady)
local Extra, extraTold = Data.Set("Extra"), {}
local function Gone() extraTold[#extraTold + 1] = "gone" end
local function Waits() extraTold[#extraTold + 1] = "waits" end
Extra:OnStamp(function() extraTold[#extraTold + 1] = "stays" end)
Extra:OnStamp(Gone)
Extra:OnStamp(Gone)
Data.WhenReady("Extra", Waits)
Extra:OffStamp(Gone)
Extra:OffStamp(Waits)
W.AddSets(MakeSets("Extra", { ["Extra.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Extra", { game = "forever", hash = "0badf00d", build = 65000, key = "int", fields = { "name" }, types = { "text" }, patches = {} })\n'
    .. 'if not S then return end\nS.rows[1] = "65000\\t\\tOne"\n' }))
for _ = 1, 3 do Frame() end
check(Data.Set("Extra"):Get(1, "name") == "One" and Data.Set("Extra").hash == "0badf00d", "a set that comes late, written by hand: there")
check(#extraTold == 1 and extraTold[1] == "stays", "OffStamp: a listener taken back is not told, nor one that waited")

-- A set file of values of the wrong kind: Get, History, Keys and Each answer nil or nothing, never an error;
-- a text key that looks like a number is shown by /sane data show
W.AddSets(MakeSets("Texts", { ["Texts.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Texts", { game = "forever", hash = "00000007", build = 65000, key = "text", fields = { "name" }, types = { "text" }, patches = {} })\n'
    .. 'if not S then return end\nS.rows["7"] = "65000\\t\\tSeven"\nS.rows["8"] = {}\nS.rows["9"] = 65000\nS.history["7"] = {}\nS.index.byName = 5\n' }))
local Texts, calmReads = Data.Set("Texts"), true
for _, key in ipairs({ "7", "8", "9", 7 }) do
    calmReads = calmReads and pcall(Texts.Get, Texts, key) and pcall(Texts.History, Texts, key) and pcall(Texts.Changes, Texts, key)
end
check(calmReads and pcall(Texts.Keys, Texts, "byName", "Seven"), "no read raises an error on a set's values of the wrong kind")
check(Texts:Get("7", "name") == "Seven" and #Texts:History("7") == 1 and Texts:Get("8") == nil and Texts:Get("9") == nil
    and Texts:History("8") == nil and #Texts:Keys("byName", "Seven") == 0 and Texts:Get(7) == nil,
    "they are no entries; a history that is no text no older versions; an index that is no table no keys")
local textsWalked = {}
Texts:Each(function(key) textsWalked[#textsWalked + 1] = key end)
for _ = 1, 3 do Frame() end
check(#textsWalked == 1 and textsWalked[1] == "7", "a walk leaves them out")
W.printed = {}
SlashCmdList.SANEUI("data show Texts 7")
check(printedMatch("Texts 7: { name = Seven, since = 65000 }%."), "/sane data show of a text key that looks like a number")

-- A set file that does not run: the game says so and goes on; the set is not there
W.AddSets(MakeSets("Broken", { ["Broken.lua"] = "this is not Lua\n" }))
local function StateOf(name)
    local state, why = Data.Set(name):State()
    return state, why or ""
end
local state, why = StateOf("Broken")
check(#W.fileErrors == 1 and state == "missing" and why:find("holds no set Broken") and Data.Set("Broken"):Get(1) == nil,
    "a set file that does not run: the set is missing, and Get answers nil, no error")

-- Set files that Data.Add does not take
local function Header(game, types) return { game = game, hash = "00000000", build = 0, key = "int", fields = { "a" }, types = types or { "int" } } end
W.printed = {}
check(Data.Add(2, "Newer", Header("forever")) == nil and select(2, Data.Set("Newer"):State()):find("of format 2")
    and printedMatch("problem in data: Newer"), "a set file of another format: nil, refused, said")
W.printed = {}
check(Data.Add(1, "Beta", Header("forever-beta")) == nil and select(2, Data.Set("Beta"):State()):find("made for forever%-beta")
    and Data.Add(1, "BetaToo", Header("forever-beta")) == nil and StateOf("BetaToo") == "refused"
    and #W.printed == 1 and printedMatch("problem in data: game") and not Core.errors["data: Beta"]
    and Core.errors["data: game"].text:find("SaneUI's data is not used: made for forever%-beta"),
    "set files of another game version (a copy made for another game folder): nil, refused, said once for them all")
check(Data.Add(1, "Odd", Header("forever", { "wobbly" })) == nil and select(2, Data.Set("Odd"):State()):find("cannot be read"),
    "a set file with a type the codec does not know: nil, refused")
check(Data.Add(1, "Gear", Header("forever")) == nil and Gear:Get(100, "name") == "Plain Gloves",
    "a set handed over a second time: nil, the first stays")

-- The client's game version: the project, then beta or test; set files of another game version refused
local function Told()
    Data.Retell()
    return Data.Game()
end
check(Told() == "forever" and Data.Add(1, "LiveWords", Header("forever")) and StateOf("LiveWords") == "ready",
    "a Forever client: forever; live's set files taken")
W.beta = true
check(Told() == "forever-beta" and Data.Add(1, "BetaWords", Header("forever-beta")) and StateOf("BetaWords") == "ready"
    and Data.Add(1, "LiveLater", Header("forever")) == nil and StateOf("LiveLater") == "refused",
    "a beta client: forever-beta; the beta's set files taken, live's refused")
check(Gear:Ready(), "a set there stays")
W.beta, W.test = false, true
check(Told() == "forever-ptr" and Data.Add(1, "BetaLater", Header("forever-beta")) == nil and StateOf("BetaLater") == "refused",
    "a test client: forever-ptr")
W.test = false
WOW_PROJECT_ID = 1
check(Told() == "retail" and Data.Add(1, "RetailWords", Header("retail")) and StateOf("RetailWords") == "ready"
    and Data.Add(1, "LiveInRetail", Header("forever")) == nil and StateOf("LiveInRetail") == "refused",
    "a Retail client: retail; Retail's set files taken, Forever's refused")
W.beta = true
check(Told() == "retail-beta", "a Retail beta client: retail-beta")
W.beta = false
WOW_PROJECT_ID = 2
local client = Told()
check(client == nil and Data.Add(1, "Unknown", Header("forever")) == nil and select(2, StateOf("Unknown")):find("cannot be told"),
    "a client of another project: no game version, every set refused")
W.printed = {}
SlashCmdList.SANEUI("data")
check(printedMatch("cannot be told %(project 2; beta: no; test: no%)"), "/sane data says so, with what it was told")
WOW_PROJECT_ID = nil
check(Told() == nil, "a client without a project: the same")
WOW_PROJECT_ID = 18
check(Told() == "forever", "back to Forever")

-- /sane data
W.printed = {}
SlashCmdList.SANEUI("data")
check(printedMatch("data of forever, build 70245 %(project 18; beta: no; test: no%); players by first name and surname %(regional names: yes%)%."),
    "/sane data: the game version, build and answers, and how players are named")
check(printedMatch("sets: .*Folk %x+ %(build 65100%), Gear " .. Gear.hash .. " %(build 65100%)"), "the sets there, with their hashes and builds")
check(printedMatch("Labels %x+, ") and printedMatch("Newer %(not used: of format 2") and printedMatch("Broken %(missing: SaneUI holds no set Broken%)"),
    "no build for a set the game never changed; the sets not used or missing, and why")
check(printedMatch("jobs running: none%."), "and the scheduler's jobs")
Steps.Run("held", Worker(10, 1, { n = 0 }))
Frame()
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 2, 1)
W.printed = {}
SlashCmdList.SANEUI("data")
check(printedMatch("jobs running: held %(5%.0 ms in one frame%); they wait while a fight or a restriction of the game's lasts%."),
    "each job with the time it worked and its frames; and that they wait, under a restriction")
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 2, 0)
for _ = 1, 3 do Frame() end
check(not Steps.Running("held"), "after it the job finishes")
W.printed = {}
SlashCmdList.SANEUI("data show Gear 100")
SlashCmdList.SANEUI("data show Labels with space")
SlashCmdList.SANEUI("data show Gear 999")
SlashCmdList.SANEUI("data show")
check(printedMatch("^|c%x+SaneUI:|r   1%.60%.0: sell 120 %-> 110%.$") and printedMatch("1%.60%.2: rare empty %-> true%.")
    and printedMatch("1%.60%.0: stats { agi = 2, sta = 3 } %-> { agi = 1, sta = 3 }%."), "/sane data show: what changed, by patch")
check(printedMatch("Gear 100: { from = { 1, 2 }, name = Plain Gloves,") and printedMatch("Labels with space: { label = SPACED, since = 0 }%.")
    and printedMatch("Gear has no 999%.") and printedMatch("/sane data show <set> <key>"), "/sane data show prints an entry")
W.printed = {}
SlashCmdList.SANEUI("data show Nowhere 1")
check(printedMatch("Nowhere is missing %(SaneUI holds no set Nowhere%)%.$"), "a set Core does not hold")
Data.frozen = false

-------------------------------------------------------------------------------
--  The data's saved variables (Data.SAVED): Core's own, handed to Core's readers once they are read
-------------------------------------------------------------------------------
Data.SAVED.Kept = true
SaneUIData_Kept = { forever = { format = 9, old = true }, ["forever-beta"] = { format = 1, mine = "beta" } }
local parts = {}
Data.Saved("Kept", function(part) parts[#parts + 1] = part end)
local part = parts[1]
check(#parts == 1 and part == SaneUIData_Kept.forever and part.format == 1 and part.broken and part.broken[1].old == true and part.old == nil,
    "Core's saved variables read: its reader is handed this client's part at once; one of a format it does not read is set aside under broken, never wiped")
check(SaneUIData_Kept["forever-beta"].mine == "beta", "another game version's part is left as it is")
Data.Saved("Kept", function(given) parts[#parts + 1] = given end)
check(#parts == 2 and parts[2] == part, "a second reader is handed the same part")
Data.SAVED.Fresh = true
local fresh
Data.Saved("Fresh", function(given) fresh = given end)
check(fresh and fresh.format == 1 and SaneUIData_Fresh.forever == fresh, "a saved variable the game had nothing of: made, with this client's part")
local never = true
Data.Saved("Nowhere", function() never = false end)
check(never and Core.errors["data: saved Nowhere"], "a name that is no saved variable of the data: noted, and its reader is never called")
W.printed = {}
SlashCmdList.SANEUI("data")
check(printedMatch("kept in the game: Characters %d+ values, Fresh 0 values, Kept 1 values, Learned %d+ values, Shared %d+ values%."),
    "/sane data says what the saved parts hold")

-------------------------------------------------------------------------------
--  What Core learns in play (Data.Learn): kept in SaneUIData_Learned, read over the sets while it is newer
-------------------------------------------------------------------------------
do
    local Lore = Data.Set("Lore")
    local road, history = Lore:Get(1), Lore:History(1)
    check(road and road.name == "New Road" and road.since == 65100 and road.day == 20000 and road.path[1].y == 2
        and history and #history == 2 and history[1].name == "Old Road" and history[2] == road,
        "what was learnt before, newer than the set's own: read over it, the set's own in its history")
    local saved = SaneUIData_Learned.forever.learned.Lore
    check(Lore:Get(2).name == "Kept" and saved[2] == nil and saved[3] == nil and saved[1],
        "a learnt row the set is as new as (its build, a later day of the set's) is dropped, and one that is no row")
    check(SaneUIData_Learned["forever-beta"].learned.Lore[1] == "beta's", "another game version's part is left as it is")
    -- Learnt now: an entry the set has, and one it has not
    local stamp, told = Lore:Stamp(), 0
    local function Told() told = told + 1 end
    Lore:OnStamp(Told)
    check(Data.Learn("Lore", 5, { name = "Stone", path = { { x = 10, y = 20, map = 1 } } })
        and Data.Learn("Lore", 9, { name = "Far Away" }), "an entry learnt, and one the set does not have")
    local stone, far = Lore:Get(5), Lore:Get(9)
    check(stone.name == "Stone" and stone.path[1].x == 10 and stone.path[1].map == 1 and stone.since == W.build
        and stone.day == math.floor(GetServerTime() / 86400) and far and far.name == "Far Away" and Lore:Stamp() > stamp
        and told == 0, "read over the set at once, of this client's build and the server's day; the stamp moved")
    Frame()
    check(told == 1, "and the set's listeners are told on the next frame")
    check(type(saved[5]) == "string" and Codec.Build(saved[5]) == W.build, "kept in the saved variable as a row of the set")
    check(Data.Learn("Lore", 1, { name = "Newest Road" }) and #Lore:History(1) == 2 and Lore:Get(1).name == "Newest Road",
        "learnt again: in the last one's place, the set's own still in the history under it")
    check(not Data.Learn("Lore", 1, { name = "a\tb" }) and not Data.Learn("Lore", 1, {}) and not Data.Learn("Nowhere", 1, { name = "x" })
        and not Data.Learn("Lore", nil, { name = "x" }) and Lore:Get(1).name == "Newest Road",
        "nothing learnt of a value its fields cannot hold, of no field at all, of a set Core does not hold, or without a key")
    Lore:OffStamp(Told)
end

-------------------------------------------------------------------------------
--  The account's characters (Characters.lua), on the saved variable SaneUIData_Characters
-------------------------------------------------------------------------------
do
    -- The game's bags, bank, gear and gold, and an alt kept by an older version or by hand: set before the login
    -- (at the top), when Core's reader took the characters' saved part
    local alt = ALT
    local saved = SaneUIData_Characters.forever
    local function Aside(what)
        for _, item in ipairs(saved.broken or {}) do if item.what == what then return item end end
    end
    local them = Data.Character(alt)
    check(them and them.class == nil and them.level == nil and them.money == 10 and Aside(alt .. " class").value == 5
        and Aside(alt .. " level").value == "thirty", "an alt's values of the wrong kind are set aside, never handed out; the others stay")
    -- Your gold changes: Core's answer follows, and those who listen are told on a later frame, outside the job
    local told, inside = 0, false
    Data.OnCharacters(function()
        told = told + 1
        inside = inside or coroutine.running() ~= nil
    end)
    check(Data.Character(Core.charKey).money == 1000, "you, with your gold")
    local stamp = Data.CharactersStamp()
    money = 5000
    W.Fire("PLAYER_MONEY")
    Frame()
    check(Data.Character(Core.charKey).money == 5000 and Data.CharactersStamp() > stamp and told == 0,
        "your gold changes: read in a step, and the answer and the stamp follow")
    Frame()
    check(told == 1 and not inside, "those who listen are told on a later frame, outside the job")
    -- Three places stored by one read (the bags, what is worn, slot by slot): told once
    told = 0
    bags[0][1].stackCount = 7
    worn[1] = 6001
    W.Fire("BAG_UPDATE", 0)
    W.Fire("PLAYER_EQUIPMENT_CHANGED", 1, true)
    W.Fire("BAG_UPDATE_DELAYED")
    for _ = 1, 2 do Frame() end
    check(told == 1 and Data.Items(Core.charKey, "bags")[1].count == 7 and Data.Worn(Core.charKey)[1] == 6001,
        "a read that stores three places tells those who listen once")
    -- A slot the client hides (a secret value, as the 12.x client hands them out): its count counts one, a hidden item
    -- is no item; both go through Core.Plain, never compared
    bags[0][2], bags[0][3] = { itemID = 4503, stackCount = W.Secret() }, { itemID = W.Secret(), stackCount = 5 }
    W.Fire("BAG_UPDATE", 0)
    W.Fire("BAG_UPDATE_DELAYED")
    for _ = 1, 2 do Frame() end
    local hidden = Data.Count(4503)
    check(hidden and hidden.total == 1 and hidden[Core.charKey].bags == 1 and #Data.Items(Core.charKey, "bags") == 3,
        "a slot the client hides: a hidden count counts one, a hidden item is passed over")
    -- The bank closes while it is read, its time more than a frame's: kept whole, never half read
    bags[6], bags[7], bags[8] = { { itemID = 1, stackCount = 1 } }, { { itemID = 2, stackCount = 1 } }, { { itemID = 3, stackCount = 1 } }
    cost = 3
    W.Fire("BANKFRAME_OPENED")
    Frame()
    W.Fire("BANKFRAME_CLOSED")
    bags[6], bags[7], bags[8] = nil, nil, nil -- closed: the game knows the bank no more
    for _ = 1, 4 do Frame() end
    local bank = Data.Items(Core.charKey, "bank")
    check(bank and #bank == 3 and bank[3].item == 3, "a bank closed while it was read is kept whole, never half read")
    -- The logout comes while the job is cut off in the bags: they are read again then, whole
    bags[2] = { { itemID = 4502, stackCount = 2 } }
    W.Fire("BAG_UPDATE", 2)
    W.Fire("BAG_UPDATE_DELAYED")
    Frame()
    cost = 0
    local before = saved.characters[Core.charKey].bags
    W.Fire("PLAYER_LOGOUT")
    check(not before:find("4502", 1, true) and saved.characters[Core.charKey].bags:find("4502\0312", 1, true),
        "the logout reads again the place the job was cut off in")
    for _ = 1, 4 do Frame() end
    -- An alt forgotten (Profiles' Forget: deleted, or moved to another account): gone from every answer
    local count = Data.Count(4500)
    check(count and count[alt] and count[alt].bags == 2 and count.total == 9, "an alt's things are counted with yours")
    told = 0
    local moved = Data.CharactersStamp()
    check(Data.Forget(Core.charKey) == false and Data.Forget("Player-70-00000000") == false and saved.characters[Core.charKey],
        "the one played is never forgotten, nor one Core does not know")
    check(Data.Forget(alt) == true and saved.characters[alt] == nil and Data.Character(alt) == nil and #Data.Characters() == 1
        and Data.Characters()[1].key == Core.charKey and Data.Items(alt, "bags") == nil and Data.Count(4500).total == 7
        and not Data.Count(4500)[alt] and Data.CharactersStamp() > moved and told == 0,
        "an alt forgotten: gone from the saved file, the characters, their things and the counts")
    Frame()
    check(told == 1, "and those who listen are told, once, on a later frame")
end

-------------------------------------------------------------------------------
--  The ships' times (Ships.lua): looked for once Travel is there; a boat's round learnt, refined, kept over a
--  new run of the realm, and set right after a ride across a restart
-------------------------------------------------------------------------------
do
    local Ships = Data.Ships()
    local position, looks = UnitPosition, 0
    UnitPosition = function(...)
        looks = looks + 1
        return position(...)
    end
    W.Wait(10)
    check(looks == 0, "nothing is looked at for the ships' times while the set Travel is not there")
    -- Two boats, each between two docks 6000 yards apart on one map (y 0 and y 5000); the set gives neither its round.
    -- And two teleports (Teleports.lua, below): one to a place the set has, one to a place it has not.
    W.AddSets(MakeSets("Ways", { ["Travel.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Travel", { game = "forever", hash = "00000b0a", build = 65000, key = "int", fields = { "kind", "path", "spell" }, types = { "text", "list tuple(x:number,y:number,map:int,stay:number,jump:bool)", "int" }, patches = {} })\n'
        .. 'if not S then return end\nS.rows[3] = "65000\\t\\tboat\\t0\\0310\\0310\\03160\\0306000\\0310\\031\\03160"\n'
        .. 'S.rows[4] = "65000\\t\\tboat\\t0\\0315000\\0310\\03160\\0306000\\0315000\\031\\03160"\n'
        .. 'S.rows[3003561] = "65000\\t\\tteleport\\t-9003.46\\031870.03\\0310\\t3561"\n'
        .. 'S.rows[4297659] = "65000\\t\\tteleport\\t\\t1297659"\n'
        .. 'S.index.byKind = { boat = "3\\0304", teleport = "3003561\\0304297659" }\n' }))
    for _ = 1, 3 do Frame() end
    W.Wait(10)
    local timetable = Ships:Table(3)
    check(looks > 0 and timetable and #timetable.stops == 2 and not timetable.known and not timetable.given,
        "the set there, the looks begin; the boat's round is estimated")
    -- The boats really take 10 seconds a round longer than estimated: they sail slower than the estimate says, so
    -- a ride's time is a second or so off until the round is learnt (as in the game)
    local round = timetable.round + 10
    local slower = (round - 120) / Ships.Run(6000)
    local function At(seconds) -- yards sailed so many seconds after leaving the first dock, at the estimate's speed
        local ramp, yards = Ships.SPEED / Ships.ACCEL, 6000
        if seconds <= 0 then return 0 end
        if seconds < ramp then return Ships.ACCEL * seconds ^ 2 / 2 end
        local left = Ships.Run(yards) - seconds
        if left > ramp then return Ships.SPEED ^ 2 / (2 * Ships.ACCEL) + Ships.SPEED * (seconds - ramp) end
        return yards - Ships.ACCEL * math.max(0, left) ^ 2 / 2
    end
    -- A ride on boat key, which leaves its first dock at server time leaves: aboard well into its run
    local learnt
    Ships:OnLearn(function(key) learnt = key end)
    local function Ride(key, leaves)
        learnt = nil
        W.Wait(leaves - 5 - (W.serverStart + W.clock))
        local y = key == 4 and 5000 or 0
        W.place = function() return { At((W.serverStart + W.clock - leaves) / slower), y, 5, 0 } end
        for _ = 1, 60 do W.Wait(1) end
        W.place = nil
        W.Wait(5)
        return learnt == key and Core.Store(Core.name).ships["Stub Realm"][key]
    end
    local start = W.serverStart + W.clock + 100
    local kept = Ride(3, start)
    check(kept and math.abs(kept.epoch - start) < 3 and kept.rides == 1 and not kept.round, "a ride: when the boat left, kept for this realm")
    kept = Ride(3, start + round + 1) -- a second late, as a ride's time may be
    check(kept and kept.rides == 2 and math.abs(kept.round - (round + 1)) < 1 and kept.span == 1 and kept.doubt and Ships:Table(3).known,
        "the next round's ride: the round learnt from the estimate, doubted until a ride agrees with it")
    kept = Ride(3, start + 4 * round)
    local learntRound = kept and kept.round
    check(kept and kept.span == 3 and not kept.doubt and math.abs(kept.round - round) < 1.5,
        "a ride three rounds on agrees: the round confirmed, and corrected by the longer span")
    kept = Ride(3, start + 5 * round)
    check(kept and kept.round == learntRound and kept.span == 3 and not kept.doubt, "a ride over a shorter span does not change it")
    local restart = start + 7 * round + 100 -- the realm restarted meanwhile: its ships run from another time
    kept = Ride(3, restart)
    local arrive = kept and Ships:Next(3, 1, restart + 1)
    check(kept and kept.round == learntRound and kept.doubt and math.abs(kept.epoch - restart) < 1
        and math.abs(arrive - (kept.epoch + Ships:Table(3).round - 60)) < 0.01,
        "a ride that does not agree is of a new run of the realm: its time taken, the round kept")
    kept = Ride(3, restart + 2 * round)
    check(kept and kept.round == learntRound and not kept.doubt, "the next ride of that run agrees with it: the round holds")
    -- The other boat: its first two rides on either side of a restart, then one more of the new run
    start = W.serverStart + W.clock + 100
    Ride(4, start)
    local other = start + 3 * round + 140
    kept = Ride(4, other)
    check(kept and math.abs(kept.round - round) > 20 and kept.doubt, "two rides across a restart give a wrong round, doubted")
    kept = Ride(4, other + 3 * round)
    check(kept and math.abs(kept.round - round) < 4 and math.abs(Ships:Table(4).round - round) < 4,
        "the next ride does not agree with it either: the round it gives takes its place")
    -- A saved file of the wrong shape: nothing known, and no error
    local store = Core.Store(Core.name)
    store.ships["Stub Realm"][3] = { epoch = "soon", seen = {} }
    check(Ships:Next(3, 1) == nil and Ships:Seen(3) == nil, "a kept ride of the wrong shape is none")
    store.ships = 7
    check(pcall(Ships.Next, Ships, 3, 1) and Ships:Next(3, 1) == nil and type(store.ships) == "table", "nor a part that is no table")
    UnitPosition = position
end

-------------------------------------------------------------------------------
--  Where a teleport brings one (Teleports.lua): learnt where one brought the player, as learned data of Travel
-------------------------------------------------------------------------------
do
    local Travel, Teleports = Data.Set("Travel"), Data.Teleports
    local function Cast(spell) W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", spell) end
    -- Teleport: Dalaran, which the set knows no place of: cast in Stormwind, a look there, then the leap
    W.place = { -9000, 860, 0, 0 }
    Cast(1297659)
    W.Wait(0.3)
    W.place = { 300.123, 400.456, 0, 0 }
    W.Wait(0.3)
    local way, learnt = Travel:Get(4297659), SaneUIData_Learned.forever.learned.Travel
    check(way and way.path and way.path[1].x == 300.12 and way.path[1].y == 400.46 and way.path[1].map == 0
        and way.kind == "teleport" and way.spell == 1297659 and learnt and type(learnt[4297659]) == "string",
        "a teleport's spell cast, then a leap: where it ended is its place, to a hundredth of a yard, learnt into the set's record")
    -- One the set has a place for: a cast that lands there teaches nothing new
    W.place = { 100, 100, 0, 0 }
    Cast(3561)
    W.Wait(0.3)
    W.place = { -9003, 870.5, 0, 0 }
    W.Wait(0.3)
    check(learnt[3003561] == nil and Travel:Get(3003561).path[1].x == -9003.46,
        "a landing within Teleports.SAME yards of the set's place: nothing learnt")
    -- Running on after a cast, never a leap, for longer than it waits: nothing learnt, nor by a leap after that
    local from = W.clock
    W.place = function() return { 200 + 7 * (W.clock - from), 200, 0, 0 } end
    Cast(1297659)
    W.Wait(Teleports.WAIT + 5)
    W.place = { 5000, 5000, 0, 0 }
    W.Wait(1)
    check(Travel:Get(4297659).path[1].x == 300.12, "running on after a cast: no leap, nothing learnt, and nothing after its time")
    -- Onto another map by a loading screen (no place told meanwhile): where the player stands once it is over
    W.place = { -9000, 860, 0, 0 }
    Cast(1297659)
    W.place = nil
    W.Wait(2)
    W.place = { 7000.5, -2000.25, 0, 1 }
    W.Fire("PLAYER_ENTERING_WORLD")
    W.Wait(0)
    way = Travel:Get(4297659)
    check(way.path[1].map == 1 and way.path[1].x == 7000.5 and way.path[1].y == -2000.25,
        "after a loading screen, onto another map: learnt there")
    -- A spell of no teleport: nothing looked for
    Cast(12345)
    W.place = { 0, 0, 0, 0 }
    W.Wait(1)
    check(Travel:Get(4297659).path[1].map == 1, "a spell of no teleport: nothing learnt")
    -- A cast whose spell the client hides (a secret value): nothing looked for, through Core.Plain in every listener of
    -- the cast (Teleports, Loot), and no error noted
    local logged = #Core.log
    Cast(W.Secret())
    W.place = { 6000, 6000, 0, 0 }
    W.Wait(1)
    check(Travel:Get(4297659).path[1].map == 1 and #Core.log == logged, "a spell the client hides: nothing looked for, no error")
    W.place = nil
end

-------------------------------------------------------------------------------
--  What a map shows (Map.lua): sets arriving together read once; the last read's points kept while it is read anew
-------------------------------------------------------------------------------
do
    local Map, Spawns, walks = Data.Map(), Data.Set("Spawns"), 0
    local each = Spawns.Each
    Spawns.Each = function(...)
        walks = walks + 1
        return each(...)
    end
    check(Map:On(1429) == nil, "the places first asked for: nil while they are read")
    for _ = 1, 3 do Frame() end
    check(Map:On(1429) and #Map:On(1429) == 0, "then none yet (the boats here stand at no dock of a map)")
    -- Two of the sets a map reads arrive together
    W.AddSets(MakeSets("Spots", {
        ["Places.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Places", { game = "forever", hash = "0000000c", build = 65000, key = "int", fields = { "kind", "name", "point" }, types = { "text", "text", "point" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows[1] = "65000\\t\\tcave\\tThe Hole\\t1429\\03150\\03150"\n'
            -- (for the watchers, below: a mailbox and a crossing on another map, all three not yet confirmed)
            .. 'S.rows[2] = "65000\\t\\tmailbox\\t\\t1430\\03130\\03130"\nS.rows[3] = "65000\\t\\tcrossing\\t\\t1430\\03190\\03190"\n'
            .. 'S.unverified = "1\\0302\\0303"\nS.index.byKind = { cave = "1", mailbox = "2", crossing = "3" }\n',
        ["Spawns.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Spawns", { game = "forever", hash = "0000000d", build = 65000, key = "text", fields = { "points" }, types = { "list point" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows["object:1617"] = "65000\\t\\t1429\\03110\\03120"\n'
            .. 'S.rows["npc:69"] = "65000\\t\\t1430\\03160\\03160"\nS.rows["npc:70"] = "65000\\t\\t1430\\03120\\03120"\n'
            -- (for the watchers: a creature of two spawn points, far apart)
            .. 'S.rows["npc:71"] = "65000\\t\\t1431\\03110\\03110\\0301431\\03180\\03180"\n'
            .. 'S.unverified = "object:1617\\030npc:69\\030npc:70\\030npc:71"\n' }))
    for _ = 1, 3 do Frame() end
    check(walks == 0 and Map:On(1429) and #Map:On(1429) == 0, "a change waits MapReader.REREAD seconds, so a burst of them is one walk")
    W.Wait(Data.MapReader.REREAD)
    for _ = 1, 6 do Frame() end
    local spot = Map:Spawns("object:1617")
    check(walks == 1 and #Map:On(1429) == 2 and spot and spot[1429][1][1] == 0.1, "two sets arriving together: read once")
    -- The objects' facts arrive: what the places say of each object is looked through first (a job), and as one says
    -- something else now the map is read anew; until that read is done the last one's points stay
    W.AddSets(MakeSets("Things", { ["Objects.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Objects", { game = "forever", hash = "0000000e", build = 65000, key = "int", fields = { "name", "kind" }, types = { "text", "text" }, patches = {} })\n'
        .. 'if not S then return end\nS.rows[1617] = "65000\\t\\tPeacebloom\\therb"\nS.unverified = "1617"\nS.index.byName = { Peacebloom = "1617" }\n' }))
    Frame()
    W.Wait(Data.MapReader.REREAD)
    for _ = 1, 2 do Frame() end -- the look through the facts: the herb is named now, so the walk comes
    check(walks == 2 and Map:Spawns("object:1617") == spot, "while the map is read anew, the last read's points stay")
    for _ = 1, 6 do Frame() end
    local herb
    for _, place in ipairs(Map:On(1429)) do herb = herb or place.what == "herb" and place end
    check(herb and herb.name == "Peacebloom" and Map:Spawns("object:1617") ~= spot and Map:Spawns("object:1617")[1429][1][2] == 0.2,
        "then the new read's: the object named, a herb")
    Spawns.Each = nil
end

-------------------------------------------------------------------------------
--  Verified (Confirm.lua, Watchers.lua): what the game confirms in play of the facts not yet verified, kept, shared
--  with the guild and the group (not in a fight or an instance), taken from them; the watchers; items' stats learned
-------------------------------------------------------------------------------
do
    local Watchers = Data.Watchers
    W.AddSets(MakeSets("Verify", {
        ["NPCs.lua"] = 'local S = SaneUI.Core.Data.Add(1, "NPCs", { game = "forever", hash = "00000020", build = 65000, key = "int", fields = { "name", "services", "levelMin", "levelMax", "rank", "kind", "health" }, '
            .. 'types = { "text", "list text", "int", "int", "text", "text", "map int int" }, play = { "name", "levelMin", "levelMax", "rank", "kind", "health{}?", "services[]" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows[69] = "65000\\t\\tA Vendor\\tvendor"\nS.rows[70] = "65000\\t\\tA Wolf"\n'
            .. 'S.rows[72] = "65000\\t\\tA Banker\\tbanker\\030vendor"\nS.unverified = "69\\03070\\03072"\n',
        ["Encounters.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Encounters", { game = "forever", hash = "00000021", build = 65000, key = "int", fields = { "name" }, types = { "text" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows[700] = "65000\\t\\tThe First Boss"\n',
        ["Bosses.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Bosses", { game = "forever", hash = "00000022", build = 65000, key = "int", fields = { "abilities", "loot" }, types = { "list int", "list int" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows[700] = "65000\\t\\t801\\030802\\t901\\030902"\nS.unverified = "700"\n',
        ["Items.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Items", { game = "forever", hash = "00000023", build = 65000, key = "int", fields = { "name", "quality", "armor", "damageMin", "damageMax", "speed", "stats" }, types = { "text", "int", "int", "int", "int", "number", "map text int" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows[4500] = "65000\\t\\tLinen Shirt\\t1\\t\\t\\t\\t\\tITEM_MOD_STAMINA_SHORT\\0313"\nS.rows[4501] = "65000\\t\\tOld Blade\\t2"\n' }))
    for _ = 1, 3 do Frame() end
    local Places, Spawns, NPCs, Objects, Bosses = Data.Set("Places"), Data.Set("Spawns"), Data.Set("NPCs"), Data.Set("Objects"), Data.Set("Bosses")
    check(Places:Unverified(2) and Places:Unverified(1) and not Places:Unverified(99) and Bosses:Unverified(700, "l901")
        and not Data.Set("Encounters"):Unverified(700),
        "the set files list the entries not yet verified (a batch's alone); an entry of the game's, or none, is not")

    -- The stand-in's world: where the player stands on a map (1000 yards square), what a unit is, the instance
    local guids, names, dead, inside, instance = { player = "Player-70-0000ABCD" }, {}, {}, false, 90
    W.mapPos = nil
    C_Map = { GetPlayerMapPosition = function(map)
                  local at = W.mapPos
                  if at and at.map == map then return { GetXY = function() return at.x, at.y end } end
              end,
              GetMapWorldSize = function() return 1000, 1000 end }
    UnitGUID = function(unit) return guids[unit] end
    UnitName = function(unit) if unit == "player" then return "Tester", "Stub" end return names[unit] end
    UnitIsPlayer = function(unit) return unit == "player" end
    UnitIsDead = function(unit) return dead[unit] or false end
    UnitLevel = function(unit) if unit == "player" then return W.level end end -- the creatures' facts: in the next part
    IsInInstance = function() return inside end
    GetInstanceInfo = function() return "A Dungeon", "party", 1, "Normal", 5, 0, false, instance end
    local loot = {}
    GetNumLootItems = function() return #loot end
    GetLootSlotLink = function(slot) return loot[slot] and ("|cff0070dd|Hitem:%d::::|h[x]|h|r"):format(loot[slot]) end
    -- The wire: what goes, as the guild's test sees it; packing a stand-in easy to read back
    local sent = {}
    local function Hex(text) return (text:gsub(".", function(c) return ("%02x"):format(c:byte()) end)) end
    C_EncodingUtil = { CompressString = function(text) return "Z" .. text end,
        DecompressString = function(text) if text:sub(1, 1) == "Z" then return text:sub(2) end end,
        EncodeBase64 = Hex, DecodeBase64 = function(text) return (text:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)) end }
    C_ChatInfo = rawget(_G, "C_ChatInfo") or {}
    C_ChatInfo.RegisterAddonMessagePrefix = function() return true end
    C_ChatInfo.SendAddonMessage = function(prefix, text, channel) sent[#sent + 1] = { text = text, channel = channel } return 0 end
    C_ChatInfo.InChatMessagingLockdown = function() return false end
    local guild, group = false, false
    -- The wire's queue goes on its frame's OnUpdate, one look a second here
    local function Pass(seconds)
        for _ = 1, seconds do
            W.Wait(1)
            local wireFrame = Core.Wire.frame
            if wireFrame and wireFrame:IsShown() then wireFrame._scripts.OnUpdate(wireFrame, 1) end
        end
    end
    IsInGuild = function() return guild end
    IsInGroup = function() return group end
    IsInRaid = function() return false end

    -- A mailbox opened: the set's mailbox within reach confirmed, the crossing far off not
    W.mapPos = { map = 1430, x = 0.305, y = 0.30 }
    W.Fire("MAIL_SHOW")
    local kept = SaneUIData_Learned.forever.confirmed
    check(not Places:Unverified(2) and Places:Unverified(3) and kept.Places and type(kept.Places[2]) == "string"
        and kept.Places[2]:find("^%d+\031%d+\031%*$"),
        "a mailbox opened: the set's within Watchers.MAILBOX yards confirmed, kept as its day, build and parts (the whole)")
    -- A zone left at the set's crossing
    W.mapPos = { map = 1430, x = 0.91, y = 0.90 }
    W.Fire("ZONE_CHANGED_NEW_AREA")
    check(not Places:Unverified(3), "a zone left near the set's crossing: confirmed")
    -- A creature seen near its spawn: its spawn, and the creature where it offers nothing to talk to
    W.mapPos = { map = 1430, x = 0.21, y = 0.20 }
    guids.target = "Creature-0-1-2-3-70-0000AAAA"
    W.combat = true
    W.Fire("PLAYER_TARGET_CHANGED")
    check(Spawns:Unverified("npc:70") and NPCs:Unverified(70), "in a fight: nothing looked at")
    W.combat = false
    W.Fire("PLAYER_TARGET_CHANGED")
    check(not Spawns:Unverified("npc:70") and not NPCs:Unverified(70), "out of it: the wolf seen at its spawn, both confirmed")
    W.mapPos = { map = 1430, x = 0.61, y = 0.60 }
    guids.mouseover = "Creature-0-1-2-3-69-0000BBBB"
    W.Fire("UPDATE_MOUSEOVER_UNIT")
    check(not Spawns:Unverified("npc:69") and NPCs:Unverified(69),
        "a vendor seen at its spawn: its spawn confirmed, the vendor itself only by talking to it")
    guids.npc = "Creature-0-1-2-3-69-0000BBBB"
    W.Fire("MERCHANT_SHOW")
    check(not NPCs:Unverified(69), "talked to: the vendor confirmed")
    -- A thing used (the game's unit "npc" is an object): its spawn near, and the thing
    W.mapPos = { map = 1429, x = 0.10, y = 0.21 }
    guids.npc = "GameObject-0-1-2-3-1617-0000CCCC"
    W.Fire("GOSSIP_SHOW")
    check(not Spawns:Unverified("object:1617") and not Objects:Unverified(1617), "a thing used at its spawn: both confirmed")

    -- A boss killed, then its loot: an item the set names confirmed; one it does not only from a corpse of its name
    W.Fire("ENCOUNTER_START", 700, "The First Boss", 1, 5)
    W.Fire("UNIT_SPELLCAST_START", "boss1", "Cast-1", 801)
    W.Fire("UNIT_SPELLCAST_START", "party1", "Cast-2", 802)
    check(not Bosses:Unverified(700, "a801") and Bosses:Unverified(700, "a802"),
        "in its fight, a spell the boss's unit cast: its ability confirmed; nobody else's casts count")
    -- The casts are asked of the game for the units watched alone, never for every unit about; a nameplate's once shown
    local bare = false
    for _, widget in ipairs(W.frames) do
        for _, event in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_SENT" }) do
            if widget._events[event] and not (widget._units and widget._units[event] and #widget._units[event] > 0) then bare = true end
        end
    end
    check(not bare, "the casts are asked of the game for the units watched alone, never for every unit about")
    names.nameplate4 = "The First Boss"
    W.Fire("UNIT_SPELLCAST_START", "nameplate4", "Cast-3", 805)
    check(Bosses:Unverified(700, "a805"), "a nameplate the game has not shown: its casts are not heard")
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate4")
    W.Fire("UNIT_SPELLCAST_START", "nameplate4", "Cast-3", 805) -- the first look asks the set Encounters for the names (a job)
    for _ = 1, 4 do Frame() end
    W.Fire("UNIT_SPELLCAST_START", "nameplate4", "Cast-3", 805)
    check(not Bosses:Unverified(700, "a805"), "shown: heard, the boss's cast by its nameplate confirmed as a fact of its own")
    names.nameplate4 = nil
    W.Fire("ENCOUNTER_END", 700, "The First Boss", 1, 5, 1)
    loot = { 901, 905 }
    W.Fire("LOOT_OPENED")
    check(not Bosses:Unverified(700, "l901") and Bosses:Unverified(700, "l905") and Bosses:Unverified(700, "l902"),
        "after the kill, in its instance: an item the set names for it confirmed; another not from just any corpse")
    names.target, dead.target = "The First Boss", true
    W.Fire("LOOT_OPENED")
    check(not Bosses:Unverified(700, "l905") and Data.Confirmed("Bosses", 700, "l905")
        and Data.ConfirmedParts("Bosses", 700)[1] == "a801",
        "from the boss's own corpse (the target of its name, dead): an item the set does not name confirmed too, a fact of its own")
    instance = 91
    loot = { 902 }
    W.Fire("LOOT_OPENED")
    check(Bosses:Unverified(700, "l902"), "in another instance: nothing of the boss's")
    instance = 90
    W.Wait(Watchers.LOOT + 1)
    W.Fire("LOOT_OPENED")
    check(Bosses:Unverified(700, "l902"), "too long after the kill: nothing of the boss's")
    names.target, dead.target = nil, nil

    -- Sharing: nobody to tell yet; in a guild but inside an instance: it waits; out of it, slowly, to the guild
    local outbox = SaneUIData_Learned.forever.outbox
    check(#sent == 0 and #outbox >= 8, "nobody to tell (no guild, no group): what was confirmed waits in the outbox")
    guild, inside = true, true
    W.Fire("PLAYER_GUILD_UPDATE")
    Pass(15)
    check(#sent == 0, "inside an instance: still waiting")
    inside = false
    Core.general.shareData = false
    W.Fire("PLAYER_ENTERING_WORLD")
    Pass(15)
    check(#sent == 0, "out of it with the switch off: nothing goes")
    Core.general.shareData = nil
    Pass(15)
    check(#sent == 0, "the switch turned on: nothing by itself, no timer looks every few seconds (the switch's hook tells)")
    Core.described[Core.name].changed("shareData", true)
    Pass(3)
    check(#sent >= 1 and sent[1].channel == "GUILD" and sent[1].text == "V1\tf\tPlaces\t2\t*",
        "told by the hook: to the guild, one confirmation a message (set, key, parts)")
    -- A fight: sharing is held while it lasts (Core.Restricted), and the fight's end tells it to go on
    local held = #sent
    W.Combat(true)
    Pass(5)
    local quiet = #sent == held and #outbox > 0
    W.Combat(false)
    Pass(5)
    check(quiet and #sent > held, "in a fight nothing more goes, what waits stays in the outbox; the fight over, told by its end, the next goes")
    Pass(40)
    local bossLine
    for _, message in ipairs(sent) do
        if message.text:find("^V1\tf\tBosses\t700\t") then bossLine = message.text end
    end
    check(#outbox == 0 and bossLine and bossLine:find("a801", 1, true) and bossLine:find("l901", 1, true)
        and bossLine:find("l905", 1, true), "everything sent in time, a boss's parts together in one message")

    -- Taken from others: a confirmation of an entry this client has unverified, once three members sent the same, one of
    -- them on the guild's channel; never by a whisper, nor an item the game does not know; kept apart (heard), never sent on
    local wire = Core.Wire
    local heard = SaneUIData_Learned.forever.heard
    wire.Take("V1\tf\tPlaces\t1\t*", "WHISPER", "Droopy Fairwind")
    check(Places:Unverified(1), "a confirmation whispered: not taken")
    wire.Take("V1\tf\tPlaces\t1\t*", "GUILD", "Droopy Fairwind")
    wire.Take("V1\tf\tPlaces\t1\t*", "PARTY", "Ann Brook")
    check(Places:Unverified(1), "from one member, or two: it waits")
    wire.Take("V1\tf\tPlaces\t1\t*", "PARTY", "Droopy Fairwind")
    check(Places:Unverified(1), "the same member again is no third")
    wire.Take("V1\tf\tPlaces\t1\t*", "PARTY", "Sly Rook")
    check(not Places:Unverified(1) and heard.Places and type(heard.Places[1]) == "string" and not (kept.Places and kept.Places[1]),
        "three members, one of them on the guild's channel: taken, kept apart from this client's own (heard, not confirmed)")
    Pass(20)
    local passedOn = false
    for _, message in ipairs(sent) do
        if message.text:find("^V1\tf\tPlaces\t1\t") then passedOn = true end
    end
    check(not passedOn, "and never sent on")
    local spells = rawget(_G, "C_Spell") or {}
    C_Spell = spells
    local spellName = spells.GetSpellName
    spells.GetSpellName = function(id) return (id == 802 or (id >= 806 and id <= 809)) and "Cleave" or nil end
    for _, name in ipairs({ "Droopy Fairwind", "Ann Brook", "Sly Rook" }) do
        wire.Take("V1\tf\tBosses\t700\ta802,l99999,a803", name == "Droopy Fairwind" and "GUILD" or "PARTY", name)
    end
    check(not Bosses:Unverified(700, "a802") and Bosses:Unverified(700, "l99999") and Bosses:Unverified(700, "a803"),
        "from three members: taken; a part naming an item or a spell the game does not know: not")
    for _, name in ipairs({ "Ann Brook", "Sly Rook", "Bo Peep" }) do wire.Take("V1\tf\tBosses\t700\ta806", "PARTY", name) end
    check(Bosses:Unverified(700, "a806"), "three of a group alone: not enough, a group can hold strangers")
    wire.Take("V1\tf\tBosses\t700\ta806", "GUILD", "Ann Brook")
    check(not Bosses:Unverified(700, "a806"), "one of them on the guild's channel: taken")
    SaneUIData_Market = { forever = { houses = {}, mine = { [Core.PlayerKeyOf("Bo Peep")] = true } } }
    Data.Series("Prices").Account()
    wire.Take("V1\tf\tBosses\t700\ta807", "PARTY", "Bo Peep")
    check(not Bosses:Unverified(700, "a807"), "from this player's other account: taken at once")
    Data.Series("Prices").Clear()
    local most = Data.Confirmations.WAITING
    Data.Confirmations.WAITING = 1
    wire.Take("V1\tf\tBosses\t700\ta808", "GUILD", "Tam Lin")
    wire.Take("V1\tf\tBosses\t700\ta809", "GUILD", "Tam Lin")
    wire.Take("V1\tf\tBosses\t700\ta809", "GUILD", "Ann Brook")
    wire.Take("V1\tf\tBosses\t700\ta809", "GUILD", "Sly Rook")
    check(Bosses:Unverified(700, "a809"), "a member with Confirm.WAITING parts waiting is heard no further")
    Data.Confirmations.WAITING = most
    wire.Take("V1\tf\tBosses\t700\ta809", "GUILD", "Tam Lin")
    check(not Bosses:Unverified(700, "a809"), "room again: its word counts")
    -- A part as Check.lua makes it, of what the entry holds; an entry takes at most Confirm.MOST parts from members
    for _, name in ipairs({ "Droopy Fairwind", "Ann Brook", "Sly Rook" }) do
        wire.Take("V1\tf\tNPCs\t72\tservices=banker,services=mailbox,services,health=12,kind,name=A Banker", "GUILD", name)
    end
    check(Data.Confirmed("NPCs", 72, "services=banker") and Data.Confirmed("NPCs", 72, "kind")
        and not Data.Confirmed("NPCs", 72, "services=mailbox") and not Data.Confirmed("NPCs", 72, "services")
        and not Data.Confirmed("NPCs", 72, "health=12") and not Data.Confirmed("NPCs", 72, "name=A Banker"),
        "a member of a list the entry holds, a field told whole: taken; a member it lacks, a bare list, a map it has none of, a field as a member: not")
    most = Data.Confirmations.MOST
    Data.Confirmations.MOST = #Data.ConfirmedParts("NPCs", 72) + 1
    for _, name in ipairs({ "Droopy Fairwind", "Ann Brook", "Sly Rook" }) do wire.Take("V1\tf\tNPCs\t72\tname,services=vendor", "GUILD", name) end
    check(Data.Confirmed("NPCs", 72, "name") and not Data.Confirmed("NPCs", 72, "services=vendor"), "an entry takes at most Confirm.MOST parts from members")
    Data.Confirmations.MOST = most
    -- The game's own word stands apart from what members told: kept as this client's own all the same, and shared
    sent = {}
    check(Data.Confirm("NPCs", 72, "services=banker") and kept.NPCs[72]:find("services=banker", 1, true)
        and Data.Confirmed("NPCs", 72, "services=banker", true) and NPCs:Unverified(72, "services=banker") == false,
        "a part members told, then confirmed by the game here: this client's own (confirmed), kept as such")
    Pass(5)
    local ownWord = false
    for _, message in ipairs(sent) do
        if message.text:find("^V1\tf\tNPCs\t72\t") and message.text:find("services=banker", 1, true) then ownWord = true end
    end
    check(ownWord, "and shared, as the game's word here")
    -- What members told never makes the game's own check confirm an entry whole: only the fields told here count
    Data.Check("NPCs", 72, { services = { "vendor" } })
    check(Data.Confirmed("NPCs", 72, "services=vendor", true) and not Data.Confirmed("NPCs", 72),
        "the game agrees with a member of a list: that part confirmed; the entry not whole on the members' word for its other fields")
    Data.Check("NPCs", 72, { name = "A Banker" })
    check(Data.Confirmed("NPCs", 72, nil, true) and kept.NPCs[72]:find("*", 1, true), "every field of the play list told here: the entry confirmed whole")
    spells.GetSpellName = spellName

    -- Items: the stats the game gives of what the character has, compared with the set's; learned where they differ
    C_Item.GetItemInfo = function(id)
        if id == 4500 then return "Linen Shirt", "|Hitem:4500|h", 1, 5, 1, "Armor", "Cloth", 1, "INVTYPE_BODY", 135, 1, 4, 1, 0 end
        if id == 4501 then return "Old Blade", "|Hitem:4501|h", 2, 10, 5, "Weapon", "Sword", 1, "INVTYPE_WEAPON", 136, 25, 2, 7, 2 end
        if id == 4502 then return "New Thing", "|Hitem:4502|h", 2, 10, 5, "Armor", "Mail", 1, "INVTYPE_CHEST", 137, 50, 4, 3, 2 end
    end
    GetItemStats = function(link)
        if link:find("4500") then return { ITEM_MOD_STAMINA_SHORT = 3 } end
        if link:find("4501") then return { ITEM_MOD_AGILITY_SHORT = 5, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1.9 } end
        return { RESISTANCE0_NAME = 120 }
    end
    C_TooltipInfo = { GetItemByID = function(id)
        if id == 4501 then return { lines = { { leftText = "Old Blade" }, { leftText = "3 - 7 Damage", rightText = "Speed 2.60" } } } end
        return { lines = { { leftText = "x" } } }
    end }
    sent = {}
    Watchers.Item(4500)
    Watchers.Item(4501)
    Watchers.Item(4502)
    local Items = Data.Set("Items")
    local blade, shirt, chest = Items:Get(4501), Items:Get(4500), Items:Get(4502)
    check(not Data.Learned("Items", 4500) and blade.stats.ITEM_MOD_AGILITY_SHORT == 5 and blade.damageMin == 3
        and blade.damageMax == 7 and blade.speed == 2.6 and blade.name == "Old Blade" and not blade.stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT
        and shirt.stats.ITEM_MOD_STAMINA_SHORT == 3 and chest and chest.armor == 120 and chest.name == "New Thing",
        "an item as the set has it: nothing learned; one without its stats, and one the set lacks: learned as the game gives them")
    Pass(20)
    local block
    for _, message in ipairs(sent) do if message.text:find("^P1\tf\tL\t") then block = message end end
    check(block and block.channel == "GUILD", "what was learned shared with the guild as a block")

    -- A row learned by another: taken only where it changes nothing but what play teaches of the item
    local function Send(text)
        local packed = Hex("Z" .. text)
        wire.Take(("P1\tf\tL\t%d\t1\t1\t%d\t%s"):format(math.random(9999), #text, packed), "PARTY", "Ann Brook")
    end
    Send("Items\0284500\02870245\t20000\tLinen Shirt\t1\t\t\t\t\tITEM_MOD_STAMINA_SHORT\0314\030ITEM_MOD_SPIRIT_SHORT\0312")
    Send("Items\0284501\02870245\t20000\tShiny Blade\t2\t\t3\t7\t2.6\tITEM_MOD_AGILITY_SHORT\0315")
    for _ = 1, 3 do Frame() end
    check(Items:Get(4500).stats.ITEM_MOD_SPIRIT_SHORT == 2 and Items:Get(4501).name == "Old Blade",
        "from a group member: new stats taken; a row that renames the item: not")

    -- Kept apart from what was learned here, out of the harvest's rows; an item the set lacks only where the game knows
    -- it; what the player saw here wins; at most Confirm.KEPT rows of a set from members, the oldest making room
    local learnedPart = SaneUIData_Learned.forever
    check(learnedPart.taken.Items[4500] and not (learnedPart.learned.Items and learnedPart.learned.Items[4500]) and Data.Taken("Items", 4500),
        "a member's row stands apart (taken), never among the learned rows the harvest reads")
    local instant = C_Item.GetItemInfoInstant
    C_Item.GetItemInfoInstant = function(id) if id >= 4509 and id <= 4511 then return id, "", "", "", 1, 4, 0 end end
    Send("Items\0284509\02870245\t20100\tNew Shiny\t2")
    Send("Items\02899998\02870245\t20100\tNo Such Thing\t2")
    Send("Items\0284502\02870245\t99999\tNew Thing\t2\t\t\t\t\t\tITEM_MOD_STAMINA_SHORT\0319")
    for _ = 1, 3 do Frame() end
    check(Items:Get(4509) and Items:Get(4509).name == "New Shiny" and Data.Taken("Items", 4509) and not Items:Get(99998),
        "an item the set lacks: taken where the game knows it, not where it does not")
    check(Items:Get(4502).armor == 120 and not Items:Get(4502).stats and not Data.Taken("Items", 4502),
        "an item learned here: a member's row of it is not taken, what the player saw wins")
    local kept = Data.Confirmations.KEPT
    Data.Confirmations.KEPT = 2
    Send("Items\0284510\02870245\t19000\tOld Shiny\t2")
    Send("Items\0284511\02870245\t20200\tNewer Shiny\t2")
    for _ = 1, 3 do Frame() end
    check(Data.Taken("Items", 4509) and Data.Taken("Items", 4511) and not Data.Taken("Items", 4500) and not Data.Taken("Items", 4510),
        "a set keeps Confirm.KEPT rows from members: the oldest, by build and day, make room")
    Data.Confirmations.KEPT = kept
    C_Item.GetItemInfoInstant = instant
    Core.errors.wire = nil
    Send("Items\028nan\02870245\t20100\tNot A Number\t2")
    for _ = 1, 3 do Frame() end
    check(Core.errors.wire == nil, "a key that is no number (nan): the row passed over, without an error")

    -- A change of the facts alone: the places looked through, read anew only where a creature's name or kind changed
    W.Wait(Data.MapReader.REREAD)
    for _ = 1, 12 do Frame() end -- the facts that arrived above: looked through, and the map read anew
    local Map, walks = Data.Map(), 0
    local each = Spawns.Each
    Spawns.Each = function(...)
        walks = walks + 1
        return each(...)
    end
    Data.Learn("NPCs", 71, { name = "A Roamer", health = { [5] = 120 } })
    W.Wait(Data.MapReader.REREAD)
    for _ = 1, 6 do Frame() end
    check(walks == 0, "a creature's row learned that changes neither its name nor its kind on the map: no walk")
    -- A change that lands while a look is pending: one more look after it, then rest
    local run, looks = Steps.Run, 0
    Steps.Run = function(options, ...)
        if type(options) == "table" and options.name == "Map look" then looks = looks + 1 end
        return run(options, ...)
    end
    Data.Learn("NPCs", 71, { name = "A Roamer", health = { [5] = 121 } })
    W.Wait(Data.MapReader.REREAD) -- the look is started, not run yet
    Data.Learn("NPCs", 71, { name = "A Roamer", health = { [5] = 122 } })
    for _ = 1, 10 do Frame() end
    check(looks == 2 and walks == 0 and not Steps.Running("Map look") and not Steps.frame:IsShown(),
        "a change that lands while a look is pending: one more look after it, then no job, and the scheduler at rest")
    Steps.Run = run
    Data.Learn("NPCs", 71, { name = "A Roamer", rank = "rare" })
    W.Wait(Data.MapReader.REREAD)
    for _ = 1, 8 do Frame() end
    local rare
    for _, place in ipairs(Map:On(1431) or {}) do rare = rare or (place.key == "npc:71" and place) or nil end
    check(walks == 1 and rare and rare.what.rare and rare.name == "A Roamer", "a rare now: the places read anew, and it stands on its map")
    Spawns.Each = nil
end

-------------------------------------------------------------------------------
--  Checked and counted in play (Check.lua, Tally.lua, Quests.lua, Loot.lua, Facts.lua): what the game tells compared
--  field by field, confirmed or learned; quests offered, taken, worked on, handed in; every loot window counted; places
--  seen merged by yards; creatures, vendors and spells
-------------------------------------------------------------------------------
do
    local Watchers, Tally, Loot, Checks = Data.Watchers, Data.Tally, Data.Loot, Data.Checks
    -- A set's file as dev/tools/data writes it: its rows (fields cut by tabs, as in the master's order)
    local function SetText(name, hash, fields, types, play, rows, unverified)
        local function Quoted(list)
            local out = {}
            for index, each in ipairs(list or {}) do out[index] = ("%q"):format(each) end
            return table.concat(out, ", ")
        end
        local text = ('local S = SaneUI.Core.Data.Add(1, %q, { game = "forever", hash = %q, build = 65000, key = "int", fields = { %s }, types = { %s }, %spatches = {} })\nif not S then return end\n')
            :format(name, hash, Quoted(fields), Quoted(types), play and ("play = { " .. Quoted(play) .. " }, ") or "")
        for key, row in pairs(rows) do text = text .. ("S.rows[%d] = %q\n"):format(key, "65000\t\t" .. row) end
        if unverified then text = text .. ("S.unverified = %q\n"):format(unverified) end
        return text
    end
    local QUEST_FIELDS = { "name", "level", "minLevel", "side", "races", "classes", "requires", "startNPCs", "startObjects",
        "startItems", "finishNPCs", "finishObjects", "objectives", "next", "rewardMoney", "rewardXP", "rewardItems",
        "rewardChoices", "rewardSpell", "tags", "groupSize" }
    local SIDED = "list tuple(npc:int,side:text)"
    local QUEST_TYPES = { "text", "int", "int", "text", "list int", "list int", "list tuple(kind:text,quest:int,side:text)",
        SIDED, "list tuple(object:int,side:text)", "list int", SIDED, "list tuple(object:int,side:text)",
        "list tuple(index:int,kind:text,what:int,count:int,text:text,stage:int)", "int", "int", "int",
        "list tuple(item:int,count:int)", "list tuple(item:int,count:int)", "int", "list text", "int" }
    local QUEST_PLAY = { "name", "level", "minLevel?", "side?", "races?", "classes?", "requires?", "startNPCs.npc",
        "startObjects.object", "startItems[]", "finishNPCs.npc", "finishObjects.object", "objectives", "next?",
        "rewardMoney", "rewardXP", "rewardItems", "rewardChoices", "rewardSpell", "tags[]?", "groupSize?" }
    -- A quest's row: its fields by name, in the set's order (\030 between a list's elements, \031 between parts)
    local function Row(values)
        local out = {}
        for index, field in ipairs(QUEST_FIELDS) do out[index] = values[field] or "" end
        return table.concat(out, "\t")
    end
    W.AddSets(MakeSets("Play", {
        ["Quests.lua"] = SetText("Quests", "00000030", QUEST_FIELDS, QUEST_TYPES, QUEST_PLAY, {
            [77] = Row({ name = "Wolves", level = "5", minLevel = "3", side = "alliance", requires = "done\03176", startNPCs = "69",
                         finishNPCs = "69", objectives = "1\031kill\03170\0318\031Wolf slain", rewardXP = "450" }),
            [79] = Row({ name = "Boars", level = "10", minLevel = "8", side = "horde", races = "2",
                         requires = "done\03150\030closed\03151" }),
            [80] = Row({ name = "Hides", level = "7", startNPCs = "69", finishNPCs = "69", rewardXP = "200",
                         objectives = "1\031loot\0312001\0314\031Wolf Hide" }),
            -- A giver's chain and its other quests (card #592): one, the next after it, one besides, one for later
            [95] = Row({ name = "Chain One", level = "3", side = "alliance", startNPCs = "73", finishNPCs = "73" }),
            [96] = Row({ name = "Chain Two", level = "4", side = "alliance", requires = "done\03195", startNPCs = "73" }),
            [97] = Row({ name = "Besides", level = "4", side = "alliance", startNPCs = "73" }),
            [98] = Row({ name = "Not Yet", level = "4", side = "alliance", requires = "done\03199", startNPCs = "73" }),
        }, "77\03079\03080") .. 'S.index.byStartNPC = { [73] = "95\03096\03097\03098" }\n',
        ["Vendors.lua"] = SetText("Vendors", "00000031", { "goods" }, { "list tuple(item:int,price:int)" }, { "goods.item" },
            { [69] = "2010\03150" }, "69"),
        ["Spells.lua"] = SetText("Spells", "00000032", { "name", "rank", "icon" }, { "text", "text", "int" }, { "name", "rank", "icon" },
            { [8613] = "Skinning", [133] = "Fireball\tRank 1\t135812" }, "133"),
    }))
    for _ = 1, 3 do Frame() end
    local Quests, Vendors, Spells, NPCs, Spawns = Data.Set("Quests"), Data.Set("Vendors"), Data.Set("Spells"), Data.Set("NPCs"), Data.Set("Spawns")
    check(Quests:Ready() and Quests:PlayFields()[1] == "name" and Quests:HasField("rewardXP") and not Quests:HasField("nothing"),
        "a set's play list comes with its file: how play tells each field")

    -- The stand-in's world: the map (1000 yards square), the units, the quest window and log
    local guids, names, levels, dead, players = { player = "Player-70-0000ABCD" }, {}, {}, {}, {}
    local here = { map = 1430, x = 0.25, y = 0.40 }
    C_Map = { GetBestMapForUnit = function() return here and here.map end,
        GetPlayerMapPosition = function(map) if here and here.map == map then return { GetXY = function() return here.x, here.y end } end end,
        GetMapWorldSize = function() return 1000, 1000 end }
    UnitGUID = function(unit) return guids[unit] end
    UnitName = function(unit) if unit == "player" then return "Tester", "Stub" end return names[unit] end
    UnitIsPlayer = function(unit) return unit == "player" or players[unit] == true end
    UnitIsDead = function(unit) return dead[unit] or false end
    UnitLevel = function(unit) if unit == "player" then return W.level end return levels[unit] end
    UnitRace = function() return "Human", "Human", 1 end
    UnitClass = function() return "Mage", "MAGE", 8 end
    UnitFactionGroup = function() return "Alliance" end
    GetMaxPlayerLevel = function() return 60 end
    IsInInstance = function() return false end
    W.level = 4
    local function Npc(id) return ("Creature-0-1-2-3-%d-0000%04X"):format(id, id) end
    local window = {}       -- the quest window: { quest, title, rewards = { {item, count} }, choices, xp, money }
    local completed = {}    -- [quest] = true: done once
    local log = {}          -- the quest log: { { info = {...}, objectives = {...} } }
    GetQuestID = function() return window.quest end
    GetTitleText = function() return window.title end
    GetNumQuestRewards = function() return #(window.rewards or {}) end
    GetNumQuestChoices = function() return #(window.choices or {}) end
    GetQuestItemInfo = function(kind, index)
        local item = (kind == "reward" and window.rewards or window.choices)[index]
        return "An Item", 134000, item.count, 2, true, item.item
    end
    GetRewardXP = function() return window.xp or 0 end
    GetRewardMoney = function() return window.money or 0 end
    C_QuestInfoSystem = { GetQuestRewardSpells = function() return {} end }
    C_QuestLog = {
        GetLogIndexForQuestID = function(quest) for index, entry in ipairs(log) do if entry.info.questID == quest then return index end end end,
        GetInfo = function(index) return log[index] and log[index].info end,
        GetQuestObjectives = function(quest) for _, entry in ipairs(log) do if entry.info.questID == quest then return entry.objectives end end end,
        GetNumQuestLogEntries = function() return #log end,
        IsQuestFlaggedCompleted = function(quest) return completed[quest] == true end,
    }
    local function Offer(quest, title, giver, extra)
        window = extra or {}
        window.quest, window.title = quest, title
        guids.npc = giver
        W.Fire("QUEST_DETAIL")
    end
    local function Take(quest, title, level, objectives)
        log[#log + 1] = { info = { questID = quest, title = title, level = level, suggestedGroup = 0, isHeader = false },
            objectives = objectives }
        W.Fire("QUEST_ACCEPTED", quest)
        W.Wait(0)
    end
    local function Told(name, key)
        local told = {}
        for _, part in ipairs(Data.ConfirmedParts(name, key)) do told[part] = true end
        return told
    end

    -- A quest our data has, offered by its giver: what agrees confirmed, the rewards it lacks learned
    completed[76] = true
    Offer(77, "Wolves", Npc(69), { rewards = { { item = 2000, count = 1 } }, xp = 450 })
    local wolves, told = Quests:Get(77), Told("Quests", 77)
    check(wolves and wolves.rewardItems and wolves.rewardItems[1].item == 2000 and Data.Learned("Quests", 77)
        and wolves.objectives[1].what == 70 and wolves.requires[1].quest == 76,
        "a quest offered with rewards the set lacks: learned, the set's other facts carried along")
    check(told.name and told["startNPCs=69"] and told.rewardItems and told.rewardXP and told.rewardMoney and not told.objectives
        and not told.requires, "and what the game told kept with it, so the harvest takes only that")
    -- Taken: the log's level and objectives
    Take(77, "Wolves", 5, { { text = "Wolf slain: 0/8", type = "monster", numRequired = 8, numFulfilled = 0, finished = false } })
    told = Told("Quests", 77)
    check(told.level and told.objectives and Quests:Get(77).objectives[1].text == "Wolf slain",
        "taken: its level and objectives as the log lists them (the count's numbers left out)")

    -- A quest whose every fact the game confirms while it is done: confirmed field by field, then whole
    Offer(80, "Hides", Npc(69), { xp = 200 })
    check(Quests:Unverified(80) and not Quests:Unverified(80, "name") and not Quests:Unverified(80, "startNPCs=69")
        and not Data.Learned("Quests", 80), "offered as our data has it: its fields confirmed, the entry not yet whole")
    Take(80, "Hides", 7, { { text = "Wolf Hide: 0/4", type = "item", numRequired = 4, numFulfilled = 0, finished = false } })
    check(Quests:Unverified(80), "taken: still its taker to see")
    window = { quest = 80 }
    guids.npc = Npc(69)
    W.Fire("QUEST_COMPLETE")
    check(not Quests:Unverified(80), "handed in to its taker: every field the game can tell told, the whole quest confirmed")

    -- An offer proves requirements wrong: a lower level, another race and side, a quest not done first
    completed[51] = false
    Offer(79, "Boars", Npc(69))
    local boars = Quests:Get(79)
    check(boars.minLevel == 4 and boars.side == nil and boars.races[2] == 1 and #boars.requires == 1
        and boars.requires[1].kind == "closed", "offered at level 4, to a human of the Alliance, without quest 50 done: narrowed")
    -- A quest another player shares says nothing of who gives it or what it needs
    players.npc = true
    Offer(78, "Shared", "Player-70-00001234")
    players.npc = nil
    check(Quests:Get(78) and not Quests:Get(78).startNPCs and not Quests:Get(78).minLevel,
        "a quest shared by a player: learned by its title, no giver, nothing narrowed")

    -- A quest only Forever has: learned whole as it is done
    Offer(90, "Rats", Npc(71), { rewards = {}, xp = 300, money = 120 })
    Take(90, "Rats", 6, { { text = "Sewer Rat slain: 0/5", type = "monster", numRequired = 5, numFulfilled = 0, finished = false } })
    -- a rat killed: the count goes up with the dead rat targeted
    guids.target, names.target, dead.target = Npc(72), "Sewer Rat", true
    log[#log].objectives[1].numFulfilled = 1
    W.Fire("QUEST_WATCH_UPDATE", 90)
    W.Wait(1)
    local rats = Quests:Get(90)
    check(rats and rats.name == "Rats" and rats.startNPCs[1].npc == 71 and rats.level == 6 and rats.rewardXP == 300
        and rats.rewardMoney == 120 and rats.objectives[1].kind == "kill" and rats.objectives[1].what == 72
        and rats.objectives[1].count == 5, "a quest the set lacks: its giver, level, rewards and objectives, the creature it asks for")
    local cell = Tally.Of("cells", "quest:90/1")
    check(cell and cell[1][1] == 1430 and cell[1][2] == 4025 and cell[1][3] == 1, "where its count went up: a cell of the map")
    guids.target, names.target, dead.target = nil, nil, nil
    -- handed in, then the next of its chain offered by the same NPC at once
    window = { quest = 90 }
    guids.npc = Npc(71)
    W.Fire("QUEST_COMPLETE")
    W.Fire("QUEST_TURNED_IN", 90, 300, 120)
    Offer(91, "More Rats", Npc(71))
    check(Quests:Get(90).finishNPCs[1].npc == 71 and Quests:Get(90).next == 91, "handed in to its taker; the quest it led to is its next")
    W.Wait(1)
    W.Fire("QUEST_TURNED_IN", 91, 0, 0)
    W.Wait(1)
    W.Fire("GOSSIP_SHOW")
    Offer(92, "Other", Npc(71))
    check(Quests:Get(91).next == nil, "a quest offered after the NPC's list: no chain")

    -- The next of a chain offered the moment the one before is handed in, the game not yet flagging that one done: its
    -- need of it stays (Core 0.3.7 took it away, and its giver showed an offer to those who had not done the first)
    local QuestWatch = Data.QuestWatch
    SaneUICharDB = SaneUICharDB or {}
    local gossip = {}
    C_GossipInfo = { GetAvailableQuests = function() return gossip end }
    W.Wait(5)
    window = { quest = 95 }
    guids.npc = Npc(73)
    W.Fire("QUEST_COMPLETE")
    W.Fire("QUEST_TURNED_IN", 95, 0, 0)
    Offer(96, "Chain Two", Npc(73))
    local two = Quests:Get(96)
    check(two.requires and two.requires[1].kind == "done" and two.requires[1].quest == 95,
        "the next of a chain offered right after the hand-in: the quest before stays its need")
    check(QuestWatch.Listed("npc:73") == nil, "a quest offered right after a hand-in says nothing of what the giver offers")
    -- The giver's list: what it offers this character now; what the data let it take but the game did not list, withheld
    W.Wait(5)
    gossip = { { questID = 97 } }
    local heard = 0
    QuestWatch.OnListed(function(thing) if thing == "npc:73" then heard = heard + 1 end end)
    W.Fire("GOSSIP_SHOW")
    local listed, withheld = QuestWatch.Listed("npc:73")
    check(listed and listed[97] and not listed[96] and withheld[96] and not withheld[98] and not withheld[95] and heard == 1,
        "the giver's list kept: the quest it lists, the one the data let you take that it did not list withheld; not the one "
        .. "for later, nor the one done")
    local function Offers(quest)
        for _, record in ipairs(Tally.Of("offers", "npc:73") or {}) do
            if record[1] == quest then return record[2], record[3], record[4] end
        end
        return 0, 0, 0
    end
    local agreed = Offers(97)
    local _, held = Offers(96)
    check(agreed == 1 and held == 1, "counted for the harvest (no character in it): 97 listed as the data has it, 96 withheld")
    W.Fire("GOSSIP_SHOW")
    check(heard == 1 and Offers(97) == 1, "the same list again: nothing told, nothing counted twice")
    W.level = 5
    check(QuestWatch.Listed("npc:73") == nil, "at another level: no word of the giver's any more")
    W.level = 4
    check(QuestWatch.Listed("npc:73") ~= nil, "back at that level the same day: its word again")
    -- A quest opened at once, with no list just before: all the giver offers; a quest to hand in opened at once: none
    W.Wait(5)
    Offer(97, "Besides", Npc(73))
    listed, withheld = QuestWatch.Listed("npc:73")
    check(listed[97] and withheld[96] and heard == 1, "a quest opened at once: the list it was already")
    W.Wait(5)
    window = { quest = 96 }
    guids.npc = Npc(73)
    W.Fire("QUEST_PROGRESS")
    listed, withheld = QuestWatch.Listed("npc:73")
    check(listed and not listed[97] and withheld[97] and heard == 2,
        "a quest to hand in opened at once: the giver offers nothing, every quest the data let you take withheld")
    local _, heldNow = Offers(97)
    check(heldNow == 1, "and 97 counted withheld once")
    gossip = {}
    SaneUICharDB.offers = nil
    -- The needs the views trust: a quest's row narrowed in play keeps the quests to do first the shipped row has
    local trusted = QuestWatch.Requires(Quests:Get(79), 79)
    local first
    for _, rule in ipairs(trusted or {}) do if rule.kind == "done" and rule.quest == 50 then first = true end end
    check(#Quests:Get(79).requires == 1 and first, "a row the game narrowed: the quest to do first as the shipped data has it")

    -- Loot: each corpse once, from the game's source per slot; a quest's item counted for those on it
    local slots, fishing = {}, false -- { item, name, count, sources = { guid, count, ... } }
    GetNumLootItems = function() return #slots end
    GetLootSlotLink = function(slot) return slots[slot].item and ("|Hitem:%d::|h[x]|h"):format(slots[slot].item) end
    GetLootSlotInfo = function(slot) return 134000, slots[slot].name, slots[slot].count or 1 end
    GetLootSourceInfo = function(slot) return unpack(slots[slot].sources) end
    IsFishingLoot = function() return fishing end
    local function Of(key)
        local out = {}
        for _, record in ipairs(Tally.Of("drops", key) or {}) do
            local size = record[1] == "d" and 4 or record[1] == "c" and 3 or 2
            out[table.concat(record, ",", 1, size)] = record[size + 1]
        end
        return out
    end
    local A, B, C, D = Npc(70):gsub("0046$", "000A"), Npc(70):gsub("0046$", "000B"), Npc(70):gsub("0046$", "000C"), Npc(70):gsub("0046$", "000D")
    slots = { { item = 2001, name = "Wolf Hide", sources = { A, 1 } }, { sources = { A, 0 } } }
    W.Fire("LOOT_OPENED", false, false)
    local wolf = Of("npc:70")
    check(wolf["c,loot,0"] == 1 and wolf["c,loot,80"] == 1 and wolf["d,loot,2001,80"] == 1,
        "a corpse looted: one loot, one for quest 80 too (its item not yet all gathered), the hide counted for those on it")
    W.Fire("LOOT_OPENED", false, false)
    check(Of("npc:70")["c,loot,0"] == 1, "the same window opened again: nothing counted twice")
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 8613)
    slots = { { item = 2002, name = "Light Leather", sources = { A, 1 } } }
    W.Fire("LOOT_OPENED", false, false)
    check(Of("npc:70")["c,skin,0"] == 1 and Of("npc:70")["d,skin,2002,0"] == 1, "skinned after the cast: a loot of its own way")
    W.Wait(5)
    slots = { { item = 2003, name = "Wolf Fang", count = 3, sources = { B, 1, C, 2 } } }
    W.Fire("LOOT_OPENED", false, false)
    wolf = Of("npc:70")
    check(wolf["c,loot,0"] == 3 and wolf["d,loot,2003,0"] == 2, "two corpses looted together: two loots, the fang from each")
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 921)
    slots = { { item = 2004, name = "Coin", sources = { D, 1 } } }
    W.Fire("LOOT_OPENED", false, false)
    W.Wait(5)
    slots = { { item = 2003, name = "Wolf Fang", sources = { D, 1 } } }
    W.Fire("LOOT_OPENED", false, false)
    wolf = Of("npc:70")
    check(wolf["c,pickpocket,0"] == 1 and wolf["d,pickpocket,2004,0"] == 1 and wolf["c,loot,0"] == 4,
        "a pocket picked, then its corpse looted: one of each")
    local cells = Tally.Of("cells", "npc:70")
    check(cells and cells[1][2] == 4025 and cells[1][3] == 4, "where each corpse was looted: its cell")
    -- a herb gathered (the set Objects calls it one): a gather, and where it stands
    local node = "GameObject-0-1-2-3-1617-00000001"
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3", 2366)
    slots = { { item = 765, name = "Silverleaf", count = 2, sources = { node, 2 } } }
    W.Fire("LOOT_OPENED", false, false)
    W.Fire("LOOT_OPENED", false, false)
    local point = Tally.Of("points", "object:1617")
    check(Of("object:1617")["c,gather,0"] == 1 and Of("object:1617")["d,gather,765,0"] == 1 and point and point[1][1] == 1430
        and point[1][2] == 25 and point[1][3] == 40 and point[1][4] == 1, "a node gathered: once, its place seen")
    -- fishing: for the zone; a container from the bags: nothing; a client without sources: nothing
    fishing = true
    slots = { { item = 6303, name = "Raw Trout", sources = {} } }
    W.Fire("LOOT_OPENED", false, false)
    fishing = false
    check(Of("zone:1430")["c,fish,0"] == 1 and Of("zone:1430")["d,fish,6303,0"] == 1, "fished: for the zone")
    slots = { { item = 2005, sources = { Npc(73), 1 } } }
    W.Fire("LOOT_OPENED", false, true)
    local source = GetLootSourceInfo
    GetLootSourceInfo = nil
    W.Fire("LOOT_OPENED", false, false)
    GetLootSourceInfo = source
    check(not Tally.Of("drops", "npc:73") and Loot.blind == nil, "from the bags, or with no source per slot: nothing counted (and no field says so: /sane data asks the game)")

    -- Places seen: merged by yards, one visit at a time
    check(Tally.Point("npc:500", 1430, 50, 50) and not Tally.Point("npc:500", 1430, 50.2, 50), "seen twice at once: one visit")
    W.Wait(Tally.VISIT + 1)
    Tally.Point("npc:500", 1430, 50.3, 50)
    Tally.Point("npc:500", 1430, 60, 60)
    Tally.Point("npc:500", 1431, 50, 50)
    local seen = Tally.Of("points", "npc:500")
    check(#seen == 3 and seen[1][4] == 2 and seen[1][2] == 50.15 and seen[2][4] == 1 and seen[3][1] == 1431,
        "again later, 3 yards off: the same place, its point the mean; farther, or on another map: places of their own")
    check(not Tally.Cell("npc:500", 1430, 100, 5) and not Tally.Point("npc:5\0310", 1430, 1, 1), "off the map, or a key that breaks a row: refused")
    local part = SaneUIData_Learned.forever
    local _, block = next(part.tally)
    check(type(block.id) == "string" and #block.id == 16 and part.maps[1430] == "1000\0311000"
        and type(block.drops["npc:70"]) == "string", "kept packed per build, with a random id and the maps' sizes")

    -- Gathering: a vein of several gathers is one visit; a rare gem counts like any item, and stands out in the reader
    do
        local Drops, Found = Data.Drops(), Data.Discoveries
        local spellName = C_Spell and C_Spell.GetSpellName
        C_Spell = C_Spell or {}
        C_Spell.GetSpellName = function(id) return ({ [2366] = "Herb Gathering", [1235230] = "Mining" })[id] end
        W.AddSets(MakeSets("Yields", { ["Drops.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Drops", { game = "forever", hash = "00000033", build = 65000, key = "text", '
            .. 'fields = { "loots", "levelMin", "levelMax", "items" }, types = { "int", "int", "int", "list tuple(item:int,how:text,drops:int,chance:number,quest:int)" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows["object:1731"] = "65000\\t\\t\\t\\t\\t2770\\031gather\\031\\03195"\n'
            .. 'S.rows["object:7"] = "65000\\t\\t200\\t\\t\\t2775\\031gather\\03110\\0315\\0302776\\031\\031\\03112"\nS.unverified = "object:7"\n' }))
        for _ = 1, 3 do Frame() end
        local vein = "GameObject-0-1-2-3-1731-00000002"
        local function Mine(items)
            W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast", 1235230)
            slots = items
            W.Fire("LOOT_OPENED", false, false)
            W.Wait(5)
        end
        Mine({ { item = 2770, name = "Copper Ore", count = 2, sources = { vein, 2 } } })
        Mine({ { item = 2770, name = "Copper Ore", sources = { vein, 1 } }, { item = 774, name = "Malachite", sources = { vein, 1 } } })
        Mine({ { item = 2770, name = "Copper Ore", sources = { vein, 1 } }, { item = 818, name = "Tigerseye", sources = {} } })
        local mined = Of("object:1731")
        check(mined["c,gather,0"] == 3 and mined["v,gather"] == 1 and mined["d,gather,2770,0"] == 3,
            "a vein mined three times, by a cast the set does not hold yet (the game's name for it): three gathers, one visit")
        check(mined["d,gather,774,0"] == 1 and mined["d,gather,818,0"] == 1, "a gem counted with it, also from a slot the game names no source for")
        check(#Drops:Of("object:1731") == 3 and Drops:Knows("object:1731", "gather", 2770) and not Drops:Knows("object:1731", "gather", 774)
            and not Drops:Knows("object:1731", "skin", 2770) and Drops:Knows("object:7", "skin", 2776), "what the set lists, by way; a row with no way lists it for every way")

        -- The game names no source at all: the gather cast's target, by its name in the set Objects; never without the cast
        local source = GetLootSourceInfo
        GetLootSourceInfo = function() end
        slots = { { item = 765, name = "Silverleaf" } }
        local before = Of("object:1617")["c,gather,0"]
        W.Fire("UNIT_SPELLCAST_SENT", "player", "Peacebloom", "Cast", 2366)
        W.Fire("LOOT_OPENED", false, false)
        check(Of("object:1617")["c,gather,0"] == before, "aimed at it, but no gather cast went off: nothing counted")
        W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast", 2366)
        W.Fire("LOOT_OPENED", false, false)
        check(Of("object:1617")["c,gather,0"] == before + 1, "the cast that opened it: that node gathered")
        W.Wait(5)
        W.Fire("UNIT_SPELLCAST_SENT", "player", "A Strange Rock", "Cast", 2366)
        W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast", 2366)
        W.Fire("LOOT_OPENED", false, false)
        check(not Tally.Of("drops", "object:0"), "aimed at a name the set does not know: not guessed")
        GetLootSourceInfo = nil
        W.Wait(5)
        local count = Of("object:1617")["c,gather,0"]
        W.Fire("UNIT_SPELLCAST_SENT", "player", "Peacebloom", "Cast", 2366)
        W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast", 2366)
        W.Fire("LOOT_OPENED", false, false)
        check(Of("object:1617")["c,gather,0"] == count + 1, "a client with no sources at all: the aimed cast still counts")
        GetLootSourceInfo = source
        W.Wait(5)

        -- The reader: chances from Drops.SURE on, until then how many of how many; rare by how seldom it comes
        for index = 1, 60 do
            Tally.Loot("object:9", "gather", 0)
            Tally.Drop("object:9", "gather", 2770, 0, 2)
            if index <= 2 then Tally.Drop("object:9", "gather", 774, 0, 1) end
            if index % 3 == 0 then Tally.Visit("object:9", "gather") end
        end
        local list = Drops:Of("object:9")
        check(list[1].item == 2770 and list[1].chance == 100 and list[1].yield == 2 and list[1].perVisit == 6 and not list[1].rare
            and list.loots.gather == 60 and list.visits.gather == 20, "what a node gives: the chance per gather, the yield, a visit's worth")
        check(list[2].item == 774 and list[2].chance == nil and list[2].drops == 2 and list[2].loots == 60 and list[2].rare and #Drops:Rare("object:9") == 1,
            "a rare gem seen twice: counted and marked rare, given no chance yet")
        Tally.Loot("object:9", "gather", 0)
        Tally.Drop("object:9", "gather", 774, 0, 1)
        local chance, came, of = Drops:Chance("object:9", 774)
        check(Drops:Of("object:9") ~= list and came == 3 and of == 61 and math.abs(chance - 300 / 61) < 0.001, "a third: its chance, the answer made anew")
        check(not Drops:Chance("object:9", 99999), "an item it never gave: no chance")
        local from = Drops:From(774)
        check(#from == 2 and from[1].key == "object:1731" and from[2].key == "object:9" and from[2].how == "gather" and #Drops:From(99999) == 0,
            "who gives an item, the likeliest first")
        check(#Drops:Of("object:9", "period") == 2, "this build period alone")
        local shipped = Drops:Of("object:7")
        check(#shipped == 2 and shipped[1].item == 2776 and shipped[1].chance == 12 and shipped[1].shipped and shipped[2].chance == 5 and shipped[2].rare
            and shipped[2].loots == 200 and shipped[1].doubt, "what only the set lists: its chance, marked, and not yet confirmed where the set says so")
        local firstHalf = Drops:Of("object:1731")
        check(firstHalf[1].item == 2770 and firstHalf[1].chance == 95 and firstHalf[1].listed and not firstHalf[1].doubt,
            "below enough loots the set's own chance stands over a few gathers, and says so")
        W.printed = {}
        SlashCmdList.SANEUI("data gathered")
        check(printedMatch("object:9: 61 gathered in 20 visits%. Rare: item 774 4%.9%% %(3 of 61%)"), "/sane data gathered: how often, in how many visits, what came seldom")
        W.printed = {}
        SlashCmdList.SANEUI("data")
        check(printedMatch("gathered and skinned, counted in play: %d+ kinds, %d+ rare drops"), "/sane data says so too")

        -- Discoveries: a drop no data listed; a change Data.Check took; the chat line only when switched on
        local function Listed(what, key)
            for _, entry in ipairs(Data.Found()) do
                if entry.what == what and entry.key == key then return entry end
            end
        end
        local drop = Listed("drop", "object:1731")
        check(drop and drop.set == "Drops" and drop.how == "watcher" and drop.day == math.floor(GetServerTime() / 86400) and drop.build == W.build
            and (drop.parts[1] == "gather=774" or drop.parts[1] == "gather=818"), "an item no data listed for that way: a discovery, of the game not the player")
        local drops = 0
        for _, entry in ipairs(Data.Found()) do
            if entry.key == "object:1731" and entry.parts[1] == "gather=2770" then drops = drops + 1 end
        end
        check(drops == 0, "what the data lists is none")
        W.printed = {}
        check(Data.Discovered("Quests", 801, "new", { "name" }) and #W.printed == 0 and Listed("new", 801).parts[1] == "name", "kept; no line while the switch is off")
        Core.general.chatData = true
        W.Wait(0)
        check(Data.Discovered("Quests", 802, "new") and printedMatch("data: .*new quest") and printedMatch("%[Details%]"), "switched on: the first at once, summed up")
        W.printed = {}
        Data.Discovered("Vendors", 69, "changed", { "goods=1" })
        check(#W.printed == 0, "the next waits")
        W.Wait(Found.GAP + 1)
        check(printedMatch("data: 1 changed vendor"), "then all that came meanwhile, in one line")
        W.printed = {}
        W.Wait(Found.GAP + 1)
        check(#W.printed == 0, "with nothing new, no line")
        W.combat = true
        Data.Discovered("Quests", 803, "new")
        check(#W.printed == 0, "never in a fight")
        W.combat = false
        W.Fire("PLAYER_REGEN_ENABLED")
        check(printedMatch("data: 1 new quest"), "after it")
        W.printed = {}
        W.Wait(Found.GAP + 1)
        W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 2)
        Data.Discovered("Quests", 804, "new")
        check(#W.printed == 0, "nor while the game restricts addons, with no fight on")
        W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 0)
        check(printedMatch("data: 1 new quest"), "once the restriction is lifted: no fight's end needed")
        Core.general.chatData = nil
        W.printed = {}
        W.Wait(Found.GAP + 1)
        Found.Prices(12)
        check(#W.printed == 0, "the auction line has its own switch")
        Core.general.chatPrices = true
        Found.Prices(3)
        check(printedMatch("auction prices: 15 moved"), "and tells what moved")
        Core.general.chatPrices = nil
        W.printed = {}
        EventRegistry:TriggerEvent("SetItemRef", "addon:SaneUI:data", "[Details]", "LeftButton")
        check(printedMatch("new Quests 803"), "[Details]: the newest discoveries")
        W.printed = {}
        SlashCmdList.SANEUI("data found")
        check(printedMatch("changed Vendors") and #W.printed == Found.SHOWN or #W.printed == #Data.Found(), "/sane data found prints them too")
        check(#Data.Found(math.floor(GetServerTime() / 86400) + 1) == 0, "from a day on")
        C_Spell.GetSpellName = spellName
    end

    -- Spawns: the point stood at confirmed, the whole once every point is
    here = { map = 1431, x = 0.105, y = 0.10 }
    guids.mouseover = Npc(71)
    W.Fire("UPDATE_MOUSEOVER_UNIT")
    local first, second = Watchers.Code({ map = 1431, x = 10, y = 10 }), Watchers.Code({ map = 1431, x = 80, y = 80 })
    check(first == "p1433963631", "a spawn point's part: its map and place to a tenth (the harvest makes the same)")
    local okHigh, high = pcall(Watchers.Code, { map = 2521, x = 42.5, y = 23.8 })
    check(okHigh and high == "p2526470184", "a map above 2143: its code past 32 bits, written whole (the game's %d refuses it)")
    check(not Spawns:Unverified("npc:71", first) and Spawns:Unverified("npc:71", second) and Spawns:Unverified("npc:71"),
        "a creature of two spawn points seen at one: that point confirmed, not the other, nor the whole")
    here = { map = 1431, x = 0.80, y = 0.805 }
    W.Wait(Watchers.AGAIN + 1)
    W.Fire("UPDATE_MOUSEOVER_UNIT")
    check(not Spawns:Unverified("npc:71"), "seen at the other too: the whole spawn confirmed")
    here = { map = 1430, x = 0.25, y = 0.40 }

    -- Creatures: what the game shows learned or confirmed; a level outside the set's widens it
    guids.mouseover, names.mouseover, levels.mouseover = Npc(300), "Ogre Mauler", 12
    UnitClassification = function() return "elite" end
    UnitCreatureType = function() return "Giant" end
    UnitHealthMax = function() return 1500 end
    UnitPlayerControlled = function() return false end
    W.Fire("UPDATE_MOUSEOVER_UNIT")
    local ogre = NPCs:Get(300)
    check(ogre and ogre.name == "Ogre Mauler" and ogre.levelMin == 12 and ogre.levelMax == 12 and ogre.rank == "elite"
        and ogre.kind == "giant" and ogre.health[12] == 1500, "a creature the set lacks, seen: learned as the game shows it")
    levels.mouseover = 13
    UnitHealthMax = function() return 1600 end
    W.Fire("UPDATE_MOUSEOVER_UNIT")
    ogre = NPCs:Get(300)
    check(ogre.levelMin == 12 and ogre.levelMax == 13 and ogre.health[12] == 1500 and ogre.health[13] == 1600,
        "seen at another level: the highest widened, its health at that level added")
    W.Fire("UPDATE_MOUSEOVER_UNIT")
    UnitPlayerControlled = function() return true end
    guids.mouseover, levels.mouseover = Npc(301), 20
    W.Fire("UPDATE_MOUSEOVER_UNIT")
    UnitPlayerControlled = function() return false end
    check(not NPCs:Get(301), "a creature a player controls (a pet, a totem): not looked at")
    -- A vendor's goods: an item the set lacks added, none taken away
    local goods = { 2010, 2011 }
    GetMerchantNumItems = function() return #goods end
    GetMerchantItemID = function(index) return goods[index] end
    CanMerchantRepair = function() return true end
    guids.npc = Npc(69)
    W.Fire("MERCHANT_SHOW")
    W.Wait(1)
    local wares = Vendors:Get(69)
    check(wares and #wares.goods == 2 and wares.goods[1].price == 50 and wares.goods[2].item == 2011 and Told("Vendors", 69)["goods=2010"],
        "a vendor's window: the good the set lacks added, the price the set has kept")
    -- Spells: name, rank, icon; all three as the set has them confirm the spell
    C_Spell = { GetSpellName = function(id) return ({ [133] = "Fireball", [134] = "Frost Nova" })[id] end,
        GetSpellSubtext = function(id) return id == 133 and "Rank 1" or "" end,
        GetSpellTexture = function(id) return id == 133 and 135812 or 135848 end }
    Data.Facts.Spell(133)
    Data.Facts.Spell(134)
    check(not Spells:Unverified(133) and Spells:Get(134) and Spells:Get(134).name == "Frost Nova" and Spells:Get(134).icon == 135848,
        "a spell as the set has it: confirmed whole; one it lacks: learned")

    -- Check alone: a field the game shows empty, a field the set has not
    check(Data.Check("Quests", 79, { groupSize = Checks.NONE, nothing = 1 }) and Told("Quests", 79).groupSize,
        "the game shows a field empty and the set has none: told, agreeing; a field the set has not: passed over")
    check(not Data.Check("Nowhere", 1, { name = "x" }), "a set that is not there: nothing")
end

-------------------------------------------------------------------------------
--  The trip underway (Trips.lua): nothing hooked or looked at before a module asks for the trips
-------------------------------------------------------------------------------
do
    local take = function() end
    TakeTaxiNode = take
    W.Fire("PLAYER_ENTERING_WORLD")
    for _ = 1, 3 do W.Wait(1) end
    check(TakeTaxiNode == take, "the world there, but no module asked for the trips: the flight master is not hooked")
    check(Data.Trips() and TakeTaxiNode ~= take, "a module asks for them: hooked at once, the world being there")
end

-------------------------------------------------------------------------------
--  The full scan of the auction house (Scan.lua, ScanBar.lua)
-------------------------------------------------------------------------------
do
    local Scan = Data.Scan
    -- The file of its own: its part is there once its addon has loaded, after Core
    check(rawget(_G, "SaneUIData_Market") == nil, "the auction data is no part of Core's saved file")
    W.Fire("AUCTION_HOUSE_SHOW")
    check(Scan.State().phase == "closed", "without its addon (switched off) nothing is scanned")
    W.Fire("ADDON_LOADED", "SaneUI_AuctionData")
    check(SaneUIData_Market.forever.format == 1, "its addon loaded: the part of this game version, as any saved variable of the data")
    local rows, asks, requested, known, rowCost = {}, 0, {}, {}, 0
    local function Plain(item, count, buyout, owner) return { item = item, count = count, buyout = buyout, owner = owner } end
    C_AuctionHouse = {
        ReplicateItems = function() asks = asks + 1 end,
        IsThrottledMessageSystemReady = function() return true end,
        GetNumReplicateItems = function() return #rows end,
        GetReplicateItemLink = function(index) return rows[index + 1] and rows[index + 1].link end,
        GetReplicateItemTimeLeft = function() return 2 end,
        GetReplicateItemInfo = function(index)
            local row = rows[index + 1]
            W.ms = W.ms + rowCost
            if not row then return end
            return "name", 1, row.count, 1, true, 1, "", row.minBid or 1, 1, row.buyout, 0, nil, nil, row.owner, nil, 0, row.item, true
        end,
    }
    -- Packed so that a test can read it: rows on one line, a block's rows cut by tabs.
    local encoding = rawget(_G, "C_EncodingUtil")
    C_EncodingUtil = { CompressString = function(text) return text end,
        EncodeBase64 = function(text) return (text:gsub("\n", "\t")) end }
    local items = C_Item
    C_Item = setmetatable({
        GetItemInfoInstant = function(item)
            if item == 666 then return nil end
            return item, "", "", "", 1, (item == 50 or item == 51) and 2 or item == 82800 and 17 or 7, 0
        end,
        GetDetailedItemLevelInfo = function(link)
            local item = tonumber(link:match("item:(%d+)"))
            return known[item] and 60 or nil
        end,
        RequestLoadItemDataByID = function(item) requested[#requested + 1] = item end,
    }, { __index = items })
    -- The bar's motion stands still: the test reads its words.
    local function noop() end
    W.methods.CreateAnimationGroup = function()
        return setmetatable({ CreateAnimation = function() return setmetatable({}, { __index = function() return noop end }) end },
            { __index = function() return noop end })
    end
    AuctionHouseFrame = CreateFrame("Frame", "AuctionHouseFrame", UIParent)
    AuctionHouseFrame:Show()
    GetCurrentRegionName = function() return "EU" end
    GetRealmID = function() return 1234 end
    local key = "eu/1234/alliance"
    local state = Scan.State()
    local saved = function() return SaneUIData_Market.forever.houses[key] end
    -- This account's scans kept whole, in the file of their own, loaded when the auction house opens.
    local function Scanned() return SaneUIData_Scans.forever.houses[key] end
    -- What an account's file leaves when its link runs: for a moment the global is that account's.
    local function Account(houses, game)
        local own = rawget(_G, "SaneUIData_Market")
        SaneUIData_Market = { [game or "forever"] = { houses = houses } }
        Data.Series("Prices").Account()
        local left = rawget(_G, "SaneUIData_Market")
        SaneUIData_Market = own
        return left
    end
    local function Accounts(houses, game)
        Data.Series("Prices").Clear()
        return Account(houses, game)
    end
    local function Read()
        for _ = 1, 200 do
            Frame()
            if state.phase ~= "reading" then return end
        end
    end
    local function Today() return math.floor(GetServerTime() / 86400) end
    -- The bar on the game's window, anchored to it, and its words.
    local function Strip()
        for _, widget in ipairs(W.frames) do
            local strip = widget._kind == "FontString" and widget._parent and widget._parent._parent
            if strip and strip._points[1] and strip._points[1][2] == AuctionHouseFrame then return strip, widget:GetText() end
        end
    end
    local function Line(text, item)
        return ("%s"):format(text):match("%f[%d]" .. item:gsub("%p", "%%%0") .. "=[^;]*;")
    end

    rows = { Plain(10, 5, 500, "Ann"), Plain(10, 5, 1500, "Bob"), Plain(10, 10, 2000, "Ann"), Plain(20, 1, 0, "Cid"),
        Plain(666, 1, 100, "Dee"), Plain(30, 0, 100, "Eve") }
    check(state.phase == "closed", "no auction house open: nothing runs")
    check(rawget(_G, "SaneUIData_Scans") == nil, "a login reads no whole scan")
    local loaded = C_AddOns.LoadAddOn
    C_AddOns.LoadAddOn = function(name) W.Fire("ADDON_LOADED", name) end
    W.Fire("AUCTION_HOUSE_SHOW")
    C_AddOns.LoadAddOn = loaded
    check(type(SaneUIData_Scans) == "table" and SaneUIData_Scans.forever.format == 1, "the auction house opens: their file is read, as this account will add to it")
    check(state.phase == "waiting" and asks == 0, "the auction house opens: the window gets a moment for its own first searches")
    check(select(2, Strip()):find("Next full scan in 0:00", 1, true), "the bar under the game's window says so")
    W.Wait(Scan.SETTLE + Scan.TICK)
    check(state.phase == "asking" and asks == 1, "then the full scan is asked for, with no click")
    check(select(2, Strip()):find("Full scan started", 1, true), "the bar says it started")
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    check(state.phase == "reading" and state.rows == 6, "the server answers: the rows are read")
    check(select(2, Strip()) == "Full scan: 0 of 6 auctions", "the bar says how far it is")
    local answered = GetServerTime()
    check(state.next == answered + Scan.INTERVAL and saved().at == answered, "the next scan counts from the answer")
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    check(asks == 1 and state.phase == "reading", "told again while it reads: nothing new")
    Read()
    check(state.phase == "waiting" and state.outcome == "kept" and state.total == 6 and state.items == 2,
        "the scan is kept: the rows, the items in them")
    check(select(2, Strip()):find("^Full scan finished at .*: 6 auctions%. Next in 1[56]:%d%d$"), "the bar says it finished, and when the next comes: " .. select(2, Strip()))
    local day = Today()
    local text = saved().days[day]
    check(Line(text, "10") == "10=100,200,20,3,2;", "an item: the lowest, the median of its units, units, auctions, sellers: " .. text)
    check(Line(text, "20") == "20=0,0,1,1,1;", "bid only: counted, no price")
    check(not text:find("666=") and not text:find("30="), "an item the game does not know and a row of nothing are left out")
    check(saved().scans[day] == 1 and SaneUIData_Market.forever.format == 1, "one scan that day, in the saved variable of this game version")
    local whole = Scanned()[answered]
    local build = whole and whole:match("^(%d+)\n")
    check(build and whole:find("10,5,500,1,1,0,2,0,Ann,,", 1, true) and whole:find("20,1,0,1,1,0,2,0,Cid,,", 1, true) and not whole:find("666,", 1, true),
        "Forever keeps the scan whole: every row of it, with its build, a seller's name beside it: " .. tostring(whole))
    local Prices = Data.Series("Prices")
    local low, market, units, auctions, sellers, at = Prices:Last(10)
    check(low == 100 and market == 200 and units == 20 and auctions == 3 and sellers == 2 and at == answered and Prices:Low(10) == 100,
        "every view reads the scan's point of an item, by its ID")
    check(Prices:Low(20) == nil and Prices:Last(20) == 0 and Prices:Low(9999) == nil, "bid only is no price; what no scan saw has none")
    check(saved().index:find("10=" .. answered .. ",100,200,20,3,2;", 1, true), "the newest points stand in the saved file")
    check(saved().recent[answered]:find("10=100,200;", 1, true) and not saved().recent[answered]:find("666=", 1, true),
        "the scan as a line per item beside it, for a graph of a day")
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    Read()
    check(saved().scans[day] == 1, "told again after it was kept: the same scan, read once")

    -- Every 16 minutes while it stays open; the day's second scan
    rows = { Plain(10, 2, 400, "Fay"), Plain(40, 1, 70, "Gus") }
    W.Wait(Scan.INTERVAL - 3)
    check(asks == 1 and state.phase == "waiting", "the 16 minutes are not up: no request")
    W.Wait(4)
    check(asks == 2 and state.phase == "asking", "16 minutes after the answer: the next scan, by itself")
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    Read()
    local same = Today() == day
    text = saved().days[Today()]
    if same then
        check(Line(text, "10") == "10=100,200,2,1,1;", "a second scan that day: the day's lowest stays, the rest is the last scan's: " .. text)
        check(Line(text, "20") == "20=0,0,1,1,1;", "an item only the first scan saw stays")
        check(saved().scans[day] == 2, "two scans that day")
    end
    check(Line(text, "40") == "40=70,70,1,1,1;", "an item new in this scan")
    check(Prices:Low(10) == 200, "the newest point is the last scan's price, not the day's lowest")
    -- What went between these two scans: Ann's two auctions; Bob's stood over the market price, so it was more likely taken back
    local went = Data.Rhythm.Read(saved().rhythm["10"], GetServerTime(), 86400, GetServerTime())
    check(went and went.daily == 15 and went.each == 2500 / 15, "what went since the last scan counts as sold: how many, for how much")
    check(saved().watched and saved().samples >= 1 and saved().stretch, "and for how long the house was watched; a stretch's sample was taken")
    check(Prices:Under(10, 200) == 2 and Prices:Under(10, 199) == 0 and Prices:Under(9999, 200) == nil,
        "how many are on offer up to a price, by the last scan")
    local gone = { market = 100, marks = { ["1,100"] = 2, ["2,100"] = 1, ["1,90"] = 1, ["1,500"] = 1, ["3,240"] = 1 },
        who = { ["1,100"] = "Ann", ["2,100"] = "Bob", ["1,90"] = "Cid", ["3,240"] = "Dee" }, ending = { ["1,90"] = true } }
    check(select(1, Scan.Bought(gone, nil)) == 7 and select(2, Scan.Bought(gone, nil)) == 540,
        "gone with nothing left of the item: all of it but what could have run out, and what stood over the market")
    check(select(1, Scan.Bought(gone, { marks = { ["1,100"] = 1, ["2,100"] = 1, ["3,240"] = 1 }, who = {} })) == 1,
        "what still stands was not bought, as many of a kind as there are")
    check(select(1, Scan.Bought(gone, { marks = { ["1,95"] = 1 }, who = { ["1,95"] = "Ann" } })) == 5,
        "a seller who put the item up anew took the old auction back: not sold")
    check(saved().recent[saved().at]:find("10=200,200;", 1, true) and saved().recent[answered]:find("10=100,200;", 1, true),
        "each scan has its own lowest there, not the day's")
    check(Prices:Low(20) == nil and Prices:Last(20) == 0, "what the last scan did not see keeps its last point")
    local scans = 0
    for _ in pairs(Scanned()) do scans = scans + 1 end
    check(scans == 2, "both scans of the day kept whole, each by itself")

    -- The server refuses: it says nothing
    rows = {}
    W.Wait(Scan.INTERVAL)
    check(asks == 3 and state.phase == "asking", "the next request")
    local at = saved().at
    W.Wait(Scan.ANSWER + 1)
    check(state.phase == "waiting" and state.outcome == "refused" and saved().at == at, "no answer: refused, and no 15 minutes counted")
    check(select(2, Strip()):find("The server gave no full scan", 1, true), "the bar says so")
    W.Wait(Scan.RETRY + 1)
    check(asks == 4, "and asked again soon")
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    check(state.phase == "asking", "an answer with no rows yet is no answer")

    -- Gear and pets by the game's item key; one the game comes to know, one it never does
    known[50] = true
    rows = { { item = 50, count = 1, buyout = 900, link = "|Hitem:50:0:0:0:0:0:-7:0:60|h[x]|h" }, -- suffix -7
        { item = 51, count = 1, buyout = 800, link = "|Hitem:51:0:0:0:0:0:0:0:60|h[y]|h" },
        { item = 52, count = 1, buyout = 700 },
        { item = 82800, count = 1, buyout = 600, link = "|Hbattlepet:39:1:3:0:0:0:0|h[z]|h" } }
    rows[3].item = 51
    rows[3].link = nil
    local meanwhile = false
    Steps.Run("meanwhile the scan waits", function() meanwhile = true end)
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    check(state.phase == "reading", "the rows are there now")
    for _ = 1, 5 do Frame() end
    check(requested[1] == 51 and #requested == 1, "gear the game does not know is asked of the server, once")
    check(meanwhile, "while the scan waits for the game to know an item, the other jobs keep the frame's time (Steps.Wait)")
    known[51] = true
    rows[3].link = nil
    W.clock = W.clock + Scan.ITEMS + 1
    Read()
    text = saved().days[Today()]
    check(state.outcome == "kept" and saved().left == 1, "after the wait what is still not known is left out")
    check(Line(text, "50:60:-7:0") == "50:60:-7:0=900,900,1,1,0;" and Line(text, "82800:0:0:39") == "82800:0:0:39=600,600,1,1,0;",
        "gear by item, level and suffix, a pet by its species: " .. text)
    check(Scanned()[saved().at]:find("item:50:0:0:0:0:0:-7:0:60", 1, true), "a row of gear whole with its item string")
    check(Prices:Low(50) == 900 and Prices:Low("|Hitem:50:0:0:0:0:0:-7:0:60|h[x]|h") == 900 and Prices:Low("|Hbattlepet:39:1:3:0:0:0:0|h[z]|h") == 600,
        "gear and pets read by their ID and by a link")

    -- What the game lists right now is the newest of all
    local told = 0
    Prices:OnChange(function() told = told + 1 end)
    local browse = { { itemKey = { itemID = 10 }, minPrice = 150, totalQuantity = 7 }, { itemKey = { itemID = 50, itemLevel = 60, itemSuffix = -7 }, minPrice = 950 },
        { itemKey = { itemID = 50, itemLevel = 60, itemSuffix = -7 }, minPrice = 870 } }
    C_AuctionHouse.GetBrowseResults = function() return browse end
    W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
    W.Wait(0)
    check(Prices:Low(10) == 150 and select(3, Prices:Last(10)) == 7 and select(2, Prices:Last(10)) == 200, "a list of the game's: its lowest price and what is on offer now, the market stays the scan's")
    check(Prices:Low(50) == 870 and told == 1, "the lowest of a list's rows of one kind; the views told once")
    W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", { { itemKey = { itemID = 50, itemLevel = 60, itemSuffix = -7 }, minPrice = 990 }, { itemKey = { itemID = 40 }, minPrice = 65 } })
    check(Prices:Low(50) == 870 and Prices:Low(40) == 65, "more rows of the same list: also the lowest")
    C_AuctionHouse.GetNumCommoditySearchResults = function() return 2 end
    C_AuctionHouse.GetCommoditySearchResultInfo = function(_, index) return { unitPrice = index == 1 and 55 or 90 } end
    C_AuctionHouse.GetCommoditySearchResultsQuantity = function() return 44 end
    W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 40)
    check(Prices:Low(40) == 55 and select(3, Prices:Last(40)) == 44, "the offers of a thing sold by the unit")
    local kind = { itemID = 10 }
    C_AuctionHouse.GetNumItemSearchResults = function() return 2 end
    C_AuctionHouse.GetItemSearchResultInfo = function(_, index) return { buyoutAmount = index == 1 and 1000 or 900, quantity = index == 1 and 10 or 20 } end
    C_AuctionHouse.GetItemSearchResultsQuantity = function() return 30 end
    W.Fire("ITEM_SEARCH_RESULTS_UPDATED", kind)
    check(Prices:Low(10) == 45 and select(3, Prices:Last(10)) == 30, "the offers of an item, per unit")
    local point = saved().index
    W.Fire("PLAYER_LOGOUT")
    check(saved().index ~= point and saved().index:find("40=%d+,55,70,44,1,1;"), "what the game listed is written at the logout: " .. saved().index)
    check(whole ~= nil and Scanned()[answered] == whole, "and never into the scans, which stay as the server gave them")

    -- A scan another addon asked for, and the auction house closed halfway
    rows = {}
    for index = 1, 300 do rows[index] = Plain(index + 100, 1, 10, "Hal") end
    W.Wait(Scan.INTERVAL - 2)
    local before = asks
    W.clock = W.clock + 1
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    check(asks == before and state.phase == "reading", "any full scan is read, whoever asked for it")
    local gone = saved().days[Today()]
    local wholes = 0
    for _ in pairs(Scanned()) do wholes = wholes + 1 end
    rowCost = 1
    Frame()
    rowCost = 0
    check(state.read > 0 and state.read < 300, "read in steps: no frame over its budget")
    W.Fire("AUCTION_HOUSE_CLOSED")
    check(state.phase == "closed" and not Strip():IsShown(), "the auction house closes, and the bar goes with it")
    rows = {}
    for _ = 1, 20 do Frame() end
    local after = 0
    for _ in pairs(Scanned()) do after = after + 1 end
    check(saved().days[Today()] == gone and after == wholes and not Steps.Running("Full auction scan"), "the list gone halfway: nothing of it is kept")
    local waited = asks
    W.Wait(Scan.INTERVAL * 2)
    check(asks == waited, "closed: no request and no look at the time")

    -- Kept per game: a limit drops the oldest days
    W.Fire("AUCTION_HOUSE_SHOW")
    check(state.outcome == "kept" and state.phase == "waiting", "opened again: the last scan kept is told")
    Scan.KEEP.forever = 2
    saved().days[Today() - 5], saved().scans[Today() - 5] = "1=1,1,1,1,1;", 1
    saved().recent[(Today() - 2) * 86400], saved().recent[(Today() - 1) * 86400] = "1=1,1;", "1=2,2;"
    rows = { Plain(10, 1, 100, "Ivy") }
    W.Wait(Scan.SETTLE + Scan.INTERVAL)
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    Read()
    check(saved().days[Today() - 5] == nil and saved().scans[Today() - 5] == nil and saved().days[Today()], "a game with a limit keeps that many days")
    check(saved().recent[(Today() - 2) * 86400] == nil and saved().recent[(Today() - 1) * 86400] and saved().recent[saved().at],
        "a scan as a line per item stays today and yesterday; the scans kept whole stay for good")
    Scan.KEEP.forever = nil

    -- The bar pressed: a scan now
    local bar = Strip()
    local pressed, due = asks, state.next
    bar._scripts.OnClick(bar)
    check(asks == pressed + 1 and state.phase == "asking", "the bar pressed: a scan asked for at once, the 16 minutes not waited for")
    bar._scripts.OnClick(bar)
    check(asks == pressed + 1, "pressed again while it waits for the server: nothing more")
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    check(state.phase == "asking", "the game tells of the last scan again: no answer to the press")
    W.Wait(Scan.ANSWER + 1)
    check(state.outcome == "refused" and state.next == due and asks == pressed + 1, "the server's 15 minutes not up: refused, and the wait goes on where it was")
    bar._scripts.OnClick(bar)
    rows[2] = Plain(10, 2, 80, "Jo")
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    check(state.phase == "reading" and state.next == GetServerTime() + Scan.INTERVAL, "the server answers a press: a scan like any other, the 16 minutes from here")
    Read()
    check(state.outcome == "kept" and state.total == 2, "and kept")
    bar._scripts.OnClick(bar)
    W.Wait(Scan.ANSWER + 1)
    bar._scripts.OnEnter(bar)
    bar._scripts.OnLeave(bar)

    -- Paused, resumed, cancelled: the game's stopwatch buttons and its X at the bar's right end
    do
        local hold, cancel
        for _, widget in ipairs(W.frames) do
            if widget._parent == bar and widget._kind == "Button" then
                if widget._template == "UIPanelCloseButtonNoScripts" then cancel = widget else hold = widget end
            end
        end
        local store, JOB = Core.Store(Core.name), "Full auction scan"
        local function Days() return saved().days[Today()] end
        check(hold and cancel and hold:IsShown() and not cancel:IsShown() and hold.art:find("PauseButton"),
            "beside the bar's words: the pause; no X while no scan runs")
        rows = {}
        for index = 1, 300 do rows[index] = Plain(index + 100, 1, 10, "Hal") end
        bar._scripts.OnClick(bar)
        check(state.phase == "asking" and cancel:IsShown(), "a scan asked for: the X is there")
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        local kept, asked = Days(), asks
        rowCost = 1
        Frame()
        check(state.phase == "reading" and state.read > 0 and state.read < 300, "read in steps")
        hold._scripts.OnClick(hold)
        check(state.paused and store.auctionScanPaused == true and hold.art:find("NextPage"),
            "the pause pressed: paused, kept in the account's store, and the button turns to play")
        Frame()
        local read = state.read
        for _ = 1, 10 do Frame() end
        check(state.read == read and read < 300 and Steps.Running(JOB) and state.phase == "reading",
            "the reading waits where it stood, the scan still underway")
        W.Wait(Scan.TICK)
        check(select(2, Strip()) == ("Full scan paused: %d of 300 auctions"):format(read), "the bar says so: " .. select(2, Strip()))
        W.Fire("AUCTION_HOUSE_CLOSED")
        check(not Steps.Running(JOB) and Days() == kept, "the house closes: the paused scan is dropped, nothing of it kept")
        state.paused = nil -- a new session: only the store remembers
        W.Fire("AUCTION_HOUSE_SHOW")
        check(state.paused == true and hold.art:find("NextPage"), "opened again, after a logout too: still paused")
        W.Wait(Scan.INTERVAL * 2)
        check(asks == asked and state.phase == "waiting" and select(2, Strip()):find("^Full scans paused%. The last finished at "),
            "no request while paused, however long: " .. select(2, Strip()))
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        Frame()
        check(state.phase == "reading" and state.read == 0 and Steps.Running(JOB), "a scan another addon asked for waits before its first row")
        hold._scripts.OnClick(hold)
        check(not state.paused and store.auctionScanPaused == nil and hold.art:find("PauseButton"), "resumed: the pause forgotten")
        Read()
        check(state.outcome == "kept" and state.total == 300 and Days() ~= kept, "the scan reads on and is kept")

        -- The X while it reads: dropped, and the game telling of it again is not read
        rows[301] = Plain(500, 1, 10, "Hal")
        kept = Days()
        bar._scripts.OnClick(bar)
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        Frame()
        local due = state.next
        check(state.phase == "reading" and state.read < 301, "the next scan reads")
        cancel._scripts.OnClick(cancel)
        check(state.phase == "waiting" and state.outcome == "cancelled" and not Steps.Running(JOB) and not cancel:IsShown(),
            "the X pressed: the scan dropped, the X gone")
        check(Days() == kept and state.next == due, "nothing of it kept; the next comes at its time")
        check(select(2, Strip()):find("^The full scan was cancelled%. Next in 1[56]:%d%d$"), "the bar says so: " .. select(2, Strip()))
        check(Scan.Cancel() == false, "nothing to cancel any more")
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        check(state.phase == "waiting", "the game tells of that scan again: not read")

        -- The X while it waits for the server: its answer is not read either; the next after a whole interval
        asked = asks
        bar._scripts.OnClick(bar)
        local at = GetServerTime()
        cancel._scripts.OnClick(cancel)
        check(asks == asked + 1 and state.phase == "waiting" and state.outcome == "cancelled" and state.next == at + Scan.INTERVAL,
            "cancelled while the server is asked: the next 16 minutes from the request")
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        check(state.phase == "waiting", "its late answer is not read")
        W.Wait(Scan.INTERVAL + Scan.TICK)
        check(asks == asked + 2 and state.phase == "asking", "the next request at its time")
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        Read()
        check(state.outcome == "kept", "and its answer read again")

        -- Paused while it waits; the bar pressed then resumes and scans now
        hold._scripts.OnClick(hold)
        asked = asks
        bar._scripts.OnClick(bar)
        check(not state.paused and store.auctionScanPaused == nil and asks == asked + 1, "paused, the bar pressed: resumed, and a scan asked for now")
        W.Wait(Scan.ANSWER + 1)
        hold._scripts.OnEnter(hold)
        hold._scripts.OnLeave(hold)
        rowCost = 0
    end

    -- Retail keeps no scan whole; a price grows old
    Scan.WHOLE.forever, Scan.RECENT.forever = nil, nil
    rows = { Plain(10, 1, 400, "Kim"), Plain(10, 1, 500, "Lee") }
    W.Wait(Scan.INTERVAL + Scan.TICK)
    W.Fire("REPLICATE_ITEM_LIST_UPDATE")
    Read()
    check(state.outcome == "kept" and Scanned()[saved().at] == nil and saved().days[Today()]:find("10=", 1, true),
        "a game that keeps no scan whole: the day's points, the newest prices")
    check(saved().recent[saved().at] == nil, "and no line per item of a scan")
    Scan.WHOLE.forever, Scan.RECENT.forever = true, true
    local fresh = Prices.FRESH
    Prices.FRESH = 0
    W.clock = W.clock + 1
    check(Prices:Low(10) == nil and Prices:Last(10) == 400, "a price not seen again for its days is no price any more, its point stays")
    Prices.FRESH = fresh
    W.printed = {}
    SlashCmdList.SANEUI("data")
    check(printedMatch("auction house eu/1234/alliance: %d+ days, %d+ whole scans %(%d+%.%d MB%)"), "/sane data says what the whole scans weigh")

    -- How a price went: what is most current for each stretch of time, whichever holds it
    do
        local home, now, today = saved(), GetServerTime(), Today()
        local function Prices4242(from, to)
            local list = {}
            for index, point in ipairs(Prices:Range(4242, from, to)) do list[index] = point.low .. "/" .. point.market end
            return table.concat(list, " ")
        end
        check(Prices4242() == "", "a thing no scan saw has no history")
        home.days[today - 9] = "1=1,1,1,1,1;4242=900,950,1,1,1;"
        home.days[today - 8] = "4242=800,850,1,1,1;2=2,2,2,2,2;"
        home.days[today - 7] = "44242=7,7,7,7,7;142420=8,8,8,8,8;"
        home.days[today - 6] = "4242=700,750,1,1,1;"
        home.days[math.floor((now - 3600) / 86400)] = "4242=1,1,1,1,1;"
        home.recent[now - 7200], home.recent[now - 3600] = "4242=640,690;", "1=1,1;4242=600,650;"
        Prices.See("4242", 555)
        check(Prices4242() == "900/950 800/850 700/750 640/690 600/650 555/0",
            "a day before the scans at hand a point a day, a day with scans a point a scan, whatever the game lists now last: " .. Prices4242())
        check(Prices4242(now - 86400) == "640/690 600/650 555/0", "from a time on")
        check(Prices4242(nil, now - 1800) == "900/950 800/850 700/750 640/690 600/650", "up to a time")
        check(Prices:Range(4242)[1].at == (today - 9 + 0.5) * 86400, "a day's point stands in the middle of the day")
        check(Prices:Range(4242)[6].at == now, "the newest point at the time it was seen")
        local stamp = Prices:Stamp()
        Prices.See("4242", 554)
        check(Prices:Stamp() ~= stamp and Prices4242():find("554/0", 1, true), "what the game lists moves the stamp and the newest point")
        home.days[today - 6] = "4242=1,1,1,1,1;"
        check(Prices4242():find("700/750", 1, true), "the rest is held")
        home.days[today - 6] = "4242=700,750,1,1,1;"

        -- The database has what the file does not; where both have a day it took this account's in with the others'
        Accounts({ ["eu/1234/alliance"] = { days = { [today - 12] = "4242=300,350,1,1,1;", [today - 8] = "2=2,2,2,2,2;4242=100,200,1,1,1;" },
            recent = { [now - 1800] = "4242=610,660;" } } })
        Prices.Changed()
        check(Prices4242() == "300/350 900/950 100/200 700/750 640/690 600/650 610/660 554/0",
            "whichever is more current: the database's days where it has them, this account's where not, the scans of both: " .. Prices4242())
        Accounts({ ["eu/1234/alliance"] = { days = { [today - 12] = "4242=300,350,1,1,1;9=9,9,9,9,9;4242=250,0,1,1,1;" } } })
        Prices.Changed()
        check(Prices4242():find("^250/350 "), "two accounts' strings of a day joined: the lowest price of them, the last market price there is")
        Accounts({ ["eu/1234/alliance"] = { days = { [today - 12] = "9=9,9,9,9,9;4242=0,0,1,1,1;4242=250,260,1,1,1;4242=280,270,1,1,1;" } } })
        Prices.Changed()
        check(Prices4242():find("^250/270 "), "a price of 0 (no buyout) is passed over, in the string or at its head")
        Accounts({ ["eu/1234/alliance"] = { days = { [today - 12] = "4242=300,350,1,1,1;" } } })
        Prices.Changed()
        check(Prices4242():find("300/350 900/950 800/850", 1, true), "a database made before it held scans")
        Accounts({})
        Prices.Changed()
        check(Prices4242():find("^900/950"), "a house the database does not have")

        -- A piece of gear: the kind its link names; its ID, the cheapest of them
        Prices.See("50:60:-7:0", 870)
        Prices.See("50:60:-9:0", 800)
        home.days[today - 9] = home.days[today - 9] .. "50:60:-7:0=880,881,1,1,1;50:60:-9:0=810,811,1,1,1;"
        Prices.Changed()
        local link = Prices:Range("|Hitem:50:0:0:0:0:0:-7:0:60|h[x]|h")
        check(link[1].low == 880 and link[#link].low == 870, "a link: the history of its kind")
        local cheapest = Prices:Range(50)
        check(cheapest[1].low == 810 and cheapest[2].low == 800, "an ID: of the cheapest of its kinds")
        home.days[today - 9], home.days[today - 8], home.days[today - 7], home.days[today - 6] = nil, nil, nil, nil
        home.days[math.floor((now - 3600) / 86400)] = nil
        home.recent[now - 7200], home.recent[now - 3600] = nil, nil
        Prices.See("4242")
        Prices.See("50:60:-7:0")
        Prices.See("50:60:-9:0")
        Prices.Changed()
    end

    -- The auction addons SaneUI knows (Core.Neighbours.Prices): their books count where SaneUI saw nothing newer
    do
        local home, now, today = saved(), GetServerTime(), Today()
        local book, scan = Core.Neighbours.KNOWN.auctionPrices, Core.Neighbours.KNOWN.auctionScan
        local zero = 1577836800 -- the client's midnight its day 0 began, by the stand-in clock
        local clock = rawget(_G, "time")
        rawset(_G, "time", function(at) return at and zero or GetServerTime() end)
        local day = math.floor((now - zero) / 86400)
        local function Day(back) return tostring(day - back) end
        local function Entry(newest, highs, lows, offered)
            return { [book.newest] = newest, [book.high] = highs, [book.low] = lows or {}, [book.offered] = offered or {} }
        end
        local realm = {
            ["4243"] = Entry(480, { [Day(2)] = 520, [Day(0)] = 500 }, { [Day(0)] = 470 }, { [Day(0)] = 12 }),
            ["4245"] = Entry(300, { [Day(3)] = 300 }),
            ["g:50:60"] = Entry(870, { [Day(1)] = 870 }), ["50"] = Entry(999, { [Day(1)] = 999 }),
            ["p:41"] = Entry(650, { [Day(1)] = 650 }),
            ["10"] = Entry(5, { [Day(9)] = 5 }),
            ["4248"] = { [book.newest] = "much", [book.high] = 7 },
        }
        rawset(_G, book.saved, { Stub = realm, ["Some Realm"] = "packed" })
        local items = {
            [4244] = { [scan.low] = 455.4, [scan.units] = 7, [scan.at] = now - 3600, [scan.days] = { [today - 1] = 460.2 } },
            [4245] = { [scan.low] = 280, [scan.units] = 3, [scan.at] = now - 3600 },
            [4247] = { [scan.low] = 210, [scan.units] = 2, [scan.at] = now - 60, [scan.days] = { [today - 2] = 100, [today - 1] = 200 } },
        }
        rawset(_G, scan.saved, { [scan.part] = { [scan.realm:format("Stub Realm", "Alliance")] = { [scan.items] = items } } })
        check(Prices:Low(4243) == nil and Prices:Low(4244) == nil, "(their books count only while their addons are loaded)")
        local own = { Prices:Last(10) }
        W.loaded[book.addon], W.loaded[scan.addon] = true, true
        Prices.Changed()

        local low, market, units, auctions, sellers, at = Prices:Last(4243)
        check(low == 480 and market == 0 and units == 12 and auctions == 0 and sellers == 0 and at == zero + day * 86400 and Prices:Low(4243) == 480,
            "a thing no scan of SaneUI's saw: an auction addon's newest price, on offer that day, at that day's start")
        low, _, units, _, _, at = Prices:Last(4244)
        check(low == 455 and units == 7 and at == now - 3600, "another's: its last scan's lowest, in whole copper, how many and when")
        check(Prices:Low(4245) == 280, "two of them: the newer")
        check(Prices:Low(10) == own[1] and select(2, Prices:Last(10)) == own[2] and own[2] > 0 and select(6, Prices:Last(10)) == own[6],
            "SaneUI's own point where it is newer, its market with it")
        check(Prices:Low("|Hitem:50:0:0:0:0:0:-7:0:60|h[x]|h") == 870 and Prices:Low(50) == 999,
            "gear: the book of its level where its link names one, else its item's")
        check(Prices:Low("|Hbattlepet:41:1:3:0:0:0:0|h[z]|h") == 650, "a pet by its species")
        check(Prices:Last(4248) == nil and Prices:Last(9999) == nil, "an entry of a shape not known, and none, are no price")
        Prices.See("4246", 300)
        items[4246] = { [scan.low] = 250, [scan.units] = 1, [scan.at] = now - 60 }
        check(Prices:Low(4246) == 300, "what the game lists now beats an older scan of theirs")
        items[4246][scan.at] = now + 60
        check(Prices:Low(4246) == 250, "and a later scan of theirs beats it")

        local function Points(item)
            local list = {}
            for index, point in ipairs(Prices:Range(item)) do list[index] = point.low .. "/" .. point.market end
            return table.concat(list, " ")
        end
        check(Points(4243) == "520/0 470/0", "their days make a range where SaneUI has none, each day's lowest: " .. Points(4243))
        check(Prices:Range(4243)[1].at == zero + (day - 2 + 0.5) * 86400, "a day of theirs in the middle of the day")
        home.days[today - 2] = "4247=900,950,1,1,1;"
        Prices.Changed()
        check(Points(4247) == "900/950 200/0 210/0",
            "a day SaneUI has stays its own, theirs fill the rest, their newest point last: " .. Points(4247))
        check(Points(4244):find("^460/0"), "the days of a scan of theirs, in whole copper")

        -- The forecast (Prices:Outlook) from their days: three weeks of them, dear on one weekday
        local dear = date("*t", zero + (day - 2 + 0.5) * 86400).wday -- the weekday two days back: not today
        local highs = {}
        for back = 20, 0, -1 do
            highs[Day(back)] = date("*t", zero + (day - back + 0.5) * 86400).wday == dear and 1500 or 1000
        end
        realm["4250"], realm["4251"] = Entry(1000, highs), Entry(1000, highs)
        Prices.Changed()
        local outlook = Prices:Outlook(4250)
        check(outlook and outlook.days > 20 and outlook.allDay and outlook.highAt and outlook.highAt > now
            and date("*t", outlook.highAt).wday == dear and outlook.high > 1200 and outlook.daily == nil,
            "a thing only their days know: the day it sells dearest is named, how many sell is not known")
        local line
        for step = 8, 1, -1 do line = Data.Rhythm.Seen(line, now - step * 3 * 3600, 1000) end
        home.rhythm["4251"] = line
        Prices.Changed()
        outlook = Prices:Outlook(4251)
        check(outlook and outlook.days > 20 and outlook.highAt and date("*t", outlook.highAt).wday == dear,
            "a day of SaneUI's own scans: their days before it join its line, and the day still counts")
        home.rhythm["4251"] = nil

        local side = UnitFactionGroup
        UnitFactionGroup = function() return "Horde" end
        local other = Prices.House("npc")
        UnitFactionGroup = side
        check(Prices.Within(other, function() return Prices:Low(4243) end) == nil and #Prices.Within(other, Prices.Range, Prices, 4243) == 0,
            "their books count for the house of your side alone")
        SaneUIData_Market.forever.houses["eu/1234/horde"] = nil

        rawset(_G, book.saved, { Stub = "packed" })
        check(Prices:Low(4243) == nil and Prices:Low(4244) == 455, "a book still packed is none; the other one's stands")
        rawset(_G, scan.saved, { [scan.part] = "changed" })
        check(Prices:Low(4244) == nil, "nor a book of a shape not known")
        Prices.See("4246")
        home.days[today - 2] = nil
        rawset(_G, book.saved, nil)
        rawset(_G, scan.saved, nil)
        W.loaded[book.addon], W.loaded[scan.addon] = nil, nil
        rawset(_G, "time", clock)
        Prices.Changed()
    end

    -- Every account's file through its link: joined, the global left clear for this account's own, which is read after them
    do
        local Prices = Data.Series("Prices")
        check(Accounts({ ["eu/1234/orc"] = { kept = 200, index = "5=200,50,50,1,1,1;", days = { [100] = "5=50,50,1,1,1;" }, recent = { [200] = "5=50,50;" } } }) == nil,
            "a link read: the global left clear")
        Account({ ["eu/1234/orc"] = { kept = 100, index = "5=100,70,70,1,1,1;6=100,8,8,1,1,1;", days = { [100] = "5=70,70,1,1,1;", [99] = "6=8,8,1,1,1;" }, recent = { [100] = "6=8,8;" } } })
        Account({ ["eu/1234/orc"] = "no shape" })
        Account(nil)
        local exists, faction, opened = rawget(_G, "UnitExists"), rawget(_G, "UnitFactionGroup"), nil
        rawset(_G, "UnitExists", function(unit) return unit == "npc" end)
        rawset(_G, "UnitFactionGroup", function() return "Orc" end)
        W.Fire("AUCTION_HOUSE_CLOSED")
        W.Fire("AUCTION_HOUSE_SHOW")
        rawset(_G, "UnitExists", exists)
        rawset(_G, "UnitFactionGroup", faction)
        check(Prices:Last(5) == 50 and Prices:Last(6) == 8, "each item's newest point of any account")
        local house = SaneUIData_Market.forever.houses["eu/1234/orc"]
        check(house.index == nil or not house.index:find("6=", 1, true), "nothing of another account goes into this one's file by reading it")
        W.Fire("AUCTION_HOUSE_CLOSED")
        W.Fire("AUCTION_HOUSE_SHOW")
        Accounts({})
    end

    -- A scan shared with the guild and the group (Relay.lua), through a wire that only writes down
    do
        local Prices, Relay, Wire = Data.Series("Prices"), Data.Relay, Core.Wire
        local send, sendBlock, drop = Wire.Send, Wire.SendBlock, Wire.Drop
        local sent, blocks, dropped, room = {}, {}, 0, true
        Wire.Send = function(kind, fields, channel, target, hurry)
            sent[#sent + 1] = { kind = kind, what = fields[1], house = fields[2], at = fields[3], channel = channel, target = target, hurry = hurry }
            return true
        end
        Wire.SendBlock = function(kind, text, channel, target, tag)
            if not room then return false end
            blocks[#blocks + 1] = { kind = kind, text = text, channel = channel, target = target, tag = tag }
            return true
        end
        Wire.Drop = function() dropped = dropped + 1 return 0 end
        local inGuild = rawget(_G, "IsInGuild")
        rawset(_G, "IsInGuild", function() return true end)
        local house = "eu/1234/alliance"

        -- The login's question, and the answer to one: the last scan, whole
        Relay.Ask()
        check(#sent == 1 and sent[1].what == "ask" and sent[1].house == house and sent[1].at == saved().kept and sent[1].channel == "GUILD",
            "a minute after the login: who has a newer scan of this house than this account?")
        Relay.Ask()
        check(#sent == 1 and type(SaneUIData_Market.forever.asked) == "table", "once in a quarter of an hour, whatever reloads come between (kept in the file)")
        sent = {}
        Relay.Told("x", { "ask", house, "0" }, "GUILD")
        W.Wait(3)
        check(#sent == 1 and sent[1].what == "have" and sent[1].at == saved().kept, "a member asks who has nothing as new: this account offers its last scan")
        Relay.Told("x", { "want", house, tostring(saved().kept) }, "GUILD")
        check(#blocks >= 1 and blocks[1].text:find("^" .. house .. "\n" .. saved().kept .. "\n"), "and sends it, all of it: " .. tostring(blocks[1] and blocks[1].text:sub(1, 60)))
        sent, blocks = {}, {}

        -- A scan kept: one message, and only what moved, and only for who asks
        rows = {}
        for index = 1, 900 do rows[index] = Plain(index + 2000, 1, 1000 + index, "Mo") end
        W.Wait(Scan.INTERVAL + Scan.TICK)
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        Read()
        local at = saved().at
        local offered = sent[#sent]
        check(#sent == 1 and offered.kind == "A" and offered.what == "have" and offered.house == house and offered.at == at
            and offered.channel == "GUILD" and offered.hurry, "a scan kept: one message on the guild: this house, this time")
        W.Wait(Relay.WAIT + 1)
        check(#blocks == 0, "nobody asks: nothing more goes, so a game alone sends one message")
        Relay.Told("x", { "want", house, tostring(at - 1) }, "GUILD")
        check(#blocks == 0, "a member asks for another scan: nothing")
        Relay.Told("x", { "want", house, tostring(at) }, "WHISPER")
        check(#blocks == 0, "never by whisper: the server stands for the sender only on the guild and the group")
        Relay.BYTES = 2000
        Relay.Told("x", { "want", house, tostring(at) }, "GUILD")
        check(#blocks > 1 and blocks[1].channel == "GUILD" and blocks[1].target == nil and blocks[1].kind == "A" and blocks[1].tag == "prices",
            "a member asks: on that channel, in blocks")
        local all = ""
        for _, block in ipairs(blocks) do
            local h, t, lines = block.text:match("^([^\n]+)\n(%d+)\n(.*)$")
            check(h == house and tonumber(t) == at and #lines <= Relay.BYTES, "each block says what house and when, and stays small")
            all = all .. lines
        end
        local _, told = all:gsub(";", ";")
        check(told == 900 and all:find("2001=1001,1001,1,1,1;", 1, true), "every item that moved, with its point")
        local count = #blocks
        Relay.Told("x", { "want", house, tostring(at) }, "GUILD")
        check(#blocks == count, "a second member asks on that channel: it rides along")
        Relay.Told("x", { "want", house, tostring(at) }, "PARTY")
        check(#blocks == count * 2 and blocks[#blocks].channel == "PARTY", "one in the party only: the same once more there")

        -- The next scan: only what moved; the queue full: tried again
        rows[1] = Plain(2001, 1, 7777, "Mo")
        blocks, sent = {}, {}
        W.Wait(Scan.INTERVAL + Scan.TICK)
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        Read()
        at = saved().at
        check(dropped >= 1, "a new scan: what still waits of the last is dropped")
        room = false
        local queue = Wire.Waiting
        Wire.Waiting = function() return 5 end
        Relay.Told("x", { "want", house, tostring(at) }, "GUILD")
        check(#blocks == 0, "no room in the queue: nothing lost")
        room = true
        Wire.Waiting = queue
        W.Wait(Relay.RETRY + 1)
        check(#blocks == 1 and blocks[1].text:find("2001=7777,7777,1,1,1;", 1, true) and not blocks[1].text:find("2002=", 1, true), "then it goes, and only what moved")

        -- A member's scan heard: wanted once, by the first to answer
        sent, blocks = {}, {}
        local later = at + Relay.QUIET + 60
        W.clock = W.clock + math.max(later - GetServerTime(), 0) -- an offer further ahead than Relay.AHEAD would be a strike
        Relay.Told("x", { "have", "eu/1/horde", tostring(later) }, "GUILD")
        Relay.Told("x", { "have", house, tostring(at + 60) }, "GUILD")
        W.Wait(Relay.WAIT + 1)
        check(#sent == 0, "a house this account does not know, or a scan no newer than it has: not wanted")
        Relay.Told("x", { "have", house, tostring(later) }, "GUILD")
        Relay.Told("x", { "have", house, tostring(later) }, "PARTY")
        W.Wait(Relay.WAIT + 1)
        check(#sent == 1 and sent[1].what == "want" and sent[1].channel == "GUILD" and sent[1].house == house and sent[1].at == later, "a newer scan: wanted, once, on its channel")
        sent = {}
        local after = later + Relay.QUIET + 60
        W.clock = W.clock + math.max(after - GetServerTime(), 0)
        Relay.Told("x", { "have", house, tostring(after) }, "GUILD")
        Relay.Told("x", { "want", house, tostring(after) }, "GUILD")
        W.Wait(Relay.WAIT + 1)
        check(#sent == 0, "another member asks first: this one stays quiet, and takes it all the same")

        -- Its blocks: fills in what is older, far-off prices need a second sender
        W.clock = W.clock + math.max(later - GetServerTime(), 0) + 60
        local stamp, seen = Prices:Stamp(), 0
        Prices:OnChange(function() seen = seen + 1 end)
        local function Block(sender, when, lines, channel, where)
            Relay.Block(sender, ("%s\n%d\n%s"):format(where or house, when, lines), channel or "GUILD")
        end
        Block("Two", later, "3003=44,55,6,7,8;3005=9,9,9,9,9;")
        W.Wait(0)
        local low, usual, units, _, _, heardAt = Prices:Last(3003)
        check(low == 44 and usual == 55 and units == 6 and heardAt == later and Prices:Low(3005) == 9 and Prices:Stamp() ~= stamp and seen == 1,
            "a member's block: its prices are the newest at once, the views told")
        Block("Two", later, "3003=45,45,1,1,1;", "WHISPER")
        check(Prices:Last(3003) == 44, "a block by whisper is passed over")
        Block("Five", later - 900, "3003=45,45,1,1,1;")
        check(Prices:Last(3003) == 44, "an older scan's changes nothing: a shared price fills in only what is older")
        check(select(1, next(Prices:Range(3003, nil, later + 100))) ~= nil, "the graphs have it too")
        Block("Five", later, "3006=1,1,1,1,1;", "GUILD", "eu/9/horde")
        check(Prices:Last(3006) == nil, "a house this account does not know: passed over")

        -- Kept apart: this account's own stands under it, and comes back
        local ownLow = Prices:Last(2002)
        Block("Six", later, "2002=" .. ownLow + 1 .. ",9,9,9,9;")
        check(Prices:Last(2002) == ownLow + 1, "a member's price stands over this account's older one")
        W.Fire("PLAYER_LOGOUT")
        check(saved().heard.Six:find("2002=" .. later .. ",", 1, true) and saved().heard.Two:find("3003=" .. later .. ",44,55,6,7,8;", 1, true), "what was told stays for the next login, apart, by sender")
        check(not saved().index:find("3003=", 1, true) and saved().index:find("2002=%d+," .. ownLow .. ","), "and this account's own points are not touched by it")
        check(not (saved().days[math.floor(later / 86400)] or ""):find("3003=", 1, true), "nor its days")

        -- Far off: waits apart, for a second sender; a group's alone is not enough
        W.clock = W.clock + Relay.SOONEST * 3
        Block("Two", later + Relay.SOONEST, "3003=4400,4400,1,1,1;")
        check(Prices:Last(3003) == 44, "more than five times off what is known: not from one sender")
        Block("Two", later + Relay.SOONEST, "3003=4400,4400,1,1,1;")
        check(Prices:Last(3003) == 44, "nor from that sender again")
        Block("Seven", later + Relay.SOONEST + 1, "3003=4300,4300,1,1,1;", "PARTY")
        check(Prices:Last(3003) == 4300, "a second sender says the same: it stands")
        Block("Two", later + Relay.SOONEST * 2, "3005=9000,9000,1,1,1;", "PARTY")
        Block("Seven", later + Relay.SOONEST * 2, "3005=9100,9100,1,1,1;", "PARTY")
        check(Prices:Last(3005) == 9, "two senders of a group alone are not enough: it can hold strangers")
        check(select(2, Prices.Shared()) >= 1, "what waits is counted")

        -- Hostile members: every block read whole, or none of it; three strikes and they are not heard
        local function Mallory(name, strikes)
            return SaneUIData_Market.forever.strikes[name] and SaneUIData_Market.forever.strikes[name].count == strikes
        end
        local now = GetServerTime()
        Block("Mallory", now, "3100=5,5,5,5,5;")
        check(Prices:Last(3100) == 5, "a member like any other, until")
        Block("Mallory", now, "3101=6,6,6,6,6;3102=oops;")
        check(Prices:Last(3101) == nil and Mallory("Mallory", 1), "a block off its shape: none of it taken, and a strike")
        Relay.Block("Mallory", "nothing of the shape", "GUILD")
        check(Mallory("Mallory", 2), "no block at all: a strike")
        Block("Mallory", now + Relay.AHEAD + 60, "3103=7,7,7,7,7;")
        check(Prices:Last(3103) == nil and Prices:Last(3100) == nil, "a scan from the future: the third strike: everything it sent taken out again")
        check(SaneUIData_Market.forever.strikes.Mallory.till > now, "and it is not heard for a week")
        Block("Mallory", now, "3104=8,8,8,8,8;")
        check(Prices:Last(3104) == nil, "not heard")
        sent = {}
        Relay.Told("Mallory", { "have", house, tostring(now + Relay.QUIET * 8) }, "GUILD")
        W.Wait(Relay.WAIT + 1)
        check(#sent == 0, "nor are its offers")
        Block("Eve", now, "3105=8,8,8,8,8;")
        Block("Eve", now + 600, "3106=8,8,8,8,8;")
        check(Prices:Last(3106) == nil and SaneUIData_Market.forever.strikes.Eve.count == 1, "two scans sooner than the server allows: a strike")
        Block("Bob", now, "3107=8,8,8,8,8;99999999999999999999=1,1,1,1,1;")
        check(Prices:Last(3107) == nil and SaneUIData_Market.forever.strikes.Bob.count == 1, "an item number no item can have: a strike")
        Block("Ann", now, "666=8,8,8,8,8;3110=8,8,8,8,8;")
        check(Prices:Last(666) == nil and Prices:Last(3110) == 8 and SaneUIData_Market.forever.strikes.Ann == nil, "an item the game does not know: left out, no strike")
        Block("Rob", now, "3108=999999999999,1,1,1,1;")
        check(Prices:Last(3108) == nil and SaneUIData_Market.forever.strikes.Rob.count == 1, "a price past all the gold there is: a strike")
        Block("Old", now - Relay.OLD - 60, "3109=1,1,1,1,1;")
        check(Prices:Last(3109) == nil and SaneUIData_Market.forever.strikes.Old == nil, "a scan too old: passed over, no strike")
        local many, doubts = {}, Prices.DOUBTS
        Prices.DOUBTS = 3
        for index = 1, 5 do many[index] = ("%d=999999,999999,1,1,1;"):format(2010 + index) end
        Block("Liar", now, table.concat(many))
        check(SaneUIData_Market.forever.strikes.Liar.count == 1, "a scan full of far-off prices: a strike")
        Prices.DOUBTS = doubts
        -- A time that is no number, an offer from the future, a block with no lines: a strike each, and none of them
        -- keeps this account's own scan to itself
        sent = {}
        Relay.Told("Nan", { "have", house, "nan" }, "GUILD")
        Relay.Told("Far", { "have", house, tostring(GetServerTime() + Relay.AHEAD + 60) }, "GUILD")
        Relay.Block("Empty", house .. "\n" .. GetServerTime() .. "\n", "GUILD")
        check(Mallory("Nan", 1) and Mallory("Far", 1) and Mallory("Empty", 1), "a time that is no number, an offer from the future, a block with no lines: a strike each")
        W.clock = W.clock + Relay.QUIET -- the quarter of an hour after Mallory's honest block (an offer from the future would reach past it)
        Relay.Offer(house, GetServerTime(), { "1=1,1,1,1,1;" })
        check(#sent == 1 and sent[1].what == "have", "and none of them keeps this account's own scan to itself")
        -- A kind of an item the house sells plain, a plain key of gear, a level past any the game makes, more lines than a
        -- scan has: a strike each; more keys than a house holds standing as one member's: the rest passed over, a strike
        Block("Kind", now, "3111:1:0:0=8,8,8,8,8;")
        Block("Plain", now, "50=8,8,8,8,8;")
        Block("Level", now, "50:99999:0:0=8,8,8,8,8;")
        check(Prices:Last(3111) == nil and Prices:Last("50") == nil and Mallory("Kind", 1) and Mallory("Plain", 1) and Mallory("Level", 1),
            "a kind of an item sold plain, a plain key of gear, a level past any the game makes: a strike each")
        local most = Relay.MOST
        Relay.MOST = 2
        Block("Long", now, "3112=1,1,1,1,1;3113=1,1,1,1,1;3114=1,1,1,1,1;")
        check(Prices:Last(3112) == nil and Mallory("Long", 1), "more lines than a scan has: a strike")
        Relay.MOST = most
        local keys = Prices.KEYS
        Prices.KEYS = 2
        Block("Many", now, "3115=1,1,1,1,1;3116=1,1,1,1,1;3117=1,1,1,1,1;")
        check(Prices:Last(3115) == 1 and Prices:Last(3116) == 1 and Prices:Last(3117) == nil and Mallory("Many", 1),
            "more keys than a house holds standing as one member's: the rest passed over, a strike")
        Prices.KEYS = keys
        Prices.See("2002", ownLow)

        -- Forgotten: what members sent gone, this account's own back, the file too
        W.printed = {}
        SlashCmdList.SANEUI("data")
        check(printedMatch("auction prices told by your guild and group since the login: %d+,"), "/sane data says what they told")
        check(printedMatch("members' auction prices: %d+ standing, %d+ waiting for a second sender, 1 senders not heard"), "and what stands, waits and is not heard")
        Block("Six", now, "2003=" .. Prices:Last(2003) + 1 .. ",9,9,9,9;")
        check(select(1, Prices.Shared()) > 0, "something stands")
        local before = Prices:Last(2003) - 1
        SlashCmdList.SANEUI("data forget")
        check(printedMatch("forgot the auction prices your guild and group sent"), "/sane data forget says so")
        check(select(1, Prices.Shared()) == 0 and select(2, Prices.Shared()) == 0, "nothing of members' stands or waits")
        check(Prices:Last(3003) == nil and Prices:Last(3005) == nil and Prices:Last(2003) == before and Prices:Last(2001) == 7777, "their prices gone, this account's own back as they were")
        W.Fire("PLAYER_LOGOUT")
        check(saved().heard == nil and not saved().index:find("3003=", 1, true) and saved().index:find("2003=", 1, true), "out of the saved file too")
        check(not next(Prices:Range(3003, nil, later + 100)), "and out of the graphs")
        check(SaneUIData_Market.forever.strikes.Mallory.till > now, "the strikes stay")

        -- A member logs in and asks: the one with a newer scan offers it, whole
        sent, blocks = {}, {}
        local kept = saved().kept
        Relay.Told("x", { "ask", house, tostring(kept) }, "GUILD")
        W.Wait(3)
        check(#sent == 0, "nothing newer than the one who asks has: no answer")
        local lines = select(2, Prices.Lines(house, kept - 1))
        check(type(lines) == "table" and #lines >= 1, "this account's last scan as it is told")
        Relay.Told("y", { "ask", house, "0" }, "GUILD")
        W.Wait(3)
        check(#sent == 0, "a transfer of that house this quarter of an hour: quiet")

        -- The switch
        Core.general.shareData = false
        sent, blocks = {}, {}
        Relay.Offer(house, after + Relay.QUIET * 2, { "1=1,1,1,1,1;" })
        Relay.Told("x", { "have", house, tostring(after + Relay.QUIET * 4) }, "GUILD")
        W.Wait(Relay.WAIT + 1)
        Block("Four", GetServerTime(), "3200=4310,4310,1,1,1;")
        check(#sent == 0 and Prices:Last(3200) == nil, "Share data off: neither sends nor takes")
        Core.general.shareData = true

        -- Asked again and again: a house is offered whole once in a quarter of an hour, and a member's second ask within it
        -- is a strike
        rows[2] = Plain(2002, 1, 8888, "Mo")
        W.Wait(Scan.INTERVAL + Scan.TICK)
        W.Fire("REPLICATE_ITEM_LIST_UPDATE")
        Read()
        sent = {}
        Relay.Told("Zed", { "ask", house, "0" }, "GUILD")
        W.Wait(3)
        check(#sent == 1 and sent[1].what == "have", "a member asks: this account offers its newest scan")
        Relay.Told("Wat", { "ask", house, "0" }, "GUILD")
        W.Wait(3)
        check(#sent == 1 and not Mallory("Wat", 1), "another asks within the quarter of an hour: not offered again, no strike")
        Relay.Told("Zed", { "ask", house, "0" }, "GUILD")
        W.Wait(3)
        check(#sent == 1 and Mallory("Zed", 1), "the same member asks again within it: a strike")

        Wire.Send, Wire.SendBlock, Wire.Drop = send, sendBlock, drop
        rawset(_G, "IsInGuild", inGuild)
        Relay.BYTES = 6000
    end

    -- What all accounts hold together: read when a house is first asked about, over this account's where newer
    Accounts({ ["eu/1234/neutral"] = { index = "777=9,1,1,1,1,1;" } }, "retail")
    check(Prices:Low(777) == nil, "another game's file is not taken")
    Accounts({ ["eu/1234/neutral"] = { index = "10=" .. GetServerTime() .. ",333,1,1,1,1;777=" .. GetServerTime() .. ",222,2,3,4,5;" } })

    -- A house of a wrong shape goes to broken; the goblin towns' house has its own key
    W.Fire("AUCTION_HOUSE_CLOSED")
    SaneUIData_Market.forever.houses["eu/1234/neutral"] = { days = "no" }
    local exists, faction = rawget(_G, "UnitExists"), rawget(_G, "UnitFactionGroup")
    rawset(_G, "UnitExists", function(unit) return unit == "npc" end)
    rawset(_G, "UnitFactionGroup", function() return "Neutral" end)
    W.Fire("AUCTION_HOUSE_SHOW")
    rawset(_G, "UnitExists", exists)
    rawset(_G, "UnitFactionGroup", faction)
    check(type(SaneUIData_Market.forever.houses["eu/1234/neutral"].days) == "table" and SaneUIData_Market.forever.broken[1].days == "no",
        "the neutral house by the NPC; a part of a wrong shape set aside, never wiped")
    check(Prices:Low(777) == 222 and select(3, Prices:Last(777)) == 3, "another account's scan is read by this one, its house's")
    check(Prices:Low(10) == 333, "while a house is open only its own prices count, never another's")
    Prices.See("10", 150)
    check(Prices:Low(10) == 150, "what the game lists right now goes over it")
    W.Fire("AUCTION_HOUSE_CLOSED")
    check(Prices:Low(10) == 400, "closed: your side's again")
    W.printed = {}
    SlashCmdList.SANEUI("data")
    check(printedMatch("auction house eu/1234/alliance: %d+ days"), "/sane data tells what the history holds")
    C_Item, W.methods.CreateAnimationGroup = items, nil
    rawset(_G, "C_EncodingUtil", encoding)
    rawset(_G, "C_AuctionHouse", nil)
    rawset(_G, "AuctionHouseFrame", nil)
end
-------------------------------------------------------------------------------
--  What the auction house takes (Fees.lua): the numbers of the game's own table, tried on what was charged in play
-------------------------------------------------------------------------------
do
    local Prices = Data.Series("Prices")
    local chosen = 2
    local cvar = rawget(_G, "GetCVar")
    GetCVar = function(name) if name == "auctionHouseDurationDropdown" then return tostring(chosen) end return cvar and cvar(name) end
    check(Prices:Cut() == 0.05 and Prices:Sale(1000) == 950, "a faction's house keeps 5% of a sale")
    check(Prices:Deposit(672, 1) == 134, "8 hours, a thing of 672c at a vendor: 134c, what the game took for one")
    check(Prices:Deposit(15, 2) == 100 and Prices:Deposit(13, 8) == 100 and Prices:Deposit(0, 1) == 100,
        "under 1s the auction costs 1s all the same, for a stack too")
    chosen = 1
    check(Prices:Deposit(10000, 1) == 500, "2 hours: 5% of the vendor price")
    chosen = 3
    check(Prices:Deposit(10000, 1) == 6000, "24 hours: 60%")
    chosen = nil
    check(Prices:Deposit(10000, 1) == 2000, "no duration chosen yet: 8 hours")
    chosen = 2
    local read = Prices.Key
    Prices.Key = function() return "eu/1234/neutral" end
    check(Prices:Cut() == 0.15 and Prices:Sale(1000) == 850 and Prices:Deposit(10000, 1) == 10000,
        "a neutral house keeps 15%, and its deposit is five times as much")
    Prices.Key = read
    check(Prices:Limit({ days = 2, high = 1000, daily = 5 }, 10) == nil and Prices:Limit({ days = 9, high = 1000, daily = 0 }, 10) == nil,
        "nothing is worth paying for what is known too shortly, or seen not selling")
    check(Prices:Limit({ days = 9, high = 1101, daily = 5 }, 45) == 909, "else a sale at its best, less cut, post and a tenth")

    -- The two houses a character can reach, each by its own fees
    local Rhythm = Data.Rhythm
    local faction = Prices.House("player")
    local side = rawget(_G, "UnitFactionGroup")
    rawset(_G, "UnitFactionGroup", function(unit) if unit == "npc" then return "Neutral" end return side(unit) end)
    local neutral = Prices.House("npc")
    rawset(_G, "UnitFactionGroup", side)
    local now = GetServerTime()
    local function Known(house, key, usual, low, seen)
        local line
        for step = 21 * 8, 1, -1 do line = Rhythm.Seen(line, now - step * 3 * 3600, usual) end
        house.rhythm[key] = Rhythm.Sold(line, now, 70, 70 * usual)
        house.watched, house.watchedAt = 7 * 86400, now
        Prices.Take(house, key, seen or now, low, usual, 10, 10, 1)
    end
    Known(faction, "7001", 1000, 1000)
    Known(neutral, "7001", 2000, 1800)
    Prices.Changed()
    check(Prices.Other() == neutral, "from your side's house: the neutral one")
    check(Prices.Within(neutral, Prices.Other) == faction, "and back")
    check(Prices.Within(neutral, Prices.Cut, Prices) == 0.15 and Prices:Cut() == 0.05, "inside it, its fees; outside again, yours")
    check(select(2, pcall(Prices.Within, neutral, error, "oops")) == "oops" and Prices:Cut() == 0.05, "an error inside changes nothing after it")
    local route = Prices:Route(7001, 100)
    check(route and route.side == "neutral" and route.low == 1800 and route.usual == 2000 and route.daily == 10, "what the neutral house says of an item")
    local deposit = math.max(100, math.floor(100 * 0.25 * 4))
    check(route.sale == math.floor(1999 * 0.85) - deposit, "a sale there is reckoned by its cut of 15% and its deposit, five times yours: " .. tostring(route.sale))
    check(Prices:Trip(route) == math.floor(route.sale / 1.25), "the most worth paying to take it there leaves a quarter on top")
    check(Prices:RouteUsual("7001") == 2000, "what it usually costs there, at a look")
    check(Prices.Within(neutral, Prices.Route, Prices, 7001, 100).side == "faction", "seen from the neutral house, yours is the other")
    check(Prices.Within(neutral, Prices.Route, Prices, 7001, 100).sale == math.floor(999 * 0.95) - 100, "by your house's fees")
    Known(neutral, "7002", 2000, 1800, now - 4 * 86400)
    Prices.Changed()
    check(Prices:Route(7002, 100).low == 1800 and Prices:Route(7002, 100).sale == nil, "seen too long ago: its price is told, but it is no ground for a trip")
    check(Prices:Route(424242, 100) == nil, "an item it never saw")
    faction.onSale, faction.onSaleCount, neutral.onSale, neutral.onSaleCount = 500, 2, 300, 1
    check(select(1, Prices:OnSale()) == 800 and select(2, Prices:OnSale()) == 3, "what you have on sale is both houses' together")
    faction.onSale, faction.onSaleCount, neutral.onSale, neutral.onSaleCount = nil, nil, nil, nil
    Prices.Take(faction, "7001", now, 0, 0, 0, 0, 0)
    Prices.Take(neutral, "7001", now, 0, 0, 0, 0, 0)
    SaneUIData_Market.forever.houses[Prices.Key(neutral)] = nil
    Prices.Changed()
    GetCVar = cvar
end

-------------------------------------------------------------------------------
--  How an item's price goes with the clock (Rhythm.lua): months of made-up scans, a stretch's sample at a time
-------------------------------------------------------------------------------
do
    local Rhythm, DAY, HOURS = Data.Rhythm, 86400, 3
    local clock = date("*t", 1790000000)
    local start = 1790000000 - clock.hour * 3600 - clock.min * 60 - clock.sec -- a midnight by the player's clock
    local function Hour(at) return date("*t", at).hour end
    local function Walk(days, price)
        local line
        for step = 0, days * 24 / HOURS - 1 do
            local at = start + step * HOURS * 3600 + 600
            line = Rhythm.Seen(line, at, price(at, step))
        end
        return line, start + days * DAY + 1800
    end
    local rolled = 1
    local function Noise(size) -- the same numbers on every run
        rolled = (rolled * 75 + 74) % 65537
        return 1 + (rolled / 65537 - 0.5) * size
    end
    local function Evening(at) return (Hour(at) >= 18 and Hour(at) < 21 and 2000 or 1000) * Noise(0.06) end

    local line, now = Walk(28, function() return 1000 end)
    local steady = Rhythm.Read(line, now)
    check(steady.usual == 1000 and steady.high == 1000 and steady.low == 1000 and steady.drift == 0 and not steady.highAt and not steady.lowAt,
        "a steady price: its usual price, no drift, no time to name: " .. line)
    check(#line < 240, "a line stays short: " .. #line)
    line, now = Walk(28, function() return 1000 * Noise(0.4) end)
    local noisy = Rhythm.Read(line, now)
    check(not noisy.highAt and noisy.drift == 0 and math.abs(noisy.usual - 1000) < 60,
        "a price that only wobbles names no time, however many stretches there are to pick from")
    line, now = Walk(28, Evening)
    local evening = Rhythm.Read(line, now)
    check(evening.highAt and Hour(evening.highAt) == 18 and evening.high > 1800 and evening.high < 2200 and not evening.allDay,
        "high every evening: that stretch is named, about at its price: " .. tostring(evening.high))
    check(evening.highAt > now - DAY and evening.highAt <= now + DAY, "the soonest such evening")
    check(evening.low < 1100, "and the rest is the cheap part: " .. tostring(evening.low))
    local early = Rhythm.Read(select(1, Walk(2, Evening)), start + 2 * DAY + 1800)
    check(not early.highAt and early.high == early.usual, "two evenings are too few")
    local saturdays
    line, now = Walk(35, function(at) return (date("*t", at).wday == 7 and 1250 or 1000) * Noise(0.06) end)
    saturdays = Rhythm.Read(line, now)
    check(saturdays.highAt and date("*t", saturdays.highAt).wday == 7 and saturdays.high > 1100 and saturdays.allDay,
        "high every Saturday: the day is named, as the time of day makes no difference")
    line, now = Walk(14, function(_, step) return 1000 * (1 + 0.03 * step / 8) * Noise(0.04) end)
    local rising = Rhythm.Read(line, now)
    check(rising.drift > 0.01 and rising.high > rising.usual and rising.usual > 1200,
        "a price going up: where it is heading, and it is expected higher, not at every hour alike: " .. tostring(rising.drift))
    line, now = Walk(14, function(_, step) return 1000 * (1 - 0.03 * step / 8) * Noise(0.04) end)
    local falling = Rhythm.Read(line, now)
    check(falling.drift < -0.01 and falling.high <= falling.usual * 1.01, "going down: no better time ahead")
    line, now = Walk(4, function(_, step) return step == 0 and 9000 or 1000 end)
    check(Rhythm.Read(line, now).usual < 1300, "one wild first listing does not make the usual price")
    line, now = Walk(14, function(_, step) return step == 60 and 1 or 1000 end)
    check(Rhythm.Read(line, now).usual > 900, "nor does one listing at nothing later on")

    check(Rhythm.Read("1,2,3", now) == nil and Rhythm.Read(nil, now) == nil, "a line of no shape reads as nothing")
    check(Rhythm.Read(Rhythm.Seen("1,2,3", now, 500), now + 3600).usual == 500, "and starts anew")
    check(Rhythm.Read(Rhythm.Sold(nil, now, 5, 100), now) == nil, "sales alone are no price")
    local sold = Rhythm.Seen(Rhythm.Sold(nil, now, 10, 1000), now, 120)
    check(Rhythm.Read(sold, now, 3600, now).daily == nil, "too short a watch tells nothing of selling")
    check(Rhythm.Read(sold, now, 2 * DAY, now).daily == 5 and Rhythm.Read(sold, now, 2 * DAY, now).each == 100, "ten sold in two days: five a day, at what they went for")
    local later = Rhythm.Read(sold, now + 7 * DAY, 2 * DAY, now)
    check(math.abs(later.daily - 5) < 0.01, "sales and the watch fade alike, so a pause changes nothing")
    local none = Rhythm.Read(Rhythm.Seen(nil, now, 120), now, 2 * DAY, now)
    check(none.daily == 0 and none.each == nil, "watched and nothing sold: that is told too")
    local house = {}
    Rhythm.Watched(house, now, 600)
    Rhythm.Watched(house, now, 600)
    check(house.watched == 1200 and house.watchedAt == now, "the watch adds up")
    check(Rhythm.Stretch(start + 3600) == Rhythm.Stretch(start + 2 * 3600) and Rhythm.Stretch(start + 3600) ~= Rhythm.Stretch(start + 4 * 3600),
        "three hours are one stretch")

    -- A book that keeps only each day's lowest price (another addon's): a day's sample, at the middle of the day
    local function Days(days, price, from)
        local line
        for day = 0, days - 1 do
            local at = (from or start) + day * DAY + 12 * 3600
            line = Rhythm.Day(line, at, price(at, day))
        end
        return line, (from or start) + days * DAY + 1800
    end
    local function Saturday(at) return (date("*t", at).wday == 7 and 1300 or 1000) * Noise(0.04) end
    line, now = Days(21, Saturday)
    local weeks = Rhythm.Read(line, now)
    check(weeks.highAt and date("*t", weeks.highAt).wday == 7 and weeks.high > 1150 and weeks.allDay and weeks.days > 20,
        "three weeks of days, dear on Saturdays: the day is named, no time of day: " .. tostring(weeks.high))
    check(Rhythm.Since(line) == start + 12 * 3600 and Rhythm.Since(nil) == nil, "a line says when it began")
    local week = Rhythm.Read(select(1, Days(7, Saturday)), start + 7 * DAY + 1800)
    check(not week.highAt and week.high == week.usual, "one week of days is too few to name a day")
    line, now = Days(7, function(_, day) return 1000 * (1 + 0.06 * day) end)
    local climbing = Rhythm.Read(line, now)
    check(climbing.drift > 0.01 and climbing.high > climbing.usual and climbing.highAt and climbing.highAt > now and climbing.allDay,
        "a week of days going up: where it is heading, and a later day to sell: " .. tostring(climbing.drift))

    -- SaneUI's own scans after them: the line's stretches and sales its own, the weekdays and the usual prices of both
    local before = select(1, Days(21, Saturday))
    local after = start + 21 * DAY
    local own
    for step = 0, 2 * 8 - 1 do
        local at = after + step * HOURS * 3600 + 600
        own = Rhythm.Seen(own, at, (Hour(at) >= 18 and Hour(at) < 21 and 1400 or 1000) * Noise(0.04))
    end
    now = after + 2 * DAY + 1800
    own = Rhythm.Sold(own, now, 6, 6000)
    local joined = Rhythm.Join(own, before)
    local both = Rhythm.Read(joined, now, 2 * DAY, now)
    check(both.days > 22 and Rhythm.Since(joined) == Rhythm.Since(before) and both.daily == 3,
        "joined: watched since the earlier line began, the sales SaneUI saw: " .. tostring(both.daily))
    check(both.high > 1150 and date("*t", both.highAt).wday == 7, "the earlier days' Saturdays still name the day")
    check(Rhythm.Read(own, now, 2 * DAY, now).high == Rhythm.Read(own, now, 2 * DAY, now).usual, "(the scans alone: two days are too few)")
    check(math.abs(both.usual / Rhythm.Read(before, now).usual - 1) < 0.1, "the usual price goes on from the earlier one's")
    check(Rhythm.Join(own, nil) == own and Rhythm.Join(nil, before) == before and Rhythm.Join(before, own) == before,
        "nothing earlier: the line as it was; no line: the earlier one; an earlier one that is not earlier: the line")
end

-------------------------------------------------------------------------------
--  Counts and discoveries shared with the guild and the group (Bundle.lua), through a wire that only writes down
-------------------------------------------------------------------------------
do
    local Bundle, Drops, Relay, Tally, Wire, Prices = Data.Bundle, Data.Drops(), Data.Relay, Data.Tally, Core.Wire, Data.Series("Prices")
    local sendBlock, blocks = Wire.SendBlock, {}
    Wire.SendBlock = function(kind, text, channel, target, tag)
        blocks[#blocks + 1] = { kind = kind, text = text, channel = channel, target = target, tag = tag }
        return true
    end
    local inGuild, inside = rawget(_G, "IsInGuild"), rawget(_G, "IsInInstance")
    rawset(_G, "IsInGuild", function() return true end)
    rawset(_G, "IsInInstance", function() return false end)
    local shared = SaneUIData_Shared.forever
    local own, build = Tally.Id()
    local ROW, ENTRY = "\029", "\028"
    local a, b, c, d, e = ("a"):rep(16), ("b"):rep(16), ("c"):rep(16), ("d"):rep(16), ("e"):rep(16)
    -- A member's block, heard at its time; Raw: whenever this clock stands.
    local function Raw(sender, id, at, ...)
        Bundle.Block(sender, table.concat({ table.concat({ id, build, at }, "\031"), ... }, ROW), "GUILD")
    end
    local function Told(sender, id, at, ...)
        W.clock = W.clock + math.max(at - GetServerTime(), 0)
        Raw(sender, id, at, ...)
    end
    local function Row(loots, times, units, item)
        return ("c\031gather\0310\031%d"):format(loots) .. (times > 0 and ("\030d\031gather\031%d\0310\031%d\031%d"):format(item or 777, times, units or times) or "")
    end
    local function Line(key, row) return "c" .. ENTRY .. key .. ENTRY .. row end
    local market = SaneUIData_Market.forever
    local function Strikes(sender)
        local entry = market.strikes[sender]
        return entry and entry.count or 0
    end
    local now = GetServerTime()

    -- Sending: what was counted, once; nothing with nothing new; never in a fight or an instance, nor with the switch off
    Tally.Sent(Tally.All())
    Bundle.Tick()
    check(#blocks == 0, "an account that counted nothing says nothing")
    Tally.Loot("object:500", "gather", 0)
    Tally.Drop("object:500", "gather", 777, 0, 2)
    Tally.Visit("object:500", "gather")
    Core.general.shareData = false
    Bundle.Tick()
    check(#blocks == 0, "the switch off: nothing goes")
    Core.general.shareData = nil
    rawset(_G, "IsInInstance", function() return true end)
    Bundle.Tick()
    check(#blocks == 0, "inside an instance it waits")
    rawset(_G, "IsInInstance", function() return false end)
    Bundle.Tick()
    local sent = blocks[1]
    check(sent and sent.kind == "B" and sent.channel == "GUILD" and sent.tag == "bundle" and not sent.target
        and sent.text:find("^" .. own .. "\031" .. build .. "\031%d+\029"), "a bundle: its block's id, build and time, on the guild's channel")
    check(sent.text:find("c\028object:500\028", 1, true), "with the key's totals")
    blocks = {}
    Bundle.Tick()
    check(#blocks == 0, "told once: nothing more until something is counted")
    Tally.Loot("object:500", "gather", 0)
    Tally.Loot("object:501", "gather", 0)
    Bundle.Tick()
    check(#blocks == 1 and blocks[1].text:find("object:501", 1, true), "what was counted since")
    blocks = {}

    -- A long row never holds the others back, and what stands still is told in turn, behind what is new
    for index = 1, 40 do Tally.Loot("object:" .. (600 + index), "gather", 0) end
    Tally.Sent(Tally.All())
    Tally.Loot("object:601", "gather", 0)
    local rows, chosen = Tally.Bundle(120, 100)
    check(chosen["object:601"] and rows[1][1] == "object:601" and #rows > 1, "room left goes to the others in turn")
    local later = Tally.Bundle(120, 100)
    check(later[2] and later[2][1] ~= rows[2][1], "and the next time to the next ones")
    Tally.Sent(chosen)

    -- Taking: apart from the player's own, the newest total of a block replacing the last
    Told("Two", a, now, Line("object:900", Row(10, 1)))
    check(not Tally.Of("drops", "object:900") and Drops:Of("object:900")[1].loots == 10, "a member's counts in the views, apart from your own")
    Tally.Loot("object:900", "gather", 0)
    check(Drops:Of("object:900")[1].loots == 11, "added to your own")
    Told("Two", a, now + Bundle.SOONEST, Line("object:900", Row(20, 2)))
    local entry = Drops:Of("object:900")[1]
    check(entry.loots == 21 and entry.drops == 2, "the same block's newer total replaces the older: nothing counted twice")
    Told("Two Alt", a, now + Bundle.SOONEST + 1, Line("object:900", Row(21, 2)))
    check(Drops:Of("object:900")[1].loots == 21 and Strikes("Two Alt") == 0,
        "the id belongs to the member first heard with it: another name under it is passed over, without a strike (an account's other character speaks through the first)")
    Told("Mal", a, now + 2 * Bundle.SOONEST, Line("object:900", Row(1000, 2)))
    Told("Two", a, now + 3 * Bundle.SOONEST, Line("object:900", Row(22, 2)))
    check(Drops:Of("object:900")[1].loots == 23 and Strikes("Two") == 0,
        "so nobody can plant counts under a member's id: its honest totals stand, and earn it no strike")
    SaneUIData_Market = { forever = { houses = {}, mine = { Two = true, ["Two Alt"] = true } } }
    Prices.Account()
    Told("Two Alt", a, now + 4 * Bundle.SOONEST, Line("object:900", Row(24, 2)),
        table.concat({ "f", "Quests", "966", "name", build .. "\t20000\tAn Alt's Rumour" }, ENTRY))
    check(Drops:Of("object:900")[1].loots == 25 and Data.Set("Quests"):Get(966) and Data.Set("Quests"):Get(966).name == "An Alt's Rumour",
        "this player's other character under the id: one voice, the newer totals replace, and its facts are taken")
    Told("Mal", a, now + 5 * Bundle.SOONEST, Line("object:900", Row(1000, 2)),
        table.concat({ "f", "Quests", "967", "name", build .. "\t20000\tA Rumour" }, ENTRY))
    local waits = shared.facts["Quests\031967\031\tA Rumour"]
    check(Drops:Of("object:900")[1].loots == 25 and waits and waits.by.Mal, "a stranger under it: its counts passed over, its facts read (they wait for three, by name, like any)")
    Prices.Clear()
    check(Tally.Keys(777)["object:900"] and #Drops:From(777) >= 2, "who gives an item, members' counts too")
    Told("Three", b, now, Line("object:901", Row(5, 1)))
    check(Drops:Of("object:901", "period")[1].loots == 5, "this build's, by itself")
    Bundle.Block("Four", table.concat({ table.concat({ c, build - 1, now }, "\031"), Line("object:902", Row(5, 1)) }, ROW), "GUILD")
    Bundle.Block("Four", table.concat({ table.concat({ own, build, now }, "\031"), Line("object:902", Row(5, 1)) }, ROW), "GUILD")
    Bundle.Block("Four", table.concat({ table.concat({ c, build, now }, "\031"), Line("object:902", Row(5, 1)) }, ROW), "WHISPER")
    check(#Drops:Of("object:902") == 0, "another build's period, this account's own block, a whisper: not taken")
    Core.general.shareData = false
    Told("Five", c, now, Line("object:902", Row(5, 1)))
    Core.general.shareData = nil
    check(#Drops:Of("object:902") == 0, "the switch off: nothing taken")

    -- Hostile members: a strike for each, three and they are not heard, and what they sent is gone
    local function Hostile(what, ...)
        local before = Strikes("Bad")
        Raw("Bad", d, ...)
        check(Strikes("Bad") == before + 1 or (before == 2 and Strikes("Bad") == 0), what)
    end
    Told("Bad", d, now, Line("object:903", Row(10, 1)))
    check(Drops:Of("object:903")[1].loots == 10, "a fair start")
    Hostile("two bundles too soon: a strike", now + 60, Line("object:903", Row(11, 1)))
    Hostile("a time ahead of this clock: a strike", GetServerTime() + Bundle.AHEAD + Bundle.SOONEST, Line("object:903", Row(11, 1)))
    check(Drops:Of("object:903")[1].loots == 10, "what came with them not taken")
    W.clock = W.clock + 2 * Bundle.SOONEST
    Hostile("more drops than loots: a strike", GetServerTime(), Line("object:903", Row(10, 11)))
    check(Relay.Ignored("Bad") and #Drops:Of("object:903") == 0, "three strikes: not heard, and what it sent taken out")
    Told("Bad", e, now + 9 * Bundle.SOONEST, Line("object:903", Row(10, 1)))
    check(#Drops:Of("object:903") == 0, "nor taken afterwards")
    local function Off(what, ...)
        market.strikes.Worse = nil
        Told("Worse", e, now + 12 * Bundle.SOONEST, ...)
        check(Strikes("Worse") == 1, what)
    end
    Told("Worse", e, now + 10 * Bundle.SOONEST, Line("object:904", Row(100, 1)))
    Off("a total that shrinks: a strike", Line("object:904", Row(50, 1)))
    Off("a total that grows faster than anybody can loot: a strike", Line("object:904", Row(2000 + 100, 1)))
    Off("a key of no known kind: a strike", Line("player:1", Row(1, 1)))
    Off("a way of no known kind: a strike", Line("object:905", "c\031stolen\0310\0311"))
    Off("a record cut short: a strike", Line("object:905", "d\031gather\031777"))
    Off("a number that is none: a strike", Line("object:905", "c\031gather\0310\031nan"))
    Off("a line of no known kind: a strike", "x" .. ENTRY .. "object:905")
    market.strikes.Worse = nil
    Bundle.Block("Worst", "no bundle at all", "GUILD")
    check(Strikes("Worst") == 1 and Relay.Strike ~= nil and Data.Relay.Strike == Relay.Strike,
        "no head: a strike, through Relay.Strike (exported before Bundle.lua reads it)")
    market.strikes.Worst = nil
    -- A block of learned rows (Confirm.lua) off its shape: a key that is no number, or more rows than it may hold: the rest
    -- passed over, a strike (the wire's packing: the stand-in of the part Verified)
    local function Hex(text) return (text:gsub(".", function(c) return ("%02x"):format(c:byte()) end)) end
    local function Rows(sender, ...)
        local text = table.concat({ ... }, ROW)
        local encoded, transfer = Hex("Z" .. text), math.random(9999)
        local parts = math.ceil(#encoded / Wire.PART)
        for part = 1, parts do -- in parts, as the wire cuts a block (a message holds 255 bytes)
            Wire.Take(("P1\tf\tL\t%d\t%d\t%d\t%s\t%s"):format(transfer, part, parts, part == 1 and #text or "",
                encoded:sub((part - 1) * Wire.PART + 1, part * Wire.PART)), "GUILD", sender)
        end
    end
    local function Row4500(day) return "Items" .. ENTRY .. "4500" .. ENTRY .. "70245\t" .. day .. "\tLinen Shirt\t1\t\t\t\t\tITEM_MOD_STAMINA_SHORT\0314" end
    Rows("Nan Key", "Items" .. ENTRY .. "nan" .. ENTRY .. "70245\t30000\tLinen Shirt\t1", Row4500(30001))
    check(Strikes("Nan Key") == 1 and not (Data.Taken("Items", 4500) or ""):find("\t30001\t", 1, true),
        "a key that is no number: a strike, and the rows after it passed over")
    local many = {}
    for index = 1, Data.Confirmations.ROWS + 1 do many[index] = Row4500(30100 + index) end
    Rows("Too Many", unpack(many))
    check(Strikes("Too Many") == 1 and (Data.Taken("Items", 4500) or ""):find("\t30108\t", 1, true)
        and not (Data.Taken("Items", 4500) or ""):find("\t30109\t", 1, true), "more rows than a block may hold: the first taken, the rest passed over, a strike")
    market.strikes["Nan Key"], market.strikes["Too Many"] = nil, nil

    -- Summed robustly: a member far from everybody else left out, none over a quarter, the player's own accounts whole
    local function Voices(key, ...)
        for index, voice in ipairs({ ... }) do Told("Voice" .. index, (("%x"):format(index)):rep(16), now + index, Line(key, voice)) end
    end
    Voices("object:910", Row(100, 50), Row(100, 52), Row(100, 48), Row(100, 100))
    entry = Drops:Of("object:910")[1]
    check(entry.loots == 300 and entry.drops == 150, "a member's chance far from everybody else's, with enough loots to be sure: left out")
    Voices("object:911", Row(100, 50), Row(100, 50), Row(100, 50), Row(9700, 4850))
    entry = Drops:Of("object:911")[1]
    check(entry.loots == 300 + 2500 and entry.drops == 150 + 1250, "with four voices none makes up more than a quarter")
    SaneUIData_Market = { forever = { houses = {}, mine = { Voice4 = true } } }
    Prices.Account()
    check(Prices.Mine("Voice4") and not Prices.Mine("Voice3"), "this player's other accounts, from their auction files")
    entry = Drops:Of("object:911")[1]
    Tally.stamp = Tally.stamp + 1
    entry = Drops:Of("object:911")[1]
    check(entry.loots == 10000 and entry.drops == 5000, "their counts count whole, as your own do")
    Tally.stamp = Tally.stamp + 1

    -- Facts: a row learned here goes along; a member's waits for three, what the player saw wins, nothing is passed on
    local Quests = Data.Set("Quests")
    Data.Check("Quests", 950, { name = "New Road" })
    Tally.Loot("object:500", "gather", 0)
    blocks = {}
    Bundle.Tick()
    local fact = blocks[1] and blocks[1].text:find("f\028Quests\028950\028name\028", 1, true)
    check(fact, "a quest learned here told in the bundle, with what the game told of it")
    blocks = {}
    Tally.Loot("object:500", "gather", 0)
    Bundle.Tick()
    check(not blocks[1].text:find("Quests", 1, true), "once")
    blocks = {}
    local function Fact(sender, key, at, row)
        -- each sender's own block id (an id belongs to the member first heard with it)
        Told(sender, ("%02x"):format(sender:byte(1)):rep(8), at,
            table.concat({ "f", "Quests", key, "name", row or (build .. "\t20000\tA Rumour") }, ENTRY))
    end
    Fact("Ann", 960, now + 20 * Bundle.SOONEST)
    check(not Quests:Get(960), "one sender: it waits, and no view has it")
    Fact("Ann", 960, now + 21 * Bundle.SOONEST)
    check(not Quests:Get(960), "the same sender again is no second")
    Fact("Bob", 960, now + 20 * Bundle.SOONEST)
    check(not Quests:Get(960), "two senders: it waits")
    Fact("Cid", 960, now + 20 * Bundle.SOONEST, build .. "\t20001\tA Rumour")
    check(Quests:Get(960) and Quests:Get(960).name == "A Rumour" and Data.Taken("Quests", 960) and not Data.Learned("Quests", 960),
        "three senders of the same (the day apart): taken, apart from what was learned here (never the harvest's)")
    local told = Data.ConfirmedParts("Quests", 960)
    check(told[1] == "name" and Data.Found()[1].how == "shared" and Data.Found()[1].key == 960, "with what the game told of it, a discovery that came from others")
    Tally.Loot("object:500", "gather", 0)
    Bundle.Tick()
    check(not blocks[1].text:find("960", 1, true), "what came from others is not passed on")
    blocks = {}
    Fact("Dan", 950, now + 20 * Bundle.SOONEST, build .. "\t20000\tNot That Road")
    Fact("Eve", 950, now + 20 * Bundle.SOONEST, build .. "\t20000\tNot That Road")
    Fact("Fay", 950, now + 20 * Bundle.SOONEST, build .. "\t20000\tNot That Road")
    check(Quests:Get(950).name == "New Road", "what the player saw wins")
    SaneUIData_Market = { forever = { houses = {}, mine = { Gil = true } } }
    Prices.Account()
    Fact("Gil", 961, now + 20 * Bundle.SOONEST)
    check(Quests:Get(961) and Quests:Get(961).name == "A Rumour", "from this player's other account: taken at once")
    Fact("Ivy", 962, now + 20 * Bundle.SOONEST, "no row")
    check(Strikes("Ivy") == 1, "what is no row: a strike")
    market.strikes.Ivy = nil
    Fact("Kim", 965, now + 20 * Bundle.SOONEST, build .. "\t20000\t" .. ("x"):rep(Bundle.LINE))
    check(Strikes("Kim") == 1 and shared.facts["Quests\031965\031\t" .. ("x"):rep(Bundle.LINE)] == nil,
        "a row longer than a line may be: a strike, and not kept")
    market.strikes.Kim = nil
    for index = 7, 9 do Told("Ids", tostring(index):rep(16), now + 20 * Bundle.SOONEST, Line("object:906", Row(1, 0))) end
    check(Strikes("Ids") == 1 and shared.counts[("9"):rep(16)] == nil, "a third block id under one name this build: a strike, and not kept")
    market.strikes.Ids = nil
    Fact("Jon", 963, now + 20 * Bundle.SOONEST, (build + 1) .. "\t20000\tFrom Ahead")
    check(not next(shared.facts, nil) or not shared.facts["Quests\031963\031\tFrom Ahead"], "a fact of another build: not kept")

    -- Forget shared data: all of it; your own stays, also what you learned yourself of an entry members once sent
    Data.Check("Quests", 961, { name = "Seen Here" })
    check(Data.Learned("Quests", 961) and not Data.Taken("Quests", 961), "an entry taken from members, then seen here: learned here, the member's row gone")
    local mineStill = Drops:Of("object:500")[1]
    SlashCmdList.SANEUI("data forget")
    check(not next(shared.counts) and not next(shared.facts) and not next(shared.taken) and shared.keys == 0, "/sane data forget: all that others sent")
    check(not Data.Taken("Quests", 960) and Data.Learned("Quests", 950) and Data.Learned("Quests", 961)
        and Drops:Of("object:500")[1].loots == mineStill.loots, "and only that: your own stay, the row learned here of what members once sent too")
    W.printed = {}
    SlashCmdList.SANEUI("data")
    Tally.Read("", nil)
    check(Tally.Read("") and not Tally.Read(7) and not Tally.Read("c\031gather\0310"), "a row read strictly")

    Wire.SendBlock = sendBlock
    rawset(_G, "IsInGuild", inGuild)
    rawset(_G, "IsInInstance", inside)
end
os.execute(("rm -rf '%s' '%s'"):format(folder, lore))

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Data in the game: all %d checks passed.\n"):format(passed))
