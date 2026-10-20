local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Recent
--  What came into the bags lately, for the category Recent: an item whose
--  count in the bags and on the character together went up, newest first, at
--  most Recent.MOST, until the next /reload (nothing is kept). Putting gear
--  on or taking it off changes no count, so it is no new item.
--
--  It listens from the login on, lightly: the bags are counted a frame after
--  a burst of bag events is over. While the bank is open nothing is counted
--  (taking items out of it is no new item); a moment after it closes the
--  counts are taken anew, without anything new.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Recent = {}
ns.Recent = Recent

Recent.MOST = 15
Recent.SETTLE = 0.5 -- seconds after the bank closes before counting anew

local list = {}           -- item IDs, newest first
local totals, counting = {}, {} -- [item] = how many: the last count, and the one being taken
local started, frozen = false, false
Recent.list = list

local function Container()
    return rawget(_G, "C_Container")
end

-- Every item's count in the carried bags and on the character, into counts (emptied first).
local function Count(counts)
    for item in pairs(counts) do counts[item] = nil end
    local api = Container()
    if not (api and api.GetContainerNumSlots and api.GetContainerItemInfo) then return counts end
    local carried = ns.Contents.Carried({})
    for _, bag in ipairs(carried) do
        for slot = 1, ns.Contents.Size(bag) do
            local info = Core.Ask(api.GetContainerItemInfo, bag, slot)
            local item = type(info) == "table" and Core.Plain(info.itemID)
            if type(item) == "number" then counts[item] = (counts[item] or 0) + (Core.Plain(info.stackCount) or 1) end
        end
    end
    local worn = rawget(_G, "GetInventoryItemID")
    if worn then
        for slot = 1, 19 do
            local item = Core.Plain(Core.Ask(worn, "player", slot))
            if type(item) == "number" then counts[item] = (counts[item] or 0) + 1 end
        end
    end
    return counts
end

-- An item to the front of the list (once), the list cut to its most.
local function Front(item)
    for index = #list, 1, -1 do
        if list[index] == item then table.remove(list, index) end
    end
    table.insert(list, 1, item)
    for index = #list, Recent.MOST + 1, -1 do list[index] = nil end
end

-- The bags counted anew; what rose goes to the front (new: whether to look for it at all).
local function Take(new)
    if frozen then return end
    Count(counting)
    local changed = false
    if started and new then
        for item, count in pairs(counting) do
            if count > (totals[item] or 0) then
                Front(item)
                changed = true
            end
        end
    end
    totals, counting = counting, totals
    started = true
    if changed and ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
end

local Soon = Core.Later(function() Take(true) end)
local Settled = Core.Later(function()
    frozen = false
    Take(false)
end, Recent.SETTLE)

function Recent.Start()
    Core.On("BAG_UPDATE_DELAYED", Soon)
    Core.On("PLAYER_EQUIPMENT_CHANGED", Soon)
    Core.On("BANKFRAME_OPENED", function() frozen = true end)
    Core.On("BANKFRAME_CLOSED", Settled)
    Take(false)
end

-- Whether an item is in the list; the list emptied (its header's Clear).
function Recent.Has(item)
    for _, other in ipairs(list) do
        if other == item then return true end
    end
    return false
end

function Recent.Clear()
    for index = #list, 1, -1 do list[index] = nil end
end

-- For the tests: the counts taken anew now, as after a burst of bag events.
Recent.Take = Take
