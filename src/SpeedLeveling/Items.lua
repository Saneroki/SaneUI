local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Items
--  What the key uses; Key.lua writes it into the macro of Find, out of a
--  fight only:
--    the hearth  when the step at hand of your leveling guide wants it (its
--                items hold the Hearthstone, or its spells the shaman's Astral
--                Recall): the Hearthstone in your bags off its cooldown, else
--                Astral Recall if you know it and it is ready. Then that is all
--                a press of Find does (the switch Hearthstone).
--    one item    when Find finds nothing wanted around you (the switch Quest
--                items): the first in your bags, usable and off its cooldown,
--                of the guide's step's items and then of the game's own quest
--                items (the item a quest in your log shows as a button), for
--                quests not yet done, but one the game says is out of range of
--                what it is for. One a press: two would be used at once.
--  Such an item is often for a place or a creature: away from it the game says
--  so and nothing is used; one that wants a target puts the game's targeting
--  hand on the cursor.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Items = {}
ns.Items = Items

Items.HEARTHSTONE = 6948  -- the game's Hearthstone
Items.RECALL = 556        -- the shaman's Astral Recall, to the same place
Items.GCD = 1.5           -- a cooldown this short is the global one: ready

local EMPTY = {}

local function Has(list, value)
    for _, entry in ipairs(list or EMPTY) do
        if entry == value then return true end
    end
    return false
end

-- A cooldown as the game gives it (start and duration, or a table of them): over, or only the global one.
local function Over(start, duration)
    if type(start) == "table" then start, duration = start.startTime, start.duration end
    start, duration = Core.Plain(start), Core.Plain(duration)
    return not (type(start) == "number" and type(duration) == "number" and start > 0 and duration > Items.GCD)
end

-- An item in your bags, usable now and off its cooldown.
local function Ready(item)
    local items, bags = rawget(_G, "C_Item"), rawget(_G, "C_Container")
    if not items or (Core.Ask(items.GetItemCount, item) or 0) < 1 then return false end
    if not Core.Ask(items.IsUsableItem, item) then return false end
    return Over(Core.Ask(bags and bags.GetItemCooldown, item))
end

-- A spell you know, off its cooldown, and its name.
local function Spell(id)
    local spells = rawget(_G, "C_Spell")
    if not Core.Ask(rawget(_G, "IsPlayerSpell"), id) then return nil end
    local name = Core.Ask(spells and spells.GetSpellName or rawget(_G, "GetSpellInfo"), id)
    if type(name) ~= "string" then return nil end
    local cooldown = spells and spells.GetSpellCooldown
    if cooldown then
        local ok, info = pcall(cooldown, id)
        if ok and not Over(info) then return nil end
    else
        if not Over(Core.Ask(rawget(_G, "GetSpellCooldown"), id)) then return nil end
    end
    return name
end

-- The hearth the guide's step wants now, as a macro line; nil when it wants none or none is ready.
function Items.Hearth(items, spells)
    local wanted = Has(items, Items.HEARTHSTONE) or Has(spells, Items.RECALL)
    if not wanted then return nil end
    if Ready(Items.HEARTHSTONE) then return "/use item:" .. Items.HEARTHSTONE end
    local recall = Has(spells, Items.RECALL) and Spell(Items.RECALL)
    return recall and "/cast " .. recall or nil
end

-- The game's quest items of the quests in your log not yet done, in the log's order (also Icons.lua's); with near,
-- only those the game does not call out of range of what they are for (its quest item's range: in range, or none).
function Items.QuestItems(near)
    local found = {}
    local range = rawget(_G, "IsQuestLogSpecialItemInRange")
    local log, special = rawget(_G, "C_QuestLog"), rawget(_G, "GetQuestLogSpecialItemInfo")
    local total = log and type(special) == "function" and Core.Ask(log.GetNumQuestLogEntries)
    if type(total) ~= "number" then return found end
    for index = 1, total do
        local info = Core.Ask(log.GetInfo, index)
        local quest = type(info) == "table" and not info.isHeader and Core.Plain(info.questID)
        if type(quest) == "number" and not Core.Ask(log.IsComplete, quest) then
            local link = Core.Ask(special, index)
            local item = type(link) == "string" and tonumber(link:match("item:(%d+)"))
            local away = near and range and Core.Ask(range, index) == 0
            if item and not away then found[#found + 1] = item end
        end
    end
    return found
end

-- The one item to use when nothing is found, as a macro line; nil when there is none ready.
function Items.Pick(items)
    for _, list in ipairs({ items or EMPTY, Items.QuestItems(true) }) do
        for _, item in ipairs(list) do
            if item ~= Items.HEARTHSTONE and Ready(item) then return "/use item:" .. item end
        end
    end
    return nil
end
