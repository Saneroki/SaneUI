local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Views
--  What the bag window shows for the view chosen in its sidebar, as blocks,
--  without a frame (Layout.lua lays them out):
--      all        All Items: Pinned and Recent first (a second look: those
--                 items are in their own category too), then a block per
--                 category in the categories' order, a group's members
--                 together as one block under the group's name; a category
--                 hidden from All Items left out, an empty one too unless it
--                 is the player's own; the free slots are not shown
--      one        One Bag: Pinned, then every slot of the ordinary bags in
--                 their order, the empty ones too, then each bag for one kind
--                 of item and the reagent bag by itself
--      each       Each Bag: every bag by itself, its slots in order
--      cat:<key>  one category's items
--      group:<g>  a group's members, each a block
--  The bank, while it is open, follows the bags: a part's head, then its
--  slots as the view shows the bags' (Bank Tabs and One Bank for the views of
--  the bags as they are, its items by category for the others).
--
--  In the views by category, a stack of an item that is no gear merges with
--  the other stacks of that item into one cell with the count of them all
--  (not while a vendor, the bank, the mail, a trade or the auction house is
--  open: there each stack is its own; Views.Merging). What the search does not
--  find is left out of them; in the views of the bags as they are, it is
--  faded.
--
--      local blocks = Views.Build(view, sections, query, order, options)
--      blocks[i] = { word, number, level (1 a part, 2 a block, 3 a group's
--          member), entries = { { record, count, faded } }, key (a
--          category's: its head takes items), group (a group's), own (the
--          player's own: shown when empty), slots (the bags as they are:
--          empty slots are cells too) }
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Views = {}
ns.Views = Views

Views.ALL, Views.ONE, Views.EACH = "all", "one", "each"
Views.FIXED = {
    { key = "all", word = ns.TEXT.bagsAllItems, icon = "Interface\\Icons\\INV_Misc_Bag_07" },
    { key = "one", word = ns.TEXT.bagsOneBag, icon = "Interface\\Icons\\INV_Misc_Bag_08" },
    { key = "each", word = ns.TEXT.bagsEachBag, icon = "Interface\\Icons\\INV_Misc_Bag_10" },
}

local Contents, Categories = ns.Contents, ns.Categories

local blocks, used = {}, 0         -- the blocks, used again
local entries, taken = {}, 0       -- the entries, used again
local byLink = {}                  -- [link] = its entry while merging
local split = {}                   -- [item] = true: split since the window opened, never merged
Views.split = split

local function Block(word, level)
    used = used + 1
    local block = blocks[used]
    if not block then
        block = { entries = {} }
        blocks[used] = block
    end
    for index = #block.entries, 1, -1 do block.entries[index] = nil end
    block.word, block.level, block.number = word, level or 2, nil
    block.key, block.group, block.own, block.slots, block.section, block.spare = nil, nil, false, false, nil, false
    return block
end

local function Entry(block, record, faded)
    taken = taken + 1
    local entry = entries[taken]
    if not entry then
        entry = {}
        entries[taken] = entry
    end
    entry.record, entry.count, entry.faded = record, nil, faded or false
    block.entries[#block.entries + 1] = entry
    return entry
end

-- Whether stacks merge now: not at a vendor, the bank, the mail, a trade, the auction house (its window open).
local TALKING = { "Merchant", "Banker", "MailInfo", "TradePartner", "GuildBanker" }
function Views.Merging(options)
    if options and options.merge == false then return false end
    local house = rawget(_G, "AuctionHouseFrame")
    if type(house) == "table" and house.IsShown and house:IsShown() then return false end
    local talk = ns.Foot and ns.Foot.Talking
    if not talk then return true end
    for _, kind in ipairs(TALKING) do
        if talk(kind) then return false end
    end
    return true
end

-- A record into a block: merged with the stack of the same item before it where stacks merge.
local function Add(block, record, merge)
    if merge and record.link and not Contents.GEAR[record.class] and not split[record.item] then
        local entry = byLink[record.link]
        if entry then
            entry.count = (entry.count or entry.record.count or 1) + (record.count or 1)
            return entry
        end
        entry = Entry(block, record)
        byLink[record.link] = entry
        return entry
    end
    return Entry(block, record)
end

local function Clear(map)
    for key in pairs(map) do map[key] = nil end
end

-- A block of these records (those with an item that the search finds), sorted.
local function Fill(block, list, query, order, merge)
    Clear(byLink)
    for _, record in ipairs(list) do
        if record.item and Contents.Found(record, query) then Add(block, record, merge) end
    end
    Contents.Sort(block.entries, order)
    block.number = #block.entries
    return block
end

-- The records of a section by category, used again: [key] = { record, ... }.
local byKey = {}
local function ByCategory(section)
    for _, list in pairs(byKey) do
        for index = #list, 1, -1 do list[index] = nil end
    end
    for _, record in ipairs(section.slots) do
        if record.item then
            local list = byKey[record.category]
            if not list then
                list = {}
                byKey[record.category] = list
            end
            list[#list + 1] = record
        end
    end
    return byKey
end

local pinned, recent = {}, {}
local showPinned, showRecent, plus, firstSection -- this building's: what is shown, whether the bags' section

-- Pinned and Recent: the items pinned, the items that came lately (newest first).
local function Fixed(section, query, order, merge)
    if showPinned then
        for index = #pinned, 1, -1 do pinned[index] = nil end
        for _, record in ipairs(section.slots) do
            if record.item and record.pinned then pinned[#pinned + 1] = record end
        end
        local block = Fill(Block(Categories.Word(Categories.PINNED)), pinned, query, order, merge)
        block.key = Categories.PINNED
        if #block.entries == 0 and (query or not plus) then used = used - 1 end
    end
    if showRecent then
        for index = #recent, 1, -1 do recent[index] = nil end
        local list = ns.Recent.list
        for _, item in ipairs(list) do
            for _, record in ipairs(section.slots) do
                if record.item == item and Contents.Found(record, query) then recent[#recent + 1] = record end
            end
        end
        local block = Block(Categories.Word(Categories.RECENT))
        block.key = Categories.RECENT
        Clear(byLink)
        for _, record in ipairs(recent) do Add(block, record, merge) end
        block.number = #block.entries
        if #block.entries == 0 then used = used - 1 end
    end
end

-- Every category of a section as a block, a group's members as one block.
local function ByCategories(section, query, order, merge)
    local lists = ByCategory(section)
    local done = {}
    for _, key in ipairs(Categories.order) do
        local def = Categories.DEF[key]
        local group = Categories.GroupOf(key)
        if not (def and def.fixed) and not done[group or key] then
            done[group or key] = true
            if group then
                if not Categories.Hidden(group) or query then
                    local block = Block(Categories.GroupWord(group))
                    block.group = group
                    Clear(byLink)
                    for _, member in ipairs(Categories.Members(group)) do
                        for _, record in ipairs(lists[member] or {}) do
                            if Contents.Found(record, query) then Add(block, record, merge) end
                        end
                    end
                    Contents.Sort(block.entries, order)
                    block.number = #block.entries
                    if #block.entries == 0 then used = used - 1 end
                end
            elseif not Categories.Hidden(key) or query then
                local block = Fill(Block(Categories.Word(key)), lists[key] or {}, query, order, merge)
                block.key = key
                block.own = Categories.Own(key)
                if #block.entries == 0 and not (block.own and not query and firstSection) then used = used - 1 end
            end
        end
    end
end

-- The slots of these bags as they are, under one head (taken / all slots); faded what the search does not find.
local function Slots(section, word, bags, query)
    local block = Block(word)
    block.slots = true
    local taken, all = 0, 0
    for _, record in ipairs(section.slots) do
        if bags[record.bag] then
            Entry(block, record, query ~= nil and record.item ~= nil and not Contents.Found(record, query))
            all = all + 1
            if record.item then taken = taken + 1 end
        end
    end
    block.number = ns.TEXT.bagsTaken:format(taken, all)
    block.spare = true
    if all == 0 then used = used - 1 end
    return block
end

local function BagSet(section, test)
    local set = {}
    for _, record in ipairs(section.slots) do
        if test(record) then set[record.bag] = true end
    end
    return set
end

local function Ordinary(record) return not record.special and not record.reagentBag end

-- The bags as they are: all ordinary bags together (one), or each bag by itself (each); the bags for one kind
-- of item and the reagent bag each by itself after them.
local function AsTheyAre(section, query, each)
    local bags, seen = {}, {}
    for _, record in ipairs(section.slots) do
        if not seen[record.bag] then
            seen[record.bag] = true
            bags[#bags + 1] = record.bag
        end
    end
    local carried = section.place == "bags"
    if not each then
        local block = Slots(section, carried and ns.TEXT.bagsMain or section.word, carried and BagSet(section, Ordinary)
            or BagSet(section, function() return true end), query)
        if not carried then block.section = section end
    end
    for _, bag in ipairs(bags) do
        local first
        for _, record in ipairs(section.slots) do
            if record.bag == bag then first = record break end
        end
        if each or carried and not Ordinary(first) then
            Slots(section, ns.Contents.BagWord(bag, section.place), { [bag] = true }, query)
        end
    end
end

-- The blocks of the view chosen: sections are the bags' (first) and the bank's parts (Bags.lua); options (the
-- window's settings, read only): { showPinned, showRecent (shown: not false), pinnedOne (Pinned in One Bag and Each
-- Bag: not false), recentOne (Recent there: true), merge (not false), plus (an empty Pinned still shown) }.
function Views.Build(view, sections, query, order, options)
    used, taken = 0, 0
    local merge = Views.Merging(options)
    local single = type(view) == "string" and view:match("^cat:(.+)$")
    local group = type(view) == "string" and view:match("^group:(.+)$")
    plus = options.plus == true
    for index, section in ipairs(sections) do
        local bags = index == 1
        if section.word and (bags or view ~= Views.ONE) then
            local block = Block(section.word, 1)
            block.section = section
        end
        firstSection = bags
        showPinned = options.showPinned ~= false
        showRecent = options.showRecent ~= false
        if single then
            local lists = ByCategory(section)
            if single == Categories.PINNED or single == Categories.RECENT then
                if bags then
                    showPinned, showRecent = single == Categories.PINNED, single == Categories.RECENT
                    Fixed(section, query, order, merge)
                end
            else
                local block = Fill(Block(Categories.Word(single)), lists[single] or {}, query, order, merge)
                block.key = single
                block.own = Categories.Own(single)
            end
        elseif group then
            local lists = ByCategory(section)
            for _, member in ipairs(Categories.Members(group)) do
                local block = Fill(Block(Categories.Word(member), 3), lists[member] or {}, query, order, merge)
                block.key = member
                if #block.entries == 0 then used = used - 1 end
            end
        elseif view == Views.ONE or view == Views.EACH then
            if bags then
                showPinned = showPinned and options.pinnedOne ~= false
                showRecent = showRecent and options.recentOne == true
                Fixed(section, query, order, merge)
            end
            AsTheyAre(section, query, view == Views.EACH)
        else
            if bags then Fixed(section, query, order, merge) end
            ByCategories(section, query, order, merge)
        end
    end
    for index = used + 1, #blocks do blocks[index].word = nil end
    blocks.count = used
    return blocks
end

-- How many cells each category would show in All Items (for the sidebar), groups summed: [key] = count.
local counts = {}
function Views.Counts(section)
    Clear(counts)
    local merge = Views.Merging()
    local seen = {}
    for _, record in ipairs(section.slots) do
        if record.item then
            local mergeKey = merge and record.link and not Contents.GEAR[record.class] and not split[record.item] and record.link
            local key = record.category
            if not (mergeKey and seen[key .. "|" .. mergeKey]) then
                counts[key] = (counts[key] or 0) + 1
                local group = Categories.GroupOf(key)
                if group then counts["group:" .. group] = (counts["group:" .. group] or 0) + 1 end
                if mergeKey then seen[key .. "|" .. mergeKey] = true end
            end
            if record.pinned then counts[Categories.PINNED] = (counts[Categories.PINNED] or 0) + 1 end
        end
    end
    local recentCount = 0
    for _, item in ipairs(ns.Recent.list) do
        for _, record in ipairs(section.slots) do
            if record.item == item then recentCount = recentCount + 1 break end
        end
    end
    counts[Categories.RECENT] = recentCount
    counts[Categories.PINNED] = counts[Categories.PINNED] or 0
    return counts
end
