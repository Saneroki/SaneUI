local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Sort
--  Our own sort of the bags, the bar's clean-up button in One Bag (the other
--  views keep the game's C_Container.SortBags): the items of the ordinary
--  bags (the backpack and the bags any item goes in; never the reagent bag,
--  a bag for one kind of item or the keyring) moved into the order the
--  categories give them: pinned items first, then by category in the
--  categories' order (Categories.order, as the player arranged it), inside
--  a category by the window's order (Contents.ORDERS, the dropdown's Sort
--  By), then by the item's link and the larger stack first; the empty slots
--  last.
--
--  It works in passes. In a pass every slot is touched at most once: a move
--  picks the item up and puts it on the other slot (C_Container.
--  PickupContainerItem twice: the game swaps two items, or joins two stacks
--  of one item). Then it waits for the game to have done them (BAG_UPDATE_
--  DELAYED and the slots unlocked again, at most Sort.LONGEST seconds) and
--  plans the next pass from what the bags hold then:
--      join    first, the partial stacks of an item joined: the smallest
--              onto the largest, the next smallest onto the next largest,
--              until no item has two partial stacks
--      place   then each slot gets the item the order wants there, from
--              the slot that holds it
--  It stops when nothing is left to move, when a pass changed nothing, after
--  Sort.PASSES passes, at a fight (it never starts in one), when the player
--  holds something on the cursor (never put down by us), when the window
--  hides. A move that left an item on the cursor puts it back (ClearCursor)
--  and stops. The bar's button is locked while it runs (Bags.Sorting).
--
--      Sort.Plan(list, order, moves)   the next pass's moves, without frames:
--          list   the ordinary bags' records in their order (Sort.Ordinary)
--          moves  { { from = record, to = record }, ... }, filled anew;
--                 returns "join", "place" or nil (nothing to move)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sort = {}
ns.Sort = Sort

Sort.PASSES = 40      -- the most passes of one sort
Sort.WAIT = 0.1       -- seconds after the game's bag update before the next pass
Sort.LONGEST = 3      -- the longest wait for one pass to be done

local Contents, Categories = ns.Contents, ns.Categories

-------------------------------------------------------------------------------
--  Planning, without frames
-------------------------------------------------------------------------------
-- The slots of the ordinary bags among a section's records (Contents.Scan), in their order, into a list.
function Sort.Ordinary(slots, into)
    for index = #into, 1, -1 do into[index] = nil end
    for _, record in ipairs(slots) do
        if record.kind == "bags" then into[#into + 1] = record end
    end
    return into
end

-- Where an item stands in the categories' order: a pinned one with Pinned, at the top.
local function Rank(record)
    if record.pinned then return Categories.rank[Categories.PINNED] or 0 end
    return Categories.rank[record.category] or math.huge
end

local order = "default" -- the window's order, while a plan is made
local function Before(a, b)
    local ra, rb = Rank(a), Rank(b)
    if ra ~= rb then return ra < rb end
    local first = Contents.Before(a, b, order)
    if first ~= nil then return first end
    if a.link ~= b.link then return (a.link or "") < (b.link or "") end
    return (a.count or 1) > (b.count or 1)
end

local function Move(moves, from, to)
    moves[#moves + 1] = moves[#moves + 1] or {}
    local move = moves[#moves]
    move.from, move.to = from, to
end

local function Clear(list)
    for index = #list, 1, -1 do list[index] = nil end
end

-- Partial stacks of one item joined: the smallest onto the largest, and so on inwards.
local partials, items = {}, {} -- [item] = { record, ... }; the items met, in the order met
local function BySize(a, b)
    if a.count ~= b.count then return a.count < b.count end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
end
local function Joins(list, moves)
    for _, stacks in pairs(partials) do Clear(stacks) end
    Clear(items)
    for _, record in ipairs(list) do
        local stack = record.stack
        if record.item and not record.locked and type(stack) == "number" and stack > 1 and (record.count or 1) < stack then
            local stacks = partials[record.item]
            if not stacks then
                stacks = {}
                partials[record.item] = stacks
            end
            if #stacks == 0 then items[#items + 1] = record.item end
            stacks[#stacks + 1] = record
        end
    end
    for _, item in ipairs(items) do
        local stacks = partials[item]
        if #stacks > 1 then
            table.sort(stacks, BySize)
            local low, high = 1, #stacks
            while low < high do
                Move(moves, stacks[low], stacks[high])
                low, high = low + 1, high - 1
            end
        end
    end
end

-- Whether a slot holds what the order wants there (false: nothing).
local function Holds(record, want)
    if not want then return not record.item end
    return record.item ~= nil and record.link == want.link and record.count == want.count
end

-- Each slot given the item the order wants there, from the slot that holds it (one that is not right itself
-- first); a slot touched once in a pass.
local wanted, used, sorted = {}, {}, {}
local function Places(list, moves)
    Clear(sorted)
    for _, record in ipairs(list) do
        if record.item then sorted[#sorted + 1] = record end
    end
    table.sort(sorted, Before)
    for index = 1, #list do
        wanted[index] = sorted[index] or false
        used[index] = list[index].locked == true
    end
    for index = #list + 1, #wanted do wanted[index], used[index] = nil, nil end
    for index, record in ipairs(list) do
        local want = wanted[index]
        if want and not used[index] and not Holds(record, want) then
            local from
            for other, source in ipairs(list) do
                if not used[other] and other ~= index and Holds(source, want) then
                    if not Holds(source, wanted[other]) then
                        from = other
                        break
                    end
                    from = from or other
                end
            end
            if from then
                Move(moves, list[from], record)
                used[index], used[from] = true, true
            end
        end
    end
end

function Sort.Plan(list, how, moves)
    Clear(moves)
    order = how or "default"
    Joins(list, moves)
    if #moves > 0 then return "join" end
    Places(list, moves)
    if #moves > 0 then return "place" end
end

-------------------------------------------------------------------------------
--  Moving, in passes
-------------------------------------------------------------------------------
local running -- { order, passes, started (the last pass's), waiting, due, last } while a sort runs
local list, moves, words = {}, {}, {}

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- What the ordinary bags hold, as words: a pass that changed nothing ends the sort.
local function Seen()
    Clear(words)
    for _, record in ipairs(list) do words[#words + 1] = (record.link or "") .. "x" .. (record.count or 0) end
    return table.concat(words, ";")
end

local Next, Late
local function Due(delay)
    if running.due then return end
    running.due = true
    C_Timer.After(delay, Next)
end

local function Pass()
    if not running then return end
    running.due = false
    if InCombatLockdown() or Game("CursorHasItem") then return Sort.Stop() end
    Sort.Ordinary(ns.Bags.Carried().slots, list)
    for _, record in ipairs(list) do
        if record.locked then
            if GetTime() - running.started > Sort.LONGEST then return Sort.Stop() end
            return Due(Sort.WAIT)
        end
    end
    local seen = Seen()
    if seen == running.last or running.passes >= Sort.PASSES then return Sort.Stop() end
    running.last = seen
    if not Sort.Plan(list, running.order, moves) then return Sort.Stop() end
    running.passes = running.passes + 1
    running.started, running.waiting = GetTime(), true
    local api = C_Container
    for _, move in ipairs(moves) do
        api.PickupContainerItem(move.from.bag, move.from.slot)
        api.PickupContainerItem(move.to.bag, move.to.slot)
        if Game("CursorHasItem") then
            ClearCursor()
            return Sort.Stop()
        end
    end
    C_Timer.After(Sort.LONGEST, Late)
end
Next = ns.Guard(Pass)

-- The game said the bags changed: the next pass a moment later.
local function Updated()
    if not (running and running.waiting) then return end
    running.waiting = false
    Due(Sort.WAIT)
end

-- The game said nothing for a whole wait: the next pass all the same (it stops if nothing changed).
local function Silent()
    if not (running and running.waiting) or GetTime() - running.started < Sort.LONGEST - Sort.WAIT then return end
    running.waiting = false
    Pass()
end
Late = ns.Guard(Silent)

local function Fight()
    Sort.Stop()
end

-- A sort begun, by the window's order (Contents.ORDERS' key); false where it cannot be now.
function Sort.Start(how)
    local api = rawget(_G, "C_Container")
    if running or InCombatLockdown() or not (api and api.PickupContainerItem) or Game("CursorHasItem") then return false end
    running = { order = how or "default", passes = 0, started = GetTime() }
    Core.On("BAG_UPDATE_DELAYED", Updated)
    Core.On("PLAYER_REGEN_DISABLED", Fight)
    Core.Sound("UI_BAG_SORTING_01")
    ns.Bags.Sorting(true)
    Pass()
    return true
end

function Sort.Stop()
    if not running then return end
    running = nil
    Core.Off("BAG_UPDATE_DELAYED", Updated)
    Core.Off("PLAYER_REGEN_DISABLED", Fight)
    ns.Bags.Sorting(false)
end

-- Whether a sort runs now; how many passes it made so far.
function Sort.Running()
    return running ~= nil, running and running.passes or 0
end
