local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Slots
--  What the open loot holds, read from the game into plain lines: one for
--  each of the game's slots, in its order (a slot taken is left out). The
--  window draws them; the rules read them. Nothing here knows a frame.
--
--      local lines = Slots.Read()       -- the loot open now (empty while none is)
--      local line = Slots.Line(slot)    -- one slot anew; nil for one that is empty
--      Slots.Wanted(line, options)      -- whether the player's rules take it at once
--      Slots.Name(id)                   -- an item's name, if the game knows it
--
--  A line: slot, kind ("item", "money", "currency"), icon, name, count,
--  quality, locked, link, id (an item's), quest (a quest wants it), starts (it
--  begins a quest not taken yet), bind (the game's: 1 when picked up, 2 when
--  equipped, 3 when used, 4 a quest's), kind's words (what, where), worth (a
--  vendor's price for one).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Slots = {}
ns.Slots = Slots

-- The game's kinds of loot slot (Enum.LootSlotType); the numbers where this client has no such list.
local function Kinds()
    local kinds = rawget(_G, "Enum") and Enum.LootSlotType
    return kinds or { None = 0, Item = 1, Money = 2, Currency = 3 }
end

-- What the game says of an item: its kind's words, where it is worn, its price at a vendor, how it binds.
local function ItemFacts(link)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if type(info) ~= "function" or not link then return nil end
    local ok, name, _, _, _, _, what, sub, _, where, _, worth, _, _, bind = pcall(info, link)
    if not ok then return nil end
    return Plain(name), Plain(what), Plain(sub), Plain(where), Plain(worth), Plain(bind)
end

function Slots.Name(id)
    return (ItemFacts(id))
end

-- One slot of the open loot as a line; nil for an empty one (taken, or nothing there).
function Slots.Line(slot)
    local icon, name, count, currency, quality, locked, questItem, questID, active, coin = GetLootSlotInfo(slot)
    name = Plain(name)
    if not name and not Plain(icon) then return nil end
    local kinds = Kinds()
    local kind = Plain(GetLootSlotType and GetLootSlotType(slot))
    if kind == kinds.None then return nil end
    local line = { slot = slot, icon = Plain(icon), name = name or "", count = Plain(count) or 1,
                   quality = Plain(quality) or 1, locked = Plain(locked) and true or false }
    currency = Plain(currency)
    if kind == kinds.Money or (kind == nil and Plain(coin)) then
        line.kind = "money"
        -- The game writes a coin slot's money as its name, on lines ("12 Silver\n3 Copper"): one line here.
        line.name = line.name:gsub("\n", " ")
    elseif kind == kinds.Currency or currency then
        line.kind = "currency"
        local util = rawget(_G, "CurrencyContainerUtil")
        if currency and util and util.GetCurrencyContainerInfo then
            local n, t, c, q = util.GetCurrencyContainerInfo(currency, line.count, line.name, line.icon, line.quality)
            line.name, line.icon, line.count, line.quality = Plain(n) or line.name, Plain(t) or line.icon,
                Plain(c) or line.count, Plain(q) or line.quality
        end
    else
        line.kind = "item"
    end
    questID = Plain(questID)
    line.quest = (Plain(questItem) or questID) and true or false
    line.starts = (questID and not Plain(active)) and true or false
    if line.kind == "item" then
        line.link = Plain(GetLootSlotLink(slot))
        line.id = line.link and tonumber(line.link:match("item:(%d+)"))
        local _, what, sub, where, worth, bind = ItemFacts(line.link)
        line.what, line.sub, line.worth, line.bind = what, sub, worth, bind
        line.where = where and where ~= "" and Core.Word(where, nil) or nil
    end
    return line
end

-- Every line of the loot open now, in the game's order.
function Slots.Read()
    local lines = {}
    local count = Plain(GetNumLootItems()) or 0
    for slot = 1, count do
        local line = Slots.Line(slot)
        if line then lines[#lines + 1] = line end
    end
    return lines
end

-- Whether the player's rules (the module's options) take this line at once. A thing that binds when picked up is
-- never taken by a rule but the quest's: the game would ask, and the player should see it first.
function Slots.Wanted(line, options)
    if not line or line.locked then return false end
    if line.kind ~= "item" then return options.takeCoins and true or false end
    if options.takeQuest and (line.quest or line.starts or line.bind == 4) then return true end
    if line.bind == 1 then return false end
    local kept = options.takeKept and type(options.kept) == "table" and line.id and options.kept[line.id]
    if kept then return true end
    local upTo = tonumber(options.takeUpTo) or -1
    return upTo >= 0 and line.quality <= upTo
end

-- The note under a line's name: how it binds, its kind and where it is worn; a quest's.
function Slots.Note(line)
    local T = ns.TEXT
    if line.kind == "money" then return T.coins end
    if line.kind == "currency" then return T.currency end
    if line.starts then return T.questStarts end
    if line.quest or line.bind == 4 then return T.questItem end
    local parts = {}
    if line.bind == 1 then parts[1] = T.pickup elseif line.bind == 2 then parts[1] = T.equip
    elseif line.bind == 3 then parts[1] = T.use end
    local kind = line.where or line.sub or line.what
    if kind and kind ~= "" then parts[#parts + 1] = kind end
    return table.concat(parts, " · ")
end
