local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Views
--  What the bag window shows for the view chosen in its sidebar, as blocks,
--  without a frame (Layout.lua lays them out):
--      all        All Items: Pinned and Recent first (a pinned item only
--                 there while Pinned is shown, not in its own category too;
--                 a recent one in its category as well), then a block per
--                 category in the categories' order; a group divided
--                 (Categories.Divided): its name (a title), each of its
--                 members holding items as a block of its own (the empty
--                 ones left out), then one empty slot for the whole group (a
--                 bare block: no head); a group whole: one block of all its
--                 members' items under its name; a category
--                 hidden from All Items left out; an empty one shown too (a
--                 line of empty slots to drop an item into), but not while
--                 searching nor in the bank; the free slots are not shown
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
--      local blocks = Views.Build(view, sections, query, order, options, store)
--      store: { blocks = {}, entries = {} } a window's own, used again (nil: the bags')
--      blocks[i] = { word, number, level (1 a part, 2 a block, 3 a group's
--          member), entries = { { record, count, faded } }, key (a
--          category's: its head takes items), group (a group's), title (a
--          group's name over its members: no cells), bare (no head: the
--          group's one empty slot), drop (where an item let go on its
--          empty slot goes: "group:<group>"; else its key), own (the
--          player's own: shown when empty), slots (the bags as they are:
--          empty slots are cells too), plus (a "+" after its cells, to put
--          an item in: Pinned, a category that takes items), bin (Junk's:
--          the waste bin before its cells), into (where an item let go
--          over one of its items goes, as over its head: the bags' Pinned,
--          a category of theirs that takes items, a group as one; nil:
--          the game's own, the two items swap) }
--  Pinned is shown with its "+" when it is empty too (not while searching).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Views = {}
ns.Views = Views

Views.ALL, Views.ONE, Views.EACH = "all", "one", "each"
Views.FIXED = {
    { key = "all", word = ns.TEXT.bagsAllItems, icon = ns.Categories.ART .. "all" },
    { key = "one", word = ns.TEXT.bagsOneBag, icon = ns.Categories.ART .. "one" },
    { key = "each", word = ns.TEXT.bagsEachBag, icon = ns.Categories.ART .. "each" },
}

local Contents, Categories = ns.Contents, ns.Categories

local mine = { blocks = {}, entries = {} } -- the bags' blocks and entries, used again (another window has its own)
local blocks, entries = mine.blocks, mine.entries -- those of the building under way
local used, taken = 0, 0
local byLink = {}                  -- [link] = its entry while merging
local split = {}                   -- [item] = true: split since the window opened, never merged
Views.split = split

-- A group's key as a view and as a block's drop, "group:<group>", made once per group (asked per block and per
-- record of its members at each build and count; the groups are few).
local groupKeys = {}
function Views.GroupKey(group)
    local key = groupKeys[group]
    if not key then
        key = "group:" .. group
        groupKeys[group] = key
    end
    return key
end

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
    block.plus, block.title, block.bare, block.drop, block.bin, block.into = false, false, false, nil, false, nil
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

-- Whether stacks merge now: not at a vendor, the bank (each kind of banker the game has), the mail, a trade, the
-- auction house (its window open). A kind this client lacks is not asked (Foot.Talking).
local TALKING = { "Merchant", "Banker", "CharacterBanker", "AccountBanker", "MailInfo", "TradePartner", "GuildBanker" }
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

-- The records of a section by category, used again: [key] = { record, ... }; a pinned item left out while the
-- bags' Pinned is shown (apart: it stands there alone).
local byKey = {}
local apart = false
local function ByCategory(section)
    for _, list in pairs(byKey) do
        for index = #list, 1, -1 do list[index] = nil end
    end
    for _, record in ipairs(section.slots) do
        if record.item and not (apart and record.pinned) then
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

-- Where an item let go over one of a category's items goes (block.into): the bags' category that takes items.
local function Into(key)
    return firstSection and Categories.Takes(key) and key or nil
end

-- Pinned and Recent: the items pinned, the items that came lately (newest first).
local function Fixed(section, query, order, merge)
    if showPinned then
        for index = #pinned, 1, -1 do pinned[index] = nil end
        for _, record in ipairs(section.slots) do
            if record.item and record.pinned then pinned[#pinned + 1] = record end
        end
        local block = Fill(Block(Categories.Word(Categories.PINNED)), pinned, query, order, merge)
        block.key, block.plus, block.into = Categories.PINNED, plus, Categories.PINNED
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
            if group and Categories.Divided(group) then
                if not Categories.Hidden(group) or query then
                    local title = Block(Categories.GroupWord(group))
                    title.group, title.title = group, true
                    local first, cells = used, 0
                    for _, member in ipairs(Categories.Members(group)) do
                        local block = Fill(Block(Categories.Word(member), 3), lists[member] or {}, query, order, merge)
                        block.key, block.into = member, Into(member)
                        cells = cells + #block.entries
                        if #block.entries == 0 then used = used - 1 end
                    end
                    title.number = cells
                    local slot = plus and firstSection and not query
                    if slot then
                        local block = Block(nil, 3)
                        block.bare, block.plus, block.drop = true, true, Views.GroupKey(group)
                    end
                    if used == first then used = used - 1 end -- nothing under the title: no title either
                end
            elseif group then
                if not Categories.Hidden(group) or query then
                    local block = Block(Categories.GroupWord(group))
                    block.group, block.drop = group, Views.GroupKey(group)
                    block.plus = plus and firstSection
                    block.into = firstSection and block.drop or nil
                    Clear(byLink)
                    for _, member in ipairs(Categories.Members(group)) do
                        for _, record in ipairs(lists[member] or {}) do
                            if Contents.Found(record, query) then Add(block, record, merge) end
                        end
                    end
                    Contents.Sort(block.entries, order)
                    block.number = #block.entries
                    if #block.entries == 0 and (query or not firstSection) then used = used - 1 end
                end
            elseif not Categories.Hidden(key) or query then
                local block = Fill(Block(Categories.Word(key)), lists[key] or {}, query, order, merge)
                block.key, block.into = key, Into(key)
                block.own = Categories.Own(key)
                block.plus = plus and firstSection and Categories.Takes(key)
                block.bin = block.plus and key == Categories.JUNK
                if #block.entries == 0 and (query or not firstSection) then used = used - 1 end
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
-- Bag: not false), recentOne (Recent there: true), merge (not false), plus (the "+" cells: not false) }.
function Views.Build(view, sections, query, order, options, store)
    store = store or mine
    blocks, entries = store.blocks, store.entries
    used, taken = 0, 0
    local merge = Views.Merging(options)
    local single = type(view) == "string" and view:match("^cat:(.+)$")
    local group = type(view) == "string" and view:match("^group:(.+)$")
    plus = options.plus ~= false
    for _, section in ipairs(sections) do
        local bags = section.place == "bags"
        if section.word and (bags or view ~= Views.ONE) then
            local block = Block(section.word, 1)
            block.section = section
        end
        firstSection = bags
        showPinned = options.showPinned ~= false
        apart = bags and showPinned
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
                block.key, block.into = single, Into(single)
                block.own = Categories.Own(single)
                block.plus = plus and bags and Categories.Takes(single)
                block.bin = block.plus and single == Categories.JUNK
            end
        elseif group then
            local lists = ByCategory(section)
            for _, member in ipairs(Categories.Members(group)) do
                local block = Fill(Block(Categories.Word(member), 3), lists[member] or {}, query, order, merge)
                block.key, block.into = member, Into(member)
                block.plus = plus and bags and Categories.Takes(member)
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

-- How many cells each category would show in All Items (for the sidebar), groups summed, Pinned and Recent too (a
-- pinned item only Pinned's while Pinned is shown):
-- [key] = count; stacks merged as Views.Build merges them (options: the window's settings, Merge Stacks).
local counts, seen, recentItems = {}, {}, {} -- seen: [key] = { [link] = true } the stacks counted there
local function Count(key, link)
    if link then
        local links = seen[key]
        if not links then
            links = {}
            seen[key] = links
        end
        if links[link] then return end
        links[link] = true
    end
    counts[key] = (counts[key] or 0) + 1
end
function Views.Counts(section, options)
    Clear(counts)
    for _, links in pairs(seen) do Clear(links) end
    Clear(recentItems)
    for _, item in ipairs(ns.Recent.list) do recentItems[item] = true end
    local merge = Views.Merging(options)
    for _, record in ipairs(section.slots) do
        if record.item then
            local link = merge and record.link and not Contents.GEAR[record.class] and not split[record.item] and record.link or nil
            local key = record.category
            if not (record.pinned and (options or {}).showPinned ~= false) then -- a pinned item is Pinned's alone
                Count(key, link)
                local group = Categories.GroupOf(key)
                if group then Count(Views.GroupKey(group), link) end
            end
            if record.pinned then Count(Categories.PINNED, link) end
            if recentItems[record.item] then Count(Categories.RECENT, link) end
        end
    end
    counts[Categories.RECENT] = counts[Categories.RECENT] or 0
    counts[Categories.PINNED] = counts[Categories.PINNED] or 0
    return counts
end
