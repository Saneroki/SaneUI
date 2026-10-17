local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Steps
--  One scheduler for the long work of Core's data framework: loading packs, a walk over a set, later the
--  auction scan's reading, shared data taken in, the characters, the crawl; and of Core's other long work
--  (Sync's finding of the game's CVars). A job is a coroutine that does a piece of work, then asks
--  Steps.Check whether the frame's time is spent; if it is, the job yields and goes on in the next frame.
--  All jobs together get at most 5 ms a frame, and never more than a quarter of a frame at the current
--  frame rate, so a slower computer takes more frames, no frame more time. Nothing runs in a fight or while
--  the game restricts addons (Core.Restricted). (Doc/guides/data.md, *The scheduler: jobs*.)
--
--      local job = Core.Steps.Run("walk", function(rows)
--          for key in pairs(rows) do Work(key); Core.Steps.Check() end
--      end, rows)
--      job:Stop()                             -- or Core.Steps.Stop("walk"): it never goes on
--
--  Options in place of the name: Core.Steps.Run({ name = "walk", priority = true, done = Done, error = Failed,
--  label = "..." }, fn, ...). A job with priority is served first in every frame; done(problem) is told when
--  it ended, after its last step (problem nil) or an error (its text); error(problem) only after an error;
--  label is what a failure is noted under (else "data job <name>"). A job that was stopped is told nothing.
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

local jobs = {}       -- the jobs, in the order they were started; each is its own handle (Job, below)
local named = {}      -- [name] = job
local turn = 0        -- the job served last, so each gets its turn first in some frame
local current         -- the job running now
local started = 0     -- debugprofilestop() when this frame's work began
local limit = 0       -- this frame's budget, in milliseconds
local spent = false   -- this frame's time is used: the budget, or a job's Spend
local worked = false  -- a job ran in this frame (for Fresh)
local alone = false   -- the job running now was the first to run in this frame
local round = 0       -- the frames worked in, counted: a job is served once in a frame

local frame = CreateFrame("Frame")
frame:Hide()
Steps.frame = frame -- the scheduler's frame: shown, with its OnUpdate, only while there is work (the tests drive it)
local Step -- its OnUpdate, below

-- A job's handle: name, ms (the milliseconds it worked so far), frames (how many it worked in), priority.
local Job = {}
Job.__index = Job

local function Budget()
    local rate = GetFramerate()
    if type(rate) == "number" and rate > 0 then return math.min(Steps.BUDGET, 1000 / rate * Steps.SHARE) end
    return Steps.BUDGET
end

-- No OnUpdate at rest: the frame has one only while there is work and nothing holds it back.
local function Sleep()
    frame:Hide()
    frame:SetScript("OnUpdate", nil)
end

local function Wake()
    if #jobs > 0 and not Core.Restricted() then
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
    if named[job.name] == job then named[job.name] = nil end
    if #jobs == 0 then Sleep() end
end

-- A job ended by its last step (problem nil) or an error: gone, and told, outside its coroutine (Check
-- returns at once there; a new job may be started). One that was stopped first is told nothing.
local function End(job, problem)
    if job.over then return end
    job.over = true
    Remove(job)
    if problem ~= nil and job.error then Core.Safe(job.label, job.error, problem) end
    if job.done then Core.Safe(job.label, job.done, problem) end
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
    local before = debugprofilestop()
    local ok, problem
    if job.args then
        local args, count = job.args, job.count
        job.args = nil
        ok, problem = coroutine.resume(job.thread, unpack(args, 1, count))
    else
        ok, problem = coroutine.resume(job.thread)
    end
    current, worked = nil, true
    job.ms, job.frames = job.ms + debugprofilestop() - before, job.frames + 1
    if not ok then
        problem = tostring(problem)
        Core.Report(job.label, problem .. Where(job.thread))
        End(job, problem)
    elseif coroutine.status(job.thread) == "dead" then
        End(job, nil)
    end
end

-- One job's next piece in this frame.
local function Serve(job)
    job.round, job.fresh = round, false
    Resume(job)
    if debugprofilestop() - started >= limit then spent = true end
end

-- Not served in this frame yet, and not a job that waits for a frame of its own after another one worked.
local function Due(job)
    return job.round ~= round and not (job.fresh and worked)
end

function Step()
    if Core.Restricted() then
        Sleep()
        return
    end
    round = round + 1
    started, limit, spent, worked = debugprofilestop(), Budget(), false, false
    -- A job that waits for a frame of its own (Fresh) goes first; then the jobs with priority, in the order
    -- they were started; then the others, each in its turn.
    for _, job in ipairs(jobs) do
        if job.fresh then
            Serve(job)
            break
        end
    end
    local index = 1
    while not spent and jobs[index] do
        local job = jobs[index]
        if job.priority and Due(job) then Serve(job) end
        if jobs[index] == job then index = index + 1 end -- else it ended: the next one stands in its place
    end
    local served, count = 0, #jobs
    while not spent and #jobs > 0 and served < count do
        turn = turn % #jobs + 1
        local job = jobs[turn]
        served = served + 1
        if Due(job) then Serve(job) end
    end
end

-- Starts a job: fn(...) as a coroutine; name, or the options (above). Gives its handle; a job of the same
-- name is not started twice: then false.
function Steps.Run(name, fn, ...)
    local options = type(name) == "table" and name or nil
    if options then name = options.name end
    assert(name ~= nil, "a job needs a name")
    if named[name] then return false end
    local job = setmetatable({ name = name, thread = coroutine.create(fn), args = { ... }, count = select("#", ...),
        label = options and options.label or "data job " .. tostring(name), priority = options and options.priority and true or nil,
        done = options and options.done, error = options and options.error, ms = 0, frames = 0 }, Job)
    jobs[#jobs + 1] = job
    named[name] = job
    Wake()
    return job
end

-- Stops the job: it never goes on, and is told nothing. Also from inside the job (it runs on to its next
-- Check, Fresh or Spend). False if it is over already.
function Job:Stop()
    if self.over then return false end
    self.over = true
    Remove(self)
    return true
end

function Job:Running()
    return not self.over
end

function Steps.Stop(name)
    local job = named[name]
    return job ~= nil and job:Stop()
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

-- The jobs running, their handles in the order they were started (for /sane data: name, ms, frames).
function Steps.Jobs()
    local list = {}
    for index, job in ipairs(jobs) do list[index] = job end
    return list
end

-- Whether the jobs wait now: a fight, or a restriction of the game's (Core.Restricted).
function Steps.Paused()
    return Core.Restricted()
end

-- Nothing in a fight or under a restriction; the jobs go on after. Core.lua hears the restriction's event
-- first (its file is read before this one), so Core.Restricted says already what began or ended: the game
-- itself answers false while the event is sent.
Core.On("PLAYER_REGEN_DISABLED", Sleep)
Core.On("PLAYER_REGEN_ENABLED", Wake)
Core.On("ADDON_RESTRICTION_STATE_CHANGED", function()
    if Core.Restricted() then Sleep() else Wake() end
end)
