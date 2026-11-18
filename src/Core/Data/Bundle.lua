local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Bundle
--  Counts and discoveries shared with the guild and the group (Doc/ideas/Data.md, *Bundles*): every 15 minutes each member
--  that counted something tells what it counted and what it discovered, in one bundle, so that every player's loot adds
--  to the chances and a new quest reaches those who have not met it. An account that counted nothing says nothing.
--
--      counts    a key's totals of this build period, as Tally.lua keeps them: a newer total of the same block replaces
--                the older, so nothing counts twice, and two characters of one account are one voice (the block's id)
--      facts     a row Core learned here (Check.lua), with the parts the game told
--
--  A bundle is blocks of kind B: "id\031build\031at", then its lines, cut by \029: "c\028key\028row" and
--  "f\028set\028key\028parts\028row". Only the guild, the party and the raid; never in a fight, while the game restricts
--  addons, or inside an instance; what was not told waits in the saved file for the next bundle. What came from others
--  is not passed on.
--
--  No message is trusted (Doc/ideas/Data.md, *Poisoning*). Everything taken is kept apart from this player's own, in
--  SaneUIData_Shared, per sender, and can be taken out again (Data.ForgetShared). A line off its shape, a total that
--  shrinks or grows faster than anybody can loot, two bundles too soon, or more than Bundle.IDS block ids under one
--  name earns a strike (Relay.Strike). A block's id belongs to the member first heard with it: a block under it from
--  another name (an account's other character, or an impostor) is passed over, so nobody can plant counts under a
--  member's id and make its honest totals look false. Counts go into the views summed robustly (Drops.lua), and never
--  into the master: the harvest reads only SaneUIData_Learned's own rows. A fact waits until Bundle.SENDERS different
--  members sent the same; the player's other accounts (Prices.Mine) need no others, and what the player saw here always
--  wins; a row taken is kept apart (Data.LearnRow), its told parts as heard (Confirm.Heard), never passed on nor harvested.
--  The switch Share data with my guild and group turns all of it off.
-------------------------------------------------------------------------------
local Data, Wire, Codec = Core.Data, Core.Wire, Core.Data.Codec
local Tally, Prices, Relay, Confirmations = Data.Tally, Data.Series("Prices"), Data.Relay, Data.Confirmations

local Bundle = {}
Data.Bundle = Bundle
Bundle.EVERY = 15 * 60  -- seconds between two bundles of a member
Bundle.WAIT = 60        -- seconds before trying again while a fight, an instance or a restriction holds it
Bundle.BYTES = 6000     -- bytes of a block before it is packed: well under the wire's 4 KB packed
Bundle.BLOCKS = 2       -- blocks of a bundle at most
Bundle.LINE = 5000      -- bytes of a line at most
Bundle.FACTS = 20       -- facts in a bundle at most
Bundle.TOLD = 500       -- facts waiting to be told at most
Bundle.SOONEST = 14 * 60 -- seconds: a sender's two bundles no closer
Bundle.AHEAD = 300      -- seconds a bundle's time may lie ahead of this clock
Bundle.IDS = 2          -- block ids of this build period under one sender's name at most: its own, and one after a reset
Bundle.PACE = 1         -- loots a second of a way of one key, over a sender's two bundles, at most
Bundle.BURST = 30       -- ... and so many at once (many corpses looted together)
Bundle.KEYS = 5000      -- keys kept of one sender at most
Bundle.ALL = 20000      -- keys kept of all senders at most: Core's saved file must stay small (the guide, *Saved variables*)
Bundle.SENDERS = 3      -- different members who must send the same fact
Bundle.WAITING = 2000   -- facts waiting at most
Bundle.BY = 200         -- facts waiting from one sender at most
Bundle.STALE = 14       -- days a fact waits at most
Bundle.stamp = 0        -- grows with every change of what members told (Drops.lua's answers are made anew)

local KIND, TAG = "B", "bundle"
local PART, ENTRY, ROW = "\031", "\028", "\029"
local LIST = "\030"
-- The sets whose rows are shared this way. Items go their own way, checked by the game (Confirm.lua).
local SETS = { Quests = true, NPCs = true, Vendors = true, Spells = true }

local saved           -- this client's part of SaneUIData_Shared
local outgoing        -- ["set\031key"] = true: learned here, not told yet (in the saved file)
local times = {}      -- [sender] = the time of its last bundle heard
local Tick
local tick = Core.Later(function() Tick() end, Bundle.EVERY)
local soon = Core.Later(function() Tick() end, Bundle.WAIT)

local function Now()
    return Core.Ask(rawget(_G, "GetServerTime")) or 0
end

local function Whole(text)
    return type(text) == "string" and #text < 14 and text:match("^%d+$") and tonumber(text) or nil
end

local function Moved()
    Bundle.stamp = Bundle.stamp + 1
end

-------------------------------------------------------------------------------
--  Sending
-------------------------------------------------------------------------------
-- A learned row goes in the next bundle.
function Bundle.Note(set, key)
    if not (outgoing and SETS[set]) or saved.waiting >= Bundle.TOLD then return end
    local fact = set .. PART .. tostring(key)
    if not outgoing[fact] then saved.waiting = saved.waiting + 1 end
    outgoing[fact] = true
end

-- The bundle's lines: the counts, then the facts; and what to mark as told once it went.
local function Lines()
    local lines, facts = {}, {}
    local rows, chosen = Tally.Bundle(Bundle.BYTES * Bundle.BLOCKS, Bundle.LINE)
    for _, each in ipairs(rows or {}) do lines[#lines + 1] = "c" .. ENTRY .. each[1] .. ENTRY .. each[2] end
    for fact in pairs(outgoing) do
        if #facts >= Bundle.FACTS then break end
        local set, key = fact:match("^(.-)\031(.*)$")
        local row = Data.Learned(set, tonumber(key) or key)
        if row and #row <= Bundle.LINE then -- with the parts the game told here, none a member told (never passed on)
            lines[#lines + 1] = table.concat({ "f", set, key, table.concat(Confirmations.ToldParts(set, tonumber(key) or key), LIST), row }, ENTRY)
        end
        facts[#facts + 1] = fact
    end
    return lines, chosen, facts
end

-- The lines cut into blocks, each with the head; false when the wire had no room for one.
local function Send(lines, head, channels)
    local text, size, sent = { head }, #head, true
    local function Close()
        for _, channel in ipairs(channels) do
            sent = Wire.SendBlock(KIND, table.concat(text, ROW), channel, nil, TAG) and sent
        end
        text, size = { head }, #head
    end
    for _, line in ipairs(lines) do
        if size + #line > Bundle.BYTES and #text > 1 then Close() end
        text[#text + 1] = line
        size = size + #line
    end
    Close()
    return sent
end

-- The turn of a bundle: every Bundle.EVERY seconds, sooner again while something holds it back.
function Tick()
    if not (saved and Data.Sharing()) then return tick() end
    if Data.Confirmations.Held() then return soon() end
    tick()
    local channels = Relay.Channels()
    if #channels == 0 then return end
    local lines, chosen, facts = Lines()
    if #lines == 0 then return end
    local id, build = Tally.Id()
    if not id then return end
    if not Send(lines, table.concat({ id, build, Now() }, PART), channels) then return end
    Tally.Sent(chosen)
    for _, fact in ipairs(facts) do outgoing[fact] = nil end
    saved.waiting = saved.waiting - #facts
end
Bundle.Tick = function() Tick() end

-------------------------------------------------------------------------------
--  Taking in
-------------------------------------------------------------------------------
-- A key's row from a block of a member. False for what no honest count could be.
local function Counted(block, since, key, row)
    if not (key:match("^npc:%d+$") or key:match("^object:%d+$") or key:match("^zone:%d+$")) or #row > Bundle.LINE then return false end
    local read = Tally.Read(row)
    if not read then return false end
    local old = block.drops[key] and Tally.Read(block.drops[key])
    if old then
        for way, loots in pairs(old.loots) do
            if (read.loots[way] or 0) < loots then return false end
        end
        local most = since * Bundle.PACE + Bundle.BURST
        for way, loots in pairs(read.loots) do
            if loots - (old.loots[way] or 0) > most then return false end
        end
    elseif block.size >= Bundle.KEYS or saved.keys >= Bundle.ALL then
        return true -- no room: not held against the sender
    else
        block.size, saved.keys = block.size + 1, saved.keys + 1
    end
    block.drops[key] = row
    Tally.Indexed(key, row)
    return true
end

local function Waiting(sender)
    local all, own = 0, 0
    for _, fact in pairs(saved.facts) do
        all = all + 1
        if fact.by[sender] then own = own + 1 end
    end
    return all, own
end

-- What the game's own data took from others: the row apart (Data.LearnRow, at most Confirm.KEPT a set), its told parts
-- as heard (never the harvest's, never sent on).
local function Accept(set, key, row, parts)
    local current = Data.Set(set):Get(key)
    if not Data.LearnRow(set, key, row, function() return true end, Confirmations.KEPT) then return end
    local told = parts ~= "" and Codec.Cut(parts, LIST) or {}
    for _, part in ipairs(told) do Confirmations.Heard(set, key, part) end
    saved.taken[set .. PART .. tostring(key)] = true
    Data.Discovered(set, key, current and "changed" or "new", told, "shared")
    local start = set .. PART .. tostring(key) .. PART
    for text in pairs(saved.facts) do
        if text:sub(1, #start) == start then saved.facts[text] = nil end
    end
end

-- A fact from a member: told by enough of them, or by this player's other account, it is taken; else it waits.
local function Fact(sender, set, keyText, parts, row, build)
    if #row > Bundle.LINE then return false end
    local key = Whole(keyText)
    local built, body = row:match("^(%d+)\t%d*(.*)$")
    if not (key and built) then return false end
    if not SETS[set] or not Data.Set(set):Ready() or tonumber(built) ~= build then return true end
    if Data.Learned(set, key) then return true end -- what the player saw wins
    local mine = Prices.Mine(sender)
    local text = set .. PART .. key .. PART .. body
    local fact = saved.facts[text]
    if not fact then
        local all, own = Waiting(sender)
        if not mine and (all >= Bundle.WAITING or own >= Bundle.BY) then return true end
        fact = { by = {}, day = math.floor(Now() / 86400) }
        saved.facts[text] = fact
    end
    fact.by[sender] = true
    local senders = 0
    for _ in pairs(fact.by) do senders = senders + 1 end
    if mine or senders >= Bundle.SENDERS then Accept(set, key, row, parts) end
    return true
end

-- A block whole.
function Bundle.Block(sender, text, channel)
    if channel == "WHISPER" or not (saved and Data.Sharing()) or Relay.Ignored(sender) then return end
    local rows = Codec.Cut(text, ROW)
    local head = Codec.Cut(rows[1], PART)
    local id, build, at = head[1], Whole(head[2]), Whole(head[3])
    if #head ~= 3 or not (id and id:match("^%x+$") and #id == 16 and build and at) then return Relay.Strike(sender) end
    if at > Now() + Bundle.AHEAD then return Relay.Strike(sender) end
    local own, period = Tally.Id()
    if id == own or build ~= period then return end -- this account's own block; another build's period
    local last = times[sender]
    if last and last ~= at and math.abs(last - at) < Bundle.SOONEST then return Relay.Strike(sender) end
    times[sender] = at
    local block = saved.counts[id]
    -- The id belongs to the member first heard with it (the top); this player's other character under it (Prices.Mine) is
    -- one voice with it, its newer totals replace; a stranger's counts under it are passed over, its facts read all the
    -- same (they wait for Bundle.SENDERS members, by name, like any)
    local stranger = block ~= nil and block.from ~= sender and not Prices.Mine(sender)
    if not block then
        local owned = 0
        for _, each in pairs(saved.counts) do
            if each.from == sender and each.build == build then owned = owned + 1 end
        end
        if owned >= Bundle.IDS then return Relay.Strike(sender) end
        block = { build = build, at = at, size = 0, drops = {}, from = sender }
        saved.counts[id] = block
    end
    local since = math.max(at - block.at, 0)
    if not stranger then block.from, block.at = sender, at end
    for index = 2, #rows do
        local fields = Codec.Cut(rows[index], ENTRY)
        local fair
        if fields[1] == "c" and #fields == 3 then
            fair = stranger or Counted(block, since, fields[2], fields[3])
        elseif fields[1] == "f" and #fields == 5 then
            fair = Fact(sender, fields[2], fields[3], fields[4], fields[5], period)
        end
        if not fair then
            Moved()
            return Relay.Strike(sender)
        end
    end
    Moved()
end

-------------------------------------------------------------------------------
--  Reading
-------------------------------------------------------------------------------
-- What the members counted of a key, one voice for each block (Drops.lua): Tally.Read's counts, with mine for this player's
-- other accounts. period: only this build's.
function Bundle.Voices(key, period)
    local voices = {}
    if not saved then return voices end
    local _, build = Tally.Id()
    for _, block in pairs(saved.counts) do
        local row = block.drops[key]
        if row and (not period or block.build == build) then
            local voice = Tally.Read(row)
            if voice then
                voice.mine = Prices.Mine(block.from)
                voices[#voices + 1] = voice
            end
        end
    end
    return voices
end

-- fn(key, row) for every row the members told.
function Bundle.Each(fn)
    for _, block in pairs(saved and saved.counts or {}) do
        for key, row in pairs(block.drops) do fn(key, row) end
    end
end

-- What one member sent taken out, its waiting facts too; with no sender, what all sent, and the rows taken from them.
function Bundle.Forget(sender)
    if not saved then return end
    for id, block in pairs(saved.counts) do
        if not sender or block.from == sender then
            saved.keys = saved.keys - block.size
            saved.counts[id] = nil
        end
    end
    for text, fact in pairs(saved.facts) do
        fact.by[sender or ""] = nil
        if not sender or not next(fact.by) then saved.facts[text] = nil end
    end
    if not sender then
        for taken in pairs(saved.taken) do
            local set, key = taken:match("^(.-)\031(.*)$")
            Data.Unlearn(set, tonumber(key) or key)
        end
        saved.taken = {}
    end
    Moved()
end

-- The button of the page General, and /sane data forget: all that others sent, prices, counts and facts.
function Data.ForgetShared()
    Relay.ForgetAll()
    Bundle.Forget()
end

Wire.ListenBlock(KIND, Bundle.Block)
Core.On("PLAYER_LOGIN", tick)

local TEXT = {
    report = "shared with your guild and group: counts of %d members (%d kinds), %d facts waiting, %d taken.",
}
Data.reports[#Data.reports + 1] = function()
    if not saved then return end
    local members, facts, taken = 0, 0, 0
    for _ in pairs(saved.counts) do members = members + 1 end
    for _ in pairs(saved.facts) do facts = facts + 1 end
    for _ in pairs(saved.taken) do taken = taken + 1 end
    if members + facts + taken > 0 then Core.Print(TEXT.report:format(members, saved.keys, facts, taken)) end
end

-- What others sent, as the file has it; what is off its shape, of a build no longer kept, or waited too long, dropped.
Data.Saved("Shared", function(part)
    for _, name in ipairs({ "counts", "facts", "taken", "outgoing" }) do
        if type(part[name]) ~= "table" then part[name] = {} end
    end
    local builds, keep = {}, {}
    for _, block in pairs(part.counts) do
        if type(block) == "table" and type(block.build) == "number" then keep[block.build] = true end
    end
    for build in pairs(keep) do builds[#builds + 1] = build end
    table.sort(builds)
    for index = 1, #builds - Tally.BUILDS do keep[builds[index]] = nil end
    part.keys = 0
    for id, block in pairs(part.counts) do
        if type(block) == "table" and keep[block.build] and type(block.drops) == "table" and type(block.from) == "string" then
            block.size = 0
            for _ in pairs(block.drops) do block.size = block.size + 1 end
            block.at = tonumber(block.at) or 0
            part.keys = part.keys + block.size
        else
            part.counts[id] = nil
        end
    end
    part.waiting = 0
    for _ in pairs(part.outgoing) do part.waiting = part.waiting + 1 end
    local oldest = math.floor(Now() / 86400) - Bundle.STALE
    for text, fact in pairs(part.facts) do
        if type(fact) ~= "table" or type(fact.by) ~= "table" or (tonumber(fact.day) or 0) < oldest then part.facts[text] = nil end
    end
    saved, outgoing = part, part.outgoing
end)
