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
check(Data.Add(1, "Beta", Header("forever-beta")) == nil and select(2, Data.Set("Beta"):State()):find("made for forever%-beta"),
    "a set file of another game version: nil, refused")
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
check(printedMatch("Labels %x+, ") and printedMatch("Newer %(not used: of format 2") and printedMatch("Broken %(missing: Sane UI holds no set Broken%)"),
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
check(printedMatch("^|c%x+Sane UI:|r   1%.60%.0: sell 120 %-> 110%.$") and printedMatch("1%.60%.2: rare empty %-> true%.")
    and printedMatch("1%.60%.0: stats { agi = 2, sta = 3 } %-> { agi = 1, sta = 3 }%."), "/sane data show: what changed, by patch")
check(printedMatch("Gear 100: { from = { 1, 2 }, name = Plain Gloves,") and printedMatch("Labels with space: { label = SPACED, since = 0 }%.")
    and printedMatch("Gear has no 999%.") and printedMatch("/sane data show <set> <key>"), "/sane data show prints an entry")
W.printed = {}
SlashCmdList.SANEUI("data show Nowhere 1")
check(printedMatch("Nowhere is missing %(Sane UI holds no set Nowhere%)%.$"), "a set Core does not hold")
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
check(printedMatch("kept in the game: Characters %d+ values, Fresh 0 values, Kept 1 values, Learned 1 values%."),
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
            .. 'if not S then return end\nS.rows[1] = "65000\\t\\tcave\\tThe Hole\\t1429\\03150\\03150"\n',
        ["Spawns.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Spawns", { game = "forever", hash = "0000000d", build = 65000, key = "text", fields = { "points" }, types = { "list point" }, patches = {} })\n'
            .. 'if not S then return end\nS.rows["object:1617"] = "65000\\t\\t1429\\03110\\03120"\n' }))
    for _ = 1, 6 do Frame() end
    local spot = Map:Spawns("object:1617")
    check(walks == 1 and #Map:On(1429) == 2 and spot and spot[1429][1][1] == 0.1, "two sets arriving together: read once")
    -- The objects' facts arrive: the map is read anew, and until that read is done the last one's points stay
    W.AddSets(MakeSets("Things", { ["Objects.lua"] = 'local S = SaneUI.Core.Data.Add(1, "Objects", { game = "forever", hash = "0000000e", build = 65000, key = "int", fields = { "name", "kind" }, types = { "text", "text" }, patches = {} })\n'
        .. 'if not S then return end\nS.rows[1617] = "65000\\t\\tPeacebloom\\therb"\n' }))
    Frame()
    W.Wait(0) -- told: read anew, its walks still to come
    check(walks == 2 and Map:Spawns("object:1617") == spot, "while the map is read anew, the last read's points stay")
    for _ = 1, 6 do Frame() end
    local herb
    for _, place in ipairs(Map:On(1429)) do herb = herb or place.what == "herb" and place end
    check(herb and herb.name == "Peacebloom" and Map:Spawns("object:1617") ~= spot and Map:Spawns("object:1617")[1429][1][2] == 0.2,
        "then the new read's: the object named, a herb")
    Spawns.Each = nil
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
os.execute(("rm -rf '%s' '%s'"):format(folder, lore))

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Data in the game: all %d checks passed.\n"):format(passed))
