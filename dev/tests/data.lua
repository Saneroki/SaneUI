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

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Data in the game: all %d checks passed.\n"):format(passed))
