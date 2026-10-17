local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Steps
--  One scheduler for the long work of Core's data framework: loading packs, a walk over a set, later the
--  auction scan's reading, shared data taken in, the characters, the crawl. A job is a coroutine that does
--  a piece of work, then asks Steps.Check whether the frame's time is spent; if it is, the job yields and
--  goes on in the next frame. All jobs together get at most 5 ms a frame, and never more than a quarter of
--  a frame at the current frame rate, so a slower computer takes more frames, no frame more time. Nothing
--  runs in combat or while the game restricts addons. (Doc/guides/data.md, *The scheduler: jobs*.)
--
--      Core.Steps.Run("walk", function(rows)
--          for key in pairs(rows) do Work(key); Core.Steps.Check() end
--      end, rows)
--
--  A job never yields inside pcall, xpcall or Core.Safe: Lua 5.1 cannot, the yield fails into the pcall,
--  and the job runs on past its budget without a word. coroutine.resume is each job's own guard: an error
--  drops that job (reported), and the others go on.
-------------------------------------------------------------------------------
local Steps = {}
Core.Steps = Steps

Steps.BUDGET = 5    -- milliseconds a frame for all jobs together
Steps.SHARE = 0.25  -- and never more than this share of a frame at the current frame rate
Steps.ALONE = 0.5   -- milliseconds a job may have worked in a frame and still count as alone in it (Fresh)
-- The restrictions under which nothing runs (Enum.AddOnRestrictionType): combat, an encounter, a challenge
-- mode, a PvP match, a map that restricts addons. Not chat: that only limits addon messages.
local PAUSING = { 0, 1, 2, 3, 4 }

local jobs = {}       -- the jobs, in the order they were started: { name, thread, args, count, fresh }
local named = {}      -- [name] = job
local turn = 0        -- the job served last, so each gets its turn first in some frame
local current         -- the job running now
local started = 0     -- debugprofilestop() when this frame's work began
local limit = 0       -- this frame's budget, in milliseconds
local spent = false   -- this frame's time is used: the budget, or a job's Spend
local worked = false  -- a job ran in this frame (for Fresh)
local alone = false   -- the job running now was the first to run in this frame

local frame = CreateFrame("Frame")
frame:Hide()
Steps.frame = frame -- the scheduler's frame: shown, with its OnUpdate, only while there is work (the tests drive it)
local Step -- its OnUpdate, below

local function Restricted()
    local api = C_RestrictedActions
    if not (api and api.IsAddOnRestrictionActive) then return false end
    for _, kind in ipairs(PAUSING) do
        if Core.Ask(api.IsAddOnRestrictionActive, kind) then return true end
    end
    return false
end

local function Paused()
    return InCombatLockdown() or Restricted()
end

local function Budget()
    local rate = Core.Ask(GetFramerate)
    if type(rate) == "number" and rate > 0 then return math.min(Steps.BUDGET, 1000 / rate * Steps.SHARE) end
    return Steps.BUDGET
end

-- No OnUpdate at rest: the frame has one only while there is work and nothing holds it back.
local function Sleep()
    frame:Hide()
    frame:SetScript("OnUpdate", nil)
end

local function Wake()
    if #jobs > 0 and not Paused() then
        frame:SetScript("OnUpdate", Step)
        frame:Show()
    end
end

local function Remove(job)
    for index, known in ipairs(jobs) do
        if known == job then
            table.remove(jobs, index)
            if index <= turn then turn = turn - 1 end
            break
        end
    end
    named[job.name] = nil
    if #jobs == 0 then Sleep() end
end

-- The place a job failed, if the game can tell it (debugstack takes a coroutine in the client).
local function Where(thread)
    local stack = rawget(_G, "debugstack")
    if not stack then return "" end
    local ok, text = pcall(stack, thread)
    return ok and type(text) == "string" and "\n" .. text or ""
end

local function Resume(job)
    current, alone = job, not worked
    local ok, problem
    if job.args then
        local args, count = job.args, job.count
        job.args = nil
        ok, problem = coroutine.resume(job.thread, unpack(args, 1, count))
    else
        ok, problem = coroutine.resume(job.thread)
    end
    current, worked = nil, true
    if not ok then
        Core.Report("data job " .. job.name, tostring(problem) .. Where(job.thread))
        Remove(job)
    elseif coroutine.status(job.thread) == "dead" then
        Remove(job)
    end
end

function Step()
    if Paused() then
        Sleep()
        return
    end
    started, limit, spent, worked = debugprofilestop(), Budget(), false, false
    -- A job that waits for a frame of its own (Fresh) goes first.
    for index, job in ipairs(jobs) do
        if job.fresh then
            turn = index - 1
            break
        end
    end
    local served, count = 0, #jobs
    while not spent and #jobs > 0 and served < count do
        turn = turn % #jobs + 1
        local job = jobs[turn]
        served = served + 1
        if not (job.fresh and worked) then
            job.fresh = false
            Resume(job)
            if debugprofilestop() - started >= limit then spent = true end
        end
    end
end

-- Starts a job: fn(...) as a coroutine. A job of the same name is not started twice: then false.
function Steps.Run(name, fn, ...)
    if named[name] then return false end
    local job = { name = name, thread = coroutine.create(fn), args = { ... }, count = select("#", ...) }
    jobs[#jobs + 1] = job
    named[name] = job
    Wake()
    return true
end

-- In a job, between pieces of work: yields when the frame's time is spent, else returns at once.
-- Outside a job it does nothing.
function Steps.Check()
    if not current or coroutine.running() ~= current.thread then return end
    if debugprofilestop() - started >= limit then
        spent = true
        coroutine.yield()
    end
end

-- In a job: waits for a frame of its own, in which no other job ran before it.
function Steps.Fresh()
    if not current or coroutine.running() ~= current.thread then return end
    if alone and debugprofilestop() - started < Steps.ALONE then return end
    current.fresh = true
    coroutine.yield()
end

-- In a job: this frame's time is all used; nothing else runs in it. After Fresh, a step that cannot be cut
-- (loading a pack) runs alone in its frame.
function Steps.Spend()
    if not current or coroutine.running() ~= current.thread then return end
    spent = true
    coroutine.yield()
end

function Steps.Running(name)
    return named[name] ~= nil
end

-- The names of the jobs running, in the order they were started (for /sane data).
function Steps.Jobs()
    local names = {}
    for index, job in ipairs(jobs) do names[index] = job.name end
    return names
end

-- Nothing in combat or under a restriction; the jobs go on after.
Core.On("PLAYER_REGEN_DISABLED", Sleep)
Core.On("PLAYER_REGEN_ENABLED", Wake)
Core.On("ADDON_RESTRICTION_STATE_CHANGED", function()
    if Paused() then Sleep() else Wake() end
end)
